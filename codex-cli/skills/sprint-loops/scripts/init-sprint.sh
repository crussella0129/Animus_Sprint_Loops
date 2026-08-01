#!/usr/bin/env bash
# Create or extend the tracked Sprint Loops Book, then initialize the next sprint.
# Use --scaffold-only to create/refresh Book navigation without creating a sprint.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/book-paths.sh"

MODE=${1:-}
if [ "$#" -gt 1 ]; then echo "usage: $(basename "$0") [--scaffold-only]" >&2; exit 1; fi
case "$MODE" in ''|--scaffold-only) ;; *) echo "usage: $(basename "$0") [--scaffold-only]" >&2; exit 1 ;; esac

case "$(book_layout_state)" in
  conflict) printf '%s\n' "$BOOK_SPLIT_BRAIN_DIAGNOSTIC" >&2; exit 1 ;;
  legacy-only)
    printf '%s\n' "$BOOK_LEGACY_ONLY_DIAGNOSTIC" >&2
    printf 'run %s/migrate-to-book.sh before initialization\n' "$SCRIPT_DIR" >&2
    exit 1
    ;;
  book-only) book_marker_is_v2 || { printf '%s\n' "$BOOK_MARKER_DIAGNOSTIC" >&2; exit 1; } ;;
esac

mkdir -p "$BOOK_INTENTS_DIR" "$BOOK_WORK_DIR" "$BOOK_SPRINTS_DIR" "$BOOK_HISTORY_DIR"

if [ ! -f "$BOOK_README" ]; then
  cat > "$BOOK_README" <<'EOF'
# Project Book

This directory is the canonical Sprint Loops Book: project intent, executable
work, realization evidence, and sprint provenance live here together.
EOF
fi
if [ ! -f "$BOOK_INTENTS_DIR/README.md" ]; then
  cat > "$BOOK_INTENTS_DIR/README.md" <<'EOF'
# Project Intents

Intent chapters use stable `INT-NNNN` identifiers and move through `proposed`,
`planned`, `active`, `deferred`, `realized`, `superseded`, or `abandoned`.
See the installed Sprint Loops `schemas/intent.md` contract before authoring one.
EOF
fi
[ -f "$BOOK_TASKS_FILE" ] || printf '# Agent Tasks (Persistent Backlog)\n' > "$BOOK_TASKS_FILE"
[ -f "$BOOK_COMPLETED_TASKS_FILE" ] || printf '# Completed Tasks Log (Append-Only)\n' > "$BOOK_COMPLETED_TASKS_FILE"
[ -f "$BOOK_CONFIDENCE_FILE" ] || printf '1.0\n' > "$BOOK_CONFIDENCE_FILE"
[ -s "$BOOK_SUMMARY" ] || printf '# Summary\n' > "$BOOK_SUMMARY"

ensure_summary_line() {
  summary_line=$1
  if awk -v wanted="$summary_line" '
    {
      line=$0
      sub(/\r$/, "", line)
      if (line == wanted) found=1
    }
    END { exit !found }
  ' "$BOOK_SUMMARY"; then
    return
  fi
  if [ -s "$BOOK_SUMMARY" ] &&
    [ "$(tail -c 1 "$BOOK_SUMMARY" | wc -l | tr -d '[:space:]')" -eq 0 ]; then
    printf '\n' >> "$BOOK_SUMMARY"
  fi
  printf '%s\n' "$summary_line" >> "$BOOK_SUMMARY"
}
ensure_summary_line '- [Project Book](README.md)'
ensure_summary_line '- [Intents](intents/README.md)'
ensure_summary_line '- [Tasks](work/tasks.md)'
ensure_summary_line '- [Completed tasks](work/completed-tasks.md)'
for sprint_dir in "$BOOK_SPRINTS_DIR"/s*/; do
  [ -d "$sprint_dir" ] || continue
  sprint_name=${sprint_dir%/}; sprint_name=${sprint_name##*/}; sprint_number=${sprint_name#s}
  case "$sprint_number" in ''|*[!0-9]*) continue ;; esac
  ensure_summary_line "- [Sprint $sprint_number](sprints/s$sprint_number/sprint-meta.md)"
done

if [ ! -e "$BOOK_MARKER" ]; then
  marker_tmp="$BOOK_MARKER.tmp.$$"
  printf 'schema-version: 2\n' > "$marker_tmp"
  mv "$marker_tmp" "$BOOK_MARKER"
fi

# Replace only the owned marker block; preserve every line outside it and keep
# the tracked Book visible to Git. The only default ignore is transient output.
GITIGNORE=$(book_join_root .gitignore)
gitignore_tmp="$GITIGNORE.tmp.$$"
if [ -f "$GITIGNORE" ]; then
  awk '
    {
      line=$0
      sub(/\r$/, "", line)
      if (line == "# >>> sprint-loops >>>") { owned=1; next }
      if (line == "# <<< sprint-loops <<<") { owned=0; next }
      if (!owned) print
    }
  ' "$GITIGNORE" > "$gitignore_tmp"
else
  : > "$gitignore_tmp"
fi
cat >> "$gitignore_tmp" <<'EOF'
# >>> sprint-loops >>>
# The Book is tracked. Ignore only transient helper output.
*.tmp
/guards-report.ndjson
# <<< sprint-loops <<<
EOF
mv "$gitignore_tmp" "$GITIGNORE"

book_require_v2_layout
if [ "$MODE" = --scaffold-only ]; then
  echo "Book scaffold ready at $BOOK_ROOT"
  exit 0
fi

LAST=$("$SCRIPT_DIR/current-sprint.sh")
if [ "$LAST" = -1 ]; then N=0; else N=$((LAST + 1)); fi
D="$BOOK_SPRINTS_DIR/s$N"
[ ! -e "$D" ] || { echo "sprint $N already exists at $D" >&2; exit 1; }
mkdir -p "$D/sprint-research" "$D/sprint-plans" "$D/sprint-tests"
: > "$D/sprint-research/research-report.md"
: > "$D/sprint-plans/build-plan.md"
: > "$D/sprint-plans/test-plan.md"
: > "$D/sprint-tests/unit-tests.md"
: > "$D/sprint-tests/integration-tests.md"
: > "$D/sprint-tests/e2e-tests.md"
: > "$D/sprint-tests/test-report.md"

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MODEL=${SPRINT_MODEL:-unknown}
cat > "$D/sprint-meta.md" <<EOF
# Sprint $N Meta

- **Sprint number:** $N
- **Book schema version:** 2
- **Start timestamp:** $TS
- **End timestamp:** (filled at Loop Phase)
- **Model:** $MODEL
- **Exit status:** in-progress
- **Token count:** (filled at Loop Phase if observable)
- **Summary:** (one-line description of sprint goal, filled after Plan Phase)
- **Intents:** (filled after Plan Phase)
- **Completion evidence:** (filled at Loop Phase)
EOF
ensure_summary_line "- [Sprint $N](sprints/s$N/sprint-meta.md)"

echo "Initialized sprint $N at $D"
