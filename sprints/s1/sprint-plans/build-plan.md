Finalized - DO NOT EDIT

# Sprint 1 Build Plan

## Schema Tree
- Sprint Goal: close sprint-0 follow-ups (hash back-fill, abort path) + sync to all bundles
  - Component A: protocol bookkeeping automation
    - T-001: `commit-task.sh` back-fills the new commit hash into `completed-tasks.md`
  - Component B: abort path
    - T-002: add `scripts/abort-sprint.sh` + document `aborted` exit status in the relevant phase files
  - Component C: cross-bundle consistency
    - T-003: sync the changed and new scripts into both skill bundles; extend `selftest.sh` with an abort transition step

## Execution Sequence

### T-001: Back-fill the new commit's short hash into `completed-tasks.md`
- **Touches:** `open-harnesses/scripts/commit-task.sh`
- **Depends on:** (none)
- **Success criterion:** After `commit-task.sh <id> <desc>` runs, if
  `agent-tasks/completed-tasks.md` contained `Commit:** PENDING`, the first
  such occurrence is replaced with the new short hash in backticks and the
  edit is folded into the same commit via `git commit --amend --no-edit`. If
  no `PENDING` token is present, the script behaves exactly as today (no
  amend, no extra commit, no file modification). Verified in the Test Phase
  by both a positive and a negative test in a temp repo.
- **Notes:** Use `sed '0,/Commit:\*\* PENDING/{s/PENDING/`<HASH>`/}'` for
  first-occurrence replacement (GNU sed; same dialect already required by
  other helpers). Get the hash with `git rev-parse --short HEAD`. Guard the
  amend with `grep -q PENDING` so the script is a no-op for entries that
  don't opt in.

### T-002: Add `abort-sprint.sh` + document the abort path
- **Touches:** `open-harnesses/scripts/abort-sprint.sh` (new),
  `open-harnesses/particles/06-build-phase.md`,
  `open-harnesses/particles/08-loop-phase.md`
- **Depends on:** (none)
- **Success criterion:** A new executable script `abort-sprint.sh "<reason>"`
  sets `sprint-meta.md` Exit status to `aborted`, records the end timestamp,
  appends an `## Abort note` section with the reason, and commits with
  `sprint-N: aborted — <reason>`. After it runs, `current-phase.sh` reports
  `ready-for-next-sprint` (the existing exit-status regex already matches
  `aborted`). Both touched particle files acknowledge `aborted` as a
  legitimate exit status (Loop Phase: as an option for Exit status; Build
  Phase: as a one-liner pointing to the helper).
- **Notes:** Mirror the existing helper style. Reuse the `Exit status` sed
  pattern from `selftest.sh` step 08 (`/Exit status/s/in-progress/aborted/`)
  — proven to match the markdown formatting.

### T-003: Sync to both bundles + extend selftest with an abort transition
- **Touches:** `claude-code/skills/loop-sprint/scripts/{commit-task.sh,abort-sprint.sh,selftest.sh}`,
  `codex-cli/skills/sprint-loops/scripts/{commit-task.sh,abort-sprint.sh,selftest.sh}`,
  `open-harnesses/scripts/selftest.sh`,
  `claude-code/skills/loop-sprint/phases/{04-build-phase.md,06-loop-phase.md}`,
  `codex-cli/skills/sprint-loops/phases/{04-build-phase.md,06-loop-phase.md}`
- **Depends on:** T-001, T-002
- **Success criterion:** `md5sum` of `commit-task.sh`, `abort-sprint.sh`, and
  `selftest.sh` is identical across `open-harnesses/scripts/`,
  `claude-code/skills/loop-sprint/scripts/`, and
  `codex-cli/skills/sprint-loops/scripts/`. Both bundles' `selftest.sh` exits
  0 and now reports 9 transitions matched (8 from sprint 0 + the new abort
  step). The Build-Phase and Loop-Phase files in both bundles match their
  open-harnesses counterparts for the abort additions.
- **Notes:** Step 09 in the extended selftest: re-init a second sprint inside
  the same temp project, run `abort-sprint.sh "selftest abort"`, then assert
  `current-phase.sh` reports `ready-for-next-sprint`. Re-assert exec bits on
  `abort-sprint.sh` after the copies (`git update-index --chmod=+x`).
