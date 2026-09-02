Finalized - DO NOT EDIT

# Sprint 17 Test Plan

## Intent Traceability

| Intent | Acceptance criterion | Build task / EARS clause | Verification |
|--------|----------------------|--------------------------|--------------|
| [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) | A Book at contract version 1 converges to the current version in one command | T-139 / WHEN convergence runs against a Book with no `substrate-version` line, THEN it SHALL add exactly one such line; and WHEN convergence completes against a previously unstamped Book, THEN its own verification SHALL observe `substrate-complete` | `test_converge_stamps_unstamped_book`, `test_converge_verifies_after_stamp` |
| [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) | A second run of that command changes nothing and reports the no-op | T-139 / WHEN convergence runs against a Book already at the bundle's version, THEN every file and ref SHALL remain byte-identical | `test_deploy_idempotent` |
| [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) | A failure injected at any convergence step rolls back every artifact that run created | T-139 / WHEN `DEPLOY_SUBSTRATE_FAIL_AFTER=stamp` is set, THEN rollback SHALL restore the marker | `test_converge_rolls_back_stamp`, `test_deploy_rolls_back` |
| [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) | An un-converged Book produces byte-identical routing output before and after this release | T-138 / WHEN `current-phase.sh` runs against a Book carrying no `substrate-version` line, THEN it SHALL print the same phase token | `test_routing_unchanged_for_unstamped_book` |
| [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) | `check-substrate.sh` distinguishes complete, absent, partial, and outdated | T-138 / the complete, outdated, and precedence clauses | `test_substrate_complete_when_versions_match`, `test_substrate_outdated_when_book_behind`, `test_substrate_partial_outranks_version`, `test_substrate_absent` |
| [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) | A Book stamped ahead of the running bundle is refused with a diagnostic naming both versions, and never converged backwards | T-138 / WHEN the Book version is above the bundle's, THEN it SHALL print `substrate-ahead:<book>-><bundle>`; T-139 / WHEN the Book version exceeds the bundle's, THEN convergence SHALL exit non-zero and change nothing | `test_substrate_ahead_when_book_newer`, `test_converge_refuses_ahead_book` |
| [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) | Every helper that reads the marker still parses a Book carrying the new key, across all four bundles | T-137 / the `book_marker_is_v2()` clause | `test_marker_v2_survives_version_key`, `bundle-sync` |
| [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) | A closed sprint's metadata names the bundle version that ran it, in every install mode | T-140 / the `bundle-version.sh` and manifest-agreement clauses; T-141 / the init clause | `test_bundle_version_prints_single_line`, `test_manifest_requires_version`, `test_manifest_version_must_match_bundle`, `test_init_records_bundle_version` |
| [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) | The operator-facing route that reaches convergence exists in the adapter contracts | T-142 / the outdated-route, `upgrade`, and guard clauses | `test_phase01_documents_outdated_route`, `test_skill_defines_upgrade_argument`, `adapter-semantics`, `operator-docs` |

## Unit Tests

### T-137 unit tests
- **Intent:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- Location: `scripts/runtime-helpers.test.sh` (reached by `selftest.sh`, the first guard suite).
- `test_substrate_version_absent_is_one`: marker with only `schema-version: 2` → prints `1`, exit 0.
- `test_substrate_version_reads_stamped_value`: marker with `substrate-version: 2` → prints `2`, exit 0.
- `test_substrate_version_rejects_malformed`: marker with `substrate-version: two`, and separately with two `substrate-version` lines → non-zero exit, stderr names the marker path.
- `test_marker_v2_survives_version_key`: `book_marker_is_v2()` against a stamped marker → returns 0.
- Stubs: none. Fixtures are real marker files under a temp Book, following the existing `init_fixture` helper.

### T-138 unit tests
- **Intent:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- Location: `scripts/check-substrate.test.sh`, reusing `git_init_branches` / `make_book` / `make_profile`.
- `test_substrate_complete_when_versions_match`: stamped Book at the bundle version → `substrate-complete`, exit 0.
- `test_substrate_outdated_when_book_behind`: unstamped complete Book → `substrate-outdated:1->2`, exit non-zero.
- `test_substrate_ahead_when_book_newer`: marker stamped `substrate-version: 99` → `substrate-ahead:99->2`, exit non-zero.
- `test_substrate_partial_outranks_version`: unstamped Book missing the `dev` branch → output begins `substrate-partial:` and names `branch:dev`.
- `test_substrate_is_readonly` (existing, extended to the new fixtures): working tree checksum unchanged after each new state is reported.
- `test_routing_unchanged_for_unstamped_book`: the routing clause of T-138 is verified in `scripts/book-routing.test.sh` rather than here, because it exercises `current-phase.sh`; see Integration → Backwards-compatibility regression.

