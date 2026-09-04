#!/usr/bin/env bash
# Fixtures for the neutered-subject sensitivity check.
#
# The load-bearing one is test_insensitive_suite_is_caught. A checker that never
# detects anything passes every "good input" fixture ever written, so the only
# assertion that establishes this tool works is one where a genuinely bad suite
# must be reported. That is the same defect class the tool exists to find, so
# getting it wrong here would be particularly embarrassing.
#
# Each fixture builds a self-contained git repository carrying its own copy of
# the two tools plus a synthetic subject/suite pair declared through the
# extra-suite seam, so nothing here depends on the real suite list.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-sens.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM
pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }
RAN_MARKER="$TMP_ROOT/ran-marker"
export RAN_MARKER

# fixture <name> <suite-body> -> prints the repo path.
# The planted subject prints a token; a coupled suite asserts on that token, an
# uncoupled one only asserts the subject exited 0.
fixture() {
  local d="$TMP_ROOT/$1"; shift
  mkdir -p "$d/tools" "$d/extras" "$d/scripts"
  printf '/baseline.ndjson\n' > "$d/.gitignore"
  cp "$ROOT/tools/run-guards.sh" "$ROOT/tools/check-suite-sensitivity.sh" "$d/tools/"
  printf '#!/usr/bin/env bash\necho REAL-OUTPUT\n' > "$d/scripts/subject.sh"
  printf '%s\n' "scripts/subject.sh" > "$d/extras/probe.subject"
  printf '%s\n' "$1" > "$d/extras/probe.sh"
  git init -q "$d"
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" commit -qm fixture >/dev/null 2>&1
  printf '%s' "$d"
}

# Run the tool inside a fixture repo, with the extras seam pointing at a path
# that resolves both here and inside the repository copy it makes.
run_tool() {  # <repo> [extra-args...]
  local d=$1; shift
  ( cd "$d" && RUN_GUARDS_ONLY_EXTRA=1 RUN_GUARDS_EXTRA_SUITES=extras \
      bash tools/check-suite-sensitivity.sh --report baseline.ndjson "$@" 2>&1 )
}

baseline() {  # <repo> <status>
  local rc
  (cd "$1" && RUN_GUARDS_ONLY_EXTRA=1 RUN_GUARDS_EXTRA_SUITES=extras \
    bash tools/run-guards.sh --committed --out baseline.ndjson) >"$TMP_ROOT/baseline.log" 2>&1
  rc=$?
  if { [ "$2" = PASS ] && [ "$rc" -ne 0 ]; } || { [ "$2" = FAIL ] && [ "$rc" -ne 1 ]; }; then
    die baseline "expected $2, got exit $rc: $(cat "$TMP_ROOT/baseline.log")"
  fi
}

# test_sensitive_suite_passes_the_check — a suite that asserts its subject's
# actual output goes red when the subject is neutered.
GOOD=$(fixture good '#!/usr/bin/env bash
touch "$RAN_MARKER"
out=$(bash scripts/subject.sh)
[ "$out" = REAL-OUTPUT ] || exit 1')
baseline "$GOOD" PASS
out=$(run_tool "$GOOD"); rc=$?
case "$out" in *"sensitive"*) : ;; *) die test_sensitive_suite_passes_the_check "not reported sensitive: $out" ;; esac
case "$out" in *INSENSITIVE*) die test_sensitive_suite_passes_the_check "a coupled suite was called insensitive: $out" ;; esac
[ "$rc" -eq 0 ] || die test_sensitive_suite_passes_the_check "exit $rc on a clean corpus: $out"
pass test_sensitive_suite_passes_the_check

# test_insensitive_suite_is_caught — THE test. A suite that only checks its
# subject exited 0 still passes against a stub that exits 0, and must be named.
BAD=$(fixture bad '#!/usr/bin/env bash
bash scripts/subject.sh >/dev/null 2>&1 || exit 1')
baseline "$BAD" PASS
out=$(run_tool "$BAD"); rc=$?
case "$out" in *INSENSITIVE*) : ;; *) die test_insensitive_suite_is_caught "an uncoupled suite was not caught: $out" ;; esac
case "$out" in *"extra:probe.sh"*) : ;; *) die test_insensitive_suite_is_caught "the offending suite was not named: $out" ;; esac
[ "$rc" -ne 0 ] || die test_insensitive_suite_is_caught "exited 0 despite an insensitive suite"
pass test_insensitive_suite_is_caught

