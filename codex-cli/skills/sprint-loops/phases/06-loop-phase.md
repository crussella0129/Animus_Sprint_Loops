# Phase 06 — Loop

1. **Finalize `sprint-meta.md`** for the current sprint: set the end timestamp
   (ISO 8601), record the token count if observable, and set the exit status to
   `success` if all tests passed, `failed` if a failure-report was written, or
   `aborted` if the sprint was already closed mid-flight via
   `scripts/abort-sprint.sh` (in that case Exit status and end timestamp are
   already set — verify and move on).
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
6. *(Optional — PR-wrapped sprints)* If this sprint was developed on a feature
   branch and a PR was opened:
   - **On CI green** (verified per `phases/05-test-phase.md`'s CI verify
     pattern): the merge is **gated on how you're running**:
     - *Interactive run, or explicit auto-merge opt-in:*
       `gh pr merge <n> --merge --delete-branch`, then sync local base:
       ```bash
       git checkout <base> && git pull
       ```
     - *Unattended run (e.g. `codex exec`):* **do NOT merge** — merging to a
       base branch + deleting the branch is hard-to-reverse and stays
       human-gated (see SKILL.md "Safety floor"). Leave the PR open at
       "ready for review" and proceed.
   - **On CI red**: `gh run view <id> --log-failed`, fix on the same branch,
     force-push, re-verify before merging.
   - **PR body via heredoc** (avoids escaping pain on multi-line bodies with
     code fences):
     ```bash
     gh pr create --title "..." --body "$(cat <<'EOF'
     ## Summary
     ...
     ## Test plan
     ...
     ## What's deferred
     ...
     EOF
     )"
     ```

Finally, return to the Initialize Sprint phase and begin sprint N+1: re-run
`scripts/current-phase.sh` (it will report `ready-for-next-sprint`) and read
`phases/01-init-sprint.md`.
