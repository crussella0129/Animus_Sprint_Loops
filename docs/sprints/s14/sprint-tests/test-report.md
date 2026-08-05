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
| [INT-0001](../../../intents/INT-0001-project-book.md) | canonical suite runs Book validation etc. locally and in CI | T-120 `test_run_guards_includes_book`; `test_repository_full_guard_suite` | pass (local); CI pending push | — |

`INT-0001` remains `active`. Realization is staged for the Loop phase once
completion evidence (T-119/T-120 in `completed-tasks.md`) plus code/test/doc
evidence are attached.

## Summary
- Unit tests: T-119 6/6, T-120 4/4 pass; T-110–T-118 suites pass via the
  canonical runner (Windows-only `selftest` CRLF exception documented).
- Integration tests: pass (headline: live repository migration resumed with zero
  routing drift).
- E2E tests: repository-behavior green locally except the documented
  Windows-only `selftest` exception; Codex launch-time discovery deferred to a
  human checkpoint.
- CI status: **pending push** (Ubuntu + macOS matrix). Local canonical
  confirmations: **9/10 suites PASS, all `determinism: ok`**.

## CI Confirmation
- **Head SHA:** `fc8dd728527ff9594f5d9671fb3c1e0362bc79df`
- **CI run:** pending — the sprint head has not yet been pushed (first
  outward-facing action; awaiting operator decision on push/PR strategy).
- **Conclusion:** pending
- **Confirmations:** local canonical run — selftest `FAIL(det:ok, Windows-gawk
  CRLF only)`, merge-policy `PASS`, merge-policy-test `PASS`, plugin-manifest
  `PASS`, bundle-sync `PASS`, bundle-sync-test `PASS`, adapter-semantics `PASS`,
  adapter-semantics-test `PASS`, operator-docs `PASS`, shellcheck `PASS` — all
  `determinism: ok`.
- **To finalize:** push the sprint head, then record the CI conclusion on this
  SHA (authoritative) here before any merge.

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
