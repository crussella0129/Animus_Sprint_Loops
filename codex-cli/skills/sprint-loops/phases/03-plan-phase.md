# Phase 03 — Plan

**Run `/plan` to engage Codex plan mode now. Use maximum effort.** The Plan
Phase produces planning artifacts and does not edit implementation source.

Read
`docs/sprints/sN/sprint-research/research-report.md`, every intent linked
under `## Intents Reviewed`, the current `sprint-meta.md`, and the build/test
schemas. The sprint must advance at least one `INT-NNNN`.

## Build plan

Use the research recommendation to decompose the sprint goal into a schema
tree, then linearize elementary `T-NNN` tasks in dependency order. Each task
names at least one intent, touched paths, dependencies, the specific intent
acceptance criterion it advances, measurable EARS clauses, and execution notes.

The plan translates intent into work. If planning changes an outcome, boundary,
rationale, alternative, consequence, or lifecycle state, revise the stable
intent chapter and append its Transition history before continuing.

Before critic review, synchronize every sprint-advanced intent with the plan.
Move `proposed` or `deferred` to `planned`, attach Work evidence linking its
`T-NNN` task or plan anchor, and append the state change to Transition history.
Preserve an already `active` intent without adding a no-op history entry.

## Test plan

Map each EARS clause to at least one named unit test, each component to
integration coverage, and each affected intent acceptance criterion to
verification in the Intent Traceability table. Define E2E coverage when
possible; otherwise name the unlocking intent or sprint and rationale.

## Critic review (before lock)

After both plans are written, spawn a read-only critic with
`prompts/plan-critic.md`. It reads the research report, plans, and linked
intents. Save its result to
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
