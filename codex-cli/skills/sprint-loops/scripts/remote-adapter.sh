#!/usr/bin/env bash
# Provider-agnostic sprint checkpoint adapter. Opens exactly one work->base
# PR/MR via the declared remote profile (github->gh, gitlab->glab), or falls
# back to pushing work and printing the compare URL. Never merges — merging is
# the human-approve boundary.
#
# At contract version 3 and above the checkpoint is gated on a closed sprint and
# its title is composed from the Book, because a checkpoint opened mid-sprint is
# the visible symptom of a turn that ended early, and an uninformative title
# makes the checkpoint list — a project's most-read index — index nothing.
#
# Usage:
#   remote-adapter.sh [--root D] pr-exists              # exit 0 if an open PR/MR exists
#   remote-adapter.sh [--root D] open-pr [--title T] [--body B]
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT="${SPRINT_LOOP_PROJECT_ROOT:-.}"
TITLE=""; BODY=""; ACTION=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) SPRINT_LOOP_PROJECT_ROOT="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --body) BODY="$2"; shift 2 ;;
    pr-exists|open-pr) ACTION="$1"; shift ;;
    *) echo "remote-adapter: unknown argument $1" >&2; exit 2 ;;
  esac
done
. "$SCRIPT_DIR/book-paths.sh"
ROOT="$SPRINT_LOOP_PROJECT_ROOT"
[ -n "$ACTION" ] || { echo "remote-adapter: expected pr-exists|open-pr" >&2; exit 2; }

prof=$(bash "$SCRIPT_DIR/remote-profile.sh" --root "$ROOT") ||
  { echo "remote-adapter: no resolvable remote profile" >&2; exit 1; }
provider=$(printf '%s\n' "$prof" | sed -n 's/^PROVIDER=//p')
base=$(printf '%s\n' "$prof" | sed -n 's/^BASE=//p')
work=$(printf '%s\n' "$prof" | sed -n 's/^WORK=//p')

SPRINT_N=-1
SPRINT_META=""

book_phase() {
  SPRINT_LOOP_PROJECT_ROOT="$ROOT" bash "$SCRIPT_DIR/current-phase.sh" 2>/dev/null || echo unknown
}

resolve_sprint() {
  SPRINT_N=$(SPRINT_LOOP_PROJECT_ROOT="$ROOT" bash "$SCRIPT_DIR/current-sprint.sh" 2>/dev/null || echo -1)
  [ "$SPRINT_N" != -1 ] || return 1
  SPRINT_META="$BOOK_SPRINTS_DIR/s$SPRINT_N/sprint-meta.md"
  [ -s "$SPRINT_META" ]
}

# Read one anchored sprint-meta field by exact prefix.
meta_field() {
  awk -v prefix="- **$1:** " '
    { line=$0; sub(/\r$/, "", line) }
    substr(line, 1, length(prefix)) == prefix {
      print substr(line, length(prefix) + 1); exit
    }
  ' "$SPRINT_META"
}

# The checkpoint title is Book-derived, not free text: Sprint <N>: <Summary>.
compose_title() {
  local summary
  summary=$(meta_field Summary)
  case "$summary" in
    ''|'(one-line'*)
      printf 'remote-adapter: sprint %s has no Summary; the checkpoint title is composed from it\n' "$SPRINT_N" >&2
      printf '  fill the Summary field in %s before opening the checkpoint\n' "$SPRINT_META" >&2
      return 1 ;;
  esac
  printf 'Sprint %s: %s' "$SPRINT_N" "$summary"
}

# Record the checkpoint in the sprint record and commit it. open-pr runs after
# close-sprint has committed, so an uncommitted write here would leave the Book
# dirty for the next sprint's committed-evidence gate to trip on.
record_checkpoint() {
  local url=$1 tmp _crlf
  [ -n "$url" ] || return 0
  [ -s "$SPRINT_META" ] || return 0
  grep -qF -- '- **Checkpoint:**' "$SPRINT_META" && return 0
  tmp="$SPRINT_META.checkpoint.$$"
  # awk cannot observe a trailing carriage return on every supported host, so
  # the line-ending decision is made by the shared primitive and handed in.
  # Detecting it inside awk silently rewrote CRLF Book files as LF.
  if book_first_line_is_crlf "$SPRINT_META"; then _crlf=1; else _crlf=0; fi
  CHECKPOINT_URL=$url awk -v crlf="$_crlf" '
    BEGIN { url=ENVIRON["CHECKPOINT_URL"]; if (crlf) ORS="\r\n" }
    {
      sub(/\r$/, "", $0)
      print
    }
    /^- \*\*Completion evidence:\*\*/ && !done {
      print "- **Checkpoint:** " url; done=1
    }
    END { if (!done) print "- **Checkpoint:** " url }
  ' "$SPRINT_META" > "$tmp" || { rm -f "$tmp"; return 0; }
  mv "$tmp" "$SPRINT_META" || return 0
  git -C "$ROOT" add -- "$SPRINT_META" >/dev/null 2>&1 || return 0
  git -C "$ROOT" commit -q -m "sprint-$SPRINT_N: record checkpoint" -- "$SPRINT_META" >/dev/null 2>&1 || return 0
}

