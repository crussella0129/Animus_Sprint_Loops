# Phase 04 — Build

The current sprint's `build-plan.md` is finalized and must not be edited. Read it
as authoritative input.

Open `agent-tasks/agent-tasks.md`. Append each task from the build-plan's
execution sequence to the bottom in the order given, preserving task IDs and
descriptions (see `schemas/agent-tasks.md`). Tasks are consumed from the **top**
of `agent-tasks.md` — never reorder them based on preference.

Execute tasks in order. Deviate only when a task is genuinely blocked by a missing
dependency the plan did not anticipate; in that case, leave the blocking task in
place, skip to the next executable task, and note the blockage in `sprint-meta.md`
under a `blockages` section.

If a blockage proves unrecoverable mid-sprint (an external dependency disappears,
scope is invalidated, the user changes their mind), run:

```bash
bash scripts/abort-sprint.sh "<one-line reason>"
```

It sets `sprint-meta.md` Exit status to `aborted`, records the end timestamp,
appends an `## Abort note` section, and commits the close-out. The next sprint
begins fresh — an aborted sprint, unlike a failed one, does **not** become the
next sprint's primary research input.

For every task you complete:

1. Verify the success criterion is met.
2. Delete the task entry from `agent-tasks.md`.
3. Append it to `completed-tasks.md` with a completion timestamp and the file
   paths actually modified (see `schemas/completed-tasks.md`).
4. Create a commit boundary:

   ```bash
   bash scripts/commit-task.sh T-XXX "<description>"
   ```

When all tasks in the current sprint's build-plan are either completed or
documented as blocked, **read `phases/05-test-phase.md`.**
