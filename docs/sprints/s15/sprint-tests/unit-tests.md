# Sprint 15 Unit Tests

Every EARS clause in the locked [build plan](../sprint-plans/build-plan.md) maps
to a named fixture. Each substrate script ships a `*.test.sh` run per-task and,
from T-128, registered as a canonical `run-guards` suite. Results below are from
the per-task runs and the canonical suite.

## T-122 Remote-profile (`remote-profile.test.sh` — 3/3)
- `test_profile_resolves_fields`: valid profile → exact `provider/base/work/bump/mergePolicy`. **PASS.**
- `test_profile_rejects_malformed`: missing file / unknown provider / missing base / missing marker → specific diagnostic + non-zero. **PASS.**
- `test_profile_local_only_valid`: `local-only` validates; `bump` defaults `none`, `mergePolicy` defaults `human-approve`. **PASS.**

## T-123 Substrate check (`check-substrate.test.sh` — 7/7)
- `test_substrate_complete`, `test_substrate_absent`, `test_substrate_partial_no_branches` (names `branch:dev`), `test_substrate_partial_no_profile`, `test_substrate_is_readonly` (working tree + `current-phase.sh` unchanged), `test_substrate_complete_without_bump`, `test_substrate_local_only_complete`. **PASS.**

## T-124 Sprint 0 deploy (`deploy-substrate.test.sh` — 4/4)
- `test_deploy_creates_complete_substrate` (empty → complete, branches asserted), `test_deploy_idempotent` (snapshot unchanged), `test_deploy_rolls_back_on_failure` (`DEPLOY_SUBSTRATE_FAIL_AFTER` → no `docs/`/`.git` left), `test_deploy_refuses_conflict`. **PASS.**

## T-125 Provider adapters (`remote-adapter.test.sh` — 4/4)
- `test_pr_opens_once` (stubbed `gh`; exactly one `pr create`, no `pr merge`), `test_pr_refuses_second`, `test_provider_fallback_generic` (prints "manually" URL, exit 0), `test_merge_policy_human_approve` (no merge invoked). **PASS.**

## T-126 Boundary resync (`sync-work-branch.test.sh` — 3/3)
- `test_resync_brings_base_into_work` (`main` head becomes ancestor of `dev`), `test_resync_refuses_dirty` (modified tracked file → refusal, `dev` unchanged), `test_resync_writes_only_work` (`main` ref unchanged). **PASS.**

## T-127 Documentation
- `test_init_doc_runs_substrate_gate`: `01-init-sprint.md` names the substrate gate and the `substrate-absent → deploy-substrate` route. **PASS** (grep-verified).
- `test_loop_doc_single_pr_human_approve`: both `06-loop-phase.md` docs name one `work→base` PR/MR, human-approve, no per-sprint branch. **PASS.**
- `test_adapters_reference_profile`: enforced by T-128's `check_profile_contract` — each adapter references `schemas/remote-profile.md` and carries the no-per-sprint-branch commitment. **PASS.**

## T-128 Guard registration + parity
- `test_suite_registry_includes_substrate`: 15/15 suites resolve in `SUITES`, `suite_cmd`, `suite_script_hash` (0 incomplete). **PASS.**
- `test_bundle_sync_includes_substrate_scripts`: the 10 new shared files are in `REQUIRED_SCRIPTS`; bundle-sync parity green. **PASS.**
- `test_adapter_semantics_reject_per_sprint_branch`: `check-adapter-semantics.test.sh` **47/47**, incl. two new non-vacuous negatives — omit the profile reference → fail; drop the no-per-sprint-branch commitment → fail (each asserts its exact diagnostic). **PASS.**
- `test_deterministic_confirmations`: verified by the canonical `--determinism` run (see [test-report.md](test-report.md)).

## T-129 Dogfood retrofit (verified against the live repo)
- `test_repo_substrate_complete`: `check-substrate.sh .` → `substrate-complete`. **PASS.**
- `test_repo_retrofit_additions_only`: pre/post inventory shows only `dev`+`bump` branches and `docs/work/remote-profile.md` added; Book/history unchanged. **PASS.**
- `test_repo_routing_unaffected`: `current-phase.sh` unchanged by the retrofit. **PASS.**

## Summary
All per-task unit fixtures pass (remote-profile 3, check-substrate 7, deploy 4,
adapter 4, resync 3; adapter-semantics 47/47). The full canonical suite's
authoritative confirmation (Ubuntu/macOS CI) is recorded in
[test-report.md](test-report.md); the only local-Windows exception remains the
pre-existing `selftest` CRLF gawk quirk (backlog T-121), unrelated to this
sprint's scripts.
