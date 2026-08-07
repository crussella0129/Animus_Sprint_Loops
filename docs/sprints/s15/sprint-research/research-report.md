# Sprint 15 Research Report

## Intents Reviewed
- [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) — created; relevance: this sprint's whole goal (the substrate/branch/checkpoint layer); current state: `proposed`.
- [INT-0001](../../../intents/INT-0001-project-book.md) — selected (context); relevance: the substrate is layered on the realized Book v2 authority and its path/validation helpers; current state: `realized`, unchanged.

## 1. Sprint Goal
Install a first-class **substrate layer** in the Sprint Loops skill so branch
topology, Sprint 0 bootstrap, and remote checkpoints stop being reinvented per
project. Concretely: a deterministic substrate gate that runs before phase
routing and, when the substrate is absent, runs a skill-owned Sprint 0 deploy; a
long-lived `main`/`dev`/`bump` branch model with **no per-sprint branches**; and
a provider-agnostic **one-PR/MR-per-sprint** `dev→main` checkpoint that stops for
a human to approve the merge. Bounded by INT-0002; the GECK launcher rewrite is
explicitly out of scope.

## 2. Existing Code Survey
| File | Relevance | Notes |
|------|-----------|-------|
| `claude-code/skills/sprint-loop/scripts/init-sprint.sh` | high | Scaffolds the Book + next sprint; creates **no branches** — Sprint 0 deploy is the new sibling |
| `.../scripts/book-paths.sh` | high | Side-effect-free path + `book_layout_state` (book/legacy/none) contract; the substrate check mirrors this style |
| `.../scripts/current-phase.sh` | high | Artifact-derived phase router; substrate gate must compose in *front* of it, not replace it |
| `.../scripts/current-sprint.sh` | medium | Sprint-number resolver used across helpers |
| `.../scripts/check-book.sh` | medium | Book validator the substrate check reuses for the Book leg |
| `.../scripts/close-sprint.sh` | medium | Local sprint close; the Loop remote-checkpoint step wraps around this |
| `.../scripts/migrate-to-book.sh` | high | Transactional, verified, rollback-safe pattern to model `deploy-substrate.sh` on |
| `.../phases/01-init-sprint.md` | high | Only scaffolds the Book — no substrate/branch/gate; edit target |
| `.../phases/06-loop-phase.md` | high | Closes with local commits; defers all remote action to SKILL.md; **no PR/MR logic**; edit target |
| `.../phases/04-build-phase.md` | medium | Pre-flight mentions "if on a feature branch, rebase origin/<base>" — the only branch hint today |
| `.../SKILL.md` (line 82) | high | Sole remote/branch line: "explicit request or a declared preauthorized-remote profile" — the hook we give a schema |
| `tools/run-guards.sh` | high | Canonical deterministic suite; new substrate/deploy/profile suites register here |
| `tools/check-bundle-sync.sh` | high | Parity map; every new shared script must be added and byte-synced ×4 |
| `tools/check-adapter-semantics.sh` | medium | Semantic guard; branch/remote-authority prose per adapter |
| `docs/work/tasks.md` (T-109) | medium | Prior articulation of the dev-branch model — superseded and absorbed by INT-0002 |
| `antigravity-ide/global_workflows/sprint-loops.md` | medium | Antigravity adapter needs the substrate mapping too (parity) |
| `codex-cli/skills/sprint-loops/SKILL.md` | medium | Codex adapter remote-authority boundary; parallel edit |

