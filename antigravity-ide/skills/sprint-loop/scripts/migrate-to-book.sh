#!/usr/bin/env bash
# Losslessly migrate a legacy Sprint Loops project into the canonical v2 Book.
# Run from the project root. The migration is staged and verified before the
# legacy authority paths are moved; caught failures restore the original tree.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# A caller-supplied root must never redirect migration outside the current
# project. check-book.sh accepts an override; this mutating helper intentionally
# does not.
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT=.
. "$SCRIPT_DIR/book-paths.sh"

fail() {
  printf 'migrate-to-book: %s\n' "$*" >&2
  exit 1
}

PROJECT_ROOT=$(pwd -P) || fail 'cannot resolve the physical project root'
TXN="$PROJECT_ROOT/.sprint-loop-migration"
STAGE="$TXN/stage"
BACKUP="$TXN/backup"
SOURCE_MANIFEST="$TXN/legacy-manifest.tsv"
BACKUP_MANIFEST="$TXN/legacy-manifest.backup.tsv"
EXISTING_DOCS_MANIFEST="$TXN/existing-docs-manifest.tsv"
ROLLBACK_DOCS_MANIFEST="$TXN/rollback-docs-manifest.tsv"
CURRENT_DOCS_MANIFEST="$TXN/current-docs-manifest.tsv"
GITIGNORE_BASELINE="$TXN/gitignore-baseline.tsv"
TAB=$(printf '\t')

case "$PROJECT_ROOT" in
  *$'\n'*|*$'\r'*|*$'\t'*)
    fail 'unsafe project root: control characters are not supported' ;;
esac

