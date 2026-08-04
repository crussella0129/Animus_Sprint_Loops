# Sprint 2 — Unit Tests

## T-001 unit tests (finalize-plan empty-plan rejection)
| Test | Method | Result |
|------|--------|--------|
| `test_finalize_rejects_empty_plan` | `build-plan.md` with prose only, no `### T-XXX:`; run `finalize-plan.sh`; assert non-zero exit | **PASS** |
| `test_empty_plan_unchanged` | After rejection, `build-plan.md`'s first line is NOT the lock header | **PASS** |
| `test_finalize_accepts_plan_with_task` | Append `### T-001: demo`; rerun; assert exit 0 + lock header now present | **PASS** |
| `test_selftest_step_count` | `bash selftest.sh` final line reports `all 10 transitions matched` | **PASS** |

T-001 unit tests: **4/4**.

## T-002 unit tests (idempotent install scripts)
| Test | Method | Result |
|------|--------|--------|
| `test_install_claude_code_fresh` | `HOME=$TH bash claude-code/install.sh`; assert skill + command land + scripts executable | **PASS** (Build Phase) |
| `test_install_claude_code_idempotent` | Run twice, compare tree md5 hash | **PASS** (`46e1b193…` matches across runs) |
| `test_install_codex_fresh` | `HOME=$TH bash codex-cli/install.sh`; assert skill lands + scripts executable | **PASS** |
| `test_install_codex_idempotent` | Run twice, compare tree md5 | **PASS** |
| `test_install_open_harnesses_fresh` | `bash open-harnesses/install.sh <tempdir>`; assert scripts land + executable | **PASS** |
| `test_install_open_harnesses_idempotent` | Run twice, compare tree md5 | **PASS** |

T-002 unit tests: **6/6**.

## T-003 unit tests (cross-bundle sync)
| Test | Method | Result |
|------|--------|--------|
| `test_scripts_identical_across_bundles` | `md5sum` of `finalize-plan.sh` and `selftest.sh` across all 3 bundles | **PASS** — `b232bbd4…` and `71447482…` match |
| `test_both_bundles_selftest_10_steps` | Run each bundle's `selftest.sh`; assert `all 10 transitions matched` | **PASS** |

T-003 unit tests: **2/2**.

**Totals: 12 passed / 0 failed / 12 total.**
