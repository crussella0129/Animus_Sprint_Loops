#!/usr/bin/env bash
# Commit a completed task as a clean commit boundary, and back-fill the new
# commit's short hash into agent-tasks/completed-tasks.md if the agent left a
# `Commit:** PENDING` placeholder there.
# Usage: commit-task.sh <task-id> <description>
# Run from the project root. Sibling scripts are resolved relative to this file, so
# this works whether scripts/ lives in the project or in an installed skill bundle.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
N=$("$SCRIPT_DIR/current-sprint.sh")
git add -A
git commit -m "sprint-$N: $1 $2"

# Back-fill: if the agent wrote `Commit:** PENDING` in completed-tasks.md,
# replace the FIRST occurrence with the new commit's short hash and fold the
# edit into the same commit via amend. No-op if no PENDING placeholder exists,
# so this is back-compat with entries the agent filled by hand.
F="agent-tasks/completed-tasks.md"
if [ -f "$F" ] && grep -q "Commit:\*\* PENDING" "$F"; then
  HASH=$(git rev-parse --short HEAD)
  sed -i "0,/Commit:\*\* PENDING/{s|Commit:\*\* PENDING|Commit:** \`$HASH\`|}" "$F"
  git add "$F"
  git commit --amend --no-edit --quiet
fi
