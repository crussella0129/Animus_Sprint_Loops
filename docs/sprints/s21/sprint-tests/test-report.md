# Sprint 21 Test Report

## Intent Verification

| Intent | Acceptance criterion | EARS / tests | Result | Intent evidence update |
|--------|----------------------|--------------|--------|------------------------|
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | The canonical guard runner completes on Windows/MSYS2 and on POSIX CI with the same suite set and the same verdicts; no suite aborts on line-ending or text-mode behaviour | T-172 / `test_runtime_helpers_suite_completes`, `test_guard_runner_green_locally` | pass | Test evidence links this report |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Line-ending detection uses a primitive proven to observe a CR on every supported host, and the fixture asserting preservation uses that same primitive | T-172 / `test_crlf_predicate_sees_cr`, `test_crlf_predicate_rejects_lf`, `test_crlf_predicate_empty_file`, `test_book_cr_is_one_byte`, `test_finalize_preserves_uniform_crlf`, `test_finalize_preserves_uniform_lf`, `test_locked_plan_line_endings_audited` | pass | Test evidence links this report |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | A suite whose subject is replaced by an inert stub fails; checked mechanically for every suite in the runner's list, and a suite that still passes is reported by name | T-174 / `test_insensitive_suite_is_caught`, `test_sensitive_suite_passes_the_check`, `test_subjectless_suite_reported_not_failed`, `test_failing_baseline_is_not_scored`, `test_harness_subject_is_skipped`, `test_full_sweep_reports_no_insensitive_suite` | pass, after one finding | Test evidence links this report |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Every fixture asserting that something did not change is paired with proof the command ran | T-175 / `test_full_sweep_reports_no_insensitive_suite` (gate), `test_negative_assertions_are_paired` (recorded count) | pass | Test evidence links this report |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | No fixture asserts equality against a version constant's current literal | T-175 / `test_no_version_literal_assertions` | pass, **not mechanically guarded** — see Failures | Test evidence links this report; criterion partially met |
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | The console summary never reports a determinism mismatch for a suite whose two runs agreed | T-173 / `test_failing_deterministic_suite_not_labelled`, `test_nondeterministic_suite_is_labelled`, `test_passing_deterministic_suite_is_clean` | pass | Test evidence links this report |

INT-0013 stays `active`. Two of its criteria are met only in part — the
no-literal rule has no mechanical guard (T-178), and the sensitivity check is a
floor the intent itself defines as not a proof.

## Summary
- Unit tests: 23 passed / 0 failed / 23 total
- Integration tests: 5 passed / 0 failed / 5 total
- E2E tests: 2 passed / 0 failed / 2 total (one after a CI re-run — see below)
- CI status: green

## CI Confirmation
- **Head SHA:** `7661dac`
- **CI run:** [33835060603](https://github.com/crussella0129/Animus_Sprint_Loops/actions/runs/33835060603)
- **Conclusion:** success — **on re-run.** The first attempt failed on
  `guards (macos-latest)` with `NONDETERMINISTIC: merge-policy-test`;
  `guards (ubuntu-latest)` passed both times.
- **Confirmations:** `guards-report.ndjson` in this directory — one clean local
  `--determinism` run, 21 rows, 21/21 PASS, 21 `"determinism":"ok"`, 0
  mismatches. An earlier artifact merged two concurrent runs and was discarded
  rather than corrected; see `e2e-tests.md`.

## Failures

**One CI failure, resolved by re-run, root cause unknown.** The macOS leg's two
runs of `merge-policy-test` differed in exit code and evidence hash. The
determinism meta-check behaved correctly; something in the suite did not. It is
not reproducible on demand and cannot be diagnosed from the log, because the
runner deletes a failing suite's captured output. Recorded as **T-181**, with
**T-180** for the observability gap that blocks diagnosis. Explicitly not closed
as a flake.

**One sensitivity finding, resolved.** The first full sweep reported
`merge-policy-test` INSENSITIVE. The suite was correct; the subject mapping
written in T-174 named `tools/check-merge-policy.sh`, a sprint-14 compatibility
shim that `exec`s `check-adapter-semantics.sh`, so neutering it changed nothing
the suite observes. Mapping corrected; the suite now scores `sensitive`.

**One locked criterion met without a mechanical guard.** T-175's version-literal
clause was verified by inspection, not by a fixture. Nothing prevents
reintroduction — which is what T-169 was filed for, and it recurred inside a
single sprint. Deferred as **T-178** rather than patched in after Build.

## Technical Debt Identified
- **T-177** — [INT-0007](../../../intents/INT-0007-integrity-sweep.md): remove
  the `merge-policy` shims. Both the checker and its test `exec` the
  adapter-semantics pair, so the runner has executed those fixtures twice per
  run since sprint 14. Measured this sprint: `merge-policy-test` 634s and
  `adapter-semantics-test` 619s in one clean run — about 1253s of duplicated
  work, and the duplicate is also the suite that flaked in CI.
- **T-178** — the no-version-literal rule needs a guard and fixtures.
- **T-179** — `check-suite-sensitivity.sh` trusts a baseline it never validates
  against `script_hash`; a stale PASS would produce a wrong verdict.
- **T-180** — the runner discards failing suites' output.
- **T-181** — the unexplained macOS nondeterminism above.
- **T-163** — runner wall time, now measured rather than argued: one clean
  `--determinism` run takes roughly 50 minutes on this host, and T-177 alone
  would remove about a fifth of it.

## Coverage Observations

The sprint's own headline defect is the clearest coverage lesson. Fixing the
line-ending predicate made roughly 330 lines of `runtime-helpers.test.sh`
reachable for the first time since sprint 18, and what they immediately exposed
was not a fixture problem but a production one: four scripts —
`abort-sprint.sh`, `close-sprint.sh`, `commit-task.sh`, `remote-adapter.sh` —
silently rewrote CRLF Book files as LF on Windows. A suite that cannot run is
indistinguishable in the record from a suite that passes, and it hid a real
data-normalization bug for four sprints.

Three further defects were found by a check nobody had written: cross-referencing
each suite's `pass` labels against the fixture names its assertions fail under.
Two fixtures would have failed under a *different* fixture's name, and one
asserted without ever being reported as passing. That check is not mechanized
either, and is a candidate to fold into T-178.

The sensitivity check earned its place on its first real run by finding a wrong
subject mapping — but note carefully what it found: a defect in *this sprint's
own new code*, not in the suites it was built to police. Every suite it scored
was already coupled to its subject. That is consistent with the intent's own
claim that the check is a floor, and it is worth remembering before treating a
clean sweep as evidence the suites are good.
