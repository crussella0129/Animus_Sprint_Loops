Finalized - DO NOT EDIT

# Sprint 13 Test Plan

Bash-executed checks mapped 1:1 to build-plan EARS clauses.

## Unit Tests

### T-001 unit tests (finalize critique gate)
- `test_gate_refuse_missing`: temp project, plans + research valid, NO critique.md → finalize refuses, plans unlocked, message names the critic protocol.
- `test_gate_refuse_block`: critique with `## Concerns` + `## Confidence` → `` `block` `` first line → refuses.
- `test_gate_refuse_malformed`: critique missing `## Concerns` heading; separately, `## Confidence` with no recognizable verdict line → refuses both, and the message states the expected verdict shape (critique C-003).
- `test_gate_accept_clean` / `test_gate_accept_pwc`: verdicts `clean` (bare) and `` `proceed-with-caveats` `` (backticked) → gate passes, plans lock.
- `test_gate_no_prose_false_match`: valid `proceed-with-caveats` verdict; concern body contains the words "block" and "unblocked" → gate passes.
- `test_gate_ordering`: fixtures for steps 10/12/13 (empty-plan, decisions, budget) now INCLUDE valid critiques → each still refuses for its own reason (verified via selftest staying green step-by-step).

### T-002 unit tests (routing gate)
- `test_routing_report_no_critique`: test-report present, critique absent → `test`.
- `test_routing_report_plus_critique`: both present → `loop`.
- `test_routing_failure_exempt`: failure-report only → `loop`.
- `test_selftest_17`: selftest reports "all 17 transitions matched" (15 existing + step 16 refuse-missing-critique + step 17 refuse-block, both landing in T-001; step 07 two-stage walk asserts report-without-critique → `test`).
- Negative arm (recorded, not committed): throwaway current-phase.sh with the routing change reverted → the report-without-critique selftest step FAILS.

### T-003 unit tests (docs)
- `test_doc_presence`: greps for the gate sentences in claude 03, codex 03, 05 (×2 identical), oh particles 03 + 07; ROADMAP §6 antigravity note.
- `test_guards_after_docs`: check-bundle-sync.sh + check-merge-policy.sh green.

## Integration Tests
- `test_full_guard_round`: `tools/run-guards.sh --determinism` full local pass; evidence hashes byte-identical to the s12 baseline EXCEPT selftest (documented output growth from the new steps — re-baselined, internally deterministic).

## End-to-End Tests
- **Status:** possible
- `test_ci_matrix_e2e`: push `sprint-13` → both matrix legs (`guards (ubuntu-latest)`, `guards (macos-latest)`) conclude success on the head SHA; per-OS artifacts present.
- Dogfood note: s13's own plans lock BEFORE the gate exists; its critiques exist per protocol regardless. The first sprint mechanically gated is s14 — recorded as expectation, verified next sprint.
