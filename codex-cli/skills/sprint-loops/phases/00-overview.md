# Phase 00 — Overview & Core Protocol

## Outcome

Operate a five-phase Sprint Loop — Research → Plan → Build → Test → Loop —
against one Project Book, and route to the current phase from evidence on disk.
Do not skip or merge phases.

## Inputs

Invoke the installed bundle's `scripts/current-phase.sh` helper with the
project root as its working directory. The harness adapter resolves the
installed bundle path.

It prints `uninitialized`, `research`, `plan`, `build`, `test`,
`loop`, or `ready-for-next-sprint`. If it reports legacy-only or
split-brain state, stop and follow the migration diagnostic; do not create a
second writable layout.

Book schema v2 is rooted at:

```text
docs/
├── .sprint-loop-book
├── README.md
├── SUMMARY.md
├── intents/
│   ├── README.md
│   └── INT-NNNN-<slug>.md
├── work/
│   ├── tasks.md
│   ├── completed-tasks.md
│   └── confidence.txt
├── sprints/
│   └── sN/
│       ├── sprint-meta.md
│       ├── sprint-research/research-report.md
│       ├── sprint-plans/{build-plan.md,test-plan.md,critique.md}
│       ├── sprint-tests/{unit-tests.md,integration-tests.md,e2e-tests.md,critique.md,test-report.md}
│       └── failure-report.md
└── history/
```

Read the phase file matching the helper result before acting.

## Authority

Authority has one direction:

1. `docs/intents/INT-NNNN-*.md` is semantic authority for desired outcomes,
   boundaries, acceptance criteria, rationale, alternatives, consequences, and
   lifecycle state.
2. `docs/work/tasks.md` and `docs/work/completed-tasks.md` are execution
   state linked back to intent.
3. `docs/sprints/sN/` is sprint provenance: research, plans, critiques,
   verification, and close evidence.
4. `docs/SUMMARY.md` and other views are navigation only.

When these surfaces disagree, repair the lower-authority evidence from the
intent or explicitly revise the intent and append its Transition history. A
sprint record never silently changes project intent.

The filesystem is the state machine. Chat history and generated navigation do
not override Book evidence.

## Exit evidence

The phase helper has produced one unambiguous state:

- `uninitialized` → read `01-init-sprint.md`.
- `research` → read `02-research-phase.md`.
- `plan` → read `03-plan-phase.md`.
- `build` → read `04-build-phase.md`.
- `test` → read `05-test-phase.md`.
- `loop` → read `06-loop-phase.md`.
- `ready-for-next-sprint` → read `01-init-sprint.md`.
