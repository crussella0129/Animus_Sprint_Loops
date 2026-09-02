# Phase 04 — Build

## Outcome

Implement each locked task as a coherent, verified commit while keeping Book
execution state and the linked intent lifecycle synchronized.

## Inputs

Read:

- the finalized `docs/sprints/sN/sprint-plans/build-plan.md`;
- the finalized test plan for expected verification;
- `docs/work/tasks.md` and `docs/work/completed-tasks.md`;
- every intent chapter linked by the sprint metadata and tasks.

Queue each build-plan task in plan order using the
`[intent: INT-NNNN]` form from `schemas/agent-tasks.md`, adding only tasks
that are neither already queued nor recorded in `completed-tasks.md` when
resuming. Consume sprint tasks from the top. Run the project's formatter,
linter, and affected tests before each commit boundary.

Before implementing a task, move its `planned` linked intent to `active` and
append that actual state change to Transition history. Preserve an already
`active` intent without adding a duplicate history entry. A `deferred` intent
must return through Plan before execution. Preserve Work evidence throughout.

For every completed task:

1. Verify its EARS success criteria.
2. Remove its exact entry from `docs/work/tasks.md`.
3. Append a `docs/work/completed-tasks.md` entry with intent link, timestamp,
   actual touched paths, and exact `- **Commit:** PENDING`.
4. Invoke the installed bundle's
   `scripts/commit-task.sh T-XXX "<description>" -- <explicit-path> [path...]`
   helper with the project root as its working directory. List every modified
   task-owned path after `--`, including intent, sprint metadata,
   implementation, test, and documentation files.

`commit-task.sh` stages and commits only the explicit paths plus the two Book
ledgers, then backfills only the first exact `PENDING` line in a second small
evidence commit. This keeps the recorded task commit reachable in normal clones
while leaving unrelated staged and working-tree changes outside the boundary.
It does not move ledger entries or edit intent chapters.

For a recoverable dependency gap, leave the task queued, record a Blockages
entry in sprint metadata, and work the next executable planned task. Before
leaving Build, resolve the blockage, re-scope it through an unlocked future
plan/backlog, or abort; a queued current-sprint task keeps routing in Build.
For an unrecoverable mid-sprint invalidation, invoke the installed bundle's
`scripts/abort-sprint.sh "<one-line reason>"` helper with the project root as
its working directory.

## Authority

The locked build plan controls sprint execution order, but linked intent
chapters still control meaning and acceptance boundaries. The work ledgers
record queued/completed execution. Code and commits are realization evidence;
they do not silently redefine intent. If implementation exposes a semantic
change, stop, revise the intent explicitly, and record its history before
continuing.

## Exit evidence

- No `(sprint N)` task remains in `docs/work/tasks.md`.
- Every completed task has one append-only completion entry, intent link,
  timestamp, touched paths, and resolvable commit evidence.
- Linked intents are `active` (or explicitly `deferred` with transition
  history) and retain valid Work evidence.
- Project sanity checks pass at each completed task boundary.
- The phase's exit artifacts are committed; the installed `scripts/check-tracked.sh` helper reports a clean Book.
- The installed `current-phase.sh` helper reports `test`.

When complete, read `phases/05-test-phase.md`.
