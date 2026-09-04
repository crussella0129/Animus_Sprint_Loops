# INT-0013 — Verification that can fail, on the machine it runs on

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0013
- **State:** planned
- **Work evidence:** [T-172-T-176 build plan](../sprints/s21/sprint-plans/build-plan.md#execution-sequence), [Sprint 21 test plan](../sprints/s21/sprint-plans/test-plan.md)
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** none
- **Documentation evidence:** none

## Intent
The loop's gates are only as good as the evidence behind them, and for several
sprints that evidence has been the weakest artifact in the corpus rather than
the strongest. Two distinct failures produce the same outcome — a green result
that means nothing.

1. **A suite that cannot run is not evidence.** The canonical runner aborts on
   the operator's own platform before it reaches most of its suites, so local
   verification has been replaced by bespoke per-sprint checks and a wait for
   hosted CI. A gate an operator cannot execute is a gate that only exists in
   someone else's environment.

2. **An assertion that cannot fail is not evidence.** Fixtures have repeatedly
   passed while the property they name did not hold: a negative assertion that
   is satisfied when the command never ran, a `grep` for a code path that is
   dead at runtime, an assertion pinned to a literal that is true only until a
   constant moves. Each was found by a later reviewer rather than by the suite.

The desired outcome is that a green local run is worth the same as a green
hosted run, and that a suite goes red when its subject stops working.

## Acceptance criteria
- The canonical guard runner completes on Windows/MSYS2 and on POSIX CI with
  the same suite set and the same verdicts; no suite aborts the run because of
  the host's line-ending or text-mode behaviour.
- Line-ending detection anywhere in the corpus uses a primitive proven to
  observe a carriage return on every supported host, and the fixture that
  asserts line-ending preservation uses that same primitive rather than one
  that silently reports every file as LF.
- A suite whose subject is replaced by an inert stub fails. This is checked
  mechanically for every suite in the runner's list, and a suite that still
  passes against a neutered subject is reported by name.
- Every fixture asserting that something did not change is paired, in the same
  fixture, with proof that the command under test actually ran and succeeded.
- No fixture asserts equality against a version constant's current literal
  value; assertions state the relationship the property needs.
- The runner's console summary never reports a determinism mismatch for a suite
  whose two runs agreed.

## Rationale
Four consecutive sprints each shipped at least one fixture that passed without
its property holding, and in every case a later and more expensive reviewer
caught it: a plan critic, a code review, an external review. That ordering is
the problem. Review is a sampling process and will keep finding some of these,
but a defect class this repeatable should be caught by a mechanism, not by
whoever happens to look closely.

The two halves belong in one intent because they fail the same way from the
operator's seat. A suite that aborts on their machine and a suite that passes
vacuously are indistinguishable in the record: both produce a sprint that
closes with its gates satisfied and its behaviour unverified.

The neutered-subject check is deliberately a floor rather than a proof. It
establishes that a suite is coupled to its subject at all; it does not
establish that the suite would notice a subtle wrong answer. Sprint 20's dead
`pytest` tolerance would have survived it, because the fixture that missed the
defect was still coupled to the generator. Naming that limit is part of the
intent: the check buys the cheapest useful floor, and the paired-assertion and
no-literal criteria cover the shapes it cannot see.

## Alternatives
- **Full mutation testing.** Strictly stronger and the honest answer to
  "would the suite notice a subtle wrong answer". Rejected for now on cost: the
  runner is already slow enough that T-163 exists to address it, and mutating
  bash scripts meaningfully requires machinery the corpus does not have. The
  neutered-subject check is the degenerate first mutant, and the intent stays
  open to widening it.
- **A lint over fixture source.** Flag `die` calls whose assertion is negative
  and that have no preceding success check. Rejected as the primary mechanism:
  the heuristic is fragile against the many shapes these fixtures take, and a
  lint that misfires trains its own suppression. A one-time sweep plus the
  paired-assertion criterion gets the same coverage without a permanent
  false-positive source.
- **Rely on hosted CI as the real gate.** This is the status quo and it is what
  made the local abort tolerable for four sprints. Rejected because it moves
  the feedback from seconds to minutes, and because it concedes that the
  operator's own verification is decorative.
- **Fix the line-ending bug alone and leave the fixture-quality work to
  review.** Rejected: it treats the most visible instance and leaves the
  pattern that produced the others.

## Consequences
- Line-ending detection becomes a single shared primitive rather than an
  open-coded `awk` idiom, so the same misdetection cannot be reintroduced by
  copying a neighbouring script.
- The runner gains a mode that must be run when suites change, which costs
  wall time on a runner already flagged as slow (T-163). The mode is opt-in
  rather than part of every local run for that reason.
- Sweeping the existing negative assertions will change fixtures the sprint
  did not otherwise touch, which widens its diff beyond the code under change.
  That is the point, but it makes the sprint's review surface larger.
- Some fixtures currently passing may go red once they are paired with proof
  of execution. Those are findings, not regressions, and each needs a decision
  rather than a mechanical repair.

## Transition history
- 2026-09-03: created as `proposed` during Sprint 21 research, from four
  sprints of evidence — T-121/T-155 (the local abort), T-161 (unpaired negative
  assertions), T-169 (assertions against version literals), T-144 (a false
  determinism diagnostic in the runner itself), and Sprint 20's ultrareview
  finding that a fixture greped for a code path that `set -e` made dead.
- 2026-09-03: `proposed` -> `planned` - accepted into Sprint 21 as T-172
  through T-176. Planning added a finding research had not: the copy-and-
  neuter harness was prototyped before the plan was written, and its control
  run correctly refused to score three `tools/` suites that a scripts-only
  copy had broken. Without that control the mechanism would have reported
  them sensitive for the wrong reason - shipping the defect class it exists
  to catch. The control was then replaced by the guard runner's own report,
  which is cheaper and already proves each suite passes.
