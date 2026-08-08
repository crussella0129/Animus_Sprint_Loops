#!/usr/bin/env bash
# Semantic consistency guard for the intentionally divergent Sprint Loops
# adapters. Shared files are byte-compared elsewhere; this guard checks the
# authority and native-runtime meanings that must survive adapter-specific
# wording. ADAPTER_SEMANTICS_ROOT points fixtures at an isolated repository.
set -euo pipefail

ROOT="${ADAPTER_SEMANTICS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FAILED=0

REMOTE_RULE='Push, merge, release, force-push, delete, and material scope expansion require an explicit request or a declared preauthorized-remote profile.'

CLAUDE_ACTIVE=(
  ".claude-plugin/marketplace.json"
  "claude-code/.claude-plugin/plugin.json"
  "claude-code/README.md"
  "claude-code/skills/sprint-loop/SKILL.md"
  "claude-code/skills/sprint-loop/phases/00-overview.md"
  "claude-code/skills/sprint-loop/phases/01-init-sprint.md"
  "claude-code/skills/sprint-loop/phases/02-research-phase.md"
  "claude-code/skills/sprint-loop/phases/03-plan-phase.md"
  "claude-code/skills/sprint-loop/phases/04-build-phase.md"
  "claude-code/skills/sprint-loop/phases/05-test-phase.md"
  "claude-code/skills/sprint-loop/phases/06-loop-phase.md"
)

CLAUDE_RUNTIME=(
  "claude-code/skills/sprint-loop/SKILL.md"
  "claude-code/skills/sprint-loop/phases/00-overview.md"
  "claude-code/skills/sprint-loop/phases/01-init-sprint.md"
  "claude-code/skills/sprint-loop/phases/02-research-phase.md"
  "claude-code/skills/sprint-loop/phases/03-plan-phase.md"
  "claude-code/skills/sprint-loop/phases/04-build-phase.md"
  "claude-code/skills/sprint-loop/phases/05-test-phase.md"
  "claude-code/skills/sprint-loop/phases/06-loop-phase.md"
)

CODEX_ACTIVE=(
  "codex-cli/README.md"
  "codex-cli/skills/sprint-loops/AGENTS.md.fragment"
  "codex-cli/skills/sprint-loops/SKILL.md"
  "codex-cli/skills/sprint-loops/phases/00-overview.md"
  "codex-cli/skills/sprint-loops/phases/01-init-sprint.md"
  "codex-cli/skills/sprint-loops/phases/02-research-phase.md"
  "codex-cli/skills/sprint-loops/phases/03-plan-phase.md"
  "codex-cli/skills/sprint-loops/phases/04-build-phase.md"
  "codex-cli/skills/sprint-loops/phases/05-test-phase.md"
  "codex-cli/skills/sprint-loops/phases/06-loop-phase.md"
)

ANTIGRAVITY_ACTIVE=(
  "antigravity-ide/README.md"
  "antigravity-ide/global_workflows/sprint-loops.md"
  "antigravity-ide/skills/sprint-loop/SKILL.md"
)

OPEN_ACTIVE=(
  "open-harnesses/README.md"
  "open-harnesses/particles/00-overview.md"
  "open-harnesses/particles/01-init-sprint.md"
  "open-harnesses/particles/02-research-phase.md"
  "open-harnesses/particles/03-plan-phase.md"
  "open-harnesses/particles/04-build-plan-schema.md"
  "open-harnesses/particles/05-test-plan-schema.md"
  "open-harnesses/particles/06-build-phase.md"
  "open-harnesses/particles/07-test-phase.md"
  "open-harnesses/particles/08-loop-phase.md"
)

# These are the active, user-facing and executable branch-model surfaces. The
# finalized Book under docs/sprints/, completed-task history, Git/PR history,
# and this guard's own regression vocabulary are intentionally outside this
# inventory.
BRANCH_MODEL_ACTIVE=(
  "README.md"
  ".github/dependabot.yml"
  ".github/workflows/ci.yml"
  "docs/work/remote-profile.md"
  ".claude-plugin"
  "claude-code"
  "codex-cli"
  "antigravity-ide"
  "open-harnesses"
)

report() {
  printf 'adapter-semantics: %s\n' "$*" >&2
  FAILED=1
}

matches() {
  local text=$1 pattern=$2
  grep -Eiq -- "$pattern" <<<"$text"
}

