# Schema: `test-report.md`

Lives at `docs/sprints/sN/sprint-tests/test-report.md`. It is verification
provenance for the linked intents. On irrecoverable failure, write
`docs/sprints/sN/failure-report.md` instead.

```markdown
# Sprint N Test Report

## Intent Verification
| Intent | Acceptance criterion | EARS / tests | Result | Intent evidence update |
|--------|----------------------|---------------|--------|------------------------|
| [INT-0001](../../../intents/INT-0001-short-title.md) | observable outcome | T-001 / test_foo_happy_path | pass | Test evidence links this report; eligible for realized after completion evidence |

## Summary
- Unit tests: P passed / F failed / T total
- Integration tests: P passed / F failed / T total
- E2E tests: P passed / F failed / T total (or N/A)
- CI status: green | red | not-configured

## CI Confirmation
- **Head SHA:** <commit the suite ran against>
- **CI run:** <run ID + URL>
- **Conclusion:** success | failure
- **Confirmations:** <canonical-runner evidence records>
(If no CI exists: `CI not configured — local confirmations only` and link
the local canonical-runner records.)

## Failures
(If any — root cause and affected intent acceptance criteria.)

## Technical Debt Identified
- [INT-0002](../../../intents/INT-0002-follow-up.md) — deferred work and rationale

## Coverage Observations
```

The Test Phase also writes
`docs/sprints/sN/sprint-tests/critique.md`. On the pass path both non-empty
`test-report.md` and non-empty `critique.md` are required before
`current-phase.sh` routes to Loop, and the final critique must contain the
exact `## Concerns` heading plus a `clean` or `proceed-with-caveats`
Confidence verdict. A `block` or malformed verdict remains in Test. Add the
report link to each verified intent's Test evidence; do not set `realized`
until required completion and realization evidence is present.
