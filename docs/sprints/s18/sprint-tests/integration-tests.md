# Sprint 18 Integration Tests

## `test_gated_sprint_walk` — T-146 + T-147 + T-149 + T-150
**Status:** PASS

`test_checkpoint_refused_before_close` walks a single Book at contract 3 through
every open phase and asserts, at each one, that `open-pr` exits non-zero, that
the diagnostic names that exact phase, and that the provider stub was never
invoked:

| Phase | Checkpoint |
|---|---|
| `research` | refused, `phase: research` |
| `plan` | refused, `phase: plan` |
| `build` | refused, `phase: build` |
| `test` | refused, `phase: test` |
| `loop` (open) | refused, `phase: loop` |
| `ready-for-next-sprint` | opened — exactly one request |

This is the composition that matters: each gate is individually testable, but
the property the sprint promises is that a checkpoint cannot precede a close *at
any point in the loop*, and only a walk demonstrates that.

## `test_gates_inert_below_contract_3` — backwards-compatibility regression
**Status:** PASS

The same conditions at contract 2, asserted in three places:

- `test_checkpoint_gates_inert_below_contract_3` opens a checkpoint from
  `research` — mid-sprint — and gets the pre-sprint default title
  `Sprint checkpoint: dev -> main`.
- The finalize fixture locks both plans over an untracked Book file.
- The branch fixture commits from a branch that is not `work`.

Every gate is therefore proven inert on an un-converged project, which is what
makes shipping them safe. This is the claim under test, not an assertion.

## `test_checkpoint_gate_composition` — T-148 + T-150
**Status:** PASS

The close fixture proves the guards compose in the intended order rather than
each catching the same case: a sprint at phase `loop` on the base branch is
refused by `close-sprint.sh` **before** the checkpoint path is ever reached, and
the sprint metadata hash is unchanged. Only after the branch is corrected and
the Book is clean does close succeed — and only then does `open-pr` become
reachable at all, because its own gate keys on the closed state that close
produces.

## `test_bundle_identity_carries_forward` — Sprint 17 → Sprint 18
**Status:** PASS

Sprint 18's own metadata records `- **Bundle version:** 0.18.0`, written by
`init-sprint.sh` from the bundle's own `bundle-version.sh`. Sprint 17 shipped
that mechanism and could not record a value for itself; this sprint is the first
whose provenance names the bundle that ran it, end to end and unprompted.

## Cross-bundle integration
**Status:** PASS

`check-bundle-sync.sh` confirms the four bundles carry byte-identical `scripts/`
and `schemas/` sets after this sprint's additions, including the new
`check-tracked.sh` and its fixtures, and that the byte-parity phase contracts
(02, 04, 05) still match between claude-code and codex-cli after the
Exit-evidence edits.
