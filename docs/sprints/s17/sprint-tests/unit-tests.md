# Sprint 17 Unit Tests

Every EARS clause in the locked build plan maps to at least one named fixture.
Suite names are the canonical runner's suite identifiers.

## T-137 — substrate version accessor
Fixtures in `{4 bundles}/scripts/runtime-helpers.test.sh`, reached by the
`selftest` suite.

| Test | Clause | Result |
|---|---|---|
| `test_substrate_version_absent_is_one` | unstamped marker → prints `1`, exit 0 | PASS |
| `test_substrate_version_reads_stamped_value` | one well-formed entry → prints its value (checked at `2` and `11`) | PASS |
| `test_marker_v2_survives_version_key` | `book_marker_is_v2()` still returns 0 on a stamped marker | PASS |
| `test_substrate_version_rejects_malformed` | non-numeric, zero, and duplicated entries → non-zero exit, stderr names the marker path | PASS |

**Execution note.** These four ran in a focused harness driving the installed
`claude-code` bundle rather than through `selftest`, because `selftest` aborts
earlier on backlog defect **T-121** — a Windows-only CRLF-detection failure in
`finalize-plan.sh` that reproduces identically at `HEAD` and is unrelated to
this sprint (see the E2E record). They execute inside `selftest` on the CI
matrix, where T-121 does not reproduce.

## T-138 — outdated and ahead substrate states
Fixtures in `{4 bundles}/scripts/check-substrate.test.sh` (`check-substrate`
suite) and `{4 bundles}/scripts/book-routing.test.sh` (`selftest`). 12/12 pass.

| Test | Clause | Result |
|---|---|---|
| `test_substrate_complete_when_versions_match` | stamped at the bundle version → `substrate-complete`, exit 0 | PASS |
| `test_substrate_outdated_when_book_behind` | complete but unstamped → `substrate-outdated:1->2`, exit non-zero | PASS |
| `test_substrate_ahead_when_book_newer` | stamped `99` → `substrate-ahead:99->2`, exit non-zero | PASS |
| `test_substrate_partial_outranks_version` | unstamped **and** missing the work branch → `substrate-partial:…branch:dev` | PASS |
| `test_substrate_malformed_stamp_is_partial` | malformed stamp is broken, not stale → `substrate-partial:…book-substrate-version` | PASS |
| `test_substrate_is_readonly`, `test_substrate_is_readonly_for_version_states` | the working tree stays byte-identical across every state | PASS |
| `test_routing_unchanged_for_unstamped_book` | `current-phase.sh` on an unstamped Book routes normally and never writes the stamp | PASS |

The three pre-existing complete-path fixtures were converged with a `stamp`
helper driven by `BOOK_SUBSTRATE_CONTRACT_VERSION` rather than a literal, so a
later version change cannot strand them.

## T-139 — convergence entrypoint
Fixtures in `{4 bundles}/scripts/deploy-substrate.test.sh` (`deploy-substrate`
suite). 14/14 pass, including all eight pre-existing fixtures unmodified.

| Test | Clause | Result |
|---|---|---|
| `test_converge_stamps_unstamped_book` | adds exactly one `substrate-version` line; every other marker line byte-identical | PASS |
| `test_converge_verifies_after_stamp` | convergence's own final verification observes `substrate-complete` | PASS |
| `test_deploy_idempotent`, `test_converge_idempotent` | converged re-run leaves every file **and** every git ref byte-identical | PASS |
| `test_converge_check_is_readonly` | `--check` names the pending step, writes nothing, exits non-zero while pending and 0 once converged | PASS |
| `test_converge_refuses_ahead_book` | ahead Book → non-zero, diagnostic names both versions, project unchanged | PASS |
| `test_converge_rolls_back_stamp` | `DEPLOY_SUBSTRATE_FAIL_AFTER=stamp` → marker restored byte-identical | PASS |

`test_converge_verifies_after_stamp` exists because of plan critique C-002: it
is the regression test for the stamp/verify ordering, which would otherwise fail
only when T-138 and T-139 were both present.

## T-140 — bundle identity
New `tools/check-plugin-manifest.test.sh` (`plugin-manifest-test` suite), 6/6,
plus `tools/check-bundle-sync.test.sh` (`bundle-sync-test`), 18/18.

| Test | Clause | Result |
|---|---|---|
| `test_manifest_baseline_passes` | the real packaging surface is valid — proves the mutations below fail for their own reason | PASS |
| `test_bundle_version_prints_single_line` | exactly one non-empty line, exit 0 | PASS |
| `test_manifest_requires_version` | manifest without `version` → non-zero, diagnostic names the field | PASS |
| `test_manifest_version_must_match_bundle` | mismatch → non-zero, diagnostic names both values | PASS |
| `test_manifest_rejects_multiline_bundle_version` | multi-line helper output → non-zero | PASS |
| `test_manifest_requires_bundle_version_helper` | helper absent → non-zero | PASS |
| `bundle-sync` parity | `bundle-version.sh` present and byte-identical in all four bundles, and in `REQUIRED_SCRIPTS` | PASS |

## T-141 — bundle version in sprint metadata
`{4 bundles}/scripts/book-routing.test.sh` and
`{4 bundles}/scripts/runtime-helpers.test.sh` (`selftest`).

| Test | Clause | Result |
|---|---|---|
| `test_init_records_bundle_version` | exactly one `- **Bundle version:**` field matching `bundle-version.sh`, in a fixture with no plugin manifest | PASS |
| `test_legacy_sprint_meta_closes_without_bundle_version` | a record predating the field closes successfully and the field is not invented | PASS |

The second ran in a focused harness for the T-121 reason above; it is asserted
inside the `selftest` close fixture, which now strips `Bundle version` and so is
a genuine pre-sprint-17 record.

## T-142 — adapter contracts
`tools/operator-docs.test.sh` (`operator-docs` suite), 4/4, and
`tools/check-adapter-semantics.sh` (`adapter-semantics`).

| Test | Clause | Result |
|---|---|---|
| `test_phase01_documents_outdated_route` | all four adapter Init surfaces name `substrate-outdated` and route it to `deploy-substrate.sh`; both phase contracts also name `substrate-ahead`; the README documents `substrate-version` and `--check` | PASS |
| `test_skill_defines_upgrade_argument` | `upgrade` is defined in the closed argument list and advertised in `argument-hint` | PASS |
| `adapter-semantics` | every adapter authority/runtime contract still holds | PASS |

`adapter-semantics` **failed this task on first run** and the failure was
correct: six comments and diagnostics introduced the retired branch-model term
the sprint-16 guard rejects across active surfaces. The wording was changed;
the guard was not.
