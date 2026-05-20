#!/usr/bin/env bash
# Idempotent installer for the sprint-loops Codex CLI skill.
# Wipes any prior install at the target before copying fresh.
#
# Usage:
#   bash codex-cli/install.sh             # user-level: ~/.codex/skills/
#   bash codex-cli/install.sh --project   # project-level: $(pwd)/.codex/skills/ (project must be trusted)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/skills/sprint-loops"

if [ "${1:-}" = "--project" ]; then
  BASE="$(pwd)/.codex"
else
  BASE="$HOME/.codex"
fi
SKILL_DST="$BASE/skills/sprint-loops"

mkdir -p "$BASE/skills"

if [ -d "$SKILL_DST" ]; then
  echo "removed prior install: $SKILL_DST"
  rm -rf "$SKILL_DST"
fi

cp -r "$SKILL_SRC" "$SKILL_DST"
chmod +x "$SKILL_DST/scripts"/*.sh

echo "installed: $SKILL_DST"
echo
echo "Next: append the AGENTS.md fragment to your project's AGENTS.md:"
echo "  cat $SKILL_DST/AGENTS.md.fragment >> AGENTS.md"
