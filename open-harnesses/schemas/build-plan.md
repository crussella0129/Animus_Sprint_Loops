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
- **Success criterion:** function `foo` exists, signature matches spec, compiles
- **Notes:** use existing `Bar` trait from `bar.rs`
```
