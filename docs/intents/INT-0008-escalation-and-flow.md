# INT-0008 — Justified escalation, preserved flow

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0008
- **State:** proposed
- **Work evidence:** none
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** none
- **Documentation evidence:** none

## Intent
Keep the loop moving by default, and make an action that needs operating-system
or administrator authority something the sprint has to justify in writing before
it happens — without banning a category of legitimate work.

1. **A classifier.** A helper classifies a command string as `allow`,
   `justify`, or `refuse`: privilege elevation, service and registry control,
   firewall and driver changes, machine-wide package installation, and launching
   installers or executables that request elevation.
2. **A ledger.** `docs/work/escalations.md` records each `justify` action with
   its command, the intent it serves, the non-escalating alternatives
   considered, and the operator acknowledgement. Test-phase acceptance reads it;
   an escalation with no ledger entry is a defect in the sprint, not a detail.
3. **Native enforcement where a harness offers it.** A `PreToolUse` hook shipped
   with the Claude Code plugin, and an approval/sandbox configuration fragment
   for Codex. These are the deterministic layer; the ledger is the portable one.
4. **Flow-preserving defaults.** The Test phase contract names the
   non-escalating alternatives first — project-scoped invocation, CI, a
   container, or proceeding with a recorded caveat — so the path that keeps the
   sprint moving is the default one.

Design input: the observed behavior in Animus_Ferric's recent sprints is
research for this intent, so the classifier's patterns come from commands an
agent actually reached for rather than a guessed list.

## Acceptance criteria
- The classifier returns a stable verdict for a corpus of command strings
  covering all three classes on both POSIX and Windows shells, with no verdict
  depending on the host it runs on.
- A `justify` action with no corresponding ledger entry is reported by the
  Test-phase check, naming the command and the sprint.
- The shipped hook denies or prompts on a `refuse`/`justify` command in Claude
  Code, and its denial message says what to record and whom to ask.
- The Codex fragment is documented as an operator-applied configuration, and its
  absence degrades to the ledger path rather than to silence.
- A sprint that needs no escalation produces an empty ledger section and no
  additional prompts — the mechanism costs nothing when it is not needed.

## Rationale
An agent was observed repeatedly invoking executables that required
administrator authority during the Test phase, each invocation stopping the flow
of the sprint. Two things were wrong at once: the escalation may not have been
necessary, and nothing in the loop asked. A blanket prohibition is the wrong
correction, because whole categories of legitimate work — drivers, services,
system integration testing — require exactly this authority.

The right correction is friction proportional to consequence: make the
escalating path require a written justification linked to intent, and make the
non-escalating path the documented default. That preserves flow in the common
case, which is the actual goal, and leaves an auditable record in the uncommon
one.

## Alternatives
- **Prohibit escalation in the Test phase.** Blocks legitimate work and would be
  routed around by any agent that believes the escalation is necessary.
- **Rely on the harness sandbox alone.** Each harness has a different model and
  some have none; a Book-level record is the only layer that survives a change
  of runtime, which is the property cross-harness resume depends on.
- **Detect escalation after the fact from shell history.** Not portable, not
  reliably available, and too late to prevent the flow interruption.
- **A blocking prompt on every command.** Destroys flow, which is the thing this
  intent exists to protect.

## Consequences
- The classifier will misjudge unusual commands in both directions. It must be
  cheap to record an override, and its verdicts must never be presented as
  security guarantees — this is a flow-and-record mechanism, not a sandbox.
- The Claude Code hook is real enforcement and therefore a real risk of blocking
  legitimate work in the operator's own session. It ships with a documented way
  to disable it.
- Hook configuration is harness-specific and cannot be kept in byte-parity
  across bundles the way scripts are; the parity guard must not be extended to
  cover it.
- Ledger entries reference intents, which means an escalation during a sprint
  with no relevant intent is a signal that the sprint's scope is unclear.

## Transition history
- 2026-09-02: created as `proposed` — derived from operator feedback item 4.a,
  after an agent repeatedly used the Test phase to invoke executables requiring
  operating-system-level authority, interrupting the flow of consecutive
  sprints.
