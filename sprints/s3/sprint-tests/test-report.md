# Sprint 3 Test Report

## Summary
- Unit tests: 25 passed / 0 failed / 25 total
- Integration tests: 1 passed / 0 failed / 1 total (× 2 bundles, both green)
- E2E tests: 0 / 0 / 0 (N/A — not yet possible; CI is a sprint-4+ candidate)
- CI status: not-configured

## Failures
None. One in-sprint adjustment (T-001 scope expansion to tighten
`current-phase.sh` greps) and one mid-sprint sync of the personal-install
`commit-task.sh` so the rest of the sprint exercised the fixed back-fill —
both documented in `completed-tasks.md` and `sprint-meta.md`.

## Technical Debt Identified
The user surfaced five sharp critiques mid-sprint (after T-001 landed) that
become sprint-4+ candidates. Listed verbatim so a future sprint's research
can pick up:

1. **No subagent fan-out.** Plan and Test phases would benefit from a
   second-opinion call before locking — a critic / adversarial review pass.
   Today, the only "adversary" is `finalize-plan.sh` checking for ≥1
   `### T-XXX:` entry — catches empty plans but not BAD ones.
2. **No machine-checked acceptance criteria.** EARS-format requirements
   (`WHEN x THEN y`) would let test scaffolding be generated mechanically.
   Today `build-plan.md`'s "success criterion" is freeform prose; risk that
   criteria drift from what tests actually check.
3. **Plan Mode is invoked by instruction, not by tool/hook.** Soft
   constraint — relies on model compliance. Claude Code has actual plan
   mode primitives; wiring them would make it hard.
4. **Research budget (20 files / 5 sources / 30 min) is unenforceable.**
   Honor-system soft limit. Even a cheap counter (e.g. `grep -c` files
   referenced) would make it real.
5. **No cross-sprint architectural drift detection.** `decisions.md`
   exists, but the Research Phase doesn't mandate reading it before
   proposing new approaches. Sprint 8 can happily violate a decision from
   sprint 2.

Plus carried forward from sprint 2:
- CI workflow for `selftest.sh` on push across all 3 bundles.
- `abort-sprint.sh` graceful no-git-repo fallback (low priority).

## Coverage Observations
- Line-anchored back-fill regex is exercised by selftest step 11 AND by the
  unit-test block above (separate temp repo). Any future change to the
  back-fill must keep step 11 green.
- Autonomy + workflow doc presence is grep-checked at unit-test level.
  Doc-level changes that drop these sections will be caught.
- Cross-bundle parity check is now: 4 scripts md5-identical (commit-task,
  current-phase, selftest, plus finalize-plan/init-sprint/abort/update-conf
  from prior sprints) + 3 phase files diff-clean (04/05/06) + 2 SKILL.md
  files both containing the autonomy/safety sections.
