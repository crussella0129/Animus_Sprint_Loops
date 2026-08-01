# Phase 06 — Loop

1. **Reconcile intent.** For each intent advanced by the sprint, compare its
   acceptance criteria with completed task, code, test, and documentation
   evidence. On success, attach the required Markdown links and move eligible
   intents to `realized`; otherwise retain `active` or move to `deferred`
   with a reason. Append every state change to Transition history.
2. **Record durable reasoning.** Put architectural rationale, alternatives,
   consequences, and later changes in the relevant stable intent chapter. If
   the sprint discovered a distinct desired outcome, create a new intent and
   link it from `docs/SUMMARY.md`. Never create a separate active decision
   authority.
3. **Carry work forward.** Append deferred executable work to
   `docs/work/tasks.md` as `(backlog)` entries with
   `[intent: INT-NNNN]`. Do not leave actionable work only in retrospective
   prose.
4. **Update optional confidence.** Invoke the installed bundle's
   `scripts/update-confidence.sh <pass|patched|failed>` helper with the
   project root as its working directory when the Book tracks the confidence
   throttle.
5. **Validate the reconciled Book.** Commit coherent remaining intent, work,
   sprint, confidence, and evidence updates with the repository's normal
   scoped boundary. Invoke the installed bundle's `scripts/check-book.sh`
   helper from the project root and do not close while it reports an invalid
   Book.
6. **Close sprint provenance.** If the sprint was not already aborted, invoke
   the installed bundle's
   `scripts/close-sprint.sh <success|failed> "<one-line completion evidence>"`
   helper with the project root as its working directory.

   Use `success` only when `test-report.md` and a final `clean` or
   `proceed-with-caveats` critique prove the linked acceptance criteria. Use
   `failed` when `failure-report.md` records re-architecture evidence. The
   helper atomically records end timestamp, terminal status, and Completion
   evidence in `sprint-meta.md`, including migrated metadata that lacks a v2
   field. If already aborted, verify the helper-written status, end timestamp,
   and Abort note instead.
7. **Verify and compact.** Invoke the installed bundle's
   `scripts/current-phase.sh` helper from the project root and require
   `ready-for-next-sprint`. Do not re-inject closed research, plans, or
   completion logs unless the next sprint needs them. The Book remains on
   disk; the next Research Phase selects only relevant intent and provenance.
8. *(Optional — PR-wrapped sprints)* If this sprint was developed on a feature
   branch and a PR was opened:
   - **On CI green** (verified per `phases/05-test-phase.md`'s CI verify
     pattern): merging is **AI-verifiable, so it proceeds autonomously** when
     the consequence is known and reversible — `gh pr merge <n> --merge
     --delete-branch`, then `git checkout <base> && git pull`. **Exception —
     stop and surface (don't merge) when the merge's effect is unverifiable or
     undeterminable:** production deploy, public release, or an unknown blast
     radius.
   - **On CI red**: inspect the failed run, fix on the same branch, force-push,
     and re-verify before merging.
   - **Visual-review checkpoint:** if the sprint produced a visually
     inspectable artifact, surface it for human review rather than continuing
     silently.
   - Use a heredoc for multi-line PR bodies to avoid escaping problems.

Finally, return to Initialize Sprint: invoke the installed
`scripts/current-phase.sh` helper again, then read
`phases/01-init-sprint.md`.
