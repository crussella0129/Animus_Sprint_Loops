# Test Critique — Sprint 21

## Concerns

### C-001: The confirmations artifact was contaminated across two runs
- **Where:** `sprint-tests/guards-report.ndjson` (as first written) / `e2e-tests.md`
- **Quote:** "every suite `\"determinism\":\"ok\"`"
- **Failure mode:** evidence-drift
- **Why it matters:** Two `--determinism` runs executed concurrently against the
  same output path, and the artifact was produced by keeping the last row per
  suite. That merges rows from two different runs into a file presented as one.
  The merge was not merely untidy: the retained `selftest` row carried
  `"determinism":"mismatch"`, a verdict from the interrupted run, while the
  summary line quoted alongside it came from the run that finished clean. The
  report therefore asserted a determinism result its own confirmations
  contradicted. In a sprint whose entire claim is that evidence must be able to
  fail, shipping a confirmations file assembled from two runs would be
  self-defeating.
- **Suggested response:** fix-in-evidence — discard both merged artifacts and
  re-run the canonical suite alone, recording a single run's confirmations.
- **Resolution:** applied. Both files removed; `run-guards.sh --determinism`
  re-run with no competing process, and that run's confirmations are the
  recorded artifact. `e2e-tests.md` rewritten against it. The contention episode
  is retained in that record rather than deleted, because how the evidence went
  wrong is itself worth keeping.

### C-002: Two locked EARS clauses have no executed test
- **Where:** `build-plan.md` T-175 clauses 1 and 2 / `unit-tests.md` T-175
- **Quote:** "`test_negative_assertions_are_paired`: an enumeration, not a gate."
- **Failure mode:** intent/EARS-trace-gap
- **Why it matters:** Both are named as tests in the locked test plan, and
  neither exists as a fixture in the corpus. They were performed once, by hand,
  during this sprint. Clause 1 is genuinely covered by a mechanical check —
  an unpaired negative assertion is what an insensitive suite *is*, and the
  sweep gates that. Clause 2 is not: nothing stops a future fixture from
  asserting against a version constant's current literal, which is precisely
  the defect T-169 was filed for and which recurred inside a single sprint.
- **Suggested response:** defer-with-rationale, and file the mechanical check.
- **Resolution:** deferred as **T-178**. Adding a guard after Build would ship
  a check with no fixtures of its own, which is the failure this sprint exists
  to end. The plan critique (C-001) already named the enumeration as a weak
  instrument and made the sweep the gate; this records that clause 2's half of
  that reasoning does not hold, rather than leaving it implied.

### C-003: The sensitivity check trusts a baseline it never validates
- **Where:** `tools/check-suite-sensitivity.sh` `baseline_status`
- **Quote:** "the baseline comes from a guard report rather than a control run per suite"
- **Failure mode:** flake-risk
- **Why it matters:** The tool reads a `guards-report.ndjson` from any point in
  the past and treats a `PASS` row as current fact. A baseline generated before
  a code change would let the tool score a suite that no longer passes, and a
  neutered result is meaningless for such a suite. The confirmations already
  carry `script_hash` for exactly this purpose and the tool ignores it. This
  sprint hit the adjacent version of the problem — a stale, merged report — and
  only caught it by reading the rows.
- **Suggested response:** defer-with-rationale.
- **Resolution:** deferred as **T-179**. The exposure today is bounded: the
  tool refuses outright when no report exists, and skips any suite whose row is
  not `PASS`. The gap is a *stale* PASS, which needs the `script_hash`
  comparison and a fixture proving a stale baseline is refused — more than an
  after-Build patch should carry.

## Confidence
proceed-with-caveats
