---
name: sprint-loop
description: Structured five-phase workflow (Research → Plan → Build → Test → Loop) for long-horizon coding tasks. Use when the user runs /sprint-loop, asks to start a sprint, continue a sprint loop, run an iteration, work in numbered sprints, or invokes phrases like "sprint loop", "start a sprint", "continue the loop", or "next sprint". Also use when a project root contains a `sprints/` directory and the user asks to resume work.
---

# Sprint Loops

You are working in a Sprint Loop. Each sprint is a five-phase sequence with persistent state on disk.

## Routing

1. Run `scripts/current-phase.sh` to determine the active phase.
2. Read the corresponding file from `phases/`:
   - `uninitialized` → `phases/01-init-sprint.md`
   - `research` → `phases/02-research-phase.md`
   - `plan` → `phases/03-plan-phase.md`
   - `build` → `phases/04-build-phase.md`
   - `test` → `phases/05-test-phase.md`
   - `loop` → `phases/06-loop-phase.md`
   - `ready-for-next-sprint` → `phases/01-init-sprint.md`
3. Execute the instructions in that phase file. When the phase exit condition is met, re-run step 1.

## Authoritative inputs

- `phases/00-overview.md` — read first if this is your first interaction with the skill in this session.
- `schemas/` — read the relevant schema file when producing any artifact.
- The filesystem IS the state machine. Trust the disk.

## Plan mode

The Plan Phase uses Claude Code's plan-mode primitive as a hard constraint, not a soft instruction. On entering Plan Phase, the agent invokes `EnterPlanMode` (the mandatory first action — it blocks Edit/Write/Bash side effects), reasons through the plan synthesis while only reading the filesystem, then invokes `ExitPlanMode` with a two-section summary (Build plan / Test plan).

**The `ExitPlanMode` approval prompt is where "auto mode" is selected.** For an unattended run, choose the **auto-accept ("auto mode")** option at that prompt — that selection is the mechanism that carries Build/Test/Loop without per-step confirmation (it's what makes "leave it running" work). For an interactive run, approve normally. See `phases/03-plan-phase.md` for the exact protocol.

## Git discipline

Every completed task in the Build Phase ends with a git commit via `scripts/commit-task.sh`. Loop Phase verifies a clean working tree before incrementing the sprint number.

## Autonomous operation

Unattended operation is **two mechanisms working together**, both Claude-Code-specific:

1. **Auto mode (no per-step confirmation):** engaged by selecting **auto-accept** at the Plan Phase's `ExitPlanMode` prompt (see "Plan mode" above). This is what lets the Build/Test/Loop phases run without stopping for each edit/command.
2. **Recurrence (no per-sprint check-in):** launch the whole thing under the harness `/loop` skill — `/loop /sprint-loop continue`. Each time `/loop` re-fires, the agent re-runs `scripts/current-phase.sh` and resumes whatever phase the filesystem reports; when a sprint closes, the next re-fire begins the next sprint. The user starts and stops `/loop`.

Within that, work independently for the whole sprint:

- **Commit and push your own work without asking per step.** The per-task commit boundary provides rollback; the sprint structure (research-report, plans, critic `critique.md`, test-report, decisions ADR) provides the review surfaces. Don't pause on routine edits/commits/pushes.
- **Defer rather than block.** When a task's full scope hits an unanticipated dependency, ship the scoped piece, note the deferral, and continue. Use `scripts/abort-sprint.sh` only for truly unrecoverable blockages.
- **One PR per concept, numbered sequentially** (e.g. `v117`, `v118`) when the sprint is wrapped as a PR.
- **Bound long unattended runs.** An unbounded `/loop /sprint-loop continue` keeps opening new sprints — burning tokens and producing commits — until you interrupt it. For unattended runs prefer a bounded launch (e.g. `/loop 3 /sprint-loop continue`) and check the result, rather than letting it run open-ended.

## Safety floor

Autonomy stops at the safety floor:

- **Don't weaken permission or security controls** to keep the loop moving. If a tool call is denied, surface the decline clearly and continue with what *is* permitted — don't request the human auto-accept dangerous shell patterns, secrets, or escalations.
- **Don't skip pre-flight checks** documented in `phases/04-build-phase.md` even when running unattended. The four-check gate (or whatever the project's sanity gate is) blocks the per-task commit — that's the design.
- **Never `--no-verify` or bypass hooks** unless the user explicitly opted in. Hook failures are signal; investigate, don't suppress.
- **Hard-to-reverse actions warrant a pause** even in autonomous mode: force-push to a base branch, dropping a DB table, deleting infra. Surface the intent and wait for confirmation.
- **Auto-accept ≠ auto-merge.** Selecting auto-accept removes per-edit/per-command friction, NOT the gate on irreversible git operations. Under unattended auto mode the agent does **not** merge a PR to a base branch, force-push, or delete branches — it pushes the working branch, opens the PR, and stops at "ready for review" for a human. Auto-merge happens only in an interactive run or with an explicit auto-merge opt-in at launch. (The Loop Phase's PR-merge step is gated accordingly — see `phases/06-loop-phase.md`.)
