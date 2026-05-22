# Sprint Loops — Claude Code

> **This directory ships a complete, install-ready Claude Code skill: `sprint-loop`.**
> This README is the *accompanying documentation* — what the skill is, how to
> install it, and the protocol it runs. The skill itself is everything under
> `skills/sprint-loop/`; you do not need this README at runtime.

`sprint-loop` runs the five-phase Sprint Loops workflow — **Research → Plan →
Build → Test → Loop** — for long-horizon coding tasks, invoked automatically or
via the `/sprint-loop` slash command. Everything needed to deploy and run it on
Claude Code is in this directory; no other part of the repo is required.

## The skill, and its accompanying docs

| Path | Role |
|------|------|
| `skills/sprint-loop/` | **The skill.** The complete, install-ready bundle — install this. Its frontmatter `argument-hint` makes it the `/sprint-loop` slash command directly; there is no separate command file. |
| `README.md` (this file) | **Accompanying documentation.** Install guide + protocol reference for humans. |
| `LICENSE` | MIT. |

## Why a skill, not a prompt

A loop prompt is always loaded — every session pays the token cost whether you're
sprinting or not. A skill is conditionally invoked via its description, so it only
enters context when relevant. Skills also support subordinate files and bash
helpers, which matches the per-phase model exactly:

- **Skill discovery is automatic** — the description triggers when sprint-loop intent is detected.
- **Phase files are lazy-loaded** — only the active phase enters context.
- **Bash helpers do the deterministic work** — sprint numbering, phase detection, git commits. LLMs are bad at counting `s0, s1, s2`; shell scripts aren't.
- **Plan mode is engaged at the right moment** — only during the Plan Phase, not always.

## Skill layout

```
skills/sprint-loop/
├── SKILL.md                  # description + routing (skill name: sprint-loop)
├── phases/                   # one lazy-loaded file per phase
│   ├── 00-overview.md        # the complete core protocol — read first
│   ├── 01-init-sprint.md     04-build-phase.md
│   ├── 02-research-phase.md  05-test-phase.md
│   └── 03-plan-phase.md      06-loop-phase.md
├── schemas/                  # output-artifact templates (9 files)
└── scripts/                  # deterministic bash helpers (6 files)
```

`phases/00-overview.md` carries the full protocol (directory schema, phase exit
conditions, failure semantics, confidence throttle), so the agent never needs a
document outside the skill bundle.

## Installation

### Recommended — install as a plugin

This repo is a Claude Code plugin marketplace. Installing this way loads the
skill **once via the plugin mechanism**, regardless of which directory you launch
Claude Code from:

```
/plugin marketplace add crussella0129/sprint-loops
/plugin install sprint-loop@sprint-loops
```

**Why this is recommended (and how it avoids duplicate picker entries):** a bare
"personal" install (copying into `~/.claude/skills`, below) is scanned by *both*
the user root (`~/.claude`) and the project root (`<cwd>/.claude`). When you
launch Claude Code **from your home directory** those two roots are the *same*
directory, so the skill gets enumerated twice. Older installs also shipped a
separate `commands/sprint-loop.md`, which is a duplicate definition of
`/sprint-loop` (a command and a same-named skill load identically) — together
that produced up to four identical `/sprint-loop` entries. This skill now *is*
the `/sprint-loop` command (via `argument-hint`), so there is no command file,
and plugins live in the plugin tree, not in either colliding root — so they load
exactly once no matter where you start Claude. Every other skill in your picker
is delivered this way; this makes `sprint-loop` behave the same.

> **Migrating from a bare install?** Remove it so it stops double-loading:
> ```bash
> rm -rf ~/.claude/skills/sprint-loop ~/.claude/commands/sprint-loop.md
> ```
> Then install the plugin as above.

### Fallback — manual copy (no plugin system)

Skill-only (the skill *is* the `/sprint-loop` command — nothing to copy into
`commands/`). Note the home-dir caveat above — prefer the plugin install if you
launch Claude Code from `~`. Or just run `bash claude-code/install.sh`.

User-level (available in every project):

```bash
mkdir -p ~/.claude/skills
cp -r claude-code/skills/sprint-loop ~/.claude/skills/
chmod +x ~/.claude/skills/sprint-loop/scripts/*.sh
```

Project-scoped (committed alongside one repo):

```bash
mkdir -p .claude/skills
cp -r claude-code/skills/sprint-loop .claude/skills/
chmod +x .claude/skills/sprint-loop/scripts/*.sh
```

## Usage

The skill is invoked automatically when you express sprint-loop intent — "start a
sprint", "continue the loop", "next sprint", or when the project root already
contains a `sprints/` directory and you ask to resume.

The skill *is* the `/sprint-loop` slash command (its `argument-hint` frontmatter),
so you can invoke it explicitly with arguments:

- `/sprint-loop start "add JWT refresh tokens"` — initialize a new sprint with that goal
- `/sprint-loop continue` — resume from whatever phase the filesystem reports
- `/sprint-loop loop` — jump to the Loop Phase
- `/sprint-loop abort` — mark the current sprint aborted and close it out

### Unattended / auto mode (Claude-specific)

Run sprints hands-off by combining two Claude Code primitives:

- **Auto mode:** select **auto-accept** at the Plan Phase's `ExitPlanMode`
  approval — that carries Build/Test/Loop without per-step prompts.
- **Recurrence:** launch under `/loop` — `/loop /sprint-loop continue` — so
  each sprint re-fires automatically.

The loop runs unattended and **stops only at human-verification checkpoints** —
things AI can't verify: visual/UX inspection, an irreversible or
unknown-consequence action, genuine product ambiguity, or an unrecoverable
failure. Everything AI *can* verify (green CI, reversible changes, known-
reversible merges) proceeds. A count cap (`/loop N …`) is optional, not the
recommended posture — the checkpoints are the intended stops. This is
**Claude-specific** — Codex's equivalent unattended path is `codex exec`
(see `../codex-cli/`).

## How it routes

1. `scripts/current-phase.sh` inspects the filesystem and prints the active phase.
2. The skill reads the matching file from `phases/` and executes it.
3. When the phase's exit artifact is on disk, routing repeats.

Plan mode is engaged automatically when entering the Plan Phase, where the agent
produces `build-plan.md` and `test-plan.md` without touching source files. Every
completed Build-Phase task ends in a git commit via `scripts/commit-task.sh`.

The helper scripts resolve their sibling scripts relative to their own location,
so they work whether `scripts/` lives in the installed skill bundle or is copied
into the project root. They read and write sprint state in the current working
directory (your project root).

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
prompt particles) and [`../codex-cli/`](../codex-cli/) is the Codex CLI bundle. A
repo using Sprint Loops can be worked on by any of them interchangeably — the
filesystem state is the contract. None is a prerequisite for this one.