## 3. External Sources
- [GitHub CLI — `gh pr`](https://cli.github.com/manual/gh_pr) — GitHub provider adapter (create/view/merge PRs; idempotency via `gh pr list --head`).
- [GitLab CLI — `glab mr`](https://gitlab.com/gitlab-org/cli) — GitLab provider adapter (create/view merge requests).
- [Dependabot — automated dependency updates](https://docs.github.com/en/code-security/dependabot) — defines `bump`-branch push behavior and the compat-fix workflow.
- [A successful Git branching model (Driessen)](https://nvie.com/posts/a-successful-git-branching-model/) — reference for the long-lived integration (`dev`) → release (`main`) topology, adapted (no per-sprint branches).

## 4. Risks, Unknowns, Dependencies
- **Risk — dogfood retrofit:** this repo is 15 sprints of `main`-only history; imposing `dev`/`bump` on it could disturb in-flight state. Mitigation: build+test on fixtures first, then retrofit this repo as a discrete, verified step (the T-119 pattern).
- **Risk — provider CLI availability:** `gh`/`glab` may be absent or unauthenticated; the generic fallback must degrade to "push + print the compare/PR URL" and never hard-fail the loop.
- **Risk — substrate false-negative:** a valid local-only or `bump`-less project must not be judged "absent." The gate needs a `local-only` profile mode and an explicit `bump: optional`.
- **Risk — 1-PR idempotency across providers:** re-running Loop must detect an already-open `dev→main` PR/MR (by head/branch) rather than open a second; the detection has to work per provider.
- **Unknown — remote-profile schema + location:** a tracked Book file vs. an extension of the `.sprint-loop-book` marker vs. `docs/work/remote-profile.*`. (Decide in Plan.)
- **Unknown — gate composition:** wrapper that the harness calls first vs. folding the check into `current-phase.sh`'s front. Leaning wrapper to keep the phase router pure.
- **Dependency — parity + determinism:** any new shared script must pass `check-bundle-sync` (×4 byte-identical) and register deterministically in `run-guards`; tests must stub `gh`/`glab`/git identity (no network in CI).

## 5. Recommended Approach
**Primary:** add a dedicated substrate layer as new shared scripts, mirroring the
Book v2 arc (contract → helpers → phase rewire → guard registration → dogfood):
- `check-substrate.sh` — composes `book_layout_state` (Book leg) + ledger presence
  + branch presence (`main`/`dev`, `bump` if profile-enabled) + a resolvable
  remote profile → prints `substrate-complete | substrate-absent | substrate-partial:<diagnostic>`.
- `deploy-substrate.sh` — idempotent Sprint 0 bootstrap modeled on
  `migrate-to-book.sh`'s transactional/rollback style: create Book, branches,
  ledgers, remote profile, and the first sprint; re-run is a no-op.
- `remote-profile.sh` — resolve/validate a profile (provider, base/work/bump
  branch names, merge policy) and dispatch to a provider adapter.
- Provider adapters — `gh` (GitHub), `glab` (GitLab), and a generic
  push-and-print-URL fallback, behind one thin `open_sprint_pr` / `pr_exists`
  interface.
- A dev↔main **boundary resync** helper (post-merge `main→dev`), the mechanism
  that lets `dev` inherit `bump` fixes without a second writer.

Then rewire docs: `01-init-sprint.md` runs the substrate gate first (→ Sprint 0
deploy when absent); a new Sprint 0/bootstrap phase doc owns the deploy; rewrite
`06-loop-phase.md` to open exactly one `dev→main` PR/MR via the profile and
**stop for human approval**; update `SKILL.md` (line 82) and the Codex/Antigravity
adapters to reference the profile schema. Register substrate/deploy/profile/
provider tests in `run-guards.sh`, add the scripts to `check-bundle-sync.sh`, and
propagate byte-identically across the four bundles. Test-first with fixtures
(substrate complete/absent/partial; idempotent deploy; no-per-sprint-branch
invariant; single-PR idempotency; stubbed provider dispatch; `dev`-single-writer
race-safety), then dogfood-retrofit this repository.

**Recommended profile location:** a tracked Book file validated by
`check-book`/`check-substrate`, keeping remote config inside the single Book
authority rather than a root dotfile (confirm exact form in Plan).

**Alternative considered:** fold branch/remote side effects into the existing
`init-sprint.sh`/`close-sprint.sh` rather than dedicated scripts. Rejected — it
entangles the pure, artifact-derived phase router with git/network side effects
and is far harder to test in isolation. A separate, composable substrate layer
matches the existing helper design and parity/determinism guards.

## Artifacts
- [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) — the stable
  intent chapter of record (semantic authority for this sprint).
- No separate code artifacts this phase; the code survey above is drawn from the
  live skill bundles.
