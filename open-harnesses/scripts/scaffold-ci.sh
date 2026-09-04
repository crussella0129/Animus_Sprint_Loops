#!/usr/bin/env bash
# Generate the host's CI configuration from the languages a project contains.
#
# A fresh Sprint Loops project has a Book, branches, a remote profile, and an
# updater config — and no CI at all, so its first checkpoint is green because
# nothing ran. That is worse than a red one: it spends a reviewer's trust on a
# check that never happened.
#
# Four hosts, two formats. Gitea and Forgejo consume GitHub Actions workflow
# syntax, so those three share one renderer and differ only by directory;
# GitLab gets .gitlab-ci.yml; `generic` gets a portable ci.sh a human or a
# foreign runner can invoke; `local-only` gets nothing, because it has no host.
#
# Never clobbering is DIRECTORY-level, not file-level: if the host's workflow
# directory already holds anything, generate nothing. A file-level check would
# drop a second workflow beside a project's hand-written one and leave two CI
# systems disagreeing about the same push.
#
# Triggers come from the caller, which passes the remote profile's branches. A
# workflow triggering only on the base branch never runs on the branch sprints
# commit to, nor on the checkpoint itself.
#
# Usage: scaffold-ci.sh [--root <dir>] --provider <p> --base <b> --work <w>
#        [--check]        report what would be written, write nothing
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT="${SPRINT_LOOP_PROJECT_ROOT:-.}"
PROVIDER=""; BASE=""; WORK=""; CHECK_ONLY=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) SPRINT_LOOP_PROJECT_ROOT="$2"; shift 2 ;;
    --provider) PROVIDER="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --work) WORK="$2"; shift 2 ;;
    --check) CHECK_ONLY=1; shift ;;
    *) echo "scaffold-ci: unknown argument $1" >&2; exit 2 ;;
  esac
done
. "$SCRIPT_DIR/book-paths.sh"
ROOT="$SPRINT_LOOP_PROJECT_ROOT"

fail() { printf 'scaffold-ci: %s\n' "$*" >&2; exit 1; }
[ -n "$PROVIDER" ] || fail "expected --provider"
[ -n "$BASE" ] || fail "expected --base"
[ -n "$WORK" ] || fail "expected --work"

# Where each host reads its configuration, and which directory must be empty.
case "$PROVIDER" in
  github)  CI_DIR="$ROOT/.github/workflows";  CI_PATH="$CI_DIR/sprint-loops-ci.yml"; FORMAT=actions ;;
  gitea)   CI_DIR="$ROOT/.gitea/workflows";   CI_PATH="$CI_DIR/sprint-loops-ci.yml"; FORMAT=actions ;;
  forgejo) CI_DIR="$ROOT/.forgejo/workflows"; CI_PATH="$CI_DIR/sprint-loops-ci.yml"; FORMAT=actions ;;
  gitlab)  CI_DIR="$ROOT";                    CI_PATH="$ROOT/.gitlab-ci.yml";        FORMAT=gitlab ;;
  generic) CI_DIR="$ROOT";                    CI_PATH="$ROOT/ci.sh";                 FORMAT=script ;;
  local-only)
    echo "scaffold-ci: local-only profile; no CI configuration to generate"
    exit 0 ;;
  *) fail "unknown provider '$PROVIDER'" ;;
esac

# Directory-level no-clobber. For the single-file hosts the "directory" check is
# the file itself; for the Actions hosts any existing workflow means the project
# already has CI and this generator stays out of it.
if [ "$FORMAT" = actions ]; then
  if [ -d "$CI_DIR" ] && [ -n "$(ls -A "$CI_DIR" 2>/dev/null)" ]; then
    printf 'scaffold-ci: %s already contains a workflow; leaving the existing configuration alone\n' "${CI_DIR#"$ROOT"/}"
    exit 0
  fi
elif [ -e "$CI_PATH" ]; then
  printf 'scaffold-ci: %s already exists; leaving the existing configuration alone\n' "${CI_PATH#"$ROOT"/}"
  exit 0
fi

LANGS=$(bash "$SCRIPT_DIR/detect-languages.sh" --root "$ROOT")
CANONICAL=$(printf '%s\n' "$LANGS" | sed -n 's/^canonical://p' | head -n 1)
LANGS=$(printf '%s\n' "$LANGS" | grep -v '^canonical:' | grep -v '^$')

if [ -z "$CANONICAL" ] && [ -z "$LANGS" ]; then
  echo "scaffold-ci: no recognized languages and no canonical runner; nothing to generate"
  exit 0
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  printf 'would create %s\n' "${CI_PATH#"$ROOT"/}"
  exit 0
fi

