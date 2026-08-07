Finalized - DO NOT EDIT

# Sprint 15 Test Plan

Every EARS clause in [build-plan.md](build-plan.md) and every
[INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) acceptance
criterion maps to a named test below. All fixtures use throwaway git repos and
stub `gh`/`glab`/git identity on `PATH`; no network.

## Unit Tests

### T-122 Remote-profile schema + resolver
- `test_profile_resolves_fields`: a well-formed profile resolves to exact
  `provider`/`base`/`work`/`bump`/`mergePolicy` values.
- `test_profile_rejects_malformed`: missing file, unknown provider, or garbage →
  specific diagnostic + non-zero.
- `test_profile_local_only_valid`: `local-only` validates with no remote
  requirement; `mergePolicy` defaults to `human-approve` when unset.

### T-123 Substrate check
- `test_substrate_complete`: Book + ledgers + `base`/`work` (+`bump` if enabled) +
  profile → `substrate-complete`, exit 0.
- `test_substrate_absent`: empty project → `substrate-absent`, non-zero.
- `test_substrate_partial_no_branches`: Book present, `work` branch missing →
  `substrate-partial:<diagnostic>` naming branches, non-zero.
- `test_substrate_partial_no_profile`: Book + branches, no profile →
  `substrate-partial` naming the profile.
- `test_substrate_is_readonly`: invocation mutates nothing and `current-phase.sh`
  stays byte-identical (hash before == after).
- `test_substrate_complete_without_bump`: `bump` disabled in the profile and no
  `bump` branch present → still `substrate-complete` (no over-requirement).
- `test_substrate_local_only_complete`: `local-only` profile with no remote →
  `substrate-complete` (the gate does not demand a remote).

### T-124 Sprint 0 deploy
- `test_deploy_creates_complete_substrate`: empty project + profile → deploy →
  `check-substrate` = `substrate-complete`.
- `test_deploy_idempotent`: second run makes no change (tree + branch snapshot
  equal).
- `test_deploy_rolls_back_on_failure`: injected mid-deploy failure/signal → no
  partial Book, no orphan branch, original state restored.
- `test_deploy_refuses_conflict`: legacy/conflicting layout → refuse with
  diagnostic, no mutation.

### T-125 Provider adapters + one-PR/MR-per-sprint
- `test_pr_opens_once`: stubbed provider, no existing PR → exactly one
  `work→base` PR/MR created (assert the stub was invoked once with the right
  args).
- `test_pr_refuses_second`: stub reports an existing open PR for the head → no
  second create call.
- `test_provider_fallback_generic`: `gh`/`glab` absent from `PATH` → pushes
  `work` and prints the compare/PR URL, exit 0 (no hard-fail).
- `test_merge_policy_human_approve`: `mergePolicy: human-approve` → no merge
  command is ever invoked.

### T-126 Boundary resync
- `test_resync_brings_base_into_work`: `base` advanced → after resync, `work`
  contains every `base` commit.
- `test_resync_refuses_dirty`: dirty tree/index → refuse with diagnostic, no ref
  change.
- `test_resync_writes_only_work`: `base` ref is byte-identical before and after.

### T-127 Documentation
- `test_init_doc_runs_substrate_gate`: `01-init` names the substrate gate and the
  `substrate-absent → Sprint 0 deploy` route.
- `test_loop_doc_single_pr_human_approve`: `06-loop` names exactly one
  `work→base` PR/MR, human-approve, and no per-sprint branch.
- `test_adapters_reference_profile`: each adapter + `SKILL.md` references the
  remote-profile schema and contains no per-sprint-branch instruction.

### T-128 Guard registration + parity
- `test_suite_registry_includes_substrate`: each new suite appears in `SUITES`,
  `suite_cmd`, and `suite_script_hash`.
- `test_bundle_sync_includes_substrate_scripts`: missing/extra/byte-divergent new
  shared script → parity failure with the exact asset.
- `test_adapter_semantics_reject_per_sprint_branch`: adapter prose reintroducing a
  per-sprint branch or auto-merge-to-`main` → semantic-guard failure.
- `test_deterministic_confirmations`: two normalized `--determinism` runs emit
  identical evidence hashes.

### T-129 Dogfood retrofit
- `test_repo_substrate_complete`: after retrofit, `check-substrate` on this repo →
  `substrate-complete`.
- `test_repo_retrofit_additions_only`: pre/post inventory shows only the profile +
  branch additions; Book + history unchanged.
- `test_repo_routing_unaffected`: `current-phase.sh` output is unchanged by the
  retrofit.

## Integration Tests
- `test_bootstrap_to_first_sprint`: empty project → `deploy-substrate` →
  `substrate-complete` → full phase walk → sprint close opens exactly one stubbed
  `work→base` PR → boundary resync → next sprint initializes cleanly.
- `test_bump_inherit_without_race`: advance `base` (simulated `bump→main` merge);
  boundary `main→dev` resync inherits it; assert `dev` was written only by the
  sprint and the resync, never concurrently.
- `test_local_only_closes_without_remote`: `local-only` profile → Loop closes with
  a local commit, attempts no PR, and does not fail.

## End-to-End Tests
- **Status:** possible for substrate/guard behavior; the human-approved
  `dev→main` merge is a human checkpoint.
- `test_repository_full_guard_suite`: `bash tools/run-guards.sh --determinism`
  green with identical normalized evidence on the Ubuntu/macOS CI matrix
  (authoritative), including all new substrate suites.
- `test_repo_dogfood_substrate`: `check-substrate.sh` on the migrated repository
  reports `substrate-complete` (read-only).
- **Human checkpoint:** a real `dev→main` PR/MR opened by the Loop is reviewed and
  merged by a human — the merge-policy boundary cannot be self-verified.