path_is_contained() {
  case "$1" in
    "$PROJECT_ROOT"|"$PROJECT_ROOT"/*) return 0 ;;
    *) return 1 ;;
  esac
}

assert_no_control_names() {
  control_root=$1
  while IFS= read -r -d '' control_path; do
    case "$control_path" in
      *$'\n'*|*$'\r'*|*$'\t'*)
        fail "unsafe migration path: control characters are not supported: $control_path" ;;
    esac
  done < <(find "$control_root" -print0)
}

assert_tree_safe() {
  safe_path=$1
  safe_kind=$2

  [ ! -L "$safe_path" ] || fail "unsafe migration path: symlink or alias: $safe_path"
  case "$safe_kind" in
    directory) [ -d "$safe_path" ] || fail "unsafe migration path: expected directory: $safe_path" ;;
    file) [ -f "$safe_path" ] || fail "unsafe migration path: expected regular file: $safe_path" ;;
    *) fail "internal error: unsupported safety kind $safe_kind" ;;
  esac

  assert_no_control_names "$safe_path"

  unsafe_link=$(find "$safe_path" -type l -print 2>/dev/null || true)
  [ -z "$unsafe_link" ] || fail "unsafe migration path: symlink or alias beneath $safe_path: $unsafe_link"

  unsafe_type=$(find "$safe_path" ! -type d ! -type f -print 2>/dev/null || true)
  [ -z "$unsafe_type" ] || fail "unsafe migration path: unsupported filesystem node beneath $safe_path: $unsafe_type"

  # Hard-linked regular files are aliases: changing or removing one pathname
  # can leave another writable authority outside the migration inventory.
  unsafe_hardlink=$(find "$safe_path" -type f -links +1 -print 2>/dev/null || true)
  [ -z "$unsafe_hardlink" ] || fail "unsafe migration path: hard-linked file beneath $safe_path: $unsafe_hardlink"

  if [ "$safe_kind" = directory ]; then
    while IFS= read -r safe_dir; do
      safe_actual=$(CDPATH='' cd -P "$safe_dir" 2>/dev/null && pwd -P) ||
        fail "unsafe migration path: cannot resolve directory $safe_dir"
      case "$safe_dir" in
        .) safe_expected=$PROJECT_ROOT ;;
        "$PROJECT_ROOT"|"$PROJECT_ROOT"/*) safe_expected=$safe_dir ;;
        *) safe_expected="$PROJECT_ROOT/$safe_dir" ;;
      esac
      path_is_contained "$safe_actual" || fail "unsafe migration path escapes project root: $safe_dir"
      [ "$safe_actual" = "$safe_expected" ] ||
        fail "unsafe migration path traverses an alias: $safe_dir -> $safe_actual"
    done < <(find "$safe_path" -type d -print | LC_ALL=C sort)
  else
    safe_parent=${safe_path%/*}
    [ "$safe_parent" != "$safe_path" ] || safe_parent=.
    safe_parent_actual=$(CDPATH='' cd -P "$safe_parent" 2>/dev/null && pwd -P) ||
      fail "unsafe migration path: cannot resolve parent of $safe_path"
    case "$safe_parent" in
      .) safe_parent_expected=$PROJECT_ROOT ;;
      "$PROJECT_ROOT"|"$PROJECT_ROOT"/*) safe_parent_expected=$safe_parent ;;
      *) safe_parent_expected="$PROJECT_ROOT/$safe_parent" ;;
    esac
    path_is_contained "$safe_parent_actual" || fail "unsafe migration path escapes project root: $safe_path"
    [ "$safe_parent_actual" = "$safe_parent_expected" ] ||
      fail "unsafe migration path traverses an alias: $safe_path"
  fi
}

assert_optional_safe() {
  optional_path=$1
  optional_kind=$2
  if [ -L "$optional_path" ]; then
    fail "unsafe migration path: symlink or alias: $optional_path"
  elif [ -e "$optional_path" ]; then
    assert_tree_safe "$optional_path" "$optional_kind"
  fi
}

assert_gitignore_marker_shape() {
  marker_file=$1
  [ -f "$marker_file" ] || return 0
  if ! awk '
    {
      line=$0
      sub(/\r$/, "", line)
      if (line == "# >>> sprint-loops >>>") {
        starts++
        if (inside) bad=1
        inside=1
      } else if (line == "# <<< sprint-loops <<<") {
        ends++
        if (!inside) bad=1
        inside=0
      }
    }
    END { exit !(!bad && !inside && starts <= 1 && ends == starts) }
  ' "$marker_file"; then
    fail "unsafe .gitignore: malformed or duplicate sprint-loops marker block in $marker_file"
  fi
}

gitignore_without_owned_block() {
  awk '
    {
      line=$0
      sub(/\r$/, "", line)
      if (line == "# >>> sprint-loops >>>") { inside=1; next }
      if (line == "# <<< sprint-loops <<<") { inside=0; next }
      if (!inside) print
    }
  ' "$1"
}

hash_file() {
  case "$HASH_TOOL" in
    sha256sum) sha256sum "$1" | awk '{ print $1 }' ;;
    shasum) shasum -a 256 "$1" | awk '{ print $1 }' ;;
    *) fail "internal error: unsupported hash tool $HASH_TOOL" ;;
  esac
}

manifest_row() {
  row_type=$1
  row_source=$2
  row_target=$3
  if [ "$row_type" = F ]; then row_hash=$(hash_file "$row_source"); else row_hash=-; fi
  printf '%s\t%s\t%s\t%s\n' "$row_type" "$row_hash" "$row_source" "$row_target"
}

append_tree_mapping() {
  mapping_source_root=$1
  mapping_target_root=$2
  mapping_kind=$3
  find "$mapping_source_root" -print | LC_ALL=C sort |
    while IFS= read -r mapping_source; do
      if [ -d "$mapping_source" ]; then mapping_type=D; else mapping_type=F; fi
      if [ "$mapping_source" = "$mapping_source_root" ]; then
        mapping_target=$mapping_target_root
      else
        mapping_rel=${mapping_source#"$mapping_source_root"/}
        mapping_target="$mapping_target_root/$mapping_rel"
      fi
      if [ "$mapping_kind" = tasks ]; then
        case "$mapping_source" in
          "$LEGACY_TASKS_FILE") mapping_target=$BOOK_TASKS_FILE ;;
          "$LEGACY_COMPLETED_TASKS_FILE") mapping_target=$BOOK_COMPLETED_TASKS_FILE ;;
        esac
      fi
      manifest_row "$mapping_type" "$mapping_source" "$mapping_target"
    done
}

append_physical_tree_mapping() {
  physical_root=$1
  logical_root=$2
  physical_target_root=$3
  physical_kind=$4
  find "$physical_root" -print | LC_ALL=C sort |
    while IFS= read -r physical_source; do
      if [ -d "$physical_source" ]; then physical_type=D; else physical_type=F; fi
      if [ "$physical_source" = "$physical_root" ]; then
        logical_source=$logical_root
        physical_target=$physical_target_root
      else
        physical_rel=${physical_source#"$physical_root"/}
        logical_source="$logical_root/$physical_rel"
        physical_target="$physical_target_root/$physical_rel"
      fi
      if [ "$physical_kind" = tasks ]; then
        case "$logical_source" in
          "$LEGACY_TASKS_FILE") physical_target=$BOOK_TASKS_FILE ;;
          "$LEGACY_COMPLETED_TASKS_FILE") physical_target=$BOOK_COMPLETED_TASKS_FILE ;;
        esac
      fi
      if [ "$physical_type" = F ]; then
        physical_hash=$(hash_file "$physical_source")
      else
        physical_hash=-
      fi
      printf '%s\t%s\t%s\t%s\n' \
        "$physical_type" "$physical_hash" "$logical_source" "$physical_target"
    done
}

write_source_manifest() {
  : > "$SOURCE_MANIFEST"
  if [ -d "$LEGACY_SPRINTS_DIR" ]; then
    append_tree_mapping "$LEGACY_SPRINTS_DIR" "$BOOK_SPRINTS_DIR" normal >> "$SOURCE_MANIFEST"
  fi
  if [ -d "$LEGACY_TASKS_DIR" ]; then
    append_tree_mapping "$LEGACY_TASKS_DIR" "$BOOK_WORK_DIR" tasks >> "$SOURCE_MANIFEST"
  fi
  if [ -f "$LEGACY_DECISIONS_FILE" ]; then
    manifest_row F "$LEGACY_DECISIONS_FILE" "$BOOK_LEGACY_DECISIONS_FILE" >> "$SOURCE_MANIFEST"
  fi
  if [ -f "$LEGACY_CONFIDENCE_FILE" ]; then
    manifest_row F "$LEGACY_CONFIDENCE_FILE" "$BOOK_CONFIDENCE_FILE" >> "$SOURCE_MANIFEST"
  fi
  LC_ALL=C sort "$SOURCE_MANIFEST" > "$SOURCE_MANIFEST.sorted"
  mv "$SOURCE_MANIFEST.sorted" "$SOURCE_MANIFEST"

  duplicate_target=$(cut -f4 "$SOURCE_MANIFEST" | LC_ALL=C sort | uniq -d | sed -n '1p')
  [ -z "$duplicate_target" ] || fail "legacy paths map to the same Book target: $duplicate_target"
}

write_existing_docs_manifest() {
  : > "$EXISTING_DOCS_MANIFEST"
  [ -d "$BOOK_ROOT" ] || return 0
  find "$BOOK_ROOT" -print | LC_ALL=C sort |
    while IFS= read -r docs_source; do
      # The scaffold may append Book navigation to these two reader-facing
      # files. Their original bytes are checked as an exact prefix separately.
      case "$docs_source" in
        "$BOOK_README"|"$BOOK_SUMMARY") continue ;;
      esac
      if [ -d "$docs_source" ]; then docs_type=D; else docs_type=F; fi
      manifest_row "$docs_type" "$docs_source" "$docs_source"
    done >> "$EXISTING_DOCS_MANIFEST"
}

write_docs_manifest() {
  docs_manifest_path=$1
  docs_physical_root=$2
  : > "$docs_manifest_path"
  if [ -d "$docs_physical_root" ]; then
    append_physical_tree_mapping "$docs_physical_root" "$BOOK_ROOT" "$BOOK_ROOT" normal > "$docs_manifest_path"
  fi
  LC_ALL=C sort "$docs_manifest_path" > "$docs_manifest_path.sorted"
  mv "$docs_manifest_path.sorted" "$docs_manifest_path"
}

write_gitignore_baseline() {
  if [ -f .gitignore ]; then
    printf 'present\t%s\n' "$(hash_file .gitignore)" > "$GITIGNORE_BASELINE"
  else
    printf 'absent\t-\n' > "$GITIGNORE_BASELINE"
  fi
}

gitignore_matches_baseline() {
  IFS="$TAB" read -r gitignore_state gitignore_hash < "$GITIGNORE_BASELINE"
  case "$gitignore_state" in
    present)
      [ -f .gitignore ] &&
        [ "$(hash_file .gitignore)" = "$gitignore_hash" ]
      ;;
    absent) [ ! -e .gitignore ] && [ ! -L .gitignore ] ;;
    *) return 1 ;;
  esac
}

write_backup_manifest() {
  : > "$BACKUP_MANIFEST"
  if [ -d "$BACKUP/sprints" ]; then
    append_physical_tree_mapping "$BACKUP/sprints" "$LEGACY_SPRINTS_DIR" "$BOOK_SPRINTS_DIR" normal >> "$BACKUP_MANIFEST"
  fi
  if [ -d "$BACKUP/agent-tasks" ]; then
    append_physical_tree_mapping "$BACKUP/agent-tasks" "$LEGACY_TASKS_DIR" "$BOOK_WORK_DIR" tasks >> "$BACKUP_MANIFEST"
  fi
  if [ -f "$BACKUP/decisions.md" ]; then
    printf 'F\t%s\t%s\t%s\n' "$(hash_file "$BACKUP/decisions.md")" \
      "$LEGACY_DECISIONS_FILE" "$BOOK_LEGACY_DECISIONS_FILE" >> "$BACKUP_MANIFEST"
  fi
  if [ -f "$BACKUP/confidence.txt" ]; then
    printf 'F\t%s\t%s\t%s\n' "$(hash_file "$BACKUP/confidence.txt")" \
      "$LEGACY_CONFIDENCE_FILE" "$BOOK_CONFIDENCE_FILE" >> "$BACKUP_MANIFEST"
  fi
  LC_ALL=C sort "$BACKUP_MANIFEST" > "$BACKUP_MANIFEST.sorted"
  mv "$BACKUP_MANIFEST.sorted" "$BACKUP_MANIFEST"
}

backup_gitignore_matches_baseline() {
  IFS="$TAB" read -r gitignore_state gitignore_hash < "$GITIGNORE_BASELINE"
  case "$gitignore_state" in
    present)
      [ -f "$BACKUP/.gitignore" ] &&
        [ "$(hash_file "$BACKUP/.gitignore")" = "$gitignore_hash" ]
      ;;
    absent) [ ! -e "$BACKUP/.gitignore" ] && [ ! -L "$BACKUP/.gitignore" ] ;;
    *) return 1 ;;
  esac
}

verify_manifest_sources() {
  verify_manifest=$1
  while IFS="$TAB" read -r verify_type verify_hash verify_source _verify_target; do
    [ -n "$verify_type" ] || continue
    case "$verify_type" in
      D) [ -d "$verify_source" ] || return 1 ;;
      F)
        [ -f "$verify_source" ] || return 1
        [ "$(hash_file "$verify_source")" = "$verify_hash" ] || return 1
        ;;
      *) return 1 ;;
    esac
  done < "$verify_manifest"
}

verify_manifest_targets() {
  verify_manifest=$1
  verify_base=$2
  while IFS="$TAB" read -r verify_type verify_hash _verify_source verify_target; do
    [ -n "$verify_type" ] || continue
    verify_path="$verify_base/$verify_target"
    case "$verify_type" in
      D) [ -d "$verify_path" ] || return 1 ;;
      F)
        [ -f "$verify_path" ] || return 1
        [ "$(hash_file "$verify_path")" = "$verify_hash" ] || return 1
        ;;
      *) return 1 ;;
    esac
  done < "$verify_manifest"
}

assert_original_prefix() {
  prefix_original=$1
  prefix_candidate=$2
  [ -f "$prefix_original" ] || return 0
  [ -f "$prefix_candidate" ] || fail "Book scaffold discarded existing file: $prefix_original"
  prefix_size=$(wc -c < "$prefix_original" | tr -d '[:space:]')
  dd if="$prefix_candidate" bs=1 count="$prefix_size" 2>/dev/null |
    cmp -s "$prefix_original" - || fail "Book scaffold rewrote existing content in $prefix_original"
}

legacy_current_sprint() {
  legacy_n=-1
  for legacy_dir in "$LEGACY_SPRINTS_DIR"/s*/; do
    [ -d "$legacy_dir" ] || continue
    legacy_base=${legacy_dir#"$LEGACY_SPRINTS_DIR"/s}
    legacy_base=${legacy_base%/}
    case "$legacy_base" in ''|*[!0-9]*) continue ;; esac
    if [ "$legacy_base" -gt "$legacy_n" ]; then legacy_n=$legacy_base; fi
  done
  printf '%s\n' "$legacy_n"
}

