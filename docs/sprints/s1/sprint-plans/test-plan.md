Finalized - DO NOT EDIT

# Sprint 1 Test Plan

## Unit Tests

### T-001 unit tests
- `test_backfill_replaces_pending`: in a temp git repo with a `completed-tasks.md` line `- **Commit:** PENDING`, after running `commit-task.sh T-001 "test"`, the line reads `` - **Commit:** `<short-hash>` `` and only one commit exists for the change (the amend).
- `test_backfill_first_occurrence_only`: with two `PENDING` lines in `completed-tasks.md`, only the FIRST is replaced after one `commit-task.sh` run; the second remains untouched.
- `test_backfill_noop_without_pending`: with no `PENDING` token, `commit-task.sh` behaves identically to today — one commit, no `completed-tasks.md` modification, no amend.
- Stubs: a temp git repo with `git init` and an initial commit so amend has something to attach to.

### T-002 unit tests
- `test_abort_sets_status`: after `init-sprint.sh`, run `abort-sprint.sh "ran out of time"`; `sprint-meta.md` shows `Exit status:` `aborted`, end timestamp populated, and an `## Abort note` section with the reason.
- `test_abort_routes_ready`: after the abort, `current-phase.sh` prints `ready-for-next-sprint`.
- `test_abort_commits_cleanly`: after abort, the git tree is clean and HEAD's commit message starts with `sprint-N: aborted —`.

### T-003 unit tests
- `test_scripts_identical_across_bundles`: `md5sum` of `commit-task.sh`, `abort-sprint.sh`, and `selftest.sh` matches across all three bundles.
- `test_selftest_step_09_abort`: each bundle's `selftest.sh` exits 0 and prints `PASS 09 sprint aborted ... ready-for-next-sprint`.
- `test_phase_files_synced`: `diff` of `04-build-phase.md` and `06-loop-phase.md` between `claude-code/skills/loop-sprint/phases/` and `codex-cli/skills/sprint-loops/phases/` is empty (after T-003 propagates the abort additions).

## Integration Tests

### Component A+B+C integration
- `test_full_phase_walk_with_abort`: in a temp project, run a full Research→Plan→Build (with one task using PENDING placeholder) and confirm the back-filled hash appears in `completed-tasks.md` after `commit-task.sh`. Then init a second sprint, abort it, and confirm `current-phase.sh` reports `ready-for-next-sprint`. Equivalent to the extended `selftest.sh` plus a back-fill verification.

## End-to-End Tests
- **Status:** not-yet-possible
- Same constraint as sprint 0: no automated mechanism for driving the LLM-authored phase outputs. The script-layer and protocol-bookkeeping layer are fully exercised by `selftest.sh` + the unit tests above. A real E2E would require a sprint-of-sprints harness that picks goals, writes plans, and commits — out of scope for now. Unlocked by: a future sprint that adds CI driving the selftest on push (sprint 2 candidate).
