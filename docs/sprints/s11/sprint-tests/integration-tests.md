# Sprint 11 Integration Tests

## test_full_guard_round — PASS

`bash tools/run-guards.sh --determinism --out sprints/s11/sprint-tests/guards-report.ndjson`
after all 8 tasks landed. This composes every deliverable in one round: the
refactored scripts (exercised by selftest), both guard/fixture pairs, the
plugin manifest check, shellcheck over the changed script set, and the edited
docs (parity-checked by bundle-sync).

Result: **7/7 suites PASS, all `"determinism":"ok"`** (each suite run twice,
normalized evidence hashes equal). Confirmations recorded at
`sprints/s11/sprint-tests/guards-report.ndjson`.

Cross-run stability (stronger than the within-run check): the final round's
evidence hashes are byte-identical to the standalone runs earlier in the
sprint — e.g. selftest `cf5e5077…`, merge-policy-test `3a675049…`,
bundle-sync-test `2911cdcf…`, shellcheck `e3b0c442…` (the sha256 of empty
output, as expected for a clean lint) — demonstrating the output
normalization holds across separate invocations, not just within the
determinism double-run.

**Integration totals: 1 passed / 0 failed / 1 total (composed of 7 suites × 2 runs).**
