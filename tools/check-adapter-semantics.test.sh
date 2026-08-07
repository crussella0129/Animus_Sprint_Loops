#!/usr/bin/env bash
# Mutation fixtures for check-adapter-semantics.sh. Every negative case must
# fail for its named semantic diagnostic; a crash or unrelated failure does
# not count as detection.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/tools/check-adapter-semantics.sh"
PASSED=0
TOTAL=0
BASE=''
T=''
TMPDIRS=()

cleanup() {
  local dir
  for dir in "${TMPDIRS[@]:-}"; do
    [ -n "$dir" ] && rm -rf -- "$dir"
  done
}
trap cleanup EXIT

fail_test() {
  printf 'adapter-semantics fixtures: FAIL: %s\n' "$*" >&2
  exit 1
}

copy_surface() {
  local rel=$1
  mkdir -p "$(dirname "$BASE/$rel")"
  cp -R "$ROOT/$rel" "$BASE/$rel"
}

build_baseline() {
  BASE=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loops-adapter-semantics.base.XXXXXX")
  TMPDIRS+=("$BASE")
  local rel
  for rel in \
    ".claude-plugin/marketplace.json" \
    "claude-code/.claude-plugin/plugin.json" \
    "claude-code/README.md" \
    "claude-code/skills/sprint-loop/SKILL.md" \
    "claude-code/skills/sprint-loop/phases" \
    "codex-cli/README.md" \
    "codex-cli/skills/sprint-loops/AGENTS.md.fragment" \
    "codex-cli/skills/sprint-loops/SKILL.md" \
    "codex-cli/skills/sprint-loops/phases" \
    "antigravity-ide/README.md" \
    "antigravity-ide/global_workflows/sprint-loops.md" \
    "antigravity-ide/skills/sprint-loop/SKILL.md" \
    "open-harnesses/README.md" \
    "open-harnesses/particles"; do
    copy_surface "$rel"
  done
}

new_case() {
  T=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loops-adapter-semantics.case.XXXXXX")
  TMPDIRS+=("$T")
  cp -R "$BASE/." "$T/"
}

replace_text() {
  local file=$1 old=$2 new=$3 tmp
  tmp="$file.tmp"
  if ! awk -v old="$old" -v new="$new" '
    function replace_all(text, needle, replacement, at, result) {
      result = ""
      while ((at = index(text, needle)) != 0) {
        result = result substr(text, 1, at - 1) replacement
        text = substr(text, at + length(needle))
      }
      return result text
    }
    {
      changed_line = replace_all($0, old, new)
      if (changed_line != $0)
        changed = 1
      print changed_line
    }
    END { if (!changed) exit 3 }
  ' "$file" > "$tmp"; then
    rm -f -- "$tmp"
    fail_test "mutation text not found in ${file#"$T/"}: $old"
  fi
  mv "$tmp" "$file"
}

expect_pass() {
  local description=$1 output rc=0
  TOTAL=$((TOTAL + 1))
  output=$(ADAPTER_SEMANTICS_ROOT="$T" bash "$GUARD" 2>&1) || rc=$?
  if [ "$rc" -eq 0 ] &&
     [ "$output" = 'adapter-semantics: all adapter contracts satisfied' ]; then
    printf 'PASS: %s\n' "$description"
    PASSED=$((PASSED + 1))
  else
    printf 'FAIL (false reject): %s\n%s\n' "$description" "$output" >&2
  fi
}

expect_fail() {
  local description=$1 output rc=0 diagnostic_re
  shift
  TOTAL=$((TOTAL + 1))
  output=$(ADAPTER_SEMANTICS_ROOT="$T" bash "$GUARD" 2>&1) || rc=$?
  if [ "$rc" -ne 1 ]; then
    printf 'FAIL (wrong exit %s, expected 1): %s\n%s\n' \
      "$rc" "$description" "$output" >&2
    return
  fi
  for diagnostic_re in "$@"; do
    if ! printf '%s\n' "$output" | grep -Eq -- "$diagnostic_re"; then
      printf 'FAIL (wrong diagnostic): %s\n  wanted full line: /%s/\n%s\n' \
        "$description" "$diagnostic_re" "$output" >&2
      return
    fi
  done
  printf 'PASS caught: %s\n' "$description"
  PASSED=$((PASSED + 1))
}

