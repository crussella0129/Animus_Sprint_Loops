# Sprint 4 — Unit Tests

## T-001 (hard plan-mode primitive)
| Test | Result |
|------|--------|
| `test_plan_phase_mentions_EnterPlanMode` | **PASS** |
| `test_plan_phase_mentions_ExitPlanMode` | **PASS** |
| `test_skill_md_plan_mode_section_updated` | **PASS** |

T-001: **3/3**.

## T-002 (EARS-format success criteria)
| Test | Result |
|------|--------|
| `test_build_plan_schema_has_EARS` | **PASS** |
| `test_plan_phase_mandates_EARS` | **PASS** |
| `test_test_phase_describes_EARS_derivation` | **PASS** |
| `test_particle_04_mentions_EARS` | **PASS** |
| `test_particle_05_mentions_EARS` | **PASS** |

T-002: **5/5**.

## T-003 (decisions.md mandatory read + finalize-plan gate)
| Test | Result |
|------|--------|
| `test_finalize_refuses_without_decisions_reviewed` | **PASS** (clear "refusing to finalize" message) |
| `test_plans_not_locked_when_refused` | **PASS** (file unchanged) |
| `test_finalize_accepts_with_decisions_reviewed` | **PASS** (file gets the lock header) |
| `test_finalize_skips_check_when_decisions_empty` | **PASS** (back-compat for sprint 0 / new projects) |
| `test_research_schema_has_decisions_reviewed_section` | **PASS** |
| `test_research_phase_mandates_decisions_read` | **PASS** |
| `test_particle_02_mentions_decisions_read` | **PASS** |

T-003: **7/7**.

## T-004 (cross-bundle sync)
| Test | Result |
|------|--------|
| `test_finalize_plan_identical` | **PASS** (`b1b…` matching across all 3) |
| `test_selftest_identical` | **PASS** |
| `test_schema_build_plan_synced` | **PASS** |
| `test_schema_research_report_synced` | **PASS** |
| `test_phase_02_synced` | **PASS** |
| `test_phase_05_synced` | **PASS** |
| `test_both_bundles_selftest_12` | **PASS** (both report `all 12 transitions matched`) |

T-004: **7/7**.

**Totals: 22 passed / 0 failed / 22 total.**

(Plus the 12-step selftest in each of the 2 bundles = 24 additional assertions all green.)
