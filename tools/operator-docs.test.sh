#!/usr/bin/env bash
# Focused T-117 coverage: operator guides link to the Book instead of copying it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
READMES=(
  README.md
  claude-code/README.md
  codex-cli/README.md
  antigravity-ide/README.md
  open-harnesses/README.md
)
COUNT=0

fail() {
  echo "operator-docs.test: FAIL: $*" >&2
  exit 1
}

pass() { COUNT=$((COUNT + 1)); }

require_text() {
  file=$1
  expected=$2
  grep -Fq -- "$expected" "$ROOT/$file" ||
    fail "$file lacks required text: $expected"
}

reject_pattern() {
  pattern=$1
  shift
  local paths=() file
  for file in "$@"; do paths+=("$ROOT/$file"); done
  if grep -Ein -- "$pattern" "${paths[@]}" >/dev/null; then
    fail "operator documentation contains forbidden pattern: $pattern"
  fi
}

assert_local_links_resolve() {
  file=$1
  base=$(dirname "$ROOT/$file")
  while IFS= read -r token; do
    target=${token#](}
    target=${target%)}
    case "$target" in
      ''|'#'*|http://*|https://*|mailto:*) continue ;;
    esac
    target=${target%%#*}
    [ -e "$base/$target" ] || fail "$file has unresolved local link: $target"
  done < <(grep -oE '\]\([^)]*\)' "$ROOT/$file" || true)
}

test_root_docs_do_not_duplicate_protocol() {
  require_text README.md 'Book schema v2'
  require_text README.md 'open-harnesses/particles/00-overview.md'
  require_text README.md 'open-harnesses/schemas/intent.md'
  for role in 'docs/intents/' 'docs/work/' 'docs/sprints/' 'docs/SUMMARY.md'; do
    require_text README.md "$role"
  done
  for adapter in 'claude-code/README.md' 'codex-cli/README.md' 'antigravity-ide/README.md' 'open-harnesses/README.md'; do
    require_text README.md "$adapter"
  done
  require_text README.md '/sprint-loop:sprint-loop start'
  require_text README.md '$sprint-loops'
  require_text README.md '/sprint-loops'
  require_text README.md 'current-phase.sh'

  require_text claude-code/README.md 'Book v2'
  require_text codex-cli/README.md 'Book v2'
  require_text antigravity-ide/README.md 'Project Book schema v2'
  require_text open-harnesses/README.md 'Project Book schema v2'

  reject_pattern '^# Core Protocol$|^## Directory schema|^## Phase exit conditions|^## Failure semantics|^## Confidence throttle' "${READMES[@]}"
  reject_pattern 'agent-tasks/|decisions\.md|confidence\.txt|(^|[^/])sprints/|\.codex[/\\]skills|proceeds autonomously|gh[[:space:]]+pr[[:space:]]+merge|force-push.*re-verify' "${READMES[@]}"

  for file in "${READMES[@]}"; do assert_local_links_resolve "$file"; done

  if [ -f "$ROOT/ROADMAP.md" ]; then
    grep -Fqi 'non-authoritative migration source' "$ROOT/ROADMAP.md" ||
      fail 'ROADMAP.md lacks its non-authoritative migration-source marker'
    grep -Fq 'docs/intents/' "$ROOT/ROADMAP.md" ||
      fail 'ROADMAP.md lacks its future Book-intent destination'
    roadmap_items=$(grep -Ec '^## [1-9]\. ' "$ROOT/ROADMAP.md" || true)
    [ "$roadmap_items" -eq 9 ] ||
      fail "ROADMAP.md has $roadmap_items numbered migration items instead of 9"
    assert_local_links_resolve ROADMAP.md
  fi
  pass
}

test_bundle_docs_are_adapter_scoped() {
  home_marker='~'
  require_text claude-code/README.md '.claude/skills/sprint-loop/'
  require_text claude-code/README.md '/plugin marketplace add'
  require_text claude-code/README.md '/sprint-loop'
  require_text claude-code/README.md 'Claude Code Plan Mode'
  require_text claude-code/README.md '/loop'
  require_text claude-code/README.md 'abort "'
  reject_pattern '\.agents/skills|\.gemini/config|Index and retrieve particles' claude-code/README.md

  require_text codex-cli/README.md '.agents/skills/sprint-loops'
  require_text codex-cli/README.md '$sprint-loops'
  require_text codex-cli/README.md 'Native Windows PowerShell'
  require_text codex-cli/README.md 'Git for Windows Bash'
  require_text codex-cli/README.md 'WSL'
  require_text codex-cli/README.md 'preauthorized-remote profile'
  reject_pattern '\.claude/skills|\.gemini/config' codex-cli/README.md

  require_text antigravity-ide/README.md "${home_marker}/.gemini/config/global_workflows/sprint-loops.md"
  require_text antigravity-ide/README.md "${home_marker}/.gemini/config/skills/sprint-loop/"
  require_text antigravity-ide/README.md '-ConfigRoot'
  require_text antigravity-ide/README.md '/sprint-loops'
  for artifact in implementation_plan.md task.md walkthrough.md; do
    require_text antigravity-ide/README.md "$artifact"
  done
  reject_pattern '\.claude/skills|\.agents/skills' antigravity-ide/README.md

  require_text open-harnesses/README.md 'runtime-neutral distribution'
  require_text open-harnesses/README.md 'physical shared-copy'
  require_text open-harnesses/README.md 'particles/'
  require_text open-harnesses/README.md 'current-phase.sh'
  require_text open-harnesses/README.md '| Router output | Particle |'
  reject_pattern '\.claude/skills|\.agents/skills|\.gemini/config' open-harnesses/README.md
  pass
}

# Sprint 17: convergence has to be reachable from the operator surfaces, not
# only from the helper. Both byte-parity copies of the Init contract must name
# the outdated state and route it to the one idempotent command.
test_phase01_documents_outdated_route() {
  for contract in     claude-code/skills/sprint-loop/phases/01-init-sprint.md     codex-cli/skills/sprint-loops/phases/01-init-sprint.md     open-harnesses/particles/01-init-sprint.md     antigravity-ide/global_workflows/sprint-loops.md; do
    require_text "$contract" 'substrate-outdated'
    require_text "$contract" 'deploy-substrate.sh'
  done
  for contract in     claude-code/skills/sprint-loop/phases/01-init-sprint.md     codex-cli/skills/sprint-loops/phases/01-init-sprint.md; do
    require_text "$contract" 'substrate-ahead'
  done
  require_text README.md 'substrate-version'
  require_text README.md '--check'
  pass
}

# The Claude Code argument list is closed, so the upgrade route only exists if
# it is defined there and advertised by the argument hint.
test_skill_defines_upgrade_argument() {
  require_text claude-code/skills/sprint-loop/SKILL.md '- `upgrade`'
  require_text claude-code/skills/sprint-loop/SKILL.md 'argument-hint:'
  grep -Fq 'upgrade' "$ROOT/claude-code/skills/sprint-loop/SKILL.md" ||
    fail 'claude-code SKILL.md does not define the upgrade argument'
  grep -E '^argument-hint:.*upgrade' "$ROOT/claude-code/skills/sprint-loop/SKILL.md" >/dev/null ||
    fail 'argument-hint does not advertise upgrade'
  pass
}

test_root_docs_do_not_duplicate_protocol
test_bundle_docs_are_adapter_scoped
test_phase01_documents_outdated_route
test_skill_defines_upgrade_argument
echo "operator-docs.test: $COUNT documentation contracts passed"
