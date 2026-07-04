# Test Critique — Sprint 13

Critic: subagent (general-purpose) run with `prompts/test-critic.md`. Verdict: `proceed-with-caveats`.
Primary-agent responses inline as **Response:**.

## Concerns

### C-001: Verdict parser diverged from the spec regex (accepted `cleanish`); gap untested
- **Failure mode:** weak-assertion + stub-leak
- **Why it matters:** The shipped `case` globs (`clean*`) accepted `cleanish`, which the build-plan's specified boundary regex would reject; no test exercised the verdict-token boundary.
- **Response: tighten-assertion — APPLIED.** Parser rewritten to reduce the verdict line to a bare TOKEN (drop leading backtick, cut at first whitespace, drop trailing backtick) and EXACT-match against clean/proceed-with-caveats/block. `cleanish`, `blocked`, etc. now hit the malformed branch. selftest step 17 gains a `cleanish` near-miss case asserting refusal. Verified: all five committed critiques still parse to `proceed-with-caveats` (accept); `cleanish` refused.

### C-002: Inline `## Confidence: <verdict>` form (modeled in the phase docs) parsed as malformed
- **Failure mode:** negative-path (untested refuse on a doc-modeled input)
- **Why it matters:** The phase docs reference `## Confidence: block`, but the awk skipped the heading line and read the next line, so the inline form was silently refused.
- **Response: add-support — APPLIED.** Parser now accepts BOTH forms: an inline `## Confidence: <verdict>` (verdict extracted from the heading line) or the heading-then-next-line form the critic prompts produce. Verified: `## Confidence: clean` locks. Removes the doc-vs-impl inconsistency the critic identified rather than just deferring it.

### C-003: Message-content SHALLs (name the protocol / state the shape) only spot-checked in an uncommitted fixture
- **Failure mode:** weak-assertion
- **Why it matters:** The committed selftest asserted only exit code + no-lock for steps 16/17; a future edit dropping the help text wouldn't turn selftest red — the exact vacuity class s11/s12 flagged.
- **Response: tighten-assertion — APPLIED.** selftest step 16 now captures stderr and greps for `critic` (protocol pointer); step 17's malformed case greps for the `clean, proceed-with-caveats, or block` shape hint. Both message SHALLs are now guarded by the committed regression suite.

### C-004: E2E claim rested on a still-running CI matrix
- **Failure mode:** e2e-cop-out (judged on its own terms)
- **Response: resolved — the matrix completed green while this critique ran.** Both legs `success` on head `3376df0` (run 28707543957); a second confirming run follows the test-critic fixes. The test-report records the observed conclusion, not an inference. (The dogfood note — s13's own plans locked before the gate existed; s14 is the first mechanically-gated sprint — stands as an honest scope statement.)

## Confidence
`proceed-with-caveats` — C-001 and C-003 (substantive coverage gaps against this sprint's own EARS) both APPLIED with committed-selftest assertions; C-002 fixed rather than deferred; C-004 resolved by the green matrix. Critic verified the gate accepts every real critique format and selftest is a genuine 17/17.
