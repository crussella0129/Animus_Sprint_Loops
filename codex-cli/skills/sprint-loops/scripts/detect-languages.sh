#!/usr/bin/env bash
# Print the language tokens a project contains, one per line.
#
# Manifest-driven and sorted, deliberately: the canonical guard runner compares
# normalized output across two runs, so detection must not depend on filesystem
# ordering. Presence of a manifest is the signal — this answers "what is this
# project written in", not "what does it intend to become", which is a Book
# question and belongs to the reconciliation half of the intent.
#
# Shell detection prefers git's index so untracked scratch files do not decide a
# project's languages.
#
# A project that already has a canonical suite runner additionally yields a
# `canonical:<path>` token, because a generated configuration should invoke the
# project's own suite rather than guessing per-language commands.
#
# Read-only. Usage: detect-languages.sh [--root <dir>]
# Prints nothing and exits 0 for a project with no recognized manifest.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT="${SPRINT_LOOP_PROJECT_ROOT:-.}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) SPRINT_LOOP_PROJECT_ROOT="$2"; shift 2 ;;
    *) echo "detect-languages: unknown argument $1" >&2; exit 2 ;;
  esac
done
. "$SCRIPT_DIR/book-paths.sh"
ROOT="$SPRINT_LOOP_PROJECT_ROOT"

CANONICAL_RUNNER="tools/run-guards.sh"

detected=""
note() { detected="${detected}$1
"; }

[ -f "$ROOT/Cargo.toml" ] && note rust
[ -f "$ROOT/go.mod" ] && note go
if [ -f "$ROOT/pyproject.toml" ] || [ -f "$ROOT/requirements.txt" ] || [ -f "$ROOT/setup.py" ]; then
  note python
fi
[ -f "$ROOT/package.json" ] && note node

if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  if [ -n "$(git -C "$ROOT" ls-files -- '*.sh' 2>/dev/null | head -n 1)" ]; then
    note shell
  fi
elif [ -n "$(find "$ROOT" -name '*.sh' -not -path '*/.git/*' 2>/dev/null | head -n 1)" ]; then
  note shell
fi

if [ -n "$detected" ]; then
  printf '%s' "$detected" | LC_ALL=C sort
fi

# The canonical token trails the sorted language set so its presence never
# reorders the languages.
[ -f "$ROOT/$CANONICAL_RUNNER" ] && printf 'canonical:%s\n' "$CANONICAL_RUNNER"

exit 0
