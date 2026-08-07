# Plan Critique — Sprint 15

Self-critique against `prompts/plan-critic.md`'s seven failure modes (no subagent
spawned in this environment). INT-0002 is the semantic oracle; the build/test
plans are execution and verification.

## Concerns

### C-001: The substrate false-negative risk is not directly tested
- **Where:** `build-plan.md` T-123; `test-plan.md` T-123 unit tests.
- **Quote:** research risk — "a valid local-only or `bump`-less project must not be
  judged 'absent'."
- **Failure mode:** missing-risk / plan-test-mismatch
- **Why it matters:** T-123's `substrate-complete` clause says "(+`bump` if
  enabled)", but no test asserts that a `bump`-disabled or `local-only` project
  still reports `substrate-complete` without a `bump` branch or a remote. Without
  it, a regression that over-requires `bump`/remote would pass unnoticed.
- **Suggested response:** fix-in-plan — added `test_substrate_complete_without_bump`
  (bump disabled, no bump branch → `substrate-complete`) and
  `test_substrate_local_only_complete` (local-only profile, no remote →
  `substrate-complete`).

### C-002: The "single writer of `dev`" invariant is a property, not a runtime check
- **Where:** `INT-0002` acceptance ("no writer other than the running sprint
  mutates `dev`"); `test-plan.md` `test_bump_inherit_without_race`.
- **Failure mode:** intent-drift (weak verification)
- **Why it matters:** race-freedom is enforced by design (main is the single
  confluence; `sync-work-branch.sh` writes only `work`) rather than by a guard the
  suite can fail on. The integration test asserts it structurally but cannot
  prove the absence of a concurrent writer in all conditions.
- **Suggested response:** defer-with-rationale — `test_resync_writes_only_work`
  (T-126) plus the T-127 doc contract (no second writer of `dev`) are the
  strongest feasible checks; the invariant is a topology guarantee, documented as
  such. No stronger automated proof is in scope.

### C-003: T-128 bundles registration, parity, and ×4 propagation
- **Where:** `build-plan.md` T-128.
- **Failure mode:** granularity
- **Why it matters:** one task covers guard registration, `check-bundle-sync`
  inventory, `check-adapter-semantics`, and byte-identical propagation across four
  bundles — several surfaces in one diff.
- **Suggested response:** reject (the critique is wrong because ...) — this mirrors
  the accepted sprint-14 pattern (T-118/T-120), where registration + parity +
  propagation are one atomic "make the guards know about the new assets" unit;
  splitting them would produce transiently-red parity states between commits.

## Re-review
After C-001's two tests were added to `test-plan.md` and C-002/C-003 were
resolved as above, no failure-mode instance remains that would commit the sprint
to a material intent, coverage, dependency, or verification error.

## Confidence
proceed-with-caveats
