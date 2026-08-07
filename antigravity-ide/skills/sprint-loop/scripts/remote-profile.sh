#!/usr/bin/env bash
# Resolve and validate the Book-tracked Sprint Loops remote profile.
# Usage: remote-profile.sh [--root <dir>] [<field>]
#   <field> in provider|base|work|bump|mergePolicy prints one value;
#   with no field, prints all resolved values as KEY=VALUE lines.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT="${SPRINT_LOOP_PROJECT_ROOT:-.}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) SPRINT_LOOP_PROJECT_ROOT="$2"; shift 2 ;;
    *) break ;;
  esac
done
. "$SCRIPT_DIR/book-paths.sh"

fail() { printf 'remote-profile: %s\n' "$*" >&2; exit 1; }

PROFILE=$(book_join_root docs/work/remote-profile.md)
FIELD="${1:-}"

[ -f "$PROFILE" ] || fail "no remote profile at $PROFILE"
grep -qF '<!-- sprint-loop-remote-profile-v1 -->' "$PROFILE" ||
  fail "remote profile missing the sprint-loop-remote-profile-v1 marker"

# Parse key: value lines inside the first fenced code block only.
parse_profile() {
  awk '
    { sub(/\r$/, "") }
    /^```/ { fence = !fence; next }
    fence && /^[A-Za-z][A-Za-z]*:[[:space:]]/ {
      key = $0; sub(/:.*/, "", key)
      val = $0; sub(/^[^:]*:[[:space:]]*/, "", val); sub(/[[:space:]]+$/, "", val)
      print key "=" val
    }
  ' "$PROFILE"
}

provider=""; base=""; work=""; bump=""; merge_policy=""
while IFS='=' read -r pkey pval; do
  case "$pkey" in
    provider) provider=$pval ;;
    base) base=$pval ;;
    work) work=$pval ;;
    bump) bump=$pval ;;
    mergePolicy) merge_policy=$pval ;;
  esac
done < <(parse_profile)

[ -n "$provider" ] || fail "profile missing required field: provider"
case "$provider" in
  github|gitlab|generic|local-only) ;;
  *) fail "unknown provider '$provider' (expected github|gitlab|generic|local-only)" ;;
esac
[ -n "$base" ] || fail "profile missing required field: base"
[ -n "$work" ] || fail "profile missing required field: work"
[ -n "$bump" ] || bump=none
[ -n "$merge_policy" ] || merge_policy=human-approve
case "$merge_policy" in
  human-approve|auto-on-green) ;;
  *) fail "unknown mergePolicy '$merge_policy' (expected human-approve|auto-on-green)" ;;
esac

case "$FIELD" in
  "") printf 'PROVIDER=%s\nBASE=%s\nWORK=%s\nBUMP=%s\nMERGEPOLICY=%s\n' \
        "$provider" "$base" "$work" "$bump" "$merge_policy" ;;
  provider) printf '%s\n' "$provider" ;;
  base) printf '%s\n' "$base" ;;
  work) printf '%s\n' "$work" ;;
  bump) printf '%s\n' "$bump" ;;
  mergePolicy) printf '%s\n' "$merge_policy" ;;
  *) fail "unknown field '$FIELD' (expected provider|base|work|bump|mergePolicy)" ;;
esac
