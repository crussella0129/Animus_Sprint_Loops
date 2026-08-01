# Schema: `build-plan.md`

Lives at `docs/sprints/sN/sprint-plans/build-plan.md`. It translates stable
intent into executable work and remains sprint provenance after close.
`finalize-plan.sh` prepends `Finalized - DO NOT EDIT` once both plans pass
their gates.

```markdown
# Sprint N Build Plan

## Intents
- [INT-0001](../../../intents/INT-0001-short-title.md) — state: planned; acceptance criteria covered: ...

## Schema Tree
- Sprint Goal
  - Component A
    - T-001: ...
    - T-002: ...

## Execution Sequence

### T-001: <one-sentence description>
- **Intent:** [INT-0001](../../../intents/INT-0001-short-title.md)
- **Touches:** path/to/file.rs
- **Depends on:** (none) | T-XXX
- **Acceptance criterion:** <specific criterion from the linked intent>
- **Success criterion (EARS):**
  - **WHEN** `foo()` is called with valid input X, **THEN** the function **SHALL** return Y.
  - **WHEN** `foo()` is called with empty input, **THEN** the function **SHALL** return error E.
- **Notes:** use existing `Bar` trait from `bar.rs`
```

Every sprint plans against at least one intent, and every task names at least
one linked `INT-NNNN`. The plan may refine execution details but must not
silently change the linked chapter's outcome, boundaries, or acceptance
criteria. Before finalization, move every sprint-advanced `proposed` or
`deferred` intent to `planned`, attach Work evidence linking its task or this
plan, and append the actual state change to Transition history. Preserve an
already `active` intent without adding a no-op history entry. If semantics
change, amend the intent first and record the change in Transition history.

Use EARS (Easy Approach to Requirements Syntax):
`WHEN <trigger> THEN <component> SHALL <response>`. Each elementary task has
at least one measurable clause. The Test Phase derives a named test from every
clause and traces it back to the linked intent acceptance criterion.
