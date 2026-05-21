# Test Critique — Sprint 8

Critic: general-purpose subagent via `prompts/test-critic.md`. `## Confidence: block`.
It fuzzed `tools/check-merge-policy.sh` and found real false-passes — the guard
added to satisfy the *prior* critic's C-001 didn't actually enforce.

## Concerns + responses

### C-001: the consistency guard passes on contradictory states (per-file checks gated behind literal `gh pr merge`) — BLOCK
- **Response:** fix-in-plan/build (done). Rewrote `check-merge-policy.sh` to assert POSITIVE signals, whitespace-normalized: each loop doc must contain a merge-proceeds-autonomously signal AND a checkpoint-exception signal; SKILL.md must contain the stop criterion AND positively permit merging a green PR. A blanket prohibition, an emptied file, or a reworded merge-revoke now FAILS by lacking the required positive signal — not by matching a banned literal (which the critic showed is trivially dodged via rewording/whitespace). Re-verified: guard passes on current docs.

### C-002: drift test was manual inject-and-revert, not committed — BLOCK
- **Response:** add-test (done). Added committed `tools/check-merge-policy.test.sh` — fixture-based, operates on TEMP COPIES (never tracked files), mutates them into the exact bad states the critic found (emptied doc; reworded blanket prohibition with whitespace dodge; SKILL merge-revoke) and asserts the guard exits non-zero. Result: **4/4 caught** (incl. baseline-good passes). Re-runnable; the CI hook the EARS clause promised.

### C-003: "neither recommends bounding as primary" lacked a positional assertion
- **Response:** tighten (done). Verified positionally that the human-verification checkpoint framing PRECEDES the optional `/loop N` bounding aside within both the command and README auto-mode sections. (The earlier full-file grep false-matched an unrelated "optional" in the README install section; scoped check confirms order.)

### C-004: E2E both-path verification is manual prose with no recorded outcome
- **Response:** defer-with-rationale (done). e2e-tests.md now states explicitly it is a NOT-YET-EXECUTED launch-time manual checklist (auto mode is harness-level, unobservable from bash), so the test-report does not imply the stop path was observed.

## Confidence (post-response)
Was `block`; resolved. The decisive C-001/C-002 are fixed with a hardened
positive-signal guard + a committed fixture drift-test proven to catch 4/4
bad states. C-003 tightened, C-004 clarified. The test critic correctly caught
that my first guard was security theater — the second one actually guards.
