Finalized - DO NOT EDIT

# Sprint 15 Build Plan

Advances [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) —
the Sprint Loops substrate layer (bootstrap gate, branch model, provider-agnostic
checkpoints).

## Schema Tree

- Substrate layer for Sprint Loops
  - Remote contract
    - T-122: Remote-profile schema + resolver
    - T-125: Provider adapters + one-PR/MR-per-sprint
  - Substrate lifecycle
    - T-123: Deterministic substrate check
    - T-124: Sprint 0 deploy (idempotent bootstrap)
    - T-126: Boundary work-branch resync
  - Protocol + guards
    - T-127: Phase & adapter documentation rewiring
    - T-128: Guard registration + cross-bundle parity
  - Dogfood
    - T-129: Retrofit this repository onto the substrate

## Execution Sequence

### T-122: Define the remote-profile schema and its resolver
- **Touches:** `{4 bundles}/scripts/remote-profile.sh` (new), a profile schema doc under shared `schemas/`, `{4 bundles}/scripts/remote-profile.test.sh` (new)
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** a project declares a remote profile, **THEN** `remote-profile.sh` **SHALL** resolve exact `provider`, `base`, `work`, `bump` (or `none`), and `mergePolicy` fields from one Book-tracked source.
  - **WHEN** the profile is missing, malformed, or names an unknown provider, **THEN** resolution **SHALL** fail with a specific diagnostic and non-zero status.
  - **WHEN** `provider` is `local-only`, **THEN** the profile **SHALL** validate with no remote requirement beyond `base`/`work`, and `mergePolicy` **SHALL** default to `human-approve` when unset.
- **Notes:** Recommend `docs/work/remote-profile.md` with a fenced `key: value` block. Keep POSIX-portable; no network.

### T-123: Deterministic substrate check in front of routing
- **Touches:** `{4 bundles}/scripts/check-substrate.sh` (new), `{4 bundles}/scripts/check-substrate.test.sh` (new)
- **Depends on:** T-122
- **Success criterion (EARS):**
  - **WHEN** Book, ledgers, the `base`/`work` branches (and `bump` if enabled), and a resolvable profile all exist, **THEN** `check-substrate.sh` **SHALL** print `substrate-complete` and exit 0.
  - **WHEN** no substrate exists, **THEN** it **SHALL** print `substrate-absent` and exit non-zero.
  - **WHEN** substrate is partial (Book without branches, branches without profile, missing ledger, …), **THEN** it **SHALL** print `substrate-partial:<diagnostic>` naming the missing element and exit non-zero.
  - **WHEN** invoked, it **SHALL** make no repository mutation, and `current-phase.sh` **SHALL** remain byte-unchanged.
- **Notes:** Compose `book_layout_state`/`check-book` for the Book leg; resolve branches via `git rev-parse --verify` / `git show-ref`.

### T-124: Idempotent Sprint 0 deploy
- **Touches:** `{4 bundles}/scripts/deploy-substrate.sh` (new), `{4 bundles}/scripts/deploy-substrate.test.sh` (new), reuses `init-sprint.sh`
- **Depends on:** T-122, T-123
- **Success criterion (EARS):**
  - **WHEN** `deploy-substrate.sh` runs in an empty or Book-less project with a chosen profile, **THEN** it **SHALL** create Book + ledgers + `main`/`dev`/(optional `bump`) branches + profile + first sprint such that `check-substrate.sh` reports `substrate-complete`.
  - **WHEN** it is re-run on an already-complete substrate, **THEN** it **SHALL** make no changes (idempotent no-op).
  - **WHEN** any step fails or a signal interrupts it before commit, **THEN** it **SHALL** roll back, leaving no partial substrate and no orphaned branches.
  - **WHEN** a conflicting or legacy layout is present, **THEN** it **SHALL** refuse with a diagnostic instead of overwriting.
- **Notes:** Model the transactional/rollback discipline on `migrate-to-book.sh`. Create branches only when absent; never force-update an existing branch.

### T-125: Provider adapters and one PR/MR per sprint
- **Touches:** `{4 bundles}/scripts/remote-adapter.sh` (new), `{4 bundles}/scripts/remote-adapter.test.sh` (new)
- **Depends on:** T-122
- **Success criterion (EARS):**
  - **WHEN** a sprint closes with a non-`local-only` profile and no open checkpoint exists, **THEN** the adapter **SHALL** open exactly one `work→base` PR/MR via the profile's provider (`gh`|`glab`).
  - **WHEN** an open `work→base` PR/MR already exists for the current head, **THEN** the adapter **SHALL** detect it and refuse to open a second.
  - **WHEN** the provider CLI is absent or unauthenticated, **THEN** the adapter **SHALL** fall back to pushing `work` and printing the compare/PR URL without hard-failing.
  - **WHEN** `mergePolicy` is `human-approve`, **THEN** the adapter **SHALL NOT** merge; it **SHALL** leave the PR/MR open and surface it.
