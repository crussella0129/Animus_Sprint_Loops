# Sprint 18 Research Report

## Intents Reviewed
- [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) — selected; relevance: this sprint is the whole intent; current state: `proposed`, revised during this research to record the fixture-cost finding (F4) and to scope the local pre-commit hook explicitly (F7).
- [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) — selected as the gating mechanism; relevance: every gate this sprint adds must bind only at or above a substrate contract version, or it reroutes projects mid-sprint; current state: `realized` in Sprint 17, and its forward-compatibility claim was confirmed empirically at this sprint's boundary (F1).
- [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) — reviewed as context; relevance: owns the two-branch model and the one-checkpoint-per-sprint rule this sprint enforces mechanically; current state: `superseded`, but its branch decisions still describe shipped behavior.
- [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) — reviewed as context; relevance: the checkpoint gate must not interfere with sprint-boundary updater intake; current state: `active`.

## 1. Sprint Goal

Close the four ways a sprint can currently end in a state the protocol says is
impossible: a checkpoint opened before the sprint closes, a checkpoint titled
something other than `Sprint N: <description>`, phase Exit evidence satisfied by
files that were never committed, and a whole sprint executed on the base branch.
Each becomes an exit code rather than a sentence in a phase document. Every gate
binds only at or above the substrate contract version that introduces it, so an
un-converged project is unaffected.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| open-harnesses/scripts/remote-adapter.sh | high | Has **no phase gate at all** — `open-pr` will open a checkpoint from any phase. Title defaults to `Sprint checkpoint: $work -> $base` and any `--title` is accepted verbatim. Both defects are here. |
| open-harnesses/scripts/remote-adapter.test.sh | high | Five fixtures using a `gh` stub on `PATH` and a local bare repo. **None of them create a Book**, so a phase gate makes all five fail until they gain a closed sprint (F4). |
| open-harnesses/scripts/close-sprint.sh | high | Already refuses unless `current-phase.sh` reports `loop`, and already backs up the index and the meta before writing — the precedent for adding a pre-write gate rather than a post-write check. |
| open-harnesses/scripts/commit-task.sh | high | The one helper every Build task funnels through, and the earliest point a wrong-branch sprint becomes detectable. Does not read the remote profile today. |
| open-harnesses/scripts/current-phase.sh | high | Pure function; `ready-for-next-sprint` is returned exactly when the sprint meta carries a terminal `Exit status`, so the checkpoint gate can be one router call rather than two checks. |
| open-harnesses/scripts/check-substrate.sh | high | The only helper that runs before routing, so it is the only place a wrong-branch condition is observable *before* writes begin. Now carries the version states from Sprint 17. |
| open-harnesses/scripts/remote-profile.sh | high | Resolves `work`/`base`; the branch guard needs it, and must degrade gracefully when a project has no profile. |
| open-harnesses/scripts/book-paths.sh | high | Carries `BOOK_SUBSTRATE_CONTRACT_VERSION` and `book_substrate_version()` from Sprint 17 — the mechanism every gate in this sprint conditions on. |
| open-harnesses/scripts/finalize-plan.sh | medium | The Plan-phase exit gate; the natural place to require that planning evidence is committed. Already transactional with rollback. |
| open-harnesses/scripts/abort-sprint.sh | medium | Also reaches a terminal Exit status, so the checkpoint gate must decide whether an aborted sprint may checkpoint (F3). |
| open-harnesses/scripts/sync-work-branch.sh | medium | Already refuses on a dirty tracked tree — the precedent for the diagnostic style a tracked-evidence gate should use. |
| open-harnesses/schemas/sprint-meta.md | high | Needs a `Checkpoint` field so a later sprint can tell its own checkpoint from the previous one without querying the provider. |
| claude-code/skills/sprint-loop/phases/06-loop-phase.md | high | Owns the checkpoint step; where the gate's contract and the Turn Contract's stop-list belong. Diverges between adapters (not byte-parity). |
| claude-code/skills/sprint-loop/phases/{02,04,05}-*.md | high | Byte-parity with codex; each needs a committed-evidence line in Exit evidence. |
| claude-code/skills/sprint-loop/SKILL.md | medium | Carries the adapter-level authority boundary the Turn Contract must not contradict. |
| tools/check-adapter-semantics.sh | high | Scans active surfaces for authority phrasing and the retired branch term; new prose must satisfy it. Cost the previous sprint a rework cycle. |
| tools/run-guards.sh | medium | Suite registry; a new helper needs a suite entry, and `check-tracked` needs one. |
| tools/check-bundle-sync.sh | medium | `REQUIRED_SCRIPTS` grows by one per new helper, times four bundles. |
| docs/work/remote-profile.md | medium | This repository's live profile: `github` / `main` / `dev` / `human-approve` — the fixture for the real checkpoint path. |
| docs/sprints/s17/sprint-tests/critique.md | medium | C-005 (the guard runner's `det-mismatch` label) is queued as T-144 and is unrelated to this sprint; noted so it is not re-diagnosed. |

## 3. External Sources

None required. Every mechanism in this sprint is internal: the adapter, the
router, the write helpers, and the phase contracts are all project-owned, and the
provider interaction is already abstracted behind the remote profile.

## 4. Risks, Unknowns, Dependencies

**Findings**

- **F1 — Forward compatibility is now proven, not just argued.** At this
  sprint's boundary the pre-0.17.0 plugin bundle (cache `4acc1fd6e0b9`) was run
  against this repository's newly stamped Book. It reported `substrate-complete`,
  routed to `ready-for-next-sprint`, validated the Book, and resolved the sprint
  number — all correct. Sprint 17 asserted this direction of compatibility from
  the marker parser's shape but never executed it. It holds.
- **F2 — The checkpoint gate is one router call.** `current-phase.sh` returns
  `ready-for-next-sprint` exactly when the sprint meta carries a terminal
  `Exit status`, so "the sprint is closed" and "the router says ready" are the
  same condition. The gate does not need to parse the meta itself.
- **F3 — Aborted sprints reach the same terminal state.** `abort-sprint.sh`
  sets `Exit status: aborted`, which also yields `ready-for-next-sprint`. A gate
  keyed on the router therefore permits a checkpoint after an abort. That is the
  right behavior — abandoned work still needs a reversible boundary — but it must
  be a decision in the contract rather than an accident of implementation.
- **F4 — The checkpoint gate invalidates every existing adapter fixture.** All
  five `remote-adapter.test.sh` fixtures build a git repo and a remote profile
  with **no Book at all**; under a phase gate each would be refused with
  `uninitialized`. They must gain a closed-sprint Book. This is the single
  largest mechanical cost in the sprint and is not optional.
- **F5 — A placeholder Summary would produce a nonsense title.**
  `init-sprint.sh` writes `- **Summary:** (one-line description of sprint goal,
  filled after Plan Phase)`. Composing `Sprint N: <Summary>` without checking
  would emit that parenthetical as the checkpoint title. The composer must refuse
  a Summary that is still the placeholder.
- **F6 — Wrong-branch detection belongs in two places, for different reasons.**
  The write helpers (`commit-task.sh`, `close-sprint.sh`) are where enforcement
  must live, because they are the sanctioned write path. But the earliest
  *observable* moment is the substrate gate, which runs before routing — and the
  observed failure was a whole sprint completed on the base branch before anyone
  noticed. Detection at the gate plus refusal at the writes covers both.
- **F7 — The local pre-commit hook is separable and lower-value.** Once
  `commit-task.sh` refuses on the wrong branch, the first Build task catches the
  condition. A hook adds coverage for commits made outside the helpers, at the
  cost of writing into `.git/hooks` (untracked, never cloned, possibly redirected
  by `core.hooksPath`, and easy to clobber). It is the least coupled piece of
  INT-0005 and the easiest to defer without weakening the rest.
- **F8 — `check-substrate.sh` reports a project property; branch position is a
  session property.** Folding "you are on the wrong branch" into the `missing`
  list would misreport a complete substrate as incomplete. A distinct state,
  ranked after `substrate-partial` and before the version states, keeps each
  answer meaning one thing. Position must outrank the version states because
  convergence writes, and writing while on the base branch is the condition being
  prevented.

**Risks**

- **Risk:** the tracked-evidence gate fails closed on any project that has been
  running with an uncommitted Book. That is the intended effect, but the
  diagnostic must name the offending paths and the exact remedy.
- **Risk:** `close-sprint.sh` writes and commits the sprint meta, so a naive
  "docs/ must be clean" check placed after its write would always fail. It must
  run at entry, before the meta is touched.
- **Risk:** rewriting five adapter fixtures risks weakening what they already
  prove (open-once, refuse-second, generic fallback, never-merge, head-override
  rejection). Each must keep its original assertion after gaining a Book.
- **Risk:** new prose in six phase documents must satisfy `adapter-semantics`,
  which cost the previous sprint a rework cycle over a single word.

**Unknowns**

- **Unknown:** whether the tracked gate should cover the whole `docs/` tree or
  only the current sprint's artifacts. Leaning to the whole tree: the Book is one
  state machine, and a stale uncommitted intent chapter is exactly the
  lower-authority drift the contract exists to prevent.
- **Unknown:** whether `--title` should be rejected outright or normalized.
  Leaning to validate-and-refuse: silently rewriting an operator's title is the
  kind of hidden behavior this sprint is trying to remove.

**Dependencies**

- INT-0004's contract version, shipped and merged in Sprint 17. Every gate below
  is conditioned on it.

## 5. Recommended Approach

**Primary — gate at the helpers, detect at the substrate, describe in the
contracts; defer the hook.**

1. **`check-tracked.sh`** (new, four bundles): asserts the Book has no untracked
   files and no uncommitted modifications, with a diagnostic naming each path.
   Wired into `finalize-plan.sh`, `close-sprint.sh` (at entry), and `open-pr`.
2. **Checkpoint gate + composed title** in `remote-adapter.sh`: refuse unless the
   router reports `ready-for-next-sprint`; compose `Sprint N: <Summary>` from the
   Book, refusing a placeholder Summary; validate any supplied `--title` against
   `^Sprint [0-9]+: .+`; compose the body from the sprint record; record the
   resulting URL in a new `Checkpoint` field in the sprint meta.
3. **Branch guard**: refusal in `commit-task.sh` and `close-sprint.sh` when
   `HEAD` is not the profile's `work`, degrading to a no-op when no profile is
   resolvable; plus a new `substrate-misplaced:<head>-><work>` state in
   `check-substrate.sh`, ranked after `substrate-partial` and before the version
   states.
4. **Turn Contract** section in the adapter phase documents naming the only legal
   stop points, plus a committed-evidence line in each phase's Exit evidence.
5. **Version conditioning**: every gate binds only when the Book's substrate
   contract version is at or above the version this sprint ships, so an
   un-converged project behaves exactly as it does today.

**Alternative considered — enforce committal inside `current-phase.sh`,** so an
uncommitted phase artifact simply does not advance the router. Rejected: it makes
routing depend on git state, breaking the pure-function property that
cross-harness resume relies on, and it would reroute a project mid-sprint the
first time it ran. Gating at the exit helpers achieves the same outcome without
touching the router.

**Deferred with rationale — the local pre-commit hook (F7).** Recommend carrying
it forward as its own task rather than including it here. `commit-task.sh`'s
refusal already catches the observed failure at the first Build task, the hook
writes to an untracked location with real clobbering risk, and this sprint is
already at the size where the adapter fixtures alone are a substantial rewrite.
INT-0005 should stay `active` after this sprint rather than being claimed as
realized on a partial delivery.

## Artifacts

No standalone artifacts. F1 was observed directly by running the installed
pre-0.17.0 bundle against this repository's Book at commit `385bf37`, after the
Sprint 17 checkpoint merged as `d822130`.
