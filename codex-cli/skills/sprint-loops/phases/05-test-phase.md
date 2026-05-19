# Phase 05 — Test

Read the current sprint's `test-plan.md` as authoritative input.

1. Implement and run all unit tests defined for tasks completed in this sprint's
   Build Phase; record results in `sprint-tests/unit-tests.md`.
2. Implement and run all integration tests defined for components touched in this
   sprint; record results in `sprint-tests/integration-tests.md`.
3. If the test-plan marks E2E tests as possible, implement and run them; record
   results in `sprint-tests/e2e-tests.md`. Otherwise write
   `Not yet possible — unlocked by sprint N+K` in that file.

For any failing test, **do not patch the symptom** — identify the underlying
cause:

- If the fix is small and local, apply it and re-run.
- If the fix requires re-architecture, stop testing. Write `failure-report.md` to
  `sprints/sN/` documenting the root cause and the work needed (see
  `schemas/failure-report.md`), mark `sprint-meta.md` exit status as `failed`, and
  proceed to the Loop Phase — the next sprint will begin with that failure-report
  as its primary research input.

Watch for successful completion of any CI/CD pipelines configured for the repo.
When all tests pass and CI is green, write a summary to
`sprint-tests/test-report.md` (see `schemas/test-report.md`) covering: tests run,
tests passed, tests failed, coverage observations, and any technical debt
identified.

**When complete, read `phases/06-loop-phase.md`.**
