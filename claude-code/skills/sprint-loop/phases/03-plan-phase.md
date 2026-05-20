# Phase 03 — Plan

## Enter plan mode (hard primitive)

**First action this phase:** invoke the `EnterPlanMode` tool. Claude Code's
plan mode blocks Edit/Write/Bash side effects, which is exactly what the Plan
Phase needs — reasoning and decomposition only, no source files touched.

While in plan mode:

1. Read `sprint-research/research-report.md` as authoritative input
   (filesystem reads are allowed in plan mode).
2. Read `schemas/build-plan.md` and `schemas/test-plan.md` for the output
   contract.
3. Read `decisions.md` at the project root and identify which ADRs apply
   (cross-check with the report's `## Decisions Reviewed` section).
4. Synthesize the build-plan and test-plan in your head + scratch — do not
   write them to disk yet.
5. When both plans are complete and reviewed for local + global
   correctness, invoke the `ExitPlanMode` tool with a concise two-section
   plan summary (Build plan / Test plan), one paragraph per section. The
   user reviews the plan summary in the harness before approving exit.

After `ExitPlanMode` returns (plan approved), drop back to normal mode and
write the two plan artifacts to disk per the schemas below, then run
`finalize-plan.sh`.

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
task ID), its success criterion, and execution notes. Review for local
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
