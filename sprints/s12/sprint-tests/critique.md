# Test Critique — Sprint 12

Critic: subagent (general-purpose) run with `prompts/test-critic.md`. Verdict: `proceed-with-caveats`.
Primary-agent responses inline as **Response:**.

## Concerns

### C-001: Abort's timestamp + abort-note EARS sub-clauses have zero assertions anywhere
- **Failure mode:** EARS-coverage | weak-assertion
- **Why it matters:** Step 09 asserted only routing, which flips on the Exit-status edit alone — the timestamp substitution and abort-note append could be deleted and every test would still pass. Same silent-sed-no-op class this repo has documented twice.
- **Response: add-test — APPLIED.** Step 09 now greps for a real `End timestamp: 20xx-` value and the `## Abort note` heading after the abort, failing loudly on either miss. Negative arm verified: a throwaway abort-sprint.sh with the timestamp expression deleted makes step 09 FAIL. Propagated ×4; selftest still 15/15 (assertions are silent on success, so the suite's output/evidence hash is unchanged); unit-tests.md record corrected to describe what step 09 actually asserts.

### C-002: E2E states "shasum fallback path" as observed fact; it's an inference with no recorded evidence
- **Failure mode:** e2e-cop-out (claim tightness)
- **Response: tighten-assertion — APPLIED.** e2e-tests.md reworded: the macos leg ran "on a host where the shasum fallback is the expected auto-detect path"; tool selection is not recorded in run evidence and the shasum path's correctness rests on the seam test. (Optional future: a one-line `command -v sha256sum || echo no-sha256sum` CI breadcrumb.)

### C-003: shellcheck suite's baseline-continuity and determinism evidence is vacuous (empty-string hash)
- **Failure mode:** weak-assertion
- **Response: defer-with-rationale — APPLIED as note.** test-report.md states the no-op-normalization proof rests on the five content-bearing suites; shellcheck's evidence hash is the empty-output digest (its PASS is still substantive via exit code).

## Confidence
`proceed-with-caveats` — C-001 applied with negative-arm verification; C-002/C-003 applied as wording/report precision. Critic independently re-verified the E2E live (run 28694240195, both matrix jobs success, artifacts 891/903 B) and the six-of-seven baseline-hash claim byte-accurate.
