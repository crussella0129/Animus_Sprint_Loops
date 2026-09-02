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

- On a brand-new project it reports `substrate-absent` and runs
  **convergence** (`deploy-substrate.sh`), which creates the `docs/` Book, the
  `main` / `dev` branches, the work ledgers, a remote profile
  ([`schemas/remote-profile.md`](open-harnesses/schemas/remote-profile.md)), the
  first sprint, and the substrate contract stamp.
- On a project set up by an older bundle it reports
  `substrate-outdated:<book>-><bundle>` and runs the **same** command.
  Spin-up and upgrade are one idempotent operation — see [Convergence: spin-up
  and upgrade are one command](#convergence-spin-up-and-upgrade-are-one-command).
- On an established, current project it reports `substrate-complete` and hands
  off to routing, which advances the sprint through **Research → Plan → Build →
  Test → Loop**. Each phase writes its exit artifact into `docs/`; the current
  phase is *derived* from that evidence, never a mutable pointer.

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

## Convergence: spin-up and upgrade are one command

`deploy-substrate.sh` is the single entrypoint for all three cases. It creates
only what is missing, stamps the project's **substrate contract version**, and
verifies:

| Starting state | What the command does |
| --- | --- |
| Fresh project | Creates the Book, branches, ledgers, remote profile, first sprint, and the stamp. |
| Set up by an older bundle | Adds only the missing pieces and updates the stamp. |
| Already current | Nothing. It is a byte-for-byte no-op and says so. |

The contract version lives in `docs/.sprint-loop-book` beside the schema
version:

```text
schema-version: 2
substrate-version: 3
```

A Book with no `substrate-version` line is contract version 1, and every helper
reads it exactly as it did before the stamp existed — so an un-converged project
keeps behaving identically until it converges. A Book stamped *ahead* of the
running bundle is refused rather than downgraded; update the bundle instead.

Preview without writing anything:

```bash
bash scripts/deploy-substrate.sh --check
```

From Claude Code, `/sprint-loop:sprint-loop upgrade` runs the check and the
convergence and reports the resulting state without starting a sprint. Each
sprint records the bundle that ran it in `sprint-meta.md`, from the bundle's own
`scripts/bundle-version.sh`; the plugin cache pins a commit, so run
`/plugin update sprint-loop` to pick up a newly merged bundle before the next
sprint.

## One sprint per turn, one titled checkpoint per sprint

From substrate contract version 3, the turn and checkpoint contract is
mechanical rather than advisory:

| Rule | What enforces it |
| --- | --- |
| A checkpoint belongs to a finished sprint | `remote-adapter.sh open-pr` refuses unless the router reports `ready-for-next-sprint` |
| Checkpoints are titled `Sprint <N>: <description>` | the title is composed from the sprint record's `Summary`; a supplied title must match that shape or it is refused |
| Phase evidence means committed evidence | `check-tracked.sh`, called by `finalize-plan.sh` and `close-sprint.sh` |
| Sprints happen on the work branch | `commit-task.sh` and `close-sprint.sh` refuse from any other branch, and the substrate gate reports `substrate-misplaced:<head>-><work>` before routing |

Each gate binds only at or above the contract version that introduced it, so a
project that has not converged behaves exactly as it did before. The
`Checkpoint` field in the sprint record holds the opened URL, committed with the
close, so a later sprint can tell its own checkpoint from the previous one.

## Branch model and checkpoints

Sprint Loops uses a small, long-lived branch topology declared per project in a
[remote profile](open-harnesses/schemas/remote-profile.md)
(`docs/work/remote-profile.md`):

| Branch | Role |
| --- | --- |
| `main` | The official corpus. Reached only by a reviewed pull/merge request. |
| `dev` | Where sprints commit and push at any time. |

The skill never creates a per-sprint branch. Each sprint opens **exactly one
`dev → main`** pull/merge request as a reversible checkpoint, and — because the
remote profile's `mergePolicy` defaults to `human-approve` — it stops there for
a person to approve the merge. After `main` advances, `sync-work-branch.sh`
brings it back into `dev` at the sprint boundary so `dev` inherits everything on
the corpus. The provider is resolved from the profile: `github` drives `gh`,
`gitlab` drives `glab`, and any other remote falls back to pushing `dev` and
printing the compare URL, so the model works on every host.

## Dependency updates on `work`

Scheduled dependency-version updates use the same integration path as every
other sprint. The updater (Dependabot or Renovate) opens a PR/MR against the
profile's `work` branch (`dev` here); opening that request does not mutate
`work`. Handle updater intake only between sprints, before new sprint writes
begin:

1. If the updater PR is current and green in CI, merge it into `work` when the
   remote profile authorizes the merge.
2. If it is red, leave it unmerged and repair its PR head until green.
3. If the provider prevents repairing that head, run an ordinary
   dependency-only sprint that reproduces and fixes the update on `work`, then
   supersede the unmergeable updater PR.
4. The accepted update rides the next ordinary `work → base` sprint checkpoint
   (`dev → main` here). It uses the same plans, evidence, tests, and PR as any
   other sprint—there is no dependency checkpoint or sprint subtype.

Project CI must run for PRs targeting `work`; this repository's guard workflow
covers both `dev` and `main` PR bases.

**Sprint 0 deploy scaffolds the updater config create-if-absent:** GitHub gets
`.github/dependabot.yml` with `target-branch` set to `work`; GitLab and generic
hosts get `renovate.json` using Renovate's current `baseBranchPatterns` option;
`local-only` gets no hosted-updater file. Existing configs are never clobbered.
This repository's [Dependabot configuration](.github/dependabot.yml) targets
`dev`; add ecosystems (`npm`, `pip`, `cargo`, …) beside `github-actions` as the
project grows.

GitHub has one provider-level exception: Dependabot security-update PRs target
the default branch even when scheduled version updates use `target-branch`
([GitHub options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#target-branch)).
After an authorized security update reaches `main`, run
`sync-work-branch.sh` at the boundary so `dev` inherits it. This host constraint
does not create another Sprint Loops branch or sprint type.

## Verify this repository

Run the canonical suite from the repository root:

```bash
bash tools/run-guards.sh --determinism
```

## License

[MIT](LICENSE) © 2026 Charles Russella.
