# Phase 06 — Loop

## Outcome

Reconcile realized and unrealized intent, preserve durable reasoning and
carry-forward work in the Book, validate it, and close the current sprint with
evidence.

## Inputs

From `<project-root>`, read:

- every intent linked by the current sprint;
- the sprint metadata, locked plans, completion entries, test report and
  critique, or failure report;
- `docs/work/tasks.md`, `docs/work/completed-tasks.md`, and optional
  `docs/work/confidence.txt`;
- the helpers beneath `${CLAUDE_SKILL_DIR}/scripts/`.

Reconcile each advanced intent against its acceptance criteria and linked
completion, code, test, and documentation evidence. Move an eligible intent to
`realized`; otherwise retain `active` or transition it to `deferred` with
a reason. Append only actual transitions.

Put durable rationale, alternatives, consequences, and later changes in the
stable intent. Create a distinct intent for a distinct desired outcome and add
it to `docs/SUMMARY.md` once; navigation is not semantic state. Append
executable carry-forward work to `docs/work/tasks.md` as `(backlog)` entries
with intent IDs.

If the Book tracks its confidence throttle, run:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/update-confidence.sh" <pass|patched|failed>
```

Commit coherent remaining Book changes with the repository's normal scoped
boundary, then validate from `<project-root>`:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/check-book.sh"
```

Unless the sprint is already aborted, close it with exactly one evidence line:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/close-sprint.sh" <success|failed> "<one-line completion evidence>"
```

Use `success` only when a test report and accepted final critique prove the
linked acceptance criteria. Use `failed` only with failure-report provenance.
If claimed realization evidence depends on visual, experiential, or otherwise
unverifiable judgment, surface the artifact for human verification instead of
marking the intent realized or closing successfully on that claim alone.

## Remote checkpoint

After the sprint is closed and the Book validates, open exactly one checkpoint —
the reversible boundary between `work` and the corpus:

- Run the installed bundle's `scripts/remote-adapter.sh open-pr` from the project
  root. Driven by the remote profile (`schemas/remote-profile.md`), it opens
  **one** `work -> base` PR/MR (e.g. `dev -> main`) via the declared provider,
  or — when the provider is `generic`/`local-only` or its CLI is absent — pushes
  `work` and prints the compare URL.
- It opens **at most one PR/MR per sprint**: a re-run detects the existing open
  one and does not open a second.
- **The skill does not merge.** Under `mergePolicy: human-approve` (the default)
  it leaves the PR/MR open and stops for a human to approve — merging to `base`
  is the human-verification checkpoint.
- **No per-sprint branch is ever created.** Sprints accumulate on `work`; after a
  merge to `base`, `scripts/sync-work-branch.sh` brings `base` back into `work`
  at the boundary so `work` inherits the accepted corpus state.

At contract version 3 and above the checkpoint is **refused while the sprint is
still open**, and its title is composed from the Book as `Sprint <N>: <Summary>`
rather than supplied as free text. A title passed explicitly must match that
shape or it is refused. The opened URL is recorded in the sprint metadata
`Checkpoint` field and committed, so the Book is not left dirty behind the
checkpoint.

## Turn Contract

A sprint is one turn. Once a sprint is open, continue through its phases without
returning control, and stop only at one of four boundaries:

1. **Blocking product ambiguity** — the desired outcome is genuinely unclear and
   proceeding under any assumption would produce the wrong work.
2. **An unverifiable claim** — realization depends on visual, experiential, or
   otherwise human judgment; surface the artifact for a person instead of
   asserting it.
3. **An explicit abort** — the abort helper, with a one-line reason.
4. **The merge boundary** — the checkpoint is open and `mergePolicy` is
   `human-approve`, so a person approves the merge to base.

This contract is advisory: no helper runs when a turn simply ends, so it states
the intent rather than enforcing it. What is enforced is the evidence a
premature stop leaves behind. The checkpoint is refused while the sprint is
open, plan finalization and sprint close are refused while the Book carries
uncommitted state, and a task commit is refused from any branch that is not the
profile's work branch.

## Authority

Intent chapters remain semantic authority; work ledgers record executable
state; sprint records remain provenance; navigation remains a view. Loop may
make local, scoped Book changes and commits required to close the requested
sprint. The adapter-level permission and remote-action boundary in
`${CLAUDE_SKILL_DIR}/SKILL.md` still applies.

## Exit evidence

- The phase's exit artifacts are committed; the installed `scripts/check-tracked.sh` helper reports a clean Book.
- Every advanced intent has a justified state and valid evidence links.
- Durable reasoning and executable carry-forward work live in their canonical
  Book locations.
- Remaining Book changes are scoped and committed, and
  `${CLAUDE_SKILL_DIR}/scripts/check-book.sh` passes.
- `${CLAUDE_SKILL_DIR}/scripts/close-sprint.sh` records terminal status,
  timestamp, and completion evidence, or prior abort evidence is verified.
- Running
  `bash "${CLAUDE_SKILL_DIR}/scripts/current-phase.sh"` from
  `<project-root>` reports `ready-for-next-sprint`.

Return control to the session. If the user started recurring `/loop`, its next
invocation resumes through the router; this phase does not schedule itself.
