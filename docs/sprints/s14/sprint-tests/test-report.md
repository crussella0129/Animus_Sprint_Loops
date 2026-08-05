# Sprint 14 Test Report

Verification provenance for [INT-0001](../../../intents/INT-0001-project-book.md)
— the Project Book architecture. Records: [unit-tests.md](unit-tests.md),
[integration-tests.md](integration-tests.md), [e2e-tests.md](e2e-tests.md),
[critique.md](critique.md).

## Intent Verification
| Intent | Acceptance criterion | EARS / tests | Result | Intent evidence update |
|--------|----------------------|--------------|--------|------------------------|
| [INT-0001](../../../intents/INT-0001-project-book.md) | `docs/` validates under `check-book.sh` | T-119 `test_repository_book_validates` (`valid v2 Book (1 intent chapters)`) | pass | Test evidence links this report |
| [INT-0001](../../../intents/INT-0001-project-book.md) | one writable authority; split-brain refused | T-119 `test_repository_has_single_authority` (`book-only`); `test_migrate_conflict_refuses` | pass | — |
| [INT-0001](../../../intents/INT-0001-project-book.md) | every harness resolves the same Book paths/routing | `check-bundle-sync.sh` byte-identity; `check-adapter-semantics.sh` | pass | — |
| [INT-0001](../../../intents/INT-0001-project-book.md) | legacy migrates losslessly (pre/post hash 1:1) | T-119 `test_historical_import_is_lossless` (146/146, 0 mismatch) | pass | — |
| [INT-0001](../../../intents/INT-0001-project-book.md) | canonical suite runs Book validation etc. locally and in CI | T-120 `test_run_guards_includes_book`; `test_repository_full_guard_suite` | pass (CI green, Ubuntu + macOS) | — |

`INT-0001` is `realized`: T-119 and T-120 completion evidence plus code, test,
and documentation evidence are attached, and the sprint 14 guard suite concluded
`success` on the CI matrix.

## Summary
- Unit tests: T-119 6/6, T-120 4/4 pass; T-110–T-118 suites pass via the
  canonical runner (Windows-only `selftest` CRLF exception documented).
- Integration tests: pass (headline: live repository migration resumed with zero
  routing drift).
- E2E tests: repository-behavior green locally except the documented
  Windows-only `selftest` exception; Codex launch-time discovery deferred to a
  human checkpoint.
- CI status: **green** (Ubuntu + macOS matrix). On CI (POSIX awk), all **10/10
  suites PASS**; the local Windows-only `selftest` CRLF exception is absent.

## CI Confirmation
- **Head SHA:** `96bb3744ad9e47f3c1d109c75eac4e33e71ebd30` (sprint-14 tip)
- **CI run:** [guards #30971977981](https://github.com/crussella0129/Animus_Sprint_Loops/actions/runs/30971977981)
  (pull_request) and `#30971976637` (push), workflow `guards`.
- **Conclusion:** `success` (both runs; Ubuntu + macOS legs).
- **Confirmations:** the CI legs ran the identical `tools/run-guards.sh
  --determinism` entry point and passed all suites with determinism. Local
  canonical run (Windows git-bash) recorded 9/10 `PASS`, all `determinism: ok`,
  with the single `selftest` CRLF exception attributable to Windows GNU awk
  `\r`-stripping (green on CI, backlog T-121).

## Failures
- `selftest` → chained `runtime-helpers` CRLF-preservation assertions fail
  **only under Windows git-bash GNU awk 5.4.0** (`\r`-stripping). Root cause is
  environmental, not a defect in this sprint's deliverables; green on POSIX CI.
  No re-architecture required.

## Technical Debt Identified
- **T-121 (backlog):** make `finalize-plan.sh` CRLF detection robust to
  `\r`-stripping awk (byte-safe first-line inspection instead of
  `awk 'NR==1 {...substr==\r...}'`), and mirror in the `runtime-helpers` CRLF
  assertions. Windows-only; passes on CI today.

## Coverage Observations
- The strongest evidence this sprint is the live dogfood: a real active sprint
  with 10 sprints of history migrated losslessly (146/146 by SHA-256) and
  resumed with identical routing.
- The canonical runner now fingerprints and executes every Book suite from one
  entry point shared by the local Test phase and CI, so the two cannot drift.
- Local Windows coverage is bounded by two host limitations (no real symlinks;
  `\r`-stripping awk); both are handled without weakening POSIX/CI coverage
  (capability-guarded skips; backlog T-121).
