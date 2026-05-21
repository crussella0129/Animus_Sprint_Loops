# Plan Critique — Sprint 6

Critic: general-purpose subagent, invoked via Agent tool with `prompts/plan-critic.md`.
First dogfood run of sprint 5's critic protocol.

## Concerns

### C-001: Counter regex will overcount the markdown-table header + separator rows
- **Where:** `build-plan.md` T-001 Notes / `test-plan.md` `test_counter_within_budget`
- **Failure mode:** plan-test-mismatch
- **Why it matters:** The proposed regex `^\| [^|]+\|` matches the schema's `| File | Relevance | Notes |` header AND the `|------|...` separator. A "5 data rows" report would produce `files=7`. The first unit test would fail at green-build, and a 19-data-row report would silently fail the 20-file budget.
- **Response:** **fix-in-plan** — updated T-001 Notes to slice with awk + `tail -n +3` to skip header+separator. Updated EARS clause language. Added `test_counter_skips_header_and_separator` to test plan.

### C-002: T-002 EARS criterion isn't fully covered by `test_phase_02_mentions_budget_gate`
- **Where:** `build-plan.md` T-002 first EARS clause vs `test-plan.md` Unit Tests T-002
- **Failure mode:** plan-test-mismatch
- **Why it matters:** Clause mandates 4 tokens (`20`, `5`, `Budget Override`, "non-empty justification"). Test asserts only 2. A doc saying "20-file budget; override available" would pass the test while violating the EARS.
- **Response:** **fix-in-plan** — extended `test_phase_02_mentions_budget_gate` to assert all four tokens, and same fix for the schema/particle equivalents.

### C-003: T-003 bundles two distinct concerns (sync vs new selftest step)
- **Where:** `build-plan.md` T-003 description
- **Failure mode:** granularity
- **Why it matters:** Authoring selftest step 13 vs syncing scripts/docs are distinct logical concerns.
- **Response:** **defer-with-rationale** — keeping T-003 as one task. The three success criteria are tightly coupled (you can't sync a new selftest without syncing the script it depends on), and historical sprints (1, 3, 5) used the same single-sync-task pattern. Splitting now would be inconsistency for marginal benefit. Worth revisiting at a future protocol-level refactor.

### C-004: T-002 modifies `phases/02-research-phase.md` only in claude-code; codex's copy lives in T-003
- **Where:** `build-plan.md` T-002 Touches vs T-003 Touches
- **Failure mode:** hidden-dep / granularity
- **Why it matters:** The boundary between T-002 (claude canonical) and T-003 (codex propagation) is implicit, not stated.
- **Response:** **fix-in-plan** — added a one-line note to T-002 stating that the file it touches is the canonical claude-code copy and T-003 propagates to codex (follows the bundle-sync pattern from sprints 1-5). No file changes needed; just clarifies the boundary.

### C-005: Integration test only exercises one of three install bundles
- **Where:** `test-plan.md` Integration Tests
- **Failure mode:** missing-risk / plan-test-mismatch
- **Why it matters:** A codex-side install regression would ship undetected. The md5 identity check catches script-content drift but not install-script bugs.
- **Response:** **fix-in-plan** — added `test_install_codex_then_selftest_13` as a parallel integration test.

### C-006: E2E status names no unlocking sprint
- **Where:** `test-plan.md` End-to-End Tests
- **Failure mode:** e2e-drift
- **Why it matters:** "not-yet-possible" without an unlocking sprint becomes permanent boilerplate.
- **Response:** **fix-in-plan** — replaced wording with explicit "**never** at the bash-test level; LLM-harness E2E would require building a replay harness, not currently planned."

### C-007: `## Budget Override` body-check regex is unspecified
- **Where:** `build-plan.md` T-001 EARS clauses 3 & 4
- **Failure mode:** EARS-vague
- **Why it matters:** "Non-blank body line" is the binding term but no regex is specified. The test can't bind without an implementation pattern.
- **Response:** **fix-in-plan** — added to T-001 Notes: awk-slices between `^## Budget Override$` and the next `^## ` heading, then tests for `grep -qE '^[^[:space:]]'` to find a non-blank, non-whitespace-only body line.

### C-008: Sprint 0 / no-research path not unit-tested for the finalize side
- **Where:** `research-report.md` Risk #3 / `test-plan.md`
- **Failure mode:** missing-risk (partial)
- **Why it matters:** `test_counter_missing_sections` covers counter graceful return, but not the finalize path.
- **Response:** **defer-with-rationale** — the counter graceful return (exit 0) means `finalize-plan.sh` never sees a non-zero return for missing sections, so the budget gate never fires for sprint 0 / new projects. The counter test is the relevant coverage; adding a finalize-side test would duplicate it.

## Confidence

`proceed-with-caveats` per the critic. 6 fix-in-plan responses, 2 defer-with-rationale.
Plans amended below before `finalize-plan.sh`.