# The commands each language runs. Chosen to pass on an empty-but-valid project
# of that language: a generated job that is red on day one trains an operator to
# ignore red. `npm test --if-present` is a no-op without a test script, and the
# pytest line tolerates exactly its "no tests collected" code (5) and nothing
# else — a real failure still fails. That narrow allowance is deliberate and is
# not the blanket `|| true` a CI truth check should reject.
#
# The `|| rc=$?` form is required, not stylistic. Every host runs these commands
# under `set -e`: the generated ci.sh sets it, the Actions default shell is
# `bash --noprofile --norc -eo pipefail`, and the GitLab runner injects it. With
# a bare `cmd; rc=$?` the shell exits on pytest's non-zero status before the
# tolerance is ever evaluated, so the allowance is dead code and a project with
# no tests fails the first checkpoint Sprint 0 was written to make green.
lang_commands() {
  case "$1" in
    rust)   printf 'cargo fmt --check\ncargo clippy --all-targets -- -D warnings\ncargo test --all\n' ;;
    go)     printf 'test -z "$(gofmt -l .)"\ngo vet ./...\ngo test ./...\n' ;;
    python) printf 'python -m pytest || rc=$?; [ "${rc:-0}" -eq 0 ] || [ "${rc:-0}" -eq 5 ]\n' ;;
    node)   printf 'npm install --no-audit --no-fund\nnpm test --if-present\n' ;;
    shell)  printf 'git ls-files "*.sh" | xargs -r shellcheck -S warning\n' ;;
  esac
}

emit_actions() {
  printf 'name: sprint-loops-ci\n\n'
  printf '# Generated by Sprint Loops at substrate convergence. This project owns\n'
  printf '# the file now: edit it freely, and deleting it is permanent because\n'
  printf '# generation is create-if-absent.\n\n'
  printf 'on:\n'
  printf '  push:\n    branches: [%s, %s]\n' "$BASE" "$WORK"
  printf '  pull_request:\n    branches: [%s, %s]\n\n' "$BASE" "$WORK"
  printf 'jobs:\n'
  if [ -n "$CANONICAL" ]; then
    printf '  canonical:\n    runs-on: ubuntu-latest\n    steps:\n'
    printf '      - uses: actions/checkout@v4\n'
    printf '      - run: bash %s\n' "$CANONICAL"
    return 0
  fi
  printf '%s\n' "$LANGS" | while IFS= read -r lang; do
    [ -n "$lang" ] || continue
    printf '  %s:\n    runs-on: ubuntu-latest\n    steps:\n' "$lang"
    printf '      - uses: actions/checkout@v4\n'
    lang_commands "$lang" | while IFS= read -r cmd; do
      [ -n "$cmd" ] || continue
      printf '      - run: %s\n' "$cmd"
    done
  done
}

emit_gitlab() {
  printf '# Generated by Sprint Loops at substrate convergence. This project owns\n'
  printf '# the file now: edit it freely, and deleting it is permanent because\n'
  printf '# generation is create-if-absent.\n\n'
  printf 'stages:\n  - test\n\n'
  printf 'workflow:\n  rules:\n'
  printf '    - if: $CI_PIPELINE_SOURCE == "merge_request_event"\n'
  printf '    - if: $CI_COMMIT_BRANCH == "%s"\n' "$BASE"
  printf '    - if: $CI_COMMIT_BRANCH == "%s"\n\n' "$WORK"
  if [ -n "$CANONICAL" ]; then
    printf 'canonical:\n  stage: test\n  script:\n    - bash %s\n' "$CANONICAL"
    return 0
  fi
  printf '%s\n' "$LANGS" | while IFS= read -r lang; do
    [ -n "$lang" ] || continue
    printf '%s:\n  stage: test\n  script:\n' "$lang"
    lang_commands "$lang" | while IFS= read -r cmd; do
      [ -n "$cmd" ] || continue
      printf '    - %s\n' "$cmd"
    done
  done
}

emit_script() {
  printf '#!/usr/bin/env bash\n'
  printf '# Generated by Sprint Loops at substrate convergence: one canonical\n'
  printf '# command a person or a foreign CI runner can invoke. This project owns\n'
  printf '# the file now, and deleting it is permanent.\n'
  printf 'set -euo pipefail\n\n'
  if [ -n "$CANONICAL" ]; then
    printf 'bash %s\n' "$CANONICAL"
    return 0
  fi
  printf '%s\n' "$LANGS" | while IFS= read -r lang; do
    [ -n "$lang" ] || continue
    printf 'echo "== %s =="\n' "$lang"
    lang_commands "$lang"
  done
}

mkdir -p "$(dirname "$CI_PATH")"
case "$FORMAT" in
  actions) emit_actions > "$CI_PATH" ;;
  gitlab)  emit_gitlab  > "$CI_PATH" ;;
  script)  emit_script  > "$CI_PATH"; chmod +x "$CI_PATH" ;;
esac
printf 'scaffold-ci: created %s\n' "${CI_PATH#"$ROOT"/}"
