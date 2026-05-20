# Commit-hash back-fill scheme (research artifact)

Today's `commit-task.sh` (verbatim):

```bash
N=$("$SCRIPT_DIR/current-sprint.sh")
git add -A
git commit -m "sprint-$N: $1 $2"
```

The agent writes a `completed-tasks.md` entry with `**Commit:** PENDING` (or
similar placeholder), runs `commit-task.sh`, then manually edits the entry to
replace `PENDING` with the new short hash. Sprint 0 has three such manual edits
visible in its git history.

## Proposed scheme

Standardize the placeholder as the literal token `PENDING` in the line
`- **Commit:** PENDING`. After `git commit`, `commit-task.sh`:

1. Captures the new short hash via `git rev-parse --short HEAD`.
2. Replaces the FIRST occurrence of `Commit:** PENDING` in
   `agent-tasks/completed-tasks.md` with `` Commit:** `<hash>` ``.
3. If the substitution changed the file, `git commit --amend --no-edit` to fold
   the back-fill into the same commit (still one commit per task).
4. If `PENDING` is not present, do nothing — back-compat with older entries and
   with anyone who chooses to skip the placeholder.

The "first occurrence" rule assumes the agent appends one entry per task in
order and runs `commit-task.sh` between each. Both are explicit Build-Phase
expectations in the protocol.

## Why amend, not separate commit

The protocol's contract is "one commit per task" (see particle
`06-build-phase.md` and SKILL.md git discipline). A trailing housekeeping
commit per task would double commit count and dilute git log. Amend keeps the
contract intact and the back-fill is part of the same logical change.

## Risk: history of past entries

Existing entries without `PENDING` (all sprint 0 entries, post-back-fill) are
untouched. The script is purely additive — it only acts when the agent opted
in by writing `PENDING`.
