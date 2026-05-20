# Phase 05 — Test

Read the current sprint's `test-plan.md` as authoritative input.

## Deriving tests from EARS success criteria

The Build Phase's `build-plan.md` records each task's success criterion in
EARS form (`WHEN <trigger> THEN <component> SHALL <response>`). The Test
Phase mechanically scaffolds one unit test per EARS clause:

- `WHEN foo() called with input X THEN it SHALL return Y` →
  `test_foo_returns_Y_for_X` — arrange X, act `foo(X)`, assert returns `Y`.
- `WHEN foo() called with empty input THEN it SHALL return error E` →
  `test_foo_returns_E_for_empty` — arrange empty, act, assert `Err(E)`.

Each WHEN/THEN/SHALL triple maps to exactly one named test; the trigger
becomes the arrangement, the response becomes the assertion. If a task's
success criterion has no EARS clauses (freeform criteria still parse), fall
back to freeform test design and note the gap in `unit-tests.md`.

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

## CI verify (GitHub Actions)

If the repo uses GitHub Actions, **always verify conclusion as a separate step
after `gh run watch`** — the watch command's exit code is unreliable on some
platforms (Windows in particular), and a green-looking `watch` can hide a red
conclusion:

```bash
gh run watch <run-id> --exit-status                              # may lie
gh run list --branch "$(git branch --show-current)" \
  --json status,conclusion,databaseId --limit 1                  # source of truth
```

Treat the `conclusion` field from `gh run list` as authoritative. On `failure`:

```bash
gh run view <id> --log-failed
```

Read the log, fix the underlying cause (not the symptom), force-push the
branch, and re-watch. Don't merge a PR until `gh run list` shows
`conclusion: success` on the branch's head commit.

**When complete, read `phases/06-loop-phase.md`.**
