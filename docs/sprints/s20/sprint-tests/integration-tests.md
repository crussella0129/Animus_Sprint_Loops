# Sprint 20 Integration Tests

- **Tested head SHA:** recorded in `test-report.md`

## `test_sprint_zero_surface` — T-164 + T-165 + T-166
**Status:** PASS

The whole Sprint 0 surface in one fixture, and the answer to what the operator
asked for. A bare `git init` with a GitHub `origin` and a `Cargo.toml`,
converged with **no flags at all**, produces:

```text
provider: github                          inferred from origin      (sprint 19)
substrate-version: 4                      contract stamp            (sprint 17)
.github/dependabot.yml                    updater, targeting dev    (sprint 16)
.github/workflows/sprint-loops-ci.yml     generated CI              (this sprint)
  on: push / pull_request → [main, dev]
  jobs: rust → cargo fmt --check, clippy -D warnings, cargo test
```

Four sprints' mechanisms composing into one command. No single task's fixtures
prove this, and each of the four links was independently broken within the last
month: the provider defaulted to `local-only`, the contract did not exist, and
CI was absent entirely.

## `test_hand_written_ci_survives` — T-165 + T-166
**Status:** PASS

A project whose `.github/workflows/` already holds a workflow converges fully —
profile, updater, branches, stamp — and its workflow directory is byte-identical
afterwards, with no second workflow added.

This has to hold under a *full* convergence rather than a direct generator call,
because that is how it will actually be met: an established project runs
convergence to pick up a contract version and must not acquire a competing CI
system as a side effect.

## `test_converge_generates_ci_after_stamp` — the ordering property
**Status:** PASS

Convergence raises a project to the current contract in the same run, so where
the CI step sits relative to the stamp decides whether the run that *upgrades* a
project also gives it CI. Placed before the stamp — as the locked plan's wording
implied — a fresh project reads contract 1 and generates nothing, and an
upgrading project sees CI only on a second convergence.

The fixture asserts the marker ends at contract 4 in the same run that produced
the workflow, which is the observable form of "the step runs after the stamp".

## Cross-bundle integration
**Status:** PASS

`check-bundle-sync.sh` confirms the four bundles carry byte-identical `scripts/`
and `schemas/` after two new helpers and their fixtures — four copies each, plus
`REQUIRED_SCRIPTS` entries and two new runner suites.
