Finalized - DO NOT EDIT

# Sprint 7 Test Plan

## Unit Tests (doc-presence; auto mode is harness/LLM-level, not bash-drivable)

### T-001 (Plan Phase)
- `test_plan_phase_enterplanmode_mandatory`: `phases/03-plan-phase.md` states EnterPlanMode is the mandatory first action.
- `test_plan_phase_autoaccept`: it mentions selecting auto-accept / "auto mode" at the ExitPlanMode approval for unattended runs.
- `test_plan_phase_interactive_path`: the interactive review/approve path is retained.

### T-002 (SKILL.md + Loop-Phase merge gate)
- `test_skill_plan_mode_autoaccept`: SKILL.md "Plan mode" mentions ExitPlanMode + auto-accept selection.
- `test_skill_loop_launch_resume`: SKILL.md "Autonomous operation" contains `/loop /sprint-loop continue` AND says re-fire re-runs `current-phase.sh` / resumes (not a cadence claim). [C-002]
- `test_skill_bounding_recommendation`: SKILL.md recommends bounding (`/loop N ...`) and warns unbounded runs continue until interrupt. [C-003]
- `test_skill_safety_floor_automode`: SKILL.md states no unattended merge-to-base / force-push / destructive without opt-in.
- `test_loop_phase_merge_gated`: `phases/06-loop-phase.md` PR-merge step is gated on interactive-or-opt-in (NOT an unconditional `gh pr merge`). [C-004 — the decisive fix; this is the test the critic noted was missing]

### T-003 (command + cross-bundle)
- `test_command_loop_launch`: `commands/sprint-loop.md` contains `/loop /sprint-loop continue` + bounding recommendation.
- `test_particle_08_recurrence_and_gate`: `open-harnesses/particles/08-loop-phase.md` mentions the recurrence primitive AND the human-gated merge.
- `test_codex_loop_phase_merge_gated`: codex `phases/06-loop-phase.md` merge step carries the same gate (consistent with claude).
- `test_readme_claude_specific`: `claude-code/README.md` notes auto mode is Claude-specific.
- `test_selftest_unchanged`: both bundles' `selftest.sh` still report `all 14 transitions matched` (no script change).

## Integration Tests
- `test_install_then_selftest_14`: install via `claude-code/install.sh` → installed selftest exits 0 with `all 14 transitions matched`.

## End-to-End Tests
- **Status:** never bash-testable — auto mode is a harness behavior (plan-mode auto-accept + `/loop`).
- **First-launch verification (E2E stand-in, per critic C-007):** first unattended launch should be bounded (`/loop 2 /sprint-loop continue` or interrupt after one sprint) and confirm: (a) plan mode engaged, (b) auto-accept carried Build/Test/Loop without per-step prompts, (c) the next sprint fired, (d) NO merge-to-base happened unattended (PR left open for review).
