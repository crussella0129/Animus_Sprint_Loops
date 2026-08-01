# Schema: `completed-tasks.md`

Lives at `docs/work/completed-tasks.md`. This append-only execution ledger
records completed work. It is realization evidence for intent chapters, not
semantic authority by itself.

```markdown
# Completed Tasks Log (Append-Only)

## T-001 (sprint N)
- **Description:** ...
- **Intent:** [INT-0001](../intents/INT-0001-short-title.md)
- **Completed:** YYYY-MM-DDTHH:MM:SSZ
- **Files modified:** path/to/file.rs
- **Commit:** PENDING
```

Each entry names at least one linked intent. Write the exact
`- **Commit:** PENDING` line immediately before invoking the installed
bundle's
`scripts/commit-task.sh T-001 "<description>" -- <explicit-path> [path...]`
helper with the project root as its working directory.

The helper stages and commits only the explicit task paths plus
`docs/work/tasks.md` and this completion ledger. It then replaces only the
first exact `PENDING` line with the task commit hash and records that ledger
change in a second evidence commit, keeping the named task commit reachable in
normal clones. Unrelated staged and working-tree changes remain outside the
boundary. The helper does not move the task, append this entry, or update the
intent chapter; the Build Phase owns those steps.
