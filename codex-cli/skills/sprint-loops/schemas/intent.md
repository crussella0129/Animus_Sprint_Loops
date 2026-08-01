# Schema: intent chapter

Intent chapters live at `docs/intents/INT-NNNN-<slug>.md`. They are the Book's
stable semantic authority: one durable statement of project intent spanning
planned and realized work. `docs/SUMMARY.md` is navigation only.

```markdown
# INT-0001 — Short title

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0001
- **State:** proposed
- **Work evidence:** none
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** none
- **Documentation evidence:** none

## Intent
<desired outcome and boundaries>

## Acceptance criteria
<observable conditions that prove the intent>

## Rationale
<why this intent exists>

## Alternatives
<options considered and why they were not selected>

## Consequences
<accepted costs, constraints, and follow-on effects>

## Transition history
- YYYY-MM-DD: created as `proposed`.
```

Every Markdown file in `docs/intents/` except `README.md` is an intent chapter.
Each chapter has exactly one `INT-NNNN` identifier, and identifiers are globally
unique. Legal states are `proposed`, `planned`, `active`, `deferred`, `realized`,
`superseded`, and `abandoned`.

Every evidence value is either `none` or one or more Markdown links.

- `planned`, `active`, and `deferred` require Work evidence naming a `T-NNN`
  task or linking a plan beneath `docs/sprints/sN/sprint-plans/`.
- `realized` requires Completion evidence that names a `T-NNN` and links
  `docs/work/completed-tasks.md`. It also requires at least one link in Code,
  Test, or Documentation evidence.
- Other states may use `none` when that evidence does not apply.

Intent, Acceptance criteria, Rationale, Alternatives, Consequences, and
Transition history are required prose. Preserve transition history when state
changes. Record rationale and consequences here instead of creating an active
ADR. Sprint records are provenance; migrated ADRs under `docs/history/` are
non-authoritative history.
