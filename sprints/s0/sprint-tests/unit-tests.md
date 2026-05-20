# Sprint 0 — Unit Tests

All unit tests defined in the Plan Phase are covered by
`open-harnesses/scripts/selftest.sh`. The selftest creates a throwaway project
and drives it through all 8 phase transitions.

## T-001 unit tests
| Test | Step | Result |
|------|------|--------|
| `test_plan_finalized_before_build` | selftest step 04 — plan finalized, no tasks queued, no completed sprint-N tasks | **PASS** — got `build` (pre-fix: got `test`) |
| `test_no_regression_research`      | selftest step 02 — after `init-sprint.sh` | **PASS** — got `research` |
| `test_no_regression_plan`          | selftest step 03 — research-report non-empty, plans not finalized | **PASS** — got `plan` |
| `test_no_regression_build_in_progress` | selftest step 05 — sprint-N task queued in `agent-tasks.md` | **PASS** — got `build` |
| `test_build_done_test_pending`     | selftest step 06 — task consumed, sprint-N in `completed-tasks.md`, test-report empty | **PASS** — got `test` |

All 5 T-001 unit tests pass: **5/5**.

## T-002 unit tests
| Test | Method | Result |
|------|--------|--------|
| `test_selftest_passes_on_fixed_script` | `bash open-harnesses/scripts/selftest.sh` against the current (fixed) script | **PASS** — exit 0, all 8 transitions matched |
| `test_selftest_fails_on_buggy_script`  | Replaced `current-phase.sh` with the pre-T-001 version in a temp dir; reran selftest | **PASS** — selftest exited non-zero with `FAIL 04 plan finalized, build not started expected=build got=test` |

T-002 unit tests: **2/2**.

## T-003 unit tests
| Test | Method | Result |
|------|--------|--------|
| `test_scripts_identical_across_bundles` | `md5sum` of `current-phase.sh` and `selftest.sh` across all three bundles | **PASS** — `current-phase.sh`: `31769bde80804b651062bdf2d4af24b6` in all 3; `selftest.sh`: `b97af24c19d95f876721a5738e56b28b` in all 3 |

T-003 unit tests: **1/1**.

**Totals: 8 passed / 0 failed / 8 total.**
