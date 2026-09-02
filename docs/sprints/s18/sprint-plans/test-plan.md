Finalized - DO NOT EDIT

# Sprint 18 Test Plan

## Intent Traceability

| Intent | Acceptance criterion | Build task / EARS clause | Verification |
|--------|----------------------|--------------------------|--------------|
| [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) | `open-pr` before close exits non-zero naming the phase and opens nothing | T-150 / WHEN the router reports anything other than `ready-for-next-sprint`, THEN it SHALL exit non-zero and SHALL NOT invoke the provider | `test_checkpoint_refused_before_close` |
| [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) | With no title supplied the checkpoint is titled exactly `Sprint <N>: <Summary>` | T-150 / the composed-title clause | `test_checkpoint_title_composed_from_book` |
| [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) | A malformed supplied title is refused | T-150 / WHEN a `--title` does not match `^Sprint [0-9]+: .+` | `test_checkpoint_rejects_malformed_title` |
| [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) | An untracked or dirty exit artifact cannot close; the diagnostic names the path | T-146 / the untracked and modified clauses; T-147 / the finalize and close clauses | `test_tracked_reports_untracked`, `test_tracked_reports_modified`, `test_finalize_refuses_dirty_book`, `test_close_refuses_dirty_book` |
| [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) | A task commit from the base branch is refused before anything is staged | T-148 / the `commit-task.sh` clause | `test_commit_task_refuses_wrong_branch` |
| [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) | Re-running the checkpoint opens no second request and the recorded URL is unchanged | T-150 / the record-once clause | `test_pr_refuses_existing_checkpoint`, `test_checkpoint_recorded_once` |
| [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) | An un-converged Book is unaffected by all four gates | T-146 / the version clause; T-147, T-148, T-150 / each contract-version clause | `test_gates_inert_below_contract_3` |
| [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) | Earlier detection of a misplaced working branch | T-149 / the misplaced and precedence clauses | `test_substrate_misplaced_on_base_branch`, `test_substrate_partial_outranks_misplaced`, `test_substrate_misplaced_outranks_outdated` |
| [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) | The operator-facing statement of the contract exists | T-151 / the Turn Contract and Exit-evidence clauses | `test_turn_contract_present`, `test_exit_evidence_requires_commit`, `adapter-semantics`, `operator-docs` |

## Unit Tests

### T-146 unit tests
- **Intent:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- Location: new `scripts/check-tracked.test.sh`, registered as the `check-tracked` suite.
- `test_tracked_clean_book_passes`: fully committed Book → exit 0, no output on stderr.
- `test_tracked_reports_untracked`: a new uncommitted file under `docs/` → non-zero, stderr names that path.
- `test_tracked_reports_modified`: a tracked Book file modified in the working tree → non-zero, stderr names that path.
- `test_tracked_reports_every_offender`: two offending paths → both named in one run.
- `test_tracked_ignores_non_git`: Book with no `.git` → exit 0, silent.
- `test_bundle_version_is_0_18_0`: `bundle-version.sh` and `plugin.json` agree at `0.18.0` (via the existing `plugin-manifest` guard).
- `test_contract_3_sees_stamp_2_as_behind`: a Book stamped `2` read by this bundle → `book_substrate_version()` prints `2`, `BOOK_SUBSTRATE_CONTRACT_VERSION` is `3`, and `check-substrate.sh` reports `substrate-outdated:2->3`.

### T-147 unit tests
- **Intent:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- Location: `scripts/runtime-helpers.test.sh`, reusing `plan_fixture` and `init_fixture`.
- `test_finalize_refuses_dirty_book`: contract-3 fixture with an untracked Book file → `finalize-plan.sh` refuses, names the path, and both plans remain unlocked.
- `test_close_refuses_dirty_book`: contract-3 fixture at phase `loop` with a modified Book file → `close-sprint.sh` refuses and the sprint metadata hash is unchanged.
- `test_finalize_allows_clean_book`: the same fixture with everything committed → locks both plans.

### T-148 unit tests
- **Intent:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- Location: `scripts/runtime-helpers.test.sh`.
- `test_commit_task_refuses_wrong_branch`: contract-3 fixture checked out on `main` → `commit-task.sh` exits non-zero naming both branches, and `git diff --cached` is empty afterwards.
- `test_close_refuses_wrong_branch`: same condition → `close-sprint.sh` refuses with the metadata hash unchanged.
- `test_branch_guard_inert_without_profile`: fixture with no `docs/work/remote-profile.md` → `commit-task.sh` commits normally from any branch.

