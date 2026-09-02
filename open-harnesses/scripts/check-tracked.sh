#!/usr/bin/env bash
# Assert the Book carries no uncommitted state: nothing under the Book root is
# untracked, and no tracked Book file has working-tree modifications.
#
# The phase contracts define Exit evidence as artifacts existing. Under "the
# filesystem is the state machine" an untracked file is indistinguishable from a
# committed one, so every phase can otherwise pass with the whole Book
# uncommitted and the work never recorded. This helper is the gate that makes
# "exists" mean "exists in the corpus".
#
# Read-only. Usage: check-tracked.sh [--root <dir>]
# Exit 0 when the Book is clean, or when the project is not a git repository —
# a project without version control has no notion of tracked state, and the gate
# is inapplicable rather than failed.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT="${SPRINT_LOOP_PROJECT_ROOT:-.}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) SPRINT_LOOP_PROJECT_ROOT="$2"; shift 2 ;;
    *) echo "check-tracked: unknown argument $1" >&2; exit 2 ;;
  esac
done
. "$SCRIPT_DIR/book-paths.sh"
ROOT="$SPRINT_LOOP_PROJECT_ROOT"

git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || exit 0
[ -d "$BOOK_ROOT" ] || exit 0

# One porcelain pass reports both classes: '??' for untracked, ' M' and friends
# for modified tracked files. Every offender is listed, so one run tells the
# operator the whole remedy rather than the first step of it.
offenders=$(git -C "$ROOT" status --porcelain --untracked-files=all -- docs 2>/dev/null)

if [ -z "$offenders" ]; then
  echo "check-tracked: Book is fully committed"
  exit 0
fi

echo "check-tracked: the Book has uncommitted state; commit it before this phase exit" >&2
printf '%s\n' "$offenders" | while IFS= read -r offender_line; do
  [ -n "$offender_line" ] || continue
  printf '  %s\n' "$offender_line" >&2
done
exit 1
