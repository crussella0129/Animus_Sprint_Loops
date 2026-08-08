Finalized - DO NOT EDIT

# Sprint 16 Build Plan

## Intents
- [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) — state:
  `planned`; acceptance criteria covered: strict two-branch profile/substrate,
  hosted updater targeting `work`, boundary-only green intake, one ordinary
  `work → base` checkpoint, repository migration, and regression enforcement.

## Schema Tree
- One sprint path for dependency updates
  - Contract
    - T-130: strict remote-profile v2
  - Runtime behavior
    - T-131: two-branch substrate and work-targeted updater scaffold
    - T-132: one checkpoint path and boundary intake protocol
  - Dogfood
    - T-133: repository profile, Dependabot, CI, Actions, and operator guide
  - Enforcement
    - T-134: active-surface and cross-bundle regression guards
  - Delivery
    - T-135: transactional Codex reinstall and installed-source verification

## Pre-Build Gate
Before T-130 starts, commit the finalized Research/Plan artifacts, fast-forward
the local `main` ref to `origin/main`, run the installed
`sync-work-branch.sh`, and require `git merge-base --is-ancestor main dev` with
a clean tracked tree. This imports PR #9's merge topology before Sprint 16
implementation commits, so the eventual checkpoint diff begins at the actual
remote base. No task may start until `test_pre_build_sync` passes.

## Execution Sequence

### T-130: Replace the remote-profile contract with strict v2
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- **Touches:** `{4 bundles}/schemas/remote-profile.md`, `{4 bundles}/scripts/remote-profile.sh`, `{4 bundles}/scripts/remote-profile.test.sh`
- **Depends on:** (none)
- **Acceptance criterion:** The remote profile has exactly provider/base/work/mergePolicy and carries no third long-lived branch.
- **Success criterion (EARS):**
  - **WHEN** a valid v2 profile is resolved, **THEN** `remote-profile.sh` **SHALL** emit only `PROVIDER`, `BASE`, `WORK`, and `MERGEPOLICY` values and support only those field queries.
  - **WHEN** a profile carries an earlier marker or any unknown key, **THEN** the resolver **SHALL** reject it with a specific migration or unknown-field diagnostic instead of silently retaining stale topology.
  - **WHEN** a caller requests any field outside `provider`, `base`, `work`, or `mergePolicy`, **THEN** the resolver **SHALL** reject that field query with an exact supported-field diagnostic.
  - **WHEN** the contract and fixtures are propagated, **THEN** all four bundle copies **SHALL** be byte-identical.
- **Notes:** Use marker `sprint-loop-remote-profile-v2`; preserve provider and merge-policy validation/defaults.

### T-131: Reduce substrate deploy to base/work and target updater PRs at work
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- **Touches:** `{4 bundles}/scripts/check-substrate.sh`, `{4 bundles}/scripts/check-substrate.test.sh`, `{4 bundles}/scripts/deploy-substrate.sh`, `{4 bundles}/scripts/deploy-substrate.test.sh`
- **Depends on:** T-130
- **Acceptance criterion:** Sprint 0 creates only base/work and hosted updater scaffolds target work without clobbering project configuration.
- **Success criterion (EARS):**
  - **WHEN** substrate completeness is checked for a valid profile, **THEN** `check-substrate.sh` **SHALL** require exactly the configured `base` and `work` refs and remain read-only.
  - **WHEN** deploy runs for `github`, `gitlab`, or `generic` with `work: dev`, **THEN** it **SHALL** create only `main` and `dev` and create an absent updater config targeting `dev` (`target-branch` or `baseBranchPatterns`).
  - **WHEN** deploy runs for `local-only` or finds an existing updater config, **THEN** it **SHALL** create no updater config or leave the existing file byte-unchanged, respectively.
  - **WHEN** an injected deploy failure occurs, **THEN** rollback **SHALL** remove only artifacts created by that transaction, preserve every pre-existing file/ref/config byte-for-byte, and leave no extra branch or updater file.
- **Notes:** Rebind provider/work/mergePolicy from the resolved profile before choosing scaffolding behavior; remove retired CLI flags instead of preserving compatibility aliases.

### T-132: Enforce one checkpoint path and boundary-only dependency intake
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- **Touches:** `{4 bundles}/scripts/remote-adapter.sh`, `{4 bundles}/scripts/remote-adapter.test.sh`, `{4 bundles}/scripts/sync-work-branch.sh`, `{claude,codex}/phases/01-init-sprint.md`, `{claude,codex}/phases/06-loop-phase.md`, `open-harnesses/particles/08-loop-phase.md`, `antigravity-ide/global_workflows/sprint-loops.md`
- **Depends on:** T-130
- **Acceptance criterion:** Updater PRs are boundary-gated input to work; the adapter opens only the ordinary work-to-base sprint checkpoint.
- **Success criterion (EARS):**
  - **WHEN** `remote-adapter.sh open-pr` runs, **THEN** it **SHALL** derive its head only from profile `work` and open/detect at most one `work → base` PR/MR.
  - **WHEN** an open `work → base` checkpoint already exists, **THEN** the adapter **SHALL** report it and open no second PR/MR.
  - **WHEN** a caller supplies the retired head-override option, **THEN** the adapter **SHALL** reject it as an unknown argument and open no checkpoint.
  - **WHEN** an agent reads an active Init/operator contract, **THEN** it **SHALL** merge updater intake only at a sprint boundary when current and green, keep red intake unmerged while it is repaired until green, and avoid intake during an active sprint.
  - **WHEN** a red updater head cannot be repaired on its provider branch, **THEN** the active contract **SHALL** require an ordinary dependency-only sprint to reproduce and fix the update on `work` and supersede the unmergeable updater PR without introducing a checkpoint subtype.
  - **WHEN** base advances after a sprint merge, **THEN** `sync-work-branch.sh` **SHALL** make the advanced base an ancestor of work while leaving the base ref unchanged and using no dependency-branch-specific semantics.
