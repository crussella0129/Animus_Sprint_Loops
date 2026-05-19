# Sprint Loops — Codex CLI

> For OpenAI's Codex CLI, using its skills system and `AGENTS.md`.

A **self-contained, drop-in `sprint-loops` skill** plus an `AGENTS.md` fragment.
The skill runs the five-phase Sprint Loops workflow — **Research → Plan → Build →
Test → Loop** — for long-horizon coding tasks. Everything needed to deploy and run
it on Codex CLI is in this directory; no other part of the repo is required.

## Codex-specific considerations

Codex CLI has its own conventions worth respecting:

- **Skills are the supported primitive** for reusable instruction bundles (custom prompts are deprecated as of 2026).
- **`AGENTS.md`** is the equivalent of `CLAUDE.md` and is loaded once per session at startup.
- **`/plan` slash command** gives you plan mode natively.
- **`--ask-for-approval`** flag controls autonomy — relevant for Build Phase commit semantics.
- **`codex exec`** is the non-interactive runner — useful for CI-driven sprint loops.
- **Subagents** can parallelize independent tasks within a Build Phase.

## What's in this directory

```
codex-cli/
├── README.md                         # this file
├── LICENSE                           # MIT
└── skills/
    └── sprint-loops/
        ├── SKILL.md                  # Codex skill metadata + routing
        ├── AGENTS.md.fragment        # drop-in fragment for your project's AGENTS.md
        ├── phases/                   # one file per phase
        │   ├── 00-overview.md        # the complete core protocol — read first
        │   ├── 01-init-sprint.md     04-build-phase.md
        │   ├── 02-research-phase.md  05-test-phase.md
        │   └── 03-plan-phase.md      06-loop-phase.md
        ├── schemas/                  # output-artifact templates (9 files)
        └── scripts/                  # deterministic bash helpers (6 files)
```

`phases/00-overview.md` carries the full protocol (directory schema, phase exit
conditions, failure semantics, confidence throttle), so the agent never needs a
document outside this bundle.

## Installation

Skills live in your Codex home directory (defaults to `~/.codex/`):

```bash
mkdir -p ~/.codex/skills
cp -r codex-cli/skills/sprint-loops ~/.codex/skills/
chmod +x ~/.codex/skills/sprint-loops/scripts/*.sh
```

For project-scoped use, Codex also reads from `.codex/` at the project root, but
project-scoped configs require the project to be trusted.

Then tell Codex the project uses Sprint Loops by appending the fragment to your
project's `AGENTS.md`:

```bash
cat codex-cli/skills/sprint-loops/AGENTS.md.fragment >> AGENTS.md
```

## Usage

The skill triggers when you mention sprint loops, starting or continuing a sprint,
or when the project root already contains a `sprints/` directory. Routing follows
`SKILL.md`: `bash scripts/current-phase.sh` reports the active phase, and the
matching `phases/` file is executed.

When entering the Plan Phase, run `/plan` for native Codex plan mode.

The helper scripts resolve their sibling scripts relative to their own location,
so they work whether `scripts/` lives in the installed skill bundle or is copied
into the project root. They read and write sprint state in the current working
directory (your project root).

### Approval modes map to phase semantics

- **Research, Plan, Loop** — `--ask-for-approval on-request` (default).
- **Build** — `workspace-write` sandbox + `--ask-for-approval never`; every task ends in a git commit that provides rollback.
- **Test** — `workspace-write` + `on-request`.

Never use `--yolo` or `--dangerously-bypass-approvals-and-sandbox` for sprint
loops — the whole point of the system is auditable, recoverable iteration.

## Non-interactive mode (CI / automation)

`codex exec` makes Sprint Loops scriptable. Kick off a sprint at midnight, wake up
to either a clean test report or a failure-report you can read with your coffee:

```bash
# Run a single sprint end-to-end in CI
codex exec --ask-for-approval on-request \
  --sandbox workspace-write \
  "Continue the sprint loop. Use the sprint-loops skill. Run until the current sprint reaches the Loop Phase, then stop."
```

## Hooks integration (optional)

Codex supports lifecycle hooks. Wire `agent-turn-complete` to fire a notification
when a sprint phase completes:

```toml
# ~/.codex/config.toml
notify = ["sh", "-c", "if grep -q 'success' sprints/s$(./scripts/current-sprint.sh)/sprint-meta.md 2>/dev/null; then osascript -e 'display notification \"Sprint complete\" with title \"Sprint Loops\"'; fi"]
```

## Subagent opportunity

When the Build Phase has multiple independent tasks (no shared dependencies in the
build-plan's execution sequence), consider spawning subagents for parallelization.
Each subagent handles one task and commits its own diff; the parent agent merges
results and proceeds.

---

# Core Protocol

Sprint Loops decomposes long-horizon work into numbered sprints, each a five-phase
sequence — Research → Plan → Build → Test → Loop. This protocol is the contract;
it is identical across every harness, and only the routing layer differs between
them.

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

Conflating these is the most common failure mode in agentic workflows. The
filesystem IS the state machine. Trust the disk.

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

When a sprint fails (the Test Phase produces irrecoverable failures requiring re-architecture):

1. Test Phase writes `sprints/sN/failure-report.md`.
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

Use confidence to gate sprint ambition: when `confidence < 0.5`, the next sprint's
build-plan must have ≤ 5 elementary tasks. This mirrors the covariance update in a
Kalman filter — research is measurement, plan is prediction, build is state
update, test is innovation, loop is covariance update. The
`scripts/update-confidence.sh` helper applies the three adjustments above.

---

The same protocol ships for other runtimes alongside this directory:
[`../open-harnesses/`](../open-harnesses/) is the runtime-agnostic form (Oovra-ready
prompt particles) and [`../claude-code/`](../claude-code/) is the Claude Code
bundle. A repo using Sprint Loops can be worked on by any of them interchangeably —
the filesystem state is the contract. None is a prerequisite for this one.
