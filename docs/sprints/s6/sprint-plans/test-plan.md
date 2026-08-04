Finalized - DO NOT EDIT

# Sprint 6 Test Plan

## Unit Tests

### T-001 (counter + enforcement)
- `test_counter_within_budget`: research-report with 5 DATA rows + 2 URLs (plus the schema's header + separator rows) → `research-budget.sh` prints `files=5 sources=2` and exits 0.
- `test_counter_skips_header_and_separator`: a report with the standard `| File | Relevance | Notes |` header and `|-----|...` separator under `## 2. Existing Code Survey` but zero data rows → script prints `files=0 sources=0` (NOT `files=2`).
- `test_counter_over_files_budget`: research-report with 25 table rows + 0 URLs → script prints `files=25 sources=0` and exits 1.
- `test_counter_over_sources_budget`: research-report with 5 rows + 10 URLs → script exits 1.
- `test_counter_missing_sections`: research-report with neither section → script prints `files=0 sources=0` and exits 0 (graceful).
- `test_finalize_blocks_over_budget_no_override`: over-budget report, no `## Budget Override` → `finalize-plan.sh` exits non-zero, plans NOT locked.
- `test_finalize_accepts_over_budget_with_override`: over-budget report + `## Budget Override` with non-blank body → `finalize-plan.sh` exits 0, plans locked.
- `test_finalize_within_budget_no_override_needed`: within-budget report, no override section → `finalize-plan.sh` exits 0.

### T-002 (documentation)
- `test_phase_02_mentions_budget_gate`: `phases/02-research-phase.md` mentions ALL of `20`, `5`, `Budget Override`, and one of `non-empty`/`non-blank`/`justification` (the full EARS clause).
- `test_schema_documents_override`: `schemas/research-report.md` contains `## Budget Override` AND describes the non-empty justification requirement.
- `test_particle_02_mentions_budget`: `open-harnesses/particles/02-research-phase.md` mentions budget enforcement AND the override mechanism inside the quoted block.

### T-003 (cross-bundle)
- `test_research_budget_identical`: md5 across all 3 bundles.
- `test_finalize_plan_identical`: md5 across all 3 bundles.
- `test_selftest_identical`: md5 across all 3 bundles.
- `test_schema_research_report_synced`: byte-identical claude/codex.
- `test_phase_02_synced`: byte-identical claude/codex.
- `test_both_bundles_selftest_13`: both bundles report `all 13 transitions matched`.

## Integration Tests

- `test_install_claude_then_selftest_13`: install via `claude-code/install.sh` to a temp HOME → run installed selftest → exit 0 with `all 13 transitions matched`.
- `test_install_codex_then_selftest_13`: install via `codex-cli/install.sh` to a temp HOME → run installed selftest → exit 0 with `all 13 transitions matched`. (Closes the per-bundle install coverage gap surfaced by the plan critic.)

## End-to-End Tests
- **Status:** **never** at the bash-test level for the critic protocol — LLM execution is required and the bash harness can't drive it. Building an LLM-replay harness for E2E is a separate workstream, not currently planned. The script + budget gate is bash-testable and fully covered above.
- **Sprint-on-sprint observation:** sprint 6 is the first sprint to run the critic protocol from sprint 5. Plan Phase critique recorded in `sprints/s6/sprint-plans/critique.md`; Test Phase critique will be recorded in `sprints/s6/sprint-tests/critique.md`. The critique files themselves are the first dogfood evidence.
