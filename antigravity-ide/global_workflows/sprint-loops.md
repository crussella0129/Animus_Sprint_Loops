---
description: Run or resume the Sprint Loops Book v2 workflow while presenting Antigravity-native artifacts as non-authoritative views.
---

# Sprint Loops — Antigravity Adapter

Run this workflow only for `/sprint-loops` or a direct request to start,
continue, or resume a Sprint Loop.

## Resolve and route

- `<project-root>` is the target Git top level, or the active workspace root
  for a non-Git project. Resolve ambiguity before writing.
- `<skill-root>` is the installed Antigravity skill directory at
  `~/.gemini/config/skills/sprint-loop`. Verify its `SKILL.md`,
  `scripts/current-phase.sh`, and `schemas/intent.md`.

From `<project-root>`, run:

```bash
bash "<skill-root>/scripts/current-phase.sh"
```

Route `uninitialized` and `ready-for-next-sprint` to Initialize, then route
`research`, `plan`, `build`, `test`, and `loop` to their matching sections
below. Re-run the helper after each evidence exit. For a legacy-only or
split-brain diagnostic, stop normal writes and use
`bash "<skill-root>/scripts/migrate-to-book.sh"` only when migration is in
scope; never create a second writable state tree.

## Book authority

`docs/.sprint-loop-book` contains `schema-version: 2`. The Project Book is the
state machine:

1. `docs/intents/INT-NNNN-*.md` is semantic authority for outcomes,
   boundaries, acceptance, rationale, alternatives, consequences, and state.
2. `docs/work/tasks.md` and `docs/work/completed-tasks.md` are work state.
3. `docs/sprints/sN/` is research, planning, verification, and close
   provenance.
4. `docs/SUMMARY.md`, chat, and native artifacts are non-authoritative views.

Repair lower-authority evidence from intent, or revise the intent explicitly
and append its transition history. Record durable decisions in the intent.

## Native artifact mapping

| Native artifact | Book meaning | Synchronization rule |
| --- | --- | --- |
| `implementation_plan.md` | Non-authoritative view of unrealized intent and planning. | Put stable meaning in `docs/intents/`; put sprint execution in `docs/sprints/sN/sprint-plans/`; lock plans only with the helper. |
| `task.md` | Non-authoritative view of work state. | Mirror task IDs and status from `docs/work/tasks.md` and `docs/work/completed-tasks.md`; complete work only through the task helper. |
| `walkthrough.md` | Non-authoritative view of realization evidence. | Before presenting it, sync Completion evidence plus at least one Code, Test, or Documentation evidence link to each intent claimed as `realized`. The walkthrough alone never realizes intent. |

Another harness must be able to resume from the Book alone without native
artifacts or prior chat.

## Phase evidence and helpers

### Initialize

Run `bash "<skill-root>/scripts/init-sprint.sh"`. Exit when Book schema v2 and
the next `docs/sprints/sN/` record exist and routing reports `research`.

### Research

Resolve the sprint with `bash "<skill-root>/scripts/current-sprint.sh"`. Write
the research report from `<skill-root>/schemas/research-report.md`; its exact
`## Intents Reviewed` section links at least one selected, created, or revised
intent. Run `bash "<skill-root>/scripts/research-budget.sh"`. Exit when routing
reports `plan`.

### Plan

Draft `implementation_plan.md` from the research report, linked intent, and
proposed unlocked Book plans for native review; it does not become an upstream
authority. After approval, apply accepted feedback to intent and the Book
plans. Move each sprint-advanced `proposed` or `deferred` intent to `planned`,
attach task or plan Work evidence, and append the actual transition; preserve
an already `active` intent without a no-op entry. Every task names intent, and
every EARS clause and affected acceptance criterion maps to a named test. Save
an independent read-only critique with an accepted final verdict, then run
`bash "<skill-root>/scripts/finalize-plan.sh"`. Exit only when both plans are
helper-locked and routing reports `build`.

### Build

Render `task.md` from the locked plan and Book ledgers. Transition linked
planned intent to `active`. For each task, update the canonical ledgers using
the installed schemas, including exact Commit value `PENDING`, then run:

```bash
bash "<skill-root>/scripts/commit-task.sh" T-XXX "<description>" -- <explicit-path> [path...]
```

Refresh the native checklist from the Book. Exit when no current-sprint task
remains and routing reports `test`.

### Test

Verify every locked EARS clause and linked acceptance criterion. Save
unit/integration/E2E evidence and an accepted read-only critique under the
current sprint's `sprint-tests/`. On success, write `test-report.md` and link
Test evidence from verified intents; on re-architecture failure, write
`failure-report.md`. Exit when routing reports `loop`.

### Loop

Reconcile intent against completion plus code/test/documentation evidence,
transition eligible intent to `realized`, and put carry-forward work in
`docs/work/tasks.md`. Present `walkthrough.md` only after that sync. Commit
coherent remaining Book changes, then run:

```bash
bash "<skill-root>/scripts/check-book.sh"
bash "<skill-root>/scripts/close-sprint.sh" <success|failed> "<one-line completion evidence>"
bash "<skill-root>/scripts/current-phase.sh"
```

Exit when validation passes and the final command reports
`ready-for-next-sprint`.

## Authority

Always Proceed and auto-accept are interaction preferences only. They do not
enlarge authority, bypass Book gates, make a native view authoritative, or
authorize a new sprint beyond the user's requested boundary.

Push, merge, release, force-push, delete, and material scope expansion require an explicit request or a declared preauthorized-remote profile.

Stop for product ambiguity, unavailable required capability, irreversible or
unknown-consequence action, and visual or experiential claims needing human
judgment.