build_baseline
T=$BASE
expect_pass "baseline active surfaces pass"

new_case
rm -f -- "$T/open-harnesses/particles/08-loop-phase.md"
expect_fail "missing active surface" \
  '^adapter-semantics: open-harnesses: missing active surface: open-harnesses/particles/08-loop-phase\.md$'

new_case
replace_text "$T/claude-code/skills/sprint-loop/SKILL.md" \
  'Book schema v2' 'Book current schema'
expect_fail "Claude designated version anchor" \
  '^adapter-semantics: claude: missing Book schema version 2 at claude-code/skills/sprint-loop/SKILL\.md$'

new_case
replace_text "$T/claude-code/skills/sprint-loop/SKILL.md" \
  'Book schema v2 keeps' 'not Book schema v2 keeps'
expect_fail "negated version anchor" \
  '^adapter-semantics: claude: missing Book schema version 2 at claude-code/skills/sprint-loop/SKILL\.md$'

new_case
replace_text "$T/codex-cli/skills/sprint-loops/SKILL.md" \
  'Book v2' 'Book current workflow'
expect_fail "Codex designated version anchor" \
  '^adapter-semantics: codex: missing Book schema version 2 at codex-cli/skills/sprint-loops/SKILL\.md$'

new_case
replace_text "$T/antigravity-ide/global_workflows/sprint-loops.md" \
  'schema-version: 2' 'schema-version: current'
expect_fail "Antigravity designated version anchor" \
  '^adapter-semantics: antigravity: missing Book schema version 2 at antigravity-ide/global_workflows/sprint-loops\.md$'

new_case
replace_text "$T/open-harnesses/particles/00-overview.md" \
  'schema v2' 'current schema'
expect_fail "Open designated version anchor" \
  '^adapter-semantics: open-harnesses: missing Book schema version 2 at open-harnesses/particles/00-overview\.md$'

new_case
replace_text "$T/open-harnesses/particles/00-overview.md" 'docs/intents/' 'docs/ideas/'
expect_fail "missing semantic-intent role" \
  '^adapter-semantics: open-harnesses: missing authority role: intent$'

new_case
replace_text "$T/open-harnesses/particles/00-overview.md" 'docs/work/' 'docs/execution/'
expect_fail "missing work-state role" \
  '^adapter-semantics: open-harnesses: missing authority role: work$'

new_case
replace_text "$T/open-harnesses/particles/00-overview.md" 'docs/sprints/' 'docs/iterations/'
expect_fail "missing sprint-provenance role" \
  '^adapter-semantics: open-harnesses: missing authority role: provenance$'

new_case
replace_text "$T/open-harnesses/particles/00-overview.md" 'docs/SUMMARY.md' 'docs/INDEX.md'
expect_fail "missing navigation-view role" \
  '^adapter-semantics: open-harnesses: missing authority role: navigation$'

new_case
replace_text "$T/claude-code/skills/sprint-loop/phases/00-overview.md" \
  'is semantic authority' 'is not semantic authority'
expect_fail "negated semantic-intent role" \
  '^adapter-semantics: claude: missing authority role: intent$'

new_case
replace_text "$T/.claude-plugin/marketplace.json" \
  'a direct request to start, continue, resume, or run a sprint loop' \
  'when a project root contains a sprints/ directory'
expect_fail "Claude metadata revives root sprints activation" \
  "^adapter-semantics: claude: active legacy authority 'sprints/' at \.claude-plugin/marketplace\.json:[0-9]+$"

new_case
printf '\nThe project root stores active Sprint Loops state in\n`sprints/`.\n' >> \
  "$T/claude-code/README.md"
expect_fail "wrapped root sprints authority" \
  "^adapter-semantics: claude: active legacy authority 'sprints/' at claude-code/README\.md:[0-9]+$"

