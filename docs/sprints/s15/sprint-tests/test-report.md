# Sprint 15 Test Report

Verification provenance for [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md)
— the Sprint Loops substrate layer. Records:
[unit-tests.md](unit-tests.md), [integration-tests.md](integration-tests.md),
[e2e-tests.md](e2e-tests.md), [critique.md](critique.md).

## Intent Verification
| Intent | Acceptance criterion | EARS / tests | Result | Intent evidence update |
|--------|----------------------|--------------|--------|------------------------|
| [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) | substrate gate yields complete/absent/partial | T-123 `check-substrate.test.sh` (7/7) | pass | Test evidence links this report |
| [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) | idempotent Sprint 0 deploy + rollback | T-124 `deploy-substrate.test.sh` (4/4) | pass | — |
| [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) | no per-sprint branch; one `work→base` PR/MR per sprint | T-125 `remote-adapter.test.sh` (4/4); T-127 docs; T-128 adapter-semantics negatives | pass | — |
| [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) | profile selects provider; human-approve default | T-122 `remote-profile.test.sh` (3/3); T-125 merge-policy test | pass | — |
| [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) | `bump→main→dev` inherit via boundary resync, single confluence | T-126 `sync-work-branch.test.sh` (3/3) | pass | — |
| [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) | substrate lives in the skill, covered by the guard suite | T-128 registration (15/15) + bundle-sync + adapter-semantics (47/47) | pass | — |
| [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) | dogfood: this repo is substrate-complete | T-129 `check-substrate .` = `substrate-complete` | pass | — |

`INT-0002` is `active`; realization is staged for Loop once completion evidence
(T-122–T-129 in `completed-tasks.md`) and code/doc evidence are attached and CI
is green.

## Summary
- Unit tests: remote-profile 3/3, check-substrate 7/7, deploy 4/4, adapter 4/4,
  resync 3/3; adapter-semantics 47/47 (incl. two new non-vacuous negatives).
- Integration: pass (headline: live repo retrofit → `substrate-complete`).
- E2E: substrate/guard behavior green locally except the documented Windows-only
  `selftest` CRLF exception; the `dev→main` merge is a human checkpoint.
- CI status: **green** (Ubuntu + macOS matrix). On CI (POSIX awk) all 15 suites
  pass, including `selftest`; the local Windows-only CRLF exception is absent.

## CI Confirmation
- **Head SHA:** `97e11eb` (sprint-15 tip — the loop-close commit)
- **CI run:** [guards #31146484027](https://github.com/crussella0129/Animus_Sprint_Loops/actions/runs/31146484027)
  (pull_request) and `#31146481431` (push), workflow `guards`.
- **Conclusion:** `success` (both runs; Ubuntu + macOS legs).
- **Confirmations:** the CI legs ran the identical `tools/run-guards.sh
  --determinism` entry point and passed all 15 suites — including the five new
  substrate suites, `adapter-semantics`(+`-test`, 47/47), and `selftest` — with
  determinism. The local Windows run matched except `selftest`'s gawk CRLF quirk
  (backlog T-121).

## Failures
- `selftest` → chained `runtime-helpers` CRLF assertions fail **only under
  Windows git-bash GNU awk** (`\r`-stripping); environmental, green on POSIX CI,
  unrelated to this sprint's deliverables. No re-architecture required.

## Technical Debt Identified
- **T-121 (backlog):** byte-safe CRLF detection for `finalize-plan.sh` /
  `runtime-helpers` (Windows-only; CI-green today).
- Dependabot wiring (`.github/dependabot.yml`) for the new `bump` branch and
  `main` branch protection are operator follow-ups (noted in T-129).

## Coverage Observations
- The strongest evidence is the live dogfood: a real 15-sprint repo retrofitted
  to `substrate-complete` with only the intended additions.
- The five substrate scripts + adapter-semantics contract are registered in the
  one canonical runner shared by the local Test phase and CI, so they cannot
  drift.
