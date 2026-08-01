# Schema: `tasks.md`

Lives at `docs/work/tasks.md`. This persistent execution ledger is subordinate
to the intent chapters: it says what work is queued, not why the project wants
that work. Append at the bottom and consume from the top.

```markdown
# Agent Tasks (Persistent Backlog)

- [ ] T-001 (sprint N) [intent: INT-0001]: <description> — touches: <files>
- [ ] T-002 (sprint N) [intent: INT-0001, INT-0002]: <description> — touches: <files>
- [ ] T-101 (backlog) [intent: INT-0003]: <description> — touches: <files>
```

Every task names at least one stable `INT-NNNN` chapter. The corresponding
chapter's Work evidence must contain a Markdown link whose label or target
identifies the task or its sprint plan.

- **`(sprint N)`** — queued for sprint N's Build Phase. This literal tag is
  what `current-phase.sh` uses for routing.
- **`(backlog)`** — sprint-unassigned carry-forward. It does not affect phase
  routing. Promote it by changing the tag to `(sprint N)` during a later Plan
  or Build Phase; preserve the intent reference.

Do not place rationale, acceptance criteria, or architectural decisions here.
Update the linked intent chapter instead.
