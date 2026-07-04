# Sprint 11 Unit Tests

All tests are bash-executed checks mapped 1:1 to build-plan EARS clauses (per
phase-05 derivation). Executed during Build (per-task gates) and re-composed in
the final integration round. Every test below PASSED.

## T-001 (bundle-sync guard)
- `test_sync_clean_pass` — guard on real tree → exit 0, "bundle-sync: all mapped assets in parity across bundles". PASS
- `test_sync_drift_caught` — fixture: byte appended to mirror current-phase.sh → non-zero, names path. PASS
- `test_sync_missing_caught` — fixture: deleted antigravity schemas/test-report.md → non-zero, names path. PASS
- `test_sync_extra_caught` — fixture: rogue-helper.sh added to open-harnesses/scripts → non-zero, names path. PASS
- `test_sync_fixture_suite` — check-bundle-sync.test.sh → 5/5 behaved (incl. drifted shared phase 05 case). PASS
- Tightened per test-critique C-001: `expect_fail` now requires the guard's stderr to NAME the offending path (specific `DIVERGED:`/`MISSING:`/`EXTRA:` patterns per case) — non-zero exit alone no longer counts as "caught". Re-run: 5/5. (The tightening itself surfaced a `set -e` truncation hazard in the capture, fixed with `|| rc=$?` — see critique.md C-001.)

## T-002 (behavior-preserving refactor)
- `test_selftest_14` — "selftest: all 14 transitions matched". PASS
- `test_current_sprint_11` — prints `11` at repo root. PASS
- `test_current_sprint_empty` — `-1` with no sprints/; `-1` with empty sprints/. PASS
- `test_init_no_sprints` — bare temp dir → "Initialized sprint 0 at sprints/s0". PASS
- `test_finalize_no_sprints` — bare temp dir → non-zero, "no sprints found". PASS
- `test_budget_no_sprints` — bare temp dir → `files=0 sources=0`, exit 0. PASS
- `test_shellcheck_zero` — `shellcheck -S warning` canonical scripts + tools → zero findings. PASS
- **Bonus regression fixed en route:** check-merge-policy.test.sh's drift cases were VACUOUS since sprint 8 (quoted `"$GUARD_T"` = exit-127 command-not-found counted as "caught"). De-vacuating exposed a second latent false-pass (case-3 sed spanned hard-wrapped SKILL.md lines and no-opped); mutation now deletes permit lines wholesale. Fixture 4/4 *genuinely* caught, verified by observing the intermediate 3/4 failure.

## T-003 (confidence floor)
- `test_confidence_floor` — 0.2 + `failed` → 0.0. PASS
- `test_confidence_cap` — 0.9 + `pass` → 1.0. PASS

## T-004 (guard runner)
- `test_runner_green` — 7/7 PASS, one ndjson line per suite, 64-hex script_hash + evidence_hash, UTC ts. PASS
- `test_runner_fail_recorded` — injected failing stub (RUN_GUARDS_EXTRA_SUITES) → its line `"status":"FAIL"`, later suites recorded, exit 1. PASS
- `test_runner_determinism_pass` — `--determinism` on green tree → all real suites `"determinism":"ok"`, exit 0 (final round: 7/7). PASS
- `test_runner_nondeterminism_caught` — `$RANDOM` stub under `--determinism` → "NONDETERMINISTIC: extra:zz-rand.sh" on stderr, `"determinism":"mismatch"` recorded, exit 1. PASS
- `test_runner_normalization_branches` (added per test-critique C-002) — stub emitting CRLF line + live ISO timestamp + `sleep 1` under `--determinism` → `"determinism":"ok"` AND evidence_hash byte-equals the precomputed sha256 of the normalized text `hello\nts: <TS>\n` — TS and CR branches proven exactly. PASS
- Added during test-hardening: unwritable `--out` → "cannot write confirmations", exit 2 (a runner that can't record must not report success).

## T-005 (workflow)
- `test_yaml_parses` — yaml.safe_load OK; push (all branches) + pull_request(main) triggers, `run-guards.sh --determinism` invocation, step-summary write with `if: always()`, artifact upload with `if: always()` all asserted. PASS

## T-006 (Test-phase CI confirmations)
- `test_report_schema_block` — CI Confirmation block fields + no-CI fallback line present in canonical schema. PASS
- `test_phase05_runner_para` — "Canonical runner & confirmations" section present (claude + codex identical). PASS
- `test_sync_after_t006` — bundle-sync green post-edit. PASS

## T-007 ((backlog) form)
- `test_schema_backlog_form` — both entry forms + promotion rule documented in schema (×4). PASS
- `test_loop_docs_backlog_sentence` — backlog-append sentence in claude 06, codex 06, oh particle 08. PASS
- `test_routing_backlog_safe` — temp fixture, 2 real `(backlog)` entries at plan/build/test states → phase outputs identical to empty-backlog baseline. PASS (first attempt appended nothing due to a printf option-parse error and was redone with verified entry counts — recorded because catching vacuous passes is this sprint's theme.)
- `test_merge_policy_still_green` — consistent post-edit. PASS

## T-008 (trajectory artifacts)
- `test_roadmap_sections` — 8 numbered candidates, "Deliberately deferred" rationale block, array-test link + T1–T5 precondition. PASS
- `test_backlog_form` — 8/8 seeded entries match `^- \[ \] T-1[0-9]{2} \(backlog\): .+ — touches: .+$`. PASS

**Unit totals: 28 passed / 0 failed / 28 total** (27 planned + 1 added by the test critic; one planned test tightened post-critique and re-run).
