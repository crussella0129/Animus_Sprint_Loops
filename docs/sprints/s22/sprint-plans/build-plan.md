Finalized - DO NOT EDIT

# Sprint 22 Build Plan

## Intents
- [INT-0013](../../../intents/INT-0013-verification-integrity.md) — active; trustworthy local confirmations and sensitivity baselines, actionable failures.
- [INT-0007](../../../intents/INT-0007-integrity-sweep.md) — planned; retire the known vestigial compatibility entries only. The computed sweep remains future work.

## Schema Tree
- Reliable, economical verification
  - T-180: preserve guard failure diagnostics
  - T-179: bind sensitivity baselines to committed source
  - T-177: remove obsolete duplicate guard aliases
  - T-182: document the evidence contract and identify bundle 0.22.0

## Execution Sequence

### T-180: Preserve failure and determinism diagnostics
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- **Touches:** tools/run-guards.sh, tools/run-guards.test.sh
- **Depends on:** none
- **Acceptance criterion:** The runner's console truthfully reports failures and determinism without discarding the evidence needed to diagnose them.
- **Success criterion (EARS):**
  - **WHEN** a suite fails, **THEN** the runner **SHALL** return nonzero and print that suite's captured stdout and stderr with its name and run number (test_failure_diagnostics).
  - **WHEN** two runs disagree in exit code or normalized output, **THEN** the runner **SHALL** print both captured outputs and the normalized diff while preserving the mismatch confirmation (test_mismatch_diagnostics, test_second_run_failure).
  - **WHEN** a suite passes deterministically, **THEN** the runner **SHALL** keep its summary concise and preserve stable evidence hashes (test_passing_deterministic_suite_is_clean).

### T-179: Require current, valid sensitivity baselines
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- **Touches:** tools/run-guards.sh, tools/run-guards.test.sh, tools/check-suite-sensitivity.sh, tools/check-suite-sensitivity.test.sh
- **Depends on:** T-180
- **Acceptance criterion:** A sensitive verdict means the suite passed on the same committed source being mutated; unverifiable evidence cannot establish that claim.
- **Success criterion (EARS):**
  - **WHEN** the runner's `--committed` mode is requested, **THEN** suites **SHALL** run in one archive of the selected committed tree and confirmations **SHALL** record that tree and suite hash; ordinary working-tree runs **SHALL** be explicitly unusable for sensitivity (test_source_provenance, test_untracked_dependency).
  - **WHEN** a baseline is missing, failing, nondeterministic, malformed, duplicated, stale by suite hash or source tree, or from dirty source, **THEN** sensitivity **SHALL** refuse to score it and exit nonzero (test_baseline_integrity).
  - **WHEN** a valid committed baseline is supplied, **THEN** a coupled suite **SHALL** score sensitive and an uncoupled suite **SHALL** score INSENSITIVE with nonzero exit, without changing the real working tree (existing sensitivity fixtures with real baselines).
  - **WHEN** a requested suite is unknown or the mutated run has no valid confirmation, **THEN** sensitivity **SHALL** exit nonzero with a diagnostic rather than claim a successful sweep (test_unknown_suite, test_missing_mutated_confirmation).
  - **WHEN** multiple suites are scored, **THEN** each suite **SHALL** see all other subjects restored and receive its own verdict even when subjects are shared (test_subject_restored_between_suites, test_shared_subject_suites).
  - **WHEN** hashing, capture, or confirmation writing fails, **THEN** the runner **SHALL** exit nonzero and never emit a valid PASS confirmation for the failed operation (test_hash_failure, test_capture_failure, test_report_write_failure).
- **Notes:** Inspect provenance before mutation. Match HEAD's archived tree, not a suite hash alone. `--committed` excludes untracked/ignored dependencies and requires the runner itself to match its committed copy; the ordinary default still tests local edits. Use relative committed extra-suite paths in archived runs. Keep subjectless and harness-subject exclusions explicit. Validate CLI value arguments. No new parser/runtime dependency.

### T-177: Remove duplicate compatibility suites
- **Intent:** [INT-0007](../../../intents/INT-0007-integrity-sweep.md), [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- **Touches:** tools/run-guards.sh, tools/run-guards.test.sh, tools/check-merge-policy.sh, tools/check-merge-policy.test.sh
- **Depends on:** T-179
- **Acceptance criterion:** Remove the known vestigial compatibility layer and its redundant work; retain the canonical adapter semantics guard and fixture coverage.
- **Success criterion (EARS):**
  - **WHEN** the runner enumerates suites, **THEN** each adapter-semantics entry **SHALL** occur exactly once and neither merge-policy alias **SHALL** remain (test_canonical_suite_inventory).
  - **WHEN** adapter semantics verification runs through the canonical names, **THEN** the same checker and fixture suite **SHALL** pass (canonical adapter-semantics and adapter-semantics-test).

### T-182: Publish the refined verification contract
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- **Touches:** README.md, tools/operator-docs.test.sh, all four scripts/bundle-version.sh copies, claude-code/.claude-plugin/plugin.json
- **Depends on:** T-177
- **Acceptance criterion:** The documented baseline procedure matches the tool's actual behavior, and all runtime bundles report one version.
- **Success criterion (EARS):**
  - **WHEN** an operator follows the documented procedure, **THEN** it **SHALL** require committed changes before producing a baseline and explain stale/unscorable evidence and failure diagnostics (operator-docs; real-baseline sensitivity E2E).
  - **WHEN** bundle identity and parity checks run, **THEN** all four bundles and the manifest **SHALL** agree on 0.22.0 (plugin-manifest, bundle-sync).

## Integration and Deferred Work
Runner consumers: CI, README operator commands, runner fixtures, sensitivity
fixtures, sensitivity's listing and mutated-run calls. Preserve existing ndjson
fields and normalized hashes; add source provenance rather than replace fields.
Failure diagnostics go to stderr so existing confirmation artifacts and CI logs
remain usable without an additional artifact format.
Run focused synthetic regressions at each task boundary, then the canonical
guard runner, and sensitivity against a committed current report. Keep T-178,
T-181, the full INT-0007 sweep, and broader memoization deferred. Hosted CI is
reported only if a checkpoint is authorized and actually run; local results
must not be represented as hosted Linux/macOS evidence.
