# Plan Critique — Sprint 18

## Concerns

### C-001: the contract-version clause of T-146 had no named test
- **Where:** `build-plan.md` T-146 / `test-plan.md` "T-146 unit tests"
- **Quote:** "**WHEN** `book_substrate_version()` reads a Book stamped `2`, **THEN** it **SHALL** print `2` while `BOOK_SUBSTRATE_CONTRACT_VERSION` reports `3`."
- **Failure mode:** plan-test-mismatch
- **Why it matters:** this clause is what makes every other gate conditional. Its verification was only implied by the integration regression, so a defect in the version comparison — the mechanism the whole sprint rests on — would have had no test that named it.
- **Suggested response:** fix-in-plan — **applied.** `test_contract_3_sees_stamp_2_as_behind` now asserts the accessor value, the bundle constant, and the resulting `substrate-outdated:2->3` in one fixture.

### C-002: recording the checkpoint would leave the Book dirty for the next sprint's own gate
- **Where:** `build-plan.md` T-150
- **Quote:** "its URL **SHALL** be recorded once in the sprint metadata `Checkpoint` field"
- **Failure mode:** hidden-dep
- **Why it matters:** material, and self-inflicted. `open-pr` runs *after* `close-sprint.sh` has committed the sprint record. Writing the `Checkpoint` field at that point makes `remote-adapter.sh` a Book writer for the first time and leaves an uncommitted Book change behind — which is precisely the condition T-147's tracked-evidence gate refuses. The next sprint's plan lock or close would then fail on a dirty Book created by the previous sprint's own checkpoint, and the cause would be several steps removed from the symptom.
- **Suggested response:** fix-in-plan — **applied.** The clause now requires the record to be committed in one scoped commit, following the `close-sprint.sh` precedent; `test_checkpoint_record_is_committed` asserts `check-tracked.sh` passes afterwards; and T-150's notes state the reason so the coupling is not rediscovered later.

### C-003: the sprint's own Loop has an ordering constraint the plan did not state
- **Where:** `test-plan.md` End-to-End
- **Quote:** "converge **this repository** from contract 2 to 3 and take its own Sprint 18 checkpoint through the newly gated adapter"
- **Failure mode:** hidden-dep
- **Why it matters:** convergence to contract 3 modifies `docs/.sprint-loop-book`. Once the Book is at 3, `close-sprint.sh` refuses a dirty Book — including the marker change convergence just made. Running the E2E in the obvious order (converge, then close) fails on itself. This sprint is the first to gate its own close, so the constraint has never been exercised.
- **Suggested response:** fix-in-plan — **applied.** `test_repository_converges_before_close` names the required Loop order explicitly: converge → commit → validate → close → checkpoint.

### C-004: T-146 carries two separable concerns
- **Where:** `build-plan.md` T-146
- **Quote:** "Raise the substrate contract to 3 and add the tracked-evidence helper"
- **Failure mode:** granularity
- **Why it matters:** a version raise and a new helper are independent changes sharing one commit boundary, so the diff will not read as a single logical unit.
- **Suggested response:** defer-with-rationale. They are separable but not independent *in effect*: every later task's gate needs both the helper and the version to exist, and splitting them produces an intermediate commit where the contract has been raised while nothing yet reads it — a state that would make this repository report `substrate-outdated` with no gate to justify it. Keeping them together means the contract version and the first thing that uses it arrive at the same boundary.

### C-005: five preserved fixtures are asserted by name, not by behavior
- **Where:** `test-plan.md` T-150
- **Quote:** "Preserved: `test_pr_opens_once`, `test_pr_refuses_existing_checkpoint`, `test_provider_fallback_generic`, `test_merge_policy_human_approve`, `test_head_override_rejected`."
- **Failure mode:** weak-assertion
- **Why it matters:** each of those fixtures must be rewritten to carry a closed-sprint Book, and a rewrite is where an assertion quietly loses its teeth — a fixture can keep its name and stop proving what it was written to prove.
- **Suggested response:** defer-with-rationale. The mitigation is procedural rather than a new test: each rewritten fixture keeps its original assertion lines unchanged, and only its setup grows a Book. The Test phase will diff the fixture file to confirm that every original assertion survived, and record that in the unit-test evidence rather than asserting it in code.

## Confidence
clean
