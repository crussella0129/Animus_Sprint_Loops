Finalized - DO NOT EDIT

# Sprint 12 Test Plan

Bash-executed checks mapped 1:1 to build-plan EARS clauses. "test_" names label recorded runs in sprint-tests/.

## Unit Tests

### T-001 unit tests (portable in-place edits)
- `test_no_gnu_sed_i`: `grep -rn "sed -i"` over canonical scripts + tools → zero matches.
- `test_selftest_14`: selftest.sh → "all 14 transitions matched" (before T-004 lands; becomes 15 after).
- `test_abort_portable`: temp git project → abort-sprint.sh flips Exit status to `aborted`, fills real end timestamp, appends abort note; routing → ready-for-next-sprint.
- `test_backfill_contract`: temp repo, single anchored PENDING + prose mention → back-filled with backticked hash, prose untouched, one commit (amend), commit message stable (covered by selftest step 11 + explicit temp-dir run).
- `test_merge_policy_4of4`: check-merge-policy.test.sh → 4/4 caught (grep -iv mutation still strips every green-mentioning line, case-insensitive).

### T-004 unit tests (first-match-only guard)
- `test_selftest_15`: selftest.sh → "all 15 transitions matched".
- `test_double_pending_first_only`: step 15's assertions — first PENDING filled, second PENDING intact, prose intact. (Negative arm: manually verified once by temporarily removing the awk `done` guard → step 15 must FAIL — recorded, not committed.)

### T-002 unit tests (portable runner)
- `test_runner_baseline_hashes`: run-guards.sh → 7/7 PASS and evidence hashes IDENTICAL to the sprint-11 committed baseline (sprints/s11/sprint-tests/guards-report.ndjson) for suites whose scripts are unchanged — proves normalization additions are output-no-ops. (Suites whose scripts changed this sprint get new script_hashes; their evidence hashes are re-baselined and must be internally deterministic.)
- `test_hash_fallback`: run the REAL runner with the explicit seam `RUN_GUARDS_HASH_TOOL=shasum` on a fixed-output stub suite → its evidence_hash equals the digest from a `RUN_GUARDS_HASH_TOOL=sha256sum` run of the same stub (same normalized input ⇒ same 64-hex digest via either tool; exercises hash_stdin in place, no copy — per plan-critique C-003).
- `test_var_folders_normalized`: stub suite emitting a per-run-varying `/var/folders/...` and `/private/var/folders/...` path under `--determinism` → `"determinism":"ok"`.
- `test_runner_lint`: shellcheck -S warning on run-guards.sh → clean.

### T-003 unit tests (workflow matrix)
- `test_yaml_matrix`: yaml.safe_load asserts matrix os list == [ubuntu-latest, macos-latest], fail-fast false, runs-on templated, artifact name templated per-os, shellcheck conditional step present, --determinism invocation unchanged.

## Integration Tests
- `test_full_guard_round`: `tools/run-guards.sh --determinism` full local pass (git-bash) after all tasks — composed proof the portable scripts, runner, and fixtures work together.

## End-to-End Tests
- **Status:** possible
- `test_ci_matrix_e2e`: push `sprint-12` → one workflow run with TWO jobs; `gh run list` → conclusion success; `gh run view <id> --json jobs` → both `guards (ubuntu-latest)` and `guards (macos-latest)` conclude success; both per-OS artifacts present. **The macos job passing is the sprint's core proof** — it executes every suite (selftest 15 transitions, both fixture tests, manifest, bundle-sync, shellcheck) on BSD userland + bash 3.2.
