Finalized - DO NOT EDIT

# Sprint 0 Test Plan

## Unit Tests

### T-001 unit tests
- `test_plan_finalized_before_build`: in a temp project where `init-sprint.sh`
  has run, `research-report.md` is non-empty, both plans have the `Finalized -
  DO NOT EDIT` header, and `agent-tasks.md` / `completed-tasks.md` have only
  their schema headers → `current-phase.sh` prints `build`. (This is the
  exact scenario captured in `sprints/s0/sprint-research/bug-trace.txt`.)
- `test_no_regression_research`: in a fresh init-only project →
  `current-phase.sh` prints `research`.
- `test_no_regression_plan`: with `research-report.md` non-empty but plans
  not finalized → `current-phase.sh` prints `plan`.
- `test_no_regression_build_in_progress`: with plans finalized and at least
  one `sprint $N` task in `agent-tasks.md` → `current-phase.sh` prints `build`.
- `test_build_done_test_pending`: with plans finalized, no tasks in
  `agent-tasks.md`, at least one `sprint $N` entry in `completed-tasks.md`,
  and `test-report.md` empty → `current-phase.sh` prints `test`.
- Stubs: none. Tests use real filesystem layout and the actual scripts.

### T-002 unit tests
- `test_selftest_passes_on_fixed_script`: `bash
  open-harnesses/scripts/selftest.sh` exits 0; stdout reports all 8
  transitions matched.
- `test_selftest_fails_on_buggy_script`: a deliberate revert of T-001 makes
  `selftest.sh` exit non-zero with a message naming the failing transition.
  (Verified once during Test Phase, then rolled back.)
- Stubs: none. The selftest creates its own temp project.

### T-003 unit tests
- `test_scripts_identical_across_bundles`: `md5sum` of `current-phase.sh` and
  `selftest.sh` matches across `open-harnesses/`,
  `claude-code/skills/loop-sprint/`, and `codex-cli/skills/sprint-loops/`.

## Integration Tests

### Component A+B+C integration
- `test_full_phase_walk_in_repo`: from the repo root, invoke each bundle's
  `current-phase.sh` and `selftest.sh` (using their installed-bundle paths) to
  confirm sibling-path resolution still works and the fix is uniformly applied.

## End-to-End Tests
- **Status:** not-yet-possible
- Unlocked by: sprint 1 — a follow-up sprint can use the now-hardened skill to
  walk a full Research → Loop on a fresh project, exercising every phase end
  to end with real outputs.
