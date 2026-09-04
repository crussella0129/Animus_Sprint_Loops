# Sprint 21 Research Report

## Intents Reviewed
- [INT-0013](../../../intents/INT-0013-verification-integrity.md) — created;
  relevance: owns this sprint's whole goal, that a green local run means what it
  says; current state: `proposed`.
- [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) —
  selected; relevance: hosts T-155 and T-161, the two backlog entries that first
  named the local abort and the unpaired negative assertions; current state:
  `active`. Not advanced by this sprint beyond retiring those entries.
- [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) —
  selected; relevance: hosts T-144 and T-169, the runner's false determinism
  diagnostic and the version-literal assertions its contract raise exposed;
  current state: `realized`, and this sprint does not reopen it.
- [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) — selected;
  relevance: Sprint 20's ultrareview finding — a fixture that greped for a code
  path `set -e` had made dead — is the clearest single instance of the defect
  class INT-0013 exists to close; current state: `active`, untouched here.

## 1. Sprint Goal
Make the loop's own verification trustworthy on the machine the operator runs
it on. Two failures produce the same worthless green: a suite that aborts before
it reaches most of the corpus, and an assertion that passes while the property
it names does not hold. This sprint fixes the abort at its root, removes a false
diagnostic in the runner itself, adds a mechanical floor that a suite must fail
when its subject is neutered, and sweeps the two assertion shapes that have now
produced defects in four consecutive sprints. It does not attempt mutation
testing, and it does not widen the Test phase's oracle.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| `open-harnesses/scripts/finalize-plan.sh` | high | Lines 178 and 183 detect CRLF with an `awk` `substr` idiom. On this host that awk cannot see a CR at all, so every CRLF plan is treated as LF and given an LF header — producing exactly the mixed line endings the branch exists to prevent. |
| `open-harnesses/scripts/runtime-helpers.test.sh` | high | Line 231 asserts CRLF preservation with the *same* awk idiom, so the fixture is blind in the same direction as the code. It is the first assertion to fail on this host and it aborts the suite, leaving lines 232–560 — including every contract-3 gate fixture — unexecuted locally. |
| `tools/run-guards.sh` | high | Line 178's `${det:+ det-mismatch}` expands whenever `det` is *set*, and `det` is set to the `"ok"` payload on agreement, so every failing suite in a `--determinism` run is labelled a determinism mismatch. The ndjson field at lines 161/165 is correct; only the human-facing summary lies. Also owns `SUITES` (19 entries), the natural place for a neutered-subject check. |
| `open-harnesses/scripts/deploy-substrate.test.sh` | high | 26 negative assertions, the highest density in the corpus, and the suite where two of them were already found passing for the wrong reason in Sprint 19. Has one paired helper, `assert_check_ran_quietly` (line 385), which is the shape the sweep should generalize. |
| `open-harnesses/scripts/scaffold-ci.test.sh` | medium | Sprint 20's dead-tolerance defect lived here; the repaired fixture (line 156) now executes the generated script rather than greping it, and is the model for "prove the behaviour, not the text". Four negative assertions remain. |
| `open-harnesses/scripts/check-tracked.test.sh` | medium | Line 79 seeds a stamp of 2 and line 82 asserts it is `-lt "$BOOK_SUBSTRATE_CONTRACT_VERSION"`. This is the *repaired* form from Sprint 20 and the pattern the sweep should enforce elsewhere. |
| `open-harnesses/scripts/remote-adapter.test.sh` | medium | Six negative assertions; the contract-2/contract-3 pairs at lines 228–232 are safe today because the gate minimum is a fixed 3, but they are the shape most likely to be copied into an unsafe instance. |
| `open-harnesses/scripts/remote-profile.test.sh` | medium | Six negative assertions, unswept. |
| `open-harnesses/scripts/book-routing.test.sh` | low | Two negative assertions. |
| `open-harnesses/scripts/migrate-to-book.test.sh` | low | Two negative assertions. |
| `open-harnesses/scripts/detect-languages.test.sh` | low | Two negative assertions. |
| `open-harnesses/scripts/sync-work-branch.test.sh` | low | One negative assertion. |
| `tools/check-plugin-manifest.test.sh` | low | Two negative assertions. 51 across the corpus in total — small enough to sweep exhaustively. |
| `open-harnesses/scripts/book-paths.sh` | medium | Already the home of the shared substrate accessors; the natural place for one line-ending primitive, so the broken idiom cannot be re-copied from a neighbour. |
| `docs/work/tasks.md` | high | T-121, T-144, T-155, T-161 and T-169 are the five backlog entries this sprint retires. T-163 (runner wall time) constrains how expensive the new check may be. |

