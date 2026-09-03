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

# Sprint 18: the turn contract is the operator-facing counterpart to the gates.
test_turn_contract_present() {
  for surface in \
    claude-code/skills/sprint-loop/phases/06-loop-phase.md \
    codex-cli/skills/sprint-loops/phases/06-loop-phase.md \
    antigravity-ide/global_workflows/sprint-loops.md \
    open-harnesses/particles/08-loop-phase.md; do
    require_text "$surface" 'Turn Contract'
    require_text "$surface" 'advisory'
    require_text "$surface" 'abort'
    require_text "$surface" 'human-approve'
  done
  require_text README.md 'One sprint per turn, one titled checkpoint per sprint'
  require_text README.md 'substrate-misplaced'
  pass
}

test_exit_evidence_requires_commit() {
  for phase in 02-research-phase 04-build-phase 05-test-phase 06-loop-phase; do
    require_text "claude-code/skills/sprint-loop/phases/$phase.md" 'check-tracked.sh'
    require_text "codex-cli/skills/sprint-loops/phases/$phase.md" 'check-tracked.sh'
  done
  pass
}

test_root_docs_do_not_duplicate_protocol
test_bundle_docs_are_adapter_scoped
# Sprint 19: provider inference must be visible to an operator, because a
# hosted project silently recorded as local-only opens no checkpoint and exits 0.
test_init_documents_provider_inference() {
  for surface in \
    claude-code/skills/sprint-loop/phases/01-init-sprint.md \
    codex-cli/skills/sprint-loops/phases/01-init-sprint.md \
    open-harnesses/particles/01-init-sprint.md \
    antigravity-ide/global_workflows/sprint-loops.md; do
    require_text "$surface" 'origin'
    require_text "$surface" 'generic'
    require_text "$surface" 'local-only'
  done
  for surface in \
    claude-code/skills/sprint-loop/phases/01-init-sprint.md \
    codex-cli/skills/sprint-loops/phases/01-init-sprint.md; do
    require_text "$surface" '--provider'
    require_text "$surface" 'forgejo'
  done
  require_text README.md 'The provider is inferred, not assumed'
  for value in github gitlab gitea forgejo generic local-only; do
    require_text README.md "$value"
  done
  require_text README.md 'never rewritten'
  require_text open-harnesses/schemas/remote-profile.md 'declared, not'
  pass
}

test_turn_contract_present
test_exit_evidence_requires_commit
# Sprint 20: CI generation must be visible, including how to opt out — a
# generated file a project cannot see is one it cannot decline.
test_init_documents_ci_generation() {
  for surface in \
    claude-code/skills/sprint-loop/phases/01-init-sprint.md \
    codex-cli/skills/sprint-loops/phases/01-init-sprint.md \
    open-harnesses/particles/01-init-sprint.md; do
    require_text "$surface" 'workflows'
    require_text "$surface" '.gitlab-ci.yml'
    require_text "$surface" 'ci.sh'
    require_text "$surface" 'local-only'
  done
  require_text README.md 'CI exists from Sprint 0'
  require_text README.md 'never touched'
  require_text README.md 'permanent'
  require_text antigravity-ide/global_workflows/sprint-loops.md 'workflow directory already holds a workflow'
  pass
}

test_init_documents_provider_inference
test_init_documents_ci_generation
test_phase01_documents_outdated_route
test_skill_defines_upgrade_argument
echo "operator-docs.test: $COUNT documentation contracts passed"
