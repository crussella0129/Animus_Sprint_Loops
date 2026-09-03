# Sprint 18 Unit Tests

Every EARS clause in the locked build plan maps to at least one named fixture.
Each gate is verified twice — once at contract 3 where it binds, once at
contract 2 where it must be inert.

## T-146 — contract 3 and the tracked-evidence helper
New `check-tracked` suite, 7/7.

| Test | Clause | Result |
|---|---|---|
| `test_tracked_clean_book_passes` | committed Book → exit 0 | PASS |
| `test_tracked_reports_untracked` | untracked Book file → non-zero, path named | PASS |
| `test_tracked_reports_modified` | modified tracked file → non-zero, path named | PASS |
| `test_tracked_reports_every_offender` | two offenders → both named in one run | PASS |
| `test_tracked_ignores_non_git` | no git repository → exit 0, silent | PASS |
| `test_tracked_ignores_non_book_changes` | change outside the Book → exit 0 | PASS |
| `test_contract_3_sees_stamp_2_as_behind` | a Sprint-17-era Book reads as behind, not current | PASS |

`plugin-manifest` confirms `bundle-version.sh` and `plugin.json` agree at
`0.18.0`; a partial change fails with a diagnostic naming both values.

## T-147 — committed-evidence gates
Fixtures in `runtime-helpers.test.sh`.

| Test | Clause | Result |
|---|---|---|
| `test_finalize_refuses_dirty_book` | untracked Book artifact → finalize refuses, names the path, both plans stay unlocked | PASS |
| `test_finalize_allows_clean_book` | committed Book → both plans lock | PASS |
| `test_close_refuses_dirty_book` | modified Book file → close refuses **and the sprint metadata hash is unchanged**, proving the check precedes the write | PASS |
| `test_gates_inert_below_contract_3` | the same dirty Book at contract 2 → locks, exactly as before this sprint | PASS |

## T-148 — work-branch guard

| Test | Clause | Result |
|---|---|---|
| `test_commit_task_refuses_wrong_branch` | on `main` → refuses naming both branches, and `git diff --cached` is empty afterwards | PASS |
| (same fixture, work branch) | on `dev` → commits and records the task path | PASS |
| `test_close_refuses_wrong_branch` | close from `main` → refuses with the metadata hash unchanged | PASS |
| `test_branch_guard_inert_without_profile` | no resolvable remote profile → commits normally from any branch | PASS |

## T-149 — `substrate-misplaced`
`check-substrate` suite, 17/17 — 12 pre-existing plus 5 added.

| Test | Clause | Result |
|---|---|---|
| `test_substrate_misplaced_on_base_branch` | complete but on `main` → `substrate-misplaced:main->dev`, exit non-zero | PASS |
| `test_substrate_complete_on_work_branch` | the same fixture on `dev` → `substrate-complete`, exit 0 | PASS |
| `test_substrate_partial_outranks_misplaced` | missing work branch **and** misplaced → `substrate-partial:` | PASS |
| `test_substrate_misplaced_outranks_outdated` | unstamped **and** misplaced → `substrate-misplaced:` | PASS |
| `test_substrate_misplaced_is_readonly` | the working tree is byte-identical after the report | PASS |

Four pre-existing complete-path fixtures needed an explicit checkout of the work
branch: the shared `git_init_branches` helper leaves `HEAD` on its scratch
branch, which the new state correctly reports as misplaced.

## T-150 — checkpoint gate, composed title, recorded checkpoint
`remote-adapter` suite, 14/14 — all five originals preserved plus nine added.

| Test | Clause | Result |
|---|---|---|
| `test_checkpoint_refused_before_close` | one Book walked through `research`, `plan`, `build`, `test`, and an open `loop`: refused at each with the phase named and the provider never invoked; accepted once closed, opening exactly one request | PASS |
| `test_checkpoint_title_composed_from_book` | no `--title` → `Sprint 0: Widget support` | PASS |
| `test_checkpoint_refuses_placeholder_summary` | Summary left at the initialization placeholder → refused, field named, provider not invoked | PASS |
| `test_checkpoint_rejects_malformed_title` | `--title "checkpoint"` → refused, provider not invoked | PASS |
| `test_checkpoint_accepts_conforming_title` | `--title "Sprint 0: something else"` → passed through verbatim | PASS |
| `test_checkpoint_recorded_once` / `test_checkpoint_reopen_is_inert` | exactly one `Checkpoint` field; a second run opens nothing and rewrites nothing | PASS |
| `test_checkpoint_record_is_committed` | after opening, `git status --porcelain -- docs` is empty | PASS |
| `test_checkpoint_gates_inert_below_contract_3` | at contract 2, a mid-sprint checkpoint opens with the old default title | PASS |
| Preserved: `test_pr_opens_once`, `test_pr_refuses_existing_checkpoint`, `test_provider_fallback_generic`, `test_merge_policy_human_approve`, `test_head_override_rejected` | original assertions unchanged; only their setup grew a Book | PASS |

**On plan critique C-005** (preserved fixtures asserted by name, not behavior):
each rewritten fixture's assertion lines are byte-identical to their pre-sprint
form. The only edits were to setup — `make_repo` now creates the Book before the
profile, and each fixture gained a `make_closed_book` call. No assertion was
weakened, removed, or made conditional.

## T-151 — Turn Contract and committed Exit evidence
`operator-docs` suite, 6/6.

| Test | Clause | Result |
|---|---|---|
| `test_turn_contract_present` | all four Loop surfaces name the Turn Contract, state that it is advisory, and name the abort and human-approve boundaries; the README documents the rules and `substrate-misplaced` | PASS |
| `test_exit_evidence_requires_commit` | phases 02, 04, 05, 06 in both byte-parity bundles reference `check-tracked.sh` | PASS |
| `adapter-semantics` | every adapter authority and runtime contract still holds after the prose change | PASS |
