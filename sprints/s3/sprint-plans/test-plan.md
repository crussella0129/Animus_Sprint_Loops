Finalized - DO NOT EDIT

# Sprint 3 Test Plan

## Unit Tests

### T-001 unit tests (back-fill correctness)
- `test_backfill_anchored_regex_ignores_substring`: in a temp git repo, `completed-tasks.md` contains a line of prose that literally includes `Commit:** PENDING` (not a Commit field — just a description string) AND a separate proper Commit field line `- **Commit:** PENDING`; run `commit-task.sh`; assert the prose line is unchanged and only the proper field line was filled.
- `test_backfill_hash_is_post_amend`: in the same temp repo, after `commit-task.sh` runs, the hash that appears in `completed-tasks.md`'s filled Commit line equals the output of `git log -1 --format=%h` (post-amend HEAD). The pre-amend hash should NOT appear.
- `test_backfill_noop_without_placeholder`: in a temp repo with no `^- **Commit:** PENDING$` line, `commit-task.sh` runs exactly one `git commit` (no amend), `completed-tasks.md` is unchanged.
- `test_selftest_step_11_passes`: `bash open-harnesses/scripts/selftest.sh` final line reports `all 11 transitions matched`.
- Stubs: throwaway git repo per test (init + seed commit + user config).

### T-002 unit tests (autonomy patterns + workflow guidance)
- `test_skill_md_has_autonomous_operation`: SKILL.md contains a `## Autonomous operation` heading.
- `test_skill_md_has_safety_floor`: SKILL.md contains a `## Safety floor` heading.
- `test_build_phase_has_preflight`: `phases/04-build-phase.md` mentions `git fetch && git rebase origin/` and references a sanity gate.
- `test_test_phase_has_ci_verify`: `phases/05-test-phase.md` mentions `gh run list --branch` as a separate step after `gh run watch`.
- `test_loop_phase_has_pr_merge`: `phases/06-loop-phase.md` mentions `gh pr merge` with `--merge --delete-branch`.
- `test_particles_have_parallel_additions`: each of `open-harnesses/particles/{06-build-phase,07-test-phase,08-loop-phase}.md` references its corresponding workflow concept (defer-over-block / CI verify / PR merge) inside its quoted block.

### T-003 unit tests (cross-bundle sync)
- `test_scripts_identical_across_bundles`: md5sum of `commit-task.sh` and `selftest.sh` matches across all 3 bundles.
- `test_phase_files_synced`: `diff -q` of `phases/04-build-phase.md`, `phases/05-test-phase.md`, `phases/06-loop-phase.md` between claude-code/sprint-loop and codex-cli/sprint-loops returns empty.
- `test_both_bundles_selftest_11_steps`: each bundle's `selftest.sh` final line reports `all 11 transitions matched`.
- `test_codex_skill_md_has_autonomy_sections`: codex's SKILL.md also has `## Autonomous operation` and `## Safety floor` (kept name-agnostic so codex's `name: sprint-loops` stands).

## Integration Tests

### Component A+B+C integration
- `test_install_then_selftest_11`: from a temp `HOME`, run `bash claude-code/install.sh`; then run the installed bundle's `selftest.sh`; assert exit 0 with `all 11 transitions matched`. Confirms install + back-fill fix + new selftest step all compose correctly.

## End-to-End Tests
- **Status:** not-yet-possible.
- Document-authoring layer remains LLM-in-the-loop. CI configuration (a sprint-4 candidate) would constitute the first automated E2E.
