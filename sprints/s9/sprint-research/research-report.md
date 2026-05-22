# Sprint 9 Research Report

## Decisions Reviewed

- **2026-05-19 — "each subdirectory is a complete atomic unit" (sprint 0/2 install ADR)** — relevant: the plugin packaging must not break the three-bundle atomicity. The plugin wraps the EXISTING `claude-code/` bundle via a manifest; it doesn't restructure or couple bundles.
- **2026-05-20/21 — install.sh per bundle (sprint 2) + idempotent reinstall** — relevant: `claude-code/install.sh` (bare ~/.claude install) remains as a fallback, but plugin install becomes the RECOMMENDED path. The duplication this sprint fixes is a property of the bare-install delivery, not of install.sh's idempotency.
- **2026-05-21 — leaked-temp-copy fix** — relevant: confirms the prior "4" investigation; this sprint addresses a DIFFERENT "4" (load-time duplication of the single bare install, not stray files).

No prior decision is violated. This sprint adds a new (recommended) delivery channel; the bare-install path stays as a documented fallback.

## 1. Sprint Goal

Root-cause and structurally fix the "4 identical `/sprint-loop` picker entries"
the user sees when launching Claude Code from their home dir, by packaging the
claude-code bundle as an installable Claude Code **plugin** (the same delivery
mechanism the non-duplicating skills use).

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| `~/.claude/skills/sprint-loop/` + `~/.claude/commands/sprint-loop.md` | **high** | The bare personal install. The ONLY personal (non-plugin) skill on the system → the only thing that duplicates. |
| `~/.claude/plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json` | **high** | Reference marketplace manifest. Fields: `$schema`, `name`, `description`, `owner{name,email}`, `plugins[]`. A plugin entry can use a LOCAL subdir source: `"source": "./plugins/<name>"` (seen on `agent-sdk-dev`). |
| `.../plugins/skill-creator/.claude-plugin/plugin.json` | **high** | Reference plugin manifest: `name`, `description`, `author{name,email}`. Plugin root auto-discovers `skills/` and `commands/`. |
| `claude-code/skills/sprint-loop/`, `claude-code/commands/sprint-loop.md` | **high** | Already the right shape for a plugin root — just add `claude-code/.claude-plugin/plugin.json` and a repo-root marketplace. |
| `claude-code/install.sh` + README | medium | Keep as documented fallback; README gains the plugin-install path as recommended. |

## 3. External Sources

None beyond the on-disk reference manifests (the canonical `claude-plugins-official` marketplace). Budget: 0 of 5.

## 4. Risks, Unknowns, Dependencies

- **Root-cause certainty.** The most-supported hypothesis: personal skills/commands are scanned from BOTH the user root (`~/.claude`) and the project root (`<cwd>/.claude`); when `cwd` is the home dir those roots are the SAME directory, so the single skill and single command are each enumerated twice → 4 identical entries. Plugin-delivered skills (every other picker entry) live in `~/.claude/plugins/...`, not in either colliding root, so they don't double — which is exactly why ONLY sprint-loop duplicates. **The plugin fix is robust even if this mechanism is slightly off**: moving delivery to the plugin tree removes sprint-loop from `~/.claude/skills` + `~/.claude/commands` entirely, so whatever doubles those no longer applies.
- **Risk: skill + command still = 2 entries.** A plugin shipping both a skill AND a same-named command may surface 2 picker entries (loaded once each, not doubled). To reach exactly ONE, the plugin could ship the skill only. Decision deferred to Plan — flag the 2-vs-1 trade-off (the command provides `start`/`continue`/`abort` typed args).
- **Risk: can't verify the picker from bash.** Manifest well-formedness (valid JSON, correct schema/fields, structure matches reference plugins) IS bash-testable; the actual picker count is a launch-time user check (documented as the E2E).
- **Risk: marketplace name collision / repo-as-marketplace.** The repo root gets `.claude-plugin/marketplace.json`; the plugin sources from `./claude-code`. Must not conflict with the existing root `.gitignore` or bundle atomicity. Low risk — additive files.
- **Dependency:** Claude Code plugin system (`/plugin marketplace add`, `/plugin install`). No new repo deps.

## 5. Recommended Approach

**Primary:** package the repo as a single-plugin marketplace.

1. *Marketplace + plugin manifests.* Add `.claude-plugin/marketplace.json` at the repo root declaring one plugin `sprint-loop` with `"source": "./claude-code"`. Add `claude-code/.claude-plugin/plugin.json` (`name: sprint-loop`, description, author). The existing `claude-code/skills/sprint-loop/` + `claude-code/commands/sprint-loop.md` become the plugin's auto-discovered content.
2. *Manifest validation test.* A committed check (extend `tools/` or a small validator) that both manifests are valid JSON, carry the required fields, and the plugin source path resolves to a dir containing `skills/sprint-loop/SKILL.md`.
3. *Docs + migration.* `claude-code/README.md` + root README: lead install with the plugin path — `/plugin marketplace add crussella0129/sprint-loops` then `/plugin install sprint-loop@sprint-loops` — and document REMOVING the bare personal install (`rm -rf ~/.claude/skills/sprint-loop ~/.claude/commands/sprint-loop.md`) so the duplication is gone. Keep `install.sh` as the explicit non-plugin fallback.

**Alternatives considered:**
- *"Just don't run from home."* Rejected as the primary fix — it's environmental advice, not structural; the user explicitly wants the structural answer.
- *Drop the command (skill-only) on the bare install.* Reduces 4→2 but doesn't address the root delivery difference; doesn't make sprint-loop behave like the other (plugin) skills.
- *Ship skill-only in the plugin.* Considered for "exactly 1" — deferred to Plan as a trade-off (loses typed-arg command).

**Rationale:** The non-duplicating skills are all plugins; sprint-loop is the lone bare personal install. Matching their delivery (plugin) is the structural fix — it removes sprint-loop from the colliding `~/.claude/skills` + `~/.claude/commands` roots entirely, so the load-time doubling can't occur regardless of cwd.

## Artifacts
- (none — reference manifests inspected inline)
