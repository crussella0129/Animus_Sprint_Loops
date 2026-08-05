# Sprint 13 Unit Tests

Bash-executed checks mapped 1:1 to build-plan EARS clauses. All PASSED.

## T-001 (finalize critique gate)
- `test_gate_refuse_missing` — selftest step 16: valid research/plan, no critique.md → finalize refuses, plans unlocked. PASS
- `test_gate_refuse_block` — selftest step 17 stage 1: `` `block` `` verdict → refuses, unlocked. PASS
- `test_gate_refuse_malformed` — temp fixture: `## Confidence` verdict line "The plan looks fine to me." → exit 1, unlocked, message states the expected verdict shape (clean/proceed-with-caveats/block, optionally backticked). PASS
- `test_gate_accept_clean` — selftest steps 04 / 17-stage-2 lock with a `clean` verdict. PASS
- `test_gate_accept_pwc` — temp fixture: bare `proceed-with-caveats` verdict → locks. PASS
- `test_gate_no_prose_false_match` — temp fixture: valid `proceed-with-caveats` verdict, concern body reads "this could block the sprint if unblocked improperly" → LOCKS (verdict parse scoped to the first non-empty line after `## Confidence`). PASS
- `test_gate_near_miss_refused` (added per test-critique C-001) — selftest step 17: verdict line `cleanish` → refused as malformed (exact-token match, not prefix glob), message states the shape. PASS
- `test_gate_inline_form` (added per test-critique C-002) — `## Confidence: clean` inline verdict → LOCKS (parser accepts both the inline and heading-then-next-line forms the phase docs model). PASS
- `test_gate_all_committed_critiques_parse` — the five committed critiques (s11/s12 plan+test, s13 plan) all reduce to `proceed-with-caveats` → accept; none wrongly refused/accepted. PASS
- `test_gate_message_content` (added per test-critique C-003) — selftest step 16 asserts the missing-critique refusal names the critic protocol; step 17 asserts the malformed refusal states the verdict shape. PASS
- `test_gate_ordering` — empty-plan check hoisted before the critique gate; selftest steps 10/12/13 still refuse at their own gates (empty-plan / decisions / budget) without needing critique fixtures — verified by selftest staying green with those steps' fixtures unchanged. PASS

## T-002 (routing gate)
- `test_routing_report_no_critique` — temp fixture (build done): test-report present, critique absent → `test`. Also selftest step 07a. PASS
- `test_routing_report_plus_critique` — both present → `loop`. Also selftest step 07b. PASS
- `test_routing_failure_exempt` — failure-report.md only → `loop` (critique not required on the failure path). PASS
- `test_selftest_17` — "all 17 transitions matched". PASS
- Negative arm (recorded, not committed): a throwaway current-phase.sh with the routing change reverted to the old single-line behavior → selftest step 07a FAILS (report-without-critique wrongly routes `loop`). PASS

## T-003 (docs)
- `test_doc_presence` — greps pass: "Critique gate" in claude 03 + codex 03; "Routing gate (sprint 13)" in claude 05 + codex 05 (parity-identical); "REFUSES to lock unless" in oh particle 03; "will not advance to Loop until" in oh particle 07; "antigravity's Plan sync-step adds" in ROADMAP §6. PASS
- `test_guards_after_docs` — check-bundle-sync.sh + check-merge-policy.sh green. PASS

**Unit totals: 18 passed / 0 failed / 18 total** (12 planned + 2 negative arms + 4 test-critic-added: near-miss refusal, inline form, committed-critique corpus, message content).