- **Notes:** Ephemeral bot PR heads remain ordinary provider artifacts; the removed override was a protocol-level checkpoint escape hatch.

### T-133: Dogfood the consolidated model in this repository
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- **Touches:** `docs/work/remote-profile.md`, `.github/dependabot.yml`, `.github/workflows/ci.yml`, `README.md`
- **Depends on:** T-131, T-132
- **Acceptance criterion:** This repository targets version-update PRs at dev, runs CI for them, preserves the two Actions updates, and documents one ordinary sprint path.
- **Success criterion (EARS):**
  - **WHEN** this repository's live profile is resolved, **THEN** it **SHALL** use the v2 marker and declare only `github`, `main`, `dev`, and `human-approve` values.
  - **WHEN** Dependabot opens a scheduled version-update PR, **THEN** `.github/dependabot.yml` **SHALL** target `dev` and use dependency-neutral commit wording.
  - **WHEN** a PR targets `dev` or `main`, **THEN** the guards workflow **SHALL** run; its checkout and artifact-upload steps **SHALL** retain the v7 changes proven by merged PRs #7/#8.
  - **WHEN** an operator reads the root README, **THEN** it **SHALL** see exactly `main`/`dev`, the green-at-boundary intake rule, the GitHub security-update caveat, and no dependency checkpoint/sprint subtype.
- **Notes:** Reapply the two Actions line changes as Sprint 16 work rather than merging the retiring branch's stale configuration ancestry.

### T-134: Add non-vacuous no-remnants and parity enforcement
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- **Touches:** `tools/check-adapter-semantics.sh`, `tools/check-adapter-semantics.test.sh`, every mirrored asset changed by T-130–T-132
- **Depends on:** T-130, T-131, T-132, T-133
- **Acceptance criterion:** Canonical guards reject revival of the retired branch model on active surfaces while preserving finalized provenance.
- **Success criterion (EARS):**
  - **WHEN** the active adapter/schema/script/phase/operator/profile/updater surfaces contain the retired branch term, **THEN** `check-adapter-semantics.sh` **SHALL** fail with a path-specific branch-model diagnostic while excluding finalized sprint and Git/PR history.
  - **WHEN** fixtures inject that term separately into adapter, schema, script, phase, operator-guide, live-profile, and updater-config surfaces, **THEN** `check-adapter-semantics.test.sh` **SHALL** observe a path-specific failure for every class, proving the guard inventory is complete and non-vacuous.
  - **WHEN** all four bundles are compared and the canonical deterministic suite runs twice, **THEN** every mapped asset **SHALL** be byte-identical and every normalized guard confirmation **SHALL** match.
- **Notes:** The guard's own regression vocabulary and immutable Book history are explicit exclusions; active distributions are not.

### T-135: Reinstall and verify the revised Codex skill
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- **Touches:** `C:/Users/charl/.agents/skills/sprint-loops`, `docs/work/tasks.md`, `docs/work/completed-tasks.md`
- **Depends on:** T-134
- **Acceptance criterion:** Codex receives the revised active contract after implementation and guard verification.
- **Success criterion (EARS):**
  - **WHEN** the repository's documented Windows transactional installer runs against the revised `codex-cli/skills/sprint-loops` source, **THEN** it **SHALL** replace the user-scoped install without leaving a lock, staging directory, backup, or ownership marker.
  - **WHEN** source and installed trees are compared after activation, **THEN** every regular file **SHALL** have the same relative path and SHA-256 hash.
  - **WHEN** the installed router and v2 profile resolver run from this repository, **THEN** they **SHALL** report the phase implied by the Book and resolve GitHub/main/dev/human-approve without any retired branch output.
- **Notes:** This is the second refresh requested by the user; the first refresh supplied the protocol used to run Sprint 16.

## Post-Checkpoint Realization Step

### M-001: Retire the remote dependency branch after the human-approved checkpoint
- **Intent:** [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md)
- **Owner:** Loop handoff under `mergePolicy: human-approve`; this is causally
  post-Build and is not disguised as a Build task.
- **Depends on:** T-135, a green Sprint 16 `dev → main` PR, and explicit human approval of that merge.
- **Success criterion (EARS):**
  - **WHEN** Sprint 16 is merged and `main` is verified to contain the v2 profile, Dependabot target `dev`, CI coverage for `dev`, and both Actions v7 updates, **THEN** the authorized operator **SHALL** resync `main → dev`, delete the local and remote retired branch, and verify the remote long-lived branch set is exactly `main`/`dev`.
  - **WHEN** merge or deletion authority is not granted, **THEN** Loop **SHALL** keep INT-0003 active, record M-001 as carry-forward work, and leave the recoverable branch intact rather than claim realization.
- **Notes:** Tests verify preconditions and post-state; they do not perform the remote deletion as a hidden test side effect.
