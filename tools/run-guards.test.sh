#!/usr/bin/env bash
# Fixtures for the canonical guard runner.
#
# The runner decides whether every other suite passed, and until this file it
# had no fixtures of its own — which is how a four-sprint-old defect survived:
# `${det:+ det-mismatch}` expands when the field is SET, and the field is set to
# the "ok" payload on agreement, so every failing suite in a --determinism run
# was labelled nondeterministic. The ndjson was right and only the human-facing
# line lied, so nothing downstream noticed.
#
# The suites here are synthetic and driven through RUN_GUARDS_ONLY_EXTRA, so a
# fixture costs milliseconds instead of the real 19-suite run.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RG="$ROOT/tools/run-guards.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-guards.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM
pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

# The report path is a parent-scope variable on purpose: run_with is always
# called in a command substitution, and a subshell's assignment would not
# survive back to the assertions that read it.
NDJSON="$TMP_ROOT/report.ndjson"

# run_with <dir-of-extras> [flags...] -> stdout+stderr; ndjson at $NDJSON
run_with() {
  local extras=$1; shift
  RUN_GUARDS_ONLY_EXTRA=1 RUN_GUARDS_EXTRA_SUITES="$extras" \
    bash "$RG" --out "$NDJSON" "$@" 2>&1
}

# test_failing_deterministic_suite_not_labelled — a suite that fails the same
# way twice is a failure, not a nondeterminism. This is the regression.
D="$TMP_ROOT/det-fail"; mkdir -p "$D"
printf '#!/usr/bin/env bash\necho "same output every run"\nexit 1\n' > "$D/failing.sh"
out=$(run_with "$D" --determinism)
rc=$?
[ "$rc" -ne 0 ] || die test_failing_deterministic_suite_not_labelled 'failure returned success'
case "$out" in
  *"FAIL  extra:failing.sh"*) : ;;
  *) die test_failing_deterministic_suite_not_labelled "suite did not fail: $out" ;;
esac
case "$out" in
  *det-mismatch*) die test_failing_deterministic_suite_not_labelled \
      "a deterministic failure was labelled a determinism mismatch: $out" ;;
esac
grep -q '"determinism":"ok"' "$NDJSON" ||
  die test_failing_deterministic_suite_not_labelled "ndjson lost the ok verdict: $(cat "$NDJSON")"
pass test_failing_deterministic_suite_not_labelled

# test_nondeterministic_suite_is_labelled — and the label must still appear when
# it is true, so the fix cannot be "never print it".
N="$TMP_ROOT/nondet"; mkdir -p "$N"
cat > "$N/flaky.sh" <<EOF
#!/usr/bin/env bash
c="$TMP_ROOT/counter"
n=\$(cat "\$c" 2>/dev/null || echo 0)
n=\$((n + 1))
printf '%s\n' "\$n" > "\$c"
echo "run number \$n"
EOF
out=$(run_with "$N" --determinism)
rc=$?
[ "$rc" -ne 0 ] || die test_nondeterministic_suite_is_labelled 'mismatch returned success'
case "$out" in
  *det-mismatch*) : ;;
  *) die test_nondeterministic_suite_is_labelled "a real mismatch was not labelled: $out" ;;
esac
grep -q '"determinism":"mismatch"' "$NDJSON" ||
  die test_nondeterministic_suite_is_labelled "ndjson lost the mismatch verdict"
pass test_nondeterministic_suite_is_labelled

# test_passing_deterministic_suite_is_clean — the ordinary case, so neither of
# the above can pass by the runner reporting everything as failed.
P="$TMP_ROOT/ok"; mkdir -p "$P"
printf '#!/usr/bin/env bash\necho steady\n' > "$P/good.sh"
out=$(run_with "$P" --determinism)
rc=$?
[ "$rc" -eq 0 ] || die test_passing_deterministic_suite_is_clean "clean run exited $rc: $out"
case "$out" in
  *"PASS  extra:good.sh"*) : ;;
  *) die test_passing_deterministic_suite_is_clean "no PASS line: $out" ;;
esac
case "$out" in
  *det-mismatch*) die test_passing_deterministic_suite_is_clean "clean run labelled a mismatch" ;;
esac
pass test_passing_deterministic_suite_is_clean

case "$out" in
  *steady*|*'--- end '*) die test_passing_deterministic_suite_is_clean 'passing output was not suppressed' ;;
esac

printf '#!/usr/bin/env bash\necho stdout-detail\necho stderr-detail >&2\nexit 7\n' > "$D/failing.sh"
out=$(run_with "$D"); rc=$?
[ "$rc" -ne 0 ] || die test_failure_diagnostics 'failure returned success'
for token in stdout-detail stderr-detail 'extra:failing.sh / run 1 / exit 7'; do
  case "$out" in *"$token"*) : ;; *) die test_failure_diagnostics "missing $token: $out" ;; esac
done
pass test_failure_diagnostics

rm -f "$TMP_ROOT/counter"
out=$(run_with "$N" --determinism); rc=$?
[ "$rc" -ne 0 ] || die test_mismatch_diagnostics 'mismatch returned success'
for token in 'run number 1' 'run number 2' 'normalized diff' '-run number 1' '+run number 2'; do
  case "$out" in *"$token"*) : ;; *) die test_mismatch_diagnostics "missing $token: $out" ;; esac
done
pass test_mismatch_diagnostics

