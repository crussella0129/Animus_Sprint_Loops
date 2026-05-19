# Schema: `test-plan.md`

Lives at `sprints/sN/sprint-plans/test-plan.md`. Produced in the Plan Phase after `build-plan.md`. Prepended with `Finalized - DO NOT EDIT` once locked.

```markdown
# Sprint N Test Plan

## Unit Tests
### T-001 unit tests
- `test_foo_happy_path`: input X → output Y
- `test_foo_empty_input`: input ∅ → error E
- Stubs: `MockBar`

## Integration Tests
### Component A integration
- `test_component_a_pipeline`: T-001 + T-002 composed → output Z

## End-to-End Tests
- **Status:** possible | not-yet-possible
- (if possible) `test_full_workflow`: ...
- (if not) Unlocked by: sprint N+K when component C exists
```
