# Sprint 1 Test Report

## Summary
- Unit tests: 16 passed / 0 failed / 16 total
- Integration tests: 1 passed / 0 failed / 1 total (run from both skill bundles, both green)
- E2E tests: 0 / 0 / 0 (N/A — not yet possible; unlocked by adding CI for `selftest.sh`, a sprint-2 candidate)
- CI status: not-configured

## Failures
None at the unit/integration level. One real planning gap was caught during
Build (the abort path required hoisting the Exit-status check in
`current-phase.sh`); resolved by extending T-002's scope. Documented under
T-002 in `agent-tasks/completed-tasks.md`.

## Technical Debt Identified
- The `selftest.sh` step 09 now requires a git repo in the temp directory.
  Inside the selftest this is fine (it does `git init` inline), but if anyone
  ever invokes `abort-sprint.sh` outside a git repo, `git commit` fails with
  `set -e`. Consider a graceful "no git repo, skipping commit" fallback in
  `abort-sprint.sh` if external-use scenarios appear. Low priority — every
  protocol-compliant project root IS a git repo (the Build Phase requires
  per-task commits).
- The empty-build-plan edge case flagged in sprint 0 is still open. A
  `finalize-plan.sh` enhancement (refuse to lock a plan with zero `T-XXX`
  entries) is the right home and remains a sprint-2 candidate.
- A CI workflow running `selftest.sh` on push for all three bundles would
  catch any cross-bundle drift automatically. Sprint-2 candidate.

## Coverage Observations
- All 7 phases-of-interest plus the new abort transition are exercised by
  `selftest.sh` (9 transitions total). Adding any new `current-phase.sh`
  branch in the future should come with a matching selftest step.
- `commit-task.sh` is now lightly tested at the unit level. The positive,
  first-occurrence, and negative cases are covered. A future enhancement
  (e.g., back-fill across multiple PENDING entries in one call) would need
  test extensions.
- `abort-sprint.sh` is fully unit-covered (status, note, routing, clean
  tree, commit-message format) and integration-covered (selftest step 09).
