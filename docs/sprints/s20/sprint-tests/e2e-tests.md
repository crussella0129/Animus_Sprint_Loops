# Sprint 20 End-to-End Tests

- **Status:** possible

## `test_repository_converges_to_contract_4` — PASS

```text
$ check-substrate.sh
substrate-outdated:3->4                            (exit 1)

$ deploy-substrate.sh --check
pending: stamp substrate-version: 4 (currently 3)  (exit 1, wrote nothing)

$ deploy-substrate.sh
deploy-substrate: substrate-complete (… contract=4)  (exit 0)

$ check-substrate.sh
substrate-complete                                 (exit 0)
```

One-line marker diff; a second convergence changed neither the working tree nor
`HEAD`.

## `test_repository_workflow_untouched` — PASS

The live no-clobber case, on a project that would be actively harmed by a second
workflow. This repository has a hand-written `.github/workflows/ci.yml` that
runs the canonical guard suite on both legs of a matrix. After convergence:

- the workflow directory listing is unchanged — still exactly `ci.yml`;
- `ci.yml` is byte-identical;
- no `sprint-loops-ci.yml` was created.

A file-level create-if-absent check would have added a second workflow beside
it, and this repository would then have had two CI systems disagreeing about
the same push. The directory-level rule is what prevents that, and this is the
case that proves it on a real project rather than a fixture.

## `test_guard_suite_green` — a real regression, found and fixed

The first full run reported **17/19**, with two failures. Every suite recorded
`"determinism":"ok"`.

`check-tracked` was a **genuine regression introduced by this sprint**. A fixture
written in Sprint 18, `test_contract_3_sees_stamp_2_as_behind`, asserted the
bundle constant equalled the literal `3`. Raising the contract to 4 broke it —
and it failed for a reason that had nothing to do with the property it was
written to protect, which was "a Book stamped by an earlier bundle reads as
behind". It is now `test_older_stamp_reads_as_behind` and asserts the
*relationship* (`stamped < BOOK_SUBSTRATE_CONTRACT_VERSION`) rather than a
literal, so the next contract raise cannot break it.

A sweep for the same shape then found the defect **freshly reintroduced by this
sprint, one task later**: `test_converge_generates_ci_after_stamp` asserted
`substrate-version: 4` as a literal. It now reads the bundle constant. Sprint 17
established the convention of driving fixtures from the constant, and both
lapses show how easily it is dropped when writing a fixture that happens to be
true today.

The second failure is `selftest`, backlog defect **T-121** — Windows/MSYS2 GNU
awk strips a trailing `\r`, so `finalize-plan.sh` misclassifies a CRLF plan.
Reproduced byte-identically from an unmodified `0f8f35d` checkout during Sprint
17; it does not reproduce on POSIX. Fourth consecutive sprint. T-155 stands.

Both changed suites were re-verified individually after the fix:
`check-tracked` 8/8, and the four-bundle parity guard green.

### Suite composition after this sprint

| Suite | Status |
|---|---|
| `selftest` | **FAIL** — T-121, pre-existing and platform-specific |
| `detect-languages` *(new)* | PASS |
| `scaffold-ci` *(new)* | PASS |
| `check-tracked` | PASS after the regression fix |
| `deploy-substrate`, `check-substrate`, `remote-profile`, `remote-adapter` | PASS |
| `plugin-manifest`(+test), `bundle-sync`(+test) | PASS |
| `adapter-semantics`(+test), `merge-policy`(+test), `operator-docs` | PASS |
| `sync-work-branch`, `shellcheck` | PASS |

### Runtime

The runner now carries 19 suites and took roughly an hour under contention;
`deploy-substrate` alone is 659s, having grown to 31 fixtures each performing a
full convergence. This is the third sprint in which runtime has grown
materially, and T-163 already tracks it.

## Authoritative CI conclusion

Recorded in `test-report.md` with the tested head SHA and both matrix legs. CI
runs the same entry point, so the local and hosted suites cannot drift; it is
also where `selftest` runs to completion.