new_case
wrapped_three_line=$(( $(wc -l < "$T/claude-code/README.md") + 3 ))
printf 'The project root stores\ncurrent authoritative state in\n`sprints/`.\n' >> \
  "$T/claude-code/README.md"
expect_fail "three-line wrapped legacy declaration" \
  "^adapter-semantics: claude: active legacy authority 'sprints/' at claude-code/README\.md:${wrapped_three_line}$"

new_case
printf '\nThe project root does not use sprints/ as active authority.\n' >> \
  "$T/claude-code/README.md"
printf 'The former project-root agent-tasks/ layout is read-only history.\n' >> \
  "$T/claude-code/README.md"
printf 'Root decisions.md is historical and non-authoritative.\n' >> \
  "$T/claude-code/README.md"
expect_pass "negative, former, and read-only legacy prose remains safe"

new_case
historical_canonical_line=$(( $(wc -l < "$T/claude-code/README.md") + 2 ))
printf '\nsprints/ is a historical canonical source of truth.\n' >> \
  "$T/claude-code/README.md"
expect_fail "historical prose cannot mask canonical legacy authority" \
  "^adapter-semantics: claude: active legacy authority 'sprints/' at claude-code/README\.md:${historical_canonical_line}$"

new_case
legacy_but_line=$(( $(wc -l < "$T/claude-code/README.md") + 2 ))
printf '\nsprints/ is historical but remains canonical project state.\n' >> \
  "$T/claude-code/README.md"
expect_fail "contrast continuation retains legacy subject" \
  "^adapter-semantics: claude: active legacy authority 'sprints/' at claude-code/README\.md:${legacy_but_line}$"

new_case
legacy_semicolon_line=$(( $(wc -l < "$T/claude-code/README.md") + 2 ))
wrapped_semicolon_line=$((legacy_semicolon_line + 2))
printf '\nsprints/ is historical; it remains canonical project state.\n' >> \
  "$T/claude-code/README.md"
printf 'sprints/ is historical;\nit remains canonical project state.\n' >> \
  "$T/claude-code/README.md"
expect_fail "semicolon continuation retains legacy subject" \
  "^adapter-semantics: claude: active legacy authority 'sprints/' at claude-code/README\.md:${legacy_semicolon_line}$" \
  "^adapter-semantics: claude: active legacy authority 'sprints/' at claude-code/README\.md:${wrapped_semicolon_line}$"

new_case
legacy_dash_line=$(( $(wc -l < "$T/claude-code/README.md") + 2 ))
printf '\nsprints/ is historical — still authoritative project state.\n' >> \
  "$T/claude-code/README.md"
expect_fail "em-dash continuation retains legacy subject" \
  "^adapter-semantics: claude: active legacy authority 'sprints/' at claude-code/README\.md:${legacy_dash_line}$"

new_case
printf '\nsprints/ is historical, but docs/ is canonical project state.\n' >> \
  "$T/claude-code/README.md"
printf 'sprints/ is historical; the Book is current; it remains canonical.\n' >> \
  "$T/claude-code/README.md"
expect_pass "explicit or intervening subjects break legacy association"

new_case
printf '\nThe migration guide mentions `sprints/`\n\n' >> \
  "$T/claude-code/README.md"
printf 'Current authoritative state lives in `docs/`.\n' >> \
  "$T/claude-code/README.md"
printf 'The migration guide mentions `agent-tasks/`\n' >> \
  "$T/claude-code/README.md"
printf '## Canonical Project Book\n' >> "$T/claude-code/README.md"
printf 'Current authoritative state lives in `docs/`.\n' >> \
  "$T/claude-code/README.md"
expect_pass "blank lines and headings reset legacy clause accumulation"

new_case
authoritative_line=$(( $(wc -l < "$T/claude-code/README.md") + 2 ))
resides_line=$((authoritative_line + 1))
printf '\nsprints/ is authoritative project state.\n' >> "$T/claude-code/README.md"
printf 'Current state resides in sprints/.\n' >> "$T/claude-code/README.md"
expect_fail "expanded affirmative legacy vocabulary" \
  "^adapter-semantics: claude: active legacy authority 'sprints/' at claude-code/README\.md:${authoritative_line}$" \
  "^adapter-semantics: claude: active legacy authority 'sprints/' at claude-code/README\.md:${resides_line}$"

