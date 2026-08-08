#!/usr/bin/env bash
# Fixtures for remote-adapter.sh — open-once, refuse-second, generic fallback,
# never-merge. gh/glab are stubbed on PATH; a local bare repo backs the push.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RA="$SCRIPT_DIR/remote-adapter.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-adapter.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM
pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

make_repo() {  # <dir> <profile-body>
  git init -q --bare "$1.git"
  git init -q "$1"
  git -C "$1" checkout -q -b dev
  git -C "$1" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  git -C "$1" remote add origin "$1.git"
  mkdir -p "$1/docs/work"
  printf '# Remote Profile\n\n<!-- sprint-loop-remote-profile-v2 -->\n\n```\n%s\n```\n' \
    "$2" > "$1/docs/work/remote-profile.md"
}
STUB_BIN="$TMP_ROOT/bin"; mkdir -p "$STUB_BIN"
cat > "$STUB_BIN/gh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUBLOG"
if [ "${1:-}" = pr ] && [ "${2:-}" = list ]; then [ "${STUB_PR_EXISTS:-0}" = 1 ] && echo 42; exit 0; fi
if [ "${1:-}" = pr ] && [ "${2:-}" = create ]; then echo "https://example/pr/1"; exit 0; fi
exit 0
STUB
chmod +x "$STUB_BIN/gh"

# test_pr_opens_once
P1="$TMP_ROOT/once"; make_repo "$P1" 'provider: github
base: main
work: dev'
export STUBLOG="$P1.log"; : > "$STUBLOG"
PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 bash "$RA" --root "$P1" open-pr >/dev/null 2>&1 ||
  die test_pr_opens_once 'open-pr failed'
[ "$(grep -c 'pr create' "$STUBLOG")" = 1 ] || die test_pr_opens_once "expected 1 create, got $(grep -c 'pr create' "$STUBLOG")"
grep -q 'pr merge' "$STUBLOG" && die test_pr_opens_once 'merge was invoked'
pass test_pr_opens_once

# test_pr_refuses_existing_checkpoint
P2="$TMP_ROOT/second"; make_repo "$P2" 'provider: github
base: main
work: dev'
export STUBLOG="$P2.log"; : > "$STUBLOG"
out=$(PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=1 bash "$RA" --root "$P2" open-pr 2>&1) ||
  die test_pr_refuses_existing_checkpoint 'open-pr errored'
grep -q 'pr create' "$STUBLOG" && die test_pr_refuses_existing_checkpoint 'opened a second PR'
printf '%s' "$out" | grep -qi 'already' || die test_pr_refuses_existing_checkpoint 'no already-open message'
pass test_pr_refuses_existing_checkpoint

# test_provider_fallback_generic
P3="$TMP_ROOT/generic"; make_repo "$P3" 'provider: generic
base: main
work: dev'
out=$(bash "$RA" --root "$P3" open-pr 2>&1) || die test_provider_fallback_generic 'generic open-pr failed'
printf '%s' "$out" | grep -qi 'manually' || die test_provider_fallback_generic 'no fallback message'
pass test_provider_fallback_generic

# test_merge_policy_human_approve
P4="$TMP_ROOT/merge"; make_repo "$P4" 'provider: github
base: main
work: dev
mergePolicy: human-approve'
export STUBLOG="$P4.log"; : > "$STUBLOG"
PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 bash "$RA" --root "$P4" open-pr >/dev/null 2>&1 ||
  die test_merge_policy_human_approve 'open-pr failed'
grep -q 'pr merge' "$STUBLOG" && die test_merge_policy_human_approve 'merge invoked under human-approve'
pass test_merge_policy_human_approve

# test_head_override_rejected
PH="$TMP_ROOT/head"; make_repo "$PH" 'provider: github
base: main
work: dev'
export STUBLOG="$PH.log"; : > "$STUBLOG"
if PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 \
   bash "$RA" --root "$PH" --head alternate open-pr >"$PH.out" 2>&1; then
  die test_head_override_rejected 'head override was accepted'
fi
grep -q 'unknown argument --head' "$PH.out" ||
  die test_head_override_rejected 'no unknown-argument diagnostic'
[ ! -s "$STUBLOG" ] || die test_head_override_rejected 'provider was invoked'
pass test_head_override_rejected

printf 'remote-adapter selftest: all fixtures passed\n'
