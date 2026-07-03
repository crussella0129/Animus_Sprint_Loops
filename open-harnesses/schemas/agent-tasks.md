# Schema: `agent-tasks.md`

Lives at `agent-tasks/agent-tasks.md` — the **persistent** backlog, shared across all sprints. Append at the bottom, consume from the top.

```markdown
# Agent Tasks (Persistent Backlog)

- [ ] T-001 (sprint N): <description> — touches: <files>
- [ ] T-002 (sprint N): <description> — touches: <files>
- [ ] T-101 (backlog): <description> — touches: <files>
```

Two entry forms:

- **`(sprint N)`** — queued for sprint N's Build Phase; this is the form
  `current-phase.sh` routes on (its greps anchor to the literal `(sprint N)`).
- **`(backlog)`** — a sprint-unassigned carry-forward: work a sprint surfaced
  but deferred. Parked until some future Build Phase promotes it by rewriting
  the tag to `(sprint N)`. `(backlog)` entries never affect phase routing.
  Use `T-1xx` IDs to keep them visually distinct from in-sprint tasks.
