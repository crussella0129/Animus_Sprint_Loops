# Test Critique — Sprint 15

Self-critique against `prompts/test-critic.md`'s failure-mode list (no subagent
spawned in this environment). INT-0002 acceptance is the oracle; the substrate
fixtures and the live dogfood are provenance.

## Concerns

### C-001: CI on the sprint-15 head SHA is not yet recorded
- **Where:** `e2e-tests.md` `test_repository_full_guard_suite`; `test-report.md` CI Confirmation.
- **Failure mode:** evidence-drift
- **Why it matters:** the authoritative full-green signal is the Ubuntu/macOS CI
  leg; until the branch is pushed and CI concludes, the report leans on the local
  canonical run plus per-suite reasoning.
- **Response:** defer-with-rationale — the local canonical confirmations are
  recorded now; the CI conclusion is attached to `test-report.md` and gates the
  `dev→main` (and sprint-15) merge in Loop.

### C-002: the full local suite is not 10/10 green
- **Where:** `selftest` chained `runtime-helpers` CRLF assertions.
- **Failure mode:** evidence-drift / flake-risk
- **Response:** defer-with-rationale — pre-existing Windows GNU-awk `\r`-stripping
  (backlog T-121), deterministic (not a flake), green on POSIX CI, and unrelated
  to any T-122–T-129 script.

### C-003: provider adapter is proven against stubs, not a live remote
- **Where:** `remote-adapter.test.sh` stubs `gh`.
- **Failure mode:** stub-leakage
- **Why it matters:** the stub mirrors the `gh pr list/create` contract, not a
  real GitHub round-trip; a real-API regression could slip a unit run.
- **Response:** defer-with-rationale — the stub asserts the contract (exactly one
  `pr create`, never `pr merge`, generic fallback on absence), and the real
  round-trip is exercised end-to-end when the Loop opens this very sprint's
  `sprint-15 → main` PR and by the human-approve boundary. No network in unit CI
  by design.

### C-004: the "single writer of `dev`" invariant is a topology property
- **Where:** INT-0002 acceptance; `test_bump_inherit_without_race`.
- **Failure mode:** intent-coverage (weak verification)
- **Response:** defer-with-rationale — enforced by `test_resync_writes_only_work`
  (base never mutated) + the T-127 doc contract (`main` the single confluence);
  no stronger automated proof of absence-of-concurrency is in scope.

### C-005: deploy rollback is injected at one step
- **Where:** `test_deploy_rolls_back_on_failure` (`DEPLOY_SUBSTRATE_FAIL_AFTER=branches`).
- **Failure mode:** negative-path
- **Response:** defer-with-rationale — the injection exercises the full
  `CREATED_*` cleanup path (branches + sprint + profile + Book + `.git`); the
  rollback is uniform across steps, so one late injection covers the mechanism.

## Re-review
No concern leaves an INT-0002 acceptance criterion or EARS promise unproved by
the local + dogfood evidence; C-001 is the only open item and is gated by CI
before any merge.

## Confidence
proceed-with-caveats
