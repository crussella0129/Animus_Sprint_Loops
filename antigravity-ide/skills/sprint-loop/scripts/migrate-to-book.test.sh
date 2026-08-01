#!/usr/bin/env bash
# Focused lossless/idempotent/safety fixtures for migrate-to-book.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATE="$SCRIPT_DIR/migrate-to-book.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-migrate.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM

pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

write_meta() {
  meta_path=$1 sprint_number=$2 status=$3
  cat > "$meta_path" <<EOF
# Sprint $sprint_number Meta

- **Sprint number:** $sprint_number
- **Start timestamp:** 2026-01-01T00:00:00Z
- **End timestamp:** (filled at Loop Phase)
- **Model:** fixture
- **Exit status:** $status
- **Token count:** (filled at Loop Phase if observable)
- **Summary:** fixture
EOF
}

snapshot_book() {
  snapshot_root=$1 snapshot_out=$2
  (
    cd "$snapshot_root"
    find docs -print | LC_ALL=C sort | while IFS= read -r snapshot_path; do
      if [ -d "$snapshot_path" ]; then
        printf 'D\t%s\n' "$snapshot_path"
      else
        printf 'F\t%s\t' "$snapshot_path"
        cksum "$snapshot_path"
      fi
    done
    printf 'G\t'; cksum .gitignore
  ) > "$snapshot_out"
}

test_hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{ print $1 }'
  else
    shasum -a 256 "$1" | awk '{ print $1 }'
  fi
}

