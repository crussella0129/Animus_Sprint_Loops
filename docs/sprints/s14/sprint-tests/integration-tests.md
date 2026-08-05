# Sprint 14 Integration Tests

Integration coverage from the locked [test plan](../sprint-plans/test-plan.md).
The strongest integration signal this sprint is the **live dogfood**: this
repository is itself a legacy-active sprint that was migrated to the Book and
resumed without drift.

## Book lifecycle integration
- `test_fresh_book_full_phase_cycle` — `book-routing.test.sh` initializes a
  fixture project and walks research → plan → build → test → loop → ready,
  asserting each derived phase, plus scaffold idempotency. **PASS.**

## Migration-to-lifecycle integration
- `test_legacy_active_sprint_migrates_and_resumes` — `migrate-to-book.test.sh`
  migrates a legacy fixture and confirms Book routing resumes the same phase
  writing only v2 paths. **PASS.**
- **Live dogfood (T-119):** this repository — a real sprint 14 mid-**build** with
  10 legacy sprints of history — was migrated by `migrate-to-book.sh`.
  `current-sprint.sh` = 14 and `current-phase.sh` = `build` **both before and
  after** cutover (verified inside the transactional stage and again post-commit),
  then advanced normally build → test as T-119/T-120 completed. Layout is
  `book-only`. **PASS.**

## Intent-to-evidence integration
- `test_unrealized_to_realized_transition` / `test_illegal_transition_is_rejected`
  — `check-book.test.sh` proves state-dependent evidence: planned/active/deferred
  require work evidence; realized requires completion plus code/test/doc; illegal
  shapes are rejected with the source unchanged. The live `INT-0001` chapter
  exercises the unrealized arc (`proposed → planned → active` recorded in its
  transition history, work evidence linking the sprint 14 plans); realization is
  staged for Loop once completion evidence is attached. **PASS.**

## Cross-harness integration
- `test_all_harnesses_read_same_book_fixture` — `check-bundle-sync.sh` proves the
  shared Book scripts/schemas are byte-identical across claude-code, codex-cli,
  antigravity-ide, and open-harnesses, so every adapter resolves the same paths
  and routing. **PASS.**
- `test_shared_core_divergent_adapters` — `check-adapter-semantics.sh` proves the
  intentionally divergent adapter docs still carry the Book v2 anchors, authority
  roles, native boundaries, and remote-safety rules while remaining non-identical.
  **PASS.**

## Canonical runner integration
- `test_run_guards_includes_book` — the canonical `run-guards.sh` executes Book
  validation, migration/routing selftests, bundle parity, adapter semantics,
  operator-doc contracts, shellcheck, and the determinism meta-check from one
  entry point, emitting one ndjson confirmation per suite. Verified by the sprint
  run (9/10 `determinism: ok`; Windows-only `selftest` CRLF exception documented
  in [unit-tests.md](unit-tests.md)). **PASS.**

## Summary
- Integration checks: pass. The live repository migration is the headline
  integration proof — a real active sprint migrated and resumed with zero
  routing drift and lossless history.
