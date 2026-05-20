# Sprint 1 — Integration Tests

## Component A+B+C integration

| Test | Method | Result |
|------|--------|--------|
| `test_full_phase_walk_with_abort` | Each bundle's `selftest.sh` walks all 9 transitions in one process: `uninitialized` → `research` → `plan` → `build (not started)` → `build (in progress)` → `test` → `loop` → `ready-for-next-sprint` (via success) → `ready-for-next-sprint` (via abort). Runs `init-sprint.sh`, `finalize-plan.sh`, and `abort-sprint.sh` along the way. | **PASS** — `selftest: all 9 transitions matched` from both claude-code/loop-sprint and codex-cli/sprint-loops bundles. |

**Totals: 1 passed / 0 failed / 1 total** (per bundle = 2 runs total, both green).