new_case
replace_text "$T/claude-code/skills/sprint-loop/SKILL.md" \
  'Push, merge, release, force-push, delete, and material scope expansion require an explicit request or a declared preauthorized-remote profile.' \
  'Remote operations remain user-gated.'
expect_fail "missing exact remote rule" \
  '^adapter-semantics: claude: expected one exact remote authority rule, found 0$'

new_case
printf '\n%s\n' \
  'Push, merge, release, force-push, delete, and material scope expansion require an explicit request or a declared preauthorized-remote profile.' >> \
  "$T/codex-cli/skills/sprint-loops/SKILL.md"
expect_fail "duplicate exact remote rule" \
  '^adapter-semantics: codex: expected one exact remote authority rule, found 2$'

new_case
replace_text "$T/claude-code/skills/sprint-loop/SKILL.md" \
  'Push, merge, release, force-push, delete, and material scope expansion require an explicit request or a declared preauthorized-remote profile.' \
  'Push and merge a green PR autonomously without asking.'
expect_fail "autonomous remote authorization" \
  '^adapter-semantics: claude: autonomous remote authorization at claude-code/skills/sprint-loop/SKILL\.md:[0-9]+$'

new_case
printf '\nPush changes automatically after an explicit user request.\n' >> \
  "$T/open-harnesses/README.md"
printf 'Push changes automatically under a declared preauthorized-remote profile.\n' >> \
  "$T/open-harnesses/README.md"
expect_pass "explicit remote authority permits automatic execution"

new_case
imperative_line=$(( $(wc -l < "$T/open-harnesses/README.md") + 2 ))
printf '\nCommit, push, and merge verified work.\n' >> "$T/open-harnesses/README.md"
expect_fail "direct imperative remote contradiction" \
  "^adapter-semantics: open-harnesses: autonomous remote authorization at open-harnesses/README\.md:${imperative_line}$"

new_case
printf '\nDo not merge green changes automatically.\n' >> \
  "$T/open-harnesses/README.md"
printf 'Never release without confirmation.\n' >> \
  "$T/open-harnesses/README.md"
printf 'Never use --ask-for-approval never.\n' >> \
  "$T/open-harnesses/README.md"
printf 'Do not set sandbox to unrestricted.\n' >> \
  "$T/open-harnesses/README.md"
expect_pass "safe same-clause remote and permission prohibitions pass"

new_case
semicolon_line=$(( $(wc -l < "$T/open-harnesses/README.md") + 2 ))
colon_line=$((semicolon_line + 1))
dash_line=$((semicolon_line + 2))
contrast_line=$((semicolon_line + 3))
printf '\nDo not push; merge green changes automatically.\n' >> "$T/open-harnesses/README.md"
printf 'Do not weaken permissions: set sandbox to unrestricted.\n' >> "$T/open-harnesses/README.md"
printf 'Do not push — release automatically.\n' >> "$T/open-harnesses/README.md"
printf 'Do not change permissions, but set sandbox to unrestricted.\n' >> "$T/open-harnesses/README.md"
expect_fail "clause-local negation cannot mask later authorization" \
  "^adapter-semantics: open-harnesses: autonomous remote authorization at open-harnesses/README\.md:${semicolon_line}$" \
  "^adapter-semantics: open-harnesses: permission expansion at open-harnesses/README\.md:${colon_line}$" \
  "^adapter-semantics: open-harnesses: autonomous remote authorization at open-harnesses/README\.md:${dash_line}$" \
  "^adapter-semantics: open-harnesses: permission expansion at open-harnesses/README\.md:${contrast_line}$"

