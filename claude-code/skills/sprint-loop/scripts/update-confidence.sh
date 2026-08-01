#!/usr/bin/env bash
# Adjust the optional Book confidence throttle.
# Usage: update-confidence.sh <pass|patched|failed>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/book-paths.sh"
book_require_v2_layout

F=$BOOK_CONFIDENCE_FILE
if [ -f "$F" ]; then C=$(cat "$F"); else C=1.0; fi
case "${1:-}" in
  pass)    C=$(awk -v c="$C" 'BEGIN{v=c+0.1; if(v>1.0)v=1.0; printf "%.1f", v}') ;;
  patched) C=$(awk -v c="$C" 'BEGIN{v=c-0.1; if(v<0.0)v=0.0; printf "%.1f", v}') ;;
  failed)  C=$(awk -v c="$C" 'BEGIN{v=c-0.3; if(v<0.0)v=0.0; printf "%.1f", v}') ;;
  *) echo "usage: $(basename "$0") <pass|patched|failed>" >&2; exit 1 ;;
esac

TMP="$F.tmp.$$"
trap 'rm -f "$TMP"' EXIT
printf '%s\n' "$C" > "$TMP"
mv "$TMP" "$F"
trap - EXIT
echo "confidence: $C"
