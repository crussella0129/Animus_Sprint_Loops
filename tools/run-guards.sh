#!/usr/bin/env bash
# Canonical guard-suite runner (sprint 11). Single source of "the suite" for
# both the local Test phase and CI — the two can't drift because they both
# invoke this script.
#
# Derived from the array-test confirmation model (github.com/crussella0129/
# array-test, docs/ARCHITECTURE.md §2/§5/§6.1), sized to a bash guard suite:
# each suite run is recorded as one ndjson confirmation
#   {"suite","script_hash","status","evidence_hash","duration_s","ts",("determinism")}
# where script_hash fingerprints the suite's own definition (its script file,
# or the linted file set for shellcheck) and evidence_hash is the sha256 of
# the suite's NORMALIZED output (temp paths, ISO timestamps, and CRs stripped,
# so two identical runs in the same environment hash identically). No Merkle
# root / memoization yet — see ROADMAP.md.
#
# Usage: run-guards.sh [--determinism] [--out <path>]
#   --determinism   run each suite twice; normalized evidence hashes (and exit
#                   codes) must match, else the suite is flagged nondeterministic
#                   and the runner fails (array-test's determinism meta-check).
#   --out <path>    ndjson output path (default ./guards-report.ndjson).
#
# RUN_GUARDS_EXTRA_SUITES=<dir>: every *.sh in <dir> is appended as an extra
# suite (used by the Test phase to exercise the FAIL/nondeterminism paths
# without touching the real suite list).
#
# JSON note: field values here are hex hashes, integers, and fixed-alphabet
# suite names — no escaping required.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DETERMINISM=0
OUT="./guards-report.ndjson"
while [ $# -gt 0 ]; do
  case "$1" in
    --determinism) DETERMINISM=1; shift ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "usage: $(basename "$0") [--determinism] [--out <path>]" >&2; exit 2 ;;
  esac
done

EXTRA_DIR="${RUN_GUARDS_EXTRA_SUITES:-}"

SUITES=(selftest merge-policy merge-policy-test plugin-manifest bundle-sync bundle-sync-test adapter-semantics adapter-semantics-test operator-docs remote-profile check-substrate deploy-substrate remote-adapter sync-work-branch shellcheck)
if [ -n "$EXTRA_DIR" ]; then
  for f in "$EXTRA_DIR"/*.sh; do
    [ -f "$f" ] || continue
    SUITES+=("extra:${f##*/}")
  done
fi

