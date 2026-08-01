# Phase 01 — Initialize Sprint

## Outcome

Create or extend one tracked Book schema v2 and initialize the next numbered
sprint without creating legacy root authorities.

## Inputs

Invoke the installed bundle's `scripts/init-sprint.sh` helper with the
project root as its working directory. The harness adapter resolves the
installed bundle path.

The helper classifies existing state before writing. It refuses legacy-only and
split-brain layouts, preserves existing Book content and project
`.gitignore` entries, creates missing Book scaffolding, and chooses the next
`docs/sprints/sN/` number. Set `SPRINT_MODEL` before invoking it if the
model identifier is known.

The initialized metadata includes Sprint number, Book schema version, start
timestamp, model, `in-progress` status, Summary, Intents, and Completion
evidence fields.

## Authority

Initialization establishes containers and provenance only. It does not invent
project intent. Existing `docs/intents/` chapters remain semantic authority;
existing `docs/work/` ledgers remain execution state; existing sprint records
remain provenance. `docs/SUMMARY.md` receives stable navigation links only.

Do not hand-create parallel legacy state surfaces. Use the installed
`migrate-to-book.sh` helper when initialization diagnoses legacy state.

## Exit evidence

All of the following exist:

- `docs/.sprint-loop-book` declares schema version 2.
- `docs/README.md`, `docs/SUMMARY.md`, `docs/intents/`,
  `docs/work/`, and `docs/sprints/` exist.
- `docs/work/tasks.md`, `docs/work/completed-tasks.md`, and
  `docs/work/confidence.txt` exist without overwriting prior content.
- The new `docs/sprints/sN/` contains initialized research, plan, test, and
  metadata artifacts, and `SUMMARY.md` links its metadata.
- The installed `current-phase.sh` helper reports `research`.

When complete, read `phases/02-research-phase.md`.
