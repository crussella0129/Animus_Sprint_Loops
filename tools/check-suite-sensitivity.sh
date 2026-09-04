#!/usr/bin/env bash
# Check coupling to each suite's subject, using a passing committed baseline.
# This is a floor, not a proof: subtle wrong answers may still go undetected.
# Usage: check-suite-sensitivity.sh [--report <ndjson>] [suite...]
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT="$ROOT/guards-report.ndjson"
SELECTED=""
fatal() { printf 'check-suite-sensitivity: %s\n' "$*" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --report) [ $# -ge 2 ] && [ -n "$2" ] || fatal '--report requires a path'; REPORT="$2"; shift 2 ;;
    -*) fatal "unsupported option: $1" ;;
    *) SELECTED="$SELECTED $1"; shift ;;
  esac
done
[ -r "$REPORT" ] || fatal "no guard report at $REPORT; run tools/run-guards.sh --committed first"
REPORT="$(cd "$(dirname "$REPORT")" && pwd)/$(basename "$REPORT")"
SOURCE_TREE=$(git -C "$ROOT" rev-parse 'HEAD^{tree}') || fatal 'cannot resolve HEAD tree'
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-sensitivity.XXXXXX") || fatal 'cannot allocate work directory'
trap 'rm -rf "$TMP_ROOT"' EXIT
trap 'exit 130' HUP INT TERM
TMP_ROOT=$(cd "$TMP_ROOT" && pwd -P) || fatal 'cannot resolve physical work directory'
PRISTINE="$TMP_ROOT/pristine"
mkdir -p "$PRISTINE" || fatal 'cannot create archive directory'
git -C "$ROOT" archive "$SOURCE_TREE" | tar -x -C "$PRISTINE" || fatal 'could not extract HEAD'

# Validate the canonical runner's compact NDJSON protocol before extraction.
# A grep hit, partial row, or last-of-several confirmation is not evidence.
# confirmation <file> <suite> -> status script_hash source_tree determinism
confirmation() {
  [ -r "$1" ] || return 1
  awk -v wanted="$2" '
    {
      sub(/\r$/, "")
      if ($0 !~ /^\{"suite":"[a-zA-Z0-9_.:-]+","script_hash":"[0-9a-f]+","source_tree":"[a-zA-Z0-9-]+","status":"(PASS|FAIL)","evidence_hash":"[0-9a-f]+","duration_s":[0-9]+,"ts":"[0-9-]+T[0-9:]+Z"(,"determinism":"(ok|mismatch)")?\}$/) { bad=1; next }
      split($0, f, "\"")
      if (length(f[8]) != 64 || length(f[20]) != 64) { bad=1; next }
      if (f[12] != "working-tree" && length(f[12]) != 40 && length(f[12]) != 64) { bad=1; next }
      if (f[4] == wanted) {
        count++
        row=f[16] " " f[8] " " f[12] " " (f[28] == "determinism" ? f[30] : "none")
      }
    }
    END { if (bad || count != 1) exit 1; print row }
  ' "$1"
}

archive_runner() { (cd "$PRISTINE" && bash tools/run-guards.sh "$@"); }
# Unknown names are errors, not subjectless suites. Avoid expanding an empty
# array under set -u on stock macOS Bash 3.2.
args=()
for suite in $SELECTED; do args+=("$suite"); done
if [ "${#args[@]}" -gt 0 ]; then
  SUITES=$(archive_runner --list-suites "${args[@]}") || fatal 'cannot enumerate requested suites'
else
  SUITES=$(archive_runner --list-suites) || fatal 'cannot enumerate suites'
fi
SUBJECTS=$(archive_runner --list-subjects) || fatal 'cannot enumerate subjects'
HASHES=$(archive_runner --list-hashes) || fatal 'cannot fingerprint suites'

work="$TMP_ROOT/work"
cp -R "$PRISTINE" "$work" || fatal 'cannot create mutation copy'
insensitive=""
unscorable=""
scored=0
printf '%-24s %-14s %s\n' SUITE VERDICT SUBJECT

