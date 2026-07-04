#!/usr/bin/env bash
# Initialize the next sprint's filesystem state. See particles/01-init-sprint.md.
# Optional: set SPRINT_MODEL to record the model identifier in sprint-meta.md.
# Run from the project root. Sibling scripts are resolved relative to this
# file, so this works whether scripts/ lives in the project or in an
# installed skill bundle.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p sprints
LAST=$("$SCRIPT_DIR/current-sprint.sh")
if [ "$LAST" = "-1" ]; then N=0; else N=$((LAST + 1)); fi

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

# Drop a .gitignore for the ephemeral sprint working memory (idempotent —
# guarded by the marker so re-running init never duplicates it, and an
# existing .gitignore is preserved with the block appended once). Long-term
# memory (decisions.md, agent-tasks/, confidence.txt) stays TRACKED.
if ! grep -q '# >>> sprint-loops >>>' .gitignore 2>/dev/null; then
  cat >> .gitignore <<'GI'

# >>> sprint-loops >>>
# Ephemeral sprint working memory — regenerable; the real outcome lives in the
# per-task git commits + decisions.md. KEEP tracked (long-term memory the
# protocol depends on): decisions.md, agent-tasks/, confidence.txt.
sprints/
*.tmp
# <<< sprint-loops <<<
GI
fi

echo "Initialized sprint $N at $D"
