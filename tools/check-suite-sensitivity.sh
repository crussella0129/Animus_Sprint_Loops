#!/usr/bin/env bash
# Require every guard suite to FAIL when the script it tests is neutered.
#
# Four consecutive sprints shipped a fixture that passed while the property it
# named did not hold, and every one was caught by a later, more expensive
# reviewer rather than by the suite. This is the cheap mechanical floor under
# that: replace a suite's subject with a stub that exits 0 and prints nothing,
# run the suite, and require it to fail. A suite that still passes is asserting
# something that does not depend on its subject.
#
# WHAT THIS DOES NOT PROVE. It establishes that a suite is coupled to its
# subject at all. It does not establish that the suite would notice a subtly
# wrong answer. Sprint 20 shipped a generated `pytest` tolerance that was dead
# code under `set -e`, and the fixture that missed it was still coupled to the
# generator, so this check would have passed it. Treat a clean run as a floor,
# never as evidence that the suites are good.
#
# The run happens in a copy of the repository extracted from HEAD, never in the
# working tree, for two reasons: a crash must not leave a stubbed script behind,
# and a suite that resolves the repository root from its own location has to
# find a real one. A scripts-only copy was tried first and silently broke three
# `tools/` suites' root resolution, which would have scored them "sensitive" for
# entirely the wrong reason.
#
# Because only committed content is copied, this checks HEAD, not the working
# tree. That matches the corpus's committed-evidence discipline: a suite that
# only exists uncommitted is not yet evidence of anything.
#
# The baseline comes from a guard report rather than a control run per suite:
# run-guards.sh already establishes that each suite passes, one suite in the
# list exceeds 120s, and doubling the runner is the cost T-163 exists to avoid.
# Asking whether a *failing* suite is sensitive is not a meaningful question, so
# such a suite is skipped and named rather than scored.
#
# Usage: check-suite-sensitivity.sh [--report <ndjson>] [suite...]
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT="$ROOT/guards-report.ndjson"
SELECTED=""
while [ $# -gt 0 ]; do
  case "$1" in
    --report) REPORT="$2"; shift 2 ;;
    -*) echo "usage: $(basename "$0") [--report <ndjson>] [suite...]" >&2; exit 2 ;;
    *) SELECTED="$SELECTED $1"; shift ;;
  esac
done

command -v git >/dev/null 2>&1 || { echo "check-suite-sensitivity: git is required" >&2; exit 2; }
[ -r "$REPORT" ] || {
  echo "check-suite-sensitivity: no guard report at $REPORT" >&2
  echo "  run 'bash tools/run-guards.sh' first; its baseline is what makes a" >&2
  echo "  neutered result meaningful" >&2
  exit 2
}

TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-sensitivity.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM

PRISTINE="$TMP_ROOT/pristine"
mkdir -p "$PRISTINE"
git -C "$ROOT" archive HEAD | tar -x -C "$PRISTINE" ||
  { echo "check-suite-sensitivity: could not extract HEAD" >&2; exit 2; }

# baseline_status <suite> — PASS, or whatever the report recorded, or "absent".
baseline_status() {
  awk -v s="$1" '
    index($0, "\"suite\":\"" s "\"") {
      if (match($0, /"status":"[A-Z]+"/)) {
        v = substr($0, RSTART + 10, RLENGTH - 11)
        print v; found = 1
      }
    }
    END { if (!found) print "absent" }
  ' "$REPORT" | tail -n 1
}

if [ -n "$SELECTED" ]; then
  SUITES=$(printf '%s\n' $SELECTED)
else
  SUITES=$(bash "$ROOT/tools/run-guards.sh" --list-suites)
fi
SUBJECTS=$(bash "$ROOT/tools/run-guards.sh" --list-subjects)

insensitive=""
scored=0
printf '%-24s %-14s %s\n' "SUITE" "VERDICT" "SUBJECT"
printf '%-24s %-14s %s\n' "------------------------" "--------------" "-------"

for suite in $SUITES; do
  subject=$(printf '%s\n' "$SUBJECTS" | awk -v s="$suite" '$1 == s { print $2; exit }')
  if [ -z "$subject" ]; then
    printf '%-24s %-14s %s\n' "$suite" "no-subject" "(is its own subject)"
    continue
  fi
  # The harness runs each suite THROUGH run-guards.sh, so a suite whose subject
  # is run-guards.sh itself cannot be scored here: neutering the subject also
  # neuters the harness, every suite "passes", and the verdict would be a false
  # INSENSITIVE. Naming that is the honest answer; guessing would not be.
  if [ "$subject" = tools/run-guards.sh ]; then
    printf '%-24s %-14s %s\n' "$suite" "skipped" "harness-subject (scored by its own fixtures)"
    continue
  fi
  status=$(baseline_status "$suite")
  if [ "$status" != PASS ]; then
    printf '%-24s %-14s %s\n' "$suite" "skipped" "baseline-not-pass ($status)"
    continue
  fi

  work="$TMP_ROOT/work"
  rm -rf "$work"
  cp -r "$PRISTINE" "$work"
  [ -f "$work/$subject" ] || {
    printf '%-24s %-14s %s\n' "$suite" "skipped" "subject absent at HEAD: $subject"
    continue
  }
  printf '#!/usr/bin/env bash\n# neutered by check-suite-sensitivity.sh\nexit 0\n' > "$work/$subject"
  chmod +x "$work/$subject"

  if (cd "$work" && bash tools/run-guards.sh --out "$TMP_ROOT/neutered.ndjson" "$suite") >/dev/null 2>&1; then
    printf '%-24s %-14s %s\n' "$suite" "INSENSITIVE" "$subject"
    insensitive="$insensitive $suite"
  else
    printf '%-24s %-14s %s\n' "$suite" "sensitive" "$subject"
  fi
  scored=$((scored + 1))
done

echo
if [ -n "$insensitive" ]; then
  echo "check-suite-sensitivity: these suites PASS with their subject neutered:$insensitive" >&2
  echo "  each is asserting something that does not depend on the script it tests" >&2
  exit 1
fi
echo "check-suite-sensitivity: $scored suites scored, all fail when their subject is neutered"
echo "  (a floor, not a proof: this shows coupling, not that a subtly wrong answer would be caught)"
