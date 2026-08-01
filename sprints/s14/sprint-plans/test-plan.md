Finalized - DO NOT EDIT

# Sprint 14 Test Plan

## Unit Tests

### T-110 Book contract and validator
- `test_book_paths_resolve_v2`: valid marker/schema → all shared paths resolve under `docs/`.
- `test_book_rejects_duplicate_intent_id`: duplicate `INT-NNNN` → exact duplicate-ID diagnostic.
- `test_book_rejects_invalid_state`: unknown lifecycle state → exact state diagnostic.
- `test_book_requires_work_evidence`: planned/active/deferred intent without task or plan link → rejection.
- `test_book_requires_realization_evidence`: realized intent without completion plus code/test/doc evidence → rejection.
- `test_book_rejects_conflicting_layouts`: writable Book plus writable legacy state → split-brain rejection.
- Stubs: temporary fixture repositories only.

### T-111 Book-native initialization and routing
- `test_init_creates_tracked_book`: empty project → `docs/README.md`, `SUMMARY.md`, intent/work/sprint paths, and no root authorities.
- `test_init_preserves_gitignore`: existing ignore content survives; Book is not ignored; transient files remain ignored.
- `test_phase_walk_book_only`: empty research → research; completed research → plan; locked plans → build; terminal tasks → test; report+critique → loop; closed meta → ready.
- `test_init_is_idempotent_for_scaffolding`: existing Book scaffolding is preserved and only the next sprint is created.
- Stubs: fixture Git repository and UTC clock output where existing selftest already stubs it.

### T-112 Legacy migration
- `test_migrate_legacy_losslessly`: root sprints/tasks/decisions/confidence → mapped Book paths with identical content and provenance.
- `test_migrate_is_idempotent`: second run → no duplicates and success/no-op result.
- `test_migrate_conflict_refuses`: divergent legacy and Book content → non-zero split-brain diagnostic.
- `test_router_conflict_refuses`: current-sprint/current-phase against divergent dual layouts → non-zero split-brain diagnostic rather than a selected phase.
- `test_migrate_invalid_path_refuses_before_mutation`: escaping, aliased, or symlinked state path → exact refusal and byte-identical legacy source inventory.
- `test_legacy_only_is_detected`: phase resolver identifies legacy state and directs migration without writing a second layout.
- `test_migrated_decisions_are_history`: ADR text survives under history but no active decisions authority is created.
- Stubs: fixture files with spaces, empty files, multiple sprints, and existing `docs/` content.

### T-113 Runtime helpers and gates
- `test_finalize_requires_intent_review`: non-empty intent set + missing `## Intents Reviewed` → refusal.
- `test_finalize_rejects_legacy_heading_only`: `## Decisions Reviewed` alone → refusal with migration guidance.
- `test_finalize_rejects_empty_build_plan`: no `### T-NNN` execution entry → refusal before mutation.
- `test_finalize_requires_accepting_critic`: missing, malformed, or blocking verdict → refusal before mutation.
- `test_finalize_is_atomic`: invalid test plan or critique → neither plan receives a lock.
- `test_finalize_keeps_budget_gate`: 21 files or 6 sources refuse unless a non-empty override exists.
- `test_commit_updates_book_ledger_exactly_once`: first anchored PENDING evidence entry changes; prose and later entries remain unchanged.
- `test_commit_preserves_completion_evidence`: completed entry retains task ID, touched paths, timestamp, and a resolvable commit reference after amend.
- `test_abort_updates_book_meta`: status, timestamp, and reason update under Book path with no unrelated mutation.
- `test_close_updates_book_meta`: successful Loop close records terminal status, end time, and completion evidence without rewriting closed artifacts.
- `test_confidence_updates_book_state`: pass/patched/failed apply the existing bounded scalar semantics at the Book path.
- Stubs: Git commit identity and fixture files; no network.

### T-114 Shared protocol content
- `test_shared_protocol_has_book_contract`: each shared phase/schema/prompt names canonical Book inputs and evidence exits.
- `test_shared_protocol_has_no_active_adr_authority`: shared active instructions contain no directive to append/read root `decisions.md`.
- `test_intent_schema_covers_lifecycle`: schema documents all legal states, evidence requirements, rationale, alternatives, consequences, and transition history.
- Stubs: static fixture copies used by the parity test.

### T-115 Codex adapter
- `test_codex_skill_routes_by_resolved_path`: routing invokes the installed skill helper with project root as cwd.
- `test_codex_skill_is_mode_aware`: no mandatory or agent-invoked `/plan` instruction remains.
- `test_codex_phase_contract_shape`: every Codex phase contains exactly one Outcome, Inputs, Authority, and Exit evidence section.
- `test_codex_authority_boundary`: no blanket `--ask-for-approval never`, push, merge, force-push, release, or delete authorization remains.
- `test_codex_positive_authority_rule`: push, merge, release, force-push, delete, and material scope expansion each require an explicit request or declared preauthorized-remote profile.
- `test_codex_shared_workspace_guidance`: subagent text requires disjoint bounded work and one integrating writer unless isolated worktrees exist.
- `test_codex_install_locations`: user/repo examples target `.agents/skills`; Windows and POSIX paths are documented.
- `test_codex_activation_contract`: the skill description matches direct sprint/Book-resume intent and does not trigger solely on unrelated documentation.
- `test_codex_progressive_disclosure`: SKILL owns routing, phase files own phase contracts, README owns operator setup, and AGENTS is a short pointer.
- Stubs: static text fixtures; no Codex launch required for unit coverage.