legacy_inventory() {
  inventory_root=$1 inventory_out=$2
  {
    for inventory_source_root in sprints agent-tasks; do
      [ -d "$inventory_root/$inventory_source_root" ] || continue
      while IFS= read -r inventory_actual; do
        inventory_source=${inventory_actual#"$inventory_root"/}
        if [ -d "$inventory_actual" ]; then
          inventory_type=D
          inventory_hash=-
        else
          inventory_type=F
          inventory_hash=$(test_hash_file "$inventory_actual")
        fi
        case "$inventory_source" in
          sprints) inventory_target=docs/sprints ;;
          sprints/*) inventory_target="docs/sprints/${inventory_source#sprints/}" ;;
          agent-tasks) inventory_target=docs/work ;;
          agent-tasks/agent-tasks.md) inventory_target=docs/work/tasks.md ;;
          agent-tasks/completed-tasks.md) inventory_target=docs/work/completed-tasks.md ;;
          agent-tasks/*) inventory_target="docs/work/${inventory_source#agent-tasks/}" ;;
        esac
        printf '%s\t%s\t%s\t%s\n' \
          "$inventory_type" "$inventory_hash" "$inventory_source" "$inventory_target"
      done < <(find "$inventory_root/$inventory_source_root" -print | LC_ALL=C sort)
    done
    for inventory_source in decisions.md confidence.txt; do
      [ -f "$inventory_root/$inventory_source" ] || continue
      case "$inventory_source" in
        decisions.md) inventory_target=docs/history/decisions-legacy.md ;;
        confidence.txt) inventory_target=docs/work/confidence.txt ;;
      esac
      printf 'F\t%s\t%s\t%s\n' "$(test_hash_file "$inventory_root/$inventory_source")" \
        "$inventory_source" "$inventory_target"
    done
  } | LC_ALL=C sort > "$inventory_out"
}

assert_inventory_migrated() {
  migrated_root=$1 migrated_inventory=$2 migrated_provenance=$3
  while IFS="$(printf '\t')" read -r migrated_type migrated_hash migrated_source migrated_target; do
    migrated_path="$migrated_root/$migrated_target"
    case "$migrated_type" in
      D) [ -d "$migrated_path" ] || return 1 ;;
      F)
        [ -f "$migrated_path" ] || return 1
        [ "$(test_hash_file "$migrated_path")" = "$migrated_hash" ] || return 1
        ;;
      *) return 1 ;;
    esac
    grep -Fqx "    $migrated_type	$migrated_hash	$migrated_source	$migrated_target" \
      "$migrated_provenance" || return 1
  done < "$migrated_inventory"
}

P="$TMP_ROOT/legacy project"
mkdir -p "$P/sprints/s0/sprint-research" "$P/sprints/s0/sprint-plans" "$P/sprints/s0/sprint-tests"
mkdir -p "$P/sprints/s2/sprint-research/artifacts/empty dir" "$P/sprints/s2/sprint-plans" "$P/sprints/s2/sprint-tests"
write_meta "$P/sprints/s0/sprint-meta.md" 0 success
write_meta "$P/sprints/s2/sprint-meta.md" 2 in-progress
printf 'old research\n' > "$P/sprints/s0/sprint-research/research-report.md"
printf 'current research\n' > "$P/sprints/s2/sprint-research/research-report.md"
printf 'Finalized - DO NOT EDIT\n\n# build\n' > "$P/sprints/s2/sprint-plans/build-plan.md"
printf 'Finalized - DO NOT EDIT\n\n# test\n' > "$P/sprints/s2/sprint-plans/test-plan.md"
: > "$P/sprints/s2/sprint-research/artifacts/file with spaces.txt"
mkdir -p "$P/agent-tasks"
printf '# Agent Tasks (Persistent Backlog)\n- [ ] T-200 (sprint 2): fixture\n' > "$P/agent-tasks/agent-tasks.md"
printf '# Completed Tasks Log (Append-Only)\n' > "$P/agent-tasks/completed-tasks.md"
printf 'extra ledger bytes\n' > "$P/agent-tasks/notes with spaces.md"
printf '# Architectural Decisions\n\n## Keep these exact bytes\n' > "$P/decisions.md"
printf '0.7\n' > "$P/confidence.txt"
mkdir -p "$P/docs"
printf 'existing docs survive\n' > "$P/docs/guide with spaces.md"
printf '# Existing summary\r\n- [Sprint 0](sprints/s0/sprint-meta.md)\r\ncustom tail' > "$P/docs/SUMMARY.md"
printf 'node_modules/\r\n# >>> sprint-loops >>>\r\nsprints/\r\n*.tmp\r\n# <<< sprint-loops <<<\r\n' > "$P/.gitignore"
cp -p "$P/decisions.md" "$TMP_ROOT/decisions.before"
cp -p "$P/confidence.txt" "$TMP_ROOT/confidence.before"
cp -p "$P/agent-tasks/agent-tasks.md" "$TMP_ROOT/tasks.before"
cp -p "$P/sprints/s2/sprint-research/artifacts/file with spaces.txt" "$TMP_ROOT/spaces.before"
legacy_inventory "$P" "$TMP_ROOT/legacy.inventory"

if (cd "$P" && bash "$SCRIPT_DIR/current-phase.sh" >out 2>err); then
  die test_legacy_only_is_detected 'legacy-only router selected a writable phase'
fi
grep -Fq 'legacy-only Sprint Loops layout detected; migrate to the v2 Book before writing state' "$P/err" ||
  die test_legacy_only_is_detected 'migration diagnostic missing'
[ ! -e "$P/docs/.sprint-loop-book" ] && [ ! -e "$P/.sprint-loop-migration" ] ||
  die test_legacy_only_is_detected 'router mutated the legacy-only fixture'
rm -f "$P/out" "$P/err"
pass test_legacy_only_is_detected

(cd "$P" && bash "$MIGRATE" > "$TMP_ROOT/success.out") || die test_migrate_legacy_losslessly 'migration failed'
for old in sprints agent-tasks decisions.md confidence.txt; do
  [ ! -e "$P/$old" ] || die test_migrate_legacy_losslessly "legacy authority remains: $old"
done
cmp -s "$TMP_ROOT/decisions.before" "$P/docs/history/decisions-legacy.md" || die test_migrate_legacy_losslessly 'decisions bytes changed'
cmp -s "$TMP_ROOT/confidence.before" "$P/docs/work/confidence.txt" || die test_migrate_legacy_losslessly 'confidence bytes changed'
cmp -s "$TMP_ROOT/tasks.before" "$P/docs/work/tasks.md" || die test_migrate_legacy_losslessly 'task bytes changed'
cmp -s "$TMP_ROOT/spaces.before" "$P/docs/sprints/s2/sprint-research/artifacts/file with spaces.txt" || die test_migrate_legacy_losslessly 'space-named file changed'
[ -d "$P/docs/sprints/s2/sprint-research/artifacts/empty dir" ] || die test_migrate_legacy_losslessly 'empty directory lost'
grep -Fqx 'existing docs survive' "$P/docs/guide with spaces.md" || die test_migrate_legacy_losslessly 'existing docs changed'
grep -Fq '<!-- sprint-loop-migration-v2 -->' "$P/docs/history/migration-provenance.md" || die test_migrate_legacy_losslessly 'provenance missing'
assert_inventory_migrated "$P" "$TMP_ROOT/legacy.inventory" "$P/docs/history/migration-provenance.md" ||
  die test_migrate_legacy_losslessly 'full path/type/SHA-256 inventory did not map one-to-one'
[ "$(grep -cF '(sprints/s0/sprint-meta.md)' "$P/docs/SUMMARY.md")" = 1 ] || die test_migrate_legacy_losslessly 's0 navigation missing or duplicated'
[ "$(grep -cF '(sprints/s2/sprint-meta.md)' "$P/docs/SUMMARY.md")" = 1 ] || die test_migrate_legacy_losslessly 's2 navigation missing or duplicated'
grep -Fqx 'custom tail' "$P/docs/SUMMARY.md" || die test_migrate_legacy_losslessly 'SUMMARY line boundary was not preserved'
[ "$(grep -cFx '# >>> sprint-loops >>>' "$P/.gitignore")" = 1 ] || die test_migrate_legacy_losslessly 'ignore marker duplicated'
grep -Fq 'node_modules/' "$P/.gitignore" || die test_migrate_legacy_losslessly 'project ignore lost'
if grep -Fqx 'sprints/' "$P/.gitignore"; then die test_migrate_legacy_losslessly 'nested Book history remains ignored'; fi
[ "$(cd "$P" && bash "$SCRIPT_DIR/current-sprint.sh")" = 2 ] || die test_migrate_legacy_losslessly 'current sprint drifted'
[ "$(cd "$P" && bash "$SCRIPT_DIR/current-phase.sh")" = build ] || die test_migrate_legacy_losslessly 'phase drifted'
(cd "$P" && bash "$SCRIPT_DIR/check-book.sh" . >/dev/null) || die test_migrate_legacy_losslessly 'Book validation failed'
pass test_migrate_legacy_losslessly
[ -f "$P/docs/history/decisions-legacy.md" ] && [ ! -e "$P/docs/decisions.md" ] ||
  die test_migrated_decisions_are_history 'legacy decisions became an active Book authority'
pass test_migrated_decisions_are_history

snapshot_book "$P" "$TMP_ROOT/book.before"
(cd "$P" && bash "$MIGRATE" > "$TMP_ROOT/rerun.out") || die test_migrate_is_idempotent 'rerun failed'
snapshot_book "$P" "$TMP_ROOT/book.after"
cmp -s "$TMP_ROOT/book.before" "$TMP_ROOT/book.after" || die test_migrate_is_idempotent 'rerun changed Book bytes or paths'
pass test_migrate_is_idempotent

C="$TMP_ROOT/conflict"; mkdir -p "$C"
(cd "$C" && bash "$SCRIPT_DIR/init-sprint.sh" --scaffold-only >/dev/null)
mkdir -p "$C/sprints/s9"; printf 'legacy conflict\n' > "$C/sprints/s9/state.txt"
before_conflict=$(cksum "$C/sprints/s9/state.txt" "$C/docs/.sprint-loop-book")
if (cd "$C" && bash "$MIGRATE" >out 2>err); then die test_migrate_conflict_refuses 'migration chose an authority'; fi
grep -Fq 'split-brain state: writable Book and legacy Sprint Loops layouts coexist' "$C/err" || die test_migrate_conflict_refuses 'diagnostic missing'
[ "$before_conflict" = "$(cksum "$C/sprints/s9/state.txt" "$C/docs/.sprint-loop-book")" ] || die test_migrate_conflict_refuses 'conflict fixture mutated'
for router in current-sprint.sh current-phase.sh; do
  if (cd "$C" && bash "$SCRIPT_DIR/$router" >out 2>err); then die test_router_conflict_refuses "$router chose an authority"; fi
  grep -Fq 'split-brain state: writable Book and legacy Sprint Loops layouts coexist' "$C/err" || die test_router_conflict_refuses "$router diagnostic missing"
done
pass test_migrate_conflict_refuses
pass test_router_conflict_refuses

O="$TMP_ROOT/outside"; B="$TMP_ROOT/unsafe"; mkdir -p "$O/s0" "$B"
printf 'outside bytes\n' > "$O/s0/state.txt"
ln -s "$O" "$B/sprints"
outside_before=$(cksum "$O/s0/state.txt")
if (cd "$B" && bash "$MIGRATE" >out 2>err); then die test_migrate_invalid_path_refuses_before_mutation 'symlink accepted'; fi
grep -Fq 'unsafe migration path: symlink or alias' "$B/err" || die test_migrate_invalid_path_refuses_before_mutation 'diagnostic missing'
[ "$outside_before" = "$(cksum "$O/s0/state.txt")" ] || die test_migrate_invalid_path_refuses_before_mutation 'outside target changed'
[ ! -e "$B/docs" ] && [ ! -e "$B/.sprint-loop-migration" ] || die test_migrate_invalid_path_refuses_before_mutation 'fixture mutated before refusal'
pass test_migrate_invalid_path_refuses_before_mutation

N="$TMP_ROOT/nested-alias"; NO="$TMP_ROOT/nested-outside"
mkdir -p "$N/sprints/s0/artifacts" "$NO"
printf 'nested outside bytes\n' > "$NO/state.txt"
ln -s "$NO" "$N/sprints/s0/artifacts/external"
if (cd "$N" && bash "$MIGRATE" >out 2>err); then
  die test_migrate_nested_alias_refuses 'nested symlink accepted'
fi
grep -Fq 'unsafe migration path: symlink or alias beneath' "$N/err" ||
  die test_migrate_nested_alias_refuses 'nested alias diagnostic missing'
[ ! -e "$N/docs" ] && [ ! -e "$N/.sprint-loop-migration" ] ||
  die test_migrate_nested_alias_refuses 'nested alias fixture mutated'
pass test_migrate_nested_alias_refuses

H="$TMP_ROOT/hardlink-alias"
mkdir -p "$H/sprints/s0"
printf 'hardlink bytes\n' > "$H/sprints/s0/original.txt"
ln "$H/sprints/s0/original.txt" "$H/sprints/s0/alias.txt"
if (cd "$H" && bash "$MIGRATE" >out 2>err); then
  die test_migrate_hardlink_refuses 'hard-linked source accepted'
fi
grep -Fq 'unsafe migration path: hard-linked file beneath' "$H/err" ||
  die test_migrate_hardlink_refuses 'hardlink diagnostic missing'
[ ! -e "$H/docs" ] && [ ! -e "$H/.sprint-loop-migration" ] ||
  die test_migrate_hardlink_refuses 'hardlink fixture mutated'
pass test_migrate_hardlink_refuses

DO="$TMP_ROOT/docs-outside"; DA="$TMP_ROOT/docs-alias"
mkdir -p "$DO" "$DA"
printf 'outside docs bytes\n' > "$DO/guide.md"
printf 'legacy decision\n' > "$DA/decisions.md"
ln -s "$DO" "$DA/docs"
docs_outside_before=$(cksum "$DO/guide.md")
if (cd "$DA" && bash "$MIGRATE" >out 2>err); then
  die test_migrate_book_target_alias_refuses 'symlinked Book target accepted'
fi
grep -Fq 'unsafe migration path: symlink or alias: docs' "$DA/err" ||
  die test_migrate_book_target_alias_refuses 'Book target alias diagnostic missing'
[ "$docs_outside_before" = "$(cksum "$DO/guide.md")" ] ||
  die test_migrate_book_target_alias_refuses 'outside Book target changed'
[ ! -e "$DA/.sprint-loop-migration" ] ||
  die test_migrate_book_target_alias_refuses 'Book target alias created a transaction'
pass test_migrate_book_target_alias_refuses

I="$TMP_ROOT/ignored-book"
mkdir -p "$I"
printf 'ignored history decision\n' > "$I/decisions.md"
printf '/docs/history/\n' > "$I/.gitignore"
ignored_before=$(cksum "$I/decisions.md" "$I/.gitignore")
if (cd "$I" && bash "$MIGRATE" >out 2>err); then
  die test_migrate_rejects_ignored_book_path 'ignored Book subtree accepted'
fi
grep -Fq 'Book path remains ignored after .gitignore migration: docs/history' "$I/err" ||
  die test_migrate_rejects_ignored_book_path 'ignored Book diagnostic missing'
[ "$ignored_before" = "$(cksum "$I/decisions.md" "$I/.gitignore")" ] ||
  die test_migrate_rejects_ignored_book_path 'ignored-path refusal changed source bytes'
[ ! -e "$I/docs" ] && [ ! -e "$I/.sprint-loop-migration" ] ||
  die test_migrate_rejects_ignored_book_path 'ignored-path refusal mutated the fixture'
pass test_migrate_rejects_ignored_book_path

MV_STUB="$TMP_ROOT/mv-stub"
mkdir -p "$MV_STUB"
REAL_MV_BIN=$(command -v mv)
cat > "$MV_STUB/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source_path=${1-}
target_path=${2-}
case "$source_path|$target_path" in
  "sprints|"*/.sprint-loop-migration/backup/sprints)
    if [ "${MV_TEST_MODE:-}" = mutate ]; then
      printf 'late writer bytes\n' > "$source_path/late-writer.txt"
    fi
    "$REAL_MV_BIN" "$@"
    if [ "${MV_TEST_MODE:-}" = signal ]; then
      kill -TERM "$PPID"
    fi
    ;;
  *) "$REAL_MV_BIN" "$@" ;;
