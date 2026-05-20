# Phase 04 — Build

The current sprint's `build-plan.md` is finalized and must not be edited. Read it
as authoritative input.

Open `agent-tasks/agent-tasks.md`. Append each task from the build-plan's
execution sequence to the bottom in the order given, preserving task IDs and
descriptions (see `schemas/agent-tasks.md`). Tasks are consumed from the **top**
of `agent-tasks.md` — never reorder them based on preference.

## Pre-flight (before the first commit)

If this sprint is working on a feature branch (not directly on `main`), refresh
the base first so per-task commits land cleanly:

```bash
git fetch && git rebase origin/<base>      # e.g. origin/main
```

Run the project's sanity gate before each `commit-task.sh` — fail fast inside
the loop is cheaper than failing in CI. Examples:

- **Rust:** `cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test`
- **Python:** `ruff format --check && ruff check && pytest`
- **Go:** `gofmt -l . | (! grep .) && go vet ./... && go test ./...`
- **TypeScript:** `npm run lint && npm test`

Block the commit on any failure; fix and re-run before invoking
`commit-task.sh`. The protocol's commit-per-task contract assumes each commit
is independently green.

Execute tasks in order. Deviate only when a task is genuinely blocked by a missing
dependency the plan did not anticipate; in that case, leave the blocking task in
place, skip to the next executable task, and note the blockage in `sprint-meta.md`
under a `blockages` section.

**Defer rather than block.** When a task's full scope depends on something the
plan didn't anticipate (cross-component refactor, a missing library, an
upstream API change), prefer to ship the *scoped piece* — the part that's
self-contained and tested — and explicitly list the deferred work in the
blockage note and, if applicable, the PR body. Blocking the whole sprint for
one over-scoped task wastes the other tasks' value. Save abort for
unrecoverable blockages.

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
