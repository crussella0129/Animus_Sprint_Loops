# Sprint 9 Unit Tests — Results

All run via `tools/check-plugin-manifest.sh` against the real tree + temp fixtures.

| Test | Result | Evidence |
|------|--------|----------|
| test_marketplace_valid_json | PASS | checker parses `.claude-plugin/marketplace.json` |
| test_marketplace_declares_plugin | PASS | entry `name==sprint-loop`, `source=="./claude-code"` asserted (exit 5 if wrong) |
| test_plugin_json_name | PASS | `claude-code/.claude-plugin/plugin.json` `.name==sprint-loop` |
| test_plugin_source_resolves | PASS | `./claude-code` resolves to dir containing `skills/sprint-loop/SKILL.md` |
| test_checker_passes_on_good_repo | PASS | exit 0, "OK — marketplace 'sprint-loop' -> ./claude-code" |
| test_checker_fails_missing_skill | PASS | temp copy w/o SKILL.md → nonzero, "missing skills/sprint-loop/SKILL.md" |
| test_checker_fails_bad_json | PASS | corrupt marketplace.json → nonzero, "not valid JSON" |
| test_readme_plugin_first | PASS | both `/plugin` lines + bare-install removal lines present |
