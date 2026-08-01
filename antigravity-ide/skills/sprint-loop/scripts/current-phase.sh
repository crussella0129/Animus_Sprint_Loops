#!/usr/bin/env bash
# Derive the active phase exclusively from Book artifacts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/book-paths.sh"
# shellcheck source=critic-contract.sh
. "$SCRIPT_DIR/critic-contract.sh"
N=$("$SCRIPT_DIR/current-sprint.sh")
if [ "$N" = -1 ]; then echo uninitialized; exit 0; fi
D="$BOOK_SPRINTS_DIR/s$N"

test_critique_allows_loop() {
  local verdict
  verdict=$(critic_verdict "$1") || return 1
  case "$verdict" in clean|proceed-with-caveats) return 0 ;; *) return 1 ;; esac
}

if grep -Eq '^- \*\*Exit status:\*\* (success|failed|aborted)[[:space:]]*$' "$D/sprint-meta.md" 2>/dev/null; then
  echo ready-for-next-sprint; exit 0
fi
if [ ! -s "$D/sprint-research/research-report.md" ]; then echo research; exit 0; fi
if ! grep -qF 'Finalized - DO NOT EDIT' "$D/sprint-plans/build-plan.md" 2>/dev/null; then echo plan; exit 0; fi
if ! grep -qF 'Finalized - DO NOT EDIT' "$D/sprint-plans/test-plan.md" 2>/dev/null; then echo plan; exit 0; fi
if grep -qE "\(sprint $N\)" "$BOOK_TASKS_FILE" 2>/dev/null; then echo build; exit 0; fi
if ! grep -qE "\(sprint $N\)" "$BOOK_COMPLETED_TASKS_FILE" 2>/dev/null; then echo build; exit 0; fi
if [ -s "$D/failure-report.md" ]; then echo loop; exit 0; fi
if [ -s "$D/sprint-tests/test-report.md" ] &&
   test_critique_allows_loop "$D/sprint-tests/critique.md"; then
  echo loop
  exit 0
fi
echo test
