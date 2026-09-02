#!/usr/bin/env bash
# Focused Book initialization and artifact-routing fixtures.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-routing.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM

pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }
phase() { (cd "$1" && bash "$SCRIPT_DIR/current-phase.sh"); }
assert_phase() { got=$(phase "$1"); [ "$got" = "$2" ] || die "$3" "expected=$2 got=$got"; pass "$3"; }

F="$TMP_ROOT/fresh project"
mkdir -p "$F/docs"
printf 'keep me\n' > "$F/docs/guide with spaces.md"
printf 'node_modules/\n' > "$F/.gitignore"
(cd "$F" && git init -q && SPRINT_MODEL=selftest bash "$SCRIPT_DIR/init-sprint.sh" >/dev/null)
for path in docs/.sprint-loop-book docs/README.md docs/SUMMARY.md docs/intents/README.md docs/work/tasks.md docs/work/completed-tasks.md docs/work/confidence.txt docs/sprints/s0/sprint-meta.md; do
  [ -e "$F/$path" ] || die test_init_creates_tracked_book "missing $path"
done
for path in sprints agent-tasks decisions.md confidence.txt; do
  [ ! -e "$F/$path" ] || die test_init_creates_tracked_book "legacy authority created: $path"
done
grep -Fqx 'keep me' "$F/docs/guide with spaces.md" || die test_init_creates_tracked_book 'pre-existing docs changed'
grep -Fqx 'node_modules/' "$F/.gitignore" || die test_init_preserves_gitignore 'existing ignore lost'
if (cd "$F" && git check-ignore -q docs/README.md); then die test_init_preserves_gitignore 'Book is ignored'; fi
pass test_init_creates_tracked_book
pass test_init_preserves_gitignore

assert_phase "$F" research test_phase_walk_research
printf '# research\n\n## Intents Reviewed\n- none yet\n' > "$F/docs/sprints/s0/sprint-research/research-report.md"
assert_phase "$F" plan test_phase_walk_plan
printf 'Finalized - DO NOT EDIT\n\n# build\n' > "$F/docs/sprints/s0/sprint-plans/build-plan.md"
assert_phase "$F" plan test_phase_walk_both_plans_required
printf 'Finalized - DO NOT EDIT\n\n# test\n' > "$F/docs/sprints/s0/sprint-plans/test-plan.md"
assert_phase "$F" build test_phase_walk_build_not_started
printf '%s\n' '- [ ] T-001 (sprint 0) [intent: INT-0001]: fixture' >> "$F/docs/work/tasks.md"
assert_phase "$F" build test_phase_walk_build_queued
awk '$0 !~ /T-001 \(sprint 0\)/ { print }' "$F/docs/work/tasks.md" > "$F/docs/work/tasks.md.tmp"
mv "$F/docs/work/tasks.md.tmp" "$F/docs/work/tasks.md"
printf '\n## T-001 (sprint 0)\n- **Commit:** `fixture`\n' >> "$F/docs/work/completed-tasks.md"
assert_phase "$F" test test_phase_walk_test
printf '# report\n' > "$F/docs/sprints/s0/sprint-tests/test-report.md"
assert_phase "$F" test test_phase_walk_requires_critique
cat > "$F/docs/sprints/s0/sprint-tests/critique.md" <<'EOF'
# Critique
## Concerns
- evidence gap
## Confidence
block
EOF
assert_phase "$F" test test_phase_walk_rejects_blocking_critique
cat > "$F/docs/sprints/s0/sprint-tests/critique.md" <<'EOF'
# Critique
## Concerns
- none
## Confidence
clean extra
EOF
assert_phase "$F" test test_phase_walk_rejects_malformed_critique
cat > "$F/docs/sprints/s0/sprint-tests/critique.md" <<'EOF'
# Critique
## Concerns
- none
## Confidence
clean
EOF
assert_phase "$F" loop test_phase_walk_loop
awk '{ sub(/\*\*Exit status:\*\* in-progress/, "**Exit status:** success"); print }' "$F/docs/sprints/s0/sprint-meta.md" > "$F/docs/sprints/s0/sprint-meta.md.tmp"
mv "$F/docs/sprints/s0/sprint-meta.md.tmp" "$F/docs/sprints/s0/sprint-meta.md"
assert_phase "$F" ready-for-next-sprint test_phase_walk_ready

SNAP="$TMP_ROOT/scaffold snapshot"; mkdir -p "$SNAP"
for path in README.md intents/README.md work/tasks.md work/completed-tasks.md work/confidence.txt; do
  mkdir -p "$SNAP/$(dirname "$path")"; cp "$F/docs/$path" "$SNAP/$path"
done
(cd "$F" && SPRINT_MODEL=selftest bash "$SCRIPT_DIR/init-sprint.sh" >/dev/null)
for path in README.md intents/README.md work/tasks.md work/completed-tasks.md work/confidence.txt; do
  cmp "$F/docs/$path" "$SNAP/$path" >/dev/null || die test_init_is_idempotent_for_scaffolding "changed $path"
