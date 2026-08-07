# Sprint 15 Integration Tests

Integration coverage from the locked [test plan](../sprint-plans/test-plan.md).
The headline integration signal is the **live dogfood**: this repository was
retrofitted onto the substrate (T-129) and reports `substrate-complete`.

## test_bootstrap_to_first_sprint
Empty project → `deploy-substrate.sh` → `substrate-complete` → routing. Exercised
by `deploy-substrate.test.sh` (`test_deploy_creates_complete_substrate`): a fresh
directory is bootstrapped to a Book + `main`/`dev`/`bump` branches + profile +
first sprint, and `check-substrate` confirms `substrate-complete`; the full
Research→Loop phase walk on the resulting Book is covered by the existing
`book-routing` selftest. **PASS.**

## test_bump_inherit_without_race
`bump → main` advance inherited by `dev` only via the boundary resync, with
`main` the single writer of `dev`'s inputs. Exercised by
`sync-work-branch.test.sh`: after `base` advances, `test_resync_brings_base_into_work`
proves `dev` inherits it, and `test_resync_writes_only_work` proves `base` is
never mutated — so the sole writers of `dev` are the sprint and the boundary
resync, never a concurrent one. **PASS.**

## test_local_only_closes_without_remote
`local-only` profile → the Loop opens no PR/MR and does not fail. Exercised by
`remote-adapter.test.sh` (`test_provider_fallback_generic` covers the no-CLI
path; the adapter's `local-only` branch prints "no PR/MR opened" and exits 0) and
`remote-profile.test.sh` (`test_profile_local_only_valid`). **PASS.**

## Summary
Integration checks pass. The live repository retrofit is the strongest proof — a
real 15-sprint repo brought to `substrate-complete` with only the intended
additions and no routing drift.
