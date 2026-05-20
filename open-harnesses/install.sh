#!/usr/bin/env bash
# Idempotent installer for the Sprint Loops helper scripts.
# Copies open-harnesses/scripts/ into <target>/scripts/, wiping any prior
# <target>/scripts/ first. Use for the open-harness deployment path (the
# canonical "scripts at project root" install pattern).
#
# Usage:
#   bash open-harnesses/install.sh             # target = $(pwd)
#   bash open-harnesses/install.sh /path/proj  # target = /path/proj
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_SRC="$SCRIPT_DIR/scripts"
TARGET="${1:-$(pwd)}"
SCRIPTS_DST="$TARGET/scripts"

if [ ! -d "$TARGET" ]; then
  echo "target directory does not exist: $TARGET" >&2
  exit 1
fi

if [ -d "$SCRIPTS_DST" ]; then
  echo "removed prior install: $SCRIPTS_DST"
  rm -rf "$SCRIPTS_DST"
fi

cp -r "$SCRIPTS_SRC" "$SCRIPTS_DST"
chmod +x "$SCRIPTS_DST"/*.sh

echo "installed: $SCRIPTS_DST"
