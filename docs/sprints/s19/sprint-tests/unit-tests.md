# Sprint 19 Unit Tests

- **Tested head SHA:** recorded in `test-report.md`

Every EARS clause in the locked build plan maps to a named fixture. **Every
inference fixture omits `--provider`** — the path all sixteen pre-sprint deploy
fixtures took a flag around, and the reason a `local-only` default survived them.

## T-157 — provider inference
`deploy-substrate` suite.

| Test | Clause | Result |
|---|---|---|
| `test_infer_github_https` | `https://github.com/o/r.git` → `github`, and `.github/dependabot.yml` is scaffolded | PASS |
| `test_infer_github_ssh` | `git@github.com:o/r.git`, `ssh://git@github.com/o/r.git`, and a mixed-case host all → `github` | PASS |
| `test_infer_gitlab` | `gitlab.example.net` (an enterprise host) → `gitlab`, `renovate.json` scaffolded | PASS |
| `test_infer_forgejo_codeberg` | `codeberg.org` → `forgejo` | PASS |
| `test_infer_unknown_host_is_generic` | an unrecognized remote → `generic`, **not** `local-only` | PASS |
| `test_infer_no_remote_is_local_only` | no `origin` → `local-only`, and no updater config | PASS |
| `test_infer_non_origin_remote_is_local_only` | a remote named `upstream` but no `origin` → `local-only` | PASS |
| `test_explicit_provider_wins` | `--provider local-only` against a GitHub origin → `local-only` | PASS |
| `test_infer_records_provenance` | the inferred value and its source URL are recorded outside the fence, the resolver still parses the file, and an explicit provider is never claimed as inferred | PASS |
| `test_existing_profile_untouched` | an existing profile is byte-identical after convergence, and its recorded provider is unchanged | PASS |

**A false pass was found and fixed during Build.**
`test_existing_profile_untouched` originally created `docs/work` before the Book
existed, so `init-sprint` refused, convergence never ran, and the profile was
trivially unchanged — the fixture passed without exercising anything. It now
asserts convergence *completed* (`substrate-complete` in its output) before
asserting the profile did not change.

## T-158 — the provider enum
`remote-profile`, `deploy-substrate`, and `remote-adapter` suites.

| Test | Clause | Result |
|---|---|---|
| `test_profile_accepts_gitea_forgejo` | both values resolve, by field query and full resolve | PASS |
| `test_profile_rejects_malformed` (existing) | `bitbucket` is still rejected after widening | PASS |
| `test_profile_enum_diagnostic_names_every_value` | the rejection diagnostic names all six accepted values | PASS |
| `test_gitea_gets_renovate` | `gitea` and `forgejo` both scaffold `renovate.json` targeting the work branch | PASS |
| `test_forgejo_uses_fallback_checkpoint` | `open-pr` takes the push-and-compare fallback and invokes no provider CLI | PASS |

`deploy-substrate.sh` carries **two** provider dispatches — one on the write path
and one in the `--check` drift report. Both were widened; widening only the first
would have made `--check` under-report the pending Renovate step for these hosts,
a silent disagreement between what convergence says it will do and what it does.

## T-159 — the disagreement report
`deploy-substrate` suite.

| Test | Clause | Result |
|---|---|---|
| `test_check_reports_disagreement` | a `local-only` profile against a GitHub origin reports `provider-disagreement`, naming both values | PASS |
| `test_check_disagreement_is_readonly` | every file and every git ref is byte-identical afterwards, and the recorded provider is unrepaired | PASS |
| `test_check_silent_on_agreement` | a `github` profile with a GitHub origin reports nothing | PASS |
| `test_check_silent_without_remote` | a `local-only` profile with no origin reports nothing | PASS |

The report is deliberately **not** counted as a pending convergence step, so it
does not change `--check`'s exit code: it is a diagnosis for a person, not work
convergence intends to do.

## T-160 — the operator-facing contracts
`operator-docs` and `adapter-semantics` suites. 7/7 documentation contracts.

| Test | Clause | Result |
|---|---|---|
| `test_init_documents_provider_inference` | all four Init surfaces name `origin`, `generic`, and `local-only`; both phase contracts name `--provider` and `forgejo`; the README names every accepted value and the never-rewritten rule; the schema states the values are declared rather than inferred | PASS |
| `adapter-semantics` | every adapter authority and runtime contract still holds after the prose change | PASS |
