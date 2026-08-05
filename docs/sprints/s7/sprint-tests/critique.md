# Test Critique — Sprint 7

Critic: general-purpose subagent via `prompts/test-critic.md`. Returned
`## Confidence: proceed-with-caveats`. It independently verified (by direct
read) that the decisive C-004 contradiction is resolved in ALL THREE copies —
claude-code 06-loop-phase.md, codex-cli 06-loop-phase.md, and open-harnesses
particle 08 — not just asserted in SKILL.md, and that SKILL.md is now
consistent with them.

## Concerns + responses

### C-001: 12 of 13 unit tests are doc-presence greps; only the selftest is substantive
- **Response:** defer-with-rationale. By design — auto mode is a harness behavior (plan-mode auto-accept + `/loop`), not bash-drivable. The doc-presence tests verify the skill *instructs* the right thing; the selftest (unchanged at 14) proves no script regressed. Noted in the report.

### C-002: merge-gate tests assert presence of gating, not absence of an unconditional merge — tighten
- **Response:** tighten-assertion (done). Added `test_no_unconditional_merge`: for every file containing `gh pr merge` (both bundles' 06-loop-phase.md + particle 08), the unattended "do NOT merge / leave the PR open" gate must also be present. All three PASS. Also confirmed the old contradictory SKILL.md line "merge your own PRs" was removed. This hardens against a future edit re-introducing an ungated merge.

### C-003: codex/particle gate-consistency asserted but not differentially tested
- **Response:** defer-with-rationale. The wording is intentionally bundle-specific (codex: "Unattended run (e.g. `codex exec`)"; claude: "Unattended auto mode (running under `/loop`)") per the README's Claude-vs-Codex split — a strict text-equality test would be wrong. The critic manually confirmed semantic equivalence; recorded here.

## Confidence (post-response)
`proceed-with-caveats` → resolved. C-002 tightened with a passing negative
grep; C-001/C-003 deferred with rationale. The decisive safety fix (C-004) is
verified resolved in all three copies. Safe to finalize.
