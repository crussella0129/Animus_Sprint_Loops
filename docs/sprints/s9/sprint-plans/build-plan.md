Finalized - DO NOT EDIT

# Sprint 9 Build Plan

## Schema Tree
- Sprint Goal: structurally fix the 4× /sprint-loop picker duplication by delivering the claude-code bundle as an installable Claude Code plugin (marketplace), so it loads once via the plugin mechanism instead of as a bare ~/.claude personal install
  - Component A: plugin + marketplace manifests
    - T-001: add repo-root `.claude-plugin/marketplace.json` (one plugin, `source: ./claude-code`) + `claude-code/.claude-plugin/plugin.json`
  - Component B: manifest validation (bash-testable)
    - T-002: add `tools/check-plugin-manifest.sh` (+ wire into selftest's tail or run standalone) asserting both manifests are valid JSON with required fields and a resolvable skill path
  - Component C: docs + migration
    - T-003: rewrite `claude-code/README.md` Installation to lead with the plugin path + bare-install REMOVAL; add a one-line plugin pointer to the root README

## Execution Sequence

### T-001: Add marketplace + plugin manifests
- **Touches:** `.claude-plugin/marketplace.json` (new), `claude-code/.claude-plugin/plugin.json` (new)
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** Claude Code reads the repo-root `.claude-plugin/marketplace.json`, **THEN** the manifest **SHALL** declare `name: "sprint-loops"`, an `owner`, and a `plugins` array with exactly one entry named `sprint-loop` whose `source` is the local subdir `"./claude-code"`.
  - **WHEN** the plugin is installed, **THEN** `claude-code/.claude-plugin/plugin.json` **SHALL** carry `name: "sprint-loop"`, a `description` (matching the skill's discovery description), and an `author`.
  - **WHEN** the plugin root (`claude-code/`) is scanned, **THEN** its existing `skills/sprint-loop/SKILL.md` and `commands/sprint-loop.md` **SHALL** be the auto-discovered content (no file moves).
- **Notes:** Mirror the on-disk reference shapes exactly (`$schema`, `name`, `description`, `owner{name,email}`, `plugins[]` for the marketplace; `name`, `description`, `author{name,email}` for the plugin). Local-subdir source form is the `"./plugins/agent-sdk-dev"` pattern seen in the official marketplace.

### T-002: Manifest validation check
- **Touches:** `tools/check-plugin-manifest.sh` (new)
- **Depends on:** T-001
- **Success criterion (EARS):**
  - **WHEN** `tools/check-plugin-manifest.sh` runs against a well-formed repo, **THEN** it **SHALL** exit 0 after asserting: both manifests parse as JSON; marketplace has `name` + a `plugins[]` entry named `sprint-loop`; that entry's `source` resolves to a directory containing `skills/sprint-loop/SKILL.md`; the plugin.json `name` equals `sprint-loop`.
  - **WHEN** either manifest is missing, invalid JSON, or the source path does not contain `skills/sprint-loop/SKILL.md`, **THEN** the check **SHALL** exit non-zero with a message naming the failed assertion.
- **Notes:** Use `python3 -c` for JSON parse/field extraction (jq may be absent on Windows git-bash). Resolve `ROOT` via `BASH_SOURCE` parent-of-parent (sibling-script lesson). No dependency on the picker (not bash-observable).

### T-003: Docs + migration
- **Touches:** `claude-code/README.md`, `README.md` (repo root, if present — else `open-harnesses`/top doc)
- **Depends on:** T-001
- **Success criterion (EARS):**
  - **WHEN** a user reads `claude-code/README.md` Installation, **THEN** it **SHALL** present the plugin path FIRST — `/plugin marketplace add crussella0129/sprint-loops` then `/plugin install sprint-loop@sprint-loops` — labelled recommended, with the manual `cp`-into-`~/.claude` path kept below as an explicit fallback.
  - **WHEN** a user has the bare personal install AND switches to the plugin, **THEN** the README **SHALL** instruct removing `~/.claude/skills/sprint-loop` and `~/.claude/commands/sprint-loop.md` so the load-time duplication is eliminated, and **SHALL** state the root cause in one sentence (bare personal installs are scanned by both the user and project roots, which coincide when Claude Code is launched from the home dir).
  - **WHEN** a user reads the repo-root README, **THEN** it **SHALL** mention the repo is an installable plugin marketplace.
- **Notes:** Don't touch the YAML `description:` of SKILL.md. README is human-facing; keep the protocol section intact.
