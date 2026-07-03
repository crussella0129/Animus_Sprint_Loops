#!/usr/bin/env bash
# Cross-bundle parity guard (sprint 11). The four bundles are intentionally
# self-contained atomic units (sprint-2 ADR), which means their shared assets
# are hand-synchronized copies. This guard makes that synchronization
# enforceable: it fails when any mapped copy diverges, goes missing, or a
# mirror grows a file the canonical bundle doesn't have. Wire into CI.
#
# Parity map (measured at sprint 11; canonical = claude-code/skills/sprint-loop):
#   scripts/  — identical file SET + bytes across claude-code, codex-cli,
#               antigravity-ide, open-harnesses
#   schemas/  — same four bundles
#   prompts/  — claude-code, codex-cli, open-harnesses (antigravity has none)
#   phases/00,01,02,04,05 — claude-code <-> codex-cli
#
# Intentionally divergent (NOT checked): phases/03 + 06 (harness-specific
# plan-mode/loop mechanics), SKILL.md, READMEs, installers, AGENTS.md.fragment,
# open-harnesses particles/, antigravity-ide global_workflows/ (condensed
# rewrites of the protocol, not copies).
#
# BUNDLE_SYNC_ROOT overrides the repo root (used by the fixture test).
set -euo pipefail

ROOT="${BUNDLE_SYNC_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CANON="claude-code/skills/sprint-loop"
fail=0

# check_pair <canonical-relpath> <mirror-relpath>
check_pair() {
  if [ ! -f "$ROOT/$2" ]; then
    echo "MISSING: $2 (canonical: $1)" >&2; fail=1
  elif ! cmp -s "$ROOT/$1" "$ROOT/$2"; then
    echo "DIVERGED: $2 differs from $1" >&2; fail=1
  fi
}

# check_dir_set <subdir> <mirror-base>...
# Every canonical file must exist byte-identical in each mirror's <subdir>,
# and no mirror may carry a file the canonical set lacks.
check_dir_set() {
  local sub="$1"; shift
  local seen=0 f base mirror
  for f in "$ROOT/$CANON/$sub"/*; do
    [ -f "$f" ] || continue
    seen=1
    base="${f##*/}"
    for mirror in "$@"; do
      check_pair "$CANON/$sub/$base" "$mirror/$sub/$base"
    done
  done
  if [ "$seen" = "0" ]; then
    echo "EMPTY CANONICAL SET: $CANON/$sub/ has no files (malformed tree?)" >&2; fail=1
  fi
  for mirror in "$@"; do
    for f in "$ROOT/$mirror/$sub"/*; do
      [ -f "$f" ] || continue
      base="${f##*/}"
      if [ ! -f "$ROOT/$CANON/$sub/$base" ]; then
        echo "EXTRA: $mirror/$sub/$base (absent from canonical $CANON/$sub/)" >&2; fail=1
      fi
    done
  done
}

check_dir_set scripts codex-cli/skills/sprint-loops antigravity-ide/skills/sprint-loop open-harnesses
check_dir_set schemas codex-cli/skills/sprint-loops antigravity-ide/skills/sprint-loop open-harnesses
check_dir_set prompts codex-cli/skills/sprint-loops open-harnesses

for p in 00-overview 01-init-sprint 02-research-phase 04-build-phase 05-test-phase; do
  check_pair "$CANON/phases/$p.md" "codex-cli/skills/sprint-loops/phases/$p.md"
done

if [ "$fail" = "0" ]; then
  echo "bundle-sync: all mapped assets in parity across bundles"
  exit 0
fi
exit 1
