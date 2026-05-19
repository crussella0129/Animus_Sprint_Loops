# Sprint Loops

A lightweight protocol for autonomous software development — for **Claude Code**,
**Codex CLI**, and **open harnesses** like OpenClaw and OpenCode.

Sprint Loops decomposes long-horizon coding work into numbered sprints, each a
five-phase sequence — **Research → Plan → Build → Test → Loop** — with persistent
state on disk and a clean separation between working memory and the rolling
backlog. The filesystem IS the state machine. Trust the disk.

## Three install paths

This repo ships the same protocol three ways. Pick the directory that matches your
agent runtime — each is self-contained and ready to use:

| Directory | Target | What it is |
|-----------|--------|------------|
| [`open-harnesses/`](open-harnesses/) | OpenClaw, OpenCode, local LLMs, custom runners, GECK | The **canonical, runtime-agnostic spec**: the core protocol, prompt particles, artifact schemas, and reference shell scripts. |
| [`claude-code/`](claude-code/) | Anthropic Claude Code | A drop-in `~/.claude/skills/sprint-loops/` skill bundle plus an optional `/sprint` slash command. |
| [`codex-cli/`](codex-cli/) | OpenAI Codex CLI | A drop-in `~/.codex/skills/sprint-loops/` skill bundle plus an `AGENTS.md` fragment. |

The core protocol — filesystem layout, phase exit conditions, schemas — is
identical across all three. What changes is only how the agent discovers and
routes through the phases. **Each directory is a complete, self-contained unit:**
installing one does not require the others, and each carries the full core
protocol. `open-harnesses/` additionally doubles as the canonical cross-harness
reference and the Oovra-particle source.

## Quick start

**Claude Code:**

```bash
cp -r claude-code/skills/sprint-loops ~/.claude/skills/
cp claude-code/commands/sprint.md ~/.claude/commands/
chmod +x ~/.claude/skills/sprint-loops/scripts/*.sh
```

Then say "start a sprint" or run `/sprint start "<goal>"`. See
[`claude-code/README.md`](claude-code/README.md).

**Codex CLI:**

```bash
cp -r codex-cli/skills/sprint-loops ~/.codex/skills/
chmod +x ~/.codex/skills/sprint-loops/scripts/*.sh
cat codex-cli/skills/sprint-loops/AGENTS.md.fragment >> AGENTS.md
```

See [`codex-cli/README.md`](codex-cli/README.md).

**Open harness:**

```bash
cp -r open-harnesses/scripts /path/to/your/project/scripts
chmod +x /path/to/your/project/scripts/*.sh
```

Index `open-harnesses/particles/` into your retrieval store and wire the
invocation loop. See [`open-harnesses/README.md`](open-harnesses/README.md).

## Repository layout

```
sprint-loops/
├── README.md            # this file
├── LICENSE              # MIT
├── open-harnesses/      # Section 1 — canonical spec: protocol, particles, schemas, scripts
├── claude-code/         # Section 2 — drop-in Claude Code skill + /sprint command
└── codex-cli/           # Section 3 — drop-in Codex CLI skill + AGENTS.md fragment
```

## Cross-harness compatibility

A repo using Sprint Loops can be worked on by any of the three harnesses
interchangeably. The filesystem state is the contract:

- `sprints/sN/` and `agent-tasks/` mean the same thing everywhere.
- Phase files are content-identical across harnesses (only the routing layer differs).
- `decisions.md` and `confidence.txt` are universal.
- Git history is the source of truth for what actually happened.

You can start a sprint on Claude Code at your desk, continue it on Codex in a CI
run overnight, and resume it on an OpenClaw node the next morning — without any
state translation. The project itself is the protocol.

## Distribution

Each adapter directory can ship as a separate release targeted at its harness:

- `sprint-loops-protocol` — the spec, schemas, and reference shell scripts (`open-harnesses/`).
- `sprint-loops-claude-code` — drop-in `~/.claude/skills/sprint-loops/` bundle.
- `sprint-loops-codex` — drop-in `~/.codex/skills/sprint-loops/` bundle.
- `sprint-loops-particles` — Oovra-ready individual `.md` particles (`open-harnesses/particles/`).

If folded into GECK, "GECK Loops" becomes a fourth adapter directory — without
changing anything in the first three.

## License

[MIT](LICENSE) © 2026 Charles Russella.
