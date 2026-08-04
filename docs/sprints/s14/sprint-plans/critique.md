# Plan Critique — Sprint 14

The independent critic initially returned `block`. Every concern below was addressed in the unlocked plan artifacts and re-reviewed; the final independent verdict was `clean`.

## Concerns

### C-001: Finalization and ledger criteria lacked complete test coverage
- **Where:** T-113 build criteria and unit tests.
- **Failure mode:** plan-test-mismatch
- **Why it mattered:** Empty-plan rejection, accepting-critic enforcement, sprint-close metadata, and commit-evidence preservation did not each have named coverage.
- **Primary response:** fix-in-plan — added `test_finalize_rejects_empty_build_plan`, `test_finalize_requires_accepting_critic`, `test_commit_preserves_completion_evidence`, and `test_close_updates_book_meta`.

### C-002: Codex authority test could pass without a positive boundary
- **Where:** T-115 `test_codex_authority_boundary`.
- **Failure mode:** missing-risk
- **Why it mattered:** Removing unsafe prose alone would pass without requiring explicit request or a declared preauthorized-remote profile.
- **Primary response:** fix-in-plan — added `test_codex_positive_authority_rule` covering push, merge, release, force-push, delete, and material scope expansion.

### C-003: Split-brain routing refusal was untested
- **Where:** T-112 third EARS clause and migration tests.
- **Failure mode:** plan-test-mismatch
- **Why it mattered:** Migration refusal did not prove `current-sprint.sh` and `current-phase.sh` also refused conflicting layouts.
- **Primary response:** fix-in-plan — added `test_router_conflict_refuses` with an exact split-brain diagnostic.

### C-004: Repository migration had no losslessness proof
- **Where:** T-117 in the initial plan, renumbered T-119.
- **Failure mode:** missing-risk
- **Why it mattered:** Structural validation and secret scanning did not prove every legacy artifact and rationale entry survived.
- **Primary response:** fix-in-plan — added a pre/post path-and-content-hash inventory EARS clause and `test_historical_import_is_lossless`, with explicit reviewed exclusions as the only allowed difference.

### C-005: Adapter alignment was not elementary
- **Where:** initial T-116.
- **Failure mode:** granularity
- **Why it mattered:** Claude semantics, Antigravity mapping, documentation consolidation, and parity enforcement had different failure surfaces and rollback boundaries.
- **Primary response:** fix-in-plan — split the work into T-116 adapter semantics, T-117 operator documentation, and T-118 parity policy; renumbered dogfood and guard tasks to T-119/T-120.

### C-006: Two tests introduced behavior absent from EARS criteria
- **Where:** T-111 initialization idempotency and T-115 launch-time activation.
- **Failure mode:** plan-test-mismatch
- **Why it mattered:** Useful tests had no owning product contract.
- **Primary response:** fix-in-plan — added explicit T-111 scaffolding-idempotency and T-115 single-surface/direct-intent/non-document-trigger EARS clauses.

### C-007: Codex phase-contract requirement was unmeasurable
- **Where:** T-115 criterion 1.
- **Failure mode:** EARS-vague
- **Why it mattered:** “Concise contracts” had no structural threshold and could omit required information.
- **Primary response:** fix-in-plan — required exactly named `## Outcome`, `## Inputs`, `## Authority`, and `## Exit evidence` sections in every Codex phase and added `test_codex_phase_contract_shape`.

### C-008: Migration path preflight had no negative test
- **Where:** T-112 migration safety.
- **Failure mode:** missing-risk
- **Why it mattered:** No test proved an escaping, aliased, or symlinked state path failed before mutation.
- **Primary response:** fix-in-plan — promoted path safety into an EARS clause and added `test_migrate_invalid_path_refuses_before_mutation` with a byte-identical source-inventory assertion.

## Re-review

The independent re-review found no remaining concerns after C-001 through C-008 were fixed.

## Confidence

clean
