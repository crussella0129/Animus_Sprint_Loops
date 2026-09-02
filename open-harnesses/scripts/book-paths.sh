#!/usr/bin/env bash
# Shared, side-effect-free path and layout contract for Sprint Loops Book v2.
# Source this file after setting SPRINT_LOOP_PROJECT_ROOT (default: current dir).
# shellcheck disable=SC2034 # Public BOOK_*/LEGACY_* variables are consumed by callers.

BOOK_SCHEMA_VERSION=2
# The substrate contract version this bundle implements. A Book marker with no
# 'substrate-version' entry predates the stamp and is contract version 1.
BOOK_SUBSTRATE_CONTRACT_VERSION=3
BOOK_SPLIT_BRAIN_DIAGNOSTIC='split-brain state: writable Book and legacy Sprint Loops layouts coexist'
BOOK_LEGACY_ONLY_DIAGNOSTIC='legacy-only Sprint Loops layout detected; migrate to the v2 Book before writing state'
BOOK_UNINITIALIZED_DIAGNOSTIC='Sprint Loops Book is not initialized'
BOOK_MARKER_DIAGNOSTIC="invalid Sprint Loops Book marker: expected exactly one anchored 'schema-version: 2' entry"
BOOK_SUBSTRATE_VERSION_DIAGNOSTIC="invalid Sprint Loops substrate version: expected at most one anchored 'substrate-version: <positive integer>' entry"

book_join_root() {
  case "${SPRINT_LOOP_PROJECT_ROOT:-.}" in
    ''|.) printf '%s' "$1" ;;
    */) printf '%s%s' "${SPRINT_LOOP_PROJECT_ROOT}" "$1" ;;
    *) printf '%s/%s' "${SPRINT_LOOP_PROJECT_ROOT}" "$1" ;;
  esac
}

BOOK_ROOT=$(book_join_root docs)
BOOK_MARKER=$(book_join_root docs/.sprint-loop-book)
BOOK_README=$(book_join_root docs/README.md)
BOOK_SUMMARY=$(book_join_root docs/SUMMARY.md)
BOOK_INTENTS_DIR=$(book_join_root docs/intents)
BOOK_WORK_DIR=$(book_join_root docs/work)
BOOK_TASKS_FILE=$(book_join_root docs/work/tasks.md)
BOOK_COMPLETED_TASKS_FILE=$(book_join_root docs/work/completed-tasks.md)
BOOK_CONFIDENCE_FILE=$(book_join_root docs/work/confidence.txt)
BOOK_SPRINTS_DIR=$(book_join_root docs/sprints)
BOOK_HISTORY_DIR=$(book_join_root docs/history)
BOOK_LEGACY_DECISIONS_FILE=$(book_join_root docs/history/decisions-legacy.md)
BOOK_MIGRATION_PROVENANCE_FILE=$(book_join_root docs/history/migration-provenance.md)

LEGACY_SPRINTS_DIR=$(book_join_root sprints)
LEGACY_TASKS_DIR=$(book_join_root agent-tasks)
LEGACY_TASKS_FILE=$(book_join_root agent-tasks/agent-tasks.md)
LEGACY_COMPLETED_TASKS_FILE=$(book_join_root agent-tasks/completed-tasks.md)
LEGACY_DECISIONS_FILE=$(book_join_root decisions.md)
LEGACY_CONFIDENCE_FILE=$(book_join_root confidence.txt)

book_marker_is_v2() {
  [ -f "$BOOK_MARKER" ] || return 1
  awk '
    { sub(/\r$/, "") }
    /^[[:space:]]*schema-version:/ { count++ }
    /^schema-version:[[:space:]]*2[[:space:]]*$/ { valid++ }
    END { exit !(count == 1 && valid == 1) }
  ' "$BOOK_MARKER"
}

# Print the Book's substrate contract version. A marker carrying no
# 'substrate-version' entry is contract version 1 — "unstamped" is a real
# version, not a null. A malformed or repeated entry is refused rather than
# guessed, following the remote-profile marker precedent.
book_substrate_version() {
  [ -f "$BOOK_MARKER" ] || {
    printf '%s\n' "$BOOK_MARKER_DIAGNOSTIC" >&2
    return 1
  }
  book_substrate_version_value=$(awk '
    { sub(/\r$/, "") }
    /^[[:space:]]*substrate-version:/ { count++ }
    /^substrate-version:[[:space:]]*[1-9][0-9]*[[:space:]]*$/ {
      valid++
      value=$0
      sub(/^substrate-version:[[:space:]]*/, "", value)
      sub(/[[:space:]]*$/, "", value)
    }
    END {
      if (count == 0) { print 1; exit 0 }
      if (count == 1 && valid == 1) { print value; exit 0 }
      exit 1
    }
  ' "$BOOK_MARKER") || {
    printf '%s: %s\n' "$BOOK_SUBSTRATE_VERSION_DIAGNOSTIC" "$BOOK_MARKER" >&2
    return 1
  }
  printf '%s\n' "$book_substrate_version_value"
}

book_has_book_layout() {
  [ -e "$BOOK_MARKER" ] || [ -d "$BOOK_INTENTS_DIR" ] ||
    [ -d "$BOOK_WORK_DIR" ] || [ -d "$BOOK_SPRINTS_DIR" ]
}

book_has_legacy_layout() {
  [ -d "$LEGACY_SPRINTS_DIR" ] || [ -d "$LEGACY_TASKS_DIR" ] ||
    [ -e "$LEGACY_DECISIONS_FILE" ] || [ -e "$LEGACY_CONFIDENCE_FILE" ]
}

book_layout_state() {
  if book_has_book_layout; then
    if book_has_legacy_layout; then printf '%s\n' conflict; else printf '%s\n' book-only; fi
  elif book_has_legacy_layout; then
    printf '%s\n' legacy-only
  else
    printf '%s\n' none
  fi
}

book_assert_no_split_brain() {
  if [ "$(book_layout_state)" = conflict ]; then
    printf '%s\n' "$BOOK_SPLIT_BRAIN_DIAGNOSTIC" >&2
    return 1
  fi
}

book_require_v2_layout() {
  case "$(book_layout_state)" in
    conflict) printf '%s\n' "$BOOK_SPLIT_BRAIN_DIAGNOSTIC" >&2; return 1 ;;
    legacy-only) printf '%s\n' "$BOOK_LEGACY_ONLY_DIAGNOSTIC" >&2; return 1 ;;
    none) printf '%s\n' "$BOOK_UNINITIALIZED_DIAGNOSTIC" >&2; return 1 ;;
  esac
  if ! book_marker_is_v2; then
    printf '%s\n' "$BOOK_MARKER_DIAGNOSTIC" >&2
    return 1
  fi
  for book_required_dir in "$BOOK_INTENTS_DIR" "$BOOK_WORK_DIR" "$BOOK_SPRINTS_DIR"; do
    if [ ! -d "$book_required_dir" ]; then
      printf 'invalid Sprint Loops Book layout: missing directory %s\n' "$book_required_dir" >&2
      return 1
    fi
  done
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  book_layout_state
fi
