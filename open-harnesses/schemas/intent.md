# Schema: intent chapter

Intent chapters live at `docs/intents/INT-NNNN-<slug>.md`. They are the
Project Book's stable semantic authority: one durable statement of project
intent spanning unrealized and realized work. `docs/SUMMARY.md` is navigation
only.

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
<desired outcome, boundaries, and non-goals>

## Acceptance criteria
<observable conditions that prove the intent>

## Rationale
<why this intent exists and why the current direction was chosen>

## Alternatives
<options considered and why they were not selected>

## Consequences
<accepted costs, constraints, and follow-on effects>

## Transition history
- YYYY-MM-DD: created as `proposed`.
```

Every Markdown file in `docs/intents/` except `README.md` is an intent
chapter. Each chapter has exactly one globally unique `INT-NNNN` identifier.
Legal states are:

- `proposed` — described but not accepted into executable work.
- `planned` — accepted and linked to scheduled work.
- `active` — implementation or verification is in progress.
- `deferred` — still desired, with work deliberately postponed.
- `realized` — acceptance criteria are satisfied and realization evidence is
  attached.
- `superseded` — replaced by a newer intent; name the replacement in prose.
- `abandoned` — no longer intended; preserve the reason.

Protocol transitions are `proposed → planned|abandoned`,
`planned → active|deferred|abandoned`,
`active → realized|deferred|superseded|abandoned`,
`deferred → planned|active|superseded|abandoned`, and
`realized → superseded`. Create a follow-on intent instead of rewriting a
terminal chapter. Append every state change and its reason to Transition
history; never erase prior entries.

Every evidence value is either exactly `none` or one or more Markdown links.

- `planned`, `active`, and `deferred` require Work evidence. Use a link
  whose label or target identifies a `T-NNN` task or a plan beneath
  `docs/sprints/sN/sprint-plans/`, for example
  `[T-001 build plan](../sprints/s14/sprint-plans/build-plan.md#t-001-short-title)`.
- `realized` requires Completion evidence that identifies a `T-NNN` and
  links `docs/work/completed-tasks.md`, for example
  `[T-001 completion](../work/completed-tasks.md#t-001-sprint-14)`.
  It also requires at least one Markdown link in Code, Test, or Documentation
  evidence.
- Other states may use `none` where an evidence class does not apply.

Record rationale, alternatives, consequences, and subsequent changes in this
stable chapter. Sprint records provide provenance; migrated material under
`docs/history/` is non-authoritative history and never a second decision
store.

`check-book.sh` validates the v2 marker, unique IDs, legal state names, field
shape, and state-dependent evidence shape. Authors and reviewers must also
verify link resolution, prose quality, acceptance coverage, and transition
legality; the structural validator does not prove those semantic properties.
