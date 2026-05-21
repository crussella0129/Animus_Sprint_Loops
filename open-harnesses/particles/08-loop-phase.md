# Particle: Loop Phase

```
"You are in the Loop Phase. First, update 'sprint-meta.md' for the current sprint: set the end timestamp (ISO 8601), record the token count if observable, and set the exit status to 'success' if all tests passed, 'failed' if a failure-report was written, or 'aborted' if the sprint was already closed mid-flight via 'abort-sprint.sh' (in which case Exit status and end timestamp are already set — verify and move on). Second, compact context: do NOT re-inject prior sprint research, plans, or completed-task logs into your working context unless they are explicitly needed for the next sprint's research. The persistent state lives on disk; trust it. Third, if any architectural decisions were made during this sprint that future sprints will need to understand, append a brief entry to 'decisions.md' at the project root following the ADR-lite schema. Fourth, verify the git working tree is clean — if any uncommitted changes remain, commit them with a 'sprint-N: cleanup' message. If the sprint was developed as a PR and CI is green (per the Test Phase's separate-step verification), the merge is human-gated: in an INTERACTIVE run (or with an explicit auto-merge opt-in) merge it with 'gh pr merge <n> --merge --delete-branch' and sync local base, but in an UNATTENDED run leave the PR open at 'ready for review' (merging to a base branch is hard-to-reverse and must not happen unattended); use a heredoc for the PR body to avoid escaping issues. A harness with a recurring-invocation primitive (e.g. Claude Code's '/loop') can drive sprint-to-sprint recurrence automatically — see the Claude Code bundle's SKILL.md 'Autonomous operation' for the auto-accept + /loop pattern. Finally, return to the Initialize Sprint particle and begin sprint N+1."
```

Output artifact schema: [`../schemas/decisions.md`](../schemas/decisions.md).
Helper script: [`../scripts/update-confidence.sh`](../scripts/update-confidence.sh) adjusts the optional confidence throttle.

---

Loop closed. Re-inject [`01-init-sprint.md`](01-init-sprint.md) for sprint N+1.
