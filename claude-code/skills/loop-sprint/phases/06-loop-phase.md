# Phase 06 — Loop

1. **Finalize `sprint-meta.md`** for the current sprint: set the end timestamp
   (ISO 8601), record the token count if observable, and set the exit status to
   `success` if all tests passed or `failed` if a failure-report was written.
2. **Compact context.** Do NOT re-inject prior sprint research, plans, or
   completed-task logs into your working context unless they are explicitly needed
   for the next sprint's research. The persistent state lives on disk; trust it.
3. **Record decisions.** If any architectural decisions were made during this
   sprint that future sprints will need to understand, append a brief entry to
   `decisions.md` at the project root following the ADR-lite schema
   (`schemas/decisions.md`).
4. **Verify a clean tree.** Check the git working tree — if any uncommitted
   changes remain, commit them with a `sprint-N: cleanup` message.
5. *(Optional)* If you track the confidence throttle, update it now:
   `bash scripts/update-confidence.sh <pass|patched|failed>`.

Finally, return to the Initialize Sprint phase and begin sprint N+1: re-run
`scripts/current-phase.sh` (it will report `ready-for-next-sprint`) and read
`phases/01-init-sprint.md`.