# test_failing_baseline_is_not_scored — sensitivity of a failing suite is not a
# meaningful question. The suite must not even be executed.
# The marker must land somewhere that outlives the tool: suites run with cwd
# set to a copy inside the tool's own temp dir, which its EXIT trap deletes,
# so an earlier $PWD/RAN-MARKER could never be found and the assertion below
# could never fire.
RAN_MARKER="$TMP_ROOT/ran-marker"
export RAN_MARKER
rm -f "$RAN_MARKER"
FB=$(fixture failbase '#!/usr/bin/env bash
touch "$RAN_MARKER"
exit 1')
baseline "$FB" FAIL
rm -f "$RAN_MARKER"
out=$(run_tool "$FB"); rc=$?
case "$out" in *baseline-not-pass*) : ;; *) die test_failing_baseline_is_not_scored "not skipped: $out" ;; esac
[ "$rc" -ne 0 ] || die test_failing_baseline_is_not_scored "a failing baseline returned success"
[ ! -e "$RAN_MARKER" ] ||
  die test_failing_baseline_is_not_scored "the suite ran despite a non-PASS baseline"
pass test_failing_baseline_is_not_scored

# test_subjectless_suite_reported_not_failed — no subject is a real answer.
NS=$(fixture nosubject '#!/usr/bin/env bash
exit 0')
rm "$NS/extras/probe.subject"
git -C "$NS" add -A >/dev/null 2>&1; git -C "$NS" commit -qm drop >/dev/null 2>&1
baseline "$NS" PASS
out=$(run_tool "$NS"); rc=$?
case "$out" in *no-subject*) : ;; *) die test_subjectless_suite_reported_not_failed "not reported: $out" ;; esac
[ "$rc" -eq 0 ] || die test_subjectless_suite_reported_not_failed "a subjectless suite failed the run"
pass test_subjectless_suite_reported_not_failed

# test_sensitivity_leaves_worktree_clean — the tool neuters scripts, so proving
# it never touches the real tree is not optional.
CL=$(fixture clean '#!/usr/bin/env bash
out=$(bash scripts/subject.sh)
[ "$out" = REAL-OUTPUT ] || exit 1')
baseline "$CL" PASS
before=$(cd "$CL" && git status --porcelain --untracked-files=all)
subject_before=$(cksum "$CL/scripts/subject.sh")
run_tool "$CL" >/dev/null 2>&1 || die test_sensitivity_leaves_worktree_clean 'valid control did not complete'
after=$(cd "$CL" && git status --porcelain --untracked-files=all)
[ "$before" = "$after" ] || die test_sensitivity_leaves_worktree_clean "working tree changed: $after"
[ "$subject_before" = "$(cksum "$CL/scripts/subject.sh")" ] ||
  die test_sensitivity_leaves_worktree_clean "the real subject script was neutered in place"
pass test_sensitivity_leaves_worktree_clean

# test_missing_baseline_refuses — without a baseline a neutered result means
# nothing, so the tool must refuse rather than report a misleading verdict.
MB=$(fixture nobaseline '#!/usr/bin/env bash
exit 0')
out=$( cd "$MB" && RUN_GUARDS_ONLY_EXTRA=1 RUN_GUARDS_EXTRA_SUITES=extras \
  bash tools/check-suite-sensitivity.sh --report absent.ndjson 2>&1 ); rc=$?
[ "$rc" -eq 2 ] || die test_missing_baseline_refuses "expected exit 2, got $rc: $out"
case "$out" in *"no guard report"*) : ;; *) die test_missing_baseline_refuses "no diagnostic: $out" ;; esac
pass test_missing_baseline_refuses

# test_harness_subject_is_skipped - the tool runs each suite THROUGH
# run-guards.sh, so a suite whose subject IS run-guards.sh cannot be scored:
# neutering it neuters the harness and everything "passes", which would be
# reported as a false INSENSITIVE. Verified here rather than only observed in
# the real corpus, so a mapping change cannot silently reintroduce it.
HS=$(fixture harness '#!/usr/bin/env bash
exit 0')
printf '%s\n' "tools/run-guards.sh" > "$HS/extras/probe.subject"
git -C "$HS" add -A >/dev/null 2>&1; git -C "$HS" commit -qm harness >/dev/null 2>&1
baseline "$HS" PASS
out=$(run_tool "$HS"); rc=$?
case "$out" in *harness-subject*) : ;; *) die test_harness_subject_is_skipped "not skipped: $out" ;; esac
case "$out" in *INSENSITIVE*) die test_harness_subject_is_skipped "scored a harness-subject suite: $out" ;; esac
[ "$rc" -eq 0 ] || die test_harness_subject_is_skipped "a harness-subject skip failed the run"
pass test_harness_subject_is_skipped

