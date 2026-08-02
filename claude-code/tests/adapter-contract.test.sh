#!/usr/bin/env bash
# Static coverage for Claude Code's intentionally divergent Book v2 adapter.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_ROOT="$ROOT/claude-code/skills/sprint-loop"
SKILL="$SKILL_ROOT/SKILL.md"
PLAN="$SKILL_ROOT/phases/03-plan-phase.md"
LOOP="$SKILL_ROOT/phases/06-loop-phase.md"
ACTIVE=("$SKILL" "$PLAN" "$LOOP")
ORCHESTRATION_FILES=("$SKILL" "$SKILL_ROOT"/phases/*.md)

fail() {
  echo "claude-adapter-contract: FAIL: $*" >&2
  exit 1
}

require_text() {
  file=$1
  expected=$2
  grep -Fq -- "$expected" "$file" ||
    fail "$file lacks required text: $expected"
}

reject_pattern() {
  pattern=$1
  shift
  if grep -Ein -- "$pattern" "$@" >/dev/null; then
    fail "forbidden Claude adapter pattern found: $pattern"
  fi
}

test_claude_keeps_only_native_orchestration() {
  require_text "$SKILL" 'filesystem or documentation presence is never an activation'
  require_text "$SKILL" 'bash "${CLAUDE_SKILL_DIR}/scripts/current-phase.sh"'
  require_text "$SKILL" 'Book schema v2'
  require_text "$SKILL" 'semantic intent'
  require_text "$SKILL" 'work state'
  require_text "$SKILL" 'sprint provenance'
  require_text "$SKILL" 'navigation-only'
  for book_path in 'docs/intents/' 'docs/work/' 'docs/sprints/' 'docs/SUMMARY.md'; do
    require_text "$SKILL" "$book_path"
  done

  for heading in '## Outcome' '## Inputs' '## Authority' '## Exit evidence'; do
    for phase in "$PLAN" "$LOOP"; do
      count=$(grep -cFx -- "$heading" "$phase" || true)
      [ "$count" -eq 1 ] || fail "$phase has $count copies of $heading"
    done
  done

  enter_count=$(grep -Foh -- 'EnterPlanMode' "${ORCHESTRATION_FILES[@]}" | wc -l | tr -d '[:space:]')
  exit_count=$(grep -Foh -- 'ExitPlanMode' "${ORCHESTRATION_FILES[@]}" | wc -l | tr -d '[:space:]')
  [ "$enter_count" -eq 1 ] || fail "expected one EnterPlanMode reference, found $enter_count"
  [ "$exit_count" -eq 1 ] || fail "expected one ExitPlanMode reference, found $exit_count"
  require_text "$PLAN" 'Invoke `EnterPlanMode` as the first phase action.'
  require_text "$PLAN" 'invoke `ExitPlanMode`'

  require_text "$SKILL" '/loop /sprint-loop continue'
  require_text "$SKILL" 'For session-scoped recurrence'
  require_text "$SKILL" 'changes active permissions'
  require_text "$SKILL" 'none enlarges authority'

  require_text "$PLAN" 'bash "${CLAUDE_SKILL_DIR}/scripts/finalize-plan.sh"'
  require_text "$LOOP" 'bash "${CLAUDE_SKILL_DIR}/scripts/check-book.sh"'
  require_text "$LOOP" 'bash "${CLAUDE_SKILL_DIR}/scripts/close-sprint.sh"'
  require_text "$LOOP" 'this phase does not schedule itself'

  remote_rule='Push, merge, release, force-push, delete, and material scope expansion require an explicit request or a declared preauthorized-remote profile.'
  remote_count=$(grep -Foh -- "$remote_rule" "${ACTIVE[@]}" | wc -l | tr -d '[:space:]')
  [ "$remote_count" -eq 1 ] || fail "expected one exact remote authority rule, found $remote_count"

  reject_pattern 'bash[[:space:]]+"?scripts/|agent-tasks/|(^|[^/])sprints/|decisions\.md|gh[[:space:]]+pr|proceeds autonomously|merge.*green|force-push.*re-verify|change.*permission mode|set.*permission mode' "${ACTIVE[@]}"
  reject_pattern 'implementation_plan\.md|walkthrough\.md|Always Proceed' "${ACTIVE[@]}"

  skill_lines=$(wc -l < "$SKILL" | tr -d '[:space:]')
  [ "$skill_lines" -le 100 ] || fail "Claude SKILL duplicates phase protocol ($skill_lines lines)"
}

test_claude_keeps_only_native_orchestration
echo "claude-adapter-contract: test_claude_keeps_only_native_orchestration passed"
