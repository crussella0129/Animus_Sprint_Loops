# Sprint 14 Unit Tests

Tests derive from the locked [test plan](../sprint-plans/test-plan.md). Book
lifecycle, initialization, migration, runtime, and adapter unit tests for
T-110–T-118 are implemented as the deterministic guard suites and executed by
the canonical runner (`tools/run-guards.sh`); the T-119/T-120 tests below were
additionally verified read-only against the migrated repository.

## Canonical suite run (evidence)

`bash tools/run-guards.sh --determinism` — **9/10 suites PASS with
`determinism: ok`**. Per-suite: selftest, merge-policy, merge-policy-test,
plugin-manifest, bundle-sync, bundle-sync-test, adapter-semantics,
adapter-semantics-test, operator-docs, shellcheck. The `selftest` suite chains
`check-book.test.sh`, `book-routing.test.sh`, `migrate-to-book.test.sh`, and
`runtime-helpers.test.sh` (T-110–T-113 unit coverage) plus the phase-transition
walk.

- **Known local exception:** `selftest`'s chained `runtime-helpers` CRLF
  assertions fail **only under Windows git-bash GNU awk 5.4.0**, which strips a
  trailing `\r`; both `finalize-plan.sh`'s `\r`-detection and the test's own
  `\r`-assertion misfire there. Reproduced and root-caused
  (`printf 'abc\r\n' | awk '{print length}'` → 3). Green on the authoritative
  Ubuntu/macOS CI. Filed as backlog **T-121**; not a T-119/T-120 regression.

## T-110–T-118 (Book contract, init, migration, runtime, protocol, adapters, parity)

Implemented as fixtures and executed via the canonical suite:

- `check-book.test.sh` — v2 marker, duplicate-ID, invalid-state, work/realization
  evidence, split-brain, legacy-only, SUMMARY-navigation-only. **PASS.**
- `book-routing.test.sh` — tracked-scaffold init, gitignore preservation, full
  phase walk, scaffold idempotency, legacy detection, split-brain router
  refusal. **PASS.**
- `migrate-to-book.test.sh` — lossless/idempotent migration, conflict + router
  split-brain refusal, path-safety refusals, history-not-authority. **PASS**
  (symlink negatives portably skipped on this host — see T-120 below).
- `runtime-helpers.test.sh` — intent-review / legacy-heading / empty-plan /
  accepting-critic / atomic / budget gates; ledger back-fill, completion
  evidence, abort/close/confidence Book updates. **PASS on POSIX / CI**; local
  Windows CRLF exception above.
- `check-adapter-semantics.test.sh`, `check-bundle-sync.test.sh`,
  `operator-docs.test.sh` — adapter Book anchors/authority/boundaries, parity
  inventories, operator-doc contracts. **PASS.**

## T-119 — Repository dogfood migration (verified against the live repo)

- `test_repository_book_validates` — `check-book.sh .` → `valid v2 Book (1 intent
  chapters)`. **PASS.**
- `test_repository_summary_links_resolve` — every `docs/SUMMARY.md` link resolves
  (0 broken) and `INT-0001` is reachable from navigation. **PASS.**
- `test_repository_has_single_authority` — `book_layout_state` = `book-only`; no
  root `sprints/`, `agent-tasks/`, `decisions.md`, or `confidence.txt` remains.
  **PASS.**
- `test_repository_intent_evidence` — `INT-0001` is `active` and its Work
  evidence links this sprint's build and test plans; `check-book.sh` enforces
  state-appropriate evidence shape. **PASS.**
- `test_historical_import_is_safe` — the 3 migrated per-sprint
  `guards-report.ndjson` files contain only suite names, SHA-256 hashes, status,
  duration, and normalized timestamps — no secrets, credentials, or absolute
  paths. **PASS.**
- `test_historical_import_is_lossless` — pre/post SHA-256 inventory: **146/146
  files identical, 0 missing, 0 mismatch**; reviewed exclusions = **none**
  ([migration-verification.md](../migration-verification.md)). **PASS.**

## T-120 — Canonical suite registration

- `test_suite_registry_complete` — every one of the 10 `SUITES` names resolves in
  both `suite_cmd` and `suite_script_hash` (0 incomplete). **PASS.**
- `test_negative_fixtures_are_non_vacuous` — the registered negative suites assert
  their exact diagnostic, not just non-zero exit: `check-bundle-sync.test.sh`'s
  `expect_fail` requires exit 1 **plus** an exact stderr line; the
  `migrate-to-book`/`adapter-semantics` negatives grep exact diagnostics. **PASS.**
- `test_deterministic_confirmations` — two normalized runs emit identical
  evidence hashes; the run recorded `determinism: ok` for all suites, including
  the three newly registered ones (`adapter-semantics`, `adapter-semantics-test`,
  `operator-docs`). **PASS.**
- `test_shell_portability` — the `shellcheck` suite now covers the shared scripts
  (via the byte-identical claude-code copy), the intentionally divergent Codex
  `install.sh`/tests, and every bundle installer + adapter-contract test — all
  clean at `-S warning`; the CI matrix runs Ubuntu + macOS. **PASS.**
  Portability of the symlink-rejection fixtures added via a `can_symlink`
  capability guard (skip where the host cannot create a real symlink; still
  executed on POSIX CI).

## Summary

- T-119 unit checks: 6/6 pass (verified against the live migrated repo).
- T-120 unit checks: 4/4 pass.
- T-110–T-118 suites: pass via the canonical runner; one Windows-only
  `runtime-helpers` CRLF exception documented above (CI-green, backlog T-121).
