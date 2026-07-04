# Test Critique — Sprint 11

Critic: subagent (general-purpose) run with `prompts/test-critic.md`. Verdict: `proceed-with-caveats`.
Primary-agent responses inline as **Response:**.

## Concerns

### C-001: Bundle-sync fixture suite asserts exit codes only — path-naming SHALL not regression-guarded
- **Where:** `tools/check-bundle-sync.test.sh` `expect_fail` / `unit-tests.md` T-001
- **Failure mode:** weak-assertion
- **Why it matters:** The durable artifact CI re-runs forever asserted only non-zero exit; a guard that crashes (or exits 1 without naming the path) would still count as "caught" — the exact vacuity class this sprint excavated from check-merge-policy.test.sh.
- **Response: tighten-assertion — APPLIED.** `expect_fail` now takes a required stderr pattern and fails on "wrong failure — path not named"; all four cases assert their specific `DIVERGED:`/`MISSING:`/`EXTRA:` path. Applying the fix itself tripped a second latent hazard — the `out=$(guard)` capture triggered the script's `set -e` on the expected non-zero exit, silently truncating the suite after the baseline case (observed as bundle-sync-test FAIL inside the runner) — fixed with `|| rc=$?`. Final: 5/5 behaved, shellcheck clean.

### C-002: Normalization EARS clause only exercised for temp paths — timestamp and CR branches untested
- **Where:** build-plan T-004 clause 4 / `tools/run-guards.sh` `normalize()`
- **Failure mode:** EARS-coverage
- **Why it matters:** No suite output contained an ISO timestamp or CR, so the `<TS>` and `tr -d '\r'` branches were dead-untested; a regression would surface later as unexplained CI determinism flake.
- **Response: add-test — APPLIED.** `test_runner_normalization_branches`: stub suite emitting a CRLF line + a live `date -u` ISO timestamp + `sleep 1` (forcing the double-run timestamps to differ) under `--determinism` → `"determinism":"ok"` AND evidence_hash exactly equals the precomputed sha256 of the fully-normalized text `hello\nts: <TS>\n` — proving both branches byte-exactly, not just differentially. PASS.

### C-003: test_runner_green under-asserts against the ndjson-fields SHALL
- **Failure mode:** weak-assertion (minor)
- **Response: defer-with-rationale — as the critic itself noted, the committed `guards-report.ndjson` visibly carries `suite` and integer `duration_s` on all lines, so the SHALL is evidenced by the artifact; scripting the field check is folded into the future array-test integration work (T-101), where the record format becomes load-bearing.

### C-004: normalize() temp-path pattern is environment-narrow — latent determinism flake
- **Failure mode:** flake-risk
- **Response: defer-with-rationale — APPLIED as annotation.** Both current environments use `/tmp/tmp.*`; macOS portability is already backlogged. T-102's backlog entry now explicitly includes broadening `normalize()` (TMPDIR / /var/folders) so the future macos-latest leg doesn't land red on determinism.

## Confidence

`proceed-with-caveats` — C-001 and C-002 applied and re-verified; C-003/C-004 deferred with recorded rationale (C-004 annotated into T-102). Proceeding to finalize test-report.md.
