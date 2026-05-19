#!/usr/bin/env bash
# Inspect the filesystem and print the active phase. The filesystem IS the state machine.
set -euo pipefail
N=$(./scripts/current-sprint.sh)
if [ "$N" = "-1" ]; then echo "uninitialized"; exit 0; fi
D="sprints/s$N"
if [ ! -s "$D/sprint-research/research-report.md" ]; then echo "research"; exit 0; fi
if ! grep -q "Finalized - DO NOT EDIT" "$D/sprint-plans/build-plan.md" 2>/dev/null; then echo "plan"; exit 0; fi
if ! grep -q "Finalized - DO NOT EDIT" "$D/sprint-plans/test-plan.md" 2>/dev/null; then echo "plan"; exit 0; fi
if grep -q "sprint $N" agent-tasks/agent-tasks.md 2>/dev/null; then echo "build"; exit 0; fi
if [ ! -s "$D/sprint-tests/test-report.md" ] && [ ! -s "$D/failure-report.md" ]; then echo "test"; exit 0; fi
if ! grep -q "Exit status:.*\(success\|failed\|aborted\)" "$D/sprint-meta.md" 2>/dev/null; then echo "loop"; exit 0; fi
echo "ready-for-next-sprint"
