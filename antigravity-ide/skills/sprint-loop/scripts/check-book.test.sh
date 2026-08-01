#!/usr/bin/env bash
# Focused fixtures for the Book v2 path contract and intent validator.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/check-book.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-book-test.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM

pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

make_book() {
  fixture=$1
  mkdir -p "$fixture/docs/intents" "$fixture/docs/work" "$fixture/docs/sprints"
  printf 'schema-version: 2\n' > "$fixture/docs/.sprint-loop-book"
  printf '# Project Book\n' > "$fixture/docs/README.md"
  printf '# Summary\n' > "$fixture/docs/SUMMARY.md"
}

write_intent() {
  fixture=$1 id=$2 state=$3 work=$4 completion=$5 code=$6 test_ev=$7 docs_ev=$8 suffix=${9:-intent}
  cat > "$fixture/docs/intents/$id-$suffix.md" <<EOF
# $id — Fixture

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** $id
- **State:** $state
- **Work evidence:** $work
- **Completion evidence:** $completion
- **Code evidence:** $code
- **Test evidence:** $test_ev
- **Documentation evidence:** $docs_ev
EOF
}

expect_fail() {
  name=$1 needle=$2 fixture=$3
  if bash "$CHECK" "$fixture" > "$TMP_ROOT/out" 2> "$TMP_ROOT/err"; then
    die "$name" 'validator unexpectedly succeeded'
  fi
  grep -Fq "$needle" "$TMP_ROOT/err" || die "$name" "missing diagnostic: $needle"
  pass "$name"
}

F="$TMP_ROOT/paths"; make_book "$F"
(
  # shellcheck disable=SC2034 # Consumed by the sourced path contract.
  SPRINT_LOOP_PROJECT_ROOT="$F"
  . "$SCRIPT_DIR/book-paths.sh"
  [ "$BOOK_ROOT" = "$F/docs" ]
  [ "$BOOK_INTENTS_DIR" = "$F/docs/intents" ]
  [ "$BOOK_TASKS_FILE" = "$F/docs/work/tasks.md" ]
  [ "$BOOK_COMPLETED_TASKS_FILE" = "$F/docs/work/completed-tasks.md" ]
  [ "$BOOK_CONFIDENCE_FILE" = "$F/docs/work/confidence.txt" ]
  [ "$BOOK_SPRINTS_DIR" = "$F/docs/sprints" ]
  [ "$(book_layout_state)" = book-only ]
  book_marker_is_v2
  book_require_v2_layout
) || die test_book_paths_resolve_v2 'path contract mismatch'
pass test_book_paths_resolve_v2

F="$TMP_ROOT/valid-proposed"; make_book "$F"
write_intent "$F" INT-0001 proposed none none none none none
bash "$CHECK" "$F" >/dev/null || die test_book_accepts_proposed 'valid Book rejected'
pass test_book_accepts_proposed

F="$TMP_ROOT/duplicate"; make_book "$F"
write_intent "$F" INT-0001 proposed none none none none none one
write_intent "$F" INT-0001 proposed none none none none none two
expect_fail test_book_rejects_duplicate_intent_id 'duplicate intent ID INT-0001' "$F"

F="$TMP_ROOT/invalid-state"; make_book "$F"
write_intent "$F" INT-0002 invented none none none none none
expect_fail test_book_rejects_invalid_state "invalid state 'invented'" "$F"

for state in planned active deferred; do
  F="$TMP_ROOT/missing-work-$state"; make_book "$F"
  write_intent "$F" INT-0003 "$state" none none none none none
  expect_fail "test_book_requires_work_evidence_$state" 'missing work evidence' "$F"
done

F="$TMP_ROOT/missing-completion"; make_book "$F"
write_intent "$F" INT-0004 realized '[T-004](../work/tasks.md#t-004)' none '[implementation](../../src/lib.rs)' none none
expect_fail test_book_requires_completion_evidence 'missing completion evidence' "$F"

F="$TMP_ROOT/missing-realization"; make_book "$F"
write_intent "$F" INT-0005 realized '[T-005](../work/tasks.md#t-005)' '[T-005 completion](../work/completed-tasks.md#t-005)' none none none
expect_fail test_book_requires_realization_evidence 'missing realization evidence' "$F"

F="$TMP_ROOT/valid-realized"; make_book "$F"
write_intent "$F" INT-0006 realized '[T-006](../work/tasks.md#t-006)' '[T-006 completion](../work/completed-tasks.md#t-006)' '[implementation](../../src/lib.rs)' none none
bash "$CHECK" "$F" >/dev/null || die test_book_accepts_realized_evidence 'valid realized intent rejected'
pass test_book_accepts_realized_evidence

F="$TMP_ROOT/conflict"; make_book "$F"; mkdir -p "$F/sprints"
expect_fail test_book_rejects_conflicting_layouts 'split-brain state: writable Book and legacy Sprint Loops layouts coexist' "$F"

F="$TMP_ROOT/legacy"; mkdir -p "$F/sprints"
expect_fail test_book_rejects_legacy_only 'legacy-only Sprint Loops layout detected' "$F"

F="$TMP_ROOT/summary-state"; make_book "$F"
printf '<!-- sprint-loop-intent-v2 -->\n' >> "$F/docs/SUMMARY.md"
expect_fail test_book_keeps_summary_navigation_only 'navigation only' "$F"

printf 'check-book selftest: all fixtures passed\n'
