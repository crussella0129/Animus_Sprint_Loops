#!/usr/bin/env bash
# Provider-agnostic sprint checkpoint adapter. Opens exactly one work->base
# PR/MR via the declared remote profile (github->gh, gitlab->glab), or falls
# back to pushing work and printing the compare URL. Never merges — merging is
# the human-approve boundary. Usage:
#   remote-adapter.sh [--root D] pr-exists              # exit 0 if an open PR/MR exists
#   remote-adapter.sh [--root D] open-pr [--title T] [--body B]
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT="${SPRINT_LOOP_PROJECT_ROOT:-.}"
TITLE=""; BODY=""; ACTION=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) SPRINT_LOOP_PROJECT_ROOT="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --body) BODY="$2"; shift 2 ;;
    pr-exists|open-pr) ACTION="$1"; shift ;;
    *) echo "remote-adapter: unknown argument $1" >&2; exit 2 ;;
  esac
done
. "$SCRIPT_DIR/book-paths.sh"
ROOT="$SPRINT_LOOP_PROJECT_ROOT"
[ -n "$ACTION" ] || { echo "remote-adapter: expected pr-exists|open-pr" >&2; exit 2; }

prof=$(bash "$SCRIPT_DIR/remote-profile.sh" --root "$ROOT") ||
  { echo "remote-adapter: no resolvable remote profile" >&2; exit 1; }
provider=$(printf '%s\n' "$prof" | sed -n 's/^PROVIDER=//p')
base=$(printf '%s\n' "$prof" | sed -n 's/^BASE=//p')
work=$(printf '%s\n' "$prof" | sed -n 's/^WORK=//p')

pr_exists() {
  case "$provider" in
    github)
      command -v gh >/dev/null 2>&1 || return 1
      [ -n "$(gh pr list --head "$work" --base "$base" --state open --json number --jq '.[].number' 2>/dev/null)" ] ;;
    gitlab)
      command -v glab >/dev/null 2>&1 || return 1
      glab mr list --source-branch "$work" --target-branch "$base" --state opened 2>/dev/null | grep -q '!' ;;
    *) return 1 ;;
  esac
}

compare_url() {
  if url=$(git -C "$ROOT" remote get-url origin 2>/dev/null) && [ -n "$url" ]; then
    printf '%s (compare %s...%s)' "$url" "$base" "$work"
  else
    printf '(no origin remote configured)'
  fi
}

open_pr() {
  [ -n "$TITLE" ] || TITLE="Sprint checkpoint: $work -> $base"
  git -C "$ROOT" push -q -u origin "$work" 2>/dev/null || true
  case "$provider" in
    github)
      if command -v gh >/dev/null 2>&1; then
        ( cd "$ROOT" && gh pr create --head "$work" --base "$base" --title "$TITLE" --body "$BODY" ) && return 0
      fi ;;
    gitlab)
      if command -v glab >/dev/null 2>&1; then
        ( cd "$ROOT" && glab mr create --source-branch "$work" --target-branch "$base" --title "$TITLE" --description "$BODY" ) && return 0
      fi ;;
  esac
  printf 'remote-adapter: pushed %s; open a %s -> %s PR/MR manually: %s\n' "$work" "$work" "$base" "$(compare_url)"
  return 0
}

case "$ACTION" in
  pr-exists) pr_exists ;;
  open-pr)
    if [ "$provider" = local-only ]; then
      echo "remote-adapter: local-only profile; no PR/MR opened"; exit 0
    fi
    if pr_exists; then
      echo "remote-adapter: an open $work -> $base PR/MR already exists; not opening a second"; exit 0
    fi
    open_pr ;;
esac
