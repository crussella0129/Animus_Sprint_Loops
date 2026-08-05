# Sprint 14 End-to-End Tests

**Status:** possible for repository behavior; launch-time skill discovery
remains a human/client checkpoint (per the [test plan](../sprint-plans/test-plan.md)).

## test_repository_full_guard_suite
Run `bash tools/run-guards.sh --determinism` from the migrated repository and
require all suites green with identical normalized evidence.

- **Local (Windows git-bash) result:** **9/10 suites PASS, all `determinism:
  ok`**. The `selftest` suite fails only at the `runtime-helpers` CRLF
  assertions under Windows GNU awk 5.4.0 (`\r`-stripping); root-caused and
  backlogged as T-121. Every other suite — including the newly registered
  `adapter-semantics`, `adapter-semantics-test`, and `operator-docs` — is green
  and deterministic.
- **Authoritative result:** the Ubuntu + macOS CI matrix (`.github/workflows/ci.yml`)
  runs the identical entry point. The CI conclusion on the sprint head SHA is
  the authoritative confirmation and is recorded in
  [test-report.md](test-report.md) once the sprint branch is pushed.

## test_fresh_downstream_project
Initialize a fresh Book in an empty project and run a synthetic sprint with the
helper scripts. Exercised by `book-routing.test.sh` (tracked-scaffold init on an
empty fixture, full phase walk, idempotent re-scaffold) and the bundle
`install.sh` scripts. **PASS** (fixture-level E2E).

## test_migrated_downstream_project
Copy a legacy fixture, migrate it with one bundle, and resume — with no
translation or split-brain state. Exercised by `migrate-to-book.test.sh`
(lossless + idempotent migration, resume at the same phase, split-brain refusal)
combined with `check-bundle-sync.sh` (any bundle's helpers are byte-identical,
so "migrate with one, resume with another" reduces to reading the same Book).
**PASS** (fixture-level E2E).

## Human checkpoint — Codex skill discovery
After installing/reloading the revised Codex skill in a **new** session, a human
must verify that `$sprint-loops` appears exactly once, activates on a direct
sprint/Book-resume request, and does **not** activate merely because unrelated
documentation exists. This is a launch-time client-discovery property that
cannot be self-verified in this environment. **Deferred to human verification.**

## Summary
- Repository-behavior E2E: green locally except the documented Windows-only
  `selftest` CRLF exception; CI (Ubuntu/macOS) is the authoritative full-green
  confirmation.
- Codex launch-time skill discovery: human checkpoint, deferred.