### T-116 Claude and Antigravity semantics
- `test_antigravity_maps_native_artifacts_to_book`: implementation plan, task, and walkthrough map to intent, work, and realization evidence.
- `test_claude_keeps_only_native_orchestration`: Claude plan/recurrence mechanics remain while shared Book semantics match the neutral contract.

### T-117 Operator documentation
- `test_root_docs_do_not_duplicate_protocol`: root/bundle READMEs link to the contract and contain no second full directory schema.
- `test_bundle_docs_are_adapter_scoped`: each bundle README limits itself to current installation, invocation, and adapter-specific operation.

### T-118 Book parity policy
- `test_bundle_sync_includes_book_assets`: missing/extra/divergent shared Book schema or helper → exact parity failure.
- `test_adapter_semantics_reject_legacy_authority`: intentionally divergent adapter docs that name root state as active → semantic guard failure.
- `test_adapter_semantics_require_version`: divergent adapter missing the Book schema version → semantic guard failure.
- Stubs: generated parity fixtures used by `check-bundle-sync.test.sh`.

### T-119 Repository dogfood migration
- `test_repository_book_validates`: actual `docs/` passes the shared validator.
- `test_repository_summary_links_resolve`: every Book navigation link resolves and every canonical intent is reachable.
- `test_repository_has_single_authority`: no writable root sprint/task/decision state remains.
- `test_repository_intent_evidence`: `INT-0001` links this sprint's plan while active and completion/code/test evidence when realized.
- `test_historical_import_is_safe`: migrated ignored artifacts pass a targeted secret/generated-output inspection before staging.
- `test_historical_import_is_lossless`: pre/post path-and-hash inventories match one-to-one except for an explicit reviewed exclusions list.
- Stubs: none; operates read-only against the repository after migration.

### T-120 Canonical suite registration
- `test_suite_registry_complete`: every Book suite appears in `SUITES`, `suite_cmd`, and `suite_script_hash`.
- `test_negative_fixtures_are_non_vacuous`: each expected failure asserts its specific diagnostic, not only a non-zero status.
- `test_deterministic_confirmations`: two normalized runs emit identical evidence hashes.
- `test_shell_portability`: shellcheck plus Ubuntu/macOS CI cover every shared script and intentionally divergent Codex script.
- Stubs: temporary confirmation directories and forced supported hash tools.

## Integration Tests

### Book lifecycle integration
- `test_fresh_book_full_phase_cycle`: initialize a fixture project, author research and intent-aware plans, lock, queue/complete tasks, record test critique/report, close sprint, and verify every derived phase.

### Migration-to-lifecycle integration
- `test_legacy_active_sprint_migrates_and_resumes`: create a legacy fixture at each phase boundary, migrate it, then confirm Book routing resumes the same phase and writes only v2 paths.

### Intent-to-evidence integration
- `test_unrealized_to_realized_transition`: begin with a planned intent linked to a task/plan, complete the task and attach verified code/test evidence, transition to realized, and validate the Book at each legal state.
- `test_illegal_transition_is_rejected`: proposed intent moved directly to realized without required evidence → rejection and unchanged source.

### Cross-harness integration
- `test_all_harnesses_read_same_book_fixture`: Claude, Codex, Antigravity, and open-harness helpers derive identical sprint/intent state from one fixture.
- `test_shared_core_divergent_adapters`: shared assets remain byte-identical while adapter-specific plan/recurrence text passes semantic contracts.

### Canonical runner integration
- `test_run_guards_includes_book`: canonical runner executes Book, migration, parity, policy, shellcheck, and existing state-machine suites with confirmation artifacts.

## End-to-End Tests

- **Status:** possible for repository behavior; launch-time skill discovery remains a human/client checkpoint.
- `test_repository_full_guard_suite`: run `bash tools/run-guards.sh --determinism` from the migrated repository and require all suites green with identical normalized evidence.
- `test_fresh_downstream_project`: install/copy one bundle into a temporary project, initialize the Book, execute a complete synthetic sprint with helper scripts, and verify final Book links and state.
- `test_migrated_downstream_project`: copy a representative legacy fixture, migrate it with one bundle, resume with another bundle, and verify no translation or split-brain state.
- **Human checkpoint:** after installing/reloading the revised Codex skill in a new session, verify `$sprint-loops` appears once, activates on a direct sprint request, and does not activate merely because unrelated documentation exists.
