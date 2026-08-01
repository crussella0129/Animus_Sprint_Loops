Finalized - DO NOT EDIT

# Sprint 14 Build Plan

## Schema Tree

- Book-centered Sprint Loops protocol
  - Canonical Book model
    - T-110: Define the Book schema, paths, lifecycle, and validator
    - T-111: Initialize and route fresh projects through the Book
    - T-112: Migrate legacy project state without split-brain writes
  - Shared workflow
    - T-113: Rewire runtime helpers and state gates to Book evidence
    - T-114: Rewrite shared phase, schema, prompt, and particle contracts
  - Harness adapters
    - T-115: Refactor Codex for current GPT-5.6/Codex behavior
    - T-116: Align Claude and Antigravity adapter semantics
    - T-117: Consolidate root and bundle operator documentation
    - T-118: Extend parity policy for the Book core and divergent adapters
  - Dogfood and proof
    - T-119: Migrate this repository into its own Book
    - T-120: Register and harden canonical Book verification

## Execution Sequence

### T-110: Define the shared Book contract and its structural validator
- **Touches:** `{claude-code,codex-cli,antigravity-ide}/skills/sprint-loop*/schemas/intent.md`, `open-harnesses/schemas/intent.md`, `{4 bundles}/scripts/book-paths.sh`, `{4 bundles}/scripts/check-book.sh`
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** a project uses Sprint Loops v2, **THEN** every harness **SHALL** resolve `docs/`, `docs/intents/`, `docs/work/`, and `docs/sprints/` through one byte-identical path contract.
  - **WHEN** an intent chapter declares `planned`, `active`, `deferred`, or `realized`, **THEN** the validator **SHALL** require the corresponding work or realization evidence defined by the shared schema.
  - **WHEN** duplicate intent IDs, malformed state metadata, missing evidence, or conflicting Book/legacy layouts exist, **THEN** validation **SHALL** fail with a specific diagnostic.
- **Notes:** Keep the Book human-readable Markdown and mdBook-compatible. `SUMMARY.md` is navigation, not a second state store. Preserve POSIX shell portability.

### T-111: Make fresh initialization and phase routing Book-native
- **Touches:** `{4 bundles}/scripts/init-sprint.sh`, `{4 bundles}/scripts/current-sprint.sh`, `{4 bundles}/scripts/current-phase.sh`, `{4 bundles}/scripts/selftest.sh`
- **Depends on:** T-110
- **Success criterion (EARS):**
  - **WHEN** `init-sprint.sh` runs in a project with no Sprint Loops state, **THEN** it **SHALL** create a tracked `docs/` Book, stable navigation, intent/work directories, and the next sprint beneath `docs/sprints/` without creating root authorities.
  - **WHEN** a valid Book-only sprint advances through artifact states, **THEN** `current-phase.sh` **SHALL** derive the same Research → Plan → Build → Test → Loop transitions across every bundle.
  - **WHEN** `.gitignore` already contains project content, **THEN** initialization **SHALL** preserve it and ignore only transient/generated data, never the Book.
  - **WHEN** Book scaffolding already exists and initialization creates a later sprint, **THEN** initialization **SHALL** preserve existing Book content without duplicating navigation or schema markers.
- **Notes:** Retain artifact-derived phase state. Do not introduce a writable `phase.txt`.

### T-112: Add a lossless, idempotent legacy-to-Book migration
- **Touches:** `{4 bundles}/scripts/migrate-to-book.sh`, `{4 bundles}/scripts/selftest.sh`, migration guidance in shared schemas
- **Depends on:** T-110, T-111
- **Success criterion (EARS):**
  - **WHEN** only legacy `sprints/`, `agent-tasks/`, `decisions.md`, or `confidence.txt` state exists, **THEN** migration **SHALL** preserve it beneath `docs/`, record provenance, and leave one writable Book authority.
  - **WHEN** the migration is rerun after success, **THEN** it **SHALL** be idempotent and make no duplicate records.
  - **WHEN** both legacy and Book layouts contain conflicting writable state, **THEN** migration and routing **SHALL** stop with a split-brain diagnostic instead of choosing silently.
  - **WHEN** a resolved legacy source or Book target escapes the project root, traverses an alias, or uses a symlinked state directory, **THEN** migration **SHALL** refuse before mutating any source.
