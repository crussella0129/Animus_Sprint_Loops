Finalized - DO NOT EDIT

# Sprint 9 Test Plan

## Unit Tests

### T-001 unit tests (manifests) — exercised via T-002's checker
- `test_marketplace_valid_json`: repo-root `.claude-plugin/marketplace.json` parses as JSON.
- `test_marketplace_declares_plugin`: `.plugins[]` contains an entry with `name == "sprint-loop"` and `source == "./claude-code"`.
- `test_plugin_json_name`: `claude-code/.claude-plugin/plugin.json` parses and `.name == "sprint-loop"`.
- `test_plugin_source_resolves`: the dir named by the plugin entry's `source` contains `skills/sprint-loop/SKILL.md`.

### T-002 unit tests (checker behavior)
- `test_checker_passes_on_good_repo`: `tools/check-plugin-manifest.sh` exits 0 on the real tree.
- `test_checker_fails_missing_skill`: in a temp copy where `skills/sprint-loop/SKILL.md` is removed under the source dir, the checker exits non-zero mentioning the skill path.
- `test_checker_fails_bad_json`: in a temp copy where `marketplace.json` is corrupted, the checker exits non-zero mentioning JSON parse.

### T-003 unit tests (docs)
- `test_readme_plugin_first`: `claude-code/README.md` contains `/plugin marketplace add crussella0129/sprint-loops` and `/plugin install sprint-loop@sprint-loops`, and the bare-install removal lines (`~/.claude/skills/sprint-loop`, `~/.claude/commands/sprint-loop.md`).

## Integration / cross-bundle
- `test_no_bundle_files_moved`: `claude-code/skills/sprint-loop/SKILL.md` and `claude-code/commands/sprint-loop.md` still exist at their original paths (the plugin wraps, not moves).
- `test_selftest_still_passes`: each bundle's `selftest.sh` still exits 0 at "all 14 transitions matched" (manifests are additive — no protocol change).

## E2E (launch-time, NOT bash-observable — documented user check)
- `e2e_picker_count`: after removing the bare install and `/plugin install sprint-loop@sprint-loops`, launching Claude Code FROM THE HOME DIR shows the plugin loaded ONCE via the plugin mechanism (no 4× root-collision doubling). Expected surfaces: the skill plus its `/sprint-loop` command (≤2), NOT 4. Reaching exactly 1 = the optional skill-only variant (drop the command). This is the human-verification checkpoint — the picker count is a UI surface the sprint cannot assert from bash.

## Confidence
The fix is robust independent of the exact doubling mechanism: plugin delivery removes sprint-loop from `~/.claude/skills` + `~/.claude/commands` entirely, so the colliding-roots enumeration no longer applies. Manifest correctness is fully bash-tested; the picker count is the documented E2E.