# Reuse a real passing baseline, altering one property at a time. A marker
# outside the archived copies proves invalid evidence is rejected before runs.
cp "$GOOD/baseline.ndjson" "$TMP_ROOT/valid.ndjson"
expect_refusal() {  # repo test diagnostic [suite...]
  local repo=$1 test=$2 diagnostic=$3 out rc
  shift 3
  rm -f "$RAN_MARKER"
  out=$(run_tool "$repo" "$@"); rc=$?
  [ "$rc" -ne 0 ] || die "$test" "invalid evidence returned success: $out"
  case "$out" in *"$diagnostic"*) : ;; *) die "$test" "missing diagnostic $diagnostic: $out" ;; esac
  [ ! -e "$RAN_MARKER" ] || die "$test" 'suite ran with invalid evidence'
}
for variant in absent malformed duplicate hash tree working nondeterministic; do
  case "$variant" in
    absent) : > "$GOOD/baseline.ndjson" ;;
    malformed) printf 'not-json\n' > "$GOOD/baseline.ndjson" ;;
    duplicate) cat "$TMP_ROOT/valid.ndjson" "$TMP_ROOT/valid.ndjson" > "$GOOD/baseline.ndjson" ;;
    hash) sed 's/"script_hash":"[^"]*"/"script_hash":"0000000000000000000000000000000000000000000000000000000000000000"/' "$TMP_ROOT/valid.ndjson" > "$GOOD/baseline.ndjson" ;;
    tree) sed 's/"source_tree":"[^"]*"/"source_tree":"0000000000000000000000000000000000000000"/' "$TMP_ROOT/valid.ndjson" > "$GOOD/baseline.ndjson" ;;
    working) sed 's/"source_tree":"[^"]*"/"source_tree":"working-tree"/' "$TMP_ROOT/valid.ndjson" > "$GOOD/baseline.ndjson" ;;
    nondeterministic) sed 's/}$/,"determinism":"mismatch"}/' "$TMP_ROOT/valid.ndjson" > "$GOOD/baseline.ndjson" ;;
  esac
  expect_refusal "$GOOD" "test_baseline_integrity_$variant" baseline-
done
cp "$TMP_ROOT/valid.ndjson" "$GOOD/baseline.ndjson"
pass test_baseline_integrity

expect_refusal "$GOOD" test_unknown_suite 'unknown suite' misspelled-suite
pass test_unknown_suite

# A changed subject invalidates the old report even though the suite hash has
# not moved. Staged/local edits alone are excluded by --committed.
printf '#!/usr/bin/env bash\necho CHANGED\n' > "$GOOD/scripts/subject.sh"
git -C "$GOOD" add scripts/subject.sh
baseline "$GOOD" PASS
out=$(run_tool "$GOOD"); rc=$?
[ "$rc" -eq 0 ] || die test_source_provenance "staged edits leaked into HEAD baseline: $out"
git -C "$GOOD" commit -qm 'change subject' || die test_source_provenance 'commit failed'
expect_refusal "$GOOD" test_source_provenance baseline-source-mismatch
pass test_source_provenance

