# Sprint 5 — End-to-End Tests

**Status:** not-yet-possible at the bash-test level.

The critic spawn-review-address protocol requires LLM execution (Agent tool
spawn), which the selftest harness can't drive. The first sprint to invoke
`/sprint-loop` through Plan or Test phase WILL exercise the critic
protocol live — sprint 6 onward is the in-vivo test surface.

**Sprint-on-sprint observation:** sprint 5 itself didn't run the critic
(the prompts + protocol landed in this sprint). Sprint 6 onward will
operate under the new convention: every Plan and Test phase records a
`critique.md` alongside its artifacts.

**Unlocked by:** sprint 6 onward (operational test in vivo). Sprint 6's
test-report will be the first to include a `## Critic review` section
documenting how the protocol behaved.