validate_stage_gitignore() {
  stage_ignore="$STAGE/.gitignore"
  [ -f "$stage_ignore" ] || fail 'Book scaffold did not create .gitignore'
  assert_gitignore_marker_shape "$stage_ignore"
  marker_starts=$(awk '{ sub(/\r$/, "") } $0 == "# >>> sprint-loops >>>" { n++ } END { print n+0 }' "$stage_ignore")
  [ "$marker_starts" -eq 1 ] || fail 'Book scaffold must produce exactly one sprint-loops .gitignore block'
  if awk '{ sub(/\r$/, "") } $0 == "sprints/" { found=1 } END { exit !found }' "$stage_ignore"; then
    fail "unsafe .gitignore rule 'sprints/' would also ignore docs/sprints/"
  fi

  probe_name=".sprint-loop-ignore-probe.$$"
  while IFS= read -r probe_dir; do
    [ ! -e "$probe_dir/$probe_name" ] && [ ! -L "$probe_dir/$probe_name" ] ||
      fail "staged Book already contains reserved ignore probe: $probe_dir/$probe_name"
    : > "$probe_dir/$probe_name"
  done < <(find "$STAGE/$BOOK_ROOT" -type d -print | LC_ALL=C sort)

  git -C "$STAGE" init -q
  while IFS= read -r probe_absolute; do
    probe_path=${probe_absolute#"$STAGE"/}
    ignore_rc=0
    git -C "$STAGE" -c core.excludesFile=/dev/null check-ignore -q --no-index \
      "$probe_path" || ignore_rc=$?
    case "$ignore_rc" in
      0) fail "Book path remains ignored after .gitignore migration: $probe_path" ;;
      1) : ;;
      *) fail "git check-ignore could not validate the staged Book path: $probe_path" ;;
    esac
  done < <(find "$STAGE/$BOOK_ROOT" -print | LC_ALL=C sort)
  while IFS= read -r probe_file; do
    rm -f "$probe_file"
  done < <(find "$STAGE/$BOOK_ROOT" -type f -name "$probe_name" -print)
  rm -rf "$STAGE/.git"
}

