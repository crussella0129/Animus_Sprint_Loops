# Schema: `build-plan.md`

Lives at `sprints/sN/sprint-plans/build-plan.md`. Produced in the Plan Phase. Prepended with `Finalized - DO NOT EDIT` once locked.

```markdown
# Sprint N Build Plan

## Schema Tree
- Sprint Goal
  - Component A
    - T-001: ...
    - T-002: ...
  - Component B
    - T-003: ...

## Execution Sequence

### T-001: <one-sentence description>
- **Touches:** path/to/file.rs
- **Depends on:** (none) | T-XXX
- **Success criterion (EARS):**
  - **WHEN** `foo()` is called with valid input X, **THEN** the function **SHALL** return Y.
  - **WHEN** `foo()` is called with empty input, **THEN** the function **SHALL** return error E.
- **Notes:** use existing `Bar` trait from `bar.rs`
```

**Success criterion format** — Use EARS (Easy Approach to Requirements Syntax):
`WHEN <trigger> THEN <component> SHALL <response>`. Each elementary task
should have at least one EARS clause; multiple are encouraged when the task
has distinct behavioral surfaces (happy path, error path, edge case). Test
Phase scaffolds one `test_*` per WHEN/THEN/SHALL triple. Freeform notes are
allowed alongside but tests are derived from EARS clauses.
