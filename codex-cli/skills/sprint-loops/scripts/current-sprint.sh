#!/usr/bin/env bash
# Print the current (highest-numbered) sprint number, or -1 if uninitialized.
# This is the single source of the sprint-number computation — sibling scripts
# call it rather than re-deriving the answer.
set -euo pipefail
n=-1
for d in sprints/s*/; do
  [ -d "$d" ] || continue
  b="${d#sprints/s}"; b="${b%/}"
  case "$b" in ''|*[!0-9]*) continue ;; esac
  if [ "$b" -gt "$n" ]; then n="$b"; fi
done
echo "$n"
