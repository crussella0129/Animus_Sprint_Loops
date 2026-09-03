#!/usr/bin/env bash
# Atomically close the current Book sprint with explicit completion evidence.
# Usage: close-sprint.sh <success|failed> "<one-line completion evidence>"
set -euo pipefail

if [ "$#" -ne 2 ] || [ -z "$2" ]; then
  echo "usage: $(basename "$0") <success|failed> \"<one-line completion evidence>\"" >&2
  exit 1
fi
TARGET_STATUS=$1
EVIDENCE=$2
case "$TARGET_STATUS" in success|failed) : ;; *)
  echo "usage: $(basename "$0") <success|failed> \"<one-line completion evidence>\"" >&2
  exit 1
esac
case "$EVIDENCE" in
  *$'\n'*|*$'\r'*) echo "completion evidence must be one line" >&2; exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/book-paths.sh"
book_require_v2_layout
# Committed-evidence gate (contract 3), at entry. close-sprint writes and
# commits the sprint metadata itself, so a check placed after that write would
# always see its own change and always fail.
if book_gates_active; then
  if ! CLOSE_TRACKED_OUT=$(bash "$SCRIPT_DIR/check-tracked.sh" 2>&1); then
    echo "refusing to close: commit the Book before closing the sprint" >&2
    printf '%s\n' "$CLOSE_TRACKED_OUT" >&2
    exit 1
  fi
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
      printf 'refusing to close: HEAD is %s but the remote profile names %s as the work branch\n' "$CURRENT_BRANCH" "$EXPECTED_BRANCH" >&2
      printf '  switch to %s before writing sprint state\n' "$EXPECTED_BRANCH" >&2
      exit 1
    fi
  fi
fi

N=$("$SCRIPT_DIR/current-sprint.sh")
if [ "$N" = -1 ]; then echo "no sprint to close" >&2; exit 1; fi
META="$BOOK_SPRINTS_DIR/s$N/sprint-meta.md"
if [ ! -s "$META" ]; then echo "missing or empty $META" >&2; exit 1; fi

STATUS=$(awk '
  /^- \*\*Exit status:\*\*/ {
    line=$0; sub(/\r$/, "", line)
    sub(/^.*Exit status:\*\*[[:space:]]*/, "", line); print line; exit
  }
' "$META")
case "$STATUS" in
  "$TARGET_STATUS")
    echo "Sprint $N is already closed with status $STATUS; no Book artifact was rewritten."
    exit 0
    ;;
  success|failed|aborted)
    echo "refusing to close sprint $N as $TARGET_STATUS: it is already $STATUS" >&2
    exit 1
    ;;
  in-progress|'') : ;;
  *) echo "refusing to close sprint $N: malformed Exit status '$STATUS'" >&2; exit 1 ;;
esac

PHASE=$("$SCRIPT_DIR/current-phase.sh")
if [ "$PHASE" != loop ]; then
  echo "refusing to close sprint $N: current phase is $PHASE; Loop evidence is required" >&2
  exit 1
fi

FAILURE_REPORT="$BOOK_SPRINTS_DIR/s$N/failure-report.md"
TEST_REPORT="$BOOK_SPRINTS_DIR/s$N/sprint-tests/test-report.md"
TEST_CRITIQUE="$BOOK_SPRINTS_DIR/s$N/sprint-tests/critique.md"
case "$TARGET_STATUS" in
  success)
    if [ -s "$FAILURE_REPORT" ] || [ ! -s "$TEST_REPORT" ] || [ ! -s "$TEST_CRITIQUE" ]; then
      echo "refusing to close sprint $N as success: passing test report and critique are required, with no failure report" >&2
      exit 1
    fi
    ;;
  failed)
    if [ ! -s "$FAILURE_REPORT" ]; then
      echo "refusing to close sprint $N as failed: a non-empty failure report is required" >&2
      exit 1
    fi
    ;;
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
SPRINT_LOOP_CLOSE_EVIDENCE=$EVIDENCE
export SPRINT_LOOP_CLOSE_EVIDENCE
awk -v ts="$TS" -v status="$TARGET_STATUS" '
  BEGIN { evidence=ENVIRON["SPRINT_LOOP_CLOSE_EVIDENCE"] }
  {
    if (NR == 1) {
      if (sub(/\r$/, "", $0)) ORS="\r\n"
    } else {
      sub(/\r$/, "", $0)
    }
  }
  /^- \*\*End timestamp:\*\*/ && !end_done {
    print "- **End timestamp:** " ts; end_done=1; next
  }
  /^- \*\*Exit status:\*\*/ && !status_done {
    print "- **Exit status:** " status; status_done=1; next
  }
  /^- \*\*Completion evidence:\*\*/ && !evidence_done {
    print "- **Completion evidence:** " evidence; evidence_done=1; next
  }
  { print }
  END {
    # Legacy sprint-meta files did not carry every v2 field. Append only the
    # missing anchored fields rather than rewriting the rest of the artifact.
    if (!end_done) print "- **End timestamp:** " ts
    if (!status_done) print "- **Exit status:** " status
    if (!evidence_done) print "- **Completion evidence:** " evidence
  }
' "$META" > "$TMP"
unset SPRINT_LOOP_CLOSE_EVIDENCE
mv "$TMP" "$META"
trap - EXIT

if ! git add -- "$META"; then
  restore_after_git_failure
  echo "failed to stage close metadata; original Book and index restored" >&2
  exit 1
fi
if git diff --cached --quiet -- "$META"; then
  echo "Sprint $N closed as $TARGET_STATUS (no tracked metadata change to commit)."
else
  if ! git commit -m "sprint-$N: close ($TARGET_STATUS)" -- "$META"; then
    restore_after_git_failure
    echo "failed to commit close metadata; original Book and index restored" >&2
    exit 1
  fi
  echo "Sprint $N closed as $TARGET_STATUS."
fi
cleanup
trap - EXIT
