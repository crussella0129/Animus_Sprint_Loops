# Test Critique — Sprint 18

## Concerns

### C-001: the sprint's own fixtures missed the defect that mattered most
- **Where:** `e2e-tests.md` / `test-plan.md` Integration Tests
- **Quote:** "a fresh deploy creates its own branches and leaves `HEAD` on `base`, so the new `substrate-misplaced` state made convergence fail its own post-deploy verification and roll the entire deploy back"
- **Failure mode:** integration-drift
- **Why it matters:** this is the most serious defect either sprint has produced — every fresh project would have been undeployable — and **nothing written during this sprint would have caught it**. T-149's fixtures proved the misplaced state in isolation; the planned integration tests composed T-146/147/149/150 but never included `deploy-substrate`, because convergence belongs to the *previous* sprint's intent. The canonical suite caught it only because it runs every suite, including ones this sprint had no reason to think about.
- **Suggested response:** fix-in-plan — **applied**, plus a standing lesson. The fix separates the fresh-deploy case from the existing-project case and adds two fixtures. The generalizable finding is that a sprint's integration coverage is scoped to its own intent, so a gate that changes a *shared* helper's observable output can break a consumer from an earlier intent with no local test to notice. That is now carry-forward work: the integration section of a plan that changes a shared helper's output should enumerate that helper's existing consumers.

### C-002: the intent says the checkpoint path is gated on committed evidence; it is not
- **Where:** `INT-0005` Intent, item 3 / `remote-adapter.sh`
- **Quote:** "A new helper asserts that each phase's exit artifacts are git-tracked and free of uncommitted modification, wired into `finalize-plan.sh`, `close-sprint.sh`, and the checkpoint path."
- **Failure mode:** intent-coverage
- **Why it matters:** `remote-adapter.sh` does not call `check-tracked.sh`. No acceptance criterion requires it — only the Intent prose does — so the locked plan omitted it and the plan critic did not catch the mismatch. The chapter and the code disagree, which is exactly the lower-authority drift the Book contract exists to prevent, even though the practical exposure is nil.
- **Suggested response:** defer-with-rationale, recorded as carry-forward. In practice the check is redundant: `close-sprint.sh` runs the gate immediately before, and `open-pr` is refused until close has succeeded, so the Book is provably clean when the checkpoint opens — and the adapter commits its own `Checkpoint` write, so it is clean afterwards too. The right repair is to reconcile the prose with the acceptance criteria in a later sprint rather than to widen a locked plan mid-sprint. INT-0005 stays `active`, so the chapter is not being closed over the discrepancy.

### C-003: T-121 has now cost two consecutive sprints of local verification
- **Where:** `e2e-tests.md` / `unit-tests.md` T-147, T-148
- **Quote:** "the five contract-3 gate fixtures for T-147 and T-148 … were verified in a focused harness extracted verbatim from the suite file"
- **Failure mode:** evidence-drift
- **Why it matters:** the local `selftest` suite aborts before this sprint's own gate fixtures, for the second sprint running. The harness workaround is faithful — the block is extracted verbatim and run against the installed bundle — but it is a weaker provenance than the canonical runner, and the pattern is now recurring rather than incidental. A third sprint of this would make "verified locally" routinely mean "verified by a bespoke harness".
- **Suggested response:** defer-with-rationale, with a raised priority. The CI matrix executes these fixtures in place and is authoritative, so this sprint's evidence stands. But T-121 is a one-line change in a file this sprint touched twice, and the argument for leaving it in the backlog gets weaker each sprint. Recorded as a caveat and flagged for prioritization rather than silently deferred again.

### C-004: the Turn Contract is verified by keyword presence
- **Where:** `unit-tests.md` T-151 / `tools/operator-docs.test.sh`
- **Quote:** "`test_turn_contract_present` | all four Loop surfaces name the Turn Contract, state that it is advisory, and name the abort and human-approve boundaries"
- **Failure mode:** weak-assertion
- **Why it matters:** the test greps for `Turn Contract`, `advisory`, `abort`, and `human-approve`. Those words could satisfy the check while the contract said something materially different, and the words `abort` and `human-approve` already appear elsewhere in some of those files.
- **Suggested response:** defer-with-rationale. Prose contracts are not mechanically checkable beyond presence, and the sprint's own position is that this contract is advisory — the enforcement lives in the gates, each of which has a real behavioral test. A stronger assertion here would be checking that documentation says what it says, which is circular. The honest statement is that T-151's tests prove the contract is present and reachable, not that it is correct; correctness of prose is a review property.

### C-005: `test_gates_inert_below_contract_3` is one planned name for three separate assertions
- **Where:** `test-plan.md` Integration / `unit-tests.md`
- **Quote:** "`test_gates_inert_below_contract_3`"
- **Failure mode:** plan-test-mismatch
- **Why it matters:** the plan names a single test; the implementation spreads the property across `test_checkpoint_gates_inert_below_contract_3` in the adapter suite, a contract-2 finalize fixture in `runtime-helpers.test.sh`, and a contract-2 branch fixture. A reader checking the plan against the suite finds no test by that name.
- **Suggested response:** defer-with-rationale. The property is genuinely per-helper — each gate lives in a different script with a different fixture harness — and forcing it into one named test would mean one fixture reaching across three suites. The integration record names all three locations explicitly, so the mapping is documented even though the single planned name does not exist.

## Confidence
proceed-with-caveats