## 3. External Sources
- None. Every finding is reproduced directly on the affected host; the probe
  artifact is the evidence, and a vendor documentation claim would be weaker
  than the measurement.

## 4. Risks, Unknowns, Dependencies
- **Finding (not a risk): the fix named in the backlog does not work.** T-121
  proposes detecting the CR by pattern-matching a command substitution of
  `head -n1`. Command substitution strips a trailing CR along with the newline
  on this host, so that form reports LF for every CRLF file — it would have
  passed POSIX CI and left the bug in place on the only platform that has it.
  Measured, 5/5 runs.
- **Finding: `grep` is self-inconsistent here and must not be used.** For the
  same file and the same pattern, `grep -c` counts 2 matches and `grep -q`
  reports none, reproducibly across 5 runs each. The usable primitives are
  `IFS= read -r` and the byte tools (`head -c`, `od`, `tr`, `wc -c`).
- **Risk: fixing the fixture unblocks 300+ lines of assertions that have not
  run locally for four sprints.** Some may fail for reasons unrelated to line
  endings. That is a benefit, but it can turn a small task into an open-ended
  one, so the sprint must treat any such failure as a finding to record rather
  than an obligation to repair in place.
- **Risk: the neutered-subject check costs wall time on a runner T-163 already
  flags as slow.** Mitigate by making it a separate mode rather than part of
  every run, and by letting each suite stop at its first assertion failure,
  which is the common case and is fast.
- **Unknown: how many suites survive neutering.** If the number is large the
  sprint must report rather than repair, or it becomes unbounded. The check's
  first run is itself a finding.
- **Unknown: whether the awk misdetection has already produced a mixed-ending
  plan in this repository's own history.** Worth one check during Build; it
  affects whether anything needs repairing beyond the code.
- **Dependency: none external.** All four bundles carry copies of the affected
  scripts, so every change is a four-way parity edit enforced by
  `tools/check-bundle-sync.sh`.

## 5. Recommended Approach
Primary — four tasks, in dependency order:

1. **One line-ending primitive, used by both the code and its fixture.** Add a
   first-line CRLF predicate to `book-paths.sh` built on `IFS= read -r`,
   replace both `awk` sites in `finalize-plan.sh`, and rewrite the
   `runtime-helpers.test.sh` assertion to check *every* line with the same
   primitive rather than sampling with a blind one. Then run the suite to the
   end and record what the previously unreachable assertions say.
2. **Repair the runner's false diagnostic.** Make the `det-mismatch` label
   expand only on an actual mismatch. One line, and it removes a message that
   has been misdescribing every failure in every `--determinism` run.
3. **A neutered-subject mode for the runner.** `--sensitivity` replaces each
   suite's subject script with an inert stub, runs the suite, and requires it to
   fail; any suite that still passes is reported by name. Scope it honestly in
   the docs: it proves coupling, not correctness.
4. **Sweep the two assertion shapes.** Pair all 51 negative assertions with
   proof the command ran, generalizing `assert_check_ran_quietly`; and replace
   any assertion against a version constant's current literal with the
   relationship the property actually needs.

Alternative considered: fix only T-121 and T-144 and leave the fixture-quality
work to review. Rejected — that is what the last four sprints did, and each of
them shipped another instance. The abort is the visible symptom; the assertion
shapes are the cause.

Rationale: tasks 1 and 2 remove two mechanisms that actively misinform the
operator, and are small and certain. Task 3 buys a cheap mechanical floor where
review has been carrying the load. Task 4 is the one-time cost of a backlog
already written down. Ordering matters: task 1 must land first, because until
the suite runs to completion on this host the sprint cannot see the evidence
tasks 3 and 4 will produce.

## Artifacts
- `line-ending-probe.txt` — measured CR visibility for seven primitives on this
  host, five runs each, including the two contradictory `grep` results, proof
  that writing CRLF is unaffected, and the current suite failure it causes.
