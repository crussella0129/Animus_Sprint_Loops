Finalized - DO NOT EDIT

# Sprint 4 Build Plan

## Schema Tree
- Sprint Goal: top 3 sprint-3 follow-ups (hard plan-mode, EARS, decisions-review)
  - Component A: hard plan-mode primitive
    - T-001: wire `EnterPlanMode`/`ExitPlanMode` into `phases/03-plan-phase.md` + SKILL.md Plan-mode section (claude-code only; codex retains `/plan`)
  - Component B: EARS-format success criteria
    - T-002: update `schemas/build-plan.md` example + `phases/03-plan-phase.md` (both bundles) + `phases/05-test-phase.md` (both bundles) + open-harnesses particles 04/05 to require/use EARS clauses
  - Component C: cross-sprint architectural drift detection
    - T-003: mandatory `decisions.md` read in `phases/02-research-phase.md` (both bundles) + open-harnesses particle 02 + `schemas/research-report.md` adds "## Decisions Reviewed" section + `finalize-plan.sh` refuses lock without it (skip if `decisions.md` empty/absent)
  - Component D: cross-bundle sync + regression coverage
    - T-004: sync to both bundles, extend `selftest.sh` step 12 for the new finalize-plan gate

## Execution Sequence

### T-001: Wire hard `EnterPlanMode`/`ExitPlanMode` protocol into claude-code's Plan Phase
- **Touches:** `claude-code/skills/sprint-loop/phases/03-plan-phase.md`, `claude-code/skills/sprint-loop/SKILL.md`
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** an agent enters the Plan Phase via the sprint-loop skill, **THEN** `phases/03-plan-phase.md` **SHALL** instruct it to invoke the `EnterPlanMode` tool as its first action.
  - **WHEN** plan synthesis is complete in plan mode, **THEN** `phases/03-plan-phase.md` **SHALL** instruct the agent to invoke `ExitPlanMode` with both plan summaries before writing files.
  - **WHEN** an agent reads SKILL.md "Plan mode" section, **THEN** the section **SHALL** describe the tool-call protocol (not just say "engage plan mode now").
- **Notes:** Plan mode in Claude Code blocks Edit/Write, so the writes happen AFTER `ExitPlanMode`. Codex's `/plan` integration is unchanged (its SKILL.md already specifies the slash command). Open-harnesses keeps generic language (no harness primitive exists there).

### T-002: EARS-format success criteria across schema, Plan/Test phase docs, and particles
- **Touches:** `open-harnesses/schemas/build-plan.md`, `claude-code/skills/sprint-loop/phases/03-plan-phase.md`, `claude-code/skills/sprint-loop/phases/05-test-phase.md`, `open-harnesses/particles/04-build-plan-schema.md`, `open-harnesses/particles/05-test-plan-schema.md`
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** an agent reads `schemas/build-plan.md`, **THEN** the schema example **SHALL** show success criteria in EARS form (`WHEN <trigger> THEN <component> SHALL <response>`).
  - **WHEN** an agent reads `phases/03-plan-phase.md` Build-plan composition section, **THEN** it **SHALL** state that each task's success criterion uses at least one EARS clause.
  - **WHEN** an agent reads `phases/05-test-phase.md`, **THEN** it **SHALL** describe deriving one `test_*` per WHEN/THEN/SHALL triple.
  - **WHEN** open-harnesses particles 04 and 05 are loaded into a retrieval store, **THEN** their quoted blocks **SHALL** mention EARS.
- **Notes:** EARS is recommended, not mandatory — freeform criteria still parse. Sprint 4's own build-plan (this file) demonstrates the format. Bundle sync happens in T-004.

### T-003: Mandatory `decisions.md` read + `finalize-plan.sh` enforcement
- **Touches:** `open-harnesses/scripts/finalize-plan.sh`, `open-harnesses/schemas/research-report.md`, `claude-code/skills/sprint-loop/phases/02-research-phase.md`, `open-harnesses/particles/02-research-phase.md`
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** `finalize-plan.sh` is invoked AND the project's `decisions.md` is non-empty AND the current sprint's `research-report.md` lacks a heading matching `^## Decisions Reviewed`, **THEN** the script **SHALL** exit non-zero with a clear message and not lock the plans.
  - **WHEN** `decisions.md` is empty or absent, **THEN** `finalize-plan.sh` **SHALL** skip the check (back-compat with new projects + sprint 0).
  - **WHEN** an agent reads `phases/02-research-phase.md`, **THEN** it **SHALL** be instructed to read `decisions.md` first and list the relevant ADRs in the report's `## Decisions Reviewed` section.
  - **WHEN** an agent reads `schemas/research-report.md`, **THEN** the schema **SHALL** include a `## Decisions Reviewed` section near the top.
- **Notes:** The grep in `finalize-plan.sh` is `grep -qE '^## Decisions Reviewed'` (line-anchored, lesson from sprint 3). Codex's `phases/02-research-phase.md` gets the same update in T-004 sync.

### T-004: Cross-bundle sync + selftest step 12
- **Touches:** `codex-cli/skills/sprint-loops/phases/{02-research-phase.md,03-plan-phase.md,05-test-phase.md}`, `claude-code/skills/sprint-loop/schemas/{build-plan.md,research-report.md}`, `codex-cli/skills/sprint-loops/schemas/{build-plan.md,research-report.md}`, `claude-code/skills/sprint-loop/scripts/{finalize-plan.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/scripts/{finalize-plan.sh,selftest.sh}`
- **Depends on:** T-001, T-002, T-003
- **Success criterion (EARS):**
  - **WHEN** `md5sum` is run on `finalize-plan.sh` and `selftest.sh` across all 3 bundles, **THEN** the values **SHALL** match.
  - **WHEN** `diff -q` is run between claude-code/codex-cli for `schemas/build-plan.md`, `schemas/research-report.md`, and `phases/{02,05}-*.md`, **THEN** the output **SHALL** be empty.
  - **WHEN** each bundle's `selftest.sh` is invoked, **THEN** it **SHALL** exit 0 reporting `selftest: all 12 transitions matched`.
- **Notes:** Step 12 of `selftest.sh`: in a temp project, write a non-empty `decisions.md`, run a fresh sprint up to plan-finalize-time, deliberately omit the Decisions Reviewed section from research-report, run `finalize-plan.sh`, assert non-zero exit AND that plans were NOT locked.
