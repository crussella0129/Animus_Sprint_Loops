# Sprint 0 Test Report

## Summary
- Unit tests: 8 passed / 0 failed / 8 total
- Integration tests: 1 passed / 0 failed / 1 total
- E2E tests: 0 / 0 / 0 (N/A — not yet possible, unlocked by sprint 1)
- CI status: not-configured (this repo has no CI; the selftest is the substitute and can be wired into CI by sprint 1 if desired)

## Failures
None. The Build Phase's T-002 first-run did surface a real bug — in the
selftest's own simulation `sed` pattern, not in the protocol — which was
fixed in the same task before T-002 was committed. Captured as a note in
`agent-tasks/completed-tasks.md` under T-002.

## Technical Debt Identified
- The `commit-task.sh` helper does not back-fill the commit hash into
  `completed-tasks.md`. Hashes are added manually after the commit lands.
  Worth automating in a follow-up sprint (small two-step: commit, then
  amend the just-written entry with the new hash, or write the hash on
  the next commit's run).
- An empty build plan (zero elementary tasks) would now loop on `build`
  indefinitely after the T-001 disambiguator. Out of scope for sprint 0,
  flagged in the research report as a follow-up.

## Coverage Observations
- All five phase-detection branches in `current-phase.sh` are now exercised
  by `selftest.sh`. Adding a sixth distinct state (e.g. `aborted`) in a
  future sprint should come with a corresponding selftest step.
- Cross-bundle byte-identity is checked at test time; if a future change
  diverges the three copies, the integration test catches it on the spot.
