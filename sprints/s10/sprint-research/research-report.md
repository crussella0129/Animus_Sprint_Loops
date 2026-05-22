# Sprint 10 Research Report

## Decisions Reviewed
- **2026-05-22 — sprint-loop ships as a Claude Code plugin (sprint 9)** — directly extended here. Sprint 9 delivered the plugin (4→2). This sprint takes 2→1 by removing the duplicate surface, which sprint 9 deliberately deferred to a user decision (critique C-002). The user authorized investigating; the investigation resolved the trade-off (none exists).
- **2026-05-21 — bundle atomicity (sprint 0/2)** — removing the command is still within the claude-code bundle; codex-cli and open-harnesses are untouched. The bundle stays self-contained (skill-only).

## 1. Sprint Goal
Collapse the plugin's two `/sprint-loop` surfaces into exactly ONE, with no loss
of function, by making the skill a user-invoked slash command and removing the
now-redundant legacy command file.

## 2. Existing Code Survey (investigation findings — the core of this sprint)
| Source | Finding |
|--------|---------|
| `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/README.md` (official, on-disk) | "The `commands/*.md` layout is a **legacy format**. It is **loaded identically to `skills/<name>/SKILL.md`** — the only difference is file layout." → a skill + same-named command = a DUPLICATE definition of `/sprint-loop`, not two complementary surfaces. This is the "2". |
| `.../example-plugin/skills/example-command/SKILL.md` | A **user-invoked skill** carries `name` + `description` + `argument-hint:` (+ optional `allowed-tools`) and IS the slash command `/name` with args. A skill may have BOTH `description` (model-invoked) and `argument-hint` (user-invoked). |
| `claude-code/commands/sprint-loop.md` | Unique content = `$ARGUMENTS` verb routing (no-arg→continue, `start <goal>`, `loop`, `abort`) + auto-mode launch notes. The auto-mode/stop-criterion prose already lives in SKILL.md (sprints 3/7/8). Only the verb routing must move into SKILL.md. |
| refs to migrate | `claude-code/install.sh` (copies the command), `claude-code/README.md` (layout table + fallback + usage), root `README.md` (mentions the command). `completed-tasks.md`/`decisions.md` are historical — leave. |
| `tools/check-plugin-manifest.sh` | Doesn't check the command. Opportunity: add a regression assert that the plugin ships NO `commands/sprint-loop.md` (so the duplicate cannot return). |

## 3. External Sources
None beyond the on-disk official `example-plugin` (the canonical teaching reference). Budget: 0 of 5.

## 4. Risks, Unknowns, Dependencies
- **Risk: skill not invocable as `/sprint-loop <verb>` after dropping the command.** Mitigated: `argument-hint` makes a skill a user-invoked slash command per the reference; verb routing moves into SKILL.md body. Still a launch-time UI behavior → documented E2E.
- **Risk: restricting tools via `allowed-tools` would break the loop** (it needs Bash/Edit/Write/Agent). Mitigation: do NOT add `allowed-tools` (omission = full access, current behavior). Add only `argument-hint`.
- **Risk: install.sh `cp` of a deleted file fails.** Mitigation: T-002 updates install.sh to skill-only in the same task.
- **Dependency:** none new. codex-cli keeps its own command (separate runtime, out of scope).

## 5. Recommended Approach
1. **Skill becomes user-invoked too** — add `argument-hint:` to SKILL.md frontmatter (keep `description`); add a short "Invocation" section routing `$ARGUMENTS` (continue/start/loop/abort), folding the command's dispatch.
2. **Remove `claude-code/commands/sprint-loop.md`** (and the now-empty `commands/`), so `/sprint-loop` is defined exactly once.
3. **Update refs** — `install.sh` (skill-only), `claude-code/README.md` (layout/fallback/usage), root README; add a checker assertion that no conflicting command ships.

**Alternatives:** keep both (rejected — that IS the duplicate); ship command-only and drop the skill (rejected — the skill carries phases/scripts/auto-trigger; the command is the thin legacy file).
