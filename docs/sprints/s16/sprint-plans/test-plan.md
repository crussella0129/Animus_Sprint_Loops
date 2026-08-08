Finalized - DO NOT EDIT

# Sprint 16 Test Plan

## Intent Traceability
| Intent | Acceptance criterion | Build task / EARS clause | Verification |
|--------|----------------------|--------------------------|--------------|
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | profile v2 has exactly provider/base/work/mergePolicy | T-130 / valid profile emits four fields; legacy marker, unknown keys, and unknown field queries reject; copies match | `test_profile_v2_resolves_four_fields`, `test_profile_rejects_legacy_marker`, `test_profile_rejects_unknown_field`, `test_profile_rejects_unknown_field_query`, `test_bundle_parity` |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | deploy creates only base/work and hosted updater targets work | T-131 / exact refs + provider-specific target + no-clobber/rollback preservation | `test_substrate_two_branch_complete`, `test_deploy_hosted_targets_work`, `test_deploy_exact_branch_set`, `test_deploy_no_clobber`, `test_deploy_rolls_back`, `test_deploy_rollback_preserves_preexisting` |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | boundary intake is green-only; red stays unmerged; never mid-sprint; unrepairable heads become ordinary sprints | T-132 / active contracts carry all boundary and fallback clauses | `test_boundary_intake_contract_all_adapters`, `test_unrepairable_updater_uses_ordinary_sprint` |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | adapter has only work-to-base checkpoint | T-132 / profile-derived head; existing checkpoint detected; override rejected; resync positive path | `test_pr_opens_once_from_work`, `test_pr_refuses_existing_checkpoint`, `test_head_override_rejected`, `test_sync_brings_base_into_work` |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | every corpus checkpoint is an ordinary sprint | T-132, T-133 / active protocol and README contain one path | `test_single_checkpoint_contract` |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | repository targets dev, CI covers dev, Actions v7 preserved | T-133 / live configuration clauses | `test_live_profile_v2`, `test_repo_dependabot_targets_dev`, `test_ci_covers_dev`, `test_actions_v7_preserved` |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | guards reject active revival but retain history | T-134 / seven active-surface class failures + parity/determinism | `test_retired_branch_in_adapter_fails`, `test_retired_branch_in_schema_fails`, `test_retired_branch_in_script_fails`, `test_retired_branch_in_phase_fails`, `test_retired_branch_in_operator_guide_fails`, `test_retired_branch_in_live_profile_fails`, `test_retired_branch_in_updater_config_fails`, `test_active_surfaces_clean`, `test_bundle_parity`, `test_deterministic_guards` |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | revised model is delivered to Codex | T-135 / clean transactional activation + tree hash parity + installed runtime | `test_user_install_has_no_transaction_artifacts`, `test_installed_tree_matches_source`, `test_installed_router_and_profile_v2` |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | remote long-lived branches become main/dev after the checkpoint | M-001 / authorized post-merge resync and deletion | `test_post_merge_remote_preconditions`, `test_post_merge_remote_topology` |

## Unit Tests

### T-130 unit tests
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- `test_profile_v2_resolves_four_fields`: valid GitHub profile emits exactly provider/base/work/mergePolicy and each supported field query resolves.
- `test_profile_rejects_legacy_marker`: earlier marker fails with a migration diagnostic.
- `test_profile_rejects_unknown_field`: any extra key fails rather than being ignored.
- `test_profile_rejects_unknown_field_query`: any unsupported positional field query exits non-zero and lists only the four v2 fields.
- `test_profile_local_only_defaults`: local-only remains valid and mergePolicy defaults to human-approve.

### T-131 unit tests
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- `test_substrate_two_branch_complete`: `main`/`dev` plus v2 profile is complete; a missing configured branch is partial.
- `test_substrate_read_only`: file/ref snapshots and current-phase hash remain unchanged.
- `test_deploy_hosted_targets_work`: GitHub writes Dependabot `target-branch: dev`; GitLab/generic write Renovate `baseBranchPatterns: ["dev"]`.
- `test_deploy_exact_branch_set`: fresh hosted deploy creates exactly `main` and `dev`, with no third long-lived branch.
- `test_deploy_local_only_no_updater`: local-only creates no hosted-updater file.
- `test_deploy_no_clobber`: a pre-existing updater config is byte-identical after deploy.
- `test_deploy_rolls_back`: injected failure removes the Book/profile/refs/updater created by the transaction.
- `test_deploy_rollback_preserves_preexisting`: an injected failure leaves seeded files, refs, profile content, and updater configuration byte-identical.

