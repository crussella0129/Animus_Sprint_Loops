# Sprint 6 — Unit Tests

## T-001 (counter + enforcement) — exercised during Build
| Test | Result |
|------|--------|
| `test_counter_within_budget` (5 rows + 2 URLs → files=5 sources=2, exit 0) | **PASS** |
| `test_counter_skips_header_and_separator` (header+sep only → files=0) | **PASS** |
| `test_counter_over_files_budget` (25 rows → files=25, exit 1) | **PASS** |
| `test_counter_missing_sections` (stub → files=0 sources=0, exit 0) | **PASS** |
| `test_finalize_blocks_over_budget_no_override` (refuses + not locked) | **PASS** |
| `test_finalize_accepts_over_budget_with_override` (locks) | **PASS** |
| `test_finalize_within_budget_no_override_needed` (locks) | **PASS** |

T-001: **10/10** (added test_counter_over_sources_budget, test_finalize_blocks_override_heading_empty_body, test_counter_bare_heading_variant per test-critic C-001/C-002/C-003). (Two real bugs caught & fixed during Build: counter overcounting per critic C-001; `finalize-plan.sh` unbound `SCRIPT_DIR`.)

## T-002 (documentation)
| Test | Result |
|------|--------|
| `test_phase_02_mentions_budget_gate` (all 4 tokens: 20, 5, Budget Override, justification) | **PASS** |
| `test_schema_documents_override` | **PASS** |
| `test_particle_02_mentions_budget` | **PASS** |

T-002: **3/3**.

## T-003 (cross-bundle)
| Test | Result |
|------|--------|
| `test_research_budget_identical` | **PASS** |
| `test_finalize_plan_identical` | **PASS** |
| `test_selftest_identical` | **PASS** |
| `test_schema_research_report_synced` | **PASS** |
| `test_phase_02_synced` | **PASS** |
| `test_both_bundles_selftest_13` | **PASS** |

T-003: **6/6**.

**Totals: 19 passed / 0 failed / 19 total.** (3 added in response to the test-critic block.)
