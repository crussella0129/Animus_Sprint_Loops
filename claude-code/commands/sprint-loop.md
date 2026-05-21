---
description: Sprint Loop control — start, continue, loop, or abort a sprint.
---

Invoke the sprint-loop skill. Arguments: $ARGUMENTS

If no arguments: run `scripts/current-phase.sh` and continue from wherever the project is.
If `start <goal>`: initialize a new sprint with the goal `$ARGUMENTS`.
If `loop`: jump to the Loop Phase.
If `abort`: mark current sprint as aborted in `sprint-meta.md` and close it out.

## Unattended / auto mode

The loop runs sprints **unattended and keeps going**, stopping only at
human-verification checkpoints — things AI can't verify (visual/UX inspection,
an irreversible-or-unknown-consequence action, genuine product ambiguity, an
unrecoverable failure). Everything it *can* verify (green CI, reversible
changes, known-reversible merges) it just does. Launch:

```
/loop /sprint-loop continue
```

Two things make it hands-off:
- **Auto mode (no per-step prompts):** at the Plan Phase's `ExitPlanMode`
  approval, select the **auto-accept** option — that carries Build/Test/Loop
  without per-action confirmation.
- **Recurrence (no per-sprint check-in):** `/loop` re-fires `/sprint-loop
  continue`; each re-fire resumes via `scripts/current-phase.sh`.

Runaway control is the per-task commit rollback + the checkpoint stops + your
ability to interrupt. *Optionally* cap the run with `/loop N /sprint-loop
continue` if you want a hard ceiling, but it's not required — the checkpoints
are the intended stopping points. See SKILL.md "The stop criterion" for the
full checkpoint list.
