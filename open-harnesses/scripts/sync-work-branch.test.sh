#!/usr/bin/env bash
# Fixtures for sync-work-branch.sh — brings base into work, refuses dirty,
# writes only work.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC="$SCRIPT_DIR/sync-work-branch.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-sync.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM
pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

git_c() { git -C "$R" -c user.email=t@t -c user.name=t "$@"; }

make_repo() {  # <dir> — main ahead of dev by one commit; on dev
  R="$1"
  git init -q "$R"
  git -C "$R" checkout -q -b main
  printf 'v0\n' > "$R/file.txt"; git -C "$R" add file.txt; git_c commit -q -m base0
  git -C "$R" branch dev
  git_c commit -q --allow-empty -m base1
  git -C "$R" checkout -q dev
  mkdir -p "$R/docs/work"
  printf '# Remote Profile\n\n<!-- sprint-loop-remote-profile-v1 -->\n\n```\nprovider: github\nbase: main\nwork: dev\n```\n' \
    > "$R/docs/work/remote-profile.md"
}

# test_resync_brings_base_into_work
R="$TMP_ROOT/sync"; make_repo "$R"
main_head=$(git -C "$R" rev-parse main)
git -C "$R" merge-base --is-ancestor "$main_head" dev 2>/dev/null && die test_resync_brings_base_into_work 'dev already contains main (bad fixture)'
bash "$SYNC" --root "$R" >/dev/null 2>&1 || die test_resync_brings_base_into_work 'sync failed'
git -C "$R" merge-base --is-ancestor "$main_head" dev || die test_resync_brings_base_into_work 'dev does not contain main head after sync'
pass test_resync_brings_base_into_work

# test_resync_refuses_dirty
R="$TMP_ROOT/dirty"; make_repo "$R"
printf 'changed\n' > "$R/file.txt"   # modify a tracked file
dev_before=$(git -C "$R" rev-parse dev)
if bash "$SYNC" --root "$R" >/dev/null 2>"$R.err"; then die test_resync_refuses_dirty 'dirty tree accepted'; fi
grep -qi 'dirty\|uncommitted' "$R.err" || die test_resync_refuses_dirty 'no dirty diagnostic'
[ "$(git -C "$R" rev-parse dev)" = "$dev_before" ] || die test_resync_refuses_dirty 'dev changed on refusal'
pass test_resync_refuses_dirty

# test_resync_writes_only_work
R="$TMP_ROOT/onlywork"; make_repo "$R"
main_before=$(git -C "$R" rev-parse main)
bash "$SYNC" --root "$R" >/dev/null 2>&1 || die test_resync_writes_only_work 'sync failed'
[ "$(git -C "$R" rev-parse main)" = "$main_before" ] || die test_resync_writes_only_work 'base (main) was modified'
pass test_resync_writes_only_work

printf 'sync-work-branch selftest: all fixtures passed\n'
