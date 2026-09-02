# INT-0007 — Computed integrity sweep for stubs and vestigial structure

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0007
- **State:** proposed
- **Work evidence:** none
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** none
- **Documentation evidence:** none

## Intent
Add a computed pass to the Test phase that looks for the two defects the phase
gates cannot see, because both are invisible to a test suite that passes.

1. **Stubs.** Placeholder implementations left behind when context compacts or
   the executing agent changes between sprints: `todo!()`, `unimplemented!()`,
   `NotImplementedError`, a panic that says not implemented, a bare `pass` body,
   a hardcoded placeholder return, and `TODO`/`FIXME` markers introduced by the
   sprint under test.
2. **Vestigial structure.** Things the corpus has outgrown: helpers absent from
   every runner list, files nothing sources or links, schemas no phase reads,
   near-duplicate copies that have drifted apart, configuration keys nothing
   consumes.

Scope alternates. The sweep's tier — touched paths only, or the whole corpus —
and its file sample are derived from the sprint's head commit SHA, so a sprint's
sweep is reproducible from its own record while the sequence of sweeps across
sprints is not a fixed rotation. Findings are written to
`sprint-tests/sweep-report.md`, read by the test critic, and either addressed or
justified in the record before the sprint can close.

## Acceptance criteria
- For a fixed head SHA, tier and sample selection are identical across runs; for
  different SHAs across a corpus of fixtures, both tiers and a spread of samples
  occur.
- A planted stub inside a sampled file is reported with its path, line, and
  category; a stub outside the sample is not reported, and the report says what
  was in scope.
- A helper added to a bundle but absent from every runner list is reported as
  vestigial.
- The sweep report is required before Loop only for Books at or above the
  contract version that introduces it.
- The sweep contributes no nondeterminism: the guard suite's run-twice
  determinism meta-check passes with the sweep in the suite list.

## Rationale
The loop's verification is derived from the locked plan's EARS clauses and the
linked acceptance criteria. That is the right oracle and it is deliberately
narrow: it proves the sprint did what it promised, and says nothing about what
the sprint left behind. Stubs pass tests that were written against them, and a
vestigial helper passes every test in the repository by never being called.

Making the scope computed rather than fixed keeps the pass from settling into a
shape work can be arranged around, and deriving it from the head commit keeps
the result reproducible from the sprint record — which a genuinely random draw
would not be.

## Alternatives
- **A fixed full-corpus sweep every sprint.** Predictable and, on a growing
  corpus, slow enough that it gets skipped or narrowed until it means nothing.
- **A linter in CI.** Catches known stub patterns and misses vestigial structure
  entirely, because "nothing references this" is a corpus-level question. Worth
  having in addition, not instead.
- **Sampling with `$RANDOM`.** Would break the guard runner's determinism
  meta-check, which runs every suite twice and compares normalized evidence
  hashes — a nondeterministic suite takes the whole run red.
- **A blocking gate on every finding.** Some findings are correct as written.
  The gate is that findings are addressed or justified in the record, not that
  the report is empty.

## Consequences
- False positives are certain, particularly in the vestigial scan, where a file
  can be referenced by something the scan cannot see. The report is evidence for
  a human or critic to weigh, not a verdict; the justification path must be as
  cheap as the fix path.
- Whole-corpus tiers cost time proportional to repository size, and that cost
  lands unevenly across sprints by design.
- Adding a required artifact to the Loop route is the highest-risk change in
  this plan. It must be conditioned on the substrate contract version from
  INT-0004, or a project mid-sprint reroutes underneath itself.

## Transition history
- 2026-09-02: created as `proposed` — derived from operator feedback item 3.a,
  which observed stubs surviving compaction and agent handover between sprints,
  and vestigial structure accumulating with nothing looking for it.
