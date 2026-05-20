# Sprint 3 — Unit Tests

## T-001 unit tests (back-fill correctness)
| Test | Result |
|------|--------|
| `test_backfill_anchored_regex_ignores_substring` — prose `Commit:** PENDING` in description text NOT replaced | **PASS** (prose=1 still present) |
| `test_backfill_field_filled` — real anchored field line gets a backticked hash | **PASS** (2 fields filled: original `abcd123` + new hash) |
| `test_backfill_no_pending_left` — after back-fill, no `PENDING` placeholder remains in the (legitimate field) list | **PASS** |
| `test_backfill_noop_without_placeholder` — when no anchored `PENDING` exists, `completed-tasks.md` md5 unchanged | **PASS** |
| `test_backfill_no_extra_commits` — when no placeholder, no extra amend (delta=1 commit) | **PASS** |
| `test_selftest_step_11_passes` — `selftest.sh` reports `all 11 transitions matched` | **PASS** |

T-001 unit tests: **6/6**.

## T-002 unit tests (autonomy + workflow doc presence)
| Test | Result |
|------|--------|
| `test_skill_md_has_autonomous_operation` — `## Autonomous operation` H2 in SKILL.md body | **PASS** |
| `test_skill_md_has_safety_floor` — `## Safety floor` H2 in SKILL.md body | **PASS** |
| `test_build_phase_has_preflight` — `phases/04-build-phase.md` mentions `git fetch && git rebase origin/` | **PASS** |
| `test_build_phase_has_defer_over_block` — defer-over-block paragraph present | **PASS** |
| `test_test_phase_has_ci_verify` — `phases/05-test-phase.md` mentions `gh run list --branch` | **PASS** |
| `test_loop_phase_has_pr_merge` — `phases/06-loop-phase.md` mentions `gh pr merge --merge --delete-branch` | **PASS** |
| `test_particle_06_has_defer` — open-harnesses particle 06 mentions "Defer rather than block" | **PASS** |
| `test_particle_07_has_ci_verify` — particle 07 mentions `gh run list --branch` | **PASS** |
| `test_particle_08_has_pr_merge` — particle 08 mentions `gh pr merge` | **PASS** |

T-002 unit tests: **9/9**.

## T-003 unit tests (cross-bundle sync)
| Test | Result |
|------|--------|
| `test_commit_task_identical` | **PASS** (`44307dfa…`) |
| `test_current_phase_identical` | **PASS** (`62414f4d…`) |
| `test_selftest_identical` | **PASS** (`d88c67bb…`) |
| `test_04_build_phase_synced` | **PASS** (claude == codex) |
| `test_05_test_phase_synced` | **PASS** |
| `test_06_loop_phase_synced` | **PASS** |
| `test_codex_skill_md_has_autonomous_operation` | **PASS** |
| `test_codex_skill_md_has_safety_floor` | **PASS** |
| `test_claude_bundle_selftest_11_steps` | **PASS** (`all 11 transitions matched`) |
| `test_codex_bundle_selftest_11_steps` | **PASS** |

T-003 unit tests: **10/10**.

**Totals: 25 passed / 0 failed / 25 total.**
