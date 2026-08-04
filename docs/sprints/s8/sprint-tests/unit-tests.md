# Sprint 8 — Unit Tests

## T-001 (SKILL.md checkpoint philosophy)
| Test | Result |
|------|--------|
| `test_skill_checkpoint_default` | **PASS** |
| `test_skill_four_categories` (incl. unknown-blast-radius) | **PASS** |
| `test_skill_ai_verifiable_proceeds` | **PASS** |
| `test_skill_bounding_optional` | **PASS** |

## T-002 (Loop-Phase + durable guard)
| Test | Result |
|------|--------|
| `test_loop_merge_on_green_autonomous` | **PASS** |
| `test_loop_unknown_or_unverifiable_stops` | **PASS** |
| `test_loop_visual_review_checkpoint` | **PASS** |
| `test_check_merge_policy_passes` | **PASS** |
| `test_check_merge_policy_catches_drift` | **PASS** — now a COMMITTED fixture test (`tools/check-merge-policy.test.sh`, 4/4 bad states caught on temp copies) after the test critic showed the first guard false-passed |

## T-003 (command + README)
| Test | Result |
|------|--------|
| `test_command_checkpoint_lead` | **PASS** |
| `test_readme_checkpoint` | **PASS** |
| `test_no_bound_it_headline` | **PASS** (bounding marked optional in both) |
| `test_selftest_unchanged` | **PASS** (both bundles 14/14) |

**Totals: 13 passed / 0 failed / 13 total.** The C-001 guard
(`test_check_merge_policy_catches_drift`) is the substantive one — a committed,
drift-catching regression test, not a one-shot grep.
