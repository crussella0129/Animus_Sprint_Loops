#!/usr/bin/env bash
# Self-test for the Sprint Loops helper scripts.
# Creates a throwaway project, drives it through every phase transition, and
# asserts that current-phase.sh reports the expected phase at each step.
# Exits 0 on success; non-zero with the failing transition on the first miss.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
cp -r "$SCRIPT_DIR" "$T/scripts"
chmod +x "$T/scripts"/*.sh
cd "$T"

assert_phase() {
  local expected="$1" step="$2" got
  got=$(bash "$T/scripts/current-phase.sh")
  if [ "$got" = "$expected" ]; then
    printf "  PASS  %-34s expected=%-22s got=%s\n" "$step" "$expected" "$got"
  else
    printf "  FAIL  %-34s expected=%-22s got=%s\n" "$step" "$expected" "$got" >&2
    exit 1
  fi
}

echo "selftest: driving an 8-step phase walk in $T"

assert_phase uninitialized          "01 fresh project"

SPRINT_MODEL=selftest bash "$T/scripts/init-sprint.sh" >/dev/null
assert_phase research               "02 after init-sprint"

echo "research body" > sprints/s0/sprint-research/research-report.md
assert_phase plan                   "03 research written, plan not finalized"

# build-plan must contain at least one `### T-XXX:` entry or finalize-plan.sh refuses.
printf '# build\n\n### T-001: demo\n' > sprints/s0/sprint-plans/build-plan.md
echo "test content"  > sprints/s0/sprint-plans/test-plan.md
bash "$T/scripts/finalize-plan.sh" >/dev/null
assert_phase build                  "04 plan finalized, build not started"

echo "- [ ] T-001 (sprint 0): demo — touches: x" >> agent-tasks/agent-tasks.md
assert_phase build                  "05 task queued, build in progress"

# Simulate the Build Phase completing the task: consume from agent-tasks,
# append to completed-tasks.
sed -i '/T-001 (sprint 0)/d' agent-tasks/agent-tasks.md
cat >> agent-tasks/completed-tasks.md <<'EOF'

## T-001 (sprint 0)
- **Description:** demo
EOF
assert_phase test                   "06 task done, test pending"

echo "tests passed" > sprints/s0/sprint-tests/test-report.md
assert_phase loop                   "07 test-report written"

sed -i '/Exit status/s/in-progress/success/' sprints/s0/sprint-meta.md
assert_phase ready-for-next-sprint  "08 sprint closed"

# Step 09 exercises abort-sprint.sh: init a fresh sprint, abort it, and assert
# routing short-circuits to ready-for-next-sprint regardless of whether any
# research/plan/build work happened. Requires a git repo for the abort commit.
git init -q . >/dev/null
git config user.email selftest@example.invalid
git config user.name selftest
git add -A
git -c commit.gpgsign=false commit -q -m "selftest: pre-sprint-1 baseline" >/dev/null
SPRINT_MODEL=selftest bash "$T/scripts/init-sprint.sh" >/dev/null
git add -A
git -c commit.gpgsign=false commit -q -m "selftest: init sprint 1" >/dev/null
bash "$T/scripts/abort-sprint.sh" "selftest abort" >/dev/null
assert_phase ready-for-next-sprint  "09 sprint aborted via abort-sprint.sh"

# Step 10 exercises the empty-build-plan rejection: a fresh sprint whose
# build-plan.md has no `### T-XXX:` entries must NOT be lockable.
SPRINT_MODEL=selftest bash "$T/scripts/init-sprint.sh" >/dev/null
echo "research body" > sprints/s2/sprint-research/research-report.md
printf '# build\n\nno tasks here, just prose\n' > sprints/s2/sprint-plans/build-plan.md
echo "test content" > sprints/s2/sprint-plans/test-plan.md
if bash "$T/scripts/finalize-plan.sh" >/dev/null 2>&1; then
  printf "  FAIL  %-34s expected=%-22s got=%s\n" "10 empty-plan rejected" "non-zero exit" "exit 0 (accepted)" >&2
  exit 1
fi
if head -n1 sprints/s2/sprint-plans/build-plan.md | grep -qF "Finalized - DO NOT EDIT"; then
  printf "  FAIL  %-34s expected=%-22s got=%s\n" "10 empty-plan unchanged" "no lock header" "lock header present" >&2
  exit 1
fi
printf "  PASS  %-34s expected=%-22s got=%s\n" "10 empty-plan rejected" "non-zero exit" "non-zero exit + file unchanged"

echo "selftest: all 10 transitions matched"
