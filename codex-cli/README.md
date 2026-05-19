# Sprint Loops — Codex CLI

> For OpenAI's Codex CLI, using its skills system and `AGENTS.md`.

A drop-in `sprint-loops` skill plus an `AGENTS.md` fragment. The skill runs the
five-phase Sprint Loops workflow — **Research → Plan → Build → Test → Loop** — for
long-horizon coding tasks. The protocol itself is defined in
[`../open-harnesses/`](../open-harnesses/); this directory is a thin adapter over it.

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
└── skills/
    └── sprint-loops/
        ├── SKILL.md                  # Codex skill metadata + routing
        ├── AGENTS.md.fragment        # drop-in fragment for your project's AGENTS.md
        ├── phases/                   # one file per phase (00–06)
        ├── schemas/                  # output-artifact templates (9 files)
        └── scripts/                  # deterministic bash helpers (6 files)
```

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

For the core protocol — directory schema, phase exit conditions, failure
semantics, and the optional confidence throttle — see
[`../open-harnesses/README.md`](../open-harnesses/README.md).
