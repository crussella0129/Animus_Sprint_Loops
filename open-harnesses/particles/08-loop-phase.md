# Particle: Loop Phase

```
"You are in the Loop Phase. First, update 'sprint-meta.md' for the current sprint: set the end timestamp (ISO 8601), record the token count if observable, and set the exit status to 'success' if all tests passed or 'failed' if a failure-report was written. Second, compact context: do NOT re-inject prior sprint research, plans, or completed-task logs into your working context unless they are explicitly needed for the next sprint's research. The persistent state lives on disk; trust it. Third, if any architectural decisions were made during this sprint that future sprints will need to understand, append a brief entry to 'decisions.md' at the project root following the ADR-lite schema. Fourth, verify the git working tree is clean — if any uncommitted changes remain, commit them with a 'sprint-N: cleanup' message. Finally, return to the Initialize Sprint particle and begin sprint N+1."
```

Output artifact schema: [`../schemas/decisions.md`](../schemas/decisions.md).
Helper script: [`../scripts/update-confidence.sh`](../scripts/update-confidence.sh) adjusts the optional confidence throttle.

---

Loop closed. Re-inject [`01-init-sprint.md`](01-init-sprint.md) for sprint N+1.
