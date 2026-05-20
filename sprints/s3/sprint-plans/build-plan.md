Finalized - DO NOT EDIT

# Sprint 3 Build Plan

## Schema Tree
- Sprint Goal: fix back-fill correctness + bake autonomy/workflow patterns into the skill, sync across all bundles
  - Component A: back-fill correctness
    - T-001: anchor the `PENDING` regex and capture the post-amend hash in `commit-task.sh`; selftest step 11 guards both regressions
  - Component B: autonomy + workflow patterns
    - T-002: bake autonomy directives + workflow patterns into SKILL.md, the skill's phase files (04-build, 05-test, 06-loop), and the open-harnesses particles
  - Component C: cross-bundle sync
    - T-003: sync updated `commit-task.sh` + `selftest.sh` + phase files to both skill bundles; verify md5/diff and 11-step selftest from each

## Execution Sequence

### T-001: Anchor PENDING regex + capture post-amend hash in `commit-task.sh`; selftest step 11
- **Touches:** `open-harnesses/scripts/commit-task.sh`, `open-harnesses/scripts/selftest.sh`
- **Depends on:** (none)
- **Success criterion:**
  - `commit-task.sh`'s back-fill block uses `grep -qE '^- \*\*Commit:\*\* PENDING$'` (line-anchored full-line match) for detection and `sed -i "0,/^- \*\*Commit:\*\* PENDING$/{s||- **Commit:** \\\`$HASH\\\`|}"` for substitution.
  - The hash is captured AFTER the first `git commit --amend --no-edit`, via `HASH=$(git log -1 --format=%h)`, followed by sed-fill and a SECOND `git commit --amend --no-edit`. The embedded hash equals the final HEAD's short SHA.
  - `selftest.sh` gains step 11: a temp git repo with `completed-tasks.md` containing a description text that literally includes the substring `Commit:** PENDING` PLUS a real anchored field on its own line; runs `commit-task.sh`; asserts (a) description's text is UNCHANGED, (b) the field line now has a backticked hash, (c) the embedded hash equals `git log -1 --format=%h`.
- **Notes:** The two-amend sequence is `commit -> amend (fold tree) -> capture HEAD -> sed -> add -> amend (fold backfill)`. If the file has no PENDING, no amends happen — back-compat preserved.

### T-002: Bake autonomy + workflow patterns into the skill and the open-harnesses particles
- **Touches:** `claude-code/skills/sprint-loop/SKILL.md`, `claude-code/skills/sprint-loop/phases/04-build-phase.md`, `claude-code/skills/sprint-loop/phases/05-test-phase.md`, `claude-code/skills/sprint-loop/phases/06-loop-phase.md`, `open-harnesses/particles/06-build-phase.md`, `open-harnesses/particles/07-test-phase.md`, `open-harnesses/particles/08-loop-phase.md`
- **Depends on:** (none)
- **Success criterion:**
  - SKILL.md body has two new H2 sections: "Autonomous operation" (work independently in multi-turn loops, commit/push without per-step confirmation, defer-over-block) and "Safety floor" (don't weaken permission/security controls, surface declines and continue).
  - `phases/04-build-phase.md` opens task execution with a Pre-flight bullet: `git fetch && git rebase origin/<base>` if working on a branch; run the project's sanity gate (e.g. `cargo fmt && cargo clippy -- -D warnings && cargo test`, `pytest`, `go test ./...`) before `commit-task.sh`. Defer-over-block guidance added next to the existing blockage paragraph.
  - `phases/05-test-phase.md` gains a "CI verify (GitHub Actions)" subsection: after `gh run watch`, always run `gh run list --branch <branch> --json status,conclusion` as a separate verification step.
  - `phases/06-loop-phase.md` gains an optional step about PR merge on green: `gh pr merge <n> --merge --delete-branch` then `git checkout <base> && git pull`, and on red: `gh run view <id> --log-failed` + fix on the same branch.
  - Each open-harnesses particle (06, 07, 08) gains a single matching sentence inside its existing quoted block, preserving the embedding-tight format.
- **Notes:** Keep the YAML `description:` line of SKILL.md unchanged (it's the discovery surface). New SKILL.md sections live in the body. The phase additions are advice, not new mandatory protocol — agents can skip if not applicable (e.g. no CI configured).

### T-003: Sync to both skill bundles
- **Touches:** `claude-code/skills/sprint-loop/scripts/{commit-task.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/scripts/{commit-task.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/SKILL.md` (the autonomy/safety H2 sections — name remains `sprint-loops`), `codex-cli/skills/sprint-loops/phases/{04-build-phase.md,05-test-phase.md,06-loop-phase.md}`
- **Depends on:** T-001, T-002
- **Success criterion:**
  - `md5sum` of `commit-task.sh` and `selftest.sh` matches across all 3 bundles.
  - `diff -q` of the four claude-code phase files vs the corresponding codex-cli phase files is empty for `04`, `05`, `06` (the three updated in T-002). `00` and `01-03` remain identical as before. Codex's SKILL.md gets the same Autonomous-operation + Safety-floor body sections (kept skill-name-agnostic so codex's `name: sprint-loops` stands).
  - Both bundles' `selftest.sh` exits 0 and reports `selftest: all 11 transitions matched`.
- **Notes:** Re-assert exec bits on the synced scripts (`git update-index --chmod=+x`). Add the two SKILL.md sections to codex's SKILL.md as a separate small edit (not a wholesale copy — codex SKILL.md has its own routing/approval-modes content already).
