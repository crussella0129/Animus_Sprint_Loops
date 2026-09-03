#!/usr/bin/env bash
# Fixtures for check-tracked.sh — the committed-evidence gate (sprint 18).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CT="$SCRIPT_DIR/check-tracked.sh"
INIT="$SCRIPT_DIR/init-sprint.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-tracked.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM
pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

# shellcheck source=book-paths.sh
. "$SCRIPT_DIR/book-paths.sh"

make_committed_book() {  # <dir>
  local d="$1"
  mkdir -p "$d"
  git init -q "$d"
  git -C "$d" config user.email sprint-loop@example.invalid
  git -C "$d" config user.name "Sprint Loop Test"
  ( cd "$d" && SPRINT_LOOP_PROJECT_ROOT=. SPRINT_MODEL=selftest bash "$INIT" >/dev/null )
  git -C "$d" add -A
  git -C "$d" commit -qm 'book'
}
run() { bash "$CT" --root "$1" 2>&1; }
succeeds() { bash "$CT" --root "$1" >/dev/null 2>&1; }

# test_tracked_clean_book_passes
C="$TMP_ROOT/clean"; make_committed_book "$C"
succeeds "$C" || die test_tracked_clean_book_passes "clean Book refused: $(run "$C")"
case "$(run "$C")" in *'fully committed'*) : ;; *) die test_tracked_clean_book_passes "unexpected output: $(run "$C")" ;; esac
pass test_tracked_clean_book_passes

# test_tracked_reports_untracked
U="$TMP_ROOT/untracked"; make_committed_book "$U"
printf 'draft\n' > "$U/docs/intents/INT-0009-uncommitted.md"
if succeeds "$U"; then die test_tracked_reports_untracked 'untracked Book file accepted'; fi
case "$(run "$U")" in *'INT-0009-uncommitted.md'*) : ;; *) die test_tracked_reports_untracked "path not named: $(run "$U")" ;; esac
pass test_tracked_reports_untracked

# test_tracked_reports_modified
M="$TMP_ROOT/modified"; make_committed_book "$M"
printf 'drifted\n' >> "$M/docs/work/tasks.md"
if succeeds "$M"; then die test_tracked_reports_modified 'modified Book file accepted'; fi
case "$(run "$M")" in *'work/tasks.md'*) : ;; *) die test_tracked_reports_modified "path not named: $(run "$M")" ;; esac
pass test_tracked_reports_modified

# test_tracked_reports_every_offender — one run gives the whole remedy.
E="$TMP_ROOT/every"; make_committed_book "$E"
printf 'draft\n' > "$E/docs/intents/INT-0009-uncommitted.md"
printf 'drifted\n' >> "$E/docs/work/tasks.md"
every_out=$(run "$E")
case "$every_out" in *'INT-0009-uncommitted.md'*) : ;; *) die test_tracked_reports_every_offender 'untracked offender missing' ;; esac
case "$every_out" in *'work/tasks.md'*) : ;; *) die test_tracked_reports_every_offender 'modified offender missing' ;; esac
pass test_tracked_reports_every_offender

# test_tracked_ignores_non_git — a project without version control has no
# tracked state, so the gate is inapplicable rather than failed.
N="$TMP_ROOT/nogit"; mkdir -p "$N"
( cd "$N" && SPRINT_LOOP_PROJECT_ROOT=. SPRINT_MODEL=selftest bash "$INIT" >/dev/null )
succeeds "$N" || die test_tracked_ignores_non_git "non-git project refused: $(run "$N")"
pass test_tracked_ignores_non_git

# test_tracked_ignores_non_book_changes — the gate is about the Book, not the
# working tree at large.
O="$TMP_ROOT/outside"; make_committed_book "$O"
printf 'unrelated\n' > "$O/scratch.txt"
succeeds "$O" || die test_tracked_ignores_non_book_changes "non-Book change refused: $(run "$O")"
pass test_tracked_ignores_non_book_changes

# test_older_stamp_reads_as_behind — a Book stamped by an earlier bundle is
# behind, not current, so version-gated behavior binds only after convergence.
#
# Asserted as a relationship rather than against a literal contract number: an
# earlier form of this fixture hardcoded the then-current version and broke the
# first time the contract was raised, failing for a reason that had nothing to
# do with the property it was written to protect.
V="$TMP_ROOT/version"; make_committed_book "$V"
printf 'schema-version: 2\nsubstrate-version: 2\n' > "$V/docs/.sprint-loop-book"
stamped=$( cd "$V" && SPRINT_LOOP_PROJECT_ROOT=. . "$SCRIPT_DIR/book-paths.sh" && book_substrate_version )
[ "$stamped" = 2 ] || die test_older_stamp_reads_as_behind "accessor read '$stamped', expected 2"
[ "$stamped" -lt "$BOOK_SUBSTRATE_CONTRACT_VERSION" ] ||
  die test_older_stamp_reads_as_behind "stamp $stamped is not behind the bundle's $BOOK_SUBSTRATE_CONTRACT_VERSION"
pass test_older_stamp_reads_as_behind

printf 'check-tracked selftest: all fixtures passed\n'