new_case
push_line=$(( $(wc -l < "$T/open-harnesses/README.md") + 2 ))
merge_line=$((push_line + 1))
release_line=$((push_line + 2))
force_line=$((push_line + 3))
delete_line=$((push_line + 4))
scope_line=$((push_line + 5))
without_request_line=$((push_line + 6))
no_request_line=$((push_line + 7))
printf '\nPush changes automatically after tests pass.\n' >> "$T/open-harnesses/README.md"
printf 'Merge changes without confirmation.\n' >> "$T/open-harnesses/README.md"
printf 'Release automatically after verification.\n' >> "$T/open-harnesses/README.md"
printf 'Force-push without asking.\n' >> "$T/open-harnesses/README.md"
printf 'Delete the branch automatically.\n' >> "$T/open-harnesses/README.md"
printf 'Material scope expansion proceeds without an explicit request.\n' >> "$T/open-harnesses/README.md"
printf 'Push changes automatically without an explicit user request.\n' >> "$T/open-harnesses/README.md"
printf 'Push changes automatically with no explicit user request.\n' >> "$T/open-harnesses/README.md"
expect_fail "every remote action rejects automatic or no-confirmation authority" \
  "^adapter-semantics: open-harnesses: autonomous remote authorization at open-harnesses/README\.md:${push_line}$" \
  "^adapter-semantics: open-harnesses: autonomous remote authorization at open-harnesses/README\.md:${merge_line}$" \
  "^adapter-semantics: open-harnesses: autonomous remote authorization at open-harnesses/README\.md:${release_line}$" \
  "^adapter-semantics: open-harnesses: autonomous remote authorization at open-harnesses/README\.md:${force_line}$" \
  "^adapter-semantics: open-harnesses: autonomous remote authorization at open-harnesses/README\.md:${delete_line}$" \
  "^adapter-semantics: open-harnesses: autonomous remote authorization at open-harnesses/README\.md:${scope_line}$" \
  "^adapter-semantics: open-harnesses: autonomous remote authorization at open-harnesses/README\.md:${without_request_line}$" \
  "^adapter-semantics: open-harnesses: autonomous remote authorization at open-harnesses/README\.md:${no_request_line}$"

new_case
printf '\nSet --ask-for-approval never to keep the phase moving.\n' >> \
  "$T/codex-cli/skills/sprint-loops/SKILL.md"
expect_fail "Codex permission expansion" \
  '^adapter-semantics: codex: permission expansion at codex-cli/skills/sprint-loops/SKILL\.md:[0-9]+$'

new_case
printf '\nDo not weaken permission boundaries. Set permission mode to unrestricted.\n' >> \
  "$T/codex-cli/README.md"
expect_fail "adjacent safe sentence does not mask permission expansion" \
  '^adapter-semantics: codex: permission expansion at codex-cli/README\.md:[0-9]+$'

new_case
replace_text "$T/codex-cli/skills/sprint-loops/SKILL.md" \
  'Never change Codex sandbox, approval, or permission' \
  'Respect the current Codex runtime'
expect_fail "Codex native permission boundary" \
  '^adapter-semantics: codex: missing native boundary: permissions$'

new_case
replace_text "$T/claude-code/skills/sprint-loop/phases/03-plan-phase.md" \
  'Invoke `EnterPlanMode` as the first phase action.' \
  'Enter planning as the first phase action.'
replace_text "$T/claude-code/skills/sprint-loop/phases/03-plan-phase.md" \
  'invoke `ExitPlanMode`' 'leave planning'
expect_fail "Claude Plan Mode boundary" \
  '^adapter-semantics: claude: missing native boundary: Plan Mode$'

new_case
replace_text "$T/claude-code/skills/sprint-loop/phases/03-plan-phase.md" \
  'EnterPlanMode' 'EnterPlanningMode'
replace_text "$T/claude-code/skills/sprint-loop/phases/03-plan-phase.md" \
  'ExitPlanMode' 'ExitPlanningMode'
printf '\nDo not invoke EnterPlanMode or ExitPlanMode from Loop.\n' >> \
  "$T/claude-code/skills/sprint-loop/phases/06-loop-phase.md"
expect_fail "negative Plan Mode mentions cannot relocate ownership" \
  '^adapter-semantics: claude: missing native boundary: Plan Mode$'