cat >> "$N/flaky.sh" <<'EOF'
[ "$n" -eq 1 ] || { echo second-run-error >&2; exit 9; }
EOF
rm -f "$TMP_ROOT/counter"
out=$(run_with "$N" --determinism); rc=$?
[ "$rc" -ne 0 ] || die test_second_run_failure 'second-run failure returned success'
for token in second-run-error 'run 1 / exit 0' 'run 2 / exit 9'; do
  case "$out" in *"$token"*) : ;; *) die test_second_run_failure "missing $token: $out" ;; esac
done
pass test_second_run_failure

# The evidence writer must fail closed even if the suite itself succeeds.
BROKEN_BIN="$TMP_ROOT/broken-bin"; mkdir -p "$BROKEN_BIN"
printf '#!/usr/bin/env bash\nexit 9\n' > "$BROKEN_BIN/sha256sum"
chmod +x "$BROKEN_BIN/sha256sum"
out=$(PATH="$BROKEN_BIN:$PATH" RUN_GUARDS_HASH_TOOL=sha256sum run_with "$P"); rc=$?
[ "$rc" -ne 0 ] || die test_hash_failure 'failed hash backend returned success'
case "$out" in *'cannot capture or hash evidence'*) : ;; *) die test_hash_failure "no hash diagnostic: $out" ;; esac
if grep -q '"status":"PASS"' "$NDJSON"; then die test_hash_failure 'emitted PASS without a hash'; fi
pass test_hash_failure

RUNNER_RAN_MARKER="$TMP_ROOT/runner-ran"
export RUNNER_RAN_MARKER
printf '#!/usr/bin/env bash\ntouch "$RUNNER_RAN_MARKER"\necho steady\n' > "$P/good.sh"
run_with "$P" >/dev/null || die test_capture_failure 'probe control failed'
[ -f "$RUNNER_RAN_MARKER" ] || die test_capture_failure 'control marker is not observable'
rm -f "$RUNNER_RAN_MARKER"
printf '#!/usr/bin/env bash\nexit 9\n' > "$BROKEN_BIN/mktemp"
chmod +x "$BROKEN_BIN/mktemp"
out=$(PATH="$BROKEN_BIN:$PATH" run_with "$P"); rc=$?
[ "$rc" -ne 0 ] || die test_capture_failure 'failed capture allocation returned success'
case "$out" in *'cannot allocate capture directory'*) : ;; *) die test_capture_failure "no capture diagnostic: $out" ;; esac
[ ! -e "$RUNNER_RAN_MARKER" ] || die test_capture_failure 'suite ran without capture storage'
if grep -q '"status":"PASS"' "$NDJSON"; then die test_capture_failure 'emitted PASS without capture storage'; fi
pass test_capture_failure

WRITE_FAIL="$TMP_ROOT/write-fail"; mkdir -p "$WRITE_FAIL"
RUNNER_REPORT_PATH=$NDJSON
export RUNNER_REPORT_PATH
cat > "$WRITE_FAIL/probe.sh" <<'EOF'
#!/usr/bin/env bash
rm -f "$RUNNER_REPORT_PATH" || exit 1
mkdir "$RUNNER_REPORT_PATH" || exit 1
echo 'suite completed, but report destination is now a directory'
EOF
out=$(run_with "$WRITE_FAIL"); rc=$?
[ "$rc" -ne 0 ] || die test_report_write_failure 'failed append returned success'
case "$out" in *'cannot append confirmation'*) : ;; *) die test_report_write_failure "no write diagnostic: $out" ;; esac
[ -d "$NDJSON" ] || die test_report_write_failure 'fixture did not replace the report destination'
rmdir "$NDJSON"
pass test_report_write_failure

run_with "$P" >/dev/null || die test_listing_modes 'control failed'
before=$(cksum "$NDJSON")
rm -f "$RUNNER_RAN_MARKER"
for mode in --list-suites --list-subjects --list-hashes; do
  out=$(run_with "$P" "$mode"); rc=$?
  [ "$rc" -eq 0 ] || die test_listing_modes "$mode failed: $out"
  [ ! -e "$RUNNER_RAN_MARKER" ] || die test_listing_modes "$mode ran suites"
  [ "$before" = "$(cksum "$NDJSON")" ] || die test_listing_modes "$mode overwrote the report"
done
pass test_listing_modes

out=$(bash "$RG" --out 2>&1); rc=$?
[ "$rc" -eq 2 ] || die test_missing_output_argument 'missing --out value did not fail'
case "$out" in *'--out requires a path'*) : ;; *) die test_missing_output_argument "no usage diagnostic: $out" ;; esac
pass test_missing_output_argument

inventory=$(RUN_GUARDS_ONLY_EXTRA=0 RUN_GUARDS_EXTRA_SUITES='' bash "$RG" --list-suites) ||
  die test_canonical_suite_inventory 'enumeration failed'
for suite in adapter-semantics adapter-semantics-test; do
  count=$(printf '%s\n' "$inventory" | grep -Fxc "$suite")
  [ "$count" -eq 1 ] || die test_canonical_suite_inventory "$suite occurs $count times"
done
if printf '%s\n' "$inventory" | grep -q '^merge-policy'; then
  die test_canonical_suite_inventory 'retired aliases still registered'
fi
pass test_canonical_suite_inventory

printf 'run-guards selftest: all fixtures passed\n'
