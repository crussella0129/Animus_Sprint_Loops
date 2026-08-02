# Phase 06 — Loop

## Outcome

Reconcile realized and unrealized intent, preserve durable reasoning and
carry-forward work in the Book, validate it, and close the current sprint with
evidence.

## Inputs

From `<project-root>`, read:

- linked `docs/intents/INT-NNNN-*.md` chapters;
- the current sprint metadata, plans, completion entries, test report and
  critique, or failure report;
- `docs/work/tasks.md`, `docs/work/completed-tasks.md`, and optional
  `docs/work/confidence.txt`;
- the close and validation helpers under `<skill-root>/scripts/`.

Reconcile each advanced intent against its acceptance criteria and linked
completion, code, test, and documentation evidence. Move eligible intent to
`realized`; otherwise retain `active` or transition to `deferred` with a
reason. Append only actual transitions. Put durable rationale, alternatives,
consequences, and later changes in the stable intent, creating a distinct
intent for a distinct outcome. Add each new intent to `docs/SUMMARY.md` once;
that link is navigation, not semantic state.

Append executable carry-forward work to `docs/work/tasks.md` as `(backlog)`
entries with intent IDs. If the confidence throttle is tracked, run from
`<project-root>`:

```bash
bash "<skill-root>/scripts/update-confidence.sh" <pass|patched|failed>
```

Commit coherent remaining Book changes with an explicit scoped boundary, then
validate before close:

```bash
bash "<skill-root>/scripts/check-book.sh"
```

Unless the sprint is already aborted, close it with exactly one evidence line:

```bash
bash "<skill-root>/scripts/close-sprint.sh" <success|failed> "<one-line completion evidence>"
```

Use `success` only for a test report with an accepted final critique; use
`failed` only with failure-report provenance.

## Authority

Intent chapters remain semantic authority; work ledgers record executable
state; sprint records remain provenance; navigation remains a view. Loop may
make local, scoped Book commits required to close the requested sprint. It
does not grant remote authority or permission changes; the adapter-level
boundary in `SKILL.md` still applies.

## Exit evidence

- Every advanced intent has a justified state and valid evidence links.
- Durable reasoning and executable carry-forward work live in their canonical
  Book locations.
- Remaining Book changes are scoped and committed, and `check-book.sh` passes.
- `close-sprint.sh` records terminal status, timestamp, and completion
  evidence, or prior abort evidence is verified.
- Running `bash "<skill-root>/scripts/current-phase.sh"` from
  `<project-root>` reports `ready-for-next-sprint`.
