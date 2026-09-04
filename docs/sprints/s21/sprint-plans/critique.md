# Plan Critique — Sprint 21

## Concerns

### C-001: The paired-assertion criterion's first clause is enforced only by review
- **Where:** `build-plan.md` T-175 first EARS clause / `test-plan.md` T-175 unit tests
- **Quote:** "`test_negative_assertions_are_paired`: a review-completeness check rather than a runtime assertion — enumerate the negative assertions in every suite and confirm each sits in a fixture that also asserts the command's success."
- **Failure mode:** plan-test-mismatch
- **Why it matters:** This sprint exists because review kept being the thing that
  caught these defects. A clause whose only verification is a careful read
  reproduces the exact failure it is meant to end: the moment a new fixture is
  written after this sprint, nothing fails. The clause is stated as a permanent
  property of the corpus but is checked once, by hand.
- **Suggested response:** fix-in-plan — say plainly which clause is the gate.
  T-175's third clause (the sensitivity sweep reporting no `INSENSITIVE` suite)
  is a real mechanical check and is precisely the enforcement for unpaired
  negatives at suite granularity. Demote the enumeration to a reported count
  that a later sprint can compare against, and stop implying it gates anything.
- **Resolution:** applied. The traceability row for that clause now names
  `test_full_sweep_reports_no_insensitive_suite` as the gate and
  `test_negative_assertions_are_paired` as a recorded count, and the test plan
  states outright that an unpaired negative *is* an insensitive suite, so the
  mechanical check covers the clause the enumeration only measures.

### C-002: A research risk was dropped between the report and the plan
- **Where:** `research-report.md` §4 / `build-plan.md` (absent)
- **Quote:** "Unknown: whether the awk misdetection has already produced a mixed-ending plan in this repository's own history. Worth one check during Build; it affects whether anything needs repairing beyond the code."
- **Failure mode:** missing-risk
- **Why it matters:** The research named a cheap check with a real consequence —
  if locked plans in this repository are already mixed-ending, the sprint fixes
  the cause and silently leaves the damage. No task, test, or deferral mentions
  it, which is how a known unknown becomes an unknown.
- **Suggested response:** fix-in-plan — add it to T-172 as an explicit step with
  a recorded outcome, whether the answer is "none found" or a list.
- **Resolution:** applied. T-172 gains an audit clause over this repository's
  already-locked plans, with `test_locked_plan_line_endings_audited` requiring
  the counts in the test report and every mixed file repaired or named.

### C-003: T-175 depends on T-174 and does not say so
- **Where:** `build-plan.md` T-175 "Depends on: T-172"
- **Quote:** "**WHEN** the sweep is complete, **THEN** the sensitivity check from T-174 **SHALL** report no suite as `INSENSITIVE`."
- **Failure mode:** hidden-dep
- **Why it matters:** T-175's own success clause invokes a tool built in T-174,
  so the declared dependency is incomplete and the execution order the plan
  implies is not the one it needs. T-175 and T-176 also both touch
  `tools/operator-docs.test.sh` under a `tools/*.test.sh` glob without either
  naming the overlap.
- **Suggested response:** fix-in-plan — declare T-174, and narrow T-176's touched
  paths so the two tasks do not claim the same file.
- **Resolution:** applied. T-175 now declares `T-172, T-174`, and its touched
  paths exclude `tools/operator-docs.test.sh`, which T-176 owns.

### C-004: T-173 mixes a bug fix with a feature its consumer needs
- **Where:** `build-plan.md` T-173
- **Quote:** "Make the `det-mismatch` label expand only on an actual mismatch … Add `suite_subject()`, `--list-suites` and `--list-subjects`."
- **Failure mode:** granularity
- **Why it matters:** Two unrelated observable outcomes in one task — a false
  diagnostic that has been misreporting failures for four sprints, and a listing
  interface that exists solely so T-174 can consume it. They produce an
  incoherent diff, and the acceptance criterion named on the task covers only
  the first.
- **Suggested response:** fix-in-plan — leave T-173 as the determinism-label fix
  alone, and move `suite_subject()` and the listing flags into T-174, which is
  their only consumer. This also removes the T-173 → T-174 dependency.
- **Resolution:** applied. T-173 is now the determinism-label fix alone;
  `suite_subject()`, `--list-suites` and `--list-subjects` moved to T-174, their
  only consumer, which also removed the T-173 -> T-174 dependency.

## Confidence
proceed-with-caveats
