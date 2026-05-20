Finalized - DO NOT EDIT

# Sprint 0 Build Plan

## Schema Tree
- Sprint Goal: harden phase detection + add permanent self-test for the loop-sprint skill
  - Component A: phase-detection fix
    - T-001: correct build/test discrimination in the canonical `current-phase.sh`
  - Component B: regression coverage
    - T-002: add `scripts/selftest.sh` driving every phase transition with assertions
  - Component C: cross-bundle consistency
    - T-003: sync the updated `current-phase.sh` and new `selftest.sh` into both skill bundles

## Execution Sequence

### T-001: Add a "build not started" disambiguator to `current-phase.sh`
- **Touches:** `open-harnesses/scripts/current-phase.sh`
- **Depends on:** (none)
- **Success criterion:** With plans finalized and no tasks yet appended to
  `agent-tasks/agent-tasks.md` (the scenario captured in
  `sprints/s0/sprint-research/bug-trace.txt`), `current-phase.sh` prints `build`
  instead of `test`. All other transitions retain their current output.
- **Notes:** Insert a single additional check after the existing
  `grep -q "sprint $N" agent-tasks/agent-tasks.md` line: if no `sprint $N`
  entries exist in `completed-tasks.md` either, the Build Phase has not
  started — print `build`. Preserves the "filesystem IS the state machine"
  principle (uses an existing on-disk signal, adds no new state surface).

### T-002: Add `scripts/selftest.sh` that exercises every phase transition
- **Touches:** `open-harnesses/scripts/selftest.sh` (new file)
- **Depends on:** T-001
- **Success criterion:** A new executable shell script that creates a temp
  project, drives it through the 8 transitions (`uninitialized` → `research` →
  `plan` → `build` (not started) → `build` (in progress) → `test` → `loop` →
  `ready-for-next-sprint`), asserts `current-phase.sh` output at each step, and
  exits 0 on success / non-zero with a diff-style message on failure. Running
  `bash open-harnesses/scripts/selftest.sh` from the repo root exits 0.
- **Notes:** Each step must use only the public helper scripts (`init-sprint.sh`,
  `finalize-plan.sh`) or direct file writes that match the protocol's contract
  — no internal-only knowledge of `current-phase.sh`. The script self-cleans
  its temp dir on success and on failure.

### T-003: Sync the updated `current-phase.sh` and new `selftest.sh` into both skill bundles
- **Touches:** `claude-code/skills/loop-sprint/scripts/current-phase.sh`,
  `claude-code/skills/loop-sprint/scripts/selftest.sh`,
  `codex-cli/skills/sprint-loops/scripts/current-phase.sh`,
  `codex-cli/skills/sprint-loops/scripts/selftest.sh`
- **Depends on:** T-001, T-002
- **Success criterion:** `md5sum` of each of the two files is identical across
  `open-harnesses/scripts/`, `claude-code/skills/loop-sprint/scripts/`, and
  `codex-cli/skills/sprint-loops/scripts/`. Running each bundle's `selftest.sh`
  exits 0.
- **Notes:** This is a `cp` from the canonical source. Re-assert exec bits on
  the copies before the next git commit (`git update-index --chmod=+x`).
