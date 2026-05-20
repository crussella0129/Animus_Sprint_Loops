Finalized - DO NOT EDIT

# Sprint 5 Test Plan

## Unit Tests

### T-001 unit tests (critic prompt templates)
- `test_plan_critic_prompt_exists`: `open-harnesses/prompts/plan-critic.md` exists and is non-empty.
- `test_test_critic_prompt_exists`: `open-harnesses/prompts/test-critic.md` exists and is non-empty.
- `test_plan_critic_mentions_required_failure_modes`: plan-critic prompt mentions `EARS`, `decisions.md`, and `plan-test` (covers the documented failure modes the critic must screen for).
- `test_test_critic_mentions_required_failure_modes`: test-critic prompt mentions `EARS` and either `assertion` or `coverage`.
- `test_both_prompts_specify_structured_output`: both contain `## Concerns` and `## Confidence` (the required output sections).

### T-002 unit tests (spawn-review-address protocol)
- `test_plan_phase_mentions_critic`: `claude-code/skills/sprint-loop/phases/03-plan-phase.md` mentions `prompts/plan-critic.md` and `critique.md`.
- `test_test_phase_mentions_critic`: `claude-code/skills/sprint-loop/phases/05-test-phase.md` mentions `prompts/test-critic.md` and `critique.md`.
- `test_plan_phase_mentions_address_step`: `phases/03-plan-phase.md` instructs to "address each concern" (fix / defer / reject) before lock-down.
- `test_particle_03_mentions_critic`: `open-harnesses/particles/03-plan-phase.md` mentions critic spawn inside its quoted block.
- `test_particle_07_mentions_critic`: `open-harnesses/particles/07-test-phase.md` mentions critic spawn inside its quoted block.

### T-003 unit tests (cross-bundle)
- `test_plan_critic_md5_identical`: md5 across all 3 bundle prompt-dirs matches.
- `test_test_critic_md5_identical`: same.
- `test_phase_05_synced`: claude-code phase 05 byte-identical to codex-cli phase 05.
- `test_codex_skill_md_references_critic_prompts`: codex's `SKILL.md` mentions both critic prompts in its Subagent opportunity section.
- `test_both_bundles_selftest_12`: selftest unchanged at 12 steps, both bundles green.

## Integration Tests

### Component A+B+C integration
- `test_install_then_selftest_12`: install via `claude-code/install.sh` to a temp HOME, then run the installed bundle's selftest; exit 0 with `all 12 transitions matched` (no new selftest step — critic step is LLM-execution-level).

## End-to-End Tests
- **Status:** not-yet-possible at the bash-test level.
- The critic step REQUIRES LLM execution (Agent tool spawn), which the
  selftest harness can't drive. The first sprint to actually invoke
  `/sprint-loop` through Plan or Test phase will exercise the critic
  protocol live — sprint 6 onward is the in-vivo test surface.
- **Unlocked by:** sprint 6 will operationally test the critic by running
  through a normal sprint; sprint 6 may also add a hard-gate via
  `finalize-plan.sh` requiring `critique.md` (deferred-from-this-sprint
  candidate).