for suite in $SUITES; do
  subject=$(printf '%s\n' "$SUBJECTS" | awk -v s="$suite" '$1 == s { print $2; exit }')
  if [ -z "$subject" ]; then
    printf '%-24s %-14s %s\n' "$suite" no-subject '(no single subject)'
    continue
  fi
  if [ "$subject" = tools/run-guards.sh ]; then
    printf '%-24s %-14s %s\n' "$suite" skipped 'harness-subject (scored by its own fixtures)'
    continue
  fi

  reason=""
  record=$(confirmation "$REPORT" "$suite") || reason='baseline-invalid (missing, malformed, or duplicate confirmation)'
  if [ -z "$reason" ]; then
    read -r status script_hash source_tree determinism <<< "$record"
    expected_hash=$(printf '%s\n' "$HASHES" | awk -v s="$suite" '$1 == s { print $2; exit }')
    if [ "$status" != PASS ]; then reason="baseline-not-pass ($status)"
    elif [ "$determinism" = mismatch ]; then reason='baseline-nondeterministic'
    elif [ "$source_tree" != "$SOURCE_TREE" ]; then reason='baseline-source-mismatch (use a current --committed report)'
    elif [ "$script_hash" != "$expected_hash" ]; then reason='baseline-script-mismatch'
    fi
  fi
  if [ -n "$reason" ]; then
    printf '%-24s %-14s %s\n' "$suite" unscorable "$reason"
    unscorable="$unscorable $suite"
    continue
  fi

  # Never follow a subject declaration out of the archive or through symlinks.
  case "$subject" in /*|[A-Za-z]:*|..|../*|*/../*|*/..)
    fatal "subject is outside the archive: $subject" ;;
  esac
  subject_parent=$(cd "$work/$(dirname "$subject")" && pwd -P) || fatal "missing subject parent: $subject"
  case "$subject_parent/" in "$work/"*) : ;; *) fatal "subject parent escapes archive: $subject" ;; esac
  [ -f "$PRISTINE/$subject" ] && [ ! -L "$work/$subject" ] || fatal "invalid subject: $subject"

  printf '#!/usr/bin/env bash\n# neutered by check-suite-sensitivity.sh\nexit 0\n' > "$work/$subject" || fatal "cannot neuter $subject"
  rm -f "$TMP_ROOT/neutered.ndjson"
  (cd "$work" && bash tools/run-guards.sh --out "$TMP_ROOT/neutered.ndjson" "$suite") >"$TMP_ROOT/neutered.log" 2>&1
  neutered_rc=$?
  # Restore before any verdict/continue. A shared subject does not make two
  # different suites interchangeable; each needs an independent observation.
  cp -p "$PRISTINE/$subject" "$work/$subject" || fatal "cannot restore $subject"

  record=$(confirmation "$TMP_ROOT/neutered.ndjson" "$suite") || record=""
  if [ -n "$record" ]; then
    read -r status mutated_hash _tree determinism <<< "$record"
  fi
  if [ -z "$record" ] || [ "$mutated_hash" != "$script_hash" ] ||
      [ "$determinism" = mismatch ] ||
      { [ "$neutered_rc" -eq 0 ] && [ "$status" != PASS ]; } ||
      { [ "$neutered_rc" -ne 0 ] && { [ "$neutered_rc" -ne 1 ] || [ "$status" != FAIL ]; }; }; then
    printf '%-24s %-14s %s\n' "$suite" unscorable "no valid mutated confirmation (rc=$neutered_rc)"
    cat "$TMP_ROOT/neutered.log" >&2
    unscorable="$unscorable $suite"
    continue
  fi
  if [ "$status" = PASS ]; then
    printf '%-24s %-14s %s\n' "$suite" INSENSITIVE "$subject"
    insensitive="$insensitive $suite"
  else
    printf '%-24s %-14s %s\n' "$suite" sensitive "$subject"
  fi
  scored=$((scored + 1))
done

if [ -n "$insensitive" ] || [ -n "$unscorable" ]; then
  [ -z "$insensitive" ] || echo "check-suite-sensitivity: suites PASS with their subject neutered:$insensitive" >&2
  [ -z "$unscorable" ] || echo "check-suite-sensitivity: suites could not be scored:$unscorable" >&2
  exit 1
fi
echo "check-suite-sensitivity: $scored suites scored, all fail when their subject is neutered"
echo '  (a floor, not a proof: this shows coupling, not that a subtly wrong answer would be caught)'
