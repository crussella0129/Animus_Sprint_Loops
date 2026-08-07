#!/usr/bin/env bash
# Idempotent Sprint 0 deploy: bring a project to substrate-complete.
# Creates only what is missing — Book scaffold + first sprint, remote profile,
# and base/work/(bump) branches — then verifies. Transactional: any failure or
# signal before commit rolls back every artifact this run created.
# Usage: deploy-substrate.sh [--root <dir>] [--provider p] [--base b] [--work w]
#                            [--bump b | --no-bump] [--merge-policy m]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT="${SPRINT_LOOP_PROJECT_ROOT:-.}"
PROVIDER=local-only; BASE=main; WORK=dev; BUMP=none; MERGE_POLICY=human-approve
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) SPRINT_LOOP_PROJECT_ROOT="$2"; shift 2 ;;
    --provider) PROVIDER="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --work) WORK="$2"; shift 2 ;;
    --bump) BUMP="$2"; shift 2 ;;
    --no-bump) BUMP=none; shift ;;
    --merge-policy) MERGE_POLICY="$2"; shift 2 ;;
    *) echo "deploy-substrate: unknown argument $1" >&2; exit 2 ;;
  esac
done
. "$SCRIPT_DIR/book-paths.sh"
ROOT="$SPRINT_LOOP_PROJECT_ROOT"

fail() { printf 'deploy-substrate: %s\n' "$*" >&2; exit 1; }

case "$(book_layout_state)" in
  legacy-only) fail "legacy layout present; migrate to the Book before deploy" ;;
  conflict) fail "$BOOK_SPLIT_BRAIN_DIAGNOSTIC" ;;
esac

PROFILE=$(book_join_root docs/work/remote-profile.md)

if [ "$(bash "$SCRIPT_DIR/check-substrate.sh" --root "$ROOT" 2>/dev/null)" = substrate-complete ]; then
  echo "deploy-substrate: already substrate-complete; nothing to do"
  exit 0
fi

CREATED_BOOK=0; CREATED_PROFILE=0; CREATED_SPRINT=""; CREATED_GITDIR=0
CREATED_BRANCHES=""; COMMITTED=0

rollback() {
  [ "$COMMITTED" -eq 1 ] && return 0
  for _b in $CREATED_BRANCHES; do git -C "$ROOT" branch -D "$_b" >/dev/null 2>&1 || true; done
  [ -n "$CREATED_SPRINT" ] && rm -rf "$CREATED_SPRINT"
  [ "$CREATED_PROFILE" -eq 1 ] && rm -f "$PROFILE"
  [ "$CREATED_BOOK" -eq 1 ] && rm -rf "$BOOK_ROOT"
  [ "$CREATED_GITDIR" -eq 1 ] && rm -rf "$ROOT/.git"
  return 0
}
trap 'rollback' EXIT
trap 'exit 130' HUP INT TERM

# Test seam: fail deterministically after a named step to exercise rollback.
maybe_fail() { [ "${DEPLOY_SUBSTRATE_FAIL_AFTER:-}" = "$1" ] && fail "injected failure after $1"; return 0; }

# 1. Book scaffold + first sprint.
if [ "$(book_layout_state)" = none ]; then
  ( cd "$ROOT" && SPRINT_LOOP_PROJECT_ROOT=. bash "$SCRIPT_DIR/init-sprint.sh" >/dev/null ) ||
    fail "book scaffold/init failed"
  CREATED_BOOK=1
elif ! ls -d "$BOOK_SPRINTS_DIR"/s* >/dev/null 2>&1; then
  ( cd "$ROOT" && SPRINT_LOOP_PROJECT_ROOT=. bash "$SCRIPT_DIR/init-sprint.sh" >/dev/null ) ||
    fail "first sprint init failed"
  CREATED_SPRINT=$(ls -d "$BOOK_SPRINTS_DIR"/s* 2>/dev/null | LC_ALL=C sort -V | tail -1)
fi
maybe_fail book

# 2. Remote profile.
if [ ! -f "$PROFILE" ]; then
  mkdir -p "$(dirname "$PROFILE")"
  {
    printf '# Remote Profile\n\n<!-- sprint-loop-remote-profile-v1 -->\n\n```\n'
    printf 'provider: %s\nbase: %s\nwork: %s\n' "$PROVIDER" "$BASE" "$WORK"
    [ "$BUMP" != none ] && printf 'bump: %s\n' "$BUMP"
    printf 'mergePolicy: %s\n```\n' "$MERGE_POLICY"
  } > "$PROFILE"
  CREATED_PROFILE=1
fi
prof=$(bash "$SCRIPT_DIR/remote-profile.sh" --root "$ROOT") || fail "invalid remote profile"
BASE=$(printf '%s\n' "$prof" | sed -n 's/^BASE=//p')
WORK=$(printf '%s\n' "$prof" | sed -n 's/^WORK=//p')
BUMP=$(printf '%s\n' "$prof" | sed -n 's/^BUMP=//p')
maybe_fail profile

# 3. Git repo + branches.
if ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$ROOT" init -q || fail "git init failed"
  CREATED_GITDIR=1
fi
if ! git -C "$ROOT" rev-parse -q --verify HEAD >/dev/null 2>&1; then
  git -C "$ROOT" add -A -- docs >/dev/null 2>&1 || true
  git -C "$ROOT" -c user.email=sprint-loops@local -c user.name=sprint-loops \
    commit -q --allow-empty -m "sprint-0: substrate" || fail "initial commit failed"
fi
branch_list="$BASE $WORK"
[ "$BUMP" != none ] && branch_list="$branch_list $BUMP"
# shellcheck disable=SC2086 # branch names are single tokens by construction.
for br in $branch_list; do
  if ! git -C "$ROOT" show-ref --verify --quiet "refs/heads/$br"; then
    git -C "$ROOT" branch "$br" HEAD || fail "creating branch $br failed"
    CREATED_BRANCHES="$CREATED_BRANCHES $br"
  fi
done
maybe_fail branches

# 4. Verify.
result=$(bash "$SCRIPT_DIR/check-substrate.sh" --root "$ROOT" 2>/dev/null) || true
[ "$result" = substrate-complete ] || fail "post-deploy verification failed: $result"

COMMITTED=1
trap - EXIT HUP INT TERM
printf 'deploy-substrate: substrate-complete (provider=%s base=%s work=%s bump=%s)\n' \
  "$PROVIDER" "$BASE" "$WORK" "$BUMP"
