# Plan Critique — Sprint 17

## Concerns

### C-001: the routing-regression clause has no test in its own task block
- **Where:** `build-plan.md` T-138 / `test-plan.md` "T-138 unit tests"
- **Quote:** "**WHEN** `current-phase.sh` runs against a Book carrying no `substrate-version` line, **THEN** it **SHALL** print the same phase token for that fixture as it printed before this sprint."
- **Failure mode:** plan-test-mismatch
- **Why it matters:** the clause is the sprint's whole backwards-compatibility claim. Its test lives in the Integration section under a different heading, so a reader checking T-138's coverage task-by-task finds the clause unverified and may conclude the claim is asserted rather than tested.
- **Suggested response:** fix-in-plan — **applied.** The T-138 unit block now names `test_routing_unchanged_for_unstamped_book` and points to its real location in `book-routing.test.sh`, with the reason it lives there.

### C-002: the stamp step, as ordered, would make convergence fail its own verification
- **Where:** `build-plan.md` T-139 Notes (as originally drafted)
- **Quote:** "the stamp is the terminal step, after post-deploy verification succeeds"
- **Failure mode:** hidden-dep
- **Why it matters:** material. `deploy-substrate.sh` ends by running `check-substrate.sh` and failing unless it reads exactly `substrate-complete`. Once T-138 lands, a complete-but-unstamped Book reports `substrate-outdated:1->2`. A stamp placed after that verification would therefore make convergence fail on precisely the projects it exists to upgrade — the sprint's primary acceptance criterion — and the failure would surface only when T-138 and T-139 were both present, not while either was developed alone.
- **Suggested response:** fix-in-plan — **applied.** T-139 now specifies the stamp step runs **before** the final verification, states the ordering constraint and its cause in the task Notes, adds an EARS clause requiring convergence's own verification to observe `substrate-complete` on a previously unstamped Book, and adds `test_converge_verifies_after_stamp` to prove the ordering rather than assume it.

### C-003: bumping the bundle version requires editing five files in agreement
- **Where:** `build-plan.md` T-140
- **Quote:** "`plugin.json` gains a matching `version`; the manifest guard fails when the two disagree"
- **Failure mode:** hidden-dep
- **Why it matters:** the guard makes disagreement observable, which is the point, but a version bump now touches four byte-parity copies of `bundle-version.sh` plus `plugin.json`, and a partial bump fails two guards with two different diagnostics. This is an accepted cost rather than a defect, but it should be a recorded consequence of the intent rather than a surprise discovered at the first bump.
- **Suggested response:** defer-with-rationale — the coupling is the mechanism working as designed, and `check-bundle-sync.sh` plus `check-plugin-manifest.sh` between them name every file that disagrees. Recorded here as sprint provenance; no plan change.

## Confidence
clean
