#!/usr/bin/env bash
# Idempotent installer for the sprint-loop Claude Code skill.
# Wipes any prior install at the target before copying fresh — so running
# this twice always lands the current bundle, no stale files left over.
#
# The skill IS the /sprint-loop slash command (its frontmatter carries
# argument-hint), so there is no separate command file to install. Prefer the
# plugin install (see README) — this manual path is the fallback.
#
# Usage:
#   bash claude-code/install.sh             # user-level: ~/.claude/skills/
#   bash claude-code/install.sh --project   # project-level: $(pwd)/.claude/skills/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/skills/sprint-loop"

if [ "${1:-}" = "--project" ]; then
  BASE="$(pwd)/.claude"
else
  BASE="$HOME/.claude"
fi
SKILL_DST="$BASE/skills/sprint-loop"

mkdir -p "$BASE/skills"

if [ -d "$SKILL_DST" ]; then
  echo "removed prior install: $SKILL_DST"
  rm -rf "$SKILL_DST"
fi

cp -r "$SKILL_SRC" "$SKILL_DST"
chmod +x "$SKILL_DST/scripts"/*.sh

echo "installed: $SKILL_DST"
echo "note: /sprint-loop is provided by the skill itself — no separate command file."
