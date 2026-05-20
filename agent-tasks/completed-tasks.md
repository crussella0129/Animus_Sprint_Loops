# Completed Tasks Log (Append-Only)

## T-001 (sprint 0)
- **Description:** Add "build not started" disambiguator to `current-phase.sh` so a finalized-plan sprint with no queued tasks reports `build` instead of `test`.
- **Completed:** 2026-05-19T21:55:00Z
- **Files modified:** `open-harnesses/scripts/current-phase.sh`
- **Commit:** `94f41eb`

## T-002 (sprint 0)
- **Description:** Add `scripts/selftest.sh` that drives every phase transition and asserts `current-phase.sh` output at each step. First run caught a bug in the test's own `sed` pattern (line failed to match the `**Exit status:**` markdown formatting); fixed in the same task.
- **Completed:** 2026-05-19T21:57:00Z
- **Files modified:** `open-harnesses/scripts/selftest.sh` (new)
- **Commit:** `453cd40`

## T-003 (sprint 0)
- **Description:** Sync the fixed `current-phase.sh` and the new `selftest.sh` into the claude-code/loop-sprint and codex-cli/sprint-loops bundles. Verified md5 identity across all three copies and ran both bundles' selftests (8/8 transitions pass each).
- **Completed:** 2026-05-19T21:59:00Z
- **Files modified:** `claude-code/skills/loop-sprint/scripts/{current-phase.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/scripts/{current-phase.sh,selftest.sh}`
- **Commit:** `8083b84`

## T-001 (sprint 1)
- **Description:** `commit-task.sh` now back-fills the new commit's short hash into the FIRST `Commit:** PENDING` line of `agent-tasks/completed-tasks.md` and folds the edit into the same commit via `git commit --amend --no-edit`. Positive-case sanity-tested in a temp repo: PENDING → `ff380ad`, exactly one commit recorded. Back-compat: no-op when no `PENDING` token present.
- **Completed:** 2026-05-20T04:00:00Z
- **Files modified:** `open-harnesses/scripts/commit-task.sh`
- **Commit:** `3ba16e4`

## T-002 (sprint 1)
- **Description:** Added `scripts/abort-sprint.sh` taking a one-line reason: sets `sprint-meta.md` Exit status to `aborted`, records the end timestamp, appends an `## Abort note` section, and commits `sprint-N: aborted — <reason>`. Updated open-harnesses particles `06-build-phase.md` and `08-loop-phase.md` to document the abort path and the `aborted` exit status.
- **Scope expansion:** Surfaced during Build that `current-phase.sh` only checked Exit status at the bottom (to distinguish `loop` from `ready-for-next-sprint`), so an `aborted` status set mid-sprint was masked by upstream filesystem checks (research-report empty → returned `research` instead of `ready-for-next-sprint`). Hoisted the exit-status check to the top of `current-phase.sh`; all 8 sprint-0 selftest transitions still pass (regression-clean), and abort now routes correctly. Files modified beyond the plan: `open-harnesses/scripts/current-phase.sh`.
- **Completed:** 2026-05-20T05:16:00Z
- **Files modified:** `open-harnesses/scripts/abort-sprint.sh` (new), `open-harnesses/scripts/current-phase.sh`, `open-harnesses/particles/06-build-phase.md`, `open-harnesses/particles/08-loop-phase.md`
- **Commit:** `df1c102`

## T-003 (sprint 1)
- **Description:** Extended `selftest.sh` with step 09 (init a second sprint, abort it via `abort-sprint.sh`, assert `current-phase.sh` reports `ready-for-next-sprint`); synced `commit-task.sh`, `abort-sprint.sh`, the hoisted `current-phase.sh`, and the new 9-step `selftest.sh` into both skill bundles; propagated the abort docs into both bundles' `phases/04-build-phase.md` and `phases/06-loop-phase.md`. Verified md5 identity across all 3 bundles for the 4 scripts, both bundles' selftests now report 9/9 transitions matched, and the touched phase files are byte-identical between claude-code and codex-cli.
- **Completed:** 2026-05-20T05:18:00Z
- **Files modified:** `claude-code/skills/loop-sprint/scripts/{commit-task.sh,abort-sprint.sh,current-phase.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/scripts/{commit-task.sh,abort-sprint.sh,current-phase.sh,selftest.sh}`, `open-harnesses/scripts/selftest.sh`, `claude-code/skills/loop-sprint/phases/{04-build-phase.md,06-loop-phase.md}`, `codex-cli/skills/sprint-loops/phases/{04-build-phase.md,06-loop-phase.md}`
- **Commit:** `83e0edf`
