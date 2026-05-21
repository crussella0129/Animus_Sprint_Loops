---
description: Sprint Loop control — start, continue, loop, or abort a sprint.
---

Invoke the sprint-loop skill. Arguments: $ARGUMENTS

If no arguments: run `scripts/current-phase.sh` and continue from wherever the project is.
If `start <goal>`: initialize a new sprint with the goal `$ARGUMENTS`.
If `loop`: jump to the Loop Phase.
If `abort`: mark current sprint as aborted in `sprint-meta.md` and close it out.

## Unattended / auto mode

To run sprints without checking in after each one, launch under the harness
`/loop` skill:

```
/loop 3 /sprint-loop continue
```

Two things make this hands-off:
- **Auto mode (no per-step prompts):** at the Plan Phase's `ExitPlanMode`
  approval, select the **auto-accept** option. That selection carries
  Build/Test/Loop without per-action confirmation.
- **Recurrence (no per-sprint check-in):** `/loop` re-fires `/sprint-loop
  continue`; each re-fire resumes via `scripts/current-phase.sh`.

**Bound it** (`/loop 3 …`, not open-ended) — an unbounded loop keeps opening
sprints until you interrupt. Auto mode does not auto-merge PRs to a base
branch; that stays human-gated (see SKILL.md "Safety floor").
