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

# Back-fill: if `completed-tasks.md` has a fully-anchored placeholder line
# `- **Commit:** PENDING`, replace the FIRST such line with the just-committed
# short hash and fold the edit into the same commit via amend.
#
# Line-anchoring (`^...$`) prevents false positives — earlier versions matched
# the substring inside other entries' description text, corrupting them.
#
# Known quirk (intentional): the embedded hash is the PRE-amend hash. The
# amend (which folds the back-fill itself into the commit) produces a new
# HEAD with a different SHA. The embedded hash thus refers to a commit that
# was rewritten by the amend; you can find the actual commit via
# `git log --grep "sprint-N: T-XXX"` (commit messages are stable). Trying to
# embed the post-amend hash requires either two amends (which produce a
# THIRD hash) or a second commit (violates one-commit-per-task). The
# pre-amend hash is the simplest stable identifier under the constraints.
F="agent-tasks/completed-tasks.md"
if [ -f "$F" ] && grep -qE '^- \*\*Commit:\*\* PENDING$' "$F"; then
  HASH=$(git rev-parse --short HEAD)
  sed -i "0,/^- \\*\\*Commit:\\*\\* PENDING$/{s|^- \\*\\*Commit:\\*\\* PENDING\$|- **Commit:** \`$HASH\`|}" "$F"
  git add "$F"
  git commit --amend --no-edit --quiet
fi