### T-149 unit tests
- **Intent:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- Location: `scripts/check-substrate.test.sh`, reusing `git_init_branches` / `make_book` / `make_profile` / `stamp`.
- `test_substrate_misplaced_on_base_branch`: complete, stamped, checked out on `main` → `substrate-misplaced:main->dev`, exit non-zero.
- `test_substrate_complete_on_work_branch`: the same fixture on `dev` → `substrate-complete`, exit 0.
- `test_substrate_partial_outranks_misplaced`: missing the work branch **and** misplaced → `substrate-partial:`.
- `test_substrate_misplaced_outranks_outdated`: unstamped **and** misplaced → `substrate-misplaced:`.
- `test_substrate_misplaced_is_readonly`: the working tree is byte-identical after the report.

### T-150 unit tests
- **Intent:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- Location: `scripts/remote-adapter.test.sh`. All five existing fixtures gain a closed-sprint Book and keep their original assertions.
- `test_checkpoint_refused_before_close`: a fixture at each of `research`, `plan`, `build`, `test`, and an open `loop` → non-zero, diagnostic names that phase, and `STUBLOG` is empty.
- `test_checkpoint_title_composed_from_book`: closed sprint with `Summary: Widget support` → the stub records `--title 'Sprint 7: Widget support'`.
- `test_checkpoint_refuses_placeholder_summary`: Summary left at the initialization placeholder → refused, diagnostic names the field, provider not invoked.
- `test_checkpoint_rejects_malformed_title`: `--title "checkpoint"` → refused, provider not invoked.
- `test_checkpoint_accepts_conforming_title`: `--title "Sprint 7: something else"` → accepted and passed through verbatim.
- `test_checkpoint_recorded_once`: after opening, the sprint metadata carries exactly one `Checkpoint` field; a second `open-pr` neither opens a request nor changes that field.
- `test_checkpoint_record_is_committed`: after opening, `check-tracked.sh` passes — the adapter committed its own Book write rather than leaving the tree dirty for the next sprint's gate to trip on.
- Preserved: `test_pr_opens_once`, `test_pr_refuses_existing_checkpoint`, `test_provider_fallback_generic`, `test_merge_policy_human_approve`, `test_head_override_rejected`.

### T-151 unit tests
- **Intent:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- Location: `tools/operator-docs.test.sh`.
- `test_turn_contract_present`: every adapter Loop surface names the four legal stop points and states that the contract is advisory.
- `test_exit_evidence_requires_commit`: phases 02, 04, 05, and 06 each state that their exit artifacts are committed.
- `adapter-semantics`, `operator-docs`: both guard suites exit 0 after the prose change.

## Integration Tests

### `test_gated_sprint_walk` — T-146 + T-147 + T-149 + T-150
- **Intents:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- One fixture project walked from `research` to `ready-for-next-sprint` at contract 3, asserting at each phase that `open-pr` is refused with that phase named, that a dirty Book blocks the plan lock and the close, and that once the sprint is closed on a clean Book from the work branch the checkpoint opens exactly once with a composed title.

### `test_gates_inert_below_contract_3` — backwards-compatibility regression
- **Intents:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md), [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- The same fixture stamped at contract 2: `open-pr` opens from mid-sprint, a dirty Book locks plans and closes, and a wrong-branch commit succeeds — exactly the pre-sprint behavior. This is the compatibility claim under test, and it is the reason the gates can ship without rerouting live projects.

### `test_checkpoint_gate_composition` — T-148 + T-150
- **Intents:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- A sprint closed from the work branch on a clean Book opens its checkpoint; the same sprint attempted from the base branch is refused at `close-sprint.sh` before the checkpoint path is ever reached, proving the guards compose in the intended order rather than each catching the same case.

## End-to-End Tests
- **Status:** possible
- `test_guard_suite_green`: `bash tools/run-guards.sh --determinism` — all suites PASS with matching normalized evidence hashes across both runs, including the new `check-tracked` suite. Record the tested head SHA and the authoritative CI conclusion.
- `test_repository_converges_to_contract_3`: this repository's own Book converges from contract 2 to 3 via `deploy-substrate.sh`, with a one-line marker diff and a byte-identical re-run.
- `test_repository_converges_before_close`: convergence to contract 3 modifies the marker, so the resulting change must be committed **before** `close-sprint.sh` runs — otherwise this sprint's own tracked-evidence gate refuses the close. The required Loop order is converge → commit → validate → close → checkpoint, and this sprint is the first run to exercise it against itself.
- `test_repository_checkpoint_is_gated`: this sprint's own checkpoint is opened through the newly gated adapter — refused while the sprint is open, accepted once closed, and titled `Sprint 18: <Summary>` with no `--title` supplied. The live proof of both the gate and the title rule.
