#!/usr/bin/env bash
# Durable consistency guard for the auto-mode merge policy (sprint 8; addresses
# the sprint-7 C-004 contradiction class). Re-runnable on every change — wire
# into CI.
#
# Robust by POSITIVE assertion (a contradictory/blanket/emptied doc FAILS by
# lacking the required signals — not by matching a banned literal, which is
# trivially reworded around). Whitespace-normalized so multi-space/newline
# dodges don't slip through.
#
# Each Loop-Phase merge doc MUST contain:
#   (1) an autonomy signal — merge "proceeds autonomously" on green CI, AND
#   (2) a checkpoint-exception signal — stop/surface for an unverifiable or
#       undeterminable consequence.
# SKILL.md MUST contain the human-verification stop criterion AND positively
# permit merging a green PR (so a reworded "never merges" blanket fails).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

norm() { tr '\n' ' ' < "$1" | tr -s '[:space:]' ' '; }

check_loop_doc() {
  local f="$1" n
  [ -f "$ROOT/$f" ] || { echo "missing: $f" >&2; return 1; }
  n="$(norm "$ROOT/$f")"
  printf '%s' "$n" | grep -qi "proceeds autonomously" \
    || { echo "INCONSISTENT: $f lacks the merge-proceeds-autonomously signal" >&2; return 1; }
  printf '%s' "$n" | grep -qiE "unverifiable|undeterminable|blast radius|leave the PR open|stop and surface" \
    || { echo "INCONSISTENT: $f lacks the checkpoint-exception signal" >&2; return 1; }
}

for f in \
  "claude-code/skills/sprint-loop/phases/06-loop-phase.md" \
  "codex-cli/skills/sprint-loops/phases/06-loop-phase.md" \
  "open-harnesses/particles/08-loop-phase.md"; do
  check_loop_doc "$f" || fail=1
done

SK="claude-code/skills/sprint-loop/SKILL.md"
if [ -f "$ROOT/$SK" ]; then
  n="$(norm "$ROOT/$SK")"
  printf '%s' "$n" | grep -qiE "halt only at .*human-verification|human-verification checkpoint" \
    || { echo "INCONSISTENT: $SK lacks the human-verification stop criterion" >&2; fail=1; }
  printf '%s' "$n" | grep -qiE "merging a green( -CI)? PR|merge a green PR" \
    || { echo "INCONSISTENT: $SK does not positively permit merging a green PR (reworded blanket?)" >&2; fail=1; }
else
  echo "missing: $SK" >&2; fail=1
fi

if [ "$fail" = "0" ]; then echo "merge-policy consistent across all docs"; exit 0; else exit 1; fi
