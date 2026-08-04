# Sprint 12 Test Report

## Summary
- Unit tests: 13 passed / 0 failed / 13 total (incl. two negative-arm verifications: fill-all back-fill regression and abort-timestamp no-op both genuinely caught)
- Integration tests: 1 passed / 0 failed / 1 total (`test_full_guard_round` — 7 suites × 2 determinism runs)
- E2E tests: 1 passed / 0 failed / 1 total (`test_ci_matrix_e2e` — both matrix legs, twice: runs 28694240195 and 28694489982)
- CI status: green (both legs)

## CI Confirmation
- **Head SHA:** `7e14676b12cec35e1b02edb0e4fd2009380b283d`
- **CI run:** 28694489982 — https://github.com/crussella0129/sprint-loops/actions/runs/28694489982
- **Conclusion:** success — per-job: `guards (ubuntu-latest)` success, `guards (macos-latest)` success (authoritative via `gh run list` / `gh run view --json jobs`)
- **Confirmations:** `sprints/s12/sprint-tests/guards-report.ndjson` (local, committed) + per-OS artifacts `guards-report-ubuntu-latest` / `guards-report-macos-latest` on each run

## Failures
None.

## Technical Debt Identified
- Which hash tool `hash_stdin`'s auto-detect selects on a given CI host is not recorded in run evidence (test-critique C-002); a one-line `command -v sha256sum || echo no-sha256sum` breadcrumb step is a cheap future add.
- shellcheck's evidence hash is the empty-output digest, so its "baseline unchanged" adds no information — the normalization no-op proof rests on the five content-bearing suites (test-critique C-003, noted for precision).
- Carried from s11 (unchanged): merge-policy guard's `( -CI)?` regex quirk; ndjson field assertions unscripted until T-101.

## Coverage Observations
- Every T-001/T-002/T-003/T-004 EARS clause maps to a recorded passing test; the two contract-critical rewrites (awk back-fill, abort edits) are each guarded by a selftest step with a verified negative arm — deleting the `done` guard or the timestamp expression makes the suite fail.
- Baseline continuity across the portability refactor: six of seven suites' evidence hashes byte-identical to the s11 committed baseline; selftest re-baselined once for a documented output change (step 15) and held stable through the step-09 assertion additions (silent on success).
- The macos-latest leg executed the full suite twice under `--determinism` on BSD userland/macOS bash — the sprint's portability claim is now a continuously re-verified CI invariant, not a one-time audit.
