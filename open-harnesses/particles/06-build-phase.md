# Particle: Build Phase

```
"You are in the Build Phase. The current sprint's 'build-plan.md' is finalized and must not be edited. Read it as authoritative input. Open 'agent-tasks/agent-tasks.md'. Append each task from the build-plan's execution sequence to the bottom of 'agent-tasks.md' in the order given, preserving task IDs and descriptions. Tasks are consumed from the top of 'agent-tasks.md' — never reorder them based on preference. Execute tasks in order. Deviate only when a task is genuinely blocked by a missing dependency that the plan did not anticipate; in that case, leave the blocking task in place, skip to the next executable task, and note the blockage in 'sprint-meta.md' under a 'blockages' section. If a blockage proves unrecoverable mid-sprint (an external dependency disappears, the scope is invalidated, you change your mind, etc.), run 'scripts/abort-sprint.sh \"<reason>\"' instead — it marks the sprint aborted in 'sprint-meta.md', records the abort note, and closes the sprint with a commit so the next sprint can begin fresh. An aborted sprint, unlike a failed one, does NOT become the next sprint's primary research input. For every task you complete: verify the success criterion is met, delete the task entry from 'agent-tasks.md', and append it to 'completed-tasks.md' with a completion timestamp and the file paths actually modified. After every task completion, run 'git add -A && git commit -m \"sprint-N: T-XXX <description>\"' to create a commit boundary. When all tasks in the current sprint's build-plan are either completed or documented as blocked, proceed to the Test Phase."
```

Backlog schemas: [`../schemas/agent-tasks.md`](../schemas/agent-tasks.md), [`../schemas/completed-tasks.md`](../schemas/completed-tasks.md).
Helper script: [`../scripts/commit-task.sh`](../scripts/commit-task.sh) creates the per-task commit boundary.

---

Next particle: `07-test-phase.md`.
