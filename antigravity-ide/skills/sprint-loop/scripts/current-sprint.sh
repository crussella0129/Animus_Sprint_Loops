#!/usr/bin/env bash
# Print the highest Book sprint number, or -1 when no Sprint Loops state exists.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/book-paths.sh"

case "$(book_layout_state)" in
  none) echo -1; exit 0 ;;
  conflict) printf '%s\n' "$BOOK_SPLIT_BRAIN_DIAGNOSTIC" >&2; exit 1 ;;
  legacy-only) printf '%s\n' "$BOOK_LEGACY_ONLY_DIAGNOSTIC" >&2; exit 1 ;;
esac
book_require_v2_layout

n=-1
for d in "$BOOK_SPRINTS_DIR"/s*/; do
  [ -d "$d" ] || continue
  b=${d%/}; b=${b##*/}; b=${b#s}
  case "$b" in ''|*[!0-9]*) continue ;; esac
  if [ "$b" -gt "$n" ]; then n=$b; fi
done
echo "$n"
