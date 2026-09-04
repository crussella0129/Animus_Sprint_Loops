#!/usr/bin/env bash
# Commit explicitly scoped task paths, then durably record their commit.
# Usage: commit-task.sh <task-id> <description...> -- <path> [path...]
set -euo pipefail

if [ "$#" -lt 4 ]; then
  echo "usage: $(basename "$0") <task-id> <description...> -- <path> [path...]" >&2
  exit 1
fi
TASK_ID=$1
shift
DESCRIPTION=
while [ "$#" -gt 0 ] && [ "$1" != -- ]; do
  if [ -n "$DESCRIPTION" ]; then DESCRIPTION="$DESCRIPTION $1"; else DESCRIPTION=$1; fi
  shift
done
if [ -z "$DESCRIPTION" ] || [ "$#" -eq 0 ] || [ "$1" != -- ]; then
  echo "usage: $(basename "$0") <task-id> <description...> -- <path> [path...]" >&2
  exit 1
fi
shift
if [ "$#" -eq 0 ]; then
  echo "commit-task requires at least one explicit task path after --" >&2
  exit 1
fi
TASK_PATHS=("$@")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/book-paths.sh"
book_require_v2_layout
N=$("$SCRIPT_DIR/current-sprint.sh")
if [ "$N" = -1 ]; then echo "no sprint found" >&2; exit 1; fi

F=$BOOK_COMPLETED_TASKS_FILE
if [ ! -f "$F" ] || ! awk '
  { sub(/\r$/, "", $0) }
  $0 == "- **Commit:** PENDING" { found=1 }
  END { exit !found }
' "$F"; then
  echo "refusing to commit $TASK_ID: $F has no exact pending commit evidence entry" >&2
  exit 1
fi

# Work-branch guard (contract 3). A sprint executed on the base branch is
# otherwise only discovered at checkpoint time, when the whole sprint is already
# there. Refuse before anything is staged. A project with no resolvable remote
# profile is a legitimate configuration and is left alone.
if book_gates_active; then
  if BRANCH_PROFILE=$(bash "$SCRIPT_DIR/remote-profile.sh" 2>/dev/null); then
    EXPECTED_BRANCH=$(printf '%s\n' "$BRANCH_PROFILE" | sed -n 's/^WORK=//p')
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)
    if [ -n "$EXPECTED_BRANCH" ] && [ "$CURRENT_BRANCH" != "$EXPECTED_BRANCH" ]; then
      printf 'refusing to commit %s: HEAD is %s but the remote profile names %s as the work branch\n' "$TASK_ID" "$CURRENT_BRANCH" "$EXPECTED_BRANCH" >&2
      printf '  switch to %s before writing sprint state\n' "$EXPECTED_BRANCH" >&2
      exit 1
    fi
  fi
fi

# Scope both staging and committing. Unrelated staged and working-tree changes
# remain outside this task boundary.
COMMIT_PATHS=("${TASK_PATHS[@]}" "$BOOK_TASKS_FILE" "$BOOK_COMPLETED_TASKS_FILE")
git add -A -- "${COMMIT_PATHS[@]}"
git commit -m "sprint-$N: $TASK_ID $DESCRIPTION" -- "${COMMIT_PATHS[@]}"
HASH=$(git rev-parse HEAD)

# The ledger edit is intentionally exact and first-match-only. Prose that
# merely mentions PENDING and later task entries remain untouched.
TMP="$F.tmp.$$"
trap 'rm -f "$TMP"' EXIT
# awk cannot observe a trailing carriage return on every supported host, so
# the line-ending decision is made by the shared primitive and handed in.
# Detecting it inside awk silently rewrote CRLF Book files as LF.
if book_first_line_is_crlf "$F"; then _crlf=1; else _crlf=0; fi
awk -v crlf="$_crlf" -v h="$HASH" '
  BEGIN { if (crlf) ORS="\r\n" }
  {
    sub(/\r$/, "", $0)
  }
  !done && $0 == "- **Commit:** PENDING" {
    $0 = "- **Commit:** `" h "`"; done=1
  }
  { print }
' "$F" > "$TMP"
mv "$TMP" "$F"
trap - EXIT
git add -- "$F"
git commit -m "sprint-$N: $TASK_ID record commit evidence" -- "$F"

# The task commit is now an ancestor of the evidence commit, so a normal clone
# retains and resolves the recorded object without relying on a reflog.
if ! git cat-file -e "$HASH^{commit}"; then
  echo "commit evidence $HASH is not resolvable after recording" >&2
  exit 1
fi
