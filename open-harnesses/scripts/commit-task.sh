#!/usr/bin/env bash
# Commit a completed task as a clean commit boundary.
# Usage: commit-task.sh <task-id> <description>
set -euo pipefail
N=$(./scripts/current-sprint.sh)
git add -A
git commit -m "sprint-$N: $1 $2"