all_surfaces_exist() {
  local rel
  for rel in "$@"; do
    [ -f "$ROOT/$rel" ] || return 1
  done
  return 0
}

check_surface_set() {
  local adapter=$1 rel missing=0
  shift
  for rel in "$@"; do
    if [ ! -f "$ROOT/$rel" ]; then
      report "$adapter: missing active surface: $rel"
      missing=1
    fi
  done
  [ "$missing" -eq 0 ]
}

normalize_files() {
  local rel
  for rel in "$@"; do
    [ -f "$ROOT/$rel" ] || continue
    tr '\n' ' ' < "$ROOT/$rel"
    printf ' '
  done | tr -s '[:space:]' ' '
}

check_adapter_surfaces() {
  local adapter=$1
  shift
  check_surface_set "$adapter" "$@" || true
}

check_retired_branch_model() {
  local rel path output
  local active_files=()

  for rel in "${BRANCH_MODEL_ACTIVE[@]}"; do
    path="$ROOT/$rel"
    if [ -f "$path" ]; then
      active_files+=("$path")
    elif [ -d "$path" ]; then
      while IFS= read -r path; do
        active_files+=("$path")
      done < <(find "$path" -type f -print | LC_ALL=C sort)
    else
      report "branch-model: missing active surface: $rel"
    fi
  done

  output=$(LC_ALL=C awk -v root="$ROOT/" '
    {
      text = tolower($0)
      if (text ~ /(^|[^[:alnum:]])bump([^[:alnum:]]|$)/ ||
          text ~ /(^|[^[:alnum:]])bump[_-]?branch([^[:alnum:]]|$)/) {
        rel = substr(FILENAME, length(root) + 1)
        printf "adapter-semantics: retired branch model term \047bump\047 at %s:%d\n", rel, FNR
      }
    }
  ' "${active_files[@]}")
  if [ -n "$output" ]; then
    printf '%s\n' "$output" >&2
    FAILED=1
  fi
}

check_version_anchor() {
  local adapter=$1 rel=$2 positive=$3 corpus
  [ -f "$ROOT/$rel" ] || return 0
  corpus=$(normalize_files "$rel")
  if ! matches "$corpus" "$positive" ||
     matches "$corpus" '(not|never|no longer)[[:space:]]+.{0,30}(Book schema v2|Book v2|schema-version:[[:space:]]*2|schema v2)'; then
    report "$adapter: missing Book schema version 2 at $rel"
  fi
}

check_profile_contract() {
  local adapter=$1 rel=$2 corpus
  [ -f "$ROOT/$rel" ] || return 0
  corpus=$(normalize_files "$rel")
  matches "$corpus" 'remote-profile' ||
    report "$adapter: missing remote-profile schema reference at $rel"
  matches "$corpus" 'no per-sprint branch' ||
    report "$adapter: missing the no-per-sprint-branch commitment at $rel"
}

check_positive_role() {
  local adapter=$1 role=$2 corpus=$3 positive negative
  case "$role" in
    intent)
      positive='docs/intents/.{0,160}(semantic authority|semantic chapters|semantic intent)'
      negative='docs/intents/.{0,160}(not|never|no longer).{0,100}(semantic|authority)'
      ;;
    work)
      positive='docs/work/.{0,180}(execution state|execution ledgers|work state)'
      negative='docs/work/.{0,160}(not|never|no longer).{0,100}(execution|work state)'
      ;;
    provenance)
      positive='docs/sprints/.{0,160}(sprint provenance|provenance)'
      negative='docs/sprints/.{0,160}(not|never|no longer).{0,100}provenance'
      ;;
    navigation)
      positive='docs/SUMMARY\.md.{0,160}(navigation(-only| only)?|navigation only|non-authoritative (view|views))'
      negative='docs/SUMMARY\.md.{0,160}(not|never|no longer).{0,100}(navigation|view)|docs/SUMMARY\.md.{0,160}(is|are|becomes?|serves as)[[:space:]]+(an?[[:space:]]+)?authoritative|docs/SUMMARY\.md.{0,160}(semantic state|state store)'
      ;;
  esac
  if ! matches "$corpus" "$positive" || matches "$corpus" "$negative"; then
    report "$adapter: missing authority role: $role"
  fi
}

check_role_anchor() {
  local adapter=$1 rel=$2 corpus role
  [ -f "$ROOT/$rel" ] || return 0
  corpus=$(normalize_files "$rel")
  for role in intent work provenance navigation; do
    check_positive_role "$adapter" "$role" "$corpus"
  done
}

