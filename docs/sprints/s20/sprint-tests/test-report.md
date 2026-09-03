# Sprint 20 Test Report

**Verdict: PASS with caveats.** Every acceptance criterion this sprint scoped
has an executed, named test, and CI is green on both matrix legs. One genuine
regression was found by the suite and fixed. Five critique concerns are
recorded; two become carry-forward work.

## Authoritative confirmation

| Field | Value |
|---|---|
| Tested head SHA | `51fb9553e75c73076a6afe6bb7652dbf48168df3` |
| Run | [33805640507](https://github.com/crussella0129/Animus_Sprint_Loops/actions/runs/33805640507) |
| Conclusion | **success** |
| `guards (ubuntu-latest)` | success |
| `guards (macos-latest)` | success |

All 19 suites pass on CI, including `selftest` — which confirms T-121 is
Windows-only rather than a real defect in the suite.

## What the sprint delivers

A bare `git init` with a GitHub origin, converged with **no flags**:

```text
provider: github                          inferred from origin      (sprint 19)
substrate-version: 4                      contract stamp            (sprint 17)
.github/dependabot.yml                    updater, targeting dev    (sprint 16)
.github/workflows/sprint-loops-ci.yml     generated CI              (this sprint)
  on: push / pull_request → [main, dev]
  jobs: rust → cargo fmt --check, clippy -D warnings, cargo test
```

Previously a fresh project got the first three and no CI at all, so its first
checkpoint was green because nothing ran.

## Intent acceptance criteria

| INT-0012 criterion (in scope) | Evidence | Result |
|---|---|---|
| A fresh project on each provider converges to CI in that host's format; `local-only` gets none | `test_scaffold_paths_per_provider`, `test_scaffold_local_only_writes_nothing`, `test_converge_generates_ci`, `test_converge_local_only_gets_no_ci` | PASS |
| The configuration runs the languages the project contains | the nine `detect-languages` fixtures, `test_scaffold_jobs_match_detection`, `test_scaffold_uses_canonical_runner` | PASS |
| An existing configuration is never clobbered | `test_scaffold_refuses_existing_workflow_dir`, `test_hand_written_ci_survives`, and this repository's own untouched `ci.yml` | PASS |
| A job whose failure is observable when tests fail | `test_scaffold_generic_ci_actually_fails` | PASS for `generic` only — see C-002 |

Triggers naming both branches, rollback, idempotence, and the `--check` preview
are covered by `test_scaffold_triggers_name_both_branches` and the four T-166
convergence fixtures.

## The regression the suite caught

`check-tracked` failed on the first full run, from this sprint's contract raise.
A Sprint 18 fixture asserted the bundle constant equalled the literal `3`, so
raising it to 4 broke a test for a reason unrelated to the property it protects.
It now asserts the relationship. A sweep found the same shape **freshly
reintroduced one task later** in this sprint's own
`test_converge_generates_ci_after_stamp`; that one now reads the constant too.

Sprint 17 established driving fixtures from the constant. It has now been
dropped twice in one sprint, by the same author, which makes it a habit rather
than an oversight.

## Scope this sprint did not close

INT-0012 remains **`active`**. Parts 3 and 4 — reconciling jobs as a project's
languages change, and proposing rather than performing removals — are untouched;
both need to read intent chapters and are a different mechanism from generation.

INT-0006's CI truth check, which would verify that what this sprint generates can
actually fail, is also still outstanding.

## Caveats carried into Loop

- **C-001** — the locked plan contained a clause that specified the defect: a
  version gate evaluated at entry, inside the operation that changes the version.
  Fixed as a recorded deviation; the lesson is carry-forward.
- **C-002** — the observable-failure criterion is met for one host of five.
  Deferred; needs INT-0006 plus a real hosted run.
- **C-003** — no fixture asserts the generated YAML parses. Carry-forward, and a
  deliberate dependency decision rather than an oversight.
- **C-004** — the generated Python step's exit-5 allowance must be permitted by
  INT-0006's future truth check. Second recording of the same requirement.
- **C-005** — third contract raise in four sprints, and the first that writes a
  new file. Deferred with rationale.

`selftest` is red locally for the fourth consecutive sprint on T-121. No fixture
of this sprint sits downstream of the abort point, so nothing needed a workaround.

## Verdict

Pass. Final critique verdict: `proceed-with-caveats`.
