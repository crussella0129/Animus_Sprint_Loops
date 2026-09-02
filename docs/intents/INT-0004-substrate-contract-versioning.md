# INT-0004 — Versioned substrate contract with one idempotent convergence entrypoint

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0004
- **State:** proposed
- **Work evidence:** none
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** none
- **Documentation evidence:** none

## Intent
Make spin-up and upgrade the same operation, and make "which contract is this
project on?" a fact on disk rather than an inference.

1. **A substrate contract version.** `docs/.sprint-loop-book` carries a second
   anchored key, `substrate-version: N`, beside the unchanged
   `schema-version: 2`. An absent key means version 1.
2. **One convergence entrypoint.** `deploy-substrate.sh` becomes an ordered list
   of individually idempotent convergence steps behind its existing
   transactional rollback: it spins up a fresh project, brings an older project
   to the current contract, and no-ops on a current one. `--check` reports drift
   read-only without writing.
3. **A fourth substrate answer.** `check-substrate.sh` reports
   `substrate-outdated:<from>-><to>` when the Book is otherwise valid but behind
   the installed bundle. Init routes that to convergence; the adapter also
   exposes a deliberate `upgrade` invocation.
4. **Bundle version discipline.** `plugin.json` carries a `version`, the skill
   records its bundle identity at Init, and `sprint-meta.md` gains a
   `Bundle version` field, so the bundle that ran a sprint is recorded rather
   than inferred. This closes the deferred roadmap item on plugin version
   discipline and the documented reload step.

Non-goals: this intent adds no phase gate and changes no routing behavior. It
only makes version-conditional gating possible for the intents that follow.

## Acceptance criteria
- A Book at contract version 1 converges to the current version in one command,
  and a second run of that command changes nothing and reports the no-op.
- A failure injected at any convergence step rolls back every artifact that run
  created, leaving the project at its prior contract version.
- An un-converged Book produces byte-identical routing output before and after
  the release that introduces this intent.
- `check-substrate.sh` distinguishes `substrate-complete`, `substrate-absent`,
  `substrate-partial:<diagnostic>`, and `substrate-outdated:<from>-><to>`.
- Every helper that reads the marker still parses a Book carrying the new key,
  across all four bundles.
- A closed sprint's metadata names the bundle version that ran it.

## Rationale
`deploy-substrate.sh` was already three quarters of an upgrade tool: it creates
only what is missing, verifies, and rolls back. What it lacked was any notion of
what "current" means, so it could add absent artifacts but never recognize that
a present artifact was stale. A version stamp supplies that, and once gates can
ask the Book which contract it is on, every later behavioral change ships
without breaking a project mid-flight.

The marker is the right home for the stamp: `book_marker_is_v2()` requires
exactly one line matching `^\s*schema-version:`, so a differently named key is
invisible to every existing parser in every bundle. The compatibility cost of
this design is therefore approximately zero, which is what makes it the right
foundation to put first.

## Alternatives
- **Unconditional gates, no version.** Simplest to write, and it reroutes
  projects mid-sprint when a new required artifact appears. Rejected: the router
  must stay a pure function of the filesystem for cross-harness resume to hold.
- **A separate `upgrade-substrate.sh`.** Two scripts that must agree about what
  a complete substrate is, which is exactly the drift the guard suite exists to
  prevent elsewhere. Rejected as a second writable authority in script form.
- **Version in the remote profile.** The profile is about the remote topology
  and is legitimately absent on `local-only` projects. The Book marker is the
  one artifact every Sprint Loops project has.
- **Semantic versioning of the whole bundle as the gate.** Too coarse: the
  question a gate asks is "has this project's substrate been converged?", not
  "which release is installed?".

## Consequences
- New behavior reaches an existing project only after convergence runs. Init
  converging automatically keeps that from being a manual burden, at the cost of
  Init occasionally doing more than initialize.
- Every gate introduced from here on must record the contract version that
  introduced it, or the compatibility guarantee decays silently.
- The convergence step list becomes a maintained ordering with its own review
  burden; a step that is not genuinely idempotent breaks the no-op guarantee.
- Bundle version discipline adds a per-sprint bump obligation and a documented
  reload step, because the plugin cache pins a commit and a running loop
  otherwise keeps executing the bundle it started with.

## Transition history
- 2026-09-02: created as `proposed` — derived from operator feedback that the
  spin-up and update paths should be one idempotent system, and required as the
  compatibility foundation for INT-0005 through INT-0009.
