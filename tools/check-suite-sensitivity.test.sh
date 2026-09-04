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

# fixture <name> <suite-body> -> prints the repo path.
# The planted subject prints a token; a coupled suite asserts on that token, an
# uncoupled one only asserts the subject exited 0.
fixture() {
  local d="$TMP_ROOT/$1"; shift
  mkdir -p "$d/tools" "$d/extras" "$d/scripts"
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
  printf '{"suite":"extra:probe.sh","script_hash":"x","status":"%s","evidence_hash":"y","duration_s":0,"ts":"2026-01-01T00:00:00Z"}\n' \
    "$2" > "$1/baseline.ndjson"
}

# test_sensitive_suite_passes_the_check — a suite that asserts its subject's
# actual output goes red when the subject is neutered.
GOOD=$(fixture good '#!/usr/bin/env bash
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
FB=$(fixture failbase '#!/usr/bin/env bash
touch "$PWD/RAN-MARKER"
exit 0')
baseline "$FB" FAIL
out=$(run_tool "$FB"); rc=$?
case "$out" in *baseline-not-pass*) : ;; *) die test_failing_baseline_is_not_scored "not skipped: $out" ;; esac
[ "$rc" -eq 0 ] || die test_failing_baseline_is_not_scored "a skip was treated as a failure"
find "$TMP_ROOT/failbase" -name RAN-MARKER | grep -q . &&
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
run_tool "$CL" >/dev/null 2>&1
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

printf 'check-suite-sensitivity selftest: all fixtures passed\n'
