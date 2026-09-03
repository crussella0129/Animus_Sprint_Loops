# Sprint 19 Test Report

**Verdict: PASS with caveats.** Every acceptance criterion this sprint scoped
has an executed, named test, and CI is green on both matrix legs. Five critique
concerns are recorded; three become carry-forward work.

## Authoritative confirmation

| Field | Value |
|---|---|
| Tested head SHA | `facd325d3dec158d96b49389bdcea98f17f5e84c` |
| Run | [33715133221](https://github.com/crussella0129/Animus_Sprint_Loops/actions/runs/33715133221) |
| Conclusion | **success** |
| `guards (ubuntu-latest)` | success |
| `guards (macos-latest)` | success |

All 17 suites pass on CI, including `selftest`, which fails locally for the
Windows-only reason below. Local run: **16/17**, every suite
`"determinism":"ok"`.

## The defect this sprint existed to fix

| | Before | After |
|---|---|---|
| Recorded provider | `local-only` | `github` |
| Updater config | absent | `.github/dependabot.yml` |
| Checkpoint | `no PR/MR opened`, exit 0 | dispatches to the provider |
| Provenance | none | inferred value + source URL in the profile |

Reproduced both ways on a throwaway repository, running convergence exactly as
the Init contract instructs — with no arguments. The old behavior was silent:
nothing failed, the sprint closed successfully, and the loop simply had no
remote half.

## Intent acceptance criteria

| INT-0006 criterion (in scope this sprint) | Evidence | Result |
|---|---|---|
| Inference from a recognized `origin`, with the source URL recorded | `test_infer_github_https`, `test_infer_github_ssh`, `test_infer_gitlab`, `test_infer_forgejo_codeberg`, `test_infer_records_provenance` | PASS |
| No `origin` → `local-only` | `test_infer_no_remote_is_local_only`, `test_infer_non_origin_remote_is_local_only` | PASS |
| Unrecognized remote → `generic`, never `local-only` | `test_infer_unknown_host_is_generic` | PASS |
| Explicit `--provider` always wins | `test_explicit_provider_wins` | PASS |
| An existing profile is reported on, never rewritten | `test_existing_profile_untouched`, `test_check_reports_disagreement`, `test_check_disagreement_is_readonly` | PASS |
| `gitea`/`forgejo` accepted; unknown values still rejected | `test_profile_accepts_gitea_forgejo`, `test_profile_rejects_malformed`, `test_profile_enum_diagnostic_names_every_value` | PASS |
| The operator-facing statement of detection exists | `test_init_documents_provider_inference`, `adapter-semantics`, `operator-docs` | PASS |

## Scope this sprint did not close

INT-0006 remains **`active`**. Six of its thirteen acceptance criteria are
proven; the REST checkpoint tier, the CI truth check, and best-effort base
protection were out of scope by design and were recorded as such at plan time in
three places. Realizing the chapter now would misrepresent the delivery.

CI *generation* — per-provider workflow files chosen from the project's actual
languages, and reconciled as intents add or drop them — is
[INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) and is
untouched. Provider truth was its prerequisite; that prerequisite now holds.

## Caveats carried into Loop

- **C-001** — a fixture passed without exercising anything, caught only by a
  stray diagnostic. Fixed, and the general rule (a "did not change" assertion
  must be paired with proof the operation ran) is carry-forward, because other
  fixtures share the shape.
- **C-002** — a cross-task dependency missing from the plan, for the second
  sprint running. Recorded as evidence for T-154 rather than a new task.
- **C-003** — a local-path `origin` resolves to `generic` and is untested.
  Carry-forward.
- **C-004** — the runner's wall time roughly tripled under machine contention.
  Carry-forward; deliberately not solved here, since memoization is a
  separately-scoped ROADMAP decision.
- **C-005** — partial intent delivery, recorded rather than repaired.

`selftest` is red locally for the third consecutive sprint on backlog defect
T-121. Unlike Sprints 17 and 18, no fixture of this sprint sits downstream of the
abort point, so nothing needed a focused-harness workaround — but T-155 stands.

## Verdict

Pass. Final critique verdict: `proceed-with-caveats`.
