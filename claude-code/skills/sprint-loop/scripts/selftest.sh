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
# --allow-empty: init-sprint.sh gitignores sprints/, so these scaffolding
# commits may stage nothing new; the test only cares about routing, not commits.
git -c commit.gpgsign=false commit -q --allow-empty -m "selftest: pre-sprint-1 baseline" >/dev/null
SPRINT_MODEL=selftest bash "$T/scripts/init-sprint.sh" >/dev/null
git add -A
git -c commit.gpgsign=false commit -q --allow-empty -m "selftest: init sprint 1" >/dev/null
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

# Step 11 exercises commit-task.sh's back-fill: the line-anchored regex must
# NOT match a `Commit:** PENDING` substring inside other entries' description
# text (the real bug that motivated this fix), and a proper anchored field
# line MUST be filled with a backticked short-hash.
cat > agent-tasks/completed-tasks.md <<'EOF'
# Completed Tasks Log (Append-Only)

## T-001 (sprint 0)
- **Description:** Discussed the placeholder format. Literal mention of `Commit:** PENDING` here — must NOT be touched by back-fill.
- **Files modified:** none
- **Commit:** `abcd123`

## T-002 (sprint 0)
- **Description:** Real task
- **Files modified:** seed
- **Commit:** PENDING
EOF
echo "trigger" > seed
bash "$T/scripts/commit-task.sh" T-002 "selftest back-fill" >/dev/null
PROSE_OK=$(grep -c 'Literal mention of `Commit:\*\* PENDING` here' agent-tasks/completed-tasks.md || true)
FIELD_FILLED=$(grep -cE '^- \*\*Commit:\*\* `[0-9a-f]+`$' agent-tasks/completed-tasks.md || true)
PENDING_LEFT=$(grep -cE '^- \*\*Commit:\*\* PENDING$' agent-tasks/completed-tasks.md || true)
# Original `abcd123` plus the new back-filled hash = 2 filled fields.
if [ "$PROSE_OK" = "1" ] && [ "$FIELD_FILLED" = "2" ] && [ "$PENDING_LEFT" = "0" ]; then
  printf "  PASS  %-34s expected=%-22s got=%s\n" "11 back-fill line-anchored" "prose intact, 1 fill" "prose intact, real field filled"
else
  printf "  FAIL  %-34s prose_ok=%s fields_filled=%s pending_left=%s\n" "11 back-fill line-anchored" "$PROSE_OK" "$FIELD_FILLED" "$PENDING_LEFT" >&2
  exit 1
fi

# Step 12 exercises finalize-plan.sh's Decisions-Reviewed gate: when
# decisions.md is non-empty AND the current sprint's research-report.md lacks
# a `## Decisions Reviewed` heading, finalize-plan.sh must refuse.
SPRINT_MODEL=selftest bash "$T/scripts/init-sprint.sh" >/dev/null
NEW_S=$(bash "$T/scripts/current-sprint.sh")
printf '## 2026-05-20 — selftest ADR (sprint 0)\n- decision\n' > decisions.md
echo "research body without the gate section" > "sprints/s$NEW_S/sprint-research/research-report.md"
printf '# build\n\n### T-001: demo\n' > "sprints/s$NEW_S/sprint-plans/build-plan.md"
echo "tp" > "sprints/s$NEW_S/sprint-plans/test-plan.md"
if bash "$T/scripts/finalize-plan.sh" >/dev/null 2>&1; then
  printf "  FAIL  %-34s expected=%-22s got=%s\n" "12 decisions-reviewed gate" "non-zero exit" "exit 0 (accepted)" >&2
  exit 1
fi
LOCKED=$(head -n1 "sprints/s$NEW_S/sprint-plans/build-plan.md" | grep -cF "Finalized - DO NOT EDIT" || true)
if [ "$LOCKED" != "0" ]; then
  printf "  FAIL  %-34s expected=%-22s got=%s\n" "12 plans not locked on rejection" "no lock" "locked anyway" >&2
  exit 1
fi
printf "  PASS  %-34s expected=%-22s got=%s\n" "12 decisions-reviewed gate" "non-zero + no lock" "rejected + file unchanged"

