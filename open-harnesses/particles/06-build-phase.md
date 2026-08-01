# Particle: Build Phase

```
"Read the locked docs/sprints/sN/sprint-plans/build-plan.md, linked intents, docs/work/tasks.md, and docs/work/completed-tasks.md. Queue only plan tasks that are neither queued nor already recorded completed, in dependency order using (sprint N) [intent: INT-NNNN]; consume from the top and run the project's sanity checks before every task boundary. Before implementing a task, move planned intent to active and append the actual transition; preserve already-active intent without no-op history, and return deferred intent through Plan. For each completed task: verify its EARS criteria; remove its exact queued entry; append one completion entry with intent link, timestamp, actual touched paths, and the exact Commit: PENDING evidence line; then invoke the installed bundle's scripts/commit-task.sh T-NNN <description> -- <explicit-path> [path...] helper from the project root, listing every modified intent, sprint-meta, implementation, test, and documentation path. It stages/commits only explicit paths plus the two Book ledgers, then records the first exact PENDING hash in a second evidence commit so the task commit remains reachable; unrelated dirt stays out. It does not move ledgers or edit intent. Resolve, re-scope, or abort every queued current-sprint blockage before exiting Build. When no current-sprint task remains, invoke current-phase.sh and require test."
```

Schemas: [`../schemas/agent-tasks.md`](../schemas/agent-tasks.md) and
[`../schemas/completed-tasks.md`](../schemas/completed-tasks.md).
Helpers: [`../scripts/commit-task.sh`](../scripts/commit-task.sh),
[`../scripts/abort-sprint.sh`](../scripts/abort-sprint.sh), and
[`../scripts/current-phase.sh`](../scripts/current-phase.sh).

---

Next particle: `07-test-phase.md`.
