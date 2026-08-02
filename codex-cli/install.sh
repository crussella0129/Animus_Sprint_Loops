#!/usr/bin/env bash
# Transactional installer for the standalone Codex sprint-loops skill.
# Usage: bash codex-cli/install.sh [--project]
set -euo pipefail

usage() {
  echo "usage: $(basename "$0") [--project]" >&2
  echo "  no argument: install for this user under \$HOME/.agents/skills" >&2
  echo "  --project:  install at the current Git/workspace root under .agents/skills" >&2
}

case "$#" in
  0) SCOPE=user ;;
  1)
    [ "$1" = --project ] || { usage; exit 2; }
    SCOPE=project
    ;;
  *) usage; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/skills/sprint-loops"
if [ ! -f "$SKILL_SRC/SKILL.md" ]; then
  echo "install source is incomplete: $SKILL_SRC/SKILL.md is missing" >&2
  exit 1
fi

if [ "$SCOPE" = project ]; then
  if command -v git >/dev/null 2>&1 &&
     PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
    :
  else
    PROJECT_ROOT=$(pwd -P)
  fi
  case "$PROJECT_ROOT" in
    / | /[A-Za-z] | /mnt/[A-Za-z] | [A-Za-z]: | [A-Za-z]:/)
      echo "refusing project install at a filesystem or drive root: $PROJECT_ROOT" >&2
      exit 1
      ;;
  esac
  SKILLS_DIR="$PROJECT_ROOT/.agents/skills"
else
  : "${HOME:?HOME must be set for a user install}"
  SKILLS_DIR="$HOME/.agents/skills"
fi

mkdir -p "$SKILLS_DIR"
SKILLS_DIR="$(cd "$SKILLS_DIR" && pwd -P)"
SKILL_DST="$SKILLS_DIR/sprint-loops"
LOCK="$SKILLS_DIR/.sprint-loops.install.lock"
LOCK_OWNER_FILE="$LOCK/owner"
STAGE="$SKILLS_DIR/.sprint-loops.install.$$"
BACKUP="$SKILLS_DIR/.sprint-loops.backup.$$"
OWNER_MARKER=.sprint-loops.install-owner
TRANSACTION_ID="$$-${RANDOM}-${RANDOM}"
LOCK_HELD=0
OLD_MOVED=0
ACTIVATING=0
COMMITTED=0

path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

if path_exists "$SKILL_SRC/$OWNER_MARKER"; then
  echo "install source uses reserved transaction marker: $OWNER_MARKER" >&2
  exit 1
fi

finish() {
  local status=$1
  local cleanup_failed=0
  local lock_owner=$TRANSACTION_ID
  local destination_owner=
  trap - EXIT HUP INT TERM

  # Before the commit point, quarantine only a destination known to have come
  # from this transaction. An unexpected destination is never deleted.
  if [ "$COMMITTED" -eq 0 ] && [ "$ACTIVATING" -eq 1 ] &&
     ! path_exists "$STAGE" && path_exists "$SKILL_DST"; then
    if [ -f "$SKILL_DST/$OWNER_MARKER" ] &&
       [ ! -L "$SKILL_DST/$OWNER_MARKER" ]; then
      IFS= read -r destination_owner < "$SKILL_DST/$OWNER_MARKER" ||
        destination_owner=
    fi
    if [ "$destination_owner" != "$TRANSACTION_ID" ]; then
      echo "rollback found an unowned destination; preserving it and any backup under $LOCK" >&2
      cleanup_failed=1
    elif ! mv "$SKILL_DST" "$STAGE"; then
      echo "rollback could not quarantine the interrupted install at $SKILL_DST" >&2
      cleanup_failed=1
    fi
  fi

  # Restore known-good content before attempting fallible staging cleanup.
  if [ "$COMMITTED" -eq 0 ] && [ "$OLD_MOVED" -eq 1 ] &&
     path_exists "$BACKUP"; then
    if ! path_exists "$SKILL_DST"; then
      if mv "$BACKUP" "$SKILL_DST"; then
        OLD_MOVED=0
      else
        echo "rollback could not restore the prior install; it remains at $BACKUP" >&2
        cleanup_failed=1
      fi
    else
      echo "rollback found an unexpected destination; prior install preserved at $BACKUP" >&2
      cleanup_failed=1
    fi
  fi

  if path_exists "$STAGE"; then
    if ! rm -rf -- "$STAGE"; then
      echo "could not remove installer staging path: $STAGE" >&2
      cleanup_failed=1
    fi
  fi

  if [ "$COMMITTED" -eq 1 ] && path_exists "$SKILL_DST/$OWNER_MARKER"; then
    destination_owner=
    if [ -f "$SKILL_DST/$OWNER_MARKER" ] &&
       [ ! -L "$SKILL_DST/$OWNER_MARKER" ]; then
      IFS= read -r destination_owner < "$SKILL_DST/$OWNER_MARKER" ||
        destination_owner=
    fi
    if [ "$destination_owner" = "$TRANSACTION_ID" ]; then
      if ! rm -f -- "$SKILL_DST/$OWNER_MARKER"; then
        echo "could not remove the committed install ownership marker" >&2
        cleanup_failed=1
      fi
    else
      echo "committed install ownership marker changed; recovery lock preserved" >&2
      cleanup_failed=1
    fi
  fi

  if path_exists "$BACKUP"; then
    if [ "$COMMITTED" -eq 0 ]; then
      echo "prior install remains preserved at $BACKUP" >&2
    else
      echo "committed install retains cleanup evidence at $BACKUP" >&2
    fi
    cleanup_failed=1
  fi

  if [ "$LOCK_HELD" -eq 1 ]; then
    if [ -f "$LOCK_OWNER_FILE" ]; then
      IFS= read -r lock_owner < "$LOCK_OWNER_FILE" || lock_owner=
    fi
    if [ "$lock_owner" = "$TRANSACTION_ID" ] &&
       [ "$cleanup_failed" -eq 0 ]; then
      if ! rm -f -- "$LOCK_OWNER_FILE" || ! rmdir "$LOCK"; then
        echo "could not release installer lock: $LOCK" >&2
        cleanup_failed=1
      fi
    elif [ "$lock_owner" != "$TRANSACTION_ID" ]; then
      echo "installer lock ownership changed (expected $TRANSACTION_ID, found ${lock_owner:-missing}); lock preserved at $LOCK" >&2
      cleanup_failed=1
    else
      echo "installer transaction artifacts remain protected by $LOCK" >&2
    fi
    LOCK_HELD=0
  fi

  if [ "$cleanup_failed" -ne 0 ] && [ "$status" -eq 0 ]; then
    status=1
  fi
  exit "$status"
}