### T-132 unit and contract tests
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- `test_pr_opens_once_from_work`: stubbed provider sees exactly one profile-work head and no merge call.
- `test_pr_refuses_existing_checkpoint`: an existing work-to-base PR produces the already-open diagnostic and zero create calls.
- `test_head_override_rejected`: retired caller override exits 2 before any provider command.
- `test_boundary_intake_contract_all_adapters`: Claude, Codex, Antigravity, and open-harness active contracts each carry boundary-only, green-only, repair-red, and no-mid-sprint requirements.
- `test_unrepairable_updater_uses_ordinary_sprint`: every active operator contract names the ordinary dependency-only sprint fallback and superseding the unmergeable updater PR, with no checkpoint subtype.
- `test_single_checkpoint_contract`: active contracts expose only the ordinary work-to-base corpus checkpoint.
- `test_sync_brings_base_into_work`: an advanced base becomes an ancestor of work.
- `test_sync_writes_only_work`: resync proves base-ref immutability plus conflict/dirty refusal.

### T-133 repository tests
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- `test_live_profile_v2`: canonical resolver returns GitHub/main/dev/human-approve for `docs/work/remote-profile.md`.
- `test_repo_dependabot_targets_dev`: YAML contains exactly one `target-branch: "dev"` and no retired target/prefix.
- `test_ci_covers_dev`: `pull_request.branches` includes both `main` and `dev`.
- `test_actions_v7_preserved`: workflow uses checkout v7 and upload-artifact v7, matching PRs #7/#8 payloads.
- `test_operator_guide_two_branch_model`: root README contains the boundary rule/security caveat and no active retired model.

### T-134 guard tests
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- `test_retired_branch_in_adapter_fails`: adapter fixture mutation yields its exact path diagnostic.
- `test_retired_branch_in_schema_fails`: schema fixture mutation yields its exact path diagnostic.
- `test_retired_branch_in_script_fails`: runtime script fixture mutation yields its exact path diagnostic.
- `test_retired_branch_in_phase_fails`: phase fixture mutation yields its exact path diagnostic.
- `test_retired_branch_in_operator_guide_fails`: root/operator guide fixture mutation yields its exact path diagnostic.
- `test_retired_branch_in_live_profile_fails`: Book remote-profile fixture mutation yields its exact path diagnostic.
- `test_retired_branch_in_updater_config_fails`: Dependabot/Renovate fixture mutation yields its exact path diagnostic.
- `test_active_surfaces_clean`: baseline scan finds no retired term in distribution/runtime/operator configuration surfaces.
- `test_bundle_parity`: all changed schema/script/test copies are byte-identical across four bundles.
- `test_deterministic_guards`: two canonical runs produce identical normalized evidence hashes.

### T-135 delivery tests
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- `test_user_install_has_no_transaction_artifacts`: no lock, stage, backup, or ownership marker remains after the documented Windows install.
- `test_installed_tree_matches_source`: sorted relative-path/SHA-256 inventories are identical.
- `test_installed_router_and_profile_v2`: installed `current-phase.sh` reports the Book-derived phase and installed resolver returns only GitHub/main/dev/human-approve.

## Integration Tests

### Contract-to-runtime integration
- **Intents:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- `test_pre_build_sync`: before the first implementation task, local `main` equals `origin/main`, `main` is an ancestor of `dev`, and the tracked tree is clean.
- `test_profile_deploy_check_pipeline`: deploy a fresh GitHub fixture with work `dev`; resolve v2; require substrate-complete; assert exact branch set and work-targeted Dependabot config.
- `test_install_then_runtime`: transactionally install the revised Codex bundle into a temporary skills root, then run its profile/substrate/deploy/adapter fixtures.
- `test_four_bundle_contract`: run bundle-sync plus adapter-semantics and its non-vacuous fixture suite.
- `test_live_repository_pre_checkpoint`: canonical profile resolves, Dependabot targets dev, dev-targeting PRs run CI, and Actions v7 payloads are present before the Sprint 16 checkpoint.

## End-to-End Tests
- **Status:** possible for the implemented path; remote branch retirement is a post-merge realization checkpoint governed by the current human-approve policy.
- `test_fresh_hosted_project_two_branch_flow`: in a temporary Git repository, deploy the hosted substrate, verify updater PR target configuration, initialize/route a synthetic sprint, close it, and assert the adapter can open only the ordinary work-to-base checkpoint.
- `test_canonical_guards_deterministic`: run `bash tools/run-guards.sh --determinism`; pass only if every suite is green and normalized evidence matches across both rounds.
- `test_post_merge_remote_preconditions` (post-Loop checkpoint): after a human approves the Sprint 16 PR, verify `main` contains the v2 profile, work-targeted updater configuration, dev-targeting CI, and Actions v7 before any deletion.
- M-001 then performs the explicitly authorized `main → dev` resync and local/remote branch deletion; no test hides that mutation.
- `test_post_merge_remote_topology` (post-M-001): read-only verification requires remote branches exactly `main`/`dev`, both branches contain the migration payloads, and no open PR names the retired branch. Do not claim INT-0003 realized before this observable checkpoint.
