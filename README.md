# Animus Sprint Loops

Animus Sprint Loops turns a project's documentation into a living **Project
Book**: one durable, linkable record of intended outcomes, active work,
realization evidence, and the sprint history that connects them. Work advances
through **Research → Plan → Build → Test → Loop**, with state derived from Book
evidence on disk.

## The Project Book

Book schema v2 is rooted at `docs/` and identified by
`docs/.sprint-loop-book`. Its authority is deliberately small and directional:

| Surface | Role |
| --- | --- |
| `docs/intents/` | Semantic authority for desired outcomes, boundaries, rationale, consequences, lifecycle state, and evidence links. |
| `docs/work/` | Current and completed execution state, linked back to intent. |
| `docs/sprints/` | Research, plans, critiques, verification, and close provenance. |
| `docs/SUMMARY.md` | Navigation only; it never becomes a second state store. |

Intent chapters span both unrealized and realized work. Plans and tasks provide
work evidence; completed tasks plus code, test, or documentation links provide
realization evidence. See the runtime-neutral [Book
contract](open-harnesses/particles/00-overview.md) and [intent lifecycle
schema](open-harnesses/schemas/intent.md) for the complete rules.

## Choose an adapter

Each adapter ships the shared Book contract plus only the orchestration needed
by its runtime. Install and operate one through its own guide:

| Runtime | Adapter guide | Invocation |
| --- | --- | --- |
| Claude Code | [Claude Code](claude-code/README.md) | `/sprint-loop:sprint-loop start "<goal>"` |
| OpenAI Codex | [Codex](codex-cli/README.md) | `$sprint-loops` |
| Antigravity IDE | [Antigravity](antigravity-ide/README.md) | `/sprint-loops` |
| OpenClaw, OpenCode, local models, and custom runners | [Open Harnesses](open-harnesses/README.md) | Route from the installed `current-phase.sh` helper. |

The Open Harnesses bundle is the runtime-neutral distribution and physical
reference copy for shared assets. It does not own project meaning: each
project's Book does.

## Cross-harness continuity

All supported adapters read the same Book schema and derive the same phase from
the same evidence. Harness-native plans, checklists, walkthroughs, and chat are
views; another harness must be able to resume from the Book alone.

For a legacy project, use the selected adapter's installed
`migrate-to-book.sh` helper before writing Book state. Migration preserves
history and establishes one writable authority. If legacy and Book layouts
conflict, routing stops with a split-brain diagnostic instead of choosing one
silently.

## Repository map

- [`open-harnesses/`](open-harnesses/) — runtime-neutral particles, schemas,
  and reference helpers.
- [`claude-code/`](claude-code/) — Claude Code skill and plugin distribution.
- [`codex-cli/`](codex-cli/) — Codex skill and cross-platform installers.
- [`antigravity-ide/`](antigravity-ide/) — Antigravity workflow, runtime skill,
  and installer.
- [`tools/`](tools/) — parity, policy, and deterministic verification guards.

## Verify this repository

Run the canonical suite from the repository root:

```bash
bash tools/run-guards.sh --determinism
```

## License

[MIT](LICENSE) © 2026 Charles Russella.
