#!/usr/bin/env bash
# Count Book research references and enforce the existing files/sources budget.
# Output: files=N sources=M; exit 1 above 20 files or 5 sources.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/book-paths.sh"

LAST=$("$SCRIPT_DIR/current-sprint.sh")
if [ "$LAST" = -1 ]; then echo "files=0 sources=0"; exit 0; fi
RPT="$BOOK_SPRINTS_DIR/s$LAST/sprint-research/research-report.md"
if [ ! -s "$RPT" ]; then echo "files=0 sources=0"; exit 0; fi

section() {
  awk -v pat="$1" '
    $0 ~ pat { in_sec=1; next }
    in_sec && /^## / { in_sec=0 }
    in_sec { print }
  ' "$RPT"
}

TABLE_LINES=$(section '^## ([0-9]+[.] *)?Existing Code Survey' | grep -cE '^\|' || true)
if [ "${TABLE_LINES:-0}" -le 2 ]; then FILES=0; else FILES=$((TABLE_LINES - 2)); fi
SOURCES=$(section '^## ([0-9]+[.] *)?External Sources' | grep -cE '^- \[.*\]\(http' || true)

echo "files=$FILES sources=$SOURCES"
if [ "$FILES" -gt 20 ] || [ "$SOURCES" -gt 5 ]; then exit 1; fi
