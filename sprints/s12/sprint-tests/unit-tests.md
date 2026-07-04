# Sprint 12 Unit Tests

Bash-executed checks mapped 1:1 to build-plan EARS clauses. Every test below PASSED (local host: Windows git-bash; macOS coverage lands via the E2E matrix leg).

## T-001 (portable in-place edits)
- `test_no_gnu_sed_i` — `grep -rn "sed -i"` over canonical scripts + tools → ZERO MATCHES. PASS
- `test_selftest_14` — "all 14 transitions matched" immediately post-T-001 (steps 09/11 exercised the rewritten abort + back-fill). PASS
- `test_abort_portable` — selftest step 09 (temp git project): routing short-circuits on the Exit-status flip, AND (added per test-critique C-001) explicit greps assert the real end-timestamp fill and the `## Abort note` append — negative arm verified (timestamp expression deleted in a throwaway copy → step 09 FAILS). PASS
- `test_backfill_contract` — live-fire: T-001's own commit back-filled its PENDING placeholder via the new awk path (`d4166c7`, backticked, amended into the same commit). PASS
- `test_merge_policy_4of4` — fixture 4/4 caught with the `grep -iv` mutation (case-insensitive deletion preserved). PASS

## T-004 (first-match-only guard)
- `test_selftest_15` — "all 15 transitions matched". PASS
- `test_double_pending_first_only` — step 15: first anchored PENDING → backticked hash; second PENDING intact; prose token mention intact. PASS
- Negative arm (recorded, not committed): throwaway commit-task.sh with the awk `done`-guard stripped → step 15 FAILED as required (fill-all regression genuinely caught). PASS

## T-002 (portable runner)
- `test_runner_baseline_hashes` — final round 7/7; per-suite comparison vs the committed s11 baseline: merge-policy, merge-policy-test, plugin-manifest, bundle-sync, bundle-sync-test, shellcheck all byte-identical; ONLY selftest re-baselined (`cf5e5077…` → `b6196a54…`, its output legitimately grew step 15). Normalization additions proven output-no-ops. PASS
- `test_hash_fallback` — real seam: `RUN_GUARDS_HASH_TOOL=sha256sum` vs `=shasum` on a fixed-output stub → identical 64-hex evidence hash (`1f636e9f…`) from the real hash_stdin, no copied code. PASS
- `test_var_folders_normalized` — stub emitting per-run-varying `/var/folders/…` and `/private/var/folders/…` paths under `--determinism` → `"determinism":"ok"`, runner exit 0. PASS
- `test_runner_lint` — shellcheck -S warning clean. PASS

## T-003 (workflow matrix)
- `test_yaml_matrix` — yaml.safe_load: matrix os == [ubuntu-latest, macos-latest], fail-fast false, runs-on templated, per-OS artifact names, conditional shellcheck install step, unchanged `--determinism` invocation, step-summary + artifact steps `if: always()`. PASS

**Unit totals: 13 passed / 0 failed / 13 total.**