count_exact() {
  local needle=$1 rel
  shift
  for rel in "$@"; do
    [ -f "$ROOT/$rel" ] || continue
    grep -Fo -- "$needle" "$ROOT/$rel" || true
  done | wc -l | tr -d '[:space:]'
}

check_remote_rule() {
  local adapter=$1 count
  shift
  all_surfaces_exist "$@" || return 0
  count=$(count_exact "$REMOTE_RULE" "$@")
  if [ "$count" -ne 1 ]; then
    report "$adapter: expected one exact remote authority rule, found $count"
  fi
}

check_claude_native() {
  local enter_count exit_count plan_enter plan_exit skill loop plan
  local plan_rel="claude-code/skills/sprint-loop/phases/03-plan-phase.md"
  all_surfaces_exist "${CLAUDE_RUNTIME[@]}" || return 0
  enter_count=$(count_exact 'EnterPlanMode' "${CLAUDE_RUNTIME[@]}")
  exit_count=$(count_exact 'ExitPlanMode' "${CLAUDE_RUNTIME[@]}")
  plan_enter=$(count_exact 'EnterPlanMode' "$plan_rel")
  plan_exit=$(count_exact 'ExitPlanMode' "$plan_rel")
  plan=$(normalize_files "$plan_rel")
  if [ "$enter_count" -ne 1 ] || [ "$exit_count" -ne 1 ] ||
     [ "$plan_enter" -ne 1 ] || [ "$plan_exit" -ne 1 ] ||
     ! matches "$plan" 'Invoke `EnterPlanMode` as the first phase action\.' ||
     ! matches "$plan" 'invoke `ExitPlanMode` with concise'; then
    report "claude: missing native boundary: Plan Mode"
  fi

  skill=$(normalize_files "claude-code/skills/sprint-loop/SKILL.md")
  loop=$(normalize_files "claude-code/skills/sprint-loop/phases/06-loop-phase.md")
  if ! matches "$skill" 'For session-scoped recurrence' ||
     ! matches "$skill" '/loop /sprint-loop continue' ||
     ! matches "$skill" 'user starts and stops recurrence' ||
     ! matches "$skill" 'none enlarges authority' ||
     ! matches "$skill" 'changes active permissions' ||
     ! matches "$loop" 'this phase does not schedule itself'; then
    report "claude: missing native boundary: /loop"
  fi
}

check_codex_native() {
  local skill workspace_rule
  all_surfaces_exist "${CODEX_ACTIVE[@]}" || return 0
  skill=$(normalize_files "codex-cli/skills/sprint-loops/SKILL.md")
  if ! matches "$skill" 'Never change Codex sandbox, approval, or permission'; then
    report "codex: missing native boundary: permissions"
  fi
  workspace_rule='Use subagents for bounded, disjoint read/review work; keep one integrating writer in a shared workspace. Parallel writers require explicit isolated worktrees.'
  if [ "$(count_exact "$workspace_rule" "${CODEX_ACTIVE[@]}")" -ne 1 ]; then
    report "codex: missing native boundary: shared workspace"
  fi
}

check_antigravity_mapping() {
  local artifact=$1 marker row count valid=1
  local workflow="antigravity-ide/global_workflows/sprint-loops.md"
  marker="| \`$artifact\` |"
  count=$(grep -Fc -- "$marker" "$ROOT/$workflow" || true)
  row=$(grep -F -- "$marker" "$ROOT/$workflow" || true)
  [ "$count" -eq 1 ] || valid=0

  case "$artifact" in
    implementation_plan.md)
      matches "$row" 'Non-authoritative view of unrealized intent and planning' || valid=0
      matches "$row" 'docs/intents/' || valid=0
      matches "$row" 'docs/sprints/sN/sprint-plans/' || valid=0
      ;;
    task.md)
      matches "$row" 'Non-authoritative view of work state' || valid=0
      matches "$row" 'docs/work/tasks\.md' || valid=0
      matches "$row" 'docs/work/completed-tasks\.md' || valid=0
      ;;
    walkthrough.md)
      matches "$row" 'Non-authoritative view of realization evidence' || valid=0
      matches "$row" 'Completion evidence plus at least one Code, Test, or Documentation evidence link' || valid=0
      matches "$row" 'walkthrough alone never realizes intent' || valid=0
      ;;
  esac

  if [ "$valid" -ne 1 ]; then
    report "antigravity: invalid native artifact mapping: $artifact"
  fi
}

