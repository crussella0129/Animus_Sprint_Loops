Finalized - DO NOT EDIT

# Sprint 2 Test Plan

## Unit Tests

### T-001 unit tests
- `test_finalize_rejects_empty_plan`: in a temp project where `build-plan.md` contains text but no `### T-XXX:` lines, `finalize-plan.sh` exits non-zero with a message mentioning "no `### T-XXX:` execution entries" and the file's first line is NOT `Finalized - DO NOT EDIT`.
- `test_finalize_accepts_plan_with_task`: same setup but with `### T-001: demo` appended; `finalize-plan.sh` exits 0 and the file is locked.
- `test_selftest_step_count`: `bash selftest.sh` exits 0 and the final line reports "all 10 transitions matched" (the original 9 plus the new empty-plan rejection step).
- Stubs: none.

### T-002 unit tests
- `test_install_claude_code_fresh`: in a temp `HOME`, run `bash claude-code/install.sh`; assert `$HOME/.claude/skills/sprint-loop/SKILL.md` and `$HOME/.claude/commands/sprint-loop.md` exist and the skill's scripts are executable.
- `test_install_claude_code_idempotent`: run `bash claude-code/install.sh` twice; second run reports "removed prior install" then re-installs; final tree md5 matches first-run tree md5.
- `test_install_codex_fresh`: same as above for `codex-cli/install.sh` targeting `$HOME/.codex/skills/sprint-loops/`.
- `test_install_open_harnesses`: `bash open-harnesses/install.sh <tempdir>`; assert `<tempdir>/scripts/current-phase.sh` exists and is executable; rerun and confirm idempotent.
- Stubs: a throwaway `$HOME` (via `HOME=$T` override) for the install targets.

### T-003 unit tests
- `test_scripts_identical_across_bundles`: `md5sum` of `finalize-plan.sh` and `selftest.sh` matches across `open-harnesses/scripts/`, `claude-code/skills/sprint-loop/scripts/`, `codex-cli/skills/sprint-loops/scripts/`.
- `test_both_bundles_selftest_10_steps`: each bundle's `selftest.sh` exits 0 and reports "all 10 transitions matched".

## Integration Tests

### Component A+B+C integration
- `test_install_then_selftest`: run `bash claude-code/install.sh` against a temp `HOME`; then run `bash $HOME/.claude/skills/sprint-loop/scripts/selftest.sh`; assert exit 0 and "all 10 transitions matched". Demonstrates the install path produces a working skill end-to-end.

## End-to-End Tests
- **Status:** not-yet-possible.
- Same constraint as prior sprints: the document-authoring layer is still LLM-in-the-loop. The script + install layer is now fully exercised by the unit and integration tests above.
- **Unlocked by:** a sprint 3 candidate adding CI (GitHub Actions running `install.sh` then `selftest.sh` for each bundle on push).