pr_exists() {
  case "$provider" in
    github)
      command -v gh >/dev/null 2>&1 || return 1
      [ -n "$(gh pr list --head "$work" --base "$base" --state open --json number --jq '.[].number' 2>/dev/null)" ] ;;
    gitlab)
      command -v glab >/dev/null 2>&1 || return 1
      glab mr list --source-branch "$work" --target-branch "$base" --state opened 2>/dev/null | grep -q '!' ;;
    *) return 1 ;;
  esac
}

compare_url() {
  if url=$(git -C "$ROOT" remote get-url origin 2>/dev/null) && [ -n "$url" ]; then
    printf '%s (compare %s...%s)' "$url" "$base" "$work"
  else
    printf '(no origin remote configured)'
  fi
}

open_pr() {
  local created=""
  [ -n "$TITLE" ] || TITLE="Sprint checkpoint: $work -> $base"
  [ -n "$BODY" ] || BODY="Sprint checkpoint from $work to $base."
  git -C "$ROOT" push -q -u origin "$work" 2>/dev/null || true
  case "$provider" in
    github)
      if command -v gh >/dev/null 2>&1; then
        if created=$( cd "$ROOT" && gh pr create --head "$work" --base "$base" --title "$TITLE" --body "$BODY" ); then
          printf '%s\n' "$created"
          record_checkpoint "$created"
          return 0
        fi
      fi ;;
    gitlab)
      if command -v glab >/dev/null 2>&1; then
        if created=$( cd "$ROOT" && glab mr create --source-branch "$work" --target-branch "$base" --title "$TITLE" --description "$BODY" ); then
          printf '%s\n' "$created"
          record_checkpoint "$created"
          return 0
        fi
      fi ;;
  esac
  printf 'remote-adapter: pushed %s; open a %s -> %s PR/MR manually: %s\n' "$work" "$work" "$base" "$(compare_url)"
  return 0
}

case "$ACTION" in
  pr-exists) pr_exists ;;
  open-pr)
    # Checkpoint gate (contract 3): a checkpoint is the boundary of a finished
    # sprint, so it is refused while one is still open. current-phase.sh reports
    # ready-for-next-sprint exactly when the sprint metadata carries a terminal
    # Exit status, so this one call is the whole condition. An aborted sprint
    # reaches that state too, and may checkpoint: abandoned work still needs a
    # reversible boundary.
    if book_gates_active; then
      phase=$(book_phase)
      if [ "$phase" != ready-for-next-sprint ]; then
        printf 'remote-adapter: refusing to open a checkpoint while the sprint is open (phase: %s)\n' "$phase" >&2
        echo '  close the sprint first; a checkpoint is the boundary of a finished sprint' >&2
        exit 1
      fi
      if ! resolve_sprint; then
        echo 'remote-adapter: no sprint record to checkpoint' >&2
        exit 1
      fi
      if [ -n "$TITLE" ]; then
        printf '%s\n' "$TITLE" | grep -Eq '^Sprint [0-9]+: .+' || {
          printf 'remote-adapter: refusing the supplied title %s\n' "\"$TITLE\"" >&2
          echo '  a checkpoint title must read: Sprint <N>: <description>' >&2
          exit 1
        }
      else
        TITLE=$(compose_title) || exit 1
      fi
      [ -n "$BODY" ] || BODY="Sprint $SPRINT_N checkpoint. Record: docs/sprints/s$SPRINT_N/sprint-meta.md"
    fi
    if [ "$provider" = local-only ]; then
      echo "remote-adapter: local-only profile; no PR/MR opened"; exit 0
    fi
    if pr_exists; then
      echo "remote-adapter: an open $work -> $base PR/MR already exists; not opening a second"; exit 0
    fi
    open_pr ;;
esac