# Step 13 exercises finalize-plan.sh's research-budget gate: an over-budget
# research-report (>20 file rows) with no `## Budget Override` must be refused;
# adding the override section then allows the lock.
SPRINT_MODEL=selftest bash "$T/scripts/init-sprint.sh" >/dev/null
BN=$(bash "$T/scripts/current-sprint.sh")
{
  printf '# r\n## Decisions Reviewed\n- selftest ADR\n## Existing Code Survey\n| File | Relevance | Notes |\n|------|-----------|-------|\n'
  for i in $(seq 1 25); do printf '| f%s.rs | low | n |\n' "$i"; done
} > "sprints/s$BN/sprint-research/research-report.md"
printf '# build\n\n### T-001: demo\n' > "sprints/s$BN/sprint-plans/build-plan.md"
echo "tp" > "sprints/s$BN/sprint-plans/test-plan.md"
if bash "$T/scripts/finalize-plan.sh" >/dev/null 2>&1; then
  printf "  FAIL  %-34s expected=%-22s got=%s\n" "13 research-budget gate" "non-zero exit" "exit 0 (accepted over budget)" >&2
  exit 1
fi
if head -n1 "sprints/s$BN/sprint-plans/build-plan.md" | grep -qF "Finalized - DO NOT EDIT"; then
  printf "  FAIL  %-34s expected=%-22s got=%s\n" "13 plans not locked over budget" "no lock" "locked anyway" >&2
  exit 1
fi
printf '\n## Budget Override\nSelftest cross-cutting audit of 25 files; justified.\n' >> "sprints/s$BN/sprint-research/research-report.md"
if ! bash "$T/scripts/finalize-plan.sh" >/dev/null 2>&1; then
  printf "  FAIL  %-34s expected=%-22s got=%s\n" "13 override accepted" "exit 0" "still refused with override" >&2
  exit 1
fi
if ! head -n1 "sprints/s$BN/sprint-plans/build-plan.md" | grep -qF "Finalized - DO NOT EDIT"; then
  printf "  FAIL  %-34s expected=%-22s got=%s\n" "13 locked after override" "lock header" "no lock" >&2
  exit 1
fi
printf "  PASS  %-34s expected=%-22s got=%s\n" "13 research-budget gate" "refuse then override" "refused over-budget, locked w/ override"

# Step 14 exercises init-sprint.sh's .gitignore drop: the marker block must be
# present exactly once (idempotent across the many init calls above), must
# ignore sprints/, and must preserve a pre-existing .gitignore's contents.
MARKERS=$(grep -c '# >>> sprint-loops >>>' .gitignore 2>/dev/null || true)
if [ "${MARKERS:-0}" != "1" ]; then
  printf "  FAIL  %-34s expected=%-22s got=%s\n" "14 gitignore idempotent" "exactly 1 block" "${MARKERS:-0} marker(s)" >&2
  exit 1
fi
if ! grep -qx 'sprints/' .gitignore; then
  printf "  FAIL  %-34s expected=%-22s got=%s\n" "14 gitignore content" "sprints/ ignored" "missing" >&2
  exit 1
fi
# Pre-existing .gitignore: contents preserved + block appended exactly once.
PT=$(mktemp -d)
printf 'node_modules/\n' > "$PT/.gitignore"
( cd "$PT" && SPRINT_MODEL=selftest bash "$T/scripts/init-sprint.sh" >/dev/null )
PRE_OK=$(grep -cx 'node_modules/' "$PT/.gitignore" || true)
BLK_OK=$(grep -c '# >>> sprint-loops >>>' "$PT/.gitignore" || true)
rm -rf "$PT"
if [ "${PRE_OK:-0}" = "1" ] && [ "${BLK_OK:-0}" = "1" ]; then
  printf "  PASS  %-34s expected=%-22s got=%s\n" "14 gitignore drop" "1 block, pre-existing kept" "block once + node_modules kept"
else
  printf "  FAIL  %-34s pre_ok=%s blk_ok=%s\n" "14 gitignore drop" "${PRE_OK:-0}" "${BLK_OK:-0}" >&2
  exit 1
fi

echo "selftest: all 14 transitions matched"
