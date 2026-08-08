#!/usr/bin/env bash
# Boundary resync: bring `base` into `work` (fast-forward or merge) so `work`
# inherits every accepted corpus change on `base`. Writes only
# `work`; `base` stays the single confluence. Refuses on a dirty tracked tree.
# Usage: sync-work-branch.sh [--root <dir>]
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT="${SPRINT_LOOP_PROJECT_ROOT:-.}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) SPRINT_LOOP_PROJECT_ROOT="$2"; shift 2 ;;
    *) echo "sync-work-branch: unknown argument $1" >&2; exit 2 ;;
  esac
done
. "$SCRIPT_DIR/book-paths.sh"
ROOT="$SPRINT_LOOP_PROJECT_ROOT"
fail() { printf 'sync-work-branch: %s\n' "$*" >&2; exit 1; }

prof=$(bash "$SCRIPT_DIR/remote-profile.sh" --root "$ROOT") || fail "no resolvable remote profile"
base=$(printf '%s\n' "$prof" | sed -n 's/^BASE=//p')
work=$(printf '%s\n' "$prof" | sed -n 's/^WORK=//p')

git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || fail "not a git repository"
git -C "$ROOT" show-ref --verify --quiet "refs/heads/$base" || fail "base branch '$base' not found"
git -C "$ROOT" show-ref --verify --quiet "refs/heads/$work" || fail "work branch '$work' not found"

[ -z "$(git -C "$ROOT" status --porcelain --untracked-files=no)" ] ||
  fail "working tree has uncommitted tracked changes; commit or stash before syncing"

base_before=$(git -C "$ROOT" rev-parse "$base")

git -C "$ROOT" checkout -q "$work" || fail "cannot checkout $work"
if ! git -C "$ROOT" -c user.email=sprint-loops@local -c user.name=sprint-loops \
      merge --no-edit "$base" >/dev/null 2>&1; then
  git -C "$ROOT" merge --abort 2>/dev/null || true
  fail "merge conflict bringing $base into $work; resolve manually"
fi

base_after=$(git -C "$ROOT" rev-parse "$base")
[ "$base_before" = "$base_after" ] || fail "internal error: $base changed during resync"

printf 'sync-work-branch: %s now contains %s (%s)\n' \
  "$work" "$base" "$(git -C "$ROOT" rev-parse --short "$work")"
