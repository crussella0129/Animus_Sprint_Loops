# Sprint 19 Test Plan

## Intent Traceability

| Intent | Acceptance criterion | Build task / EARS clause | Verification |
|--------|----------------------|--------------------------|--------------|
| [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md) | Inference from a recognized `origin` records that provider and the URL it came from | T-157 / the github, gitlab, and codeberg clauses plus the provenance clause | `test_infer_github_https`, `test_infer_github_ssh`, `test_infer_gitlab`, `test_infer_forgejo_codeberg`, `test_infer_records_provenance` |
| [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md) | No `origin` writes `local-only` | T-157 / the no-remote clause | `test_infer_no_remote_is_local_only` |
| [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md) | An unrecognized remote writes `generic`, never `local-only` | T-157 / the unrecognized-host clause | `test_infer_unknown_host_is_generic` |
| [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md) | An explicit `--provider` always wins | T-157 / the explicit-flag clause | `test_explicit_provider_wins` |
| [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md) | An existing profile is never rewritten | T-157 / the existing-profile clause; T-159 / the report-only clauses | `test_existing_profile_untouched`, `test_check_reports_disagreement` |
| [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md) | `gitea` and `forgejo` accepted; unknown values still rejected | T-158 / the resolve and reject clauses | `test_profile_accepts_gitea_forgejo`, `test_profile_rejects_malformed` |
| [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md) | Those hosts get an updater config and the fallback checkpoint path | T-158 / the updater and fallback clauses | `test_gitea_gets_renovate`, `test_forgejo_uses_fallback_checkpoint` |
| [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md) | The operator-facing statement of detection exists | T-160 / the Init, README, and guard clauses | `test_init_documents_provider_inference`, `adapter-semantics`, `operator-docs` |

## Unit Tests

### T-157 unit tests
- **Intent:** [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md)
- Location: `scripts/deploy-substrate.test.sh`. **Every fixture here omits `--provider`** — the path all sixteen existing fixtures skip, and the reason the defect survived them (research F10).
- `test_infer_github_https`: `origin=https://github.com/o/r.git` → `provider: github`, and `.github/dependabot.yml` is scaffolded.
- `test_infer_github_ssh`: `origin=git@github.com:o/r.git` and, separately, `ssh://git@github.com/o/r.git` → `provider: github` for both.
- `test_infer_gitlab`: `origin=https://gitlab.example.net/o/r.git` → `provider: gitlab`, `renovate.json` scaffolded.
- `test_infer_forgejo_codeberg`: `origin=https://codeberg.org/o/r.git` → `provider: forgejo`.
- `test_infer_unknown_host_is_generic`: `origin=https://git.example.invalid/o/r.git` → `provider: generic`, **not** `local-only`.
- `test_infer_no_remote_is_local_only`: no `origin` → `provider: local-only`, no updater config.
- `test_infer_non_origin_remote_is_local_only`: a remote named `upstream` but no `origin` → `provider: local-only`, because the checkpoint adapter pushes to `origin` exclusively, so a project without one has no remote this protocol can reach.
- `test_explicit_provider_wins`: `--provider local-only` with a GitHub `origin` → `provider: local-only`.
- `test_infer_records_provenance`: the profile carries the inferred value and its source URL as prose outside the fenced block, and `remote-profile.sh` still resolves the file cleanly.
- `test_existing_profile_untouched`: a hand-written `local-only` profile with a GitHub `origin` → convergence leaves the file byte-identical.

### T-158 unit tests
- **Intent:** [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md)
- Location: `scripts/remote-profile.test.sh`, `scripts/deploy-substrate.test.sh`, `scripts/remote-adapter.test.sh`.
- `test_profile_accepts_gitea_forgejo`: both values resolve and are printed back by the field query.
- `test_profile_rejects_malformed` (existing, extended): `bitbucket` is still rejected, and the diagnostic names every accepted value including the two new ones.
- `test_gitea_gets_renovate`: convergence with `--provider gitea` scaffolds `renovate.json` targeting the work branch.
- `test_forgejo_uses_fallback_checkpoint`: `open-pr` against a `forgejo` profile prints the manual-open fallback and invokes no provider CLI.

### T-159 unit tests
- **Intent:** [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md)
- Location: `scripts/deploy-substrate.test.sh`.
- `test_check_reports_disagreement`: profile records `local-only`, `origin` implies `github` → `--check` names both values, and the project is byte-identical afterwards.
- `test_check_silent_on_agreement`: profile records `github`, `origin` implies `github` → no disagreement reported.
- `test_check_silent_without_remote`: profile records `local-only`, no `origin` → no disagreement reported.
- `test_check_disagreement_is_readonly`: after a disagreement is reported, every file and every git ref in the project is byte-identical.

### T-160 unit tests
- **Intent:** [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md)
- Location: `tools/operator-docs.test.sh`.
- `test_init_documents_provider_inference`: every Init surface states that convergence infers from `origin`, names the `generic` and `local-only` fallbacks, and gives the override; the README names every accepted provider value and the report-don't-rewrite rule.
- `adapter-semantics`, `operator-docs`: both guard suites exit 0 after the prose change.

## Integration Tests

### `test_github_chain_end_to_end` — T-157 + T-158
- **Intents:** [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md)
- The full chain the defect broke, in one fixture: a repository with a GitHub `origin`, converged with **no flags**, produces `provider: github`, a Dependabot config targeting the work branch, and a checkpoint that dispatches to the `gh` stub rather than printing `no PR/MR opened`. This is the regression test for the reported symptom, end to end.

### `test_inference_never_rewrites` — T-157 + T-159
- **Intents:** [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md)
- A project bootstrapped with the wrong provider is diagnosed, not repaired: `--check` reports the disagreement, a subsequent full convergence still leaves the profile byte-identical, and the recorded provider continues to drive behavior. This proves the reconciliation is advisory, which is what makes it safe to run against projects whose profile an operator set deliberately.

### Cross-bundle integration
- **Intents:** [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md)
- `check-bundle-sync.sh` confirms the four bundles carry byte-identical `scripts/` and `schemas/` after the enum and inference changes. No new script file is added this sprint, so `REQUIRED_SCRIPTS` is unchanged.

## End-to-End Tests
- **Status:** possible
- `test_guard_suite_green`: `bash tools/run-guards.sh --determinism` — all suites PASS with matching normalized evidence hashes across both runs. Record the tested head SHA and the authoritative CI conclusion.
- `test_repository_profile_unchanged`: this repository's own profile still records `github`, byte-identical, and `deploy-substrate.sh --check` reports agreement between it and `origin` — the live case of a correct profile that inference must leave alone.
- `test_reported_symptom_is_gone`: reproduce the operator's original report on a throwaway repository — `git init`, add a GitHub `origin`, converge exactly as the Init contract instructs with no arguments — and confirm the profile now records `github` rather than `local-only`. The defect that opened this sprint, retested against the fix.
