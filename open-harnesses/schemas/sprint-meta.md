# Schema: `sprint-meta.md`

Lives at `docs/sprints/sN/sprint-meta.md`. It is sprint provenance and a
phase-routing record; it does not redefine intent.

```markdown
# Sprint N Meta

- **Sprint number:** N
- **Book schema version:** 2
- **Start timestamp:** YYYY-MM-DDTHH:MM:SSZ
- **End timestamp:** (filled at Loop Phase)
- **Model:** <model identifier>
- **Exit status:** in-progress
- **Token count:** (filled at Loop Phase if observable)
- **Summary:** (one-line sprint goal, filled after Plan Phase)
- **Intents:** [INT-0001](../../intents/INT-0001-short-title.md)
- **Completion evidence:** (filled at Loop Phase)

## Blockages
(Optional. Name the affected task and intent, impact, and disposition.)
```

Legal Exit status values are `in-progress`, `success`, `failed`, and
`aborted`. Close an in-progress sprint by invoking the installed bundle's
`scripts/close-sprint.sh <success|failed> "<one-line completion evidence>"`
helper with the project root as its working directory.

The helper sets the end timestamp, status, and Completion evidence atomically
and can append missing anchored fields in migrated metadata. Use
`abort-sprint.sh "<one-line reason>"` for an unrecoverable mid-sprint abort.
Do not hand-edit a closed status.
