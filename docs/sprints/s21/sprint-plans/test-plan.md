Finalized - DO NOT EDIT

# Sprint 21 Test Plan

## Intent Traceability

| Intent | Acceptance criterion | Build task / EARS clause | Verification |
|--------|----------------------|--------------------------|--------------|
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Line-ending detection uses a primitive proven to observe a CR on every supported host | T-172 / WHEN a first line ends in CRLF THEN the predicate SHALL return success on a host whose awk cannot observe a CR | `test_crlf_predicate_sees_cr` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Line-ending detection uses a primitive proven to observe a CR | T-172 / WHEN called with an LF-only file THEN it SHALL return failure | `test_crlf_predicate_rejects_lf` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Line-ending detection uses a primitive proven to observe a CR | T-172 / WHEN called with an empty file THEN it SHALL return failure rather than an error | `test_crlf_predicate_empty_file` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Line-ending detection uses a primitive proven to observe a CR | T-172 / WHEN book-paths.sh is sourced THEN BOOK_CR SHALL be exactly one byte | `test_book_cr_is_one_byte` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | The fixture asserting line-ending preservation uses that same primitive | T-172 / WHEN a CRLF plan is locked THEN every line including the header SHALL end in CRLF | `test_finalize_preserves_uniform_crlf` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | The fixture asserting line-ending preservation uses that same primitive | T-172 / WHEN an LF-only plan is locked THEN no line SHALL end in CR | `test_finalize_preserves_uniform_lf` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | The runner completes on Windows/MSYS2 and POSIX CI with the same suite set and verdicts | T-172 / (all clauses) | `test_runtime_helpers_suite_completes` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Line-ending detection uses a primitive proven to observe a CR | T-172 / WHEN the repository's locked plans are audited THEN the sprint SHALL record how many contain mixed endings and repair or accept each | `test_locked_plan_line_endings_audited` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | The console summary never reports a determinism mismatch for a suite whose two runs agreed | T-173 / WHEN a failing suite's two runs agreed THEN the line SHALL NOT contain det-mismatch | `test_failing_deterministic_suite_not_labelled` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | The console summary never reports a determinism mismatch for a suite whose two runs agreed | T-173 / WHEN two runs disagree THEN the line SHALL contain det-mismatch | `test_nondeterministic_suite_is_labelled` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Checked mechanically for every suite in the runner's list | T-174 / WHEN --list-suites is invoked THEN it SHALL print every suite name and run none | `test_list_suites_matches_runner` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Checked mechanically for every suite in the runner's list | T-174 / WHEN --list-subjects is invoked THEN it SHALL print a subject for every fixture suite and omit self-subject suites | `test_list_subjects_covers_fixture_suites` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | A suite that still passes against a neutered subject is reported by name | T-174 / WHEN a suite passes against a neutered subject THEN it SHALL be reported INSENSITIVE and exit non-zero | `test_insensitive_suite_is_caught` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | A suite whose subject is replaced by an inert stub fails | T-174 / WHEN every scored suite fails against its neutered subject THEN the tool SHALL exit 0 | `test_sensitive_suite_passes_the_check` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Checked mechanically for every suite in the runner's list | T-174 / WHEN a suite has no subject script THEN it SHALL be reported no-subject and not counted as a failure | `test_subjectless_suite_reported_not_failed` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Checked mechanically for every suite in the runner's list | T-174 / WHEN the baseline is not PASS THEN the suite SHALL be reported skipped:baseline-not-pass and not scored | `test_failing_baseline_is_not_scored` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | A suite whose subject is replaced by an inert stub fails | T-174 / WHEN the tool runs THEN it SHALL NOT modify any file under the repository working tree | `test_sensitivity_leaves_worktree_clean` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | A suite whose subject is replaced by an inert stub fails | T-174 / WHEN suite names are supplied THEN only those suites SHALL be scored | `test_suite_filter_limits_scope` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Every negative assertion is paired with proof the command ran | T-175 / WHEN a fixture asserts something did not change THEN it SHALL also assert the command exited successfully | `test_full_sweep_reports_no_insensitive_suite` (gate), `test_negative_assertions_are_paired` (recorded count) |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | No fixture asserts equality against a version constant's current literal | T-175 / WHEN a fixture depends on the contract version THEN it SHALL assert the relationship against the constant | `test_no_version_literal_assertions` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | A suite that still passes against a neutered subject is reported by name | T-175 / WHEN the sweep is complete THEN the sensitivity check SHALL report no suite as INSENSITIVE | `test_full_sweep_reports_no_insensitive_suite` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | (supporting) the check's limit is documented | T-176 / WHEN an operator reads the README THEN it SHALL state the check proves coupling, not detection of a subtly wrong answer | `test_readme_states_sensitivity_limit` |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | (supporting) bundle identity | T-176 / WHEN bundle-version.sh is invoked THEN it SHALL report 0.21.0 and the manifest SHALL agree | `test_bundle_version_and_manifest_agree` |

## Unit Tests

### T-172 unit tests
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- `test_crlf_predicate_sees_cr`: a file whose first line ends `\r\n` → predicate
  returns 0. Asserted on this host, where `awk` returns the opposite answer; the
  fixture additionally records that the `awk` form disagrees, so the test proves
  the primitive was changed rather than that the file happens to be CRLF.
- `test_crlf_predicate_rejects_lf`: LF-only file → returns non-zero.
- `test_crlf_predicate_empty_file`: zero-byte file → returns non-zero, no
  diagnostic on stderr, no non-empty exit status other than 1.
