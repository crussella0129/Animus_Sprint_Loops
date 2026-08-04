Finalized - DO NOT EDIT

# Sprint 8 Test Plan

## Unit Tests

### T-001 (SKILL.md)
- `test_skill_checkpoint_default`: "Autonomous operation" says run unattended + halt only at human-verification checkpoints.
- `test_skill_four_categories`: enumerates the four STOP categories incl. unknown-blast-radius under (b).
- `test_skill_ai_verifiable_proceeds`: AI-verifiable/green-CI work (incl. merging known-reversible) proceeds; unknown consequence → checkpoint.
- `test_skill_bounding_optional`: bounding presented as optional; runaway control = commit-rollback + checkpoints + interrupt.

### T-002 (Loop-Phase + consistency guard)
- `test_loop_merge_on_green_autonomous`: 06-loop-phase.md says known-reversible green-CI merge proceeds.
- `test_loop_unknown_or_unverifiable_stops`: it makes deploy/release/unknown-blast-radius a checkpoint.
- `test_loop_visual_review_checkpoint`: it instructs surfacing visually-inspectable artifacts.
- `test_check_merge_policy_passes`: `bash tools/check-merge-policy.sh` exits 0 on the current (consistent) docs.
- `test_check_merge_policy_catches_drift`: temporarily inject a blanket "do NOT merge" (or unconditional `gh pr merge`) into one copy → the script exits non-zero; revert. (Durable guard proven to actually catch drift — the C-001 point.)

### T-003 (command + README)
- `test_command_checkpoint_lead`: command auto-mode section leads with checkpoint philosophy, bounding an aside.
- `test_readme_checkpoint`: README auto-mode describes checkpoint stops, keeps Claude-specific note.
- `test_no_bound_it_headline`: neither doc recommends bounding as primary.
- `test_selftest_unchanged`: both bundles 14/14.

## Integration Tests
- `test_install_then_selftest_14`: install via `claude-code/install.sh` → installed selftest 14/14.

## End-to-End Tests
- **Status:** never bash-testable (harness/LLM-level).
- **First-launch verification (E2E stand-in) — exercises BOTH paths [C-005]:**
  - *Continue path:* on `/loop /sprint-loop continue`, the loop proceeds through AI-verifiable sprints without stopping and does NOT pause merely on a sprint count.
  - *Stop path (positive):* deliberately stage a checkpoint — a sprint that produces a UI/visual artifact, or a merge with an unknown/deploy consequence — and confirm the loop STOPS and surfaces it. (A loop that never stops is indistinguishable from broken checkpoint logic unless the stop path is positively exercised.)