esac
EOF
chmod +x "$MV_STUB/mv"

make_cutover_fixture() {
  cutover_root=$1
  mkdir -p "$cutover_root/sprints/s0/sprint-research" \
    "$cutover_root/sprints/s0/sprint-plans" "$cutover_root/sprints/s0/sprint-tests"
  write_meta "$cutover_root/sprints/s0/sprint-meta.md" 0 in-progress
  printf 'rollback research\n' > "$cutover_root/sprints/s0/sprint-research/research-report.md"
}

R="$TMP_ROOT/signal-rollback"
make_cutover_fixture "$R"
signal_before=$(cksum "$R/sprints/s0/sprint-meta.md")
if (cd "$R" && PATH="$MV_STUB:$PATH" REAL_MV_BIN="$REAL_MV_BIN" MV_TEST_MODE=signal \
  bash "$MIGRATE" >out 2>err); then
  die test_migrate_signal_rolls_back 'signal did not interrupt migration'
fi
[ "$signal_before" = "$(cksum "$R/sprints/s0/sprint-meta.md")" ] ||
  die test_migrate_signal_rolls_back 'legacy bytes were not restored'
[ ! -e "$R/docs" ] && [ ! -e "$R/.gitignore" ] && [ ! -e "$R/.sprint-loop-migration" ] ||
  die test_migrate_signal_rolls_back 'rollback left a partial Book or transaction'
pass test_migrate_signal_rolls_back

W="$TMP_ROOT/concurrent-writer"
make_cutover_fixture "$W"
if (cd "$W" && PATH="$MV_STUB:$PATH" REAL_MV_BIN="$REAL_MV_BIN" MV_TEST_MODE=mutate \
  bash "$MIGRATE" >out 2>err); then
  die test_migrate_detects_cutover_mutation 'cutover accepted a concurrent source addition'
fi
grep -Fq 'legacy state changed during migration cutover; rollback preserved the changed source' "$W/err" ||
  die test_migrate_detects_cutover_mutation 'cutover diagnostic missing'
grep -Fqx 'late writer bytes' "$W/sprints/late-writer.txt" ||
  die test_migrate_detects_cutover_mutation 'concurrent source bytes were lost'
[ ! -e "$W/docs" ] && [ ! -e "$W/.gitignore" ] && [ ! -e "$W/.sprint-loop-migration" ] ||
  die test_migrate_detects_cutover_mutation 'rollback left a partial Book or transaction'
pass test_migrate_detects_cutover_mutation

echo 'migrate-to-book selftest: all fixtures passed'
