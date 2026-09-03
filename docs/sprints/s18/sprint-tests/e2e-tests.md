# Sprint 18 End-to-End Tests

- **Status:** possible

## `test_repository_converges_to_contract_3` — PASS

This repository upgraded its own substrate through the entrypoint Sprint 17
shipped, which is the second consecutive sprint to prove convergence against a
real project rather than a fixture:

```text
$ check-substrate.sh
substrate-outdated:2->3                            (exit 1)

$ deploy-substrate.sh --check
pending: stamp substrate-version: 3 (currently 2)  (exit 1, wrote nothing)

$ deploy-substrate.sh
deploy-substrate: substrate-complete (… contract=3)  (exit 0)

$ check-substrate.sh
substrate-complete                                 (exit 0)
```

The diff is one line. Immediately afterwards `check-tracked.sh` reported the
marker as uncommitted — this sprint's own gate catching this sprint's own
change, which is precisely the ordering constraint plan critique C-003
identified: the Loop order must be converge → commit → validate → close.

## `test_guard_suite_green` — 16/17 PASS

`bash tools/run-guards.sh --determinism`. **Every suite recorded
`"determinism":"ok"`** — both runs produced identical normalized evidence hashes
and identical exit codes.

| Suite | Status |
|---|---|
| `selftest` | **FAIL** — backlog defect T-121, unchanged from Sprint 17 |
| `check-tracked` *(new)* | PASS |
| `check-substrate`, `deploy-substrate`, `remote-adapter` | PASS |
| `plugin-manifest`, `plugin-manifest-test`, `bundle-sync`, `bundle-sync-test` | PASS |
| `adapter-semantics`, `adapter-semantics-test`, `merge-policy`, `merge-policy-test` | PASS |
| `operator-docs`, `remote-profile`, `sync-work-branch`, `shellcheck` | PASS |

### The suite caught a defect the sprint's own fixtures did not

The first full run reported **two** failures. `deploy-substrate` was a genuine
regression introduced by T-149, and it was severe: a fresh deploy creates its own
branches and leaves `HEAD` on `base`, so the new `substrate-misplaced` state made
convergence fail its own post-deploy verification and roll the entire deploy
back. **Every fresh project would have been undeployable**, and no fixture
written during this sprint would have caught it, because each task's fixtures
tested its own behavior in isolation.

The fix keeps the rule that made the failure correct — convergence writes, so it
must not run from the base branch — while separating the two cases: a fresh
deploy checks out the work branch after creating it, and an existing project
positioned on base is refused before anything is written rather than having its
checkout moved underneath the operator. Rollback now restores the original
`HEAD` before deleting created branches, because a checked-out branch cannot be
deleted. Two fixtures were added
(`test_deploy_leaves_fresh_project_on_work`, `test_converge_refuses_from_base_branch`),
and the suite re-ran clean at 16/17.

### The `selftest` failure is still T-121

```text
runtime-helpers.test: FAIL: finalization did not preserve uniform CRLF in build-plan.md
```

Unchanged from Sprint 17 and reproduced there byte-identically from an
unmodified `0f8f35d` checkout. Windows/MSYS2 GNU awk strips a trailing `\r`, so
`finalize-plan.sh`'s CRLF detection misclassifies a CRLF plan. It does not
reproduce on POSIX; the CI conclusion recorded in `test-report.md` is therefore
authoritative.

This is the **second consecutive sprint** in which T-121 has aborted the local
suite before the sprint's own fixtures in `runtime-helpers.test.sh` could run —
this time the five contract-3 gate fixtures for T-147 and T-148. They were
verified in a focused harness extracted verbatim from the suite file and run
against the installed bundle (5/5), and they execute in place on CI. The cost is
now recurring rather than incidental, which is recorded as a caveat.

## An unplanned confirmation of Sprint 17's ahead-refusal

With `main` checked out, the pre-merge bundle read this repository's contract-3
Book and reported `substrate-ahead:3->2` — Sprint 17's refusal working against a
genuinely newer Book rather than a fixture. It is recorded because it was
observed, not because it was planned.

It also means the live `substrate-misplaced` demonstration was **not** performed
against this repository: checking out `main` swaps the scripts to the pre-merge
bundle, so what ran was the old contract-2 check. The state is proven by fixture
(`test_substrate_misplaced_on_base_branch` plus both precedence tests), and
switching this repository's branches mid-sprint to stage a demonstration would
have been gratuitous risk for no additional evidence.

## `test_repository_checkpoint_is_gated`

This sprint's own checkpoint is opened through the newly gated adapter: refused
while the sprint was open, accepted once closed, and titled `Sprint 18: …`
composed from the Book with no `--title` supplied. Recorded in `test-report.md`
with the resulting URL, since it can only be performed after the close.
