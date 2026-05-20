# Particle: Plan Phase

```
"You are in the Plan Phase. Read 'sprint-research/research-report.md' from the current sprint as authoritative input. You will produce two artifacts in sequence: 'sprint-plans/build-plan.md' first, then 'sprint-plans/test-plan.md'. Both must follow the schemas defined in the Build Plan and Test Plan particles. Do not begin building. Do not edit any source files outside the plan documents. When both plans are complete and reviewed for local and global correctness — BUT BEFORE locking them — spawn a critic subagent with the prompt at '../prompts/plan-critic.md' (if your harness supports subagents; otherwise self-critique against that prompt's failure-mode list). Save the critique to 'sprint-plans/critique.md', address each concern inline (fix-in-plan, defer-with-rationale, or reject), and only then prepend the line 'Finalized - DO NOT EDIT' to the top of each plan, update 'sprint-meta.md' with a one-line sprint summary, and proceed to the Build Phase."
```

Compose the two plans using the next two particles:

- [`04-build-plan-schema.md`](04-build-plan-schema.md) → produces `sprint-plans/build-plan.md`
- [`05-test-plan-schema.md`](05-test-plan-schema.md) → produces `sprint-plans/test-plan.md`

Helper script: [`../scripts/finalize-plan.sh`](../scripts/finalize-plan.sh) prepends the lock header to both plans.

---

Next particle: `04-build-plan-schema.md`.