if ! mkdir "$LOCK" 2>/dev/null; then
  lock_owner=unknown
  if [ -f "$LOCK_OWNER_FILE" ]; then
    IFS= read -r lock_owner < "$LOCK_OWNER_FILE" || lock_owner=unknown
  fi
  echo "another sprint-loops install holds $LOCK (owner: $lock_owner)" >&2
  exit 1
fi
LOCK_HELD=1
trap 'finish $?' EXIT
trap 'finish 129' HUP
trap 'finish 130' INT
trap 'finish 143' TERM
printf '%s\n' "$TRANSACTION_ID" > "$LOCK_OWNER_FILE"

if [ -L "$SKILL_DST" ]; then
  echo "refusing to replace symlinked skill: $SKILL_DST" >&2
  exit 1
fi
if [ -e "$SKILL_DST" ] && [ ! -d "$SKILL_DST" ]; then
  echo "refusing to replace non-directory skill target: $SKILL_DST" >&2
  exit 1
fi

if path_exists "$STAGE" || path_exists "$BACKUP"; then
  echo "refusing to reuse installer transaction paths under $SKILLS_DIR" >&2
  exit 1
fi

cp -R "$SKILL_SRC" "$STAGE"
[ -f "$STAGE/SKILL.md" ] || {
  echo "staged install is incomplete: SKILL.md is missing" >&2
  exit 1
}
printf '%s\n' "$TRANSACTION_ID" > "$STAGE/$OWNER_MARKER"
if command -v chmod >/dev/null 2>&1; then
  for helper in "$STAGE"/scripts/*.sh; do
    [ -f "$helper" ] || continue
    chmod +x "$helper"
  done
fi

if [ -d "$SKILL_DST" ]; then
  echo "replacing prior install: $SKILL_DST"
  OLD_MOVED=1
  if ! mv "$SKILL_DST" "$BACKUP"; then
    echo "failed to preserve the prior install at $BACKUP" >&2
    exit 1
  fi
fi
ACTIVATING=1
if ! mv "$STAGE" "$SKILL_DST"; then
  echo "failed to activate staged skill; prior install will be restored" >&2
  exit 1
fi
ACTIVATING=0 COMMITTED=1
if ! rm -f -- "$SKILL_DST/$OWNER_MARKER"; then
  echo "skill activated, but its transaction marker could not be removed" >&2
  exit 1
fi
if path_exists "$BACKUP"; then
  if ! rm -rf -- "$BACKUP"; then
    echo "skill activated, but prior-install cleanup failed; preserved remainder: $BACKUP" >&2
    exit 1
  fi
  OLD_MOVED=0
fi

echo "installed: $SKILL_DST"
echo "Codex detects skill changes automatically; restart only if \$sprint-loops does not appear."
echo "Optional project pointer: merge $SKILL_DST/AGENTS.md.fragment into the project's AGENTS.md once."

if [ "$SCOPE" = project ] && [ -n "${HOME:-}" ] &&
   [ -e "$HOME/.agents/skills/sprint-loops/SKILL.md" ]; then
  echo "warning: a same-name user skill is also installed; Codex may show both surfaces" >&2
fi
