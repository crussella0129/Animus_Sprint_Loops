# Sprint 12 Integration Tests

## test_full_guard_round — PASS

`bash tools/run-guards.sh --determinism --out sprints/s12/sprint-tests/guards-report.ndjson`
after all four tasks landed: **7/7 suites PASS, all `"determinism":"ok"`**. The
composed round exercises the portable scripts (selftest's 15 transitions run the
rewritten abort + awk back-fill), the portable runner (hash_stdin auto-detect on
this sha256sum host), the fixture tests, and bundle-sync parity across the four
propagated bundles — together.

Baseline continuity: six of seven suites' evidence hashes are byte-identical to
the sprint-11 committed baseline; the seventh (selftest) re-baselined for the
documented reason (step 15 added to its output) and is internally deterministic.

**Integration totals: 1 passed / 0 failed / 1 total (7 suites × 2 runs).**