suite_cmd() {
  case "$1" in
    selftest)          bash claude-code/skills/sprint-loop/scripts/selftest.sh ;;
    merge-policy)      bash tools/check-merge-policy.sh ;;
    merge-policy-test) bash tools/check-merge-policy.test.sh ;;
    plugin-manifest)   bash tools/check-plugin-manifest.sh ;;
    bundle-sync)       bash tools/check-bundle-sync.sh ;;
    bundle-sync-test)  bash tools/check-bundle-sync.test.sh ;;
    adapter-semantics)      bash tools/check-adapter-semantics.sh ;;
    adapter-semantics-test) bash tools/check-adapter-semantics.test.sh ;;
    operator-docs)     bash tools/operator-docs.test.sh ;;
    remote-profile)    bash claude-code/skills/sprint-loop/scripts/remote-profile.test.sh ;;
    check-substrate)   bash claude-code/skills/sprint-loop/scripts/check-substrate.test.sh ;;
    deploy-substrate)  bash claude-code/skills/sprint-loop/scripts/deploy-substrate.test.sh ;;
    remote-adapter)    bash claude-code/skills/sprint-loop/scripts/remote-adapter.test.sh ;;
    sync-work-branch)  bash claude-code/skills/sprint-loop/scripts/sync-work-branch.test.sh ;;
    shellcheck)        shellcheck -S warning \
                         claude-code/skills/sprint-loop/scripts/*.sh \
                         claude-code/install.sh claude-code/tests/*.sh \
                         codex-cli/install.sh codex-cli/tests/*.sh \
                         open-harnesses/install.sh \
                         tools/*.sh ;;
    extra:*)           bash "$EXTRA_DIR/${1#extra:}" ;;
  esac
}

suite_script_hash() {
  case "$1" in
    selftest)          cat claude-code/skills/sprint-loop/scripts/selftest.sh ;;
    merge-policy)      cat tools/check-merge-policy.sh ;;
    merge-policy-test) cat tools/check-merge-policy.test.sh ;;
    plugin-manifest)   cat tools/check-plugin-manifest.sh ;;
    bundle-sync)       cat tools/check-bundle-sync.sh ;;
    bundle-sync-test)  cat tools/check-bundle-sync.test.sh ;;
    adapter-semantics)      cat tools/check-adapter-semantics.sh ;;
    adapter-semantics-test) cat tools/check-adapter-semantics.test.sh ;;
    operator-docs)     cat tools/operator-docs.test.sh ;;
    remote-profile)    cat claude-code/skills/sprint-loop/scripts/remote-profile.test.sh ;;
    check-substrate)   cat claude-code/skills/sprint-loop/scripts/check-substrate.test.sh ;;
    deploy-substrate)  cat claude-code/skills/sprint-loop/scripts/deploy-substrate.test.sh ;;
    remote-adapter)    cat claude-code/skills/sprint-loop/scripts/remote-adapter.test.sh ;;
    sync-work-branch)  cat claude-code/skills/sprint-loop/scripts/sync-work-branch.test.sh ;;
    shellcheck)        cat claude-code/skills/sprint-loop/scripts/*.sh \
                         claude-code/install.sh claude-code/tests/*.sh \
                         codex-cli/install.sh codex-cli/tests/*.sh \
                         open-harnesses/install.sh \
                         tools/*.sh ;;
    extra:*)           cat "$EXTRA_DIR/${1#extra:}" ;;
  esac | hash_stdin
}

# Portable sha256 over stdin: stock macOS ships `shasum -a 256` (perl), not
# coreutils' sha256sum. RUN_GUARDS_HASH_TOOL forces one tool — the explicit
# test seam so the fallback path is testable on hosts that have both.
hash_stdin() {
  case "${RUN_GUARDS_HASH_TOOL:-auto}" in
    sha256sum) sha256sum | cut -d' ' -f1 ;;
    shasum)    shasum -a 256 | cut -d' ' -f1 ;;
    *) if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -d' ' -f1
       else shasum -a 256 | cut -d' ' -f1; fi ;;
  esac
}

# Normalize suite output so evidence hashes are stable across identical runs:
# strip CRs, replace mktemp paths (Linux/git-bash /tmp/tmp.*; macOS
# /var/folders/…, sometimes /private-prefixed) and ISO-8601 UTC timestamps
# with tokens.
normalize() {
  tr -d '\r' \
    | sed -E -e 's|/private/var/folders/[^[:space:]]+|<TMP>|g' \
             -e 's|/var/folders/[^[:space:]]+|<TMP>|g' \
             -e 's|/tmp/tmp\.[A-Za-z0-9]+|<TMP>|g' \
             -e 's|[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z|<TS>|g'
}

# run_once <suite> — prints the evidence hash; returns the suite's exit code.
run_once() {
  local cap rc
  cap=$(mktemp)
  if (cd "$ROOT" && suite_cmd "$1") >"$cap" 2>&1; then rc=0; else rc=$?; fi
  normalize <"$cap" | hash_stdin
  rm -f "$cap"
  return "$rc"
}

# Fail fast if the confirmations file can't be written — a runner that can't
# record its confirmations must not report success.
if ! : 2>/dev/null > "$OUT"; then
  echo "run-guards: cannot write confirmations to $OUT" >&2
  exit 2
fi
fail=0
passed=0

for name in "${SUITES[@]}"; do
  start=$(date +%s)
  h1=$(run_once "$name"); rc1=$?
  status=PASS
  det=""
  if [ "$DETERMINISM" = "1" ]; then
    h2=$(run_once "$name"); rc2=$?
    if [ "$h1" != "$h2" ] || [ "$rc1" != "$rc2" ]; then
      det=',"determinism":"mismatch"'
      fail=1
      echo "NONDETERMINISTIC: $name (run1 rc=$rc1 $h1 / run2 rc=$rc2 $h2)" >&2
    else
      det=',"determinism":"ok"'
    fi
  fi
  if [ "$rc1" -ne 0 ]; then status=FAIL; fail=1; fi
  dur=$(( $(date +%s) - start ))
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  script_hash=$(suite_script_hash "$name")
  printf '{"suite":"%s","script_hash":"%s","status":"%s","evidence_hash":"%s","duration_s":%s,"ts":"%s"%s}\n' \
    "$name" "$script_hash" "$status" "$h1" "$dur" "$ts" "$det" >> "$OUT"
  if [ "$status" = "PASS" ] && { [ "$DETERMINISM" = "0" ] || [ "${det}" = ',"determinism":"ok"' ]; }; then
    passed=$((passed+1))
    printf '  PASS  %-18s %ss  evidence=%s\n' "$name" "$dur" "${h1:0:12}"
  else
    printf '  FAIL  %-18s %ss  (status=%s%s)\n' "$name" "$dur" "$status" "${det:+ det-mismatch}" >&2
  fi
done

total=${#SUITES[@]}
if [ "$fail" = "0" ]; then
  echo "run-guards: $passed/$total suites PASS — confirmations in $OUT"
  exit 0
fi
echo "run-guards: $passed/$total suites PASS — FAILURES recorded in $OUT" >&2
exit 1
