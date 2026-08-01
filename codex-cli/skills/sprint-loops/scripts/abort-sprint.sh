#!/usr/bin/env bash
# Mark the current Book sprint as aborted and close it out cleanly.
# Usage: abort-sprint.sh "<one-line reason>"
set -euo pipefail

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo "usage: $(basename "$0") \"<one-line reason>\"" >&2
  exit 1
fi
REASON=$1
case "$REASON" in
  *$'\n'*|*$'\r'*) echo "abort reason must be one line" >&2; exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/book-paths.sh"
book_require_v2_layout

N=$("$SCRIPT_DIR/current-sprint.sh")
if [ "$N" = -1 ]; then
  echo "no sprint to abort (run init-sprint.sh first)" >&2
  exit 1
fi
META="$BOOK_SPRINTS_DIR/s$N/sprint-meta.md"
if [ ! -s "$META" ]; then
  echo "missing or empty $META" >&2
  exit 1
fi

STATUS=$(awk '
  /^- \*\*Exit status:\*\*/ {
    line=$0; sub(/\r$/, "", line)
    sub(/^.*Exit status:\*\*[[:space:]]*/, "", line); print line; exit
  }
' "$META")
case "$STATUS" in
  aborted) echo "Sprint $N is already aborted; no Book artifact was rewritten."; exit 0 ;;
  success|failed)
    echo "refusing to abort sprint $N: it is already closed with status $STATUS" >&2
    exit 1
    ;;
  in-progress|'') : ;;
  *) echo "refusing to abort sprint $N: malformed Exit status '$STATUS'" >&2; exit 1 ;;
esac

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TMP="$META.tmp.$$"
META_BACKUP="$META.rollback.$$"
INDEX_PATH=$(git rev-parse --git-path index)
INDEX_BACKUP="$INDEX_PATH.sprint-loop.$$"
INDEX_EXISTED=0
cp -p "$META" "$META_BACKUP"
if [ -f "$INDEX_PATH" ]; then
  cp -p "$INDEX_PATH" "$INDEX_BACKUP"
  INDEX_EXISTED=1
fi
cleanup() { rm -f "$TMP" "$META_BACKUP" "$INDEX_BACKUP"; }
restore_after_git_failure() {
  cp -p "$META_BACKUP" "$META"
  if [ "$INDEX_EXISTED" -eq 1 ]; then
    cp -p "$INDEX_BACKUP" "$INDEX_PATH"
  else
    rm -f "$INDEX_PATH"
  fi
}
trap cleanup EXIT
SPRINT_LOOP_ABORT_REASON=$REASON
export SPRINT_LOOP_ABORT_REASON
awk -v ts="$TS" '
  BEGIN { reason=ENVIRON["SPRINT_LOOP_ABORT_REASON"] }
  {
    if (NR == 1) {
      if (sub(/\r$/, "", $0)) ORS="\r\n"
    } else {
      sub(/\r$/, "", $0)
    }
  }
  /^- \*\*Exit status:\*\*/ && !status_done {
    print "- **Exit status:** aborted"; status_done=1; next
  }
  /^- \*\*End timestamp:\*\*/ && !end_done {
    print "- **End timestamp:** " ts; end_done=1; next
  }
  { print }
  END {
    if (!end_done) print "- **End timestamp:** " ts
    if (!status_done) print "- **Exit status:** aborted"
    print ""
    print "## Abort note (" ts ")"
    print reason
  }
' "$META" > "$TMP"
unset SPRINT_LOOP_ABORT_REASON
mv "$TMP" "$META"
trap - EXIT

# Commit only the Book meta artifact. Unrelated staged or working-tree changes
# remain outside this close-out boundary.
if ! git add -- "$META"; then
  restore_after_git_failure
  echo "failed to stage abort metadata; original Book and index restored" >&2
  exit 1
fi
if git diff --cached --quiet -- "$META"; then
  echo "Sprint $N marked aborted (no tracked metadata change to commit)."
else
  if ! git commit -m "sprint-$N: aborted — $REASON" -- "$META"; then
    restore_after_git_failure
    echo "failed to commit abort metadata; original Book and index restored" >&2
    exit 1
  fi
  echo "Sprint $N marked aborted."
fi
cleanup
trap - EXIT