new_case
replace_text "$T/claude-code/skills/sprint-loop/SKILL.md" \
  'the user starts and stops recurrence' 'recurrence repeats automatically'
expect_fail "Claude session-owned recurrence boundary" \
  '^adapter-semantics: claude: missing native boundary: /loop$'

new_case
replace_text "$T/claude-code/skills/sprint-loop/phases/06-loop-phase.md" \
  'this phase does not schedule itself' 'recurrence is handled elsewhere'
printf '\nThe Loop contract says this phase does not schedule itself.\n' >> \
  "$T/claude-code/skills/sprint-loop/SKILL.md"
expect_fail "Loop ownership cannot move out of phase06" \
  '^adapter-semantics: claude: missing native boundary: /loop$'

new_case
replace_text "$T/codex-cli/skills/sprint-loops/SKILL.md" \
  'Use subagents for bounded, disjoint read/review work; keep one integrating writer in a shared workspace. Parallel writers require explicit isolated worktrees.' \
  'Subagents may edit the shared workspace concurrently.'
expect_fail "Codex shared-workspace writer boundary" \
  '^adapter-semantics: codex: missing native boundary: shared workspace$'

new_case
replace_text "$T/antigravity-ide/global_workflows/sprint-loops.md" \
  'Non-authoritative view of unrealized intent and planning.' \
  'Authoritative implementation plan.'
expect_fail "Antigravity implementation-plan mapping" \
  '^adapter-semantics: antigravity: invalid native artifact mapping: implementation_plan\.md$'

new_case
replace_text "$T/antigravity-ide/global_workflows/sprint-loops.md" \
  'Non-authoritative view of work state.' 'Authoritative task state.'
expect_fail "Antigravity task mapping" \
  '^adapter-semantics: antigravity: invalid native artifact mapping: task\.md$'

new_case
replace_text "$T/antigravity-ide/global_workflows/sprint-loops.md" \
  'Non-authoritative view of realization evidence.' \
  'Authoritative realization evidence.'
expect_fail "Antigravity walkthrough mapping" \
  '^adapter-semantics: antigravity: invalid native artifact mapping: walkthrough\.md$'

new_case
replace_text "$T/antigravity-ide/global_workflows/sprint-loops.md" \
  'They do not' 'They may'
expect_fail "Antigravity preference authority boundary" \
  '^adapter-semantics: antigravity: missing native boundary: Always Proceed/auto-accept$'

new_case
replace_text "$T/open-harnesses/README.md" \
  'Those orchestration choices do not change Book authority,' \
  'Those orchestration choices may change Book authority and'
replace_text "$T/open-harnesses/README.md" \
  'bypass evidence gates, or grant remote-operation permission.' \
  'merge green changes automatically.'
expect_fail "Open host-runtime authority boundary" \
  '^adapter-semantics: open-harnesses: missing host-runtime authority boundary$'

new_case
printf '\nCanonical state lives in `docs/sprints/`; optional state lives in `docs/work/confidence.txt`.\n' >> \
  "$T/open-harnesses/README.md"
mkdir -p "$T/historical-notes"
printf 'The old root stored sprints/ and allowed merge to proceed autonomously.\n' > \
  "$T/historical-notes/legacy.md"
expect_pass "canonical Book paths and inactive history do not false-positive"

new_case
replace_text "$T/claude-code/skills/sprint-loop/SKILL.md" 'schemas/remote-profile.md' 'schemas/none.md'
expect_fail "adapter omits remote-profile reference" \
  '^adapter-semantics: claude: missing remote-profile schema reference'

new_case
replace_text "$T/codex-cli/skills/sprint-loops/SKILL.md" 'no per-sprint branch' 'a per-sprint branch'
expect_fail "adapter drops the no-per-sprint-branch commitment" \
  '^adapter-semantics: codex: missing the no-per-sprint-branch commitment'

printf 'adapter-semantics fixture test: %s/%s behaved\n' "$PASSED" "$TOTAL"
[ "$PASSED" -eq "$TOTAL" ]
