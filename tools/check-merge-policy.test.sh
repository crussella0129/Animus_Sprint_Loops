#!/usr/bin/env bash
# Fixture test for check-merge-policy.sh — proves the guard catches drift.
# Builds a throwaway copy of the four docs, mutates them into known-bad
# states, and asserts the guard exits non-zero. Never touches tracked files.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/tools/check-merge-policy.sh"
pass=0; total=0
LOOP="claude-code/skills/sprint-loop/phases/06-loop-phase.md"
SK="claude-code/skills/sprint-loop/SKILL.md"

# Track every fixture temp dir and remove ALL of them on exit (even on error).
# Without this, each mkfix leaked a temp dir containing a sprint-loop skill copy.
TMPDIRS=()
cleanup() { for d in "${TMPDIRS[@]:-}"; do [ -n "$d" ] && rm -rf "$d"; done; }
trap cleanup EXIT

run_case() {  # $1 desc ; mutates $T then expects non-zero
  local desc="$1"; total=$((total+1))
  # NOTE: invoke as `bash "$GUARD_T"` (path variable), never a quoted
  # "cmd + args" string — the original `"$GUARD_T"` with GUARD_T="bash /path"
  # was exit-127 command-not-found, making every drift case pass vacuously.
  if bash "$GUARD_T" >/dev/null 2>&1; then
    echo "FAIL (false pass): $desc"
  else
    echo "PASS caught: $desc"; pass=$((pass+1))
  fi
}

mkfix() { # copy the real tree subset into a temp ROOT and point the guard at it
  T=$(mktemp -d)
  TMPDIRS+=("$T")
  mkdir -p "$T/claude-code/skills/sprint-loop/phases" "$T/codex-cli/skills/sprint-loops/phases" "$T/open-harnesses/particles"
  cp "$ROOT/$LOOP" "$T/$LOOP"
  cp "$ROOT/codex-cli/skills/sprint-loops/phases/06-loop-phase.md" "$T/codex-cli/skills/sprint-loops/phases/06-loop-phase.md"
  cp "$ROOT/open-harnesses/particles/08-loop-phase.md" "$T/open-harnesses/particles/08-loop-phase.md"
  cp "$ROOT/$SK" "$T/$SK"
  # guard resolves ROOT as its parent's parent; place a copy at $T/tools/
  mkdir -p "$T/tools"; cp "$GUARD" "$T/tools/check-merge-policy.sh"
  GUARD_T="$T/tools/check-merge-policy.sh"
}

# baseline good copy must pass
mkfix; total=$((total+1))
if bash "$GUARD_T" >/dev/null 2>&1; then echo "PASS baseline good copy passes"; pass=$((pass+1)); else echo "FAIL baseline good copy rejected"; fi

# bad 1: empty a loop doc
mkfix; : > "$T/$LOOP"; run_case "emptied loop doc"
# bad 2: reworded blanket prohibition (no literal 'gh pr merge', extra spaces)
mkfix; printf 'Always do  NOT  merge any PR in auto mode.\n' > "$T/$LOOP"; run_case "reworded blanket prohibition (token/whitespace dodge)"
# bad 3: SKILL reworded to revoke merge (strip the positive permit signal).
# Delete every line mentioning "green" rather than s///-ing exact phrases:
# the doc is hard-wrapped, so a phrase-level substitution can span lines and
# silently no-op, leaving the permit intact (observed once this test stopped
# being vacuous — see run_case NOTE).
# (grep -iv replaces GNU sed's `-i` + `I` flag — BSD-safe case-insensitive
# line deletion; `|| true` because grep -v exits 1 if nothing survives.)
mkfix; { grep -iv 'green' "$T/$SK" || true; } > "$T/skill.tmp" && mv "$T/skill.tmp" "$T/$SK"; run_case "SKILL reworded to revoke merge permission"

echo "fixture drift-test: $pass/$total caught"
[ "$pass" = "$total" ] && exit 0 || exit 1
