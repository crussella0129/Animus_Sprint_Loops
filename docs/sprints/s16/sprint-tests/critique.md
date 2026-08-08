# Test Critique — Sprint 16

## Concerns

**Resolved prior concerns:** Head `026d6faffeba53c87db2610202e4da865304ede2` now exercises all four profile-query branches, asserts exact branch sets for every hosted provider, and proves no-clobber behavior for both Dependabot and Renovate. Hosted run `31245249580` passed on Ubuntu and macOS at that exact head; the retained 15/15 deterministic report byte-matches the Ubuntu artifact.

### C-001: Pull-request event confirmation is deferred
- **Where:** `unit-tests.md` T-133 / `test_ci_covers_dev`
- **Quote:** “`pull_request.branches` includes both `main` and `dev`.”
- **Failure mode:** evidence-drift
- **Why it matters:** Static trigger coverage and a successful hosted `push` run prove the workflow and v7 actions function at the published head, but a `pull_request` event has not yet directly exercised the branch filter. This is appropriately deferred until the protocol opens the `dev → main` PR after Test/Loop.
- **Suggested response:** defer-with-rationale

### C-002: Final remote topology remains authorization-gated
- **Where:** `e2e-tests.md` Post-Loop Checkpoints / `INT-0003` final acceptance criterion
- **Quote:** “2 pending by design; M-001 is gated on a human-approved `dev → main` merge.”
- **Failure mode:** intent-coverage
- **Why it matters:** The implemented path is proven, but branch retirement and the final `main`/`dev`-only topology cannot be accepted until M-001 receives authority and both post-merge tests pass. The current evidence correctly keeps INT-0003 active and makes no false completion claim.
- **Suggested response:** defer-with-rationale

## Confidence
proceed-with-caveats
