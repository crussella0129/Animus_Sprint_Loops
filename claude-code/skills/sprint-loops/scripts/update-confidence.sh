#!/usr/bin/env bash
# Adjust the optional confidence throttle. See the open-harnesses README,
# section "Confidence Throttle (Optional)".
# Usage: update-confidence.sh <pass|patched|failed>
#   pass    — all tests passed              → confidence + 0.1 (capped at 1.0)
#   patched — failures patched in-sprint    → confidence - 0.1
#   failed  — failure-report written        → confidence - 0.3
set -euo pipefail

F="confidence.txt"
[ -f "$F" ] || echo "1.0" > "$F"
C=$(cat "$F")

case "${1:-}" in
  pass)    C=$(awk -v c="$C" 'BEGIN{v=c+0.1; if(v>1.0)v=1.0; printf "%.1f", v}') ;;
  patched) C=$(awk -v c="$C" 'BEGIN{printf "%.1f", c-0.1}') ;;
  failed)  C=$(awk -v c="$C" 'BEGIN{printf "%.1f", c-0.3}') ;;
  *) echo "usage: $(basename "$0") <pass|patched|failed>" >&2; exit 1 ;;
esac

echo "$C" > "$F"
echo "confidence: $C"
