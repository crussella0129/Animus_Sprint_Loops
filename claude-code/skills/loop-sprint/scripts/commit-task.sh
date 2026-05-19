#!/usr/bin/env bash
# Commit a completed task as a clean commit boundary.
# Usage: commit-task.sh <task-id> <description>
# Run from the project root. Sibling scripts are resolved relative to this file, so
# this works whether scripts/ lives in the project or in an installed skill bundle.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
N=$("$SCRIPT_DIR/current-sprint.sh")
git add -A
git commit -m "sprint-$N: $1 $2"