write_provenance() {
  provenance_path="$STAGE/$BOOK_MIGRATION_PROVENANCE_FILE"
  mkdir -p "$(dirname "$provenance_path")"
  provenance_timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  {
    printf '# Legacy Sprint Loops Migration Provenance\n\n'
    printf '<!-- sprint-loop-migration-v2 -->\n\n'
    printf -- '- **Book schema version:** %s\n' "$BOOK_SCHEMA_VERSION"
    printf -- '- **Migrated at:** %s\n' "$provenance_timestamp"
    printf -- '- **Authority:** Historical provenance only. The `docs/` Book is the sole writable Sprint Loops authority.\n\n'
    printf '## Path mappings\n\n'
    printf -- '- `sprints/` -> `docs/sprints/`\n'
    printf -- '- `agent-tasks/agent-tasks.md` -> `docs/work/tasks.md`\n'
    printf -- '- `agent-tasks/completed-tasks.md` -> `docs/work/completed-tasks.md`\n'
    printf -- '- Other `agent-tasks/` content -> the same relative path under `docs/work/`\n'
    printf -- '- `confidence.txt` -> `docs/work/confidence.txt`\n'
    printf -- '- `decisions.md` -> `docs/history/decisions-legacy.md` (non-authoritative history)\n\n'
    printf '## Content inventory\n\n'
    printf 'Each indented row is `type<TAB>sha256-or--<TAB>legacy-path<TAB>Book-path`.\n\n'
    sed 's/^/    /' "$SOURCE_MANIFEST"
  } > "$provenance_path"
}

