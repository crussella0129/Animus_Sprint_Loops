# Sprint 19 Integration Tests

- **Tested head SHA:** recorded in `test-report.md`

## `test_github_chain_end_to_end` — T-157 + T-158
**Status:** PASS

The full chain the defect broke, in one fixture. A repository with a GitHub
`origin`, converged with **no flags at all**:

1. `provider: github` is recorded, not `local-only`.
2. `.github/dependabot.yml` is scaffolded targeting the work branch — the
   updater arm that never fired under the old default.
3. The checkpoint path dispatches to the provider rather than printing
   `local-only profile; no PR/MR opened` and exiting 0.

Each link was individually broken by a single unexamined default, and each is
now asserted. The middle link matters most: a project can look fine — Book
created, branches present, sprints closing successfully — while having quietly
lost both its checkpoint and its dependency updates.

## `test_inference_never_rewrites` — T-157 + T-159
**Status:** PASS

A project bootstrapped with the wrong provider is **diagnosed, not repaired**:

- `--check` reports `provider-disagreement: profile records local-only but
  origin implies github (not changed)`.
- The project is byte-identical afterwards, files and refs alike.
- A subsequent full convergence still leaves the profile untouched, and the
  recorded provider continues to drive behavior.

This is what makes the reconciliation safe to run against projects whose profile
an operator set deliberately — the composition of "infer at creation" with
"never rewrite" has to hold in both directions, and only running them together
shows it.

## Cross-bundle integration
**Status:** PASS

`check-bundle-sync.sh` confirms the four bundles carry byte-identical `scripts/`
and `schemas/` after the inference, enum, and schema changes. No new script file
was added this sprint, so `REQUIRED_SCRIPTS` is unchanged — the first sprint in
three where the four-bundle cost was a copy rather than an inventory change.

## A note on suite runtime
The `deploy-substrate` suite grew from sixteen fixtures to twenty-four, each
performing a full convergence, so it is now the slowest suite in the canonical
runner and roughly doubles under `--determinism`. Nothing is wrong, but the
runner's total wall time is becoming a real cost and is recorded as
carry-forward rather than left to be rediscovered.
