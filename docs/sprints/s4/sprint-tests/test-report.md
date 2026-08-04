# Sprint 4 Test Report

## Summary
- Unit tests: 22 passed / 0 failed / 22 total
- Integration tests: 1 passed / 0 failed / 1 total (selftest 12/12 × 2 bundles)
- E2E tests: 0 / 0 / 0 (N/A — not yet possible)
- CI status: not-configured

## Failures
None. One micro-adjustment during T-003 build: noticed my own research-report
header was `## 0. Decisions Reviewed` (with numeric prefix) while the schema
example shows no prefix. Made the `finalize-plan.sh` grep permissive over
the prefix (`^## ([0-9]+\. *)?Decisions Reviewed`) so both forms parse —
documented in sprint-4 e2e-tests.md.

## Technical Debt Identified
Carried forward to **sprint 5+**, in the user-priority order from sprint 3:

1. **Subagent fan-out** (user priority 4). Plan and Test phases should get a
   critic / adversarial review pass before locking. Today the only adversary
   is `finalize-plan.sh`'s emptiness + decisions-review checks — catches
   structural violations but not BAD plans semantically.
2. **Enforced research budget** (user priority 5). The 20-files / 5-sources
   / 30-min cap in `phases/02-research-phase.md` is honor-system. A cheap
   counter (grep -c files referenced in the report) would make it real.

Plus earlier carry-forward:
- CI workflow running `selftest.sh` on push for all 3 bundles (sprint 4+ candidate).
- `abort-sprint.sh` graceful no-git-repo fallback (low priority).

## Coverage Observations
- The plan-mode primitive (T-001) is documentation-level — verified by grep
  presence checks, not by actually exercising `EnterPlanMode`/`ExitPlanMode`
  tool calls (those are harness primitives the selftest can't drive). The
  next time a real `/sprint-loop` runs through Plan Phase will be the
  in-vivo test.
- EARS (T-002) is also documentation-level — verified by presence of EARS
  keywords in schema/phase/particle files. The first sprint that actually
  uses EARS in `build-plan.md` will demonstrate test-derivation in action.
  Sprint 4's own build-plan is the first dogfood case.
- The Decisions-Reviewed gate (T-003) IS exercised by selftest step 12 —
  real `finalize-plan.sh` invocation in a temp project, real refusal, real
  acceptance after fix. Regression-protected.