done
[ "$(cd "$F" && bash "$SCRIPT_DIR/current-sprint.sh")" = 1 ] || die test_init_is_idempotent_for_scaffolding 's1 not created'
[ "$(grep -cFx -- '- [Project Book](README.md)' "$F/docs/SUMMARY.md")" = 1 ] || die test_init_is_idempotent_for_scaffolding 'core nav duplicated'
[ "$(grep -cF '(sprints/s0/sprint-meta.md)' "$F/docs/SUMMARY.md")" = 1 ] || die test_init_is_idempotent_for_scaffolding 's0 nav duplicated'
[ "$(grep -cF '(sprints/s1/sprint-meta.md)' "$F/docs/SUMMARY.md")" = 1 ] || die test_init_is_idempotent_for_scaffolding 's1 nav missing'
[ "$(grep -cFx 'schema-version: 2' "$F/docs/.sprint-loop-book")" = 1 ] || die test_init_is_idempotent_for_scaffolding 'marker changed'
pass test_init_is_idempotent_for_scaffolding

F2="$TMP_ROOT/scaffold-only"; mkdir -p "$F2"
(cd "$F2" && bash "$SCRIPT_DIR/init-sprint.sh" --scaffold-only >/dev/null)
mkdir -p "$F2/docs/sprints/s0" "$F2/docs/sprints/s2"
: > "$F2/docs/sprints/s0/sprint-meta.md"; : > "$F2/docs/sprints/s2/sprint-meta.md"
(cd "$F2" && bash "$SCRIPT_DIR/init-sprint.sh" --scaffold-only >/dev/null)
[ ! -e "$F2/docs/sprints/s3" ] || die test_scaffold_only_refreshes_navigation 'created a sprint'
grep -qF '(sprints/s0/sprint-meta.md)' "$F2/docs/SUMMARY.md" || die test_scaffold_only_refreshes_navigation 's0 missing'
grep -qF '(sprints/s2/sprint-meta.md)' "$F2/docs/SUMMARY.md" || die test_scaffold_only_refreshes_navigation 's2 missing'
pass test_scaffold_only_refreshes_navigation

L="$TMP_ROOT/legacy"; mkdir -p "$L/sprints/s0"
if (cd "$L" && bash "$SCRIPT_DIR/init-sprint.sh" >out 2>err); then die test_legacy_only_is_detected 'init succeeded'; fi
grep -qF 'legacy-only Sprint Loops layout detected' "$L/err" || die test_legacy_only_is_detected 'diagnostic missing'
[ ! -e "$L/docs" ] || die test_legacy_only_is_detected 'mutated legacy fixture'
pass test_legacy_only_is_detected

C="$TMP_ROOT/conflict"; mkdir -p "$C/sprints" "$C/docs/intents" "$C/docs/work" "$C/docs/sprints"
printf 'schema-version: 2\n' > "$C/docs/.sprint-loop-book"
if (cd "$C" && bash "$SCRIPT_DIR/current-phase.sh" >out 2>err); then die test_router_conflict_refuses 'router succeeded'; fi
grep -qF 'split-brain state: writable Book and legacy Sprint Loops layouts coexist' "$C/err" || die test_router_conflict_refuses 'diagnostic missing'
pass test_router_conflict_refuses

# test_init_records_bundle_version — the sprint record names the bundle that
# ran it, in every install mode (the fixture has no plugin manifest at all).
BV="$TMP_ROOT/bundle-version"; mkdir -p "$BV"
(cd "$BV" && git init -q && SPRINT_MODEL=selftest bash "$SCRIPT_DIR/init-sprint.sh" >/dev/null)
BV_META="$BV/docs/sprints/s0/sprint-meta.md"
[ "$(grep -c -- '- \*\*Bundle version:\*\*' "$BV_META")" = 1 ] ||
  die test_init_records_bundle_version 'expected exactly one Bundle version field'
grep -qF -- "- **Bundle version:** $(bash "$SCRIPT_DIR/bundle-version.sh")" "$BV_META" ||
  die test_init_records_bundle_version "recorded version does not match bundle-version.sh"
pass test_init_records_bundle_version

# test_routing_unchanged_for_unstamped_book — the substrate contract version is
# invisible to routing. Every fixture above runs against Books that are never
# stamped; this asserts that directly rather than leaving it implied, because it
# is the backwards-compatibility claim of the substrate-version contract.
U="$TMP_ROOT/unstamped"; mkdir -p "$U"
(cd "$U" && git init -q && SPRINT_MODEL=selftest bash "$SCRIPT_DIR/init-sprint.sh" >/dev/null)
grep -q 'substrate-version' "$U/docs/.sprint-loop-book" &&
  die test_routing_unchanged_for_unstamped_book 'fixture marker is stamped'
assert_phase "$U" research test_routing_unchanged_for_unstamped_book
printf 'x\n' > "$U/docs/sprints/s0/sprint-research/research-report.md"
assert_phase "$U" plan test_routing_unchanged_for_unstamped_book_plan
grep -q 'substrate-version' "$U/docs/.sprint-loop-book" &&
  die test_routing_unchanged_for_unstamped_book 'routing stamped the marker'

echo 'book-routing selftest: all fixtures passed'