# A working-tree PASS that relies on an untracked file cannot qualify. The
# committed baseline actually runs without that file and correctly fails.
UD=$(fixture untracked '#!/usr/bin/env bash
touch "$RAN_MARKER"
[ -f untracked-dependency ] || exit 1
bash scripts/subject.sh >/dev/null')
touch "$UD/untracked-dependency"
(cd "$UD" && RUN_GUARDS_ONLY_EXTRA=1 RUN_GUARDS_EXTRA_SUITES=extras \
  bash tools/run-guards.sh --out baseline.ndjson) >/dev/null 2>&1 || die test_untracked_dependency 'working control failed'
expect_refusal "$UD" test_untracked_dependency baseline-source-mismatch
baseline "$UD" FAIL
expect_refusal "$UD" test_untracked_dependency baseline-not-pass
pass test_untracked_dependency

# A succeeds only with A's output; B checks A, but only B's exit status. B must
# remain INSENSITIVE after A is tested, before A is tested, and by itself.
MS=$(fixture multiple '#!/usr/bin/env bash
[ "$(bash scripts/subject.sh)" = REAL-OUTPUT ] || exit 1')
printf '#!/usr/bin/env bash\necho SECOND\n' > "$MS/scripts/second.sh"
printf 'scripts/second.sh\n' > "$MS/extras/second.subject"
cat > "$MS/extras/second.sh" <<'EOF'
#!/usr/bin/env bash
[ "$(bash scripts/subject.sh)" = REAL-OUTPUT ] || exit 1
bash scripts/second.sh >/dev/null || exit 1
EOF
git -C "$MS" add -A && git -C "$MS" commit -qm second || die test_subject_restored_between_suites 'commit failed'
baseline "$MS" PASS
for order in 'extra:probe.sh extra:second.sh' 'extra:second.sh extra:probe.sh' 'extra:second.sh'; do
  # Intentional splitting of the fixed suite-name list.
  # shellcheck disable=SC2086
  out=$(run_tool "$MS" $order); rc=$?
  [ "$rc" -eq 1 ] || die test_subject_restored_between_suites "expected insensitive verdict: $out"
  printf '%s\n' "$out" | grep -Eq '^extra:second.sh +INSENSITIVE ' ||
    die test_subject_restored_between_suites "B inherited A mutation: $out"
done
pass test_subject_restored_between_suites

printf 'scripts/subject.sh\n' > "$MS/extras/second.subject"
printf '#!/usr/bin/env bash\nbash scripts/subject.sh >/dev/null\n' > "$MS/extras/second.sh"
git -C "$MS" add -A && git -C "$MS" commit -qm shared || die test_shared_subject_suites 'commit failed'
baseline "$MS" PASS
out=$(run_tool "$MS"); rc=$?
[ "$rc" -eq 1 ] || die test_shared_subject_suites "shared subject skipped: $out"
printf '%s\n' "$out" | grep -Eq '^extra:second.sh +INSENSITIVE ' || die test_shared_subject_suites "second suite not scored: $out"
pass test_shared_subject_suites

# A committed harness that disappears only at mutation time must not be
# mistaken for a sensitive suite, whether it exits zero or nonzero.
for missing_rc in 0 2; do
  MC=$(fixture "missing-$missing_rc" '#!/usr/bin/env bash
[ "$(bash scripts/subject.sh)" = REAL-OUTPUT ] || exit 1')
  awk -v rc="$missing_rc" 'NR == 2 { print "case \"${2:-}\" in */neutered.ndjson) exit " rc " ;; esac" } { print }' \
    "$MC/tools/run-guards.sh" > "$MC/tools/runner.tmp"
  mv "$MC/tools/runner.tmp" "$MC/tools/run-guards.sh"
  git -C "$MC" add -A && git -C "$MC" commit -qm broken-harness || die test_missing_mutated_confirmation 'commit failed'
  baseline "$MC" PASS
  out=$(run_tool "$MC"); rc=$?
  [ "$rc" -eq 1 ] || die test_missing_mutated_confirmation "no confirmation returned success: $out"
  case "$out" in *'no valid mutated confirmation'*) : ;; *) die test_missing_mutated_confirmation "wrong failure: $out" ;; esac
done
pass test_missing_mutated_confirmation

# TMPDIR may have a trailing slash, .. component, or a symlink (macOS /var).
# Containment compares physical paths on both sides, never a lexical spelling.
TEMP_BASE="$TMP_ROOT/temp-roots"
mkdir -p "$TEMP_BASE/physical/holder"
for temp_spelling in "$TEMP_BASE/physical/" "$TEMP_BASE/physical/holder/.."; do
  out=$(TMPDIR="$temp_spelling" run_tool "$CL"); rc=$?
  [ "$rc" -eq 0 ] || die test_temp_root_spellings "valid TMPDIR rejected: $out"
done
pass test_temp_root_spellings
if ln -s "$TEMP_BASE/physical" "$TEMP_BASE/alias" 2>/dev/null && [ -L "$TEMP_BASE/alias" ]; then
  out=$(TMPDIR="$TEMP_BASE/alias" run_tool "$CL"); rc=$?
  [ "$rc" -eq 0 ] || die test_symlinked_temp_root "symlinked TMPDIR rejected: $out"
  pass test_symlinked_temp_root
else
  printf '  SKIP  test_symlinked_temp_root: host does not create directory symlinks\n'
fi

printf 'check-suite-sensitivity selftest: all fixtures passed\n'
