# Sprint 16 Test Report

Verification provenance for
[INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) — one
ordinary sprint path for feature and dependency work. Detailed records:
[unit-tests.md](unit-tests.md), [integration-tests.md](integration-tests.md),
[e2e-tests.md](e2e-tests.md), [critique.md](critique.md), and the retained
[canonical confirmations](guards-report.ndjson).

## Intent Verification

| Intent | Acceptance criterion | EARS / tests | Result | Intent evidence update |
|--------|----------------------|---------------|--------|------------------------|
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | profile v2 contains exactly provider/base/work/mergePolicy | T-130 / five locked profile tests, including all four query branches and strict negative paths | pass | Code evidence is T-130; Test evidence links this report |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | deploy creates only base/work; hosted updater targets work; existing config is preserved | T-131 / eight deploy and six substrate fixtures across GitHub, GitLab, generic, and local-only | pass | Code evidence is T-131 |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | updater intake is current-and-green, between sprints; red remains unmerged and unrepairable heads become ordinary dependency-only sprints | T-132 / four-bundle contract assertion, `test_boundary_intake_contract_all_adapters`, `test_unrepairable_updater_uses_ordinary_sprint` | pass | Code evidence is T-132 |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | adapter exposes only the profile-defined work-to-base checkpoint | T-132 / five adapter fixtures and three boundary-resync fixtures | pass | Code evidence is T-132 |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | every corpus checkpoint remains one ordinary sprint | T-132–T-133 / `test_single_checkpoint_contract`, root operator-guide assertions | pass | Documentation evidence is the root README branch/update contract |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | this repository targets Dependabot at dev, covers dev PRs in CI, and preserves Actions v7 | T-133 / five live-repository assertions; hosted guards at the exact final head | pass with caveat | Static PR trigger is proven and the push-triggered matrix is green; direct PR-event confirmation unlocks when Loop opens the checkpoint |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | active-surface guards reject revival of the retired model while preserving historical provenance | T-134 / 57/57 isolated mutations, active-corpus scan, four-bundle parity, 15/15 deterministic guards | pass | Code evidence is T-134 |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | revised model is delivered to the Codex user scope | T-135 / clean transaction, 49/49 source/install hash parity, installed runtime fixtures and router | pass | Delivery evidence is T-135 |
| [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) | remote long-lived branches become exactly main/dev after the checkpoint | M-001 / `test_post_merge_remote_preconditions`, `test_post_merge_remote_topology` | deferred | Human merge/deletion authority is required; INT-0003 remains active and completion evidence remains empty |

## Summary

- Unit tests: 39 passed / 0 failed / 39 total; 1 additional identifier-mutation check passed.
- Integration tests: 5 passed / 0 failed / 5 total.
- E2E tests: 2 passed / 0 failed / 2 executed; 2 post-checkpoint tests deferred behind M-001.
- CI status: green on Ubuntu and macOS.
- Test-critic verdict: `proceed-with-caveats`; both pre-final assertion gaps were fixed and rerun.

## CI Confirmation

- **Head SHA:** `026d6faffeba53c87db2610202e4da865304ede2`
- **CI run:** [guards #31245249580](https://github.com/crussella0129/Animus_Sprint_Loops/actions/runs/31245249580)
- **Conclusion:** success (Ubuntu and macOS matrix legs).
- **Confirmations:** the hosted runners executed the canonical
  `tools/run-guards.sh --determinism` entry point. The retained Ubuntu artifact
  contains 15 unique suites, 15 `PASS` statuses, and 15 `determinism: ok`
  records, and it byte-matches [guards-report.ndjson](guards-report.ndjson).

## Failures

None in the implemented pre-checkpoint scope. The two unexecuted post-merge
checks are explicit authorization-bound acceptance work, not hidden passes.

## Technical Debt Identified

- **M-001 / INT-0003 carry-forward:** after the human-approved Sprint 16 merge,
  verify the migration payload on `main`, resync `main → dev`, then retire the
  local and remote former dependency branch and prove the final two-branch
  topology. Until then INT-0003 remains `active`.
- No implementation defect was deferred from T-130–T-135.

## Coverage Observations

- The pull-request branch filter is statically asserted and the exact workflow
  passed on a hosted push. Direct `pull_request` event evidence is necessarily
  collected only after Loop opens the ordinary `dev → main` checkpoint.
- The strongest pre-checkpoint E2E test starts from an empty hosted-profile
  repository, deploys exactly `main`/`dev`, routes the complete five-phase
  lifecycle, and observes one—and only one—ordinary checkpoint.
- An exploratory parallel Git-Bash fixture launch encountered a shared `/tmp`
  cleanup collision. The installed suite and canonical runner pass serially
  under WSL/POSIX; no planned test depends on parallel mutation of one temp
  namespace.