cleanup_transaction() {
  case "$TXN" in
    "$PROJECT_ROOT/.sprint-loop-migration") rm -rf "$TXN" ;;
    *) printf 'migrate-to-book: refusing unsafe transaction cleanup: %s\n' "$TXN" >&2; return 1 ;;
  esac
}

CUTOVER_STARTED=0
COMMITTED=0
DOCS_BACKED_UP=0
DOCS_INSTALLED=0
GITIGNORE_BACKED_UP=0
GITIGNORE_INSTALLED=0
SPRINTS_BACKED_UP=0
TASKS_BACKED_UP=0
DECISIONS_BACKED_UP=0
CONFIDENCE_BACKED_UP=0

path_exists_or_link() {
  [ -e "$1" ] || [ -L "$1" ]
}

restore_backup_path() {
  restore_source=$1
  restore_target=$2
  if path_exists_or_link "$restore_source"; then
    if path_exists_or_link "$restore_target"; then
      rollback_failed=1
      return
    fi
    mv "$restore_source" "$restore_target" 2>/dev/null || rollback_failed=1
  elif ! path_exists_or_link "$restore_target"; then
    rollback_failed=1
  fi
}

rollback_cutover() {
  rollback_failed=0
  mkdir -p "$TXN/failed-install" 2>/dev/null || rollback_failed=1

  if [ "$GITIGNORE_INSTALLED" -eq 1 ] && [ -e .gitignore ]; then
    mv .gitignore "$TXN/failed-install/.gitignore" 2>/dev/null || rollback_failed=1
  fi
  if [ "$GITIGNORE_BACKED_UP" -eq 1 ]; then
    restore_backup_path "$BACKUP/.gitignore" .gitignore
  fi
  if [ "$DOCS_INSTALLED" -eq 1 ] && [ -e "$BOOK_ROOT" ]; then
    mv "$BOOK_ROOT" "$TXN/failed-install/docs" 2>/dev/null || rollback_failed=1
  fi
  if [ "$DOCS_BACKED_UP" -eq 1 ]; then
    restore_backup_path "$BACKUP/docs" "$BOOK_ROOT"
  fi
  if [ "$CONFIDENCE_BACKED_UP" -eq 1 ]; then
    restore_backup_path "$BACKUP/confidence.txt" "$LEGACY_CONFIDENCE_FILE"
  fi
  if [ "$DECISIONS_BACKED_UP" -eq 1 ]; then
    restore_backup_path "$BACKUP/decisions.md" "$LEGACY_DECISIONS_FILE"
  fi
  if [ "$TASKS_BACKED_UP" -eq 1 ]; then
    restore_backup_path "$BACKUP/agent-tasks" "$LEGACY_TASKS_DIR"
  fi
  if [ "$SPRINTS_BACKED_UP" -eq 1 ]; then
    restore_backup_path "$BACKUP/sprints" "$LEGACY_SPRINTS_DIR"
  fi

  if [ "$rollback_failed" -eq 0 ] && ! verify_manifest_sources "$SOURCE_MANIFEST"; then
    rollback_failed=1
  fi
  if [ "$rollback_failed" -eq 0 ]; then
    write_docs_manifest "$CURRENT_DOCS_MANIFEST" "$BOOK_ROOT"
    cmp -s "$ROLLBACK_DOCS_MANIFEST" "$CURRENT_DOCS_MANIFEST" || rollback_failed=1
  fi
  if [ "$rollback_failed" -eq 0 ] && ! gitignore_matches_baseline; then
    rollback_failed=1
  fi
  if [ "$rollback_failed" -ne 0 ]; then
    printf 'migrate-to-book: rollback could not be verified; transaction retained at %s\n' "$TXN" >&2
    return 1
  fi
  return 0
}

