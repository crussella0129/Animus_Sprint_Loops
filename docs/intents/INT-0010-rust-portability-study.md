# INT-0010 — Study: a Rust core and crate-shaped distribution

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0010
- **State:** proposed
- **Work evidence:** none
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** none
- **Documentation evidence:** none

## Intent
Answer one question with evidence rather than preference: what would it cost, and
what would it buy, to move the Sprint Loops core from bash helpers to Rust
distributed as crates?

The study must produce a decision record covering:

- **What the bash bundle actually gives us.** It installs by copying, runs
  anywhere with a shell, has no build step, no toolchain requirement, and no
  release pipeline. Any replacement has to price those properties, not dismiss
  them.
- **What a Rust core gives us.** Typed Book access, real error types instead of
  exit codes and diagnostics, one implementation instead of four physical copies
  held in parity by a guard, testability beyond fixture directories, and reuse by
  a second consumer.
- **The honest shape.** A Rust core with the bash helpers retained as a fallback
  tier is more likely correct than a replacement, because the fallback is what
  keeps the "works in any harness" property.
- **Distribution.** `cargo install`, prebuilt per-platform binaries, or vendored
  source — each with its failure mode in an environment that cannot compile.
- **The extraction boundary.** Which parts are worth moving first. The Book
  reader/writer/validator is the strongest candidate; phase routing is second;
  the transactional installers are the weakest, because their value is in their
  platform-specific care.
- **CubiKan's role,** as either the accounting mechanism for work units or as an
  influence on the design.

This intent authorizes research, a decision record, and at most a
throwaway spike. It does not authorize a rewrite.

## Acceptance criteria
- A decision record exists that names a recommended direction, the evidence for
  it, and the conditions under which the recommendation would change.
- The record prices the properties the bash bundle currently provides, with the
  environments that depend on each one named.
- An extraction boundary is proposed and justified, or the record states that no
  extraction is worth doing and why.
- CubiKan's applicability is answered either way rather than deferred again.
- No production helper is rewritten under this intent.

## Rationale
The four-bundle parity model works, and its cost is visible: every new helper is
eight files plus a guard entry, and the guard exists precisely because physical
copies drift. A single typed core would remove that cost. Against it, the bash
bundle's portability is not incidental — it is why the same loop runs under
Claude Code, Codex, Antigravity, and any harness with a shell, with no install
step beyond a copy.

That trade is real enough that it deserves evidence rather than a preference,
and cheap enough to study that it should not be settled by argument. A second
consumer would change the calculus substantially, which is why this study and
INT-0011 are worth doing in that order.

## Alternatives
- **Rewrite first, evaluate after.** The expensive way to learn the answer.
- **Never revisit.** Accepts the parity cost permanently, including for every
  helper the plan in INT-0004 through INT-0009 adds.
- **Rewrite in Go or another language.** Not excluded by the study, but the
  standing preference is Rust where a Rust path is viable, and the properties in
  question are not language-specific.

## Consequences
- A recommendation to extract creates a second implementation that must be held
  at parity with the bash bundle until it replaces it — the same drift problem
  in a new place, which the study must address rather than inherit.
- A recommendation not to extract should still name the parity costs it accepts,
  so the decision can be revisited with a known baseline.
- Study output is a Book intent and decision record; it must not create a
  partially converted core in the repository.

## Transition history
- 2026-09-02: created as `proposed` — derived from operator feedback item 5.a,
  which states an intent to research crate-shaped portability, explicitly not to
  rebuild yet.
