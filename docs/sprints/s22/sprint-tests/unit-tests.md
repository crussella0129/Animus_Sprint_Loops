# Sprint 22 unit and command regressions

Runtime implementation: `dbc2a83`; final assertion-strengthening commit:
`7545986097d804db20737fbf4846e0c35c2abf5c` (test files only).

## T-180 — Failure diagnostics (INT-0013)
Executed in tools/run-guards.test.sh:
- test_failure_diagnostics: stdout, stderr, suite name, run number and exit 7
  appear, and runner exits nonzero.
- test_mismatch_diagnostics: both outputs and normalized diff appear, with
  nonzero exit and mismatch confirmation.
- test_second_run_failure: passing first run and failing second run both appear.
- test_passing_deterministic_suite_is_clean: successful summary suppresses raw
  output, remains free of mismatch labels, and matches an independently computed
  SHA-256 digest for `steady\n`.
- test_normalized_evidence_hash: Linux/macOS temp paths, different timestamps
  and CR bytes normalize to the same independently computed expected digest;
  all three variants also satisfy the two-run determinism check.
- Existing deterministic-failure and nondeterministic fixtures now assert exit
  status, closing the vacuous negative assertions found by review.

## T-179 — Evidence integrity (INT-0013)
Executed in tools/run-guards.test.sh:
- test_hash_failure: injected backend error produces no PASS and nonzero exit.
- test_capture_failure: injected allocation error produces no PASS, reports the
  capture failure, and never reaches the externally observable suite marker.
- test_report_write_failure: suite turns the report destination into a directory;
  append failure is diagnosed and cannot return success.
- test_listing_modes: listing does not execute suites or alter an existing report.
- test_missing_output_argument: missing value fails with a usage diagnostic.

Executed in tools/check-suite-sensitivity.test.sh:
- test_baseline_integrity: real canonical confirmations are independently
  altered to absent, malformed, duplicated, mismatched hash/tree, working-tree,
  or PASS-with-mismatch forms. Each is refused before the external run marker.
- test_failing_baseline_is_not_scored: an actual failing baseline is unscorable
  and produces nonzero exit without executing the mutation.
- test_source_provenance: staged subject edits are excluded from committed
  baselines; after committing the changed subject, the old report is refused.
- test_untracked_dependency: a working-tree PASS cannot qualify; the committed
  baseline omits the untracked dependency and fails as it should.
- test_sensitive_suite_passes_the_check and test_insensitive_suite_is_caught:
  coupled and uncoupled controls produce opposite verdicts with real baselines.
- test_sensitivity_leaves_worktree_clean: successful control preserves status
  and the subject checksum.
- test_unknown_suite and test_missing_mutated_confirmation: unknown names and
  harness exits 0/2 without a row cannot produce successful sensitivity claims.
- test_subject_restored_between_suites: cross-dependent suites run in both
  orders and separately; exactly one correct verdict is required for every
  selected suite, and the uncoupled suite remains INSENSITIVE in every case.
- test_shared_subject_suites: distinct suites sharing a subject both receive
  exactly one correct verdict in both orders and individually.
- test_contradictory_mutated_confirmation: a syntactically valid, hash-correct
  PASS row with harness exit 1 is unscorable; no sensitive/INSENSITIVE verdict
  may appear.
- test_temp_root_spellings and test_symlinked_temp_root: valid trailing-slash,
  parent-component and symlink spellings survive physical containment checks.
- Explicit subjectless/harness-subject exclusions and missing-report refusal
  retain their existing coverage.

## T-177 / T-182 — Canonical inventory and guidance
- test_canonical_suite_inventory (INT-0007, INT-0013): exactly one occurrence
  of each adapter-semantics suite, no merge-policy aliases.
- operator-docs (INT-0013): committed baseline procedure, unscorable limitations
  and normalized failure diff remain discoverable.
- plugin-manifest and bundle-sync (INT-0013): version 0.22.0 agrees in the
  manifest and all four runtime bundles.

## Results
Focused Linux execution: 13 runner fixtures and 17 sensitivity fixtures pass.
Windows: the affected fixtures passed during implementation; final determinism results are
recorded in integration-tests.md. The directory-symlink fixture explicitly skips
when the host cannot create real symlinks; Linux executed it successfully.
ShellCheck 0.11.0 reports no warnings in changed scripts.
