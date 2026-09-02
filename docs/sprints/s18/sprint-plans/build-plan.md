Finalized - DO NOT EDIT

# Sprint 18 Build Plan

## Intents
- [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) — state: planned; acceptance criteria covered: checkpoint refused before close; composed `Sprint N: <Summary>` title with malformed titles refused; untracked or dirty exit artifacts cannot close; a wrong-branch task commit refused before staging; one checkpoint per sprint with a stable recorded URL; an un-converged Book unaffected by every gate.
- [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) — state: realized; relevance: supplies the contract version every gate binds on. Not advanced by this sprint.

## Schema Tree
- The turn and checkpoint contract
  - Mechanism
    - T-146: contract version 3 and the tracked-evidence helper
  - Evidence gates
    - T-147: committed-evidence gates at plan lock and close
    - T-148: work-branch guard in the write helpers
    - T-149: `substrate-misplaced` detection at the gate
  - Checkpoint
    - T-150: checkpoint gate, composed title and body, recorded checkpoint
  - Contracts
    - T-151: the Turn Contract and committed Exit evidence

## Execution Sequence

### T-146: Raise the substrate contract to 3 and add the tracked-evidence helper
- **Intent:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- **Touches:** `open-harnesses/scripts/check-tracked.sh` (new, +3 bundle copies), `open-harnesses/scripts/check-tracked.test.sh` (new, +3 bundle copies), `open-harnesses/scripts/book-paths.sh` (+3), `open-harnesses/scripts/bundle-version.sh` (+3), `claude-code/.claude-plugin/plugin.json`, `tools/check-bundle-sync.sh`, `tools/run-guards.sh`
- **Depends on:** (none)
- **Acceptance criterion:** an un-converged Book is unaffected by all four gates — this task supplies the version the gates test.
- **Success criterion (EARS):**
  - **WHEN** `check-tracked.sh` runs against a Book containing an untracked file, **THEN** it **SHALL** exit non-zero and write that path to stderr.
  - **WHEN** it runs against a Book containing a modified tracked file, **THEN** it **SHALL** exit non-zero and write that path to stderr.
  - **WHEN** it runs against a fully committed Book, **THEN** it **SHALL** exit 0.
  - **WHEN** it runs in a project that is not a git repository, **THEN** it **SHALL** exit 0 without a diagnostic.
  - **WHEN** `book_substrate_version()` reads a Book stamped `2`, **THEN** it **SHALL** print `2` while `BOOK_SUBSTRATE_CONTRACT_VERSION` reports `3`, so a Sprint-17-era Book is recognized as behind rather than current.
- **Notes:** the helper reports every offending path rather than the first, so one run tells the operator the whole remedy. Raise `bundle-version.sh` and `plugin.json` to `0.18.0` together — `check-plugin-manifest.sh` fails if they disagree. Add the helper to `REQUIRED_SCRIPTS` and register a `check-tracked` suite.

### T-147: Gate plan finalization and sprint close on committed evidence
- **Intent:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- **Touches:** `open-harnesses/scripts/finalize-plan.sh` (+3), `open-harnesses/scripts/close-sprint.sh` (+3), `open-harnesses/scripts/runtime-helpers.test.sh` (+3)
- **Depends on:** T-146
- **Acceptance criterion:** a phase whose exit artifact exists but is untracked or dirty cannot close, and the diagnostic names the offending path.
- **Success criterion (EARS):**
  - **WHEN** `finalize-plan.sh` runs at contract version 3 or above with an untracked or modified Book artifact, **THEN** it **SHALL** refuse, name the path, and leave both plans unlocked.
  - **WHEN** `close-sprint.sh` runs at contract version 3 or above with an untracked or modified Book artifact, **THEN** it **SHALL** refuse before modifying the sprint metadata and name the path.
  - **WHEN** either runs against a Book below contract version 3, **THEN** it **SHALL** behave exactly as it did before this sprint.
- **Notes:** `close-sprint.sh` writes and commits the sprint metadata itself, so the check runs at entry — before the meta is touched and before the index is backed up. `finalize-plan.sh` must run it before creating any lock candidate, so a refusal leaves the existing transactional rollback path untouched.

### T-148: Refuse writes from the wrong branch
- **Intent:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- **Touches:** `open-harnesses/scripts/commit-task.sh` (+3), `open-harnesses/scripts/close-sprint.sh` (+3), `open-harnesses/scripts/runtime-helpers.test.sh` (+3)
- **Depends on:** T-146
- **Acceptance criterion:** a task commit attempted while `HEAD` is the base branch is refused before anything is staged.
- **Success criterion (EARS):**
  - **WHEN** `commit-task.sh` runs at contract version 3 or above while `HEAD` is not the remote profile's `work` branch, **THEN** it **SHALL** exit non-zero naming the current and expected branches, and **SHALL NOT** stage any path.
  - **WHEN** `close-sprint.sh` runs at contract version 3 or above while `HEAD` is not the `work` branch, **THEN** it **SHALL** refuse before modifying the sprint metadata.
  - **WHEN** no remote profile resolves, **THEN** neither helper **SHALL** refuse on branch position.
  - **WHEN** the Book is below contract version 3, **THEN** neither helper **SHALL** refuse on branch position.
- **Notes:** resolve the profile best-effort; a project with no profile is a legitimate `local-only` configuration and must keep working. The refusal must precede `git add`, so the guard sits immediately after the pending-evidence check in `commit-task.sh`.

