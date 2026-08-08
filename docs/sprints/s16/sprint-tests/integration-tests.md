# Sprint 16 Integration Test Results

- **Evidence head:** `026d6faffeba53c87db2610202e4da865304ede2`
- **Result:** 5/5 locked integration tests passed.
- **Hosted matrix:** [guards #31245249580](https://github.com/crussella0129/Animus_Sprint_Loops/actions/runs/31245249580) passed on Ubuntu and macOS at the evidence head.

| Test | Integration boundary exercised | Evidence | Result |
|---|---|---|---|
| `test_pre_build_sync` | remote base → local base → work ancestry before implementation | Before T-130, local `main` was advanced to `origin/main`, installed `sync-work-branch.sh` merged it into `dev`, `git merge-base --is-ancestor main dev` passed, and the tracked tree was clean. Current verification still has `main == origin/main == eb1cb385...` and `main` ancestral to published `dev`. | pass |
| `test_profile_deploy_check_pipeline` | v2 profile → deploy transaction → substrate gate → updater config | Installed GitHub deploy fixtures created only `main`/`dev`, wrote Dependabot against `dev`, resolved the four-field profile, and returned `substrate-complete`; GitLab/generic/local and no-clobber/rollback variants also passed. | pass |
| `test_install_then_runtime` | repository source → native Windows transaction → installed Bash runtime | After exact source/install parity was proven, the installed `remote-profile`, `check-substrate`, `deploy-substrate`, `remote-adapter`, `sync-work-branch`, and Book selftests were run serially under WSL and all passed (3 + 6 + 8 + 5 + 3 named fixtures, plus the complete Book runtime aggregator). The transaction and the two strengthened fixtures were rerun after critic-driven test changes; 49/49 file hashes still match and 0 transaction artifacts remain. | pass |
| `test_four_bundle_contract` | canonical shared assets → four adapters → mutation guard | Bundle parity passed across every mapped asset. Adapter semantics passed on the active corpus, and its 57-case isolated mutation suite proved the expanded inventory non-vacuously. The hosted Ubuntu artifact was retained byte-for-byte as the canonical 15-suite report. | pass |
| `test_live_repository_pre_checkpoint` | Book/profile + GitHub config + workflow + preserved remote payload | Live resolver/config/README assertions passed at the published head. The workflow differs from `origin/bump` by only `branches: [main] → [main, dev]`, so both Actions v7 updates are carried without importing the retired branch's stale configuration ancestry. | pass |

## Host/Fixture Observation

An exploratory parallel launch of six installed Git-Bash fixture scripts caused
one `migrate-to-book` cleanup collision in Git Bash's shared `/tmp`
(`Device or resource busy`). The same installed files passed serially under WSL,
and the canonical runner also executes suites serially. This is recorded as a
host-concurrency limitation, not suppressed as a product failure; no planned
test relies on parallel mutation of one temp namespace.