- **Notes:** One `open_sprint_pr`/`sprint_pr_exists` interface; providers are pure dispatch. Tests stub `gh`/`glab` on `PATH` (no network).

### T-126: Boundary work-branch resync
- **Touches:** `{4 bundles}/scripts/sync-work-branch.sh` (new), `{4 bundles}/scripts/sync-work-branch.test.sh` (new)
- **Depends on:** T-122
- **Success criterion (EARS):**
  - **WHEN** `base` has advanced and `sync-work-branch.sh` runs at a sprint boundary, **THEN** it **SHALL** bring every `base` commit into `work` (fast-forward or merge).
  - **WHEN** the working tree or index is dirty, **THEN** it **SHALL** refuse with a diagnostic and change nothing.
  - **WHEN** it runs, **THEN** it **SHALL** write only `work`, never `base`, preserving `base` as the single confluence.
- **Notes:** This is the mechanism by which `dev` inherits `bump` fixes without a second writer.

### T-127: Rewire phase and adapter documentation
- **Touches:** `{claude,codex}` `phases/01-init-sprint.md`, `phases/06-loop-phase.md`, a new bootstrap phase doc; `{4 bundles}/SKILL.md`; `antigravity-ide/global_workflows/sprint-loops.md`; `open-harnesses/particles/*`
- **Depends on:** T-123, T-124, T-125, T-126
- **Success criterion (EARS):**
  - **WHEN** an agent reads the Init phase, **THEN** it **SHALL** run the substrate gate first and route to Sprint 0 deploy on `substrate-absent`.
  - **WHEN** an agent reads the Loop phase, **THEN** it **SHALL** open exactly one `work→base` PR/MR via the profile and stop for human approval, with no auto-merge and no per-sprint branch.
  - **WHEN** any adapter or `SKILL.md` describes remote/branch behavior, **THEN** it **SHALL** reference the remote-profile schema and the substrate gate, and **SHALL NOT** instruct per-sprint branch creation.
- **Notes:** Keep shared content byte-identical where parity requires; adapter-native mechanics (Claude plan mode, etc.) stay local.

### T-128: Register guards and enforce cross-bundle parity
- **Touches:** `tools/{run-guards.sh,check-bundle-sync.sh,check-adapter-semantics.sh,check-adapter-semantics.test.sh}`, `{4 bundles}/scripts/*` (propagation)
- **Depends on:** T-122, T-123, T-124, T-125, T-126, T-127
- **Success criterion (EARS):**
  - **WHEN** the canonical suite runs, **THEN** it **SHALL** execute the substrate, deploy, profile, provider, and resync test suites alongside the existing Book/parity/adapter/shellcheck suites, registered consistently in `SUITES`, `suite_cmd`, and `suite_script_hash`.
  - **WHEN** a new shared substrate script is missing, extra, or byte-divergent across bundles, **THEN** `check-bundle-sync.sh` **SHALL** fail with the specific asset mismatch.
  - **WHEN** an adapter reintroduces per-sprint-branch or auto-merge-to-`main` prose, or omits the profile reference, **THEN** `check-adapter-semantics.sh` **SHALL** fail.
  - **WHEN** the suite runs twice with `--determinism`, **THEN** normalized evidence **SHALL** be identical.
- **Notes:** Propagate every new script byte-identically ×4; extend the shellcheck target set to the new scripts.

### T-129: Dogfood — retrofit this repository onto the substrate
- **Touches:** `docs/work/remote-profile.md` (new), repository branches (`dev`, optional `bump`), `.gitignore` if needed
- **Depends on:** T-124, T-127, T-128
- **Success criterion (EARS):**
  - **WHEN** this repository is retrofitted, **THEN** it **SHALL** gain a `dev` branch (and optional `bump`) and a declared `docs/work/remote-profile.md` such that `check-substrate.sh` reports `substrate-complete`.
  - **WHEN** the retrofit completes, **THEN** a pre/post inventory **SHALL** show only the intended additions (profile + branches), with the Book and existing history unchanged.
  - **WHEN** routing is checked after retrofit, **THEN** `current-phase.sh` **SHALL** be unaffected.
- **Notes:** Analogous to T-119's Book dogfood; preserve history, add nothing unintended.