on_exit() {
  exit_status=$?
  trap - EXIT HUP INT TERM
  if [ "$COMMITTED" -eq 0 ]; then
    if [ "$CUTOVER_STARTED" -eq 1 ]; then
      if ! rollback_cutover; then exit 2; fi
    fi
    cleanup_transaction || exit 2
  fi
  exit "$exit_status"
}

on_signal() {
  exit 130
}

# Safety checks precede classification so a symlinked docs/ or legacy root can
# never make layout detection read outside the project.
[ ! -L "$TXN" ] || fail "unsafe migration transaction path: $TXN"
[ ! -e "$TXN" ] || fail "incomplete migration transaction exists at $TXN; recover or remove it before retrying"
assert_optional_safe "$BOOK_ROOT" directory
assert_optional_safe .gitignore file
assert_optional_safe "$LEGACY_SPRINTS_DIR" directory
assert_optional_safe "$LEGACY_TASKS_DIR" directory
assert_optional_safe "$LEGACY_DECISIONS_FILE" file
assert_optional_safe "$LEGACY_CONFIDENCE_FILE" file
assert_gitignore_marker_shape .gitignore

case "$(book_layout_state)" in
  conflict) fail "$BOOK_SPLIT_BRAIN_DIAGNOSTIC" ;;
  book-only)
    book_require_v2_layout || exit 1
    bash "$SCRIPT_DIR/check-book.sh" . >/dev/null
    printf 'migrate-to-book: Book v2 already authoritative; no migration needed\n'
    exit 0
    ;;
  none)
    printf 'migrate-to-book: no legacy Sprint Loops state found; no migration needed\n'
    exit 0
    ;;
  legacy-only) : ;;
  *) fail 'unknown Sprint Loops layout state' ;;
esac

if [ -e "$BOOK_LEGACY_DECISIONS_FILE" ] || [ -L "$BOOK_LEGACY_DECISIONS_FILE" ]; then
  fail "Book migration target already exists: $BOOK_LEGACY_DECISIONS_FILE"
fi
if [ -e "$BOOK_MIGRATION_PROVENANCE_FILE" ] || [ -L "$BOOK_MIGRATION_PROVENANCE_FILE" ]; then
  fail "Book migration target already exists: $BOOK_MIGRATION_PROVENANCE_FILE"
fi
if [ -d "$LEGACY_TASKS_DIR" ]; then
  if [ -e "$LEGACY_TASKS_FILE" ] && [ -e "$LEGACY_TASKS_DIR/tasks.md" ]; then
    fail 'legacy agent-tasks.md and tasks.md collide at docs/work/tasks.md'
  fi
  if [ -e "$LEGACY_CONFIDENCE_FILE" ] && [ -e "$LEGACY_TASKS_DIR/confidence.txt" ]; then
    fail 'legacy confidence files collide at docs/work/confidence.txt'
  fi
fi

if command -v sha256sum >/dev/null 2>&1; then
  HASH_TOOL=sha256sum
elif command -v shasum >/dev/null 2>&1; then
  HASH_TOOL=shasum
else
  fail 'SHA-256 tool required: install sha256sum or shasum'
fi
command -v git >/dev/null 2>&1 || fail 'git is required to validate that the Book remains tracked'

mkdir "$TXN" || fail "cannot acquire migration transaction at $TXN"
trap on_exit EXIT
trap on_signal HUP INT TERM
mkdir -p "$STAGE" "$BACKUP"

assert_optional_safe "$BOOK_ROOT" directory
assert_optional_safe .gitignore file
assert_optional_safe "$LEGACY_SPRINTS_DIR" directory
assert_optional_safe "$LEGACY_TASKS_DIR" directory
assert_optional_safe "$LEGACY_DECISIONS_FILE" file
assert_optional_safe "$LEGACY_CONFIDENCE_FILE" file
write_source_manifest
write_existing_docs_manifest
write_docs_manifest "$ROLLBACK_DOCS_MANIFEST" "$BOOK_ROOT"
write_gitignore_baseline
LEGACY_SPRINT_NUMBER=$(legacy_current_sprint)

