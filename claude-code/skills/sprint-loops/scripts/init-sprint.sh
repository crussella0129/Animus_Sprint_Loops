#!/usr/bin/env bash
# Initialize the next sprint's filesystem state. See particles/01-init-sprint.md.
# Optional: set SPRINT_MODEL to record the model identifier in sprint-meta.md.
set -euo pipefail

mkdir -p sprints
LAST=$(ls sprints/ 2>/dev/null | grep -E '^s[0-9]+$' | sed 's/^s//' | sort -n | tail -1 || true)
if [ -z "${LAST:-}" ]; then N=0; else N=$((LAST + 1)); fi

D="sprints/s$N"
if [ -d "$D" ]; then echo "sprint $N already exists at $D" >&2; exit 1; fi

mkdir -p "$D/sprint-research" "$D/sprint-plans" "$D/sprint-tests"
: > "$D/sprint-research/research-report.md"
: > "$D/sprint-plans/build-plan.md"
: > "$D/sprint-plans/test-plan.md"
: > "$D/sprint-tests/unit-tests.md"
: > "$D/sprint-tests/integration-tests.md"
: > "$D/sprint-tests/e2e-tests.md"
: > "$D/sprint-tests/test-report.md"

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MODEL="${SPRINT_MODEL:-unknown}"
cat > "$D/sprint-meta.md" <<EOF
# Sprint $N Meta

- **Sprint number:** $N
- **Start timestamp:** $TS
- **End timestamp:** (filled at Loop Phase)
- **Model:** $MODEL
- **Exit status:** in-progress
- **Token count:** (filled at Loop Phase if observable)
- **Summary:** (one-line description of sprint goal, filled after Plan Phase)
EOF

# Persistent state — created once, shared across all sprints.
mkdir -p agent-tasks
[ -f agent-tasks/agent-tasks.md ]    || printf '# Agent Tasks (Persistent Backlog)\n' > agent-tasks/agent-tasks.md
[ -f agent-tasks/completed-tasks.md ] || printf '# Completed Tasks Log (Append-Only)\n' > agent-tasks/completed-tasks.md
[ -f decisions.md ]                  || printf '# Architectural Decisions\n' > decisions.md

echo "Initialized sprint $N at $D"
