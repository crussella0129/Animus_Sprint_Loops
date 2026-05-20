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

The Plan Phase uses Claude Code's plan-mode primitive as a hard constraint, not a soft instruction. On entering Plan Phase, the agent invokes `EnterPlanMode` (which blocks Edit/Write/Bash side effects), reasons through the plan synthesis while only reading the filesystem, then invokes `ExitPlanMode` with a two-section summary (Build plan / Test plan) for user approval before dropping back to normal mode to write the two artifacts (`build-plan.md` and `test-plan.md`) to disk. See `phases/03-plan-phase.md` for the exact protocol.

## Git discipline

Every completed task in the Build Phase ends with a git commit via `scripts/commit-task.sh`. Loop Phase verifies a clean working tree before incrementing the sprint number.

## Autonomous operation

When invoked for a multi-turn loop (e.g. via `/loop /sprint-loop continue` or when the user signals they're stepping away), default to working independently for the entire sprint:

- **Commit, push, and merge your own PRs without asking per step.** The per-task commit boundary already provides rollback; the sprint structure already provides review surfaces (research-report, plans, test-report, decisions ADR). Don't pause for confirmation on routine work.
- **Defer rather than block.** When a feature has a non-trivial dependency the plan didn't anticipate, ship the scoped piece, note the deferral in `sprint-meta.md` blockages or the PR body, and continue with the next executable task. Use `scripts/abort-sprint.sh` only for truly unrecoverable blockages.
- **Use Plan Mode for the Plan Phase, then drop back to standard mode for Build/Test/Loop.** Plan Mode produces `build-plan.md` and `test-plan.md` without touching source files.
- **One PR per concept, numbered sequentially** (e.g. `v117`, `v118`) when the sprint is wrapped as a PR. Lets earlier work be referenced in later commit messages.

## Safety floor

Autonomy stops at the safety floor:

- **Don't weaken permission or security controls** to keep the loop moving. If a tool call is denied, surface the decline clearly and continue with what *is* permitted — don't request the human auto-accept dangerous shell patterns, secrets, or escalations.
- **Don't skip pre-flight checks** documented in `phases/04-build-phase.md` even when running unattended. The four-check gate (or whatever the project's sanity gate is) blocks the per-task commit — that's the design.
- **Never `--no-verify` or bypass hooks** unless the user explicitly opted in. Hook failures are signal; investigate, don't suppress.
- **Hard-to-reverse actions warrant a pause** even in autonomous mode: force-push to a base branch, dropping a DB table, deleting infra. Surface the intent and wait for confirmation.
