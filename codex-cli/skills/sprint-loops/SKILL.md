---
name: sprint-loops
description: Structured five-phase workflow (Research → Plan → Build → Test → Loop) for long-horizon coding tasks. Trigger when the user mentions sprint loops, starting a sprint, continuing a sprint, or when the project root contains a `sprints/` directory.
---

# Sprint Loops

Five-phase workflow for long-horizon agentic coding work.

## Routing

1. Run `bash scripts/current-phase.sh` from the project root.
2. Read the matching `phases/` file:
   - `uninitialized` or `ready-for-next-sprint` → `phases/01-init-sprint.md`
   - `research` → `phases/02-research-phase.md`
   - `plan` → `phases/03-plan-phase.md` (also invoke `/plan` slash command)
   - `build` → `phases/04-build-phase.md`
   - `test` → `phases/05-test-phase.md`
   - `loop` → `phases/06-loop-phase.md`
3. Execute. When the phase exit condition is met, re-route.

## Plan mode integration

When entering the Plan Phase, suggest the user run `/plan` for native Codex plan mode. The plan-phase file's job is to produce `build-plan.md` and `test-plan.md` — these are the planning artifacts that survive across turns.

## Approval mode guidance

- **Research, Plan, Loop** phases work fine with `--ask-for-approval on-request` (default).
- **Build Phase** benefits from `workspace-write` sandbox + `--ask-for-approval never` for batch task execution, since every task ends in a git commit that provides rollback.
- **Test Phase** can run with `workspace-write` + `on-request` for safety.

Never use `--yolo` or `--dangerously-bypass-approvals-and-sandbox` for sprint loops — the whole point of the system is auditable, recoverable iteration.

## State on disk

The filesystem IS the state machine. Persistent state lives in `sprints/` and `agent-tasks/`. Trust the disk; do not re-derive state from chat history.

## Subagent opportunity

When the Build Phase has multiple independent tasks (no shared dependencies in the build-plan's execution sequence), consider spawning subagents for parallelization. Each subagent handles one task and commits its own diff. The parent agent merges results and proceeds.

## Autonomous operation

When invoked for a multi-turn loop (e.g. via `codex exec` or when the user signals they're stepping away), default to working independently for the entire sprint:

- **Commit, push, and merge your own PRs without asking per step.** The per-task commit boundary already provides rollback; the sprint structure already provides review surfaces (research-report, plans, test-report, decisions ADR). Don't pause for confirmation on routine work.
- **Defer rather than block.** When a feature has a non-trivial dependency the plan didn't anticipate, ship the scoped piece, note the deferral in `sprint-meta.md` blockages or the PR body, and continue with the next executable task. Use `scripts/abort-sprint.sh` only for truly unrecoverable blockages.
- **Use `/plan` for the Plan Phase, then drop back to standard mode for Build/Test/Loop.** Plan Mode produces `build-plan.md` and `test-plan.md` without touching source files.
- **One PR per concept, numbered sequentially** (e.g. `v117`, `v118`) when the sprint is wrapped as a PR.

## Safety floor

Autonomy stops at the safety floor:

- **Don't weaken permission or security controls** to keep the loop moving. If a tool call is denied, surface the decline clearly and continue with what *is* permitted — never invoke `--yolo` or `--dangerously-bypass-approvals-and-sandbox`.
- **Don't skip pre-flight checks** documented in `phases/04-build-phase.md` even when running unattended. The project's sanity gate blocks the per-task commit — that's the design.
- **Never `--no-verify` or bypass hooks** unless the user explicitly opted in. Hook failures are signal; investigate, don't suppress.
- **Hard-to-reverse actions warrant a pause** even in autonomous mode: force-push to a base branch, dropping a DB table, deleting infra. Surface the intent and wait for confirmation.
