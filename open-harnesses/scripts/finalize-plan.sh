#!/usr/bin/env bash
# Validate Book planning evidence, then lock both plans as one transaction.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/book-paths.sh"
book_require_v2_layout

LAST=$("$SCRIPT_DIR/current-sprint.sh")
if [ "$LAST" = -1 ]; then echo "no sprints found" >&2; exit 1; fi
D="$BOOK_SPRINTS_DIR/s$LAST/sprint-plans"
RESEARCH="$BOOK_SPRINTS_DIR/s$LAST/sprint-research/research-report.md"
BP="$D/build-plan.md"
TP="$D/test-plan.md"
CRIT="$D/critique.md"
HEADER="Finalized - DO NOT EDIT"

# A legacy ADR acknowledgement is not a substitute for reviewing stable Book
# intent. Numeric prefixes are tolerated to match the existing report schema.
HAS_INTENT_REVIEW=0
if [ -s "$RESEARCH" ] &&
   grep -qE '^## ([0-9]+[.] *)?Intents Reviewed[[:space:]]*$' "$RESEARCH"; then
  HAS_INTENT_REVIEW=1
fi
if [ "$HAS_INTENT_REVIEW" = 0 ] && [ -s "$RESEARCH" ] &&
   grep -qE '^## ([0-9]+[.] *)?Decisions Reviewed[[:space:]]*$' "$RESEARCH"; then
  echo 'refusing to finalize: legacy `## Decisions Reviewed` does not review Book intent' >&2
  echo '  migrate that section to `## Intents Reviewed` and list the relevant INT-NNNN chapters' >&2
  exit 1
fi

HAS_INTENTS=0
for INTENT in "$BOOK_INTENTS_DIR"/INT-[0-9][0-9][0-9][0-9]-*.md; do
  if [ -f "$INTENT" ]; then HAS_INTENTS=1; break; fi
done
if [ "$HAS_INTENTS" = 1 ] && [ "$HAS_INTENT_REVIEW" = 0 ]; then
  printf 'refusing to finalize: %s lacks a `## Intents Reviewed` section\n' "$RESEARCH" >&2
  echo "  list the INT-NNNN chapters that bear on this sprint before locking the plans" >&2
  exit 1
fi

# Preserve the existing research-budget gate and its explicit override.
if ! "$SCRIPT_DIR/research-budget.sh" >/dev/null 2>&1; then
  HAS_OVERRIDE=0
  if [ -s "$RESEARCH" ]; then
    OVERRIDE_BODY=$(awk '
      /^## Budget Override[[:space:]]*$/ { in_sec=1; next }
      in_sec && /^## / { in_sec=0 }
      in_sec { print }
    ' "$RESEARCH" | grep -cE '^[^[:space:]]' || true)
    if [ "${OVERRIDE_BODY:-0}" -gt 0 ]; then HAS_OVERRIDE=1; fi
  fi
  if [ "$HAS_OVERRIDE" = 0 ]; then
    BUDGET=$("$SCRIPT_DIR/research-budget.sh" 2>/dev/null || true)
    echo "refusing to finalize: research budget exceeded ($BUDGET; limits: files=20 sources=5)" >&2
    printf '  add a `## Budget Override` section to %s with a non-empty justification, OR trim the report\n' "$RESEARCH" >&2
    exit 1
  fi
fi

# Prevalidate both files before creating or moving a lock candidate.
for PLAN in "$BP" "$TP"; do
  if [ ! -s "$PLAN" ]; then echo "missing or empty: $PLAN" >&2; exit 1; fi
done
if ! grep -qE '^### T-[0-9]+:' "$BP"; then
  echo 'refusing to finalize build-plan.md: no `### T-XXX:` execution entries found' >&2
  exit 1
fi

BP_LOCKED=0
TP_LOCKED=0
awk -v header="$HEADER" 'NR == 1 { sub(/\r$/, ""); exit !($0 == header) }' "$BP" && BP_LOCKED=1
awk -v header="$HEADER" 'NR == 1 { sub(/\r$/, ""); exit !($0 == header) }' "$TP" && TP_LOCKED=1
if [ "$BP_LOCKED" != "$TP_LOCKED" ]; then
  echo "refusing to finalize: plans are partially locked; restore a consistent pair before retrying" >&2
  exit 1
fi

CRIT_HELP="  run the plan critic and record its verdict in critique.md"
if [ ! -s "$CRIT" ]; then
  echo "refusing to finalize: $CRIT missing or empty" >&2
  echo "$CRIT_HELP" >&2
  exit 1
fi
if ! grep -qE '^## ([0-9]+[.] *)?Concerns[[:space:]]*$' "$CRIT"; then
  printf 'refusing to finalize: %s lacks a `## Concerns` heading (malformed critique)\n' "$CRIT" >&2
  echo "$CRIT_HELP" >&2
  exit 1
fi
VLINE=$(awk '
  {
    line=$0
    sub(/\r$/, "", line)
  }
  line ~ /^## ([0-9]+[.] *)?Confidence:[[:space:]]*[^[:space:]]+[[:space:]]*$/ {
    sub(/^## ([0-9]+[.] *)?Confidence:[[:space:]]*/, "", line)
    print line
    exit
  }
  line ~ /^## ([0-9]+[.] *)?Confidence[[:space:]]*$/ { found=1; next }
  found && line ~ /^## / { exit }
  found && line ~ /[^[:space:]]/ { print line; exit }
' "$CRIT")
VERDICT=$(printf '%s\n' "$VLINE" |
  sed -e 's/^`//' -e 's/[[:space:]].*$//' -e 's/`$//')
case "$VERDICT" in
  clean|proceed-with-caveats) : ;;
  block)
    echo 'refusing to finalize: plan critique verdict is `block` — fix the concerns and re-critique' >&2
    exit 1
    ;;
  *)
    printf 'refusing to finalize: %s has no recognizable `## Confidence` verdict\n' "$CRIT" >&2
    echo "  verdict must be exactly clean, proceed-with-caveats, or block" >&2
    exit 1
    ;;
