#!/usr/bin/env bash
# Prepend the lock header to build-plan.md and test-plan.md for the current sprint.
# Run this only after both plans are reviewed for local and global correctness.
set -euo pipefail

# Sibling scripts (current-sprint.sh, research-budget.sh) resolved relative to
# this file, so this works whether scripts/ lives in the project or in an
# installed skill bundle.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LAST=$("$SCRIPT_DIR/current-sprint.sh")
if [ "$LAST" = "-1" ]; then echo "no sprints found" >&2; exit 1; fi
D="sprints/s$LAST/sprint-plans"
RESEARCH="sprints/s$LAST/sprint-research/research-report.md"
HEADER="Finalized - DO NOT EDIT"

# Architectural-drift gate: if decisions.md has any entries (i.e. is non-empty
# beyond a possible title), the sprint's research-report must explicitly
# acknowledge them in a `## Decisions Reviewed` section. The check skips on
# new projects (no decisions.md) and sprint 0 (no ADRs yet).
if [ -s decisions.md ] && grep -qE '^## ' decisions.md 2>/dev/null; then
  if [ ! -s "$RESEARCH" ] || ! grep -qE '^## ([0-9]+\. *)?Decisions Reviewed' "$RESEARCH" 2>/dev/null; then
    echo "refusing to finalize: $RESEARCH lacks a \`## Decisions Reviewed\` section, but decisions.md has entries" >&2
    echo "  add the section to the research report listing which ADRs from decisions.md bear on this sprint" >&2
    exit 1
  fi
fi

# Research-budget gate: research-budget.sh exits non-zero when over budget
# (>20 files or >5 sources). When over, require a `## Budget Override` heading
# with at least one non-whitespace body line; otherwise refuse to lock.
if ! "$SCRIPT_DIR/research-budget.sh" >/dev/null 2>&1; then
  # Over budget — check for valid override.
  HAS_OVERRIDE=0
  if [ -s "$RESEARCH" ]; then
    OVERRIDE_BODY=$(awk '
      /^## Budget Override[[:space:]]*$/ { in_sec=1; next }
      in_sec && /^## / { in_sec=0 }
      in_sec { print }
    ' "$RESEARCH" | grep -cE '^[^[:space:]]' || true)
    if [ "${OVERRIDE_BODY:-0}" -gt 0 ]; then HAS_OVERRIDE=1; fi
  fi
  if [ "$HAS_OVERRIDE" = "0" ]; then
    BUDGET=$("$SCRIPT_DIR/research-budget.sh" 2>/dev/null || true)
    echo "refusing to finalize: research budget exceeded ($BUDGET; limits: files=20 sources=5)" >&2
    echo "  add a \`## Budget Override\` section to $RESEARCH with a non-empty justification, OR trim the report" >&2
    exit 1
  fi
fi

# Empty-plan gate, hoisted here (was inside the lock loop) so it runs BEFORE the
# critique gate — keeps selftest's empty-plan step isolating its own failure
# rather than tripping the critique gate first.
BP="$D/build-plan.md"
if [ ! -s "$BP" ]; then echo "missing or empty: $BP" >&2; exit 1; fi
# An empty build-plan (no `### T-XXX:` execution entries) would route the next
# phase to `build` and then never queue a task — infinite build loop.
if ! grep -qE '^### T-[0-9]+:' "$BP"; then
  echo "refusing to finalize build-plan.md: no \`### T-XXX:\` execution entries found" >&2
  exit 1
fi

# Critique gate (runs LAST, after empty-plan / decisions-reviewed / budget, so
# those gates keep isolating their own failures): the plan critic must have run
# and not blocked. `critique.md` must exist non-empty, carry a `## Concerns`
# heading, and its `## Confidence` verdict — the FIRST non-empty line after that
# heading — must start with `clean` or `proceed-with-caveats` (optionally
# backticked). A `block` verdict, a missing/malformed verdict, or a missing file
# refuses the lock. Line-scoped parse so prose mentioning "block" can't false-match.
CRIT="$D/critique.md"
CRIT_HELP="  run the plan critic (see phases/03-plan-phase.md) and record its verdict in critique.md"
if [ ! -s "$CRIT" ]; then
  echo "refusing to finalize: $CRIT missing or empty" >&2
  echo "$CRIT_HELP" >&2
  exit 1
fi
if ! grep -qE '^## Concerns' "$CRIT"; then
  echo "refusing to finalize: $CRIT lacks a \`## Concerns\` heading (malformed critique)" >&2
  echo "$CRIT_HELP" >&2
  exit 1
fi
# Extract the verdict line. Accept BOTH forms the phase docs model: inline
# (`## Confidence: clean`) and the heading-then-next-line form the critic
# prompts produce.
VLINE=$(awk '
  /^## Confidence:[[:space:]]*[^[:space:]]/ { sub(/^## Confidence:[[:space:]]*/, ""); print; exit }
  /^## Confidence/ { f=1; next }
  f && NF { print; exit }
' "$CRIT")
# Reduce to the bare verdict TOKEN: drop a leading backtick, cut at the first
# whitespace, drop a trailing backtick. Then EXACT-match — so `cleanish`,
# `blocked`, etc. do not slip through a prefix glob.
VERDICT=$(printf '%s\n' "$VLINE" | sed -e 's/^`//' -e 's/[[:space:]].*$//' -e 's/`$//')
case "$VERDICT" in
  clean|proceed-with-caveats)
    : ;;  # critic cleared the plan — proceed to lock
  block)
    echo "refusing to finalize: plan critique verdict is \`block\` — fix the concerns and re-critique" >&2
    exit 1 ;;
  *)
    echo "refusing to finalize: $CRIT has no recognizable \`## Confidence\` verdict" >&2
    echo "  the verdict (inline after \`## Confidence:\` or on the next non-empty line) must be exactly clean, proceed-with-caveats, or block (optionally backticked)" >&2
    exit 1 ;;
esac

for f in build-plan.md test-plan.md; do
  P="$D/$f"
  if [ ! -s "$P" ]; then echo "missing or empty: $P" >&2; exit 1; fi
  if head -n1 "$P" | grep -qF "$HEADER"; then
    echo "$f already finalized"
  else
    { printf '%s\n\n' "$HEADER"; cat "$P"; } > "$P.tmp" && mv "$P.tmp" "$P"
    echo "finalized $f"
  fi
done
