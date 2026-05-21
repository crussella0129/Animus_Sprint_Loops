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

- **Commit, push, and merge AI-verifiable work without asking per step.** The per-task commit boundary provides rollback; the sprint structure (research-report, plans, critic `critique.md`, test-report, decisions ADR) provides the review surfaces. Don't pause on routine edits/commits/pushes — or on merging a green-CI PR whose effect is known-and-reversible.
- **Defer rather than block.** When a task's full scope hits an unanticipated dependency, ship the scoped piece, note the deferral, and continue. Use `scripts/abort-sprint.sh` only for truly unrecoverable blockages.
- **One PR per concept, numbered sequentially** (e.g. `v117`, `v118`) when the sprint is wrapped as a PR.

## The stop criterion: halt only for what AI cannot verify

The point of running unattended is to keep going. The loop runs to completion
and halts **only at a human-verification checkpoint** — something whose
correctness or safety the AI cannot itself confirm. It is NOT bounded by an
arbitrary sprint count. Runaway control is the per-task commit rollback, the
checkpoints below, and your ability to interrupt `/loop`; a count cap
(`/loop N /sprint-loop continue`) is an *optional* extra cap, not the
recommended posture.

**Stop and surface to the human at these four checkpoints:**

1. **Visual / UX / aesthetic inspection** — anything where "does this look/feel
   right" is the test: UI, layout, rendered output, copy tone. Launch the app
   or attach the artifact and stop for the human to look (see
   `phases/06-loop-phase.md`).
2. **Irreversible action whose safety tests/CI cannot verify — *or whose
   consequence the agent cannot determine*.** Force-push to a shared branch,
   dropping a DB table, deleting infra, a public release/deploy. **If you
   cannot tell whether an action is reversible or what its blast radius is,
   that uncertainty is itself the checkpoint — default to stop, not proceed.**
   ("Can't verify" includes "can't determine the consequence.")
3. **Genuine product / scope ambiguity** — two valid interpretations and you'd
   be guessing the intent. Ask, don't pick.
4. **Unrecoverable failure** — a failure needing human diagnosis (failure-report
   territory).

**Everything the AI *can* verify proceeds autonomously** — green tests/CI,
reversible diffs, and merging a green PR whose consequence is known and
reversible. The pre-flight sanity gate (`phases/04-build-phase.md`) and the
Plan/Test critics still run; those are AI-verifiable steps, not human stops.

## Safety floor (the non-negotiable subset of the stop criterion)

These hold even when the user has waved you on:

- **Don't weaken permission or security controls** to keep the loop moving. If a tool call is denied, surface the decline and continue with what *is* permitted — don't ask the human to auto-accept dangerous shell patterns, secrets, or escalations.
- **Don't skip the pre-flight sanity gate** (`phases/04-build-phase.md`) even unattended — it blocks the per-task commit by design.
- **Never `--no-verify` or bypass hooks** unless the user explicitly opted in.
- The category-2 checkpoints above (irreversible/unknown-consequence actions) are exactly the "human must approve what AI can't verify" cases — they stay human-gated regardless of auto-accept.
