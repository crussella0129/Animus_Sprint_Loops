# Sprint Loops — Open Harnesses

> For OpenClaw, OpenCode, local LLMs, custom runners, GECK, or any agent runtime
> that can read markdown files and execute shell commands.

This directory is the **canonical, runtime-agnostic specification** of the Sprint
Loops protocol. The [`claude-code/`](../claude-code/) and [`codex-cli/`](../codex-cli/)
bundles are thin adapters over what is defined here.

Sprint Loops decomposes long-horizon coding work into numbered sprints, each a
five-phase sequence — **Research → Plan → Build → Test → Loop** — with persistent
state on disk and a clean separation between working memory and the rolling backlog.

## What's in this directory

```
open-harnesses/
├── README.md            # this file — the core protocol
├── particles/           # one prompt particle per phase (Oovra / vector-store ready)
│   ├── 00-overview.md
│   ├── 01-init-sprint.md
│   ├── 02-research-phase.md
│   ├── 03-plan-phase.md
│   ├── 04-build-plan-schema.md
│   ├── 05-test-plan-schema.md
│   ├── 06-build-phase.md
│   ├── 07-test-phase.md
│   └── 08-loop-phase.md
├── schemas/             # output-artifact templates, one per file
│   ├── sprint-meta.md       research-report.md   build-plan.md
│   ├── test-plan.md         agent-tasks.md       completed-tasks.md
│   └── test-report.md       failure-report.md    decisions.md
└── scripts/             # deterministic helpers — let bash count sprints, not the LLM
    ├── current-sprint.sh    current-phase.sh     commit-task.sh
    └── init-sprint.sh       finalize-plan.sh     update-confidence.sh
```

Particles are kept one-per-file so they can be embedded individually into
[Oovra](https://github.com/crussella0129) or any vector store — each has a single
semantic surface, which keeps embeddings tight and retrieval ranking clean.

## Getting started

1. **Drop the helpers into your project.** Copy `scripts/` to your project root so
   the agent can run `scripts/current-phase.sh` from there:

   ```bash
   cp -r open-harnesses/scripts /path/to/your/project/scripts
   chmod +x /path/to/your/project/scripts/*.sh
   ```

2. **Load the particles into your retrieval store.** Index every file in
   `particles/` (and optionally `schemas/`) so the harness can retrieve them by
   semantic match.

3. **Wire the invocation loop** (below) into your harness.

4. **Start a sprint.** When the user expresses sprint-loop intent, inject the
   Loop Overview particle, then run `scripts/init-sprint.sh` and proceed.

## Invocation model

Open harnesses retrieve particles by semantic match. The harness should:

1. Detect sprint-loop intent (user says "start a sprint", "continue the loop", etc.).
2. Run `scripts/current-phase.sh` to inspect the filesystem and determine the active phase.
3. Retrieve the matching phase particle.
4. Inject it as a user-role or system-role message.
5. Execute. Loop.

`current-phase.sh` maps the filesystem to one of: `uninitialized`, `research`,
`plan`, `build`, `test`, `loop`, `ready-for-next-sprint`. Route each to its particle:

| Phase output            | Particle                          |
|-------------------------|-----------------------------------|
| `uninitialized`         | `particles/01-init-sprint.md`     |
| `research`              | `particles/02-research-phase.md`  |
| `plan`                  | `particles/03-plan-phase.md` (→ `04`, `05`) |
| `build`                 | `particles/06-build-phase.md`     |
| `test`                  | `particles/07-test-phase.md`      |
| `loop`                  | `particles/08-loop-phase.md`      |
| `ready-for-next-sprint` | `particles/01-init-sprint.md`     |

---

# Core Protocol

This protocol is identical across all three deployment targets. What changes
between them is only how the agent discovers and routes through the phases.

## Directory schema

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

Conflating these is the most common failure mode in agentic workflows. The
filesystem IS the state machine. Trust the disk.

## Phase exit conditions (quick reference)

| Phase      | Exit artifact                                              | Exit condition                              |
|------------|------------------------------------------------------------|---------------------------------------------|
| Initialize | All directories + files exist, `sprint-meta.md` populated  | Filesystem matches schema                   |
| Research   | `research-report.md` with all 5 sections                   | Report complete, artifacts referenced       |
| Plan       | `build-plan.md` + `test-plan.md` both finalized            | Both files prepended with `Finalized - DO NOT EDIT` |
| Build      | All tasks in `agent-tasks.md` for this sprint completed or blocked | Git commits exist for each completed task   |
| Test       | `test-report.md` written (or `failure-report.md`)          | All tests run, CI green or failure documented |
| Loop       | `sprint-meta.md` finalized, git tree clean                 | Ready to invoke Initialize for sprint N+1   |

## Failure semantics

When a sprint fails (Test Phase produces irrecoverable failures requiring re-architecture):

1. Test Phase writes `sprints/sN/failure-report.md`.
2. `sprint-meta.md` exit status is set to `failed`.
3. Loop Phase still runs — closes out the failed sprint cleanly.
4. The next sprint's Research Phase begins by reading the prior `failure-report.md` as its primary input.
5. Sprint numbering does not reset. A failed sprint still counts.

See [`schemas/failure-report.md`](schemas/failure-report.md) for the report template.

## Confidence throttle (optional)

Track a `confidence` scalar across sprints. Initialize at 1.0. After each sprint:

- All tests pass → `confidence = min(1.0, confidence + 0.1)`
- Any unit/integration failures patched in-sprint → `confidence -= 0.1`
- Failure-report written → `confidence -= 0.3`

Use confidence to gate sprint ambition: when `confidence < 0.5`, the next sprint's
build-plan must have ≤ 5 elementary tasks. This mirrors the covariance update in a
Kalman filter — research is measurement, plan is prediction, build is state update,
test is innovation, loop is covariance update.

Store in `confidence.txt` as a single float. The [`scripts/update-confidence.sh`](scripts/update-confidence.sh)
helper applies the three adjustments above.

---

The protocol is the contract. A repo using Sprint Loops can be worked on by any
harness interchangeably — see the [root README](../README.md) for cross-harness notes.