if [ -d "$BOOK_ROOT" ]; then cp -pR "$BOOK_ROOT" "$STAGE/docs"; fi
if [ -f .gitignore ]; then cp -p .gitignore "$STAGE/.gitignore"; fi

# T-111 owns the exact scaffold bytes. Running against the isolated stage
# reuses them without creating a sprint or observing the live legacy layout.
(
  cd "$STAGE"
  SPRINT_LOOP_PROJECT_ROOT=. bash "$SCRIPT_DIR/init-sprint.sh" --scaffold-only >/dev/null
)

if [ -f .gitignore ]; then
  gitignore_without_owned_block .gitignore > "$TXN/gitignore-outside.before"
  gitignore_without_owned_block "$STAGE/.gitignore" > "$TXN/gitignore-outside.after"
  cmp -s "$TXN/gitignore-outside.before" "$TXN/gitignore-outside.after" ||
    fail '.gitignore migration changed project-owned content outside the sprint-loops marker'
fi

assert_original_prefix "$BOOK_README" "$STAGE/$BOOK_README"
assert_original_prefix "$BOOK_SUMMARY" "$STAGE/$BOOK_SUMMARY"

if [ -d "$LEGACY_SPRINTS_DIR" ]; then
  mv "$STAGE/$BOOK_SPRINTS_DIR" "$TXN/scaffold-sprints"
  cp -pR "$LEGACY_SPRINTS_DIR" "$STAGE/$BOOK_SPRINTS_DIR"
fi

mv "$STAGE/$BOOK_WORK_DIR" "$TXN/scaffold-work"
if [ -d "$LEGACY_TASKS_DIR" ]; then
  cp -pR "$LEGACY_TASKS_DIR" "$TXN/work"
else
  mkdir "$TXN/work"
fi
if [ -f "$TXN/work/agent-tasks.md" ]; then mv "$TXN/work/agent-tasks.md" "$TXN/work/tasks.md"; fi
[ -f "$TXN/work/tasks.md" ] || cp -p "$TXN/scaffold-work/tasks.md" "$TXN/work/tasks.md"
[ -f "$TXN/work/completed-tasks.md" ] ||
  cp -p "$TXN/scaffold-work/completed-tasks.md" "$TXN/work/completed-tasks.md"
if [ -f "$LEGACY_CONFIDENCE_FILE" ]; then cp -p "$LEGACY_CONFIDENCE_FILE" "$TXN/work/confidence.txt"; fi
mv "$TXN/work" "$STAGE/$BOOK_WORK_DIR"

mkdir -p "$STAGE/$BOOK_HISTORY_DIR"
if [ -f "$LEGACY_DECISIONS_FILE" ]; then
  cp -p "$LEGACY_DECISIONS_FILE" "$STAGE/$BOOK_LEGACY_DECISIONS_FILE"
fi
write_provenance

# The first scaffold pass ran before legacy sprint history existed in the
# stage. Refresh navigation now that every migrated sN is present; this mode is
# idempotent and never creates a new sprint.
(
  cd "$STAGE"
  SPRINT_LOOP_PROJECT_ROOT=. bash "$SCRIPT_DIR/init-sprint.sh" --scaffold-only >/dev/null
)

verify_manifest_targets "$SOURCE_MANIFEST" "$STAGE" || fail 'staged Book does not match the legacy path-and-hash inventory'
verify_manifest_targets "$EXISTING_DOCS_MANIFEST" "$STAGE" || fail 'staged Book did not preserve existing docs content'
assert_tree_safe "$STAGE/$BOOK_ROOT" directory
assert_tree_safe "$STAGE/.gitignore" file
validate_stage_gitignore
bash "$SCRIPT_DIR/check-book.sh" "$STAGE" >/dev/null

STAGED_SPRINT_NUMBER=$(cd "$STAGE" && bash "$SCRIPT_DIR/current-sprint.sh")
[ "$STAGED_SPRINT_NUMBER" = "$LEGACY_SPRINT_NUMBER" ] ||
  fail "routing changed current sprint: legacy=$LEGACY_SPRINT_NUMBER staged=$STAGED_SPRINT_NUMBER"
STAGED_PHASE=$(cd "$STAGE" && bash "$SCRIPT_DIR/current-phase.sh")
case "$STAGED_PHASE" in
  uninitialized|research|plan|build|test|loop|ready-for-next-sprint) : ;;
  *) fail "staged Book produced invalid routing phase: $STAGED_PHASE" ;;
esac

# Detect additions and removals as well as edits after staging and before the
# first source mutation by rebuilding the complete path/type/hash inventory.
cp -p "$SOURCE_MANIFEST" "$TXN/legacy-manifest.initial.tsv"
write_source_manifest
cmp -s "$SOURCE_MANIFEST" "$TXN/legacy-manifest.initial.tsv" ||
  fail 'legacy state changed while migration was being staged; retry with no concurrent writers'
