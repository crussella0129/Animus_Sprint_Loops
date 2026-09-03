# Sprint 19 End-to-End Tests

- **Status:** possible

## `test_reported_symptom_is_gone` — PASS

The defect that opened this sprint, reproduced against the fix. A throwaway
repository, a GitHub `origin`, and convergence run exactly as the Init contract
instructs — **with no arguments**:

```text
$ git init -b main && git remote add origin https://github.com/someone/some-project.git
$ deploy-substrate.sh
deploy-substrate: substrate-complete (provider=github base=main work=dev
                  mergePolicy=human-approve contract=3)

provider:               github          (was: local-only)
.github/dependabot.yml: scaffolded      (was: absent)
profile provenance:     Provider inferred as `github` from the origin remote
                        `https://github.com/someone/some-project.git`.
```

Before this sprint the same commands produced `provider: local-only`, no updater
config, and a checkpoint path that printed `local-only profile; no PR/MR opened`
and exited 0 — the silent failure behind the operator's report that the loop
"said it was working local."

## `test_repository_profile_unchanged` — PASS

The other half of the contract, on this repository:

```text
recorded provider: github
origin:            https://github.com/crussella0129/Animus_Sprint_Loops
$ deploy-substrate.sh --check
deploy-substrate: converged (no pending steps)     (exit 0)
```

No `provider-disagreement` line, because the recorded value and the origin
agree; the Book is byte-identical. A correct profile is one inference must
leave alone, and this is the live case of it.

## `test_guard_suite_green` — 16/17 PASS

`bash tools/run-guards.sh --determinism`. **All 17 suites recorded
`"determinism":"ok"`** — both runs produced identical normalized evidence hashes
and identical exit codes.

| Suite | Status |
|---|---|
| `selftest` | **FAIL** — backlog defect T-121, unchanged since Sprint 17 |
| `deploy-substrate` | PASS — the sprint's primary surface, 24 fixtures |
| `check-substrate`, `check-tracked`, `remote-profile`, `remote-adapter` | PASS |
| `plugin-manifest`, `plugin-manifest-test`, `bundle-sync`, `bundle-sync-test` | PASS |
| `adapter-semantics`, `adapter-semantics-test`, `merge-policy`, `merge-policy-test` | PASS |
| `operator-docs`, `sync-work-branch`, `shellcheck` | PASS |

### T-121, for the third consecutive sprint

```text
runtime-helpers.test: FAIL: finalization did not preserve uniform CRLF in build-plan.md
```

Windows/MSYS2 GNU awk strips a trailing `\r`, so `finalize-plan.sh` misclassifies
a CRLF plan. Reproduced byte-identically from an unmodified `0f8f35d` checkout
during Sprint 17; it does not reproduce on POSIX. Unlike Sprints 17 and 18, this
sprint added no fixtures downstream of the abort point, so nothing of its own
needed a focused-harness workaround — but the suite is still red locally, and the
CI conclusion below remains the authoritative confirmation. T-155 already flags
it for prioritization.

### Suite wall time

Total runtime roughly tripled against Sprint 18's run of the same suites —
`merge-policy-test` 1490s against 542s, `bundle-sync-test` 619s against 236s.
That is machine contention from concurrent fixture runs during Build, not a code
change, but it is the concrete form of critique C-004: the runner is long enough
that a loaded machine makes it painful, which is how leaning on CI becomes
habitual.

## Authoritative CI conclusion

Recorded in `test-report.md` with the tested head SHA and both matrix legs.
