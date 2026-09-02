#!/usr/bin/env bash
# Deterministic Sprint Loops substrate check — runs in front of phase routing.
# Prints exactly one of:
#   substrate-complete            (Book + ledgers + base/work + profile present,
#                                  stamped at this bundle's contract version)
#   substrate-absent              (no Book and no profile — a fresh project)
#   substrate-partial:<diagnostic> (some present; names what is missing)
#   substrate-outdated:<book>-><bundle> (complete, but behind this bundle)
#   substrate-ahead:<book>-><bundle>    (complete, but stamped ahead of it)
# A broken substrate outranks a stale one: substrate-partial is reported before
# either version state. Read-only. Exit 0 only for substrate-complete.
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

# Resolve the Book's substrate contract version. A malformed stamp is a broken
# substrate, not a stale one, so it joins the missing list rather than becoming
# a version state.
book_version=""
if [ "$book_state" = book-only ]; then
  book_version=$(book_substrate_version 2>/dev/null) || {
    missing="$missing book-substrate-version"
    book_version=""
  }
fi

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
if [ -n "$missing" ]; then
  printf 'substrate-partial:%s\n' "$missing"
  exit 1
fi

# Structurally complete. Everything below is a contract-version difference:
# behind this bundle is convergeable, ahead of it is refused (converging
# backwards would silently downgrade the project).
if [ "$book_version" -lt "$BOOK_SUBSTRATE_CONTRACT_VERSION" ]; then
  printf 'substrate-outdated:%s->%s\n' "$book_version" "$BOOK_SUBSTRATE_CONTRACT_VERSION"
  exit 1
fi
if [ "$book_version" -gt "$BOOK_SUBSTRATE_CONTRACT_VERSION" ]; then
  printf 'substrate-ahead:%s->%s\n' "$book_version" "$BOOK_SUBSTRATE_CONTRACT_VERSION"
  exit 1
fi
echo substrate-complete
exit 0
