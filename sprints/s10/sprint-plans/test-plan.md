Finalized - DO NOT EDIT

# Sprint 10 Test Plan

## Unit Tests
### T-001 (skill frontmatter/body)
- `test_skill_has_argument_hint`: SKILL.md frontmatter contains an `argument-hint:` line.
- `test_skill_keeps_description`: the original `description:` line is unchanged (byte-for-byte).
- `test_skill_no_allowed_tools`: frontmatter contains NO `allowed-tools:` key.
- `test_skill_routes_verbs`: SKILL.md body mentions the four routing cases (no-arg→current-phase/continue, `start`, `loop`, `abort`).

### T-002 (removal + refs)
- `test_command_file_gone`: `claude-code/commands/sprint-loop.md` does not exist.
- `test_commands_dir_not_empty_or_absent`: `claude-code/commands/` is absent (no empty dir left).
- `test_install_sh_skill_only`: `claude-code/install.sh` contains no `commands/sprint-loop` reference.
- `test_readmes_no_command_copy`: neither `claude-code/README.md` nor root `README.md` instructs copying `commands/sprint-loop.md`; both retain the `/plugin install` line.

### T-003 (regression guard)
- `test_checker_passes_skill_only`: `tools/check-plugin-manifest.sh` exits 0 on the (now skill-only) real tree.
- `test_checker_fails_if_command_returns`: in a temp copy where `commands/sprint-loop.md` is re-added under the source dir, the checker exits non-zero naming the duplicate-command regression.

## Integration
- `test_selftest_still_passes`: each bundle's `selftest.sh` exits 0 at "all 14 transitions matched".
- `test_codex_command_untouched`: codex-cli's bundle is unchanged by this sprint (out of scope).

## E2E (launch-time, NOT bash-observable — documented user check)
- `e2e_single_entry`: after `/plugin install sprint-loop@sprint-loops` (skill-only), launching Claude Code from the home dir shows exactly ONE `/sprint-loop` entry, and `/sprint-loop continue` / `/sprint-loop start "<goal>"` / `/loop /sprint-loop continue` all still work (the skill is the slash command). Human-verification checkpoint.

## Confidence
The duplicate-source removal is fully bash-tested; whether the skill renders as a usable `/sprint-loop <verb>` slash command is the launch-time E2E — backed by the official reference (`example-command` skill uses `argument-hint` as a user-invoked slash command).
