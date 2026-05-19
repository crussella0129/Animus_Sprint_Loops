# Phase 00 — Overview & Core Protocol

> Read this first if this is your first interaction with the skill this session.
> This file is the **complete protocol**. The other files in `phases/` are the
> per-phase playbooks you route into; `schemas/` holds artifact templates and
> `scripts/` holds deterministic helpers. Everything needed to run a Sprint Loop
> is in this bundle — no external document is required.

## The loop

You have entered a Sprint Loop. You will work in numbered sprints. Each sprint is
a five-phase sequence: **Research → Plan → Build → Test → Loop**. Each phase has
its own file in `phases/`; read the file matching your current phase before
acting.

Do not skip phases. Do not merge phases. The current phase ends only when its exit
artifact is written to disk.

## Determining your current phase

Run `scripts/current-phase.sh` — it inspects the filesystem and prints one of
`uninitialized`, `research`, `plan`, `build`, `test`, `loop`, or
`ready-for-next-sprint`. The mapping it applies:

- no `sprints/` directory → pre-initialization
- latest sprint's `research-report.md` missing or empty → Research
- research complete but plans lack the `Finalized - DO NOT EDIT` header → Plan
- plans finalized but `agent-tasks.md` still has incomplete tasks for this sprint → Build
- all build tasks done but `test-report.md`/`failure-report.md` missing → Test
- both exist and `sprint-meta.md` exit status still `in-progress` → Loop

The filesystem IS the state machine. Trust the disk — do not re-derive state from
chat history.

## Directory schema

A project running Sprint Loops has this layout at its root:

```
project-root/
├── decisions.md                      # ADR-style architectural decisions log
├── confidence.txt                    # Optional: confidence scalar (Kalman-style throttle)
├── agent-tasks/                      # PERSISTENT — survives across sprints
│   ├── agent-tasks.md                # Current backlog (append at bottom, consume from top)
│   └── completed-tasks.md            # Append-only log of finished tasks
└── sprints/                          # EPHEMERAL — one subdirectory per sprint
    ├── s0/
    │   ├── sprint-meta.md
    │   ├── sprint-research/
    │   │   ├── research-report.md
    │   │   └── [artifacts]
    │   ├── sprint-plans/
    │   │   ├── build-plan.md         # Locked after Plan Phase
    │   │   └── test-plan.md          # Locked after Plan Phase
    │   └── sprint-tests/
    │       ├── unit-tests.md
    │       ├── integration-tests.md
    │       ├── e2e-tests.md
    │       └── test-report.md
    ├── s1/
    └── sN/
```

## Why two state surfaces

- **`sprints/sN/`** is *working memory* — what this sprint is doing, ephemeral,
  never modified after the sprint closes.
- **`agent-tasks/`** is *long-term memory* — what has ever been done, what is still
  pending, persistent across all sprints.

Conflating these is the most common failure mode in agentic workflows.

## Phase exit conditions

| Phase      | Exit artifact                                              | Exit condition                              |
|------------|------------------------------------------------------------|---------------------------------------------|
| Initialize | All directories + files exist, `sprint-meta.md` populated  | Filesystem matches schema                   |
| Research   | `research-report.md` with all 5 sections                   | Report complete, artifacts referenced       |
| Plan       | `build-plan.md` + `test-plan.md` both finalized            | Both files prepended with `Finalized - DO NOT EDIT` |
| Build      | All tasks in `agent-tasks.md` for this sprint completed or blocked | Git commits exist for each completed task   |
| Test       | `test-report.md` written (or `failure-report.md`)          | All tests run, CI green or failure documented |
| Loop       | `sprint-meta.md` finalized, git tree clean                 | Ready to invoke Initialize for sprint N+1   |

## Failure semantics

When a sprint fails (the Test Phase produces irrecoverable failures requiring
re-architecture):

1. Test Phase writes `sprints/sN/failure-report.md` (schema: `schemas/failure-report.md`).
2. `sprint-meta.md` exit status is set to `failed`.
3. Loop Phase still runs — it closes out the failed sprint cleanly.
4. The next sprint's Research Phase begins by reading the prior `failure-report.md` as its primary input.
5. Sprint numbering does not reset. A failed sprint still counts.

## Confidence throttle (optional)

Track a `confidence` scalar across sprints in `confidence.txt`. Initialize at 1.0.
After each sprint:

- All tests pass → `confidence = min(1.0, confidence + 0.1)`
- Any unit/integration failures patched in-sprint → `confidence -= 0.1`
- Failure-report written → `confidence -= 0.3`

When `confidence < 0.5`, the next sprint's build-plan must have ≤ 5 elementary
tasks. This mirrors the covariance update in a Kalman filter — research is
measurement, plan is prediction, build is state update, test is innovation, loop
is covariance update. The `scripts/update-confidence.sh` helper applies these
adjustments.

## Routing

Once you know your phase, read the matching `phases/` file and execute it:

`01-init-sprint` → `02-research-phase` → `03-plan-phase` → `04-build-phase` →
`05-test-phase` → `06-loop-phase`, then back to `01-init-sprint` for sprint N+1.

Each phase file ends by naming the next one. When a phase's exit artifact is on
disk, re-run `scripts/current-phase.sh` and route again.
