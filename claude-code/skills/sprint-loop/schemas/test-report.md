# Schema: `test-report.md`

Lives at `sprints/sN/sprint-tests/test-report.md`. Exit artifact of a successful Test Phase. (On irrecoverable failure, write `failure-report.md` instead.)

```markdown
# Sprint N Test Report

## Summary
- Unit tests: P passed / F failed / T total
- Integration tests: P passed / F failed / T total
- E2E tests: P passed / F failed / T total (or N/A)
- CI status: green | red | not-configured

## Failures
(If any — root cause analysis, not just symptom description)

## Technical Debt Identified
## Coverage Observations
```
