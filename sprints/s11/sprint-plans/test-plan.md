Finalized - DO NOT EDIT

# Sprint 11 Test Plan

Tests are bash-executed checks (this project's code is bash + markdown + YAML); each maps to an EARS clause in build-plan.md. "test_" names are labels for the recorded runs in sprint-tests/, not xUnit functions.

## Unit Tests

### T-001 unit tests (bundle-sync guard)
- `test_sync_clean_pass`: run `tools/check-bundle-sync.sh` on the real tree (post-propagation) → exit 0, OK summary line.
- `test_sync_drift_caught`: fixture injects content drift into a mirror script → guard exits non-zero naming the path.
- `test_sync_missing_caught`: fixture deletes a mirror schema file → guard exits non-zero naming the path.
- `test_sync_extra_caught`: fixture adds an extra file to a mirror's scripts/ set → guard exits non-zero naming the path.
- `test_sync_fixture_suite`: `tools/check-bundle-sync.test.sh` → exit 0 with all cases reported caught.
- Stubs: temp-tree fixtures (mktemp -d, trap cleanup) — never mutate the real tree.

### T-002 unit tests (behavior-preserving refactor)
- `test_selftest_14`: `selftest.sh` → "all 14 transitions matched".
- `test_current_sprint_11`: `current-sprint.sh` in repo root → prints `11`.
- `test_current_sprint_empty`: temp dir with empty `sprints/` → `-1`; with no `sprints/` → `-1`.
- `test_init_no_sprints`: `init-sprint.sh` in a bare temp dir → creates `sprints/s0`, exit 0.
- `test_finalize_no_sprints`: `finalize-plan.sh` in a bare temp dir → exit non-zero, "no sprints found".
- `test_budget_no_sprints`: `research-budget.sh` in a bare temp dir → `files=0 sources=0`, exit 0.
- `test_shellcheck_zero`: `shellcheck -S warning` on canonical scripts + tools/*.sh → no findings, exit 0.

### T-003 unit tests (confidence floor)
- `test_confidence_floor`: temp dir, confidence.txt=0.2, `update-confidence.sh failed` → 0.0.
- `test_confidence_cap`: temp dir, confidence.txt=0.9, `update-confidence.sh pass` → 1.0.

### T-004 unit tests (guard runner)
- `test_runner_green`: `run-guards.sh --out <tmp>` on green tree → exit 0; ndjson has one line per suite; every line has 64-hex script_hash + evidence_hash, status PASS, UTC ts.
- `test_runner_fail_recorded`: stub suite exiting 1 injected via the runner's suite-dir override → runner exits non-zero, that suite's line has status FAIL, later suites still recorded.
- `test_runner_determinism_pass`: `run-guards.sh --determinism` on green tree → exit 0 (all evidence-hash pairs equal).
- `test_runner_nondeterminism_caught`: stub suite emitting `$RANDOM` under `--determinism` → exit non-zero naming the suite.

### T-005 unit tests (workflow)
- `test_yaml_parses`: python3 yaml.safe_load on .github/workflows/ci.yml → parses; asserts push (all branches) + pull_request (base main) triggers, a `run-guards.sh --determinism` invocation, an artifact-upload step with `if: always()`, and a step writing to `$GITHUB_STEP_SUMMARY`.

### T-006 unit tests (Test-phase CI confirmations)
- `test_report_schema_block`: `schemas/test-report.md` (canonical) contains head SHA, run ID/URL, conclusion fields + the "CI not configured — local confirmations only" fallback line.
- `test_phase05_runner_para`: `phases/05-test-phase.md` contains the canonical-runner paragraph (invoke the runner, record confirmations, CI conclusion on head SHA authoritative).
- `test_sync_after_t006`: `check-bundle-sync.sh` → exit 0 (05 claude↔codex identical; schema ×4 parity).

### T-007 unit tests ((backlog) form)
- `test_schema_backlog_form`: `schemas/agent-tasks.md` documents the `(backlog)` entry form + promotion rule.
- `test_loop_docs_backlog_sentence`: each of the three loop docs contains the backlog-append sentence.
- `test_routing_backlog_safe`: temp fixture project with a `(backlog)`-only `agent-tasks.md` at each routing-relevant phase state → `current-phase.sh` output identical to the empty-backlog fixture.
- `test_merge_policy_still_green`: `check-merge-policy.sh` after loop-doc edits → consistent.

### T-008 unit tests (trajectory artifacts)
- `test_roadmap_sections`: ROADMAP.md contains the eight prioritized candidates + the Merkle/memoization deferral rationale + array-test link naming T1–T5 as precondition.
- `test_backlog_form`: every seeded backlog line matches `^- \[ \] T-1[0-9]{2} \(backlog\): .+ — touches: .+$`.

## Integration Tests

### Component A+B integration
- `test_full_guard_round`: `tools/run-guards.sh --determinism` full local pass after ALL tasks land — the composed suite (selftest + 2× merge-policy + manifest + 2× bundle-sync + shellcheck) doubles as the integration test of the refactored scripts, new guards, and edited docs together.

## End-to-End Tests
- **Status:** possible (this sprint bootstraps it)
- `test_ci_e2e`: push branch `sprint-11` → GitHub Actions triggers; verify per phase-05 CI pattern: `gh run list --branch sprint-11 --json status,conclusion,databaseId --limit 1` → `conclusion: success` on the head SHA; guards-report.ndjson artifact present on the run. This is the authoritative confirmation recorded in test-report.md (head SHA + run URL + conclusion).
- Red-CI path: deferred with rationale (critique C-007b) — platform failure semantics; runner-side failure path covered by `test_runner_fail_recorded`.
