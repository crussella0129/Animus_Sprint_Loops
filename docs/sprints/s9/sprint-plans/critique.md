# Sprint 9 Plan Critique

> Critic subagent unavailable (API 529 Overloaded, two attempts). Per protocol
> fallback, this is a self-critique with the riskiest assumptions verified
> against the on-disk reference marketplace rather than asserted.

## Concerns

- **C-001 (verified, RESOLVED): is `"source": "./claude-code"` valid?** Yes —
  50 of the official marketplace's plugins use a plain-string local source
  (`agent-sdk-dev` → `"./plugins/agent-sdk-dev"`). No `sha`/`ref`/`url` required
  for a local subdir source. Plan T-001's source form is correct as written.
  *Response: keep as planned.*

- **C-002 (verified, MATERIAL): plugin may surface 2 entries, not 1.** The
  plugin root `claude-code/` contains BOTH `skills/sprint-loop/` and
  `commands/sprint-loop.md` (same name). Plugins auto-discover both `skills/`
  and `commands/`, so the plugin likely presents the skill AND a `/sprint-loop`
  command = 2 surfaces. The reference `agent-sdk-dev` ships commands-only and
  shows once; single-entry skills (`loop`, `claude-api`) are skill-only. So:
  plugin delivery RELIABLY removes the root-collision doubling (4 -> 2), but
  reaching exactly 1 requires shipping skill-only (dropping the command).
  *Response: do NOT silently drop the command — the user actively uses
  `/loop /sprint-loop continue` (usageCount 19). Plan delivers 4 -> 2 (the
  structural win); the 2 -> 1 step (drop command) is surfaced to the user as an
  explicit choice in the Loop phase, since it trades away a command surface they
  use AND its effect is only observable at launch (not bash-verifiable).*

- **C-003 (causal theory falsifiability):** The home-dir root-collision theory
  is the best-supported explanation (only the lone bare install duplicates; all
  plugins show once; user launches from home). It is NOT bash-falsifiable from
  here (picker is a UI surface). The fix does not depend on the theory being
  exactly right: moving delivery to the plugin tree removes sprint-loop from
  `~/.claude/skills` + `~/.claude/commands` entirely, so any
  colliding-roots enumeration of those paths cannot apply. *Response: framed as
  the documented E2E / human-verification checkpoint; fix is robust regardless.*

- **C-004 (no breakage):** Adding repo-root `.claude-plugin/marketplace.json`
  and `claude-code/.claude-plugin/plugin.json` is purely additive — no file
  moves, so bundle atomicity (sprint-0/2 ADR) and `install.sh` are untouched;
  `.gitignore` does not exclude `.claude-plugin/`; selftest is unaffected
  (additive). *Response: T-002 adds a regression assert that the bundle files
  did not move; keep selftest at 14.*

- **C-005 (EARS coverage):** Each build-plan EARS clause maps to a `test_*`:
  marketplace fields -> test_marketplace_*; plugin.json -> test_plugin_json_name;
  source resolves -> test_plugin_source_resolves + test_checker_fails_missing_skill;
  docs -> test_readme_plugin_first; no-move -> test_no_bundle_files_moved. No
  orphan clause. Hidden dependency: T-002 and T-003 both depend on T-001 (paths
  must exist first) — already declared.

## Confidence
proceed-with-caveats — the manifest design is verified correct and fully buildable/testable; the one material caveat (C-002: 4->2, not guaranteed 4->1) is handled by surfacing the skill-only choice to the user rather than silently removing a command surface they use.