- `test_book_cr_is_one_byte`: `${#BOOK_CR} -eq 1` — the assumption the whole
  task rests on, and the one command substitution could silently break.
- `test_locked_plan_line_endings_audited`: every already-locked plan under
  `docs/sprints/*/sprint-plans/` is classified with the new primitive as
  all-LF, all-CRLF, or mixed. The count of each lands in the test report, and a
  mixed file is either repaired in this sprint or named with a reason. This
  closes the research unknown the first plan draft dropped (C-002); the fix
  removes the cause, and only the audit says whether damage already exists.
- Stubs: none.

### T-173 unit tests
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- `test_failing_deterministic_suite_not_labelled`: an extra suite that fails
  identically twice, via `RUN_GUARDS_EXTRA_SUITES` → console FAIL line contains
  no `det-mismatch`, and its ndjson record carries `"determinism":"ok"`.
- `test_nondeterministic_suite_is_labelled`: an extra suite whose output differs
  between runs → console line contains `det-mismatch` and ndjson carries
  `"determinism":"mismatch"`.
- Stubs: extra suites written into a `RUN_GUARDS_EXTRA_SUITES` directory.

### T-174 unit tests
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- `test_insensitive_suite_is_caught`: the load-bearing test. Plant a subject
  script and a suite that asserts only that the subject exits 0 → the tool
  reports it `INSENSITIVE` by name and exits non-zero. Without this the tool
  could pass by never detecting anything.
- `test_sensitive_suite_passes_the_check`: a suite that asserts its subject's
  output → reported `sensitive`, tool exits 0.
- `test_subjectless_suite_reported_not_failed`: a suite with no subject mapping
  → reported `no-subject`, exit 0.
- `test_failing_baseline_is_not_scored`: a guard report recording FAIL for a
  suite → reported `skipped:baseline-not-pass`, and the suite is not executed
  (proved by a marker the suite would write if it ran).
- `test_suite_filter_limits_scope`: two planted suites, one named as an argument
  → only the named one appears in the report.
- `test_list_suites_matches_runner`: `--list-suites` output equals the `SUITES`
  array, and no `guards-report.ndjson` is written by that invocation.
- `test_list_subjects_covers_fixture_suites`: every printed subject path exists;
  `selftest`, `operator-docs`, `shellcheck`, `merge-policy`, `bundle-sync`,
  `plugin-manifest` and `adapter-semantics` are absent from the output.
- Stubs: a synthetic repository containing planted subject/suite pairs and a
  hand-written `guards-report.ndjson`.

### T-175 unit tests
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- `test_negative_assertions_are_paired`: an enumeration, not a gate. It counts
  the negative assertions in every suite and how many sit in a fixture that also
  asserts the command succeeded, and records both numbers in the test report so
  a later sprint can see whether the set grew. Stating this plainly matters:
  this sprint exists because review kept being the thing that caught these
  defects, so a hand-checked clause must not be mistaken for enforcement
  (C-001).
- The enforcement for this criterion is
  `test_full_sweep_reports_no_insensitive_suite` below. A suite whose negative
  assertions are unpaired is exactly a suite that still passes when its subject
  is neutered, so the sensitivity check fails it mechanically and by name.
- `test_no_version_literal_assertions`: no `.test.sh` compares a stamped version
  to a bare integer that equals the current contract version.
- Stubs: none.

### T-176 unit tests
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- `test_readme_states_sensitivity_limit`: asserted through
  `tools/operator-docs.test.sh` against a token that appears on one line, since
  a phrase split across a line break defeats a fixed-string match.
- `test_bundle_version_and_manifest_agree`: existing
  `tools/check-plugin-manifest.sh` coverage, re-run after the bump.

## Integration Tests

### Line-ending preservation end to end
- **Intents:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- `test_finalize_preserves_uniform_crlf`: a CRLF build and test plan through
  `finalize-plan.sh` → every line of both locked plans, including the prepended
  `Finalized - DO NOT EDIT` header and its blank line, ends in CRLF. Checked
  with the new primitive over all lines, not the first.
- `test_finalize_preserves_uniform_lf`: the LF case, so the fix cannot pass by
  declaring everything CRLF.
- `test_runtime_helpers_suite_completes`: the whole `runtime-helpers.test.sh`
  suite runs to its final assertion on this host. This is the criterion that has
  been unmet for four sprints; any assertion it newly reaches and fails is
  recorded in the test report as a finding.

### The sensitivity check against the real corpus
- **Intents:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- `test_full_sweep_reports_no_insensitive_suite`: `check-suite-sensitivity.sh`
  over every suite in the runner's list, using a green `guards-report.ndjson` as
  baseline → no suite reported `INSENSITIVE`. Run in the background; the
  resulting report is committed as sprint evidence.
- `test_sensitivity_leaves_worktree_clean`: `git status --porcelain` is
  byte-identical before and after the sweep.

## End-to-End Tests
- **Status:** possible
- `test_guard_runner_green_locally`: `bash tools/run-guards.sh --determinism`
  completes with every suite PASS on this host. Distinct from CI: the point is
  that the operator's own machine now produces the same verdict set as the
  hosted runner, which is INT-0013's first acceptance criterion.
- `test_ci_green_on_both_legs`: the hosted matrix passes on the pushed head, so
  the local and hosted verdicts can be compared rather than assumed equal.
- Pass/fail criteria: both legs green and a local `--determinism` run green with
  19+ suites; any suite that is green in one environment and not the other is a
  sprint failure, not a flake, and is recorded as such.
