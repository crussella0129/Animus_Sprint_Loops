# Sprint 21 Unit Tests

Runner: `bash tools/run-guards.sh --determinism` (21 suites, all PASS).
Per-suite confirmations: `guards-report.ndjson` in this directory.

## T-172 — the line-ending primitive

| Test | Clause | Result |
|------|--------|--------|
| `test_book_cr_is_one_byte` | WHEN book-paths.sh is sourced THEN BOOK_CR SHALL be exactly one byte | pass |
| `test_crlf_predicate_sees_cr` | WHEN the first line ends in CRLF THEN the predicate SHALL return success on a host whose awk cannot observe a CR | pass |
| `test_crlf_predicate_rejects_lf` | WHEN called with an LF-only file THEN it SHALL return failure | pass |
| `test_crlf_predicate_empty_file` | WHEN called with an empty file THEN it SHALL return failure rather than an error | pass |
| `test_locked_plan_line_endings_audited` | WHEN this repository's locked plans are audited THEN the sprint SHALL record how many contain mixed endings | pass |

`BOOK_CR` is asserted first and deliberately. An empty `BOOK_CR` makes
`case "$x" in *"$BOOK_CR")` match every string, so every file reads as CRLF and
no other assertion in the suite can fail. That state occurred during
implementation — the seed was written `printf 'x\r'`, whose trailing CR command
substitution strips — and it was the fixture, not review, that caught it.

**Audit result:** 60 locked plans under `docs/sprints/*/sprint-plans/`;
60 all-LF, 0 all-CRLF, 0 mixed. The defect removed by this task had not yet
damaged this repository, because `core.autocrlf=input` here yields LF working
copies. Nothing to repair.

## T-173 — the runner's determinism label

| Test | Clause | Result |
|------|--------|--------|
| `test_failing_deterministic_suite_not_labelled` | WHEN a failing suite's two runs agreed THEN the line SHALL NOT contain det-mismatch | pass |
| `test_nondeterministic_suite_is_labelled` | WHEN two runs disagree THEN the line SHALL contain det-mismatch | pass |
| `test_passing_deterministic_suite_is_clean` | (guards the pair: neither may pass by reporting everything failed) | pass |

Sensitivity checked directly: with only the pre-fix label expression restored in
a copy, `test_failing_deterministic_suite_not_labelled` fails with
`a deterministic failure was labelled a determinism mismatch: FAIL extra:failing.sh 0s (status=FAIL det-mismatch)`.

## T-174 — the sensitivity check

| Test | Clause | Result |
|------|--------|--------|
| `test_insensitive_suite_is_caught` | WHEN a suite passes against a neutered subject THEN it SHALL be reported INSENSITIVE and exit non-zero | pass |
| `test_sensitive_suite_passes_the_check` | WHEN every scored suite fails against its neutered subject THEN the tool SHALL exit 0 | pass |
| `test_subjectless_suite_reported_not_failed` | WHEN a suite has no subject THEN it SHALL be reported no-subject and not counted as a failure | pass |
| `test_failing_baseline_is_not_scored` | WHEN the baseline is not PASS THEN the suite SHALL be reported skipped and not executed | pass |
| `test_sensitivity_leaves_worktree_clean` | WHEN the tool runs THEN it SHALL NOT modify any file under the working tree | pass |
| `test_suite_filter_limits_scope` | WHEN suite names are supplied THEN only those SHALL be scored | pass |
| `test_missing_baseline_refuses` | (added during build: without a baseline a verdict is meaningless) | pass |
| `test_list_suites_matches_runner` | WHEN --list-suites is invoked THEN it SHALL print every suite name and run none | pass |
| `test_list_subjects_covers_fixture_suites` | WHEN --list-subjects is invoked THEN it SHALL print a subject per fixture suite and omit self-subject suites | pass |

`test_insensitive_suite_is_caught` is the load-bearing one: a checker that never
detects anything passes every good-input fixture ever written. Verified against
a mutant whose detection is discarded — the fixture fails with
`exited 0 despite an insensitive suite`. A first attempt at that proof silently
failed to build its mutant and was discarded rather than believed.

## T-175 — the two assertion shapes

| Test | Clause | Result |
|------|--------|--------|
| `test_no_version_literal_assertions` | WHEN a fixture depends on the contract version THEN it SHALL assert the relationship against the constant | pass |
| `test_negative_assertions_are_paired` | (enumeration, not a gate — see below) | recorded |

Version literals converted: 2 (`substrate-version: 99` → `V+1`;
`substrate-version: 3` → `V-1`).

Enumeration: 51 negative assertions across 9 suites; the heuristic flagged 20
fixtures in `deploy-substrate` alone. **The enumeration over-reports and is not
a verdict.** Every flagged site inspected in `deploy-substrate`,
`remote-adapter`, `check-tracked` and `detect-languages` was already paired with
proof its command ran — largely by the sprint 19 and 20 repairs. Recorded so a
later sprint can compare, and explicitly not used as the gate.

A different check did find real defects. Cross-referencing each suite's `pass`
labels against the fixture names its assertions fail under found three:

- `remote-adapter.test.sh` — `test_checkpoint_reopen_is_inert` reported as
  passing while its three assertions failed under `test_checkpoint_recorded_once`.
- `remote-profile.test.sh` — `test_profile_enum_diagnostic_names_every_value`
  reported as passing while its assertions failed under
  `test_profile_rejects_malformed`.
- `book-routing.test.sh` — `test_routing_unchanged_for_unstamped_book` asserted
  but was never reported as passing at all.

All three fixed. A failure in any of them would have named the wrong test.

## T-176 — documentation and identity

| Test | Clause | Result |
|------|--------|--------|
| `test_readme_states_sensitivity_limit` | WHEN an operator reads the README THEN it SHALL state the check proves coupling, not detection of a subtly wrong answer | pass |
| `test_bundle_version_and_manifest_agree` | WHEN bundle-version.sh is invoked THEN it SHALL report 0.21.0 and the manifest SHALL agree | pass |
