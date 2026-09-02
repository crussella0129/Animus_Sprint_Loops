Finalized - DO NOT EDIT

# Sprint 17 Build Plan

## Intents
- [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) — state: planned; acceptance criteria covered: one-command convergence with a no-op re-run; rollback of any failed convergence step; byte-identical routing for an un-converged Book; four distinguishable substrate states; marker parsed unchanged by every helper in all four bundles; refusal of a Book stamped ahead of the bundle; bundle version recorded in sprint metadata in every install mode.

## Schema Tree
- Substrate contract versioning and idempotent convergence
  - Version contract
    - T-137: substrate version accessor in the path contract
    - T-138: outdated and ahead substrate states
  - Convergence entrypoint
    - T-139: named convergence steps, the version stamp, and `--check`
  - Bundle identity
    - T-140: in-bundle version, plugin manifest agreement
    - T-141: bundle version recorded per sprint
  - Adapter contracts
    - T-142: `upgrade` argument and the outdated route

## Execution Sequence

### T-137: Add the substrate contract version to the shared path contract
- **Intent:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- **Touches:** `open-harnesses/scripts/book-paths.sh`, `claude-code/skills/sprint-loop/scripts/book-paths.sh`, `codex-cli/skills/sprint-loops/scripts/book-paths.sh`, `antigravity-ide/skills/sprint-loop/scripts/book-paths.sh`, `open-harnesses/scripts/runtime-helpers.test.sh` (+3 bundle copies)
- **Depends on:** (none)
- **Acceptance criterion:** every helper that reads the marker still parses a Book carrying the new key, across all four bundles.
- **Success criterion (EARS):**
  - **WHEN** `book_substrate_version()` reads a marker containing only `schema-version: 2`, **THEN** it **SHALL** print `1` and return 0.
  - **WHEN** it reads a marker containing exactly one `substrate-version: N` line whose value is a positive integer, **THEN** it **SHALL** print N and return 0.
  - **WHEN** it reads a marker whose `substrate-version` value is not a positive integer, or which carries more than one such line, **THEN** it **SHALL** return non-zero and write a diagnostic naming the marker path to stderr.
  - **WHEN** `book_marker_is_v2()` reads a marker carrying a valid `substrate-version` line, **THEN** it **SHALL** return 0.
- **Notes:** add `BOOK_SUBSTRATE_CONTRACT_VERSION=2` beside the existing `BOOK_SCHEMA_VERSION`, and a `BOOK_SUBSTRATE_VERSION_DIAGNOSTIC` string following the existing diagnostic-constant convention. Do not alter `book_marker_is_v2()`'s awk.

### T-138: Report outdated and ahead substrate states
- **Intent:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- **Touches:** `open-harnesses/scripts/check-substrate.sh` (+3 bundle copies), `open-harnesses/scripts/check-substrate.test.sh` (+3 bundle copies), `open-harnesses/scripts/book-routing.test.sh` (+3 bundle copies)
- **Depends on:** T-137
- **Acceptance criteria:** `check-substrate.sh` distinguishes complete, absent, partial, and outdated; a Book stamped ahead of the running bundle is refused with a diagnostic naming both versions; an un-converged Book produces byte-identical routing output.
- **Success criterion (EARS):**
  - **WHEN** the substrate is complete and the Book version equals the bundle's implemented version, **THEN** `check-substrate.sh` **SHALL** print `substrate-complete` and exit 0.
  - **WHEN** the substrate is otherwise complete and the Book version is below the bundle's, **THEN** it **SHALL** print `substrate-outdated:<book>-><bundle>` and exit non-zero.
  - **WHEN** the Book version is above the bundle's, **THEN** it **SHALL** print `substrate-ahead:<book>-><bundle>` and exit non-zero.
  - **WHEN** a required substrate element is missing and the Book version also differs from the bundle's, **THEN** it **SHALL** print the `substrate-partial:` diagnostic rather than a version state.
  - **WHEN** `check-substrate.sh` runs against any Book, **THEN** the working tree **SHALL** remain byte-identical.
  - **WHEN** `current-phase.sh` runs against a Book carrying no `substrate-version` line, **THEN** it **SHALL** print the same phase token for that fixture as it printed before this sprint.
- **Notes:** both version states use the same `<book>-><bundle>` operand order; the keyword carries the direction. Preserve the existing `missing` accumulation and its precedence — a broken substrate outranks a stale one.

### T-139: Make deploy-substrate the convergence entrypoint
- **Intent:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- **Touches:** `open-harnesses/scripts/deploy-substrate.sh` (+3 bundle copies), `open-harnesses/scripts/deploy-substrate.test.sh` (+3 bundle copies)
- **Depends on:** T-137, T-138
- **Acceptance criteria:** a Book at contract version 1 converges to the current version in one command and a second run changes nothing; a failure injected at any convergence step rolls back every artifact that run created; a Book ahead of the bundle is refused and never converged backwards.
- **Success criterion (EARS):**
  - **WHEN** convergence runs against a Book with no `substrate-version` line, **THEN** it **SHALL** add exactly one `substrate-version: <bundle>` line and **SHALL** leave every other marker line byte-identical.
  - **WHEN** convergence runs against a Book already at the bundle's version, **THEN** every file and every git ref in the project **SHALL** remain byte-identical.
  - **WHEN** convergence is invoked with `--check`, **THEN** it **SHALL** print one line per pending convergence step and **SHALL** make no filesystem or ref change.
  - **WHEN** the Book version exceeds the bundle's implemented version, **THEN** convergence **SHALL** exit non-zero with a diagnostic naming both versions and **SHALL** change nothing.
  - **WHEN** `DEPLOY_SUBSTRATE_FAIL_AFTER=stamp` is set, **THEN** rollback **SHALL** restore the marker to its pre-run content.
  - **WHEN** convergence completes against a previously unstamped Book, **THEN** its own post-convergence verification **SHALL** observe `substrate-complete` and exit 0.
