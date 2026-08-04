# Sprint 6 Test Report

## Summary
- Unit tests: 19 passed / 0 failed / 19 total (16 initial + 3 added in response to the test-critic block)
- Integration tests: 2 passed / 0 failed / 2 total (claude + codex install → selftest 13)
- E2E tests: 0 / 0 / 0 (N/A — budget gate is bash-tested via selftest step 13; critic protocol needs LLM execution)
- CI status: not-configured

## Critic review (first dogfood of sprint-5's protocol)
- **Plan critic** (`sprints/s6/sprint-plans/critique.md`): returned `proceed-with-caveats`, 8 concerns. 6 fixed in-plan BEFORE lock (counter overcounting regex, EARS-clause test coverage, install-test gap, E2E-drift wording, override-regex spec, T-002/T-003 boundary), 2 deferred with rationale. Caught the counter overcounting bug at the plan stage — would otherwise have been a build-time surprise.
- **Test critic** (`sprints/s6/sprint-tests/critique.md`): returned `block`. Two real EARS-coverage gaps — the `sources>5` exit branch had no test, and the override-present-but-empty-body negative path was unexercised. Both fixed (tests added + passing) before this report was finalized. C-003 added, C-004 deferred, C-005 confirmed. **The block was correct and valuable** — finalizing at the original "16/16" would have falsely declared the budget gate fully proven.

## Failures
None remaining. Two real implementation bugs were caught during Build by
running (not by the critic): the counter overcounting header+separator rows
(plan-critic C-001, fixed in T-001) and `finalize-plan.sh`'s unbound
`$SCRIPT_DIR` crash under `set -u` (fixed in T-001).

## Technical Debt Identified
All five of sprint 3's user-prioritized candidates (3→2→5→1→4) are now
DONE across sprints 4–6. Remaining older carry-forward (not in the user's
prioritized list):
- **CI workflow** running `selftest.sh` (+ `install.sh`) on push for all 3 bundles. The strongest remaining hardening — would turn the selftest into an automated gate.
- **Optional hard-gate** in `finalize-plan.sh` requiring `critique.md` to exist (currently the critic protocol is documented-but-not-enforced; a gate would make it mandatory like the decisions-reviewed gate).
- **`abort-sprint.sh` graceful no-git-repo fallback** (low priority, since the Build Phase requires a git root anyway).
- **C-004 from the test critic**: a direct install-placement assertion for `research-budget.sh` (deferred — selftest step 13 from installed bundle covers it indirectly).

## Coverage Observations
- The budget gate is the most thoroughly tested helper yet: 10 T-001 unit tests covering both budget halves (files + sources), header/separator skipping, missing sections, both heading-prefix variants, and all four finalize outcomes (within-budget, over-no-override, over-empty-override, over-with-override).
- selftest is now 13 steps; both bundles green; md5-identical across all 3.
- The critic protocol's first live run found a real test gap that bash-level checks alone would not have — validating sprint 5's investment.