esac

if [ "$BP_LOCKED" = 1 ] && [ "$TP_LOCKED" = 1 ]; then
  echo "build-plan.md already finalized"
  echo "test-plan.md already finalized"
  exit 0
fi

# Prepare both candidates and both backups first. Until both replacements have
# completed, any error or caught signal restores the original pair.
BP_TMP="$BP.tmp.$$"
TP_TMP="$TP.tmp.$$"
BP_BACKUP="$BP.lock-backup.$$"
TP_BACKUP="$TP.lock-backup.$$"
TRANSACTION_COMPLETE=0
cleanup() {
  cleanup_status=$?
  trap - EXIT HUP INT TERM
  rollback_failed=0
  if [ "$TRANSACTION_COMPLETE" -eq 0 ]; then
    if [ -f "$BP_BACKUP" ]; then mv "$BP_BACKUP" "$BP" || rollback_failed=1; fi
    if [ -f "$TP_BACKUP" ]; then mv "$TP_BACKUP" "$TP" || rollback_failed=1; fi
  fi
  rm -f "$BP_TMP" "$TP_TMP" "$BP_BACKUP" "$TP_BACKUP"
  if [ "$rollback_failed" -ne 0 ]; then
    echo "plan lock rollback failed; inspect $D before retrying" >&2
    exit 2
  fi
  exit "$cleanup_status"
}
on_signal() { exit 130; }
trap cleanup EXIT
trap on_signal HUP INT TERM
if awk 'NR == 1 { exit !(substr($0, length($0), 1) == "\r") }' "$BP"; then
  { printf '%s\r\n\r\n' "$HEADER"; cat "$BP"; } > "$BP_TMP"
else
  { printf '%s\n\n' "$HEADER"; cat "$BP"; } > "$BP_TMP"
fi
if awk 'NR == 1 { exit !(substr($0, length($0), 1) == "\r") }' "$TP"; then
  { printf '%s\r\n\r\n' "$HEADER"; cat "$TP"; } > "$TP_TMP"
else
  { printf '%s\n\n' "$HEADER"; cat "$TP"; } > "$TP_TMP"
fi
cp "$BP" "$BP_BACKUP"
cp "$TP" "$TP_BACKUP"
if ! mv "$BP_TMP" "$BP"; then
  echo "failed to lock build-plan.md; neither plan was changed" >&2
  exit 1
fi
if ! mv "$TP_TMP" "$TP"; then
  echo "failed to lock test-plan.md; both plans will be rolled back" >&2
  exit 1
fi
TRANSACTION_COMPLETE=1
rm -f "$BP_BACKUP" "$TP_BACKUP"
trap - EXIT HUP INT TERM
echo "finalized build-plan.md"
echo "finalized test-plan.md"
