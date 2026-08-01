# Schema: `test-plan.md`

Lives at `docs/sprints/sN/sprint-plans/test-plan.md`. It maps locked task
promises to verification of stable intent.

```markdown
# Sprint N Test Plan

## Intent Traceability
| Intent | Acceptance criterion | Build task / EARS clause | Verification |
|--------|----------------------|--------------------------|--------------|
| [INT-0001](../../../intents/INT-0001-short-title.md) | observable outcome | T-001 / WHEN ... THEN ... SHALL ... | test_foo_happy_path |

## Unit Tests
### T-001 unit tests
- **Intent:** [INT-0001](../../../intents/INT-0001-short-title.md)
- `test_foo_happy_path`: input X → output Y
- `test_foo_empty_input`: empty input → error E
- Stubs: `MockBar`

## Integration Tests
### Component A integration
- **Intents:** [INT-0001](../../../intents/INT-0001-short-title.md)
- `test_component_a_pipeline`: T-001 + T-002 composed → output Z

## End-to-End Tests
- **Status:** possible | not-yet-possible
- (if possible) `test_full_workflow`: input, observable output, pass/fail criteria
- (if not) Unlocked by: named future intent or sprint with rationale
```

Every EARS clause has at least one test, every test identifies its clause, and
the traceability table covers every acceptance criterion affected by the
sprint. Tests may strengthen an acceptance criterion but may not weaken or
redefine it.
