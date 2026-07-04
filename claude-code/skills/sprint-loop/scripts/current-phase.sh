#!/usr/bin/env bash
# Inspect the filesystem and print the active phase. The filesystem IS the state machine.
# Run from the project root. Sibling scripts are resolved relative to this file, so
# this works whether scripts/ lives in the project or in an installed skill bundle.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
N=$("$SCRIPT_DIR/current-sprint.sh")
if [ "$N" = "-1" ]; then echo "uninitialized"; exit 0; fi
D="sprints/s$N"
# Closed sprints short-circuit: if Exit status is success/failed/aborted, the
# sprint is done regardless of intermediate filesystem state. This is what
# makes abort-sprint.sh work mid-flight.
if grep -q "Exit status:.*\(success\|failed\|aborted\)" "$D/sprint-meta.md" 2>/dev/null; then echo "ready-for-next-sprint"; exit 0; fi
if [ ! -s "$D/sprint-research/research-report.md" ]; then echo "research"; exit 0; fi
if ! grep -q "Finalized - DO NOT EDIT" "$D/sprint-plans/build-plan.md" 2>/dev/null; then echo "plan"; exit 0; fi
if ! grep -q "Finalized - DO NOT EDIT" "$D/sprint-plans/test-plan.md" 2>/dev/null; then echo "plan"; exit 0; fi
# Plans are finalized. Build is in progress while sprint-N tasks remain queued.
# Match `(sprint N)` with literal parens (the schema's task-reference format)
# so we don't false-positive on prose like "flagged for sprint 3" inside
# another entry's description.
if grep -qE "\(sprint $N\)" agent-tasks/agent-tasks.md 2>/dev/null; then echo "build"; exit 0; fi
# No sprint-N tasks queued. If none have been completed either, the Build Phase
# has not started yet — the protocol's first Build-Phase action is to append tasks.
if ! grep -qE "\(sprint $N\)" agent-tasks/completed-tasks.md 2>/dev/null; then echo "build"; exit 0; fi
# Build is done. Test runs until an exit artifact exists. On the PASS path the
# test critic must also have run (sprint 13): a test-report without
# sprint-tests/critique.md keeps us in `test`. The FAILURE path
# (failure-report.md) is exempt — a failed sprint skips the critic by design.
if [ -s "$D/failure-report.md" ]; then echo "loop"; exit 0; fi
if [ -s "$D/sprint-tests/test-report.md" ] && [ -s "$D/sprint-tests/critique.md" ]; then echo "loop"; exit 0; fi
# Tests are not done (or the critic hasn't run yet).
echo "test"
