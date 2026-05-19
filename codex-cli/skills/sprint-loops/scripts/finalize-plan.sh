#!/usr/bin/env bash
# Prepend the lock header to build-plan.md and test-plan.md for the current sprint.
# Run this only after both plans are reviewed for local and global correctness.
set -euo pipefail

LAST=$(ls sprints/ 2>/dev/null | grep -E '^s[0-9]+$' | sed 's/^s//' | sort -n | tail -1 || true)
if [ -z "${LAST:-}" ]; then echo "no sprints found" >&2; exit 1; fi
D="sprints/s$LAST/sprint-plans"
HEADER="Finalized - DO NOT EDIT"

for f in build-plan.md test-plan.md; do
  P="$D/$f"
  if [ ! -s "$P" ]; then echo "missing or empty: $P" >&2; exit 1; fi
  if head -n1 "$P" | grep -qF "$HEADER"; then
    echo "$f already finalized"
  else
    { printf '%s\n\n' "$HEADER"; cat "$P"; } > "$P.tmp" && mv "$P.tmp" "$P"
    echo "finalized $f"
  fi
done
