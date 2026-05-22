Finalized - DO NOT EDIT

# Sprint 10 Build Plan

## Schema Tree
- Sprint Goal: collapse the plugin's two /sprint-loop surfaces into exactly ONE, no function lost
  - Component A: skill becomes a user-invoked slash command
    - T-001: add `argument-hint:` to SKILL.md frontmatter + an Invocation section folding the command's `$ARGUMENTS` verb routing
  - Component B: remove the duplicate
    - T-002: delete `claude-code/commands/sprint-loop.md` (+ empty `commands/`); update `claude-code/install.sh` (skill-only), `claude-code/README.md`, root `README.md`
  - Component C: regression guard + tests
    - T-003: extend `tools/check-plugin-manifest.sh` to assert the plugin ships NO `commands/sprint-loop.md`; verify selftest unaffected

## Execution Sequence

### T-001: Make SKILL.md a user-invoked slash command
- **Touches:** `claude-code/skills/sprint-loop/SKILL.md`
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** Claude Code loads `skills/sprint-loop/SKILL.md`, **THEN** the frontmatter **SHALL** contain `argument-hint:` describing the verbs (`[continue | start "<goal>" | loop | abort]`) while RETAINING the existing `description:` (so the skill stays both model- and user-invoked).
  - **WHEN** a user invokes `/sprint-loop` with no argument, **THEN** the SKILL.md body **SHALL** instruct running `scripts/current-phase.sh` and continuing; with `start <goal>` → initialize a sprint; with `loop` → Loop Phase; with `abort` → mark aborted and close out — i.e. the command's `$ARGUMENTS` routing folded in.
  - **WHEN** the frontmatter is read, **THEN** it **SHALL NOT** add an `allowed-tools` restriction (the loop needs full tool access).
- **Notes:** Keep `description:` byte-for-byte (discovery surface). Add `argument-hint` line + a short "## Invocation" section. The auto-mode/stop-criterion prose already exists in SKILL.md — do not duplicate it; just reference it.

### T-002: Remove the legacy command + update references
- **Touches:** `claude-code/commands/sprint-loop.md` (delete), `claude-code/install.sh`, `claude-code/README.md`, `README.md`
- **Depends on:** T-001
- **Success criterion (EARS):**
  - **WHEN** the claude-code bundle is inspected, **THEN** `commands/sprint-loop.md` **SHALL NOT** exist (and an empty `commands/` dir **SHALL NOT** remain).
  - **WHEN** `claude-code/install.sh` runs, **THEN** it **SHALL** install the skill only (no `cp` of a command file) and **SHALL NOT** reference `commands/sprint-loop.md`.
  - **WHEN** a user reads `claude-code/README.md` and root `README.md`, **THEN** they **SHALL** describe `/sprint-loop` as provided by the skill (one surface) and **SHALL NOT** instruct copying a separate command file; the plugin install path stays primary.
- **Notes:** codex-cli + open-harnesses untouched. Preserve the README's plugin-install + root-cause section from sprint 9.

### T-003: Regression guard + verification
- **Touches:** `tools/check-plugin-manifest.sh`
- **Depends on:** T-002
- **Success criterion (EARS):**
  - **WHEN** `tools/check-plugin-manifest.sh` runs AND the plugin source dir contains `commands/sprint-loop.md`, **THEN** it **SHALL** exit non-zero naming the duplicate-command regression.
  - **WHEN** the plugin ships skill-only (no such command), **THEN** the checker **SHALL** still exit 0.
  - **WHEN** `selftest.sh` runs, **THEN** it **SHALL** still report `all 14 transitions matched` (scripts unchanged).
- **Notes:** The assert is a single `[ -f "$SRCDIR/commands/sprint-loop.md" ] && fail ...`. Keeps the duplicate from silently returning in a future edit.