- **Notes:** Preserve legacy decisions as non-authoritative history. Do not use symlinks.

### T-113: Rewire runtime helpers and hard gates to Book evidence
- **Touches:** `{4 bundles}/scripts/{abort-sprint,commit-task,finalize-plan,research-budget,update-confidence}.sh`, `{4 bundles}/scripts/selftest.sh`
- **Depends on:** T-110, T-111, T-112
- **Success criterion (EARS):**
  - **WHEN** a plan is finalized, **THEN** the helper **SHALL** validate intent review, research budget, non-empty tasks, and critic verdict under Book paths before atomically locking both plans.
  - **WHEN** a task completes or a sprint aborts/closes, **THEN** helpers **SHALL** update only Book ledgers and preserve the existing exact-match, first-target, timestamp, and commit-evidence safety properties.
  - **WHEN** an old ADR review heading is present without the required intent review, **THEN** finalization **SHALL** reject it with migration guidance.
- **Notes:** Validate all plan preconditions before mutating either plan; preserve macOS/BSD portability.

### T-114: Rewrite the harness-neutral protocol around intent and evidence
- **Touches:** shared `phases/`, `schemas/`, `prompts/`, and `open-harnesses/particles/` content across all bundles
- **Depends on:** T-110, T-113
- **Success criterion (EARS):**
  - **WHEN** any harness reads the shared protocol, **THEN** it **SHALL** treat `docs/` as the Book, intent chapters as semantic authority, sprint records as provenance, and views/navigation as non-authoritative.
  - **WHEN** Research, Plan, Build, Test, or Loop exits, **THEN** its contract **SHALL** name the required Book evidence and valid next transition without relying on ADRs or legacy root paths.
  - **WHEN** a decision is made, **THEN** the protocol **SHALL** record rationale, alternatives, consequences, and history in the relevant stable intent rather than append a separate ADR.
- **Notes:** Keep shared content byte-identical where parity policy says it is shared.

### T-115: Refactor the Codex adapter into lean, current, authority-aware guidance
- **Touches:** `codex-cli/skills/sprint-loops/SKILL.md`, `AGENTS.md.fragment`, Codex-divergent phase files, `codex-cli/install.sh`, `codex-cli/README.md`
- **Depends on:** T-114
- **Success criterion (EARS):**
  - **WHEN** Codex activates `$sprint-loops`, **THEN** the skill **SHALL** route with resolved skill paths and every Codex phase **SHALL** expose explicit `## Outcome`, `## Inputs`, `## Authority`, and `## Exit evidence` sections without instructing the agent to invoke `/plan` or change its own permission mode.
  - **WHEN** parallel work is useful in a shared workspace, **THEN** Codex guidance **SHALL** favor bounded read/review subagents and one integrating writer unless isolated worktrees are explicit.
  - **WHEN** work would push, merge, release, force-push, delete, or materially expand scope, **THEN** the adapter **SHALL** require explicit request or a declared preauthorized-remote profile.
  - **WHEN** the Codex bundle is installed, **THEN** documentation and scripts **SHALL** use current `.agents/skills` discovery and provide Windows as well as POSIX instructions.
  - **WHEN** one Codex skill installation is reloaded, **THEN** `$sprint-loops` **SHALL** expose one skill surface, activate for direct sprint intent, and not activate solely because unrelated documentation exists.
- **Notes:** State each invariant once. README is operator/install documentation; AGENTS is only a durable Book/skill pointer.

