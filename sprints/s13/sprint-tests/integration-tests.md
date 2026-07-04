# Sprint 13 Integration Tests

## test_full_guard_round — PASS

`bash tools/run-guards.sh --determinism --out sprints/s13/sprint-tests/guards-report.ndjson`
after all three tasks: **7/7 suites PASS, all `"determinism":"ok"`**. The round
composes the new finalize critique gate + routing gate (both exercised end-to-end
by selftest's 17 transitions), the propagated ×4 scripts (bundle-sync parity),
and the edited phase docs (merge-policy consistency).

Baseline continuity vs the s12 committed baseline: six of seven suites' evidence
hashes byte-identical; only `selftest` re-baselined — its output legitimately
grew (steps 16, 17, and the 07a/07b split). The finalize-plan.sh and
current-phase.sh changes do not alter any suite's *output* except selftest's,
so the other suites' hashes are unchanged — the expected signature of a
behavior-preserving-except-where-intended change.

**Integration totals: 1 passed / 0 failed / 1 total (7 suites × 2 runs).**
