#!/usr/bin/env bash
# Deterministic Sprint Loops substrate check — runs in front of phase routing.
# Prints exactly one of:
#   substrate-complete            (Book + ledgers + base/work + profile present)
#   substrate-absent              (no Book and no profile — a fresh project)
#   substrate-partial:<diagnostic> (some present; names what is missing)
# Read-only. Exit 0 only for substrate-complete.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT="${SPRINT_LOOP_PROJECT_ROOT:-.}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) SPRINT_LOOP_PROJECT_ROOT="$2"; shift 2 ;;
    *) break ;;
  esac
done
. "$SCRIPT_DIR/book-paths.sh"
ROOT="$SPRINT_LOOP_PROJECT_ROOT"

book_state=$(book_layout_state)

# Resolve the remote profile (best-effort; drives branch names).
profile_ok=0; base=""; work=""
if profile_out=$(bash "$SCRIPT_DIR/remote-profile.sh" --root "$ROOT" 2>/dev/null); then
  profile_ok=1
  base=$(printf '%s\n' "$profile_out" | sed -n 's/^BASE=//p')
  work=$(printf '%s\n' "$profile_out" | sed -n 's/^WORK=//p')
fi

# Fresh project: neither Book nor profile present at all.
if [ "$book_state" = none ] && [ "$profile_ok" -eq 0 ]; then
  echo substrate-absent
  exit 1
fi

missing=""

case "$book_state" in
  book-only)
    bash "$SCRIPT_DIR/check-book.sh" "$ROOT" >/dev/null 2>&1 || missing="$missing book-invalid" ;;
  none) missing="$missing book" ;;
  legacy-only) missing="$missing book-legacy" ;;
  conflict) missing="$missing book-split-brain" ;;
esac

[ -f "$BOOK_TASKS_FILE" ] || missing="$missing tasks-ledger"
[ -f "$BOOK_COMPLETED_TASKS_FILE" ] || missing="$missing completed-ledger"

if [ "$profile_ok" -eq 0 ]; then
  missing="$missing profile"
elif ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  missing="$missing git-repo"
else
  git -C "$ROOT" show-ref --verify --quiet "refs/heads/$base" || missing="$missing branch:$base"
  git -C "$ROOT" show-ref --verify --quiet "refs/heads/$work" || missing="$missing branch:$work"
fi

missing="${missing# }"
if [ -z "$missing" ]; then
  echo substrate-complete
  exit 0
fi
printf 'substrate-partial:%s\n' "$missing"
exit 1