check_antigravity_native() {
  local workflow corpus
  workflow="antigravity-ide/global_workflows/sprint-loops.md"
  [ -f "$ROOT/$workflow" ] || return 0
  check_antigravity_mapping implementation_plan.md
  check_antigravity_mapping task.md
  check_antigravity_mapping walkthrough.md
  corpus=$(normalize_files "$workflow")
  if ! matches "$corpus" 'Always Proceed and auto-accept.{0,160}interaction preferences only.{0,160}(They )?do not.{0,80}enlarge authority'; then
    report "antigravity: missing native boundary: Always Proceed/auto-accept"
  fi
}

check_open_native() {
  local corpus
  all_surfaces_exist "${OPEN_ACTIVE[@]}" || return 0
  corpus=$(normalize_files "${OPEN_ACTIVE[@]}")
  if ! matches "$corpus" 'orchestration choices do not change Book authority,[[:space:]]*bypass evidence gates, or grant remote-operation permission'; then
    report "open-harnesses: missing host-runtime authority boundary"
  fi
}

scan_adapter() {
  local adapter=$1 rel output
  local files=()
  shift
  for rel in "$@"; do
    [ -f "$ROOT/$rel" ] || continue
    files+=("$ROOT/$rel")
  done
  [ "${#files[@]}" -gt 0 ] || return 0

  output=$(awk -v root="$ROOT/" -v adapter="$adapter" '
    function emit(kind, detail) {
      rel = substr(FILENAME, length(root) + 1)
      if (detail == "")
        printf "adapter-semantics: %s: %s at %s:%d\n", adapter, kind, rel, FNR
      else
        printf "adapter-semantics: %s: %s %s at %s:%d\n", adapter, kind, detail, rel, FNR
    }

    function normalize_clauses(text) {
      gsub(/—/, ";", text)
      gsub(/,[ \t]*(but|however|yet|nevertheless|instead|although|whereas)[, \t]+/, ";", text)
      gsub(/[ \t]+(but|however|yet|nevertheless|instead|although|whereas)[, \t]+/, ";", text)
      return text
    }

    function negation_before(text, position, prefix) {
      prefix = substr(text, 1, position - 1)
      return prefix ~ /do(es)?[ \t]+not|never|may[ \t]+not|must[ \t]+not|cannot|can not|none|nothing|no longer/
    }

    function authority_negated_before(text, position, prefix) {
      prefix = substr(text, 1, position - 1)
      return prefix ~ /(^|[^a-z])(not|never|no)([^a-z]|$)|cannot|can not/
    }

    function has_unnegated_legacy_authority(clause, rest, offset, position, consumed) {
      rest = clause
      offset = 0
      while (match(rest, /(^|[^a-z-])(canonical|authoritative|official|writable|active)([^a-z-]|$)|system[ \t]+of[ \t]+record|source[ \t]+of[ \t]+truth/)) {
        position = offset + RSTART
        if (!authority_negated_before(clause, position))
          return 1
        consumed = RSTART + RLENGTH - 1
        offset += consumed
        rest = substr(rest, RSTART + RLENGTH)
      }
      return 0
    }

    function legacy_safe(clause) {
      if (clause ~ /(do(es)?[ \t]+not|never|may[ \t]+not|must[ \t]+not|cannot|can not|no longer)[^.!?;:]*(use|write|create|store|persist|treat|activate|own|reside|authoritative|authority|official|writable)/)
        return 1
      if (clause ~ /(is|are|remains?|becomes?)[ \t]+not[ \t]+(an?[ \t]+)?(active|writable|canonical|authoritative|official)/)
        return 1
      if (clause ~ /(read-only|read only|historical|former|deprecated|non-authoritative|legacy history)/) {
        if (has_unnegated_legacy_authority(clause))
          return 0
        return 1
      }
      return 0
    }

    function explicit_docs_authority(clause, plain, docs_position) {
      plain = clause
      gsub(/`/, "", plain)
      if (!match(plain, /(^|[^[:alnum:]_.-])docs\//))
        return 0
      docs_position = RSTART
      return has_unnegated_legacy_authority(substr(plain, docs_position))
    }

    function authority_continuation(clause) {
      return clause ~ /^[ \t]*(it[ \t]+)?(is|are|remains?|stays?|continues?[ \t]+to[ \t]+be|serves?[ \t]+as)?[ \t]*(still[ \t]+)?((an?|the)[ \t]+)?(canonical|authoritative|official|writable|active|system[ \t]+of[ \t]+record|source[ \t]+of[ \t]+truth|semantic[ \t]+authority)([^a-z]|$)/
    }

    function legacy_token(text, normalized, sentences, sentence_count, sentence_index, clauses, clause_count, clause_index, clause, stripped, active, token, context_token) {
      normalized = normalize_clauses(text)
      sentence_count = split(normalized, sentences, /[.!?]/)
      for (sentence_index = 1; sentence_index <= sentence_count; sentence_index++) {
        context_token = ""
        clause_count = split(sentences[sentence_index], clauses, /[;:]/)
        for (clause_index = 1; clause_index <= clause_count; clause_index++) {
          clause = clauses[clause_index]
          stripped = clause
          gsub(/docs\/sprints\//, "", stripped)
          gsub(/docs\/work\/confidence\.txt/, "", stripped)
          token = ""
          if (stripped ~ /(^|[^[:alnum:]_.-])sprints\//)
            token = "sprints/"
          else if (stripped ~ /agent-tasks\//)
            token = "agent-tasks/"
          else if (stripped ~ /decisions\.md/)
            token = "decisions.md"
          else if (stripped ~ /(^|[^[:alnum:]_.-])confidence\.txt/)
            token = "confidence.txt"

          if (token != "")
            context_token = token
          else if (explicit_docs_authority(clause)) {
            context_token = ""
            continue
          } else if (context_token != "" && authority_continuation(clause))
            token = context_token
          else {
            context_token = ""
            continue
          }

          active = stripped ~ /project[ -]root|root.*(contains|has|uses|stores)|activat(e|ion)|resume|canonical|semantic authority|authoritative|authority|system of record|official|resides?|owns?|source of truth|writable|(^|[^a-z])write([^a-z]|$)|(^|[^a-z])create([^a-z]|$)|(^|[^a-z])update([^a-z]|$)|persist|queue|task state|decision state|state (lives|is)/
          if (active && !legacy_safe(clause))
            return token
        }
      }
      return ""
    }

    function remote_source_negated(text, position, prefix) {
      prefix = substr(text, 1, position - 1)
      return prefix ~ /(^|[^a-z])(without|no|not|never)([^a-z]|$)[^,;:.!?]*$/
    }

    function positive_remote_authority(text, rest, offset, position, consumed) {
      rest = text
      offset = 0
      while (match(rest, /(an?[ \t]+)?explicit[ \t]+(user[ \t]+)?request|declared[ \t]+preauthorized-remote[ \t]+profile/)) {
        position = offset + RSTART
        if (!remote_source_negated(text, position))
          return 1
        consumed = RSTART + RLENGTH - 1
        offset += consumed
        rest = substr(rest, RSTART + RLENGTH)
      }
      return 0
    }

    function autonomy_violation(text, parts, count, i, sentence, remote, signal, authorized) {
      text = normalize_clauses(text)
      count = split(text, parts, /[.!?;:]/)
      for (i = 1; i <= count; i++) {
        sentence = parts[i]
        authorized = positive_remote_authority(sentence)

        if (match(sentence, /proceed(s)?[ \t]+autonomously/)) {
          signal = index(substr(sentence, RSTART), "autonomously") + RSTART - 1
          if (!negation_before(sentence, signal))
            return 1
        }

        remote = sentence ~ /(^|[^a-z])(push|merge|release|force-push|delete)([^a-z]|$)|material[ \t]+scope[ \t]+expansion/
        if (remote && match(sentence, /automatic(ally)?|autonomously|without[^.!?;:]*(asking|confirmation|approval|request|prompt)|no[ \t-]*(confirmation|approval|request|prompt)/)) {
          signal = RSTART
          if (!authorized && !negation_before(sentence, signal))
            return 1
        }

        if (match(sentence, /gh[ \t]+pr[ \t]+merge|force-push[^.!?;:]*re-verify/)) {
          if (!authorized && !negation_before(sentence, RSTART))
            return 1
        }

        if (match(sentence, /(^|[^a-z])commit,[ \t]*push,[ \t]*and[ \t]*merge([^a-z]|$)/)) {
          if (!authorized && !negation_before(sentence, RSTART))
            return 1
        }
      }
      return 0
    }

    function permission_violation(text, parts, count, i, sentence, flag, change) {
      text = normalize_clauses(text)
      count = split(text, parts, /[.!?;:]/)
      for (i = 1; i <= count; i++) {
        sentence = parts[i]
        if (match(sentence, /--ask-for-approval|--sandbox([= \t]|$)|dangerously-skip-permissions/)) {
          flag = RSTART
          if (!negation_before(sentence, flag))
            return 1
        }
        if (match(sentence, /(^|[^a-z])(set|switch|change|weaken|disable|bypass|enlarge|expand|grant|authorize)([^a-z]|$)[^.!?;:]*(approval|permission|sandbox|security control|authority)/)) {
          change = RSTART
          if (!negation_before(sentence, change))
            return 1
        }
      }
      return 0
    }

    function trailing_sentence(text, parts, count) {
      text = normalize_clauses(text)
      count = split(text, parts, /[.!?]/)
      if (text ~ /[.!?][ \t]*$/)
        return ""
      return parts[count]
    }

    FNR == 1 {
      legacy_reported_clause = 0
      clause = ""
    }

    {
      line = tolower($0)
      blank = line ~ /^[ \t]*$/
      heading = line ~ /^[ \t]*#+([ \t]|$)/

      # Blank lines and Markdown headings are clause boundaries. Scan heading
      # text itself, but never combine it with either adjacent section.
      if (blank || heading) {
        clause = ""
        legacy_reported_clause = 0
      }
      if (blank)
        next

      combined = (clause == "" ? line : clause " " line)

      # Evaluate the accumulated unfinished sentence so declarations and
      # authority continuations may wrap across any number of lines.
      token = legacy_token(combined)
      if (token != "" && !legacy_reported_clause)
        emit("active legacy authority", "\047" token "\047")
      legacy_reported_clause = (token != "")

      if (autonomy_violation(combined))
        emit("autonomous remote authorization", "")
      if (permission_violation(combined))
        emit("permission expansion", "")

      clause = trailing_sentence(combined)
      if (clause == "")
        legacy_reported_clause = 0
      if (heading) {
        clause = ""
        legacy_reported_clause = 0
      }
    }
  ' "${files[@]}")

  if [ -n "$output" ]; then
    printf '%s\n' "$output" >&2
    FAILED=1
  fi
}

check_adapter_surfaces claude "${CLAUDE_ACTIVE[@]}"
check_adapter_surfaces codex "${CODEX_ACTIVE[@]}"
check_adapter_surfaces antigravity "${ANTIGRAVITY_ACTIVE[@]}"
check_adapter_surfaces open-harnesses "${OPEN_ACTIVE[@]}"
check_retired_branch_model

check_version_anchor claude "claude-code/skills/sprint-loop/SKILL.md" 'Book schema v2 keeps semantic intent'
check_version_anchor codex "codex-cli/skills/sprint-loops/SKILL.md" 'Sprint Loops Book v2 workflow'
check_version_anchor antigravity "antigravity-ide/global_workflows/sprint-loops.md" 'contains `schema-version: 2`'

check_profile_contract claude "claude-code/skills/sprint-loop/SKILL.md"
check_profile_contract codex "codex-cli/skills/sprint-loops/SKILL.md"
check_profile_contract antigravity "antigravity-ide/global_workflows/sprint-loops.md"
check_version_anchor open-harnesses "open-harnesses/particles/00-overview.md" 'canonical Project Book is docs/ using schema v2'

check_role_anchor claude "claude-code/skills/sprint-loop/phases/00-overview.md"
check_role_anchor codex "codex-cli/skills/sprint-loops/phases/00-overview.md"
check_role_anchor antigravity "antigravity-ide/global_workflows/sprint-loops.md"
check_role_anchor open-harnesses "open-harnesses/particles/00-overview.md"

check_remote_rule claude "${CLAUDE_ACTIVE[@]}"
check_remote_rule codex "${CODEX_ACTIVE[@]}"
check_remote_rule antigravity "${ANTIGRAVITY_ACTIVE[@]}"

check_claude_native
check_codex_native
check_antigravity_native
check_open_native

scan_adapter claude "${CLAUDE_ACTIVE[@]}"
scan_adapter codex "${CODEX_ACTIVE[@]}"
scan_adapter antigravity "${ANTIGRAVITY_ACTIVE[@]}"
scan_adapter open-harnesses "${OPEN_ACTIVE[@]}"

if [ "$FAILED" -eq 0 ]; then
  echo "adapter-semantics: all adapter contracts satisfied"
  exit 0
fi
exit 1
