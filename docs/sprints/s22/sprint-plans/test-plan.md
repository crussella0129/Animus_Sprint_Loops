Finalized - DO NOT EDIT

# Sprint 22 Test Plan

## Intent Traceability
| Intent | Acceptance criterion | Build task / EARS clause | Verification |
|--------|----------------------|--------------------------|--------------|
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Actionable, truthful failures | T-180 / failed suite | test_failure_diagnostics |
| INT-0013 | Truthful determinism verdict | T-180 / mismatch | test_mismatch_diagnostics, test_second_run_failure |
| INT-0013 | Stable passing evidence | T-180 / pass | test_passing_deterministic_suite_is_clean |
| INT-0013 | Baseline describes tested source | T-179 / provenance | test_source_provenance, test_untracked_dependency |
| INT-0013 | Invalid evidence cannot qualify | T-179 / invalid baseline | test_baseline_integrity |
| INT-0013 | Sensitivity means coupling | T-179 / valid baseline | test_sensitive_suite_passes_the_check, test_insensitive_suite_is_caught, test_sensitivity_leaves_worktree_clean |
| INT-0013 | Harness errors are not sensitivity | T-179 / unknown or absent confirmation | test_unknown_suite, test_missing_mutated_confirmation |
| INT-0013 | Independent mutation verdicts | T-179 / multiple suites | test_subject_restored_between_suites, test_shared_subject_suites |
| INT-0013 | No success without evidence | T-179 / infrastructure error | test_hash_failure, test_capture_failure, test_report_write_failure |
| [INT-0007](../../../intents/INT-0007-integrity-sweep.md) | Remove known vestigial entries | T-177 / inventory | test_canonical_suite_inventory |
| INT-0007, INT-0013 | Preserve canonical coverage | T-177 / adapter checks | adapter-semantics, adapter-semantics-test |
| INT-0013 | Discoverable correct procedure | T-182 / guidance | operator-docs, real-baseline sensitivity E2E |
| INT-0013 | Consistent runtime identity | T-182 / version | plugin-manifest, bundle-sync |

## Unit Tests
- **Intents:** INT-0013, INT-0007; clauses as mapped above.
- Synthetic runner suites cover stdout/stderr, deterministic failures, output
  differences, second-run-only failure, passing output suppression and hashes.
- Source provenance fixtures use temporary Git repositories: committed archive,
  tracked working-tree/staged edits excluded from the archive, untracked
  dependency excluded from the archive, and changed subject with unchanged test
  script. Ordinary runs remain useful but cannot qualify as sensitivity baselines.
  Query modes must not run tests or overwrite a report.
- Baseline integrity fixtures use actual runner reports, then alter one field
  or source at a time: missing/failing/duplicate/malformed/mismatched hash/tree,
  dirty source and PASS with mismatch. Assert refusal AND an external marker
  proving mutation did not run. Include valid controls.
- Unknown selections and missing mutated confirmations must fail explicitly.
- Two suites with different subjects and a cross-dependency must score identically
  together, separately and in reversed order; two distinct suites with one subject
  must both run.
- Inject a failing hash backend and a report destination made unwritable during
  execution. Assert nonzero exit, diagnostic, and absence of valid PASS evidence.
- `test_capture_failure`: inject a failing temporary-capture allocation command;
  assert nonzero exit, a capture diagnostic, no valid PASS confirmation, and
  an external marker proving the suite never ran.
- Suite inventory asserts exactly one occurrence of each canonical adapter
  suite and no retired aliases.

## Integration Tests
- **Intents:** INT-0013, INT-0007; T-179 and T-177/T-182 clauses.
- Run tools/run-guards.sh with affected suites and --determinism; retain ndjson.
- Run the canonical full runner once after coherent implementation, including
  shellcheck when available. Record exact environmental limitations and failures.
- Run bundle-sync and plugin-manifest after changing all version copies.
- Run check-book.sh, check-tracked.sh and the phase router at phase boundaries.

## End-to-End Tests
- **Status:** possible
- **Intents:** INT-0013; T-179/T-182.
- From a committed source tree, generate a canonical passing report and feed it
  to check-suite-sensitivity.sh for the affected scorable suite. Assert current
  evidence qualifies and the same report is refused after a source change.
- Fixture repositories exercise the full runner → baseline → archive → mutation
  → confirmation path, with coupled and uncoupled controls.
- POSIX CI is a separate platform confirmation; do not infer it from local
  Git Bash tests. Preserve T-181 as open without a reproduced cause.