write_docs_manifest "$CURRENT_DOCS_MANIFEST" "$BOOK_ROOT"
cmp -s "$ROLLBACK_DOCS_MANIFEST" "$CURRENT_DOCS_MANIFEST" ||
  fail 'existing docs changed while migration was being staged; retry with no concurrent writers'
gitignore_matches_baseline ||
  fail '.gitignore changed while migration was being staged; retry with no concurrent writers'
assert_tree_safe "$STAGE/$BOOK_ROOT" directory
assert_tree_safe "$STAGE/.gitignore" file

CUTOVER_STARTED=1
if [ -d "$BOOK_ROOT" ]; then
  DOCS_BACKED_UP=1
  mv "$BOOK_ROOT" "$BACKUP/docs"
fi
if [ -f .gitignore ]; then
  GITIGNORE_BACKED_UP=1
  mv .gitignore "$BACKUP/.gitignore"
fi
if [ -d "$LEGACY_SPRINTS_DIR" ]; then
  SPRINTS_BACKED_UP=1
  mv "$LEGACY_SPRINTS_DIR" "$BACKUP/sprints"
fi
if [ -d "$LEGACY_TASKS_DIR" ]; then
  TASKS_BACKED_UP=1
  mv "$LEGACY_TASKS_DIR" "$BACKUP/agent-tasks"
fi
if [ -f "$LEGACY_DECISIONS_FILE" ]; then
  DECISIONS_BACKED_UP=1
  mv "$LEGACY_DECISIONS_FILE" "$BACKUP/decisions.md"
fi
if [ -f "$LEGACY_CONFIDENCE_FILE" ]; then
  CONFIDENCE_BACKED_UP=1
  mv "$LEGACY_CONFIDENCE_FILE" "$BACKUP/confidence.txt"
fi

write_backup_manifest
cmp -s "$SOURCE_MANIFEST" "$BACKUP_MANIFEST" ||
  fail 'legacy state changed during migration cutover; rollback preserved the changed source'
write_docs_manifest "$CURRENT_DOCS_MANIFEST" "$BACKUP/docs"
cmp -s "$ROLLBACK_DOCS_MANIFEST" "$CURRENT_DOCS_MANIFEST" ||
  fail 'existing docs changed during migration cutover; rollback preserved the changed source'
backup_gitignore_matches_baseline ||
  fail '.gitignore changed during migration cutover; rollback preserved the changed source'

DOCS_INSTALLED=1
mv "$STAGE/docs" "$BOOK_ROOT"
GITIGNORE_INSTALLED=1
mv "$STAGE/.gitignore" .gitignore

[ "$(book_layout_state)" = book-only ] || fail 'cutover did not leave one Book-only authority'
book_require_v2_layout || exit 1
bash "$SCRIPT_DIR/check-book.sh" . >/dev/null
verify_manifest_targets "$SOURCE_MANIFEST" "$PROJECT_ROOT" || fail 'migrated Book does not match the legacy path-and-hash inventory'
verify_manifest_targets "$EXISTING_DOCS_MANIFEST" "$PROJECT_ROOT" || fail 'migration did not preserve existing docs content'

POST_SPRINT_NUMBER=$(bash "$SCRIPT_DIR/current-sprint.sh")
POST_PHASE=$(bash "$SCRIPT_DIR/current-phase.sh")
[ "$POST_SPRINT_NUMBER" = "$STAGED_SPRINT_NUMBER" ] || fail 'current sprint changed during migration cutover'
[ "$POST_PHASE" = "$STAGED_PHASE" ] || fail "routing phase changed during migration cutover: staged=$STAGED_PHASE final=$POST_PHASE"

write_backup_manifest
cmp -s "$SOURCE_MANIFEST" "$BACKUP_MANIFEST" ||
  fail 'legacy backup changed before migration commit; rollback retained the transaction'
write_docs_manifest "$CURRENT_DOCS_MANIFEST" "$BACKUP/docs"
cmp -s "$ROLLBACK_DOCS_MANIFEST" "$CURRENT_DOCS_MANIFEST" ||
  fail 'existing docs backup changed before migration commit; rollback retained the transaction'
backup_gitignore_matches_baseline ||
  fail '.gitignore backup changed before migration commit; rollback retained the transaction'
[ "$(book_layout_state)" = book-only ] || fail 'legacy authority reappeared before migration commit'

trap - EXIT HUP INT TERM
COMMITTED=1
cleanup_transaction
printf 'migrate-to-book: migrated legacy state losslessly; current sprint=%s phase=%s\n' "$POST_SPRINT_NUMBER" "$POST_PHASE"
