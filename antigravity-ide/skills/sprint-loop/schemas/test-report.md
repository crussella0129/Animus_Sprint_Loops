# Schema: `test-report.md`

Lives at `sprints/sN/sprint-tests/test-report.md`. Exit artifact of a successful Test Phase. (On irrecoverable failure, write `failure-report.md` instead.)

```markdown
# Sprint N Test Report

## Summary
- Unit tests: P passed / F failed / T total
- Integration tests: P passed / F failed / T total
- E2E tests: P passed / F failed / T total (or N/A)
- CI status: green | red | not-configured

## CI Confirmation
- **Head SHA:** <commit the suite ran against>
- **CI run:** <run ID + URL>
- **Conclusion:** success | failure   (authoritative — from `gh run list`, not `gh run watch`)
- **Confirmations:** <guards-report.ndjson artifact/path — one evidence record per suite>
(If the repo has no CI: write "CI not configured — local confirmations only"
and reference the local canonical-runner records instead.)

## Failures
(If any — root cause analysis, not just symptom description)

## Technical Debt Identified
## Coverage Observations
```
