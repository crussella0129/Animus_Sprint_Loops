# Test Critique — Sprint 6

Critic: general-purpose subagent via `prompts/test-critic.md`. Returned
`## Confidence: block` — two real EARS-coverage gaps. First dogfood of the
test-critic; it caught genuine omissions.

## Concerns

### C-001: Sources-over-budget path had no executed test (BLOCK)
- **Failure mode:** EARS-coverage
- **Why it matters:** T-001's exit-code EARS clause is `exit 0 if N≤20 AND M≤5, exit 1 otherwise`. `test_counter_over_files_budget` covered the files half; the sources half (`M>5`) had no test — the plan listed `test_counter_over_sources_budget` but the results dropped it (silently became "7/7" instead of 8).
- **Response:** **add-test** — ran `test_counter_over_sources_budget`: 10 URLs → `files=0 sources=10`, exit 1. **PASS.** Restored to unit-tests.md.

### C-002: Override-present-but-empty-body negative path untested (BLOCK)
- **Failure mode:** negative-path
- **Why it matters:** The override gate's binding term is "non-whitespace body line." The only block-test deleted the whole `## Budget Override` section, never driving the `grep -cE '^[^[:space:]]'` body check. A bug accepting any present heading (even blank body) would pass — defeating the justification requirement that plan-critic C-007 hardened.
- **Response:** **add-test** — ran `test_finalize_blocks_override_heading_empty_body`: over-budget report with `## Budget Override` heading followed by a blank line + a whitespace-only line → `finalize-plan.sh` still prints "budget exceeded" and does NOT lock. **PASS.** The awk heading match `^## Budget Override[[:space:]]*$` + body check `^[^[:space:]]` correctly rejects empty/whitespace bodies.

### C-003: Numeric-prefix heading tolerance not exercised
- **Failure mode:** EARS-coverage (weak)
- **Response:** **add-test** — ran `test_counter_bare_heading_variant`: `## Existing Code Survey` (no numeric prefix), 2 rows → `files=2`. **PASS.** Confirms the `^## ([0-9]+[.] *)?` alternation matches both forms.

### C-004: Integration tests re-assert the unit selftest signal
- **Failure mode:** integration-drift (mild)
- **Response:** **defer-with-rationale** — the install→selftest path DOES prove the new interaction: selftest step 13 invokes `finalize-plan.sh` → `research-budget.sh` via `SCRIPT_DIR` sibling resolution from the INSTALLED location. If `install.sh` failed to place `research-budget.sh`, step 13 would crash with the unbound-`SCRIPT_DIR`/missing-file error (the exact second build bug). So a green step 13 from the installed bundle is direct evidence the install placed the new script correctly. A separate presence-assert would be belt-and-suspenders; deferred.

### C-005: Confirm step 13 asserts both outcomes
- **Response:** **confirmed** — step 13 in `selftest.sh` has FAIL guards for BOTH the refuse branch (over-budget no-override → non-zero + not locked) AND the accept branch (override added → exit 0 + lock header present). 5 guard/print lines verified.

## Confidence (post-response)
Was `block`; now resolved. The two blocking gaps (C-001, C-002) have passing tests; C-003 added; C-004 deferred with rationale; C-005 confirmed. Safe to finalize test-report.
