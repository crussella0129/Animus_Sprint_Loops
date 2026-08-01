# Schema: `failure-report.md`

Lives at `docs/sprints/sN/failure-report.md`. Write it when failures require
re-architecture rather than a small local fix. It is failure provenance and
the primary research input for sprint N+1; the affected intent chapters remain
semantic authority.

```markdown
# Sprint N Failure Report

## Affected Intents
- [INT-0001](../../intents/INT-0001-short-title.md) — current state: active; unmet acceptance criterion: ...; recommended next state: active | deferred

## What Failed
Specific tests, components, EARS clauses, or intent acceptance criteria.

## Root Cause
Underlying cause — not symptoms.

## Required Re-architecture
What the next sprint needs to do differently and which intent text, if any,
must be revised before planning.

## Evidence
- [Test results](sprint-tests/unit-tests.md)
- [Test critique](sprint-tests/critique.md)

## State at Failure
- Completed tasks before failure: T-001, T-002
- Task in progress at failure: T-003
- Tasks not started: T-004, T-005
```

Do not mark an affected intent `realized`. Preserve valid work/completion
evidence already earned, record any state change in the intent's Transition
history, and let the next Research Phase decide whether it remains `active`
or becomes `deferred`.
