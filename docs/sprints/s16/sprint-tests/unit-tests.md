# Sprint 16 Unit and Contract Test Results

## Scope

- **Published test-hardened head:** `026d6faffeba53c87db2610202e4da865304ede2`
- **Guarded implementation commit:** `184e376a4acfba7a5a34ab110815f615864d0e32`
- **Canonical confirmations:** [guards-report.ndjson](guards-report.ndjson) — 15 unique suites, 15 PASS, 15 deterministic
- **Hosted confirmation:** [guards #31245249580](https://github.com/crussella0129/Animus_Sprint_Loops/actions/runs/31245249580) — exact published head, Ubuntu and macOS both successful
- **Result:** 39/39 locked named unit/contract checks passed; 1/1 supplemental identifier mutation passed.

The deterministic implementation candidate was committed as `184e376`; Book
evidence followed, then `026d6fa` added only the critic-requested assertions.
The changed fixtures and final installed tree were rerun against that head.

## Named Results

| Task | Named test(s) from locked plan | Executed evidence and assertion | Result |
|---|---|---|---|
| T-130 | `test_profile_v2_resolves_four_fields`; `test_profile_rejects_legacy_marker`; `test_profile_rejects_unknown_field`; `test_profile_rejects_unknown_field_query`; `test_profile_local_only_defaults` | Installed `remote-profile.test.sh` passed its resolve, malformed, and local-only fixtures. The resolve fixture now invokes and asserts all four field-query branches (`provider`, `base`, `work`, `mergePolicy`) as well as exact aggregate output. The malformed fixture separately asserts the v1 migration diagnostic, unknown profile-key rejection, unsupported-query rejection, and exact supported-field list. | pass |
| T-131 | `test_substrate_two_branch_complete`; `test_substrate_read_only`; `test_deploy_hosted_targets_work`; `test_deploy_exact_branch_set`; `test_deploy_local_only_no_updater`; `test_deploy_no_clobber`; `test_deploy_rolls_back`; `test_deploy_rollback_preserves_preexisting` | Installed `check-substrate.test.sh` passed 6/6 fixtures and installed `deploy-substrate.test.sh` passed 8/8. Exact `main`/`dev` branch sets are asserted independently for GitHub, GitLab, and generic providers; GitHub Dependabot and GitLab/generic Renovate targets are asserted; both pre-existing `dependabot.yml` and `renovate.json` are checksum-proven byte-identical. Local-only absence, transaction cleanup, and seeded-state preservation after injected failure also pass. | pass |
| T-132 | `test_pr_opens_once_from_work`; `test_pr_refuses_existing_checkpoint`; `test_head_override_rejected`; `test_boundary_intake_contract_all_adapters`; `test_unrepairable_updater_uses_ordinary_sprint`; `test_single_checkpoint_contract`; `test_sync_brings_base_into_work`; `test_sync_writes_only_work` | Installed `remote-adapter.test.sh` passed 5/5 and installed `sync-work-branch.test.sh` passed 3/3. A separate four-surface assertion checked 4 adapters × 7 required clauses: boundary-only, current-and-green, red-unmerged repair, ordinary dependency-only fallback, supersession, no subtype, and the sole `work → base` checkpoint. | pass |
| T-133 | `test_live_profile_v2`; `test_repo_dependabot_targets_dev`; `test_ci_covers_dev`; `test_actions_v7_preserved`; `test_operator_guide_two_branch_model` | A current-head live-repository assertion passed the exact four-field profile, exactly one `target-branch: "dev"` plus neutral `deps` prefix, `[main, dev]` PR bases, checkout/upload v7, the boundary/fallback/security prose, and `main == origin/main` with `main` ancestral to `dev`. `origin/bump` workflow diff is exactly the one-line addition of the `dev` PR base, proving the v7 payload was preserved. | pass |
| T-134 | `test_retired_branch_in_adapter_fails`; `test_retired_branch_in_schema_fails`; `test_retired_branch_in_script_fails`; `test_retired_branch_in_phase_fails`; `test_retired_branch_in_operator_guide_fails`; `test_retired_branch_in_live_profile_fails`; `test_retired_branch_in_updater_config_fails`; `test_active_surfaces_clean`; `test_bundle_parity`; `test_deterministic_guards` | `check-adapter-semantics.test.sh` passed 57/57 isolated mutations, including every locked class, history exclusions, embedded-word acceptance, `BUMP_BRANCH`, and supplemental `bumpBranch` installer coverage. `check-bundle-sync.sh` passed. The retained canonical report records all 15 suites PASS with `determinism: ok`. | pass |
| T-135 | `test_user_install_has_no_transaction_artifacts`; `test_installed_tree_matches_source`; `test_installed_router_and_profile_v2` | After the critic-driven fixture changes, the documented Windows transaction was rerun. It left 0 lock/stage/backup/owner artifacts; sorted source/installed manifests matched for all 49 relative paths and SHA-256 hashes; both strengthened installed fixtures passed; the installed router reported `test`; and the installed resolver emits exactly GitHub/main/dev/human-approve. | pass |

## Negative Paths

- Legacy profile markers, extra profile keys, and unsupported field queries fail
  with their contract diagnostics.
- Dirty/conflicting resync and existing-checkpoint paths refuse mutation.
- Injected deploy failures remove only transaction-created artifacts and retain
  pre-existing refs/files/config byte-for-byte.
- All active-distribution branch-model mutations fail with repository-relative
  path and line diagnostics; finalized sprint and Git history remain allowed.