### T-139 unit tests
- **Intent:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- Location: `scripts/deploy-substrate.test.sh`.
- `test_converge_stamps_unstamped_book`: a complete unstamped Book → marker gains exactly one `substrate-version: 2` line; all other marker lines byte-identical; `check-substrate.sh` then reports `substrate-complete`.
- `test_deploy_idempotent` (existing): re-run after convergence leaves the file+ref snapshot unchanged — this is the no-op proof and must pass unmodified.
- `test_converge_check_is_readonly`: `--check` against an unstamped Book → lists the pending stamp step, and the file+ref snapshot is unchanged.
- `test_converge_refuses_ahead_book`: marker stamped `99` → non-zero exit, diagnostic contains both `99` and `2`, snapshot unchanged.
- `test_converge_rolls_back_stamp`: `DEPLOY_SUBSTRATE_FAIL_AFTER=stamp` → non-zero exit and the marker byte-identical to its pre-run content.
- `test_converge_verifies_after_stamp`: convergence against a complete-but-unstamped Book exits 0 and prints its success line — proving the stamp precedes the final verification, which would otherwise observe `substrate-outdated` and fail.

### T-140 unit tests
- **Intent:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- Location: new `tools/check-plugin-manifest.test.sh`, following the `check-bundle-sync.test.sh` isolated-fixture pattern.
- `test_bundle_version_prints_single_line`: `bundle-version.sh` → exactly one line, non-empty, exit 0.
- `test_manifest_requires_version`: fixture tree whose `plugin.json` omits `version` → guard exits non-zero, message names the field.
- `test_manifest_version_must_match_bundle`: fixture whose `plugin.json` version and `bundle-version.sh` disagree → guard exits non-zero, message names both values.
- `test_bundle_sync_covers_bundle_version`: added to `tools/check-bundle-sync.test.sh` — a mutated copy of `bundle-version.sh` in one bundle fails the parity guard.

### T-141 unit tests
- **Intent:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- Location: `scripts/book-routing.test.sh` (owns the `init-sprint.sh` fixtures).
- `test_init_records_bundle_version`: a fresh init → `sprint-meta.md` contains exactly one `- **Bundle version:**` line matching `bundle-version.sh` output.
- `test_legacy_sprint_meta_closes_without_bundle_version`: a sprint record written without the field reaches `close-sprint.sh` successfully.

### T-142 unit tests
- **Intent:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- Location: `tools/operator-docs.test.sh` for the documentation assertions; the two existing guards for the rest.
- `test_phase01_documents_outdated_route`: both byte-parity copies of `phases/01-init-sprint.md` name `substrate-outdated` and route it to `deploy-substrate.sh`.
- `test_skill_defines_upgrade_argument`: each adapter `SKILL.md` defines `upgrade` in its argument list.
- `adapter-semantics`, `operator-docs`: existing guard suites exit 0 after the documentation change.

## Integration Tests

### Convergence round trip
- **Intents:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- `test_converge_round_trip`: T-137 + T-138 + T-139 composed against one fixture project — `check-substrate.sh` reports `substrate-outdated:1->2`; convergence runs; `check-substrate.sh` reports `substrate-complete` and exits 0; convergence re-runs as a verified no-op.

### Bundle identity end to end
- **Intents:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- `test_bundle_identity_reaches_sprint_record`: T-140 + T-141 composed — a fixture project initialized from a bundle whose `bundle-version.sh` is fixed to a known value produces a `sprint-meta.md` naming exactly that value, with no `.claude-plugin/` directory present in the fixture (the manual-install mode from research F7).

### Backwards-compatibility regression
- **Intents:** [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md)
- `test_routing_unchanged_for_unstamped_book`: the full `book-routing.test.sh` phase walk (research → plan → build → test → loop → ready) executed against Books that are never stamped, asserting the same phase tokens the suite asserted before this sprint. This is the compatibility claim under test rather than under assertion.

## End-to-End Tests
- **Status:** possible
- `test_guard_suite_green`: `bash tools/run-guards.sh --determinism` — all suites PASS with matching normalized evidence hashes across both runs, including the extended substrate, routing, parity, and manifest suites. Record the tested head SHA and the authoritative CI conclusion.
- `test_repository_self_converges`: run convergence against this repository's own Book. Before: `substrate-outdated:1->2`. After: `substrate-complete`, exit 0, with `docs/.sprint-loop-book` carrying both keys and no other line changed. Re-run confirms the no-op. The resulting marker is committed as part of this sprint.
- `test_installed_bundle_parity`: after the bundles are updated, the installed Claude Code plugin bundle and the repository's `claude-code/` tree compare identical for `scripts/` and `phases/`, so the loop that runs the next sprint is the loop this sprint shipped.
