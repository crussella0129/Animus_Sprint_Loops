# Sprint Loops — Claude Code

> For Anthropic's Claude Code, using the native skills system.

A drop-in `sprint-loops` skill plus an optional `/sprint` slash command. The skill
runs the five-phase Sprint Loops workflow — **Research → Plan → Build → Test → Loop**
— for long-horizon coding tasks. The protocol itself is defined in
[`../open-harnesses/`](../open-harnesses/); this directory is a thin adapter over it.

## Why a skill, not a prompt

A loop prompt is always loaded — every session pays the token cost whether you're
sprinting or not. A skill is conditionally invoked via its description, so it only
enters context when relevant. Skills also support subordinate files and bash
helpers, which matches the per-phase particle model exactly:

- **Skill discovery is automatic** — the description triggers when sprint-loop intent is detected.
- **Phase files are lazy-loaded** — only the active phase enters context.
- **Bash helpers do the deterministic work** — sprint numbering, phase detection, git commits. LLMs are bad at counting `s0, s1, s2`; shell scripts aren't.
- **Plan mode is engaged at the right moment** — only during the Plan Phase, not always.

## What's in this directory

```
claude-code/
├── README.md                         # this file
├── skills/
│   └── sprint-loops/
│       ├── SKILL.md                  # description + routing
│       ├── phases/                   # one lazy-loaded file per phase (00–06)
│       ├── schemas/                  # output-artifact templates (9 files)
│       └── scripts/                  # deterministic bash helpers (6 files)
└── commands/
    └── sprint.md                     # optional /sprint slash command
```

## Installation

User-level (available in every project):

```bash
mkdir -p ~/.claude/skills ~/.claude/commands
cp -r claude-code/skills/sprint-loops ~/.claude/skills/
cp claude-code/commands/sprint.md ~/.claude/commands/
chmod +x ~/.claude/skills/sprint-loops/scripts/*.sh
```

Project-scoped (committed alongside one repo):

```bash
mkdir -p .claude/skills .claude/commands
cp -r claude-code/skills/sprint-loops .claude/skills/
cp claude-code/commands/sprint.md .claude/commands/
chmod +x .claude/skills/sprint-loops/scripts/*.sh
```

## Usage

The skill is invoked automatically when you express sprint-loop intent — "start a
sprint", "continue the loop", "next sprint", or when the project root already
contains a `sprints/` directory and you ask to resume.

The optional `/sprint` command gives explicit control:

- `/sprint start "add JWT refresh tokens"` — initialize a new sprint with that goal
- `/sprint continue` — resume from whatever phase the filesystem reports
- `/sprint loop` — jump to the Loop Phase
- `/sprint abort` — mark the current sprint aborted and close it out

## How it routes

1. `scripts/current-phase.sh` inspects the filesystem and prints the active phase.
2. The skill reads the matching file from `phases/` and executes it.
3. When the phase's exit artifact is on disk, routing repeats.

Plan mode is engaged automatically when entering the Plan Phase, where the agent
produces `build-plan.md` and `test-plan.md` without touching source files. Every
completed Build-Phase task ends in a git commit via `scripts/commit-task.sh`.

For the core protocol — directory schema, phase exit conditions, failure
semantics, and the optional confidence throttle — see
[`../open-harnesses/README.md`](../open-harnesses/README.md).
