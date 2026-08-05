# Test Critique — Sprint 14

Self-critique against `prompts/test-critic.md`'s failure-mode list (no subagent
spawned in this environment). Intent acceptance for `INT-0001` is the semantic
oracle; EARS clauses are the sprint promises; the guard suites and the live
dogfood verifications are provenance.

## Concerns

### C-001: CI confirmation on the sprint head SHA is not yet recorded
- **Where:** `e2e-tests.md` `test_repository_full_guard_suite`; `test-report.md`
  CI Confirmation.
- **Quote:** "the CI conclusion on the sprint head SHA ... is recorded ... once
  the sprint branch is pushed."
- **Failure mode:** evidence-drift
- **Why it matters:** The authoritative full-green signal is the Ubuntu/macOS CI
  leg. Until the sprint head is pushed and CI concludes `success`, the report
  leans on local confirmations plus per-suite reasoning.
- **Response:** defer-with-rationale — the local canonical confirmations (9/10
  `determinism: ok`) are recorded now; the CI conclusion is attached to
  `test-report.md` and gates any merge in the Loop phase. Pushing the sprint is
  the next action and is surfaced to the operator (first outward-facing action,
  large structural change).

### C-002: the full local suite is not 10/10 green
- **Where:** `unit-tests.md` / `e2e-tests.md` selftest exception.
- **Failure mode:** evidence-drift / flake-risk
- **Why it matters:** A reader could mistake "9/10 local" for an unresolved
  defect in this sprint's work.
- **Response:** defer-with-rationale — root-caused to Windows GNU awk 5.4.0
  stripping `\r` (reproduced deterministically), which breaks `finalize-plan.sh`
  `\r`-detection and the test's `\r`-assertion equally; green on POSIX CI, which
  is authoritative. Pre-existing T-113 behavior, unrelated to T-119/T-120,
  backlogged as **T-121**. The failure is deterministic (`determinism: ok`), not
  a flake.

### C-003: INT-0001 has no Test evidence link
- **Where:** `docs/intents/INT-0001-project-book.md` Test evidence = `none`.
- **Failure mode:** intent-coverage / evidence-drift
- **Why it matters:** The verifying report should be reachable from the intent it
  proves, and this is a precondition for the eventual `realized` transition.
- **Response:** fix — added this sprint's `test-report.md` to `INT-0001`'s Test
  evidence (state remains `active`; realization is staged for Loop once
  completion evidence is attached).

### C-004: symlink negative paths are skipped on this host
- **Where:** `migrate-to-book.test.sh` / `check-bundle-sync.test.sh` symlink
  fixtures.
- **Failure mode:** negative-path
- **Why it matters:** The migration's symlink/alias refusal is a safety property;
  skipping its negatives locally could hide a regression.
- **Response:** reject (partial) — the `can_symlink` guard skips only where the OS
  cannot create a real symlink; the hard-link negative still runs locally, and
  all symlink negatives run on the POSIX CI matrix, so the safety property stays
  under test. Local skip does not reduce authoritative coverage.

## Confidence
proceed-with-caveats
