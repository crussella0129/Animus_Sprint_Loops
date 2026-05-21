#!/usr/bin/env bash
# Count file and source references in the current sprint's research-report.md
# and exit non-zero if either is over budget.
#
# Output: `files=N sources=M`
# Exit:   0 if N≤20 AND M≤5; 1 otherwise.
#
# Counter heuristics:
#   files   = data rows of the markdown table under `## (N. )? Existing Code Survey`
#             (markdown-table lines `^\| `, then skip the 2 header rows = header + separator)
#   sources = URL-bearing bullet lines (`^- \[.*\](http`) under `## (N. )? External Sources`
#
# Tolerant of missing sections (returns 0 for that count) and numeric-prefix
# heading variants (`## 2. Existing Code Survey` vs `## Existing Code Survey`).
set -euo pipefail

LAST=$(ls sprints/ 2>/dev/null | grep -E '^s[0-9]+$' | sed 's/^s//' | sort -n | tail -1 || true)
if [ -z "${LAST:-}" ]; then echo "files=0 sources=0"; exit 0; fi
RPT="sprints/s$LAST/sprint-research/research-report.md"
if [ ! -s "$RPT" ]; then echo "files=0 sources=0"; exit 0; fi

# Slice the section between heading $1 (regex) and the next `^## ` heading.
section() {
  awk -v pat="$1" '
    $0 ~ pat { in_sec=1; next }
    in_sec && /^## / { in_sec=0 }
    in_sec { print }
  ' "$RPT"
}

# Files: count ALL table-like lines (`^\|`) then subtract 2 for the
# header + separator rows. This catches both `| File | ... |` (header)
# and `|------|...` (separator) regardless of post-pipe spacing.
TABLE_LINES=$(section '^## ([0-9]+[.] *)?Existing Code Survey' | grep -cE '^\|' || true)
if [ "${TABLE_LINES:-0}" -le 2 ]; then FILES=0; else FILES=$((TABLE_LINES - 2)); fi

SOURCES=$(section '^## ([0-9]+[.] *)?External Sources' | grep -cE '^- \[.*\]\(http' || true)

echo "files=$FILES sources=$SOURCES"

if [ "$FILES" -gt 20 ] || [ "$SOURCES" -gt 5 ]; then exit 1; fi
exit 0