### T-116: Align Claude and Antigravity adapter semantics with the shared Book
- **Touches:** `claude-code/skills/sprint-loop/SKILL.md`, Claude-divergent phase files, `antigravity-ide/global_workflows/sprint-loops.md`
- **Depends on:** T-114, T-115
- **Success criterion (EARS):**
  - **WHEN** a user switches among supported harnesses, **THEN** each adapter **SHALL** read the same Book/state contract while retaining only its genuine orchestration differences.
  - **WHEN** Antigravity synchronizes `implementation_plan.md`, `task.md`, and `walkthrough.md`, **THEN** it **SHALL** map them respectively to unrealized intent/planning, work state, and realization evidence.
- **Notes:** Keep Claude-only plan/recurrence primitives and Antigravity-native artifacts adapter-local.

### T-117: Consolidate repository and bundle operator documentation
- **Touches:** root `README.md`, `ROADMAP.md`, bundle READMEs
- **Depends on:** T-115, T-116
- **Success criterion (EARS):**
  - **WHEN** a reader opens root or bundle documentation, **THEN** it **SHALL** identify `docs/` as the canonical Book, link to the shared contract, and avoid reproducing a second full protocol.
  - **WHEN** installation or operation differs by harness or operating system, **THEN** its bundle README **SHALL** document only that adapter-specific setup with current paths and commands.
- **Notes:** Convert roadmap material to Book intent during dogfood migration; leave this task focused on operator-facing documentation structure.

### T-118: Extend parity policy for the Book core and divergent adapters
- **Touches:** `tools/check-bundle-sync.sh`, `tools/check-bundle-sync.test.sh`, semantic adapter guard and fixtures
- **Depends on:** T-114, T-116, T-117
- **Success criterion (EARS):**
  - **WHEN** a shared Book asset is missing, extra, or byte-divergent, **THEN** the parity guard **SHALL** fail with the specific asset mismatch.
  - **WHEN** an intentionally divergent adapter reintroduces active legacy authority or omits the Book schema version, **THEN** a semantic guard **SHALL** fail without requiring adapter byte identity.
- **Notes:** Preserve bundle self-containment; clarify that a physical comparison source is not semantic ownership by a vendor adapter.

### T-119: Dogfood the new architecture by migrating this repository into its Book
- **Touches:** `docs/**`, legacy root state pointers/removals, `.gitignore`
- **Depends on:** T-112, T-114, T-117, T-118
- **Success criterion (EARS):**
  - **WHEN** this repository is migrated, **THEN** `docs/` **SHALL** contain its sprint history, work ledgers, legacy rationale, and an `INT-0001` chapter for the Book architecture with valid unrealized/realized evidence links.
  - **WHEN** legacy root authority paths are inspected after migration, **THEN** they **SHALL** be absent or unambiguous read-only pointers and shall not permit split writes.
  - **WHEN** ignored historical sprint files are considered for tracking, **THEN** the migration **SHALL** inspect them for unsafe/generated content before adding them.
  - **WHEN** the repository migration completes, **THEN** a pre/post inventory with content hashes **SHALL** prove one-to-one preservation or explicitly document every intentional exclusion.
- **Notes:** Preserve history; do not claim pre-migration sprint immutability.

### T-120: Register Book verification in the canonical deterministic guard suite
- **Touches:** `tools/run-guards.sh`, Book/migration fixture tests, `.github/workflows/ci.yml` only if registration requires it
- **Depends on:** T-113, T-118, T-119
- **Success criterion (EARS):**
  - **WHEN** the canonical suite runs locally or in CI, **THEN** it **SHALL** execute Book validation, migration/routing selftests, bundle parity, Codex semantic checks, shellcheck, and determinism confirmation.
  - **WHEN** a fixture breaks an intent link, duplicates an ID, creates split-brain state, weakens Codex authority boundaries, or reintroduces legacy authority prose, **THEN** the relevant negative test **SHALL** fail for the expected diagnostic.
  - **WHEN** the suite is run twice with `--determinism`, **THEN** normalized confirmation evidence **SHALL** be identical.
- **Notes:** Register every suite consistently in the suite list, command dispatcher, and evidence hash.
