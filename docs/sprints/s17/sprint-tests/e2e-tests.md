# Sprint 17 End-to-End Tests

- **Status:** possible
- **Tested head SHA:** `21deff426d216754902aee82a4ae14512df10fb2`

## `test_repository_self_converges` — PASS

The dogfood case: this repository is itself a Sprint Loops project, and its Book
was at contract version 1.

```text
$ check-substrate.sh
substrate-outdated:1->2                       (exit 1)

$ deploy-substrate.sh --check
pending: stamp substrate-version: 2 (currently 1)   (exit 1, wrote nothing)

$ deploy-substrate.sh
deploy-substrate: substrate-complete (provider=github base=main work=dev
                  mergePolicy=human-approve contract=2)                (exit 0)

$ check-substrate.sh
substrate-complete                            (exit 0)
```

Observed properties:

- The diff is exactly one added line — `docs/.sprint-loop-book` gained
  `substrate-version: 2` and nothing else changed (`git diff --stat`:
  `1 file changed, 1 insertion(+)`).
- Re-running convergence changed neither the working tree nor `HEAD`, and
  `--check` then reported `converged (no pending steps)` with exit 0.
- `current-phase.sh` reported `test` before and after — routing was unaffected
  by the substrate change, which is the backwards-compatibility property under
  test at real-project scale rather than fixture scale.

## `test_guard_suite_green` — 15/16 PASS, one pre-existing failure

`bash tools/run-guards.sh --determinism --out guards-report.ndjson`, the same
entry point CI uses. Confirmations are recorded in `guards-report.ndjson`.

| Suite | Status | Determinism |
|---|---|---|
| `selftest` | **FAIL** (pre-existing, see below) | ok |
| `merge-policy`, `merge-policy-test` | PASS | ok |
| `plugin-manifest`, `plugin-manifest-test` | PASS | ok |
| `bundle-sync`, `bundle-sync-test` | PASS | ok |
| `adapter-semantics`, `adapter-semantics-test` | PASS | ok |
| `operator-docs` | PASS | ok |
| `remote-profile` | PASS | ok |
| `check-substrate` | PASS | ok |
| `deploy-substrate` | PASS | ok |
| `remote-adapter` | PASS | ok |
| `sync-work-branch` | PASS | ok |
| `shellcheck` | PASS | ok |

**Every suite recorded `"determinism":"ok"`** — both runs produced identical
normalized evidence hashes and identical exit codes, including the failing one.
No suite was flagged nondeterministic.

`merge-policy` and `adapter-semantics` share an evidence hash because
`tools/check-merge-policy.sh` is a documented compatibility shim that `exec`s
`check-adapter-semantics.sh`; removing it is existing carry-forward work, not a
finding of this sprint.

### The `selftest` failure is backlog defect T-121, not this sprint

`selftest` fails inside `runtime-helpers.test.sh` with:

```text
runtime-helpers.test: FAIL: finalization did not preserve uniform CRLF in build-plan.md
```

Reproduced byte-identically from an unmodified checkout of `0f8f35d` (the
sprint-16 close, before any sprint-17 work) and from this sprint's head:

```text
=== selftest at 0f8f35d (before any sprint-17 work) ===
runtime-helpers.test: FAIL: finalization did not preserve uniform CRLF in build-plan.md
=== runtime-helpers.test.sh at 21deff4 ===
runtime-helpers.test: FAIL: finalization did not preserve uniform CRLF in build-plan.md
```

This is [T-121](../../../work/tasks.md), already queued as backlog: Windows/MSYS2
GNU awk strips a trailing `\r`, so `finalize-plan.sh`'s CRLF detection
misclassifies a CRLF plan as LF. It reproduces only under Windows git-bash and
passes on POSIX CI, which is why the CI conclusion below — not the local run —
is the authoritative confirmation for this sprint.

Because the suite aborts at that assertion, the four T-137 fixtures and the
T-141 legacy-close fixture that live downstream of it in `runtime-helpers.test.sh`
were additionally verified in focused harnesses driving the installed bundle;
all pass. They execute normally inside `selftest` on the CI matrix.

## `test_installed_bundle_parity` — deferred to the merge boundary

The installed Claude Code plugin bundle is a cache pinned to a commit
(`…/sprint-loops/sprint-loop/4acc1fd6e0b9/…`, the sprint-16 checkpoint merge on
`main`). It therefore *cannot* match this sprint's `claude-code/` tree until the
checkpoint merges and the operator runs `/plugin update sprint-loop`.

- **Verified now:** the installed bundle was byte-identical to `claude-code/`
  at the start of this sprint (`diff -rq` over `scripts/` and `phases/`), so the
  loop that ran this sprint was the loop the repository declared.
- **Unlocked by:** the Sprint 17 `dev → main` checkpoint plus a plugin reload.
  Recorded as carry-forward rather than claimed as passing — this is exactly the
  reload discipline the sprint's own README section documents.

## Authoritative CI conclusion

See `test-report.md` for the recorded run, conclusion, and per-leg results on
the `ubuntu-latest` / `macos-latest` matrix for head SHA `21deff4`.
