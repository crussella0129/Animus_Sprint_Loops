# INT-0011 — Study: staying compatible with a human-in-the-loop environment

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0011
- **State:** proposed
- **Work evidence:** none
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** none
- **Documentation evidence:** none

## Intent
A separate exploration is underway into an agentic development environment built
around "Sprint Loops, but human in the loop" — one where a person is an
addressable participant in the loop, with a declared capability profile and a
negotiated engagement mode per task, rather than a supervisor outside it. Its
specification is deliberately maintained outside this repository and is not Book
authority here.

What belongs to *this* project is the compatibility question: **what would
Sprint Loops need to be true of itself for such an environment to be a
first-class participant rather than a fork?**

The study must answer:

- **Is the Book the whole contract?** If an environment reads and writes Book v2
  exactly, is a project resumable between it, Claude Code, Codex, and Antigravity
  mid-sprint — and if not, what is missing from the schema?
- **Participant attribution.** The work ledger records what was done, not who
  did it. A human-completed task and an agent-completed task are currently
  indistinguishable. Should participant identity and engagement mode be
  Book-recordable, and if so, in which artifact?
- **Human-scale phase gates.** The loop's stop-list already names product
  ambiguity, irreversible action, and unverifiable claims. Are those the right
  boundaries when a human is a scheduled participant rather than the approver?
- **Shared extraction.** A second consumer of a Book core is the strongest
  argument for INT-0010's extraction. This study supplies that evidence or
  withdraws it.

Non-goals: no environment is built or specified under this intent, and no
document belonging to that exploration is stored in this repository.

## Acceptance criteria
- A decision record states whether Book v2 is sufficient as the sole interop
  contract for a non-CLI participant, and names any schema gap it finds.
- The participant-attribution question is answered with a concrete proposal or
  an explicit decision not to record it.
- The record states what, if anything, this project would change to keep that
  compatibility, separated into changes worth making regardless and changes
  contingent on the environment existing.
- The relationship to INT-0010 is resolved in one direction or the other.
- No specification content for the external environment lands in `docs/`.

## Rationale
The cross-harness continuity promise — another harness must be able to resume
from the Book alone — has only ever been tested against harnesses of the same
shape: a model with a shell, driving the same helpers. A human participant is
the first genuinely different consumer, and it tests the promise where it is
weakest: attribution, latency, and the assumption that whoever holds a task can
be asked to finish it now.

Answering that question is cheap and improves the Book contract whether or not
the environment is ever built, which is why it belongs here as a study rather
than as a dependency on someone else's roadmap.

## Alternatives
- **Wait until the environment exists.** Guarantees the compatibility work is
  discovered as breakage rather than designed.
- **Absorb the environment's design into this project.** Explicitly out of
  scope; the exploration is deliberately kept separate, and importing it would
  make this project's Book authoritative over something it does not own.
- **Extend the schema speculatively now.** Adds fields with no consumer, which
  the Book contract's authority direction argues against.

## Consequences
- If the study finds a schema gap, closing it is a Book v2 change with a
  migration cost across four bundles and every existing project — the version
  discipline in INT-0004 is what would make that survivable.
- Participant attribution touches the append-only completed-task ledger, whose
  format several helpers parse exactly; any change there is higher risk than its
  size suggests.
- A finding of "no changes needed" is a valid and useful outcome, and should be
  recorded as strongly as a finding of a gap.

## Transition history
- 2026-09-02: created as `proposed` — derived from operator feedback item 8.a,
  which states an intent to research compatibility with a from-scratch
  human-in-the-loop environment, not to build one, and to keep that
  exploration's documents outside this project.
