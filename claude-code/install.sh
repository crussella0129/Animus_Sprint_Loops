#!/usr/bin/env bash
# Idempotent installer for the sprint-loop Claude Code skill.
# Wipes any prior install at the target before copying fresh — so running
# this twice always lands the current bundle, no stale files left over.
#
# Usage:
#   bash claude-code/install.sh             # user-level: ~/.claude/{skills,commands}/
#   bash claude-code/install.sh --project   # project-level: $(pwd)/.claude/{skills,commands}/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/skills/sprint-loop"
CMD_SRC="$SCRIPT_DIR/commands/sprint-loop.md"

if [ "${1:-}" = "--project" ]; then
  BASE="$(pwd)/.claude"
else
  BASE="$HOME/.claude"
fi
SKILL_DST="$BASE/skills/sprint-loop"
CMD_DST="$BASE/commands/sprint-loop.md"

mkdir -p "$BASE/skills" "$BASE/commands"

if [ -d "$SKILL_DST" ]; then
  echo "removed prior install: $SKILL_DST"
  rm -rf "$SKILL_DST"
fi
if [ -f "$CMD_DST" ]; then
  echo "removed prior install: $CMD_DST"
  rm -f "$CMD_DST"
fi

cp -r "$SKILL_SRC" "$SKILL_DST"
cp    "$CMD_SRC"   "$CMD_DST"
chmod +x "$SKILL_DST/scripts"/*.sh

echo "installed: $SKILL_DST"
echo "installed: $CMD_DST"
