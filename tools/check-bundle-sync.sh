#!/usr/bin/env bash
# Cross-bundle parity guard (updated for the Book core in sprint 14). The four
# bundles remain self-contained atomic units, so their shared assets are
# physical copies. This guard fails when a mapped copy diverges, goes missing,
# or one compared bundle grows a file the maintenance reference does not have.
#
# Parity map (measured at sprint 14):
#   scripts/  — identical file SET + bytes across claude-code, codex-cli,
#               antigravity-ide, open-harnesses
#   schemas/  — same four bundles
#   prompts/  — claude-code, codex-cli, open-harnesses (antigravity has none)
#   phases/00,01,02,04,05 — claude-code <-> codex-cli
#
# open-harnesses is the physical maintenance reference for shared directories;
# claude-code is the physical reference for the two-bundle phase comparison.
# Comparison direction grants no semantic ownership to either bundle. Each
# target project's Book owns its project meaning and state.
#
# Intentionally divergent (NOT checked): phases/03 + 06 (harness-specific
# plan-mode/loop mechanics), SKILL.md, READMEs, installers, AGENTS.md.fragment,
# open-harnesses particles/, antigravity-ide global_workflows/ (condensed
# rewrites of the protocol, not copies).
#
# BUNDLE_SYNC_ROOT overrides the repo root (used by the fixture test).
set -euo pipefail
shopt -s dotglob nullglob

ROOT="${BUNDLE_SYNC_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REFERENCE="open-harnesses"
PHASE_REFERENCE="claude-code/skills/sprint-loop"
fail=0

# Minimum shared inventory. File-set parity below remains dynamic, but these
# required assets make a synchronized deletion from every bundle observable.
REQUIRED_SCRIPTS=(
  abort-sprint.sh
  book-paths.sh
  book-routing.test.sh
  bundle-version.sh
  check-book.sh
  check-book.test.sh
  close-sprint.sh
  commit-task.sh
  critic-contract.sh
  current-phase.sh
  current-sprint.sh
  finalize-plan.sh
  init-sprint.sh
  migrate-to-book.sh
  migrate-to-book.test.sh
  research-budget.sh
  runtime-helpers.test.sh
  selftest.sh
  update-confidence.sh
  check-substrate.sh
  check-substrate.test.sh
  check-tracked.sh
  check-tracked.test.sh
  deploy-substrate.sh
  deploy-substrate.test.sh
  remote-adapter.sh
  remote-adapter.test.sh
  remote-profile.sh
  remote-profile.test.sh
  sync-work-branch.sh
  sync-work-branch.test.sh
)
REQUIRED_SCHEMAS=(
  agent-tasks.md
  build-plan.md
  completed-tasks.md
  failure-report.md
  intent.md
  research-report.md
  sprint-meta.md
  test-plan.md
  test-report.md
)
REQUIRED_PROMPTS=(
  plan-critic.md
  test-critic.md
)

# check_pair <reference-relpath> <compared-relpath>
check_pair() {
  local reference_rel="$1" compared_rel="$2"
  local reference_path="$ROOT/$reference_rel"
  local compared_path="$ROOT/$compared_rel"

  if [ -L "$reference_path" ]; then
    echo "SYMLINK: $reference_rel" >&2; fail=1
  elif [ ! -e "$reference_path" ]; then
    echo "MISSING REFERENCE: $reference_rel" >&2; fail=1
  elif [ ! -f "$reference_path" ]; then
    echo "NON-REGULAR: $reference_rel" >&2; fail=1
  elif [ -L "$compared_path" ]; then
    echo "SYMLINK: $compared_rel" >&2; fail=1
  elif [ ! -e "$compared_path" ]; then
    echo "MISSING: $2 (reference: $1)" >&2; fail=1
  elif [ ! -f "$compared_path" ]; then
    echo "NON-REGULAR: $compared_rel" >&2; fail=1
  elif ! cmp -s "$reference_path" "$compared_path"; then
    echo "DIVERGED: $2 differs from $1" >&2; fail=1
  fi
}

# check_flat_entry <absolute-path> <repo-relative-path>
check_flat_entry() {
  local path="$1" relative="$2"
  if [ -L "$path" ]; then
    echo "SYMLINK: $relative" >&2
    fail=1
    return 1
  fi
  if [ ! -f "$path" ]; then
    echo "NON-REGULAR: $relative" >&2
    fail=1
    return 1
  fi
  return 0
}

# check_required_inventory <subdir> <required-file>...
check_required_inventory() {
  local sub="$1"; shift
  local base
  for base in "$@"; do
    if [ ! -e "$ROOT/$REFERENCE/$sub/$base" ] &&
       [ ! -L "$ROOT/$REFERENCE/$sub/$base" ]; then
      echo "MISSING REQUIRED SHARED ASSET: $sub/$base" >&2
      fail=1
    fi
  done
}

# check_dir_set <subdir> <compared-base>...
# Every reference file must exist byte-identical in each compared <subdir>,
# and no compared bundle may carry a file the reference set lacks.
check_dir_set() {
  local sub="$1"; shift
  local seen=0 f base compared reference_entry
  for f in "$ROOT/$REFERENCE/$sub"/*; do
    seen=1
    base="${f##*/}"
    check_flat_entry "$f" "$REFERENCE/$sub/$base" || continue
    for compared in "$@"; do
      check_pair "$REFERENCE/$sub/$base" "$compared/$sub/$base"
    done
  done
  if [ "$seen" = "0" ]; then
    echo "EMPTY REFERENCE SET: $REFERENCE/$sub/ has no files (malformed tree?)" >&2
    fail=1
  fi
  for compared in "$@"; do
    for f in "$ROOT/$compared/$sub"/*; do
      base="${f##*/}"
      reference_entry="$ROOT/$REFERENCE/$sub/$base"
      if [ -e "$reference_entry" ] || [ -L "$reference_entry" ]; then
        continue
      fi
      check_flat_entry "$f" "$compared/$sub/$base" || continue
      echo "EXTRA: $compared/$sub/$base (absent from reference $REFERENCE/$sub/)" >&2
      fail=1
    done
  done
}

check_required_inventory scripts "${REQUIRED_SCRIPTS[@]}"
check_required_inventory schemas "${REQUIRED_SCHEMAS[@]}"
check_required_inventory prompts "${REQUIRED_PROMPTS[@]}"

check_dir_set scripts claude-code/skills/sprint-loop codex-cli/skills/sprint-loops antigravity-ide/skills/sprint-loop
check_dir_set schemas claude-code/skills/sprint-loop codex-cli/skills/sprint-loops antigravity-ide/skills/sprint-loop
check_dir_set prompts claude-code/skills/sprint-loop codex-cli/skills/sprint-loops

for p in 00-overview 01-init-sprint 02-research-phase 04-build-phase 05-test-phase; do
  check_pair "$PHASE_REFERENCE/phases/$p.md" "codex-cli/skills/sprint-loops/phases/$p.md"
done

if [ "$fail" = "0" ]; then
  echo "bundle-sync: all mapped assets in parity across bundles"
  exit 0
fi
exit 1
