# Sprint 15 End-to-End Tests

**Status:** possible for substrate/guard behavior; the human-approved `dev→main`
merge is a human checkpoint (per the [test plan](../sprint-plans/test-plan.md)).

## test_repository_full_guard_suite
Run `bash tools/run-guards.sh --determinism` and require all suites green with
identical normalized evidence, including the five new substrate suites.

- **Local (Windows git-bash):** the five new suites (`remote-profile`,
  `check-substrate`, `deploy-substrate`, `remote-adapter`, `sync-work-branch`)
  plus `adapter-semantics`/`adapter-semantics-test` (47/47) and `bundle-sync`
  are green and deterministic. The one exception remains `selftest`'s chained
  `runtime-helpers` CRLF assertions — the pre-existing Windows GNU-awk
  `\r`-stripping quirk (backlog T-121), unrelated to this sprint's scripts.
- **Authoritative:** the Ubuntu + macOS CI matrix runs the identical entry
  point; its conclusion on the sprint-15 head SHA is recorded in
  [test-report.md](test-report.md) once the branch is pushed.

## test_repo_dogfood_substrate
`check-substrate.sh` on the retrofitted repository reports `substrate-complete`
(read-only). **PASS** (T-129).

## Human checkpoint — dev→main merge
The remote checkpoint opens exactly one `dev → main` PR/MR under
`mergePolicy: human-approve` and stops; a human reviews and merges. This
merge-policy boundary cannot be self-verified and is left to the operator.

## Summary
Substrate/guard E2E is green locally except the documented Windows-only
`selftest` CRLF exception; CI (Ubuntu/macOS) is the authoritative full-green
confirmation, and the `dev→main` merge is a human checkpoint.
