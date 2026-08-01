# Particle: Plan Phase

```
"Read the current research report and every intent linked under ## Intents Reviewed. The sprint must advance at least one INT-NNNN. Compose docs/sprints/sN/sprint-plans/build-plan.md and test-plan.md using the next two schema particles: every task links intent acceptance to measurable EARS clauses, and every EARS clause plus affected acceptance criterion maps to a named planned test. Planning may translate intent into work but may not silently redefine it. Move sprint-advanced proposed/deferred intents to planned, add plan/task Work evidence, and append only actual state transitions; preserve already-active intent. Run a read-only critic with the installed bundle's prompts/plan-critic.md, save docs/sprints/sN/sprint-plans/critique.md, and address every concern. Update sprint-meta.md Summary and Intents. Finally, invoke the installed bundle's scripts/finalize-plan.sh helper from the project root; it requires at least one linked Book intent. Do not prepend lock headers by hand or begin source work before both plans lock atomically."
```

Schemas: [`../schemas/build-plan.md`](../schemas/build-plan.md) and
[`../schemas/test-plan.md`](../schemas/test-plan.md).
Helper: [`../scripts/finalize-plan.sh`](../scripts/finalize-plan.sh).

---

Compose the plans with `04-build-plan-schema.md` and
`05-test-plan-schema.md`, then proceed to `06-build-phase.md` after lock.
