# Phase 03 — Plan

## Outcome

Produce intent-traceable build and test plans, obtain a clean or
proceed-with-caveats critic verdict, and lock both plans atomically without
editing implementation source.

## Inputs

From `<project-root>`, read:

- `docs/sprints/sN/sprint-research/research-report.md`;
- every intent linked under its exact `## Intents Reviewed` heading;
- the current `docs/sprints/sN/sprint-meta.md`;
- `<skill-root>/schemas/build-plan.md` and
  `<skill-root>/schemas/test-plan.md`;
- `<skill-root>/prompts/plan-critic.md`.

Draft `docs/sprints/sN/sprint-plans/build-plan.md` by decomposing the sprint
into dependency-ordered `T-NNN` tasks. Each task names its intent, touched
paths, dependency edges, acceptance criterion, and measurable EARS clauses.
Draft `test-plan.md` so every EARS clause and affected intent criterion maps to
a named test, including integration and E2E coverage or an explicit unlocking
intent.

Before critic review, move sprint-advanced `proposed` or `deferred` intents to
`planned`, attach task/plan Work evidence, and append the actual transition.
Preserve an already `active` intent without a no-op history entry. Record
semantic changes in the stable intent before reflecting them in either plan.

Delegate the critic only as bounded read-only review. The integrating writer
saves its result to `docs/sprints/sN/sprint-plans/critique.md`, addresses every
concern, and re-runs review after material plan changes. Then update the sprint
metadata Summary and Intents and, from `<project-root>`, run:

```bash
bash "<skill-root>/scripts/finalize-plan.sh"
```

## Authority

Planning may write the two unlocked plans and the Book intent/metadata needed
to make their meaning explicit. It may not edit implementation source, weaken
acceptance criteria to fit an implementation, alter the locked-plan header by
hand, change Codex operating permissions, or perform remote actions. If the
active environment cannot write the required Book artifacts, report that
limitation instead of claiming phase completion.

## Exit evidence

- Research links at least one existing Book intent.
- Every sprint-advanced intent has valid state, Work evidence, and transition
  history.
- Both plans satisfy their schemas and trace intent → EARS → named tests.
- `critique.md` has the exact critic structure and an accepted final verdict.
- `finalize-plan.sh` succeeds and both plans begin with
  `Finalized - DO NOT EDIT`.
- Re-running `bash "<skill-root>/scripts/current-phase.sh"` from
  `<project-root>` reports `build`.
