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

run_case() {  # $1 desc ; mutates $T then expects non-zero
  local desc="$1"; total=$((total+1))
  if "$GUARD_T" >/dev/null 2>&1; then
    echo "FAIL (false pass): $desc"
  else
    echo "PASS caught: $desc"; pass=$((pass+1))
  fi
}

mkfix() { # copy the real tree subset into a temp ROOT and point the guard at it
  T=$(mktemp -d)
  mkdir -p "$T/claude-code/skills/sprint-loop/phases" "$T/codex-cli/skills/sprint-loops/phases" "$T/open-harnesses/particles"
  cp "$ROOT/$LOOP" "$T/$LOOP"
  cp "$ROOT/codex-cli/skills/sprint-loops/phases/06-loop-phase.md" "$T/codex-cli/skills/sprint-loops/phases/06-loop-phase.md"
  cp "$ROOT/open-harnesses/particles/08-loop-phase.md" "$T/open-harnesses/particles/08-loop-phase.md"
  cp "$ROOT/$SK" "$T/$SK"
  cp "$ROOT/tools/check-merge-policy.sh" "$T/tools_guard.sh" 2>/dev/null || { mkdir -p "$T/tools"; cp "$ROOT/tools/check-merge-policy.sh" "$T/tools/check-merge-policy.sh"; }
  # guard resolves ROOT as its parent's parent; place a copy at $T/tools/
  mkdir -p "$T/tools"; cp "$ROOT/tools/check-merge-policy.sh" "$T/tools/check-merge-policy.sh"
  GUARD_T="bash $T/tools/check-merge-policy.sh"
}

# baseline good copy must pass
mkfix; total=$((total+1))
if $GUARD_T >/dev/null 2>&1; then echo "PASS baseline good copy passes"; pass=$((pass+1)); else echo "FAIL baseline good copy rejected"; fi

# bad 1: empty a loop doc
mkfix; : > "$T/$LOOP"; run_case "emptied loop doc"
# bad 2: reworded blanket prohibition (no literal 'gh pr merge', extra spaces)
mkfix; printf 'Always do  NOT  merge any PR in auto mode.\n' > "$T/$LOOP"; run_case "reworded blanket prohibition (token/whitespace dodge)"
# bad 3: SKILL reworded to revoke merge (strip the positive permit signal)
mkfix; sed -i 's/merging a green-CI PR whose effect is known-and-reversible/never merging anything/g; s/merging a green PR whose consequence is known and reversible/never merging/g' "$T/$SK"; run_case "SKILL reworded to revoke merge permission"

echo "fixture drift-test: $pass/$total caught"
[ "$pass" = "$total" ] && exit 0 || exit 1
