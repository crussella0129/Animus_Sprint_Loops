# Animus Sprint Loops

Animus Sprint Loops turns a project's documentation into a living **Project
Book**: one durable, linkable record of intended outcomes, active work,
realization evidence, and the sprint history that connects them. Work advances
through **Research → Plan → Build → Test → Loop**, with state derived from Book
evidence on disk.

## Quick start

Sprint Loops runs the same five-phase workflow through whichever runtime you
already use. The fastest path:

**1 — Install an adapter.** Pick your runtime from [Choose an adapter](#choose-an-adapter)
and follow its guide. For Claude Code, add the marketplace and install the plugin
from an interactive session:

```bash
/plugin marketplace add crussella0129/Animus_Sprint_Loops
/plugin install sprint-loop@sprint-loops
```

**2 — Start or resume a loop.** From your project root, invoke the adapter
(Claude Code shown; see the table for Codex, Antigravity, and open harnesses):

```text
/sprint-loop:sprint-loop start "<one-line goal>"
```

Invoke it with no argument (or `continue`) to resume whatever phase the Book
reports.

**3 — What happens.** Every run begins at the **substrate gate**
(`check-substrate.sh`):

- On a brand-new project it reports `substrate-absent` and runs **Sprint 0
  deploy** (`deploy-substrate.sh`), which creates the `docs/` Book, the `main` /
  `dev` / optional `bump` branches, the work ledgers, a remote profile
  ([`schemas/remote-profile.md`](open-harnesses/schemas/remote-profile.md)), and
  the first sprint.
- On an established project it reports `substrate-complete` and hands off to
  routing, which advances the sprint through **Research → Plan → Build → Test →
  Loop**. Each phase writes its exit artifact into `docs/`; the current phase is
  *derived* from that evidence, never a mutable pointer.

Work accumulates on `dev`, and each sprint opens exactly one `dev → main`
pull/merge request as a reversible checkpoint — see [Branch model and
checkpoints](#branch-model-and-checkpoints).

**4 — Read the result.** All project state lives in the [`docs/` Project
Book](docs/): intents, work ledgers, and sprint provenance. Read it as a rendered
book with [mdBook](#view-the-book-as-a-book-with-mdbook).

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

### View the Book as a book with mdBook

The Book is plain Markdown, so it reads fine on GitHub or in any editor — but it
is also [mdBook](https://rust-lang.github.io/mdBook/)-compatible, and `docs/`
ships a [`book.toml`](docs/book.toml). Render it as a navigable book with a
sidebar and search:

```bash
cargo install mdbook          # or: brew install mdbook
mdbook serve docs             # live preview at http://localhost:3000
mdbook build docs             # static HTML into docs/book/ (git-ignored)
```

`docs/SUMMARY.md` is the table of contents. It is navigation only and never
stores state; the rendered `docs/book/` output is generated and ignored.

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

## Branch model and checkpoints

Sprint Loops uses a small, long-lived branch topology declared per project in a
[remote profile](open-harnesses/schemas/remote-profile.md)
(`docs/work/remote-profile.md`):

| Branch | Role |
| --- | --- |
| `main` | The official corpus. Reached only by a reviewed pull/merge request. |
| `dev` | Where sprints commit and push at any time. |
| `bump` | The dependency-update target (see below); optional. |

The skill never creates a per-sprint branch. Each sprint opens **exactly one
`dev → main`** pull/merge request as a reversible checkpoint, and — because the
remote profile's `mergePolicy` defaults to `human-approve` — it stops there for
a person to approve the merge. After `main` advances, `sync-work-branch.sh`
brings it back into `dev` at the sprint boundary so `dev` inherits everything on
the corpus. The provider is resolved from the profile: `github` drives `gh`,
`gitlab` drives `glab`, and any other remote falls back to pushing `dev` and
printing the compare URL, so the model works on every host.

## Dependency updates — the `bump` branch

Dependency bumps flow through `bump`, never onto `main` or `dev` directly:

1. The updater (Dependabot/Renovate) opens update pull/merge requests against
   `bump`.
2. CI runs on `bump`. If an update reddens CI, the compatibility fix is made on
   `bump` — the "bump sprint", which is sometimes nothing at all.
3. Once `bump` is green, open the checkpoint with `remote-adapter.sh open-pr
   --head bump`: a human-approved `bump → main` pull/merge request.
4. After it merges, `dev` inherits the update at the next sprint boundary via
   `sync-work-branch.sh`. `main` stays the single confluence.

**Sprint 0 deploy scaffolds the updater config for you** (create-if-absent, only
when `bump` is enabled): `github → .github/dependabot.yml`, `gitlab` / `generic
→ renovate.json` (`baseBranches: ["bump"]`), `local-only → none`. It is a starter
(`github-actions` / `config:recommended`) — add your project's ecosystems. To
wire it up on an existing project:

- **GitHub (Dependabot).** This repo ships
  [`.github/dependabot.yml`](.github/dependabot.yml) targeting `bump`. Enable
  Dependabot under the repository's **Settings → Code security** (on by default
  for public repos). Add ecosystems (`npm`, `pip`, `cargo`, …) beside the
  `github-actions` entry as the project grows.
- **GitLab / other hosts (Renovate).** GitLab has no native Dependabot; use
  [Renovate](https://docs.renovatebot.com/) with a `renovate.json` that sets
  `"baseBranches": ["bump"]` so update requests open against `bump`. Renovate
  also runs on GitHub, Bitbucket, and Gitea if you want one tool everywhere.
- **No hosted updater.** Push dependency changes to `bump` by hand and request
  them into `main` — the branch model is identical either way.

## Verify this repository

Run the canonical suite from the repository root:

```bash
bash tools/run-guards.sh --determinism
```

## License

[MIT](LICENSE) © 2026 Charles Russella.
