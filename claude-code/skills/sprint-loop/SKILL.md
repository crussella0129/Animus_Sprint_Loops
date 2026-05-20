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

During the Plan Phase, engage plan mode and use maximum effort. The Plan Phase produces two artifacts (`build-plan.md` and `test-plan.md`); do not touch source files.

## Git discipline

Every completed task in the Build Phase ends with a git commit via `scripts/commit-task.sh`. Loop Phase verifies a clean working tree before incrementing the sprint number.
