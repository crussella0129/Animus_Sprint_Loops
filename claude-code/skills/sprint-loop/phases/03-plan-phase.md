# Phase 03 — Plan

## Outcome

Produce intent-traceable build and test plans, obtain a clean or
proceed-with-caveats critic verdict, and lock both plans atomically while
Claude Code's Plan Mode keeps implementation source unchanged.

## Inputs

Invoke `EnterPlanMode` as the first phase action. While Plan Mode is active,
read from `<project-root>`:

- `docs/sprints/sN/sprint-research/research-report.md`;
- every intent linked under its exact `## Intents Reviewed` heading;
- the current `docs/sprints/sN/sprint-meta.md`;
- `${CLAUDE_SKILL_DIR}/schemas/build-plan.md` and
  `${CLAUDE_SKILL_DIR}/schemas/test-plan.md`;
- `${CLAUDE_SKILL_DIR}/prompts/plan-critic.md`.

Draft both plans in scratch. Decompose the sprint into dependency-ordered
`T-NNN` tasks, each naming its intent, touched paths, dependencies, affected
acceptance criterion, and measurable EARS clauses. Map every EARS clause and
affected intent criterion to a named test, including integration and E2E
coverage or an explicit unlocking intent.

Review for local correctness, global correctness, and intent drift, then
invoke `ExitPlanMode` with concise `Build plan` and `Test plan` sections.
The user controls plan approval. After approval, write
`docs/sprints/sN/sprint-plans/build-plan.md` and `test-plan.md`.

Before critic review, move sprint-advanced `proposed` or `deferred` intents
to `planned`, attach task or plan Work evidence, and append the actual
transition. Preserve an already `active` intent without a no-op history entry.
Record any changed outcome, boundary, rationale, alternative, consequence, or
lifecycle state in the stable intent before reflecting it in a plan.

Run a bounded read-only critic using
`${CLAUDE_SKILL_DIR}/prompts/plan-critic.md`. Save the result to
`docs/sprints/sN/sprint-plans/critique.md`, address every concern, and repeat
review after material changes. Then update the sprint metadata Summary and
Intents and, from `<project-root>`, run:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/finalize-plan.sh"
```

The helper validates the linked intent review, research budget, two non-empty
plan files, at least one build task, and an accepted critic verdict before
locking either plan atomically.

## Authority

Planning may write the two unlocked plans and the Book intent and metadata
needed to make their meaning explicit. It may not edit implementation source,
weaken acceptance criteria to fit an implementation, hand-edit a lock header,
or bypass Plan Mode. Plan approval remains subject to the adapter-level
permission and remote-action boundary in
`${CLAUDE_SKILL_DIR}/SKILL.md`.

## Exit evidence

- Research links at least one existing Book intent.
- Every sprint-advanced intent has valid state, Work evidence, and transition
  history.
- Both plans satisfy their schemas and trace intent → EARS → named tests.
- `critique.md` has the exact critic structure and an accepted final verdict.
- `${CLAUDE_SKILL_DIR}/scripts/finalize-plan.sh` succeeds and both plans
  begin with
  `Finalized - DO NOT EDIT`.
- Running
  `bash "${CLAUDE_SKILL_DIR}/scripts/current-phase.sh"` from
  `<project-root>` reports `build`.

Then read `${CLAUDE_SKILL_DIR}/phases/04-build-phase.md`.
