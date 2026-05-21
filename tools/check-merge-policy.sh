#!/usr/bin/env bash
# Durable consistency guard for the auto-mode merge policy (sprint 8, addresses
# the sprint-7 C-004 contradiction class). Re-runnable on every change — wire
# into CI. Asserts that across the merge-policy docs:
#   - claude-code/skills/sprint-loop/phases/06-loop-phase.md
#   - codex-cli/skills/sprint-loops/phases/06-loop-phase.md
#   - open-harnesses/particles/08-loop-phase.md
#   - claude-code/skills/sprint-loop/SKILL.md
# the policy is CONSISTENT: every file that gives merge guidance also carries
# the checkpoint qualifier (stop/surface for unverifiable/undeterminable
# consequence), and NO file retains a blanket "do NOT merge" (the old
# sprint-7 wording this sprint reverses).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILES=(
  "claude-code/skills/sprint-loop/phases/06-loop-phase.md"
  "codex-cli/skills/sprint-loops/phases/06-loop-phase.md"
  "open-harnesses/particles/08-loop-phase.md"
)
fail=0
for f in "${FILES[@]}"; do
  p="$ROOT/$f"
  if [ ! -f "$p" ]; then echo "missing: $f" >&2; fail=1; continue; fi
  if grep -qi "gh pr merge" "$p"; then
    # must also carry a checkpoint qualifier near the merge guidance
    if ! grep -qiE "unverifiable|undeterminable|blast radius|surface|leave the PR open" "$p"; then
      echo "INCONSISTENT: $f gives merge guidance without a checkpoint qualifier" >&2; fail=1
    fi
    # must NOT retain the old blanket prohibition
    if grep -qi "do NOT merge" "$p"; then
      echo "STALE: $f still contains a blanket 'do NOT merge' (sprint-7 wording this sprint reverses)" >&2; fail=1
    fi
  fi
done
# SKILL.md must agree: it must NOT say auto mode never merges, and must carry the stop criterion
SK="$ROOT/claude-code/skills/sprint-loop/SKILL.md"
if grep -qi "does \*\*not\*\* merge a PR to a base branch" "$SK"; then
  echo "INCONSISTENT: SKILL.md still says auto mode does not merge (contradicts 06-loop-phase merge-on-green)" >&2; fail=1
fi
if ! grep -qiE "halt only at|human-verification checkpoint|cannot verify" "$SK"; then
  echo "INCONSISTENT: SKILL.md lacks the human-verification stop criterion" >&2; fail=1
fi

if [ "$fail" = "0" ]; then echo "merge-policy consistent across all docs"; exit 0; else exit 1; fi