- **Notes:** the stamp step runs **before** the final verification step, not after it. Ordering matters: once T-138 lands, `check-substrate.sh` reports `substrate-outdated` for a complete-but-unstamped Book, so a stamp placed after verification would make convergence fail its own check on exactly the projects it is meant to upgrade. Track the prior marker content in a `PRIOR_MARKER`-style variable so rollback restores rather than deletes, and extend the existing seam with `maybe_fail stamp`.

### T-140: Give the bundle a readable identity and enforce manifest agreement
- **Intent:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- **Touches:** `open-harnesses/scripts/bundle-version.sh` (new, +3 bundle copies), `tools/check-bundle-sync.sh`, `claude-code/.claude-plugin/plugin.json`, `tools/check-plugin-manifest.sh`, `tools/check-plugin-manifest.test.sh` (new), `tools/run-guards.sh`
- **Depends on:** (none)
- **Acceptance criterion:** a closed sprint's metadata names the bundle version that ran it, in every install mode — including the manual installer path, which installs the skill bundle with no plugin manifest beside it.
- **Success criterion (EARS):**
  - **WHEN** `bundle-version.sh` is invoked, **THEN** it **SHALL** print exactly one line carrying the bundle's version and exit 0.
  - **WHEN** `plugin.json` carries no `version` field, **THEN** `check-plugin-manifest.sh` **SHALL** exit non-zero with a diagnostic naming the missing field.
  - **WHEN** `plugin.json`'s `version` differs from the value printed by the claude-code bundle's `bundle-version.sh`, **THEN** `check-plugin-manifest.sh` **SHALL** exit non-zero with a diagnostic naming both values.
  - **WHEN** any bundle's `bundle-version.sh` differs in bytes from the maintenance reference copy, **THEN** `check-bundle-sync.sh` **SHALL** fail.
- **Notes:** the helper lives in `scripts/` precisely so the existing parity map and shellcheck coverage apply with no new guard case (research F8). Add it to `REQUIRED_SCRIPTS`, and register a `plugin-manifest-test` suite following the `merge-policy-test` / `bundle-sync-test` precedent.

### T-141: Record the bundle version in sprint metadata
- **Intent:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- **Touches:** `open-harnesses/scripts/init-sprint.sh` (+3 bundle copies), `open-harnesses/schemas/sprint-meta.md` (+3 bundle copies), `open-harnesses/scripts/book-routing.test.sh` (+3 bundle copies)
- **Depends on:** T-140
- **Acceptance criterion:** a closed sprint's metadata names the bundle version that ran it.
- **Success criterion (EARS):**
  - **WHEN** `init-sprint.sh` creates a sprint, **THEN** the new `sprint-meta.md` **SHALL** contain exactly one `- **Bundle version:**` line naming the value printed by the co-located `bundle-version.sh`.
  - **WHEN** `close-sprint.sh` closes a sprint whose `sprint-meta.md` predates this field, **THEN** it **SHALL** succeed without requiring the field.
- **Notes:** place the field after `- **Model:**`. `close-sprint.sh` already appends only its own missing anchored fields, so no change there is required — the second clause verifies that existing behavior rather than adding to it.

### T-142: Add the upgrade argument and the outdated route to the adapter contracts
- **Intent:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- **Touches:** `claude-code/skills/sprint-loop/SKILL.md`, `claude-code/skills/sprint-loop/phases/01-init-sprint.md`, `codex-cli/skills/sprint-loops/SKILL.md`, `codex-cli/skills/sprint-loops/phases/01-init-sprint.md`, `antigravity-ide/skills/sprint-loop/SKILL.md`, `antigravity-ide/global_workflows/sprint-loops.md`, `open-harnesses/particles/01-init-sprint.md`, `README.md`
- **Depends on:** T-138, T-139
- **Acceptance criterion:** a Book at contract version 1 converges to the current version in one command (the operator-facing half — the documented route that reaches it).
- **Success criterion (EARS):**
  - **WHEN** the substrate gate reports `substrate-outdated`, **THEN** the Init phase contract **SHALL** direct convergence through `deploy-substrate.sh` before initialization proceeds.
  - **WHEN** the adapter is invoked with `upgrade`, **THEN** `SKILL.md` **SHALL** define it as running the substrate check followed by convergence and reporting the resulting substrate state.
  - **WHEN** the adapter documentation set is scanned after this change, **THEN** `check-adapter-semantics.sh` and `operator-docs.test.sh` **SHALL** both exit 0.
- **Notes:** `phases/01-init-sprint.md` is byte-parity between claude-code and codex-cli — edit both identically. The argument list in `SKILL.md` is closed ("any other argument is unsupported"), so `upgrade` must be added there or it is refused by contract. Antigravity's translation layer names these helpers in prose only; add the corresponding sentence without claiming gate parity it does not have.
