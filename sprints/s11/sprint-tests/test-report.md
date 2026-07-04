# Sprint 11 Test Report

## Summary
- Unit tests: 28 passed / 0 failed / 28 total (27 planned + 1 critic-added; 1 tightened post-critique and re-run)
- Integration tests: 1 passed / 0 failed / 1 total (`test_full_guard_round` — 7 suites × 2 determinism runs, all `"determinism":"ok"`)
- E2E tests: 1 passed / 0 failed / 1 total (`test_ci_e2e` — live GitHub Actions rounds on both branch heads)
- CI status: green

## CI Confirmation
- **Head SHA:** `d403825732cf69ad57b9e83ef9df7425b0712bfd`
- **CI run:** 28693323277 — https://github.com/crussella0129/sprint-loops/actions/runs/28693323277
- **Conclusion:** success (authoritative — from `gh run list`, not `gh run watch`; prior head `47a4a2d…` run 28687496893 also success with `guards-report` artifact, 883 bytes)
- **Confirmations:** `sprints/s11/sprint-tests/guards-report.ndjson` (local, committed) + the `guards-report` artifact on each CI run — one evidence record per suite

## Failures
None. Two latent defects were *discovered and fixed* during this sprint's test work (not failures of this sprint's deliverables):
- `check-merge-policy.test.sh` drift cases had been vacuous since sprint 8 (quoted command string → exit-127 counted as "caught"); de-vacuating exposed a second false-pass (phrase-level sed spanning hard-wrapped lines). Root causes fixed; 4/4 genuinely caught, verified via the intermediate 3/4 failure.
- The critic-driven tightening of `check-bundle-sync.test.sh` surfaced a `set -e` truncation hazard in the expected-failure capture path; fixed with `|| rc=$?`, 5/5 with path-naming assertions.

## Technical Debt Identified
- `check-merge-policy.sh`'s permit regex alternative `merging a green( -CI)? PR` can never match the hyphenated "green-CI PR" form (space before `-CI`); harmless today because the plain "green PR" alternative matches the real SKILL.md, but worth a one-char fix next time that guard is touched.
- `run-guards.sh` `normalize()` temp-path pattern is `/tmp/tmp.*`-only — annotated into backlog T-102 so the future macos CI leg doesn't false-fail (test-critique C-004).
- ndjson field assertions not yet scripted for reuse (test-critique C-003) — folded into T-101 (array-test integration), where the record format becomes load-bearing.

## Coverage Observations
- Every build-plan EARS clause (T-001…T-008) maps to at least one recorded, passing test; the test critic verified the load-bearing ones against the code (confidence-floor arithmetic, ci.yml assertions, schema/doc presence claims, E2E head-SHA identity).
- Evidence hashes are stable across standalone runs, the determinism double-run, and days-apart invocations (e.g. selftest `cf5e5077…` identical in every round) — the normalization holds in practice, and the TS/CR branches are now proven byte-exactly by `test_runner_normalization_branches`.
- The suite that gated this sprint's PR is byte-identically the suite run locally (`tools/run-guards.sh` is the single definition) — the "testing lives in GitHub" goal is structurally true, not aspirational.
