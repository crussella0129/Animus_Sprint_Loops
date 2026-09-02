# INT-0005 — One sprint per turn, one titled checkpoint per sprint, from committed evidence

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0005
- **State:** planned
- **Work evidence:** [T-146–T-151 build plan](../sprints/s18/sprint-plans/build-plan.md#execution-sequence), [Sprint 18 test plan](../sprints/s18/sprint-plans/test-plan.md)
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** none
- **Documentation evidence:** none

## Intent
Close the four ways a sprint can currently end in a state the protocol says is
impossible.

1. **Checkpoint gate.** `remote-adapter.sh open-pr` refuses unless the router
   reports `ready-for-next-sprint` and the current sprint's metadata carries a
   terminal `Exit status`. Opening a checkpoint before the sprint closes becomes
   mechanically impossible rather than discouraged.
2. **Composed checkpoint title.** The adapter derives `Sprint <N>: <Summary>`
   from `current-sprint.sh` and the sprint metadata `Summary` field, and
   composes the body from the sprint record. A supplied `--title` is validated
   against that shape or refused.
3. **Tracked-evidence gate.** A new helper asserts that each phase's exit
   artifacts are git-tracked and free of uncommitted modification, wired into
   `finalize-plan.sh`, `close-sprint.sh`, and the checkpoint path. Every phase
   contract states committal as part of its Exit evidence.
4. **Work-branch guard.** `commit-task.sh` and `close-sprint.sh` refuse to
   commit while `HEAD` is not the profile's `work` branch, and
   `check-substrate.sh` reports the wrong-branch condition by name as a distinct
   state — branch position is a session property, so folding it into the
   missing-element list would misreport a complete substrate as incomplete. A
   create-if-absent local pre-commit hook covers hosts with no server-side
   protection; server-side protection belongs to INT-0006.

Every gate here binds only at or above the substrate contract version that
introduces it ([INT-0004](INT-0004-substrate-contract-versioning.md)), so an
un-converged project behaves exactly as it does today.

The checkpoint URL is recorded back into sprint metadata so a later sprint can
distinguish its own checkpoint from the previous one without querying the
provider.

Non-goal: this intent does not attempt to prevent an agent from ending its turn
early. See Consequences.

## Acceptance criteria
- `open-pr` invoked in Research, Plan, Build, Test, or an open Loop exits
  non-zero with a diagnostic naming the current phase, and opens nothing.
- With no title supplied, the opened checkpoint is titled exactly
  `Sprint <N>: <the sprint's Summary>`; a malformed supplied title is refused.
- A phase whose exit artifact exists but is untracked or dirty cannot close;
  the diagnostic names the offending path.
- A task commit attempted while `HEAD` is the base branch is refused before
  anything is staged.
- Re-running the checkpoint path for a sprint that already has one still opens
  no second request, and the recorded URL is unchanged.
- An un-converged Book (INT-0004) is unaffected by all four gates.

## Rationale
The Exit-evidence contracts define completion as files existing. Under "the
filesystem is the state machine," an untracked file is indistinguishable from a
committed one, so every phase can pass with the entire Book uncommitted and no
work ever pushed — phases 02 through 05 do not mention git at all, and the only
remote language lives in the adapter, framed as a sprint-close concern. That is
the structural cause of observed sprints that produced a checkpoint without
producing a corpus.

The checkpoint gate addresses the observed failure directly: a checkpoint opened
mid-sprint is the visible symptom of a turn that ended early, and it is the part
that does real damage, because it invites a human to review an incomplete
sprint. The title rule matters for the same reason the Book matters — the
checkpoint list is a project's most-read index, and `Sprint checkpoint: dev ->
main` repeated fifteen times indexes nothing.

## Alternatives
- **Stronger instructions in the phase docs.** Already tried; both Claude Code
  and Codex have walked past them. Prose is not a gate.
- **Gate committal inside `current-phase.sh`.** Would make routing depend on git
  state and break the pure-function property that cross-harness resume relies
  on. Rejected in favor of gating at the exit helpers.
- **Auto-commit at each phase exit.** Removes the operator's control over commit
  boundaries and would produce commits with no scoped meaning. The existing
  scoped `commit-task.sh` boundary is the better model, so the gate refuses
  rather than committing on the operator's behalf.
- **Per-sprint branches to make premature checkpoints harmless.** Contradicts
  INT-0002's established two-branch model.

## Consequences
- A project that has been running with an uncommitted Book will fail to close
  until it commits. That failure is the point, but it will be the first visible
  effect of this intent and needs a diagnostic that says exactly what to do.
- No bash helper runs when an agent simply stops talking, so "one sprint per
  turn" cannot be enforced from the substrate. The enforceable surface is the
  artifacts of a premature stop — the early checkpoint, the uncommitted Book,
  work stranded on the base branch. The turn contract in the phase docs names
  the only legal stop points; it remains advisory by nature.
- The wrong-branch guard will occasionally refuse a legitimate operation during
  migration or recovery work. The diagnostic must name the expected branch, and
  the escape is a deliberate branch switch, not a flag.
- Antigravity does not call `finalize-plan.sh` and will not inherit these gates
  until its translation layer invokes the helpers. That decision is a
  prerequisite for claiming the contract holds across adapters.
- The checkpoint gate invalidates every existing `remote-adapter.test.sh`
  fixture: all five build a git repo and a remote profile with no Book at all,
  and under a phase gate each is refused as `uninitialized`. They must gain a
  closed-sprint Book while keeping the assertion each was written to make. This
  is a mechanical cost of the gate, not a defect in the fixtures.
- The local pre-commit hook is separable from the rest of this intent and may
  land in a later sprint than the gates. Once `commit-task.sh` refuses on the
  wrong branch, the first Build task already catches the observed failure; the
  hook only extends coverage to commits made outside the helpers, and it writes
  to an untracked location that is never cloned and may be redirected by
  `core.hooksPath`. This intent therefore stays `active` across more than one
  sprint rather than being claimed as realized on a partial delivery.

## Transition history
- 2026-09-02: created as `proposed` — derived from operator feedback items 1.a
  through 1.d and 2.a, covering premature checkpoints, unformatted checkpoint
  titles, evidence that passes while untracked, and a full sprint accidentally
  executed on the base branch.
- 2026-09-02: revised during Sprint 18 Research — recorded that the checkpoint
  gate invalidates all five existing adapter fixtures until they gain a
  closed-sprint Book, scoped the local pre-commit hook as separable and
  potentially later than the gates, made the version-conditioning requirement
  explicit, and stated why the wrong-branch condition is a distinct substrate
  state rather than a missing element. State remains `proposed`.
- 2026-09-02: `proposed → planned` — Sprint 18 tasks T-146–T-151 cover the
  contract-3 mechanism and tracked-evidence helper, the committed-evidence gates
  at plan lock and close, the work-branch guard in the write helpers, the
  `substrate-misplaced` state, the checkpoint gate with its composed title and
  recorded checkpoint, and the Turn Contract. The local pre-commit hook is
  deliberately not in this sprint, so this intent remains `active` after Sprint
  18 closes.
