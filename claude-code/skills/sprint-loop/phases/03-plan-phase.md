# Phase 03 — Plan

## Enter plan mode (hard primitive — mandatory first action)

Invoke the `EnterPlanMode` tool before composing the plans. Claude Code's
plan mode keeps source edits out of the reasoning/decomposition step.

While in plan mode:

1. Read
   `docs/sprints/sN/sprint-research/research-report.md`.
2. Read every intent linked under `## Intents Reviewed`; the sprint must
   advance at least one `INT-NNNN`.
3. Read `schemas/build-plan.md`, `schemas/test-plan.md`, and the current
   `sprint-meta.md`.
4. Draft the build and test plans in scratch. Trace every task to intent
   acceptance criteria and every EARS clause to a planned test.
5. Review for local correctness, global correctness, and intent drift.
6. Invoke `ExitPlanMode` with a concise Build plan / Test plan summary.

### Plan approval and unattended operation

When `ExitPlanMode` presents the plan, an interactive run can approve
normally. An unattended Claude Code run can select its auto-accept option at
that prompt. This adapter mechanic does not change the Book contract or lower
the active safety floor.

After approval, write the two artifacts under
`docs/sprints/sN/sprint-plans/`.

Before critic review, synchronize every sprint-advanced intent with the plan.
Move `proposed` or `deferred` to `planned`, attach Work evidence linking its
`T-NNN` task or plan anchor, and append the state change to Transition history.
Preserve an already `active` intent without adding a no-op history entry.

## Build plan

Use the research recommendation to decompose the sprint goal into a schema
tree, then linearize elementary `T-NNN` tasks in dependency order. Each task
names at least one intent, touched paths, dependencies, the specific intent
acceptance criterion it advances, measurable EARS clauses, and execution notes.

The plan translates intent into work. If planning changes an outcome, boundary,
rationale, alternative, consequence, or lifecycle state, revise the stable
intent chapter and append its Transition history before continuing.

## Test plan

Map each EARS clause to at least one named unit test, each component to
integration coverage, and each affected intent acceptance criterion to
verification in the Intent Traceability table. Define E2E coverage when
possible; otherwise name the unlocking intent or sprint and rationale.

## Critic review (before lock)

After `ExitPlanMode` returns and both plans are written, use the Agent tool
with `prompts/plan-critic.md`. The critic reads the research report, plans,
and linked intents with read-only authority. Save the result to
`docs/sprints/sN/sprint-plans/critique.md`.

Address every concern inline:

- `fix-in-plan`: amend an unlocked plan.
- `defer-with-rationale`: record the follow-up against its intent and work
  ledger.
- `reject`: explain why the critique is inapplicable.

Do not lock while the critic verdict is `block`. If subagents are
unavailable, self-critique against the same prompt and save the same structure.

## Finalize

Before invoking the helper, update `sprint-meta.md` Summary and Intents with
the one-line goal and links to every `INT-NNNN` advanced by the sprint. Then
invoke the installed bundle's `scripts/finalize-plan.sh` helper with the
project root as its working directory.

The helper validates both plans before changing either one. It requires:

- at least one `### T-NNN:` build task;
- at least one Book intent and at least one Markdown-linked entry under the
  research report's exact `## Intents Reviewed` heading, rejecting a legacy
  review heading as a substitute;
- research within the 20-file / 5-source budget or a non-empty override;
- a critique with `## Concerns` and a `clean` or
  `proceed-with-caveats` Confidence verdict.

On success, both plans receive `Finalized - DO NOT EDIT`. Do not begin source
work before that evidence exists.

When complete, read `phases/04-build-phase.md`.
