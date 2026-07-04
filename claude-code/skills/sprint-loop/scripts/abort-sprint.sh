#!/usr/bin/env bash
# Mark the current sprint as aborted and close it out cleanly.
# Usage: abort-sprint.sh "<one-line reason>"
#
# An abort is the "stop, retry later" signal — distinct from the failure path
# (which uses sprints/sN/failure-report.md and feeds into the next sprint's
# research). An aborted sprint's plans and partial work are preserved, but
# Exit status is set to "aborted" and the routing immediately reports
# ready-for-next-sprint.
#
# Run from the project root. Sibling scripts are resolved relative to this
# file, so this works whether scripts/ lives in the project or in an
# installed skill bundle.
set -euo pipefail

if [ "${1:-}" = "" ]; then
  echo "usage: $(basename "$0") \"<reason>\"" >&2
  exit 1
fi
REASON="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
N=$("$SCRIPT_DIR/current-sprint.sh")
if [ "$N" = "-1" ]; then
  echo "no sprint to abort (run init-sprint.sh first)" >&2
  exit 1
fi

META="sprints/s$N/sprint-meta.md"
if [ ! -s "$META" ]; then
  echo "missing or empty $META" >&2
  exit 1
fi

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
# Portable in-place edit (BSD sed has no bare -i): write to tmp, then move.
sed -e '/Exit status/s/in-progress/aborted/' \
    -e "s|^- \*\*End timestamp:\*\* (filled at Loop Phase)|- **End timestamp:** $TS|" \
    "$META" > "$META.tmp" && mv "$META.tmp" "$META"
cat >> "$META" <<EOF

## Abort note ($TS)
$REASON
EOF

git add -A
# The abort's record (Exit status: aborted) lives in sprint-meta.md, which is
# gitignored in projects that adopt the default .gitignore. If nothing tracked
# changed, there's nothing to commit — the abort still took effect on disk and
# current-phase.sh reads it. Only commit when there IS a tracked change.
if git diff --cached --quiet; then
  echo "Sprint $N marked aborted (sprint state is gitignored; no tracked change to commit)."
else
  git commit -m "sprint-$N: aborted — $REASON"
  echo "Sprint $N marked aborted."
fi
