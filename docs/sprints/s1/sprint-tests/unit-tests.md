# Sprint 1 — Unit Tests

All tests run in isolated `mktemp -d` projects with their own `git init`. The
bundles' own `selftest.sh` covers the eight phase transitions plus the new
abort transition (T-002 / T-003).

## T-001 unit tests
| Test | Method | Result |
|------|--------|--------|
| `test_backfill_replaces_pending` | Wrote `Commit:** PENDING` into `completed-tasks.md`, ran `commit-task.sh T-001 "test"`, asserted file contains a backtick-quoted short hash and exactly one `sprint-N` commit exists | **PASS** — `1 commit, amended in place` |
| `test_backfill_first_occurrence_only` | Wrote TWO `Commit:** PENDING` lines, ran `commit-task.sh` once, asserted exactly 1 was filled and 1 remained PENDING | **PASS** — `1 filled, 1 still PENDING` |
| `test_backfill_noop_without_pending` | Ran `commit-task.sh` in a project whose `completed-tasks.md` had no PENDING token; asserted md5 of `completed-tasks.md` was unchanged and exactly 1 commit exists (no amend) | **PASS** — md5 unchanged, 1 commit |

T-001 unit tests: **3/3**.

## T-002 unit tests
| Test | Method | Result |
|------|--------|--------|
| `test_abort_sets_status` | `init-sprint.sh` then `abort-sprint.sh "scope changed"`; assert `Exit status:** aborted` appears in `sprint-meta.md` | **PASS** |
| `test_abort_note_recorded` | Same setup; assert `## Abort note` and the reason string both appear in `sprint-meta.md` | **PASS** |
| `test_abort_routes_ready` | Same setup; assert `current-phase.sh` prints `ready-for-next-sprint` | **PASS** |
| `test_abort_commits_cleanly` | After abort, `git status --short` is empty | **PASS** |
| `test_abort_commit_message` | `git log -1 --format=%s` starts with `sprint-N: aborted —` | **PASS** |

T-002 unit tests: **5/5**.

## T-003 unit tests
| Test | Method | Result |
|------|--------|--------|
| `test_scripts_identical_across_bundles` (4 files) | `md5sum` of `commit-task.sh`, `abort-sprint.sh`, `current-phase.sh`, and `selftest.sh` across all 3 bundles | **PASS** — md5s match (`d64dcc46…`, `81dfa62d…`, `9d5ef9b2…`, `b7fd732e…`) |
| `test_phase_files_synced` (2 files) | `diff -q` of `phases/04-build-phase.md` and `phases/06-loop-phase.md` between the claude-code and codex-cli bundles | **PASS** — both byte-identical |
| `test_selftest_step_09_abort` (2 bundles) | Run each bundle's `selftest.sh`, assert exit 0 and step 09 PASS with `expected=ready-for-next-sprint got=ready-for-next-sprint` | **PASS** — both bundles report `selftest: all 9 transitions matched` |

T-003 unit tests: **8/8**.

**Totals: 16 passed / 0 failed / 16 total.**

## Sprint-1 regression
The sprint-0 selftest (8 transitions) continues to pass after the hoist of the
`current-phase.sh` Exit-status check that was added during T-002's scope
expansion. Verified during Build Phase before T-002 was committed and again as
part of the 9-transition selftest above.
