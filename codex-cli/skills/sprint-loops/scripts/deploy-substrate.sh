#!/usr/bin/env bash
# Idempotent Sprint 0 deploy: bring a project to substrate-complete.
# Creates only what is missing — Book scaffold + first sprint, remote profile,
# and base/work branches — then verifies. Transactional: any failure or
# signal before commit rolls back every artifact this run created.
# Usage: deploy-substrate.sh [--root <dir>] [--provider p] [--base b] [--work w]
#                            [--merge-policy m]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT="${SPRINT_LOOP_PROJECT_ROOT:-.}"
PROVIDER=local-only; BASE=main; WORK=dev; MERGE_POLICY=human-approve
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) SPRINT_LOOP_PROJECT_ROOT="$2"; shift 2 ;;
    --provider) PROVIDER="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --work) WORK="$2"; shift 2 ;;
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

CREATED_BOOK=0; CREATED_PROFILE=0; CREATED_SPRINT=""; CREATED_GITDIR=0
CREATED_BRANCHES=""; CREATED_UPDATER=""; COMMITTED=0

rollback() {
  [ "$COMMITTED" -eq 1 ] && return 0
  for _b in $CREATED_BRANCHES; do git -C "$ROOT" branch -D "$_b" >/dev/null 2>&1 || true; done
  if [ -n "$CREATED_UPDATER" ]; then
    rm -f "$CREATED_UPDATER"
    rmdir "$(dirname "$CREATED_UPDATER")" 2>/dev/null || true
  fi
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
    printf '# Remote Profile\n\n<!-- sprint-loop-remote-profile-v2 -->\n\n```\n'
    printf 'provider: %s\nbase: %s\nwork: %s\n' "$PROVIDER" "$BASE" "$WORK"
    printf 'mergePolicy: %s\n```\n' "$MERGE_POLICY"
  } > "$PROFILE"
  CREATED_PROFILE=1
fi
prof=$(bash "$SCRIPT_DIR/remote-profile.sh" --root "$ROOT") || fail "invalid remote profile"
PROVIDER=$(printf '%s\n' "$prof" | sed -n 's/^PROVIDER=//p')
BASE=$(printf '%s\n' "$prof" | sed -n 's/^BASE=//p')
WORK=$(printf '%s\n' "$prof" | sed -n 's/^WORK=//p')
MERGE_POLICY=$(printf '%s\n' "$prof" | sed -n 's/^MERGEPOLICY=//p')
maybe_fail profile

# 2b. Dependency-updater config (create-if-absent, work-targeted).
# github -> Dependabot; gitlab/generic -> Renovate; local-only -> none. A fresh
# project has no manifests, so the config is a starter (github-actions / recommended).
case "$PROVIDER" in
  github)
    updater="$ROOT/.github/dependabot.yml"
    if [ ! -f "$updater" ]; then
      mkdir -p "$ROOT/.github"
      {
        printf '# Dependabot opens scheduled version-update PRs against the work branch.\n'
        printf '# Merge only at sprint boundaries when green; add ecosystems as the project grows.\n'
        printf 'version: 2\nupdates:\n'
        printf '  - package-ecosystem: "github-actions"\n    directory: "/"\n'
        printf '    schedule:\n      interval: "weekly"\n'
        printf '    target-branch: "%s"\n' "$WORK"
      } > "$updater"
      CREATED_UPDATER="$updater"
    fi ;;
  gitlab|generic)
    updater="$ROOT/renovate.json"
    if [ ! -f "$updater" ]; then
      {
        printf '{\n'
        printf '  "$schema": "https://docs.renovatebot.com/renovate-schema.json",\n'
        printf '  "extends": ["config:recommended"],\n'
        printf '  "baseBranchPatterns": ["%s"]\n' "$WORK"
        printf '}\n'
      } > "$updater"
      CREATED_UPDATER="$updater"
    fi ;;
esac
maybe_fail updater

# 3. Git repo + branches.
if ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$ROOT" init -q -b "$BASE" || fail "git init failed"
  CREATED_GITDIR=1
fi
if ! git -C "$ROOT" rev-parse -q --verify HEAD >/dev/null 2>&1; then
  git -C "$ROOT" add -A -- docs >/dev/null 2>&1 || true
  [ -n "$CREATED_UPDATER" ] && git -C "$ROOT" add -A -- "$CREATED_UPDATER" >/dev/null 2>&1 || true
  git -C "$ROOT" -c user.email=sprint-loops@local -c user.name=sprint-loops \
    commit -q --allow-empty -m "sprint-0: substrate" || fail "initial commit failed"
fi
branch_list="$BASE $WORK"
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
printf 'deploy-substrate: substrate-complete (provider=%s base=%s work=%s mergePolicy=%s)\n' \
  "$PROVIDER" "$BASE" "$WORK" "$MERGE_POLICY"
