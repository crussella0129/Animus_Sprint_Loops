# Sprint 18 Test Report

**Verdict: PASS with caveats.** Every acceptance criterion of
[INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) that this
sprint scoped has an executed, named test, and CI is green on both matrix legs.
One defect was found during Test and fixed; five critique concerns are recorded,
three of which become carry-forward work.

## Authoritative confirmation

| Field | Value |
|---|---|
| Tested head SHA | `aa9c440ca1487f0146a58d77ec437a922f010a2c` |
| Run | [33699363328](https://github.com/crussella0129/Animus_Sprint_Loops/actions/runs/33699363328) |
| Conclusion | **success** |
| `guards (ubuntu-latest)` | success |
| `guards (macos-latest)` | success |

CI and the local Test phase invoke the same entry point, so they cannot drift.
All 17 suites pass on CI, including `selftest`, which fails locally for the
Windows-only reason below.

## Local canonical run

`bash tools/run-guards.sh --determinism`: **16/17 PASS**, and **every suite
recorded `"determinism":"ok"`**.

The one local failure is `selftest`, on backlog defect **T-121** — Windows/MSYS2
GNU awk strips a trailing `\r`, so `finalize-plan.sh` misclassifies a CRLF plan.
Reproduced byte-identically from an unmodified `0f8f35d` checkout during Sprint
17; it does not reproduce on POSIX.

### A defect was found by the suite and fixed during Test

The first full run reported two failures. `deploy-substrate` was a real
regression from T-149: a fresh deploy creates its own branches and leaves `HEAD`
on `base`, so the new `substrate-misplaced` state made convergence fail its own
post-deploy verification and roll the entire deploy back. **Every fresh project
would have been undeployable.**

The fix preserves the rule that made the failure correct and separates the two
cases — a fresh deploy checks out the work branch after creating it; an existing
project positioned on base is refused before anything is written rather than
having its checkout moved. Rollback restores the original `HEAD` before deleting
created branches. Two fixtures added; the suite re-ran clean at 16/17.

## Intent acceptance criteria

| INT-0005 acceptance criterion | Evidence | Result |
|---|---|---|
| `open-pr` before close exits non-zero naming the phase, opens nothing | `test_checkpoint_refused_before_close` — one Book walked through five open phases | PASS |
| Title is exactly `Sprint <N>: <Summary>` with no `--title` | `test_checkpoint_title_composed_from_book` | PASS |
| A malformed supplied title is refused | `test_checkpoint_rejects_malformed_title`, `test_checkpoint_accepts_conforming_title` | PASS |
| An untracked or dirty exit artifact cannot close; the path is named | `test_tracked_*` (7), `test_finalize_refuses_dirty_book`, `test_close_refuses_dirty_book` | PASS (see C-002) |
| A task commit from the base branch is refused before staging | `test_commit_task_refuses_wrong_branch` | PASS |
| Re-running opens no second request; the URL is unchanged | `test_checkpoint_recorded_once`, `test_checkpoint_reopen_is_inert`, `test_pr_refuses_existing_checkpoint` | PASS |
| An un-converged Book is unaffected by every gate | `test_checkpoint_gates_inert_below_contract_3` plus contract-2 finalize and branch fixtures | PASS (see C-005) |

Earlier detection of a misplaced branch — not an acceptance criterion, but the
sprint's fourth gate — is covered by five `check-substrate` fixtures including
both precedence cases.

## Scope this sprint did not close

INT-0005 remains **`active`**, deliberately:

- **The local pre-commit hook** was scoped out during Research (F7) and is not
  built. `commit-task.sh`'s refusal already catches the observed failure at the
  first Build task; the hook would extend coverage to commits made outside the
  helpers.
- **The checkpoint path is not wired to `check-tracked.sh`** despite the
  chapter's Intent prose saying so (critique C-002). No acceptance criterion
  requires it and the exposure is nil, but the chapter and the code disagree.

Claiming this intent realized would misrepresent both.

## Caveats carried into Loop

- **C-001** — a sprint's integration coverage is scoped to its own intent, so a
  gate that changes a shared helper's observable output can break a consumer
  from an earlier intent with no local test to notice. Carry-forward.
- **C-002** — reconcile INT-0005's prose with its acceptance criteria for the
  checkpoint path. Carry-forward.
- **C-003** — T-121 has now aborted the local suite before this sprint's own
  fixtures for the second consecutive sprint. Flagged for prioritization.
- **C-004**, **C-005** — deferred with rationale, no follow-on work.

## Verdict

Pass. Final critique verdict: `proceed-with-caveats`.
