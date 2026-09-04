Finalized - DO NOT EDIT

# Sprint 20 Test Plan

## Intent Traceability

| Intent | Acceptance criterion | Build task / EARS clause | Verification |
|--------|----------------------|--------------------------|--------------|
| [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) | A fresh project on each provider converges to CI in that host's format; `local-only` gets none | T-165 / the per-provider path clauses; T-166 / the contract-4 generation clause | `test_scaffold_paths_per_provider`, `test_scaffold_local_only_writes_nothing`, `test_converge_generates_ci` |
| [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) | The configuration runs the languages the project actually contains | T-164 / the per-manifest detection clauses; T-165 / the canonical-runner clause | `test_detect_rust`, `test_detect_go`, `test_detect_python`, `test_detect_node`, `test_detect_shell`, `test_detect_polyglot`, `test_scaffold_uses_canonical_runner` |
| [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) | An existing CI configuration is never clobbered | T-165 / the non-empty-directory clause | `test_scaffold_refuses_existing_workflow_dir` |
| [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) | Generated triggers reach the branch sprints commit to | T-165 / the trigger clause | `test_scaffold_triggers_name_both_branches` |
| [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) | Generation is a convergence step with rollback and a preview | T-166 / the rollback, idempotence, and `--check` clauses | `test_converge_rolls_back_ci`, `test_converge_ci_idempotent`, `test_check_reports_pending_ci` |
| [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) | An un-converged project is unaffected | T-166 / the below-contract-4 clause | `test_ci_generation_inert_below_contract_4` |
| [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) | The operator-facing statement exists | T-167 / the Init, README, and guard clauses | `test_init_documents_ci_generation`, `adapter-semantics`, `operator-docs` |

## Unit Tests

### T-164 unit tests
- **Intent:** [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md)
- Location: new `scripts/detect-languages.test.sh`, registered as the `detect-languages` suite.
- `test_detect_rust`, `test_detect_go`, `test_detect_node`: a project containing only that manifest prints only that token.
- `test_detect_python`: each of `pyproject.toml`, `requirements.txt`, and `setup.py` independently yields `python`, and a project with two of them yields it once.
- `test_detect_shell`: a tracked `*.sh` yields `shell`; an **untracked** `*.sh` does not, so scratch files do not decide a project's languages.
- `test_detect_polyglot`: a project with four manifests prints all four tokens, one per line, sorted.
- `test_detect_empty_project`: no manifests → no output, exit 0.
- `test_detect_is_deterministic`: two runs against the same project produce byte-identical output.
- `test_detect_canonical_runner`: a project with `tools/run-guards.sh` additionally prints `canonical:tools/run-guards.sh`.

### T-165 unit tests
- **Intent:** [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md)
- Location: new `scripts/scaffold-ci.test.sh`, registered as the `scaffold-ci` suite.
- `test_scaffold_paths_per_provider`: `github` → `.github/workflows/sprint-loops-ci.yml`; `gitea` → `.gitea/workflows/…`; `forgejo` → `.forgejo/workflows/…`; `gitlab` → `.gitlab-ci.yml`; `generic` → an executable `ci.sh`.
- `test_scaffold_local_only_writes_nothing`: `local-only` → no file created anywhere.
- `test_scaffold_refuses_existing_workflow_dir`: a workflow directory holding an unrelated file → nothing written, the existing file byte-identical, and a message saying the existing configuration was left alone.
- `test_scaffold_triggers_name_both_branches`: a profile with non-default names (`trunk`/`work`) produces triggers naming both — proving the branches come from the profile and not from a literal.
- `test_scaffold_jobs_match_detection`: a Rust-only project yields a rust job and no node job; a polyglot project yields one job per detected language.
- `test_scaffold_uses_canonical_runner`: when the canonical token is present, the generated configuration invokes that runner and emits no per-language jobs.
- `test_scaffold_is_byte_stable`: two runs with identical inputs produce byte-identical files.
- `test_scaffold_generic_ci_actually_fails`: the `generic` output is a shell script, so it can be executed — a fixture project whose test command fails makes the generated `ci.sh` exit non-zero, and one whose commands pass makes it exit 0. This is the only host whose generated configuration can be *run* in a fixture, and it is the closest available proof that generated jobs are wired to real commands rather than being decorative.
- `test_scaffold_python_tolerates_no_tests`: the generated Python job accepts pytest's exit 5 and **nothing else** — the file contains no `|| true`, which INT-0006's truth check will reject.

### T-166 unit tests
- **Intent:** [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md)
- Location: `scripts/deploy-substrate.test.sh`.
- `test_converge_generates_ci`: a fresh GitHub project converges to a workflow at the right path with both branches in its triggers.
- `test_converge_ci_idempotent`: a second convergence leaves every file and every git ref byte-identical.
- `test_converge_rolls_back_ci`: `DEPLOY_SUBSTRATE_FAIL_AFTER=ci` → the generated configuration is removed and its directory left as it was.
- `test_check_reports_pending_ci`: `--check` on a project missing its configuration names the pending generation step and writes nothing.
- `test_ci_generation_inert_below_contract_4`: a Book stamped 3 gets no CI configuration.

### T-167 unit tests
- **Intent:** [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md)
- Location: `tools/operator-docs.test.sh`.
- `test_init_documents_ci_generation`: every Init surface names the generated file for each provider and states `local-only` gets none; the README states an existing configuration is never touched and that deletion is permanent.
- `adapter-semantics`, `operator-docs`: both guard suites exit 0 after the prose change.

## Integration Tests

### `test_sprint_zero_surface` — T-164 + T-165 + T-166
- **Intents:** [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md), [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md)
- The whole Sprint 0 surface in one fixture: a repository with a GitHub `origin` and a `Cargo.toml`, converged with **no flags**, produces an inferred `github` profile, a Dependabot config, and a workflow containing a rust job whose triggers name both branches. This is the composition the operator asked for — "a comprehensive CI test base upon sprint 0" — and no single task's fixtures prove it.

### `test_hand_written_ci_survives` — T-165 + T-166
- **Intents:** [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md)
- A project whose `.github/workflows/` already holds a workflow converges fully — profile, updater, branches, stamp — and its workflow directory is byte-identical afterwards. The generated-vs-hand-written boundary has to hold under a *full* convergence, not just a direct generator call, because that is how it will actually be met.

### `test_ci_generation_inert_below_contract_4` — backwards-compatibility regression
- **Intents:** [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md), [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- A Book stamped at contract 3 converges without gaining any CI configuration, exactly as it did before this sprint. The claim under test, not asserted.

## End-to-End Tests
- **Status:** possible
- `test_guard_suite_green`: `bash tools/run-guards.sh --determinism` — all suites PASS with matching normalized evidence hashes across both runs, including the two new suites. Record the tested head SHA and the authoritative CI conclusion.
- `test_repository_converges_to_contract_4`: this repository converges from contract 3 to 4 with a one-line marker diff and a byte-identical re-run.
- `test_repository_workflow_untouched`: this repository has a hand-written `.github/workflows/ci.yml`; after convergence its workflow directory is byte-identical and no `sprint-loops-ci.yml` exists. The live case of the no-clobber rule, on a project that would be actively harmed by getting a second workflow.
