# Sprint 3 — Integration Tests

The 11-step `selftest.sh` is the integration harness: it composes
`init-sprint.sh`, `finalize-plan.sh`, `commit-task.sh`, `abort-sprint.sh`,
and `current-phase.sh` end-to-end through every transition the protocol
defines, in one bash process.

| Test | Result |
|------|--------|
| `test_full_phase_walk_with_backfill` — selftest 11 steps run from each bundle's installed scripts | **PASS** (both bundles: `all 11 transitions matched`) |

**Totals: 1 passed / 0 failed / 1 total** (× 2 bundles = 2 runs, both green).
