Finalized - DO NOT EDIT

# Sprint 7 Build Plan

## Schema Tree
- Sprint Goal: Claude auto mode = reliably engage plan mode + select auto-accept, driven by /loop, with merge-to-base kept human-gated
  - Component A: reliable plan-mode engagement + auto-accept selection
    - T-001: claude-code phases/03-plan-phase.md — EnterPlanMode mandatory first action; ExitPlanMode auto-accept selection for unattended
  - Component B: SKILL.md protocol + Loop-Phase safety gate
    - T-002: SKILL.md "Plan mode" + "Autonomous operation" (auto-accept, /loop launch, bounding recommendation, safety floor) AND phases/06-loop-phase.md — gate the PR-merge step on interactive-or-opt-in (resolves the auto-merge contradiction)
  - Component C: command + cross-bundle docs + particle merge-gate
    - T-003: commands/sprint-loop.md; open-harnesses particle 08 (recurrence note + merge-gate); codex 06-loop-phase.md merge-gate sync; claude README claude-specific note

## Execution Sequence

### T-001: Reliable plan-mode engagement + auto-accept selection
- **Touches:** `claude-code/skills/sprint-loop/phases/03-plan-phase.md`
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** an agent enters the Plan Phase in claude-code, **THEN** `03-plan-phase.md` **SHALL** state invoking `EnterPlanMode` is the mandatory, unambiguous first action.
  - **WHEN** the plan is presented at `ExitPlanMode` and the run is unattended, **THEN** `03-plan-phase.md` **SHALL** instruct selecting the **auto-accept ("auto mode")** option — that selection is what carries Build/Test/Loop without per-step confirmation.
  - **WHEN** the run is interactive, **THEN** the doc **SHALL** retain the normal review/approve path.

### T-002: SKILL.md auto-mode protocol + Loop-Phase merge gate
- **Touches:** `claude-code/skills/sprint-loop/SKILL.md`, `claude-code/skills/sprint-loop/phases/06-loop-phase.md`
- **Depends on:** T-001
- **Success criterion (EARS):**
  - **WHEN** an agent reads SKILL.md "Plan mode", **THEN** it **SHALL** state the ExitPlanMode approval is where auto mode (auto-accept) is selected for unattended runs.
  - **WHEN** an agent reads SKILL.md "Autonomous operation", **THEN** it **SHALL** document launching `/loop /sprint-loop continue`, and that on each re-fire the agent re-runs `current-phase.sh` and resumes the reported phase (rather than claiming a per-sprint cadence `/loop` may not honor). [C-002]
  - **WHEN** an agent reads the auto-mode text, **THEN** it **SHALL** recommend BOUNDING an unattended run (e.g. `/loop N /sprint-loop continue`) and warn that an unbounded loop keeps opening sprints (burning tokens) until the user interrupts. [C-003]
  - **WHEN** an agent reads the auto-mode text, **THEN** the **safety floor SHALL be reaffirmed**: no unattended merge-to-base, force-push, branch deletion, or destructive ops without explicit opt-in (push the branch + open the PR, leave the merge).
  - **WHEN** an agent reads `phases/06-loop-phase.md` step 6 (PR merge), **THEN** that step **SHALL** be gated: auto-merge/`--delete-branch` happens ONLY in interactive mode or with an explicit auto-merge opt-in; under unattended auto mode the agent stops at "PR opened, ready for review." [C-004 — the decisive fix]
- **Notes:** C-004 was a live contradiction — the safety floor in SKILL.md vs the unconditional merge in 06-loop-phase.md. Both files are now in scope and made consistent.

### T-003: Command doc + cross-bundle docs + particle/codex merge-gate sync
- **Touches:** `claude-code/commands/sprint-loop.md`, `open-harnesses/particles/08-loop-phase.md`, `codex-cli/skills/sprint-loops/phases/06-loop-phase.md`, `claude-code/README.md`
- **Depends on:** T-001, T-002
- **Success criterion (EARS):**
  - **WHEN** an agent reads `commands/sprint-loop.md`, **THEN** it **SHALL** document `/loop /sprint-loop continue` (auto-accept selected at the plan prompt) and recommend bounding the run.
  - **WHEN** an agent reads `open-harnesses/particles/08-loop-phase.md`, **THEN** its quoted block **SHALL** (a) note a recurring-invocation primitive (Claude `/loop`) can drive recurrence and (b) state the PR merge is human-gated unless auto-merge is explicitly opted into.
  - **WHEN** an agent reads `codex-cli/skills/sprint-loops/phases/06-loop-phase.md`, **THEN** its PR-merge step **SHALL** carry the same interactive-or-opt-in gate as the claude-code copy (kept consistent).
  - **WHEN** a reader reads `claude-code/README.md`, **THEN** it **SHALL** note auto mode (plan-mode auto-accept + `/loop`) is Claude-specific (Codex uses `codex exec`).
- **Notes (granularity, C-005 deferred):** this task spans three files in different bundles; kept as one task because they're all one-to-two-sentence cross-references + the shared merge-gate propagation — a cohesive "make the merge-gate + recurrence note consistent everywhere" unit. Recorded as an intentional deviation from strict one-file granularity.
