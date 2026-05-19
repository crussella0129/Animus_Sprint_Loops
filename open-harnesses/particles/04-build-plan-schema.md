# Particle: Build Plan Schema

```
"To compose the build-plan, decompose the sprint goal into a schema tree. The root is the sprint goal. Each child node is a critical component. Each leaf is an elementary task. A task is elementary if and only if it can be completed in a single tool-call loop without re-reading the plan — concretely: it touches at most one logical concern, has a single observable success criterion, and produces a single coherent diff. Do not decompose below this granularity. After the tree is complete, linearize it into an execution sequence honoring dependencies — a task may only follow tasks it depends on. For each linearized task, record: a stable task ID (e.g., T-001), a one-sentence description, the files it will touch, its dependencies (by task ID), its success criterion, and any execution notes. Write all of this to 'build-plan.md' following the schema below. Review for local correctness (each task is well-formed) and global correctness (the sequence as a whole accomplishes the sprint goal) before finalizing."
```

Output artifact schema: [`../schemas/build-plan.md`](../schemas/build-plan.md).

---

Next particle: `05-test-plan-schema.md`.
