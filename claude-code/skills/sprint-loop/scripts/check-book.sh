#!/usr/bin/env bash
# Validate the canonical Sprint Loops Book and intent lifecycle evidence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT="${1:-.}"
. "$SCRIPT_DIR/book-paths.sh"

fail() {
  printf 'check-book: %s\n' "$*" >&2
  exit 1
}

case "$(book_layout_state)" in
  conflict) fail "$BOOK_SPLIT_BRAIN_DIAGNOSTIC" ;;
  legacy-only) fail "$BOOK_LEGACY_ONLY_DIAGNOSTIC" ;;
  none) fail "$BOOK_UNINITIALIZED_DIAGNOSTIC" ;;
esac

book_marker_is_v2 || fail "$BOOK_MARKER_DIAGNOSTIC"
for required_dir in "$BOOK_INTENTS_DIR" "$BOOK_WORK_DIR" "$BOOK_SPRINTS_DIR"; do
  [ -d "$required_dir" ] || fail "invalid Book layout: missing directory $required_dir"
done

if [ -f "$BOOK_SUMMARY" ] && grep -qF '<!-- sprint-loop-intent-v2 -->' "$BOOK_SUMMARY"; then
  fail "$BOOK_SUMMARY is navigation only and must not contain intent metadata"
fi

TMP_BASE="${TMPDIR:-/tmp}/sprint-loop-book.$$"
LIST_FILE="$TMP_BASE.intents"
ID_FILE="$TMP_BASE.ids"
trap 'rm -f "$LIST_FILE" "$ID_FILE"' EXIT HUP INT TERM
: > "$ID_FILE"
find "$BOOK_INTENTS_DIR" -type f -name '*.md' ! -name README.md -print | LC_ALL=C sort > "$LIST_FILE"

field_value() {
  field_file=$1
  field_name=$2
  field_prefix="- **$field_name:** "
  field_count=$(grep -cF -- "$field_prefix" "$field_file" || true)
  [ "$field_count" -eq 1 ] || fail "expected exactly one '$field_name' field in $field_file"
  field_line=$(grep -F -- "$field_prefix" "$field_file")
  field_result=${field_line#"$field_prefix"}
  [ -n "$field_result" ] || fail "empty '$field_name' field in $field_file"
  printf '%s\n' "$field_result"
}

evidence_shape_is_valid() {
  [ "$1" = none ] || printf '%s\n' "$1" | grep -Eq '\[[^][]+\]\([^)]+\)'
}

intent_count=0
while IFS= read -r intent_file; do
  [ -n "$intent_file" ] || continue
  anchor_count=$(grep -cFx '<!-- sprint-loop-intent-v2 -->' "$intent_file" || true)
  [ "$anchor_count" -eq 1 ] || fail "expected exactly one intent-v2 metadata anchor in $intent_file"

  intent_id=$(field_value "$intent_file" 'Intent ID')
  state=$(field_value "$intent_file" State)
  work=$(field_value "$intent_file" 'Work evidence')
  completion=$(field_value "$intent_file" 'Completion evidence')
  code=$(field_value "$intent_file" 'Code evidence')
  test_evidence=$(field_value "$intent_file" 'Test evidence')
  documentation=$(field_value "$intent_file" 'Documentation evidence')

  case "$intent_id" in INT-[0-9][0-9][0-9][0-9]) ;; *) fail "invalid intent ID '$intent_id' in $intent_file; expected INT-NNNN" ;; esac
  previous=$(awk -F '|' -v id="$intent_id" '$1 == id { sub(/^[^|]*[|]/, ""); print; exit }' "$ID_FILE")
  [ -z "$previous" ] || fail "duplicate intent ID $intent_id: $previous and $intent_file"
  printf '%s|%s\n' "$intent_id" "$intent_file" >> "$ID_FILE"

  case "$state" in
    proposed|planned|active|deferred|realized|superseded|abandoned) ;;
    *) fail "invalid state '$state' for $intent_id in $intent_file; expected proposed|planned|active|deferred|realized|superseded|abandoned" ;;
  esac

  for evidence in "$work" "$completion" "$code" "$test_evidence" "$documentation"; do
    evidence_shape_is_valid "$evidence" || fail "invalid evidence value for $intent_id in $intent_file; expected none or Markdown link(s)"
  done

  case "$state" in
    planned|active|deferred)
      if [ "$work" = none ] || ! printf '%s\n' "$work" | grep -Eq 'T-[0-9]+|sprints/s[0-9]+/sprint-plans/(build-plan|test-plan)[.]md'; then
        fail "missing work evidence for $intent_id in $intent_file (state $state)"
      fi
      ;;
    realized)
      if [ "$completion" = none ] || ! printf '%s\n' "$completion" | grep -Eq 'T-[0-9]+' || ! printf '%s\n' "$completion" | grep -q 'completed-tasks[.]md'; then
        fail "missing completion evidence for $intent_id in $intent_file (state realized)"
      fi
      if { [ "$code" = none ] || ! evidence_shape_is_valid "$code"; } &&
         { [ "$test_evidence" = none ] || ! evidence_shape_is_valid "$test_evidence"; } &&
         { [ "$documentation" = none ] || ! evidence_shape_is_valid "$documentation"; }; then
        fail "missing realization evidence for $intent_id in $intent_file (state realized); add code, test, or documentation evidence"
      fi
      ;;
  esac
  intent_count=$((intent_count + 1))
done < "$LIST_FILE"

printf 'check-book: valid v2 Book (%s intent chapters)\n' "$intent_count"
