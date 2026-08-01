# Particle: Test Phase

```
"Read the locked build/test plans, linked intent acceptance criteria, and completed-task evidence. Execute and record unit, integration, and E2E results under docs/sprints/sN/sprint-tests/, using the project's canonical suite runner and confirmation records when available. Prove every EARS clause and every affected acceptance criterion. On the pass path, run the read-only installed-bundle prompts/test-critic.md review, save and address sprint-tests/critique.md, re-run it after evidence changes, and write test-report.md only after a final clean or proceed-with-caveats verdict. Add the report link to each verified intent's Test evidence without prematurely setting realized. If failure requires re-architecture, write docs/sprints/sN/failure-report.md naming affected intents, unmet criteria, root cause, evidence, and recommended state. Invoke the installed bundle's current-phase.sh helper from the project root: a block or malformed critique remains in test; accepted critique plus test-report routes to loop; a non-empty failure-report.md takes the failure route to loop."
```

Schemas: [`../schemas/test-report.md`](../schemas/test-report.md) and
[`../schemas/failure-report.md`](../schemas/failure-report.md).
Critic: [`../prompts/test-critic.md`](../prompts/test-critic.md).

---

Next particle: `08-loop-phase.md`.
