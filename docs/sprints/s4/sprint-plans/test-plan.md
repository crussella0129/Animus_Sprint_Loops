Finalized - DO NOT EDIT

# Sprint 4 Test Plan

## Unit Tests

### T-001 unit tests (hard plan-mode primitive)
- `test_plan_phase_mentions_EnterPlanMode`: `claude-code/skills/sprint-loop/phases/03-plan-phase.md` contains the literal token `EnterPlanMode`.
- `test_plan_phase_mentions_ExitPlanMode`: same file contains `ExitPlanMode`.
- `test_skill_md_plan_mode_section_updated`: `claude-code/skills/sprint-loop/SKILL.md` "Plan mode" section references both tool names.

### T-002 unit tests (EARS-format)
- `test_build_plan_schema_has_EARS`: `open-harnesses/schemas/build-plan.md` example contains the EARS keywords `WHEN`, `THEN`, `SHALL`.
- `test_plan_phase_mandates_EARS`: `claude-code/skills/sprint-loop/phases/03-plan-phase.md` contains EARS in the build-plan composition section.
- `test_test_phase_describes_EARS_derivation`: `claude-code/skills/sprint-loop/phases/05-test-phase.md` references EARS for unit-test scaffolding.
- `test_particle_04_mentions_EARS`: `open-harnesses/particles/04-build-plan-schema.md` mentions EARS.
- `test_particle_05_mentions_EARS`: `open-harnesses/particles/05-test-plan-schema.md` mentions EARS.

### T-003 unit tests (decisions.md mandatory read + finalize-plan gate)
- `test_finalize_refuses_without_decisions_reviewed`: in a temp project with a non-empty `decisions.md` and a `research-report.md` lacking `## Decisions Reviewed`, `finalize-plan.sh` exits non-zero AND build-plan.md's first line is NOT the lock header.
- `test_finalize_accepts_with_decisions_reviewed`: same setup but with `## Decisions Reviewed` section present in research-report; `finalize-plan.sh` exits 0 and the lock header appears.
- `test_finalize_skips_check_when_decisions_empty`: in a temp project with empty `decisions.md` and no `## Decisions Reviewed` in research-report, `finalize-plan.sh` exits 0 (back-compat).
- `test_research_schema_has_decisions_reviewed_section`: `open-harnesses/schemas/research-report.md` contains a `## Decisions Reviewed` heading.
- `test_research_phase_mandates_decisions_read`: `claude-code/skills/sprint-loop/phases/02-research-phase.md` instructs reading `decisions.md` at phase start.
- `test_particle_02_mentions_decisions_read`: `open-harnesses/particles/02-research-phase.md` references `decisions.md` reading inside its quoted block.

### T-004 unit tests (cross-bundle)
- `test_finalize_plan_identical`: md5 across all 3 bundles.
- `test_selftest_identical`: md5 across all 3 bundles.
- `test_schemas_synced`: `schemas/build-plan.md` and `schemas/research-report.md` byte-identical claude-code <-> codex-cli.
- `test_phases_02_05_synced`: `phases/02-research-phase.md` and `phases/05-test-phase.md` byte-identical claude-code <-> codex-cli.
- `test_both_bundles_selftest_12`: both bundles `selftest.sh` reports `all 12 transitions matched`.

## Integration Tests

### Component A+B+C+D integration
- `test_install_then_selftest_12`: from a temp `HOME`, run `bash claude-code/install.sh`; then run the installed bundle's `selftest.sh`; assert exit 0 with `all 12 transitions matched`.

## End-to-End Tests
- **Status:** not-yet-possible.
- Document-authoring layer remains LLM-in-the-loop. Sprint 5+ candidates (subagent fan-out, enforced research budget, CI workflow) would unlock different facets of E2E coverage.
