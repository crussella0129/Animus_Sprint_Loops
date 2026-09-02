# INT-0009 — Content-derived sprint identity and a reconciliation index

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0009
- **State:** proposed
- **Work evidence:** none
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** none
- **Documentation evidence:** none

## Intent
Give each sprint an identity that does not depend on counting directories, and
give the Book a place to reconcile identity against git history.

1. **A sprint ID.** `sprint-meta.md` gains a `Sprint ID` derived by hash from
   the initializing commit SHA, the sprint number, the start timestamp, and the
   linked intent IDs. It is stable, collision-resistant, and computed from
   content rather than assigned by sequence.
2. **An index.** `docs/work/sprint-index.md` maps sprint ID to number, status,
   initializing commit, closing commit, and checkpoint URL — the Book's lookup
   table for sprint provenance, and the natural home for the link between a
   sprint and the git history it produced.
3. **Cross-checked resolution.** `current-sprint.sh` compares its directory scan
   against the index and refuses on disagreement with a diagnostic, instead of
   silently preferring one.

Non-goal: sprint directories keep their `sN/` names and sprints keep their
human-facing numbers. The hash is identity and reconciliation, not naming.

## Acceptance criteria
- Two sprints initialized from different commits never share an ID, and
  recomputing an ID from a sprint's own recorded inputs reproduces it exactly.
- A missing or renamed sprint directory produces a refusal naming the
  disagreement rather than a silently different sprint number.
- The index resolves a sprint ID to its initializing and closing commits, and
  those commits are reachable in a normal clone.
- A Book with no index behaves exactly as it does today.
- Adding the ID and index changes no existing field in `sprint-meta.md`.

## Rationale
Misnumbering is a property of how the current sprint is resolved:
`current-sprint.sh` scans `docs/sprints/s*/` and returns the maximum numeric
suffix. A directory that is missing, renamed, created concurrently, or partially
migrated changes that answer, and every downstream artifact — plans, ledger
entries, commit messages, checkpoint titles — inherits the wrong number with no
way to detect it after the fact.

Git solves the same problem with content-addressed identity, and the analogy is
worth taking literally: an identifier derived from what a sprint is, recorded
alongside the commits it produced, makes reconciliation a lookup instead of an
archaeology exercise. Keeping the numeric directory names preserves ordering,
legibility, and every existing link in the corpus.

## Alternatives
- **Hash-named directories.** Maximum rigor, and it destroys ordering,
  readability, and every existing relative link in the Book. Rejected.
- **A monotonic counter file.** A single mutable pointer — precisely the state
  shape the Book contract exists to avoid, and it fails the same way under
  concurrent or partial writes.
- **Deriving identity from the git commit hash alone.** A sprint's identity must
  exist before its first commit, and it must survive rebases of the work branch.
- **Fixing the scan only.** Refusing on gaps without an index makes recovery
  harder rather than easier; the index is what makes a refusal actionable.

## Consequences
- Two artifacts must agree — the sprint record and the index — and a repair path
  is needed for the case where they legitimately diverge, such as a
  hand-recovered sprint.
- The index is an append-heavy Book artifact that will grow with the corpus and
  should stay one line per sprint.
- Hash derivation requires a portable digest tool; the guard runner's existing
  `sha256sum`/`shasum` fallback is the precedent to reuse rather than reinvent.
- If the CubiKan accounting model matures, the identity scheme here is the
  natural place to adopt it; this intent should not foreclose that.

## Transition history
- 2026-09-02: created as `proposed` — derived from operator feedback item 6.a,
  after sprint misnumbering produced reconciliation errors that a sequence-based
  identity cannot detect.
