# Phase 03 — Plan

**Run `/plan` to engage Codex plan mode now. Use maximum effort.** The Plan Phase
produces two planning artifacts and touches no source files.

Read the current sprint's `sprint-research/research-report.md` as authoritative
input. Also read `decisions.md` at the project root and cross-check with the
report's `## Decisions Reviewed` section. Produce two artifacts in sequence:
`build-plan.md` first, then `test-plan.md`, both in `sprint-plans/`.

## Build plan

Decompose the sprint goal into a schema tree. The root is the sprint goal; each
child node is a critical component; each leaf is an elementary task. A task is
elementary if and only if it can be completed in a single tool-call loop without
re-reading the plan — it touches at most one logical concern, has a single
observable success criterion, and produces a single coherent diff. Do not
decompose below this granularity.

Linearize the tree into an execution sequence honoring dependencies — a task may
only follow tasks it depends on. For each task, record: a stable task ID (e.g.
`T-001`), a one-sentence description, the files it touches, its dependencies (by
task ID), its **success criterion (EARS-format, see below)**, and execution notes.

**Success criterion uses EARS** (Easy Approach to Requirements Syntax):
`WHEN <trigger> THEN <component> SHALL <response>`. Each elementary task gets
at least one EARS clause; multiple when the task has distinct behavioral
surfaces (happy path, error path, edge case). This format lets the Test Phase
scaffold one `test_*` per WHEN/THEN/SHALL triple mechanically; freeform notes
are allowed alongside but tests are derived from the EARS clauses. Review for local
correctness (each task well-formed) and global correctness (the sequence
accomplishes the goal). Write to `build-plan.md` following `schemas/build-plan.md`.

## Test plan

Walk the build-plan's execution sequence in order. For each elementary task,
define the unit tests: input, expected output, required stubs/mocks. For each
component (parent node in the schema tree), define the integration tests covering
interaction between its child tasks. If the build state will permit End-to-End
system testing after this sprint completes, define the E2E tests: full system
invocations with mock-real input data, observable outputs, pass/fail criteria. If
E2E is not yet possible, state so explicitly and identify the future sprint that
unlocks it. Review for local and global correctness. Write to `test-plan.md`
following `schemas/test-plan.md`.

## Finalize

Do not begin building. Do not edit any source files outside the plan documents.
After `ExitPlanMode` returns and you've written both plan files to disk per
the schemas, lock them:

```bash
bash scripts/finalize-plan.sh
```

This prepends `Finalized - DO NOT EDIT` to both files. It also enforces two
gates that block the lock if violated:

- **No-empty-plan gate**: `build-plan.md` must contain at least one
  `### T-XXX:` execution entry.
- **Decisions-reviewed gate**: when `decisions.md` is non-empty, the
  current sprint's `research-report.md` must contain a heading matching
  `^## Decisions Reviewed`. See `phases/02-research-phase.md`.

If `finalize-plan.sh` rejects, fix the violation and re-run; then update
`sprint-meta.md` with a one-line sprint summary.

**When both plans are finalized, read `phases/04-build-phase.md`.**