### T-149: Report a misplaced working branch at the substrate gate
- **Intent:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- **Touches:** `open-harnesses/scripts/check-substrate.sh` (+3), `open-harnesses/scripts/check-substrate.test.sh` (+3)
- **Depends on:** T-146
- **Acceptance criterion:** a task commit attempted from the base branch is refused — this task supplies the earlier detection that keeps a whole sprint from starting there.
- **Success criterion (EARS):**
  - **WHEN** the substrate is complete and `HEAD` is the `work` branch, **THEN** `check-substrate.sh` **SHALL** print `substrate-complete` and exit 0.
  - **WHEN** the substrate is otherwise complete and `HEAD` is not the `work` branch, **THEN** it **SHALL** print `substrate-misplaced:<head>-><work>` and exit non-zero.
  - **WHEN** a required substrate element is missing and `HEAD` is also misplaced, **THEN** it **SHALL** print the `substrate-partial:` diagnostic.
  - **WHEN** the Book is behind the bundle's contract and `HEAD` is also misplaced, **THEN** it **SHALL** print the `substrate-misplaced:` state, because convergence writes and must not run from the base branch.
  - **WHEN** it reports any of these states, **THEN** the working tree **SHALL** remain byte-identical.
- **Notes:** a detached `HEAD` reports its short SHA as `<head>`. Precedence becomes partial → misplaced → ahead → outdated → complete; record it in the script header where the existing state list lives.

### T-150: Gate the checkpoint, compose its title and body, and record it
- **Intent:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- **Touches:** `open-harnesses/scripts/remote-adapter.sh` (+3), `open-harnesses/scripts/remote-adapter.test.sh` (+3), `open-harnesses/schemas/sprint-meta.md` (+3)
- **Depends on:** T-146
- **Acceptance criteria:** `open-pr` invoked in Research, Plan, Build, Test, or an open Loop exits non-zero naming the current phase and opens nothing; with no title supplied the checkpoint is titled exactly `Sprint <N>: <the sprint's Summary>` and a malformed supplied title is refused; re-running opens no second request and the recorded URL is unchanged.
- **Success criterion (EARS):**
  - **WHEN** `open-pr` runs at contract version 3 or above while `current-phase.sh` reports anything other than `ready-for-next-sprint`, **THEN** it **SHALL** exit non-zero with a diagnostic naming that phase and **SHALL NOT** invoke the provider.
  - **WHEN** `open-pr` runs with no `--title` and the sprint metadata carries a non-placeholder `Summary`, **THEN** the opened request's title **SHALL** be exactly `Sprint <N>: <Summary>`.
  - **WHEN** the sprint metadata `Summary` is still the initialization placeholder, **THEN** `open-pr` **SHALL** refuse and name the field.
  - **WHEN** a `--title` is supplied that does not match `^Sprint [0-9]+: .+`, **THEN** `open-pr` **SHALL** refuse and **SHALL NOT** invoke the provider.
  - **WHEN** a checkpoint is opened, **THEN** its URL **SHALL** be recorded once in the sprint metadata `Checkpoint` field, and that record **SHALL** be committed in one scoped commit so the Book is left clean.
  - **WHEN** `open-pr` runs against a Book below contract version 3, **THEN** it **SHALL** behave exactly as it did before this sprint.
- **Notes:** all five existing fixtures build a repo and profile with **no Book**, so each must gain a closed-sprint Book while keeping its original assertion — open-once, refuse-second, generic fallback, never-merge, and head-override rejection. Reuse the existing `gh` stub and `STUBLOG` mechanism. The body is composed from the sprint record; keep it small and deterministic so the suite's evidence hash stays stable. Recording the checkpoint makes the adapter a Book writer for the first time, so it must commit its own write the way `close-sprint.sh` does — otherwise the checkpoint leaves the Book dirty at exactly the moment the next sprint's tracked-evidence gate inspects it.

### T-151: Add the Turn Contract and committed Exit evidence to the phase contracts
- **Intent:** [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md)
- **Touches:** `claude-code/skills/sprint-loop/phases/{02,04,05,06}-*.md`, `codex-cli/skills/sprint-loops/phases/{02,04,05,06}-*.md`, `antigravity-ide/global_workflows/sprint-loops.md`, `open-harnesses/particles/{07-test-phase,08-loop-phase}.md`, `README.md`, `tools/operator-docs.test.sh`
- **Depends on:** T-147, T-150
- **Acceptance criterion:** the operator-facing statement of the contract exists — the documented counterpart to the gates the other tasks enforce.
- **Success criterion (EARS):**
  - **WHEN** an adapter's Loop contract is read, **THEN** it **SHALL** contain a Turn Contract naming exactly four legal stop points: a blocking product ambiguity, an unverifiable claim needing human judgment, an explicit abort, and the human-approve merge boundary after the checkpoint is open.
  - **WHEN** a phase contract's Exit evidence is read, **THEN** it **SHALL** state that the phase's exit artifacts are committed.
  - **WHEN** the Loop contract's checkpoint step is read, **THEN** it **SHALL** state that the checkpoint is refused before the sprint closes and that its title is composed from the Book.
  - **WHEN** the adapter documentation set is scanned after this change, **THEN** `check-adapter-semantics.sh` and `operator-docs.test.sh` **SHALL** both exit 0.
- **Notes:** phases 02/04/05 are byte-parity between claude-code and codex-cli — edit one and copy. Phase 06 diverges per adapter and must be edited separately. The Turn Contract is advisory by nature and must say so, so it does not read as a claim of enforcement the substrate cannot make.
