#!/usr/bin/env bash
# Fixtures for scaffold-ci.sh — per-host CI generation.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SC="$SCRIPT_DIR/scaffold-ci.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-scaffold.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM
pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

project() {  # <name> [file...] -> prints the project dir
  local d="$TMP_ROOT/$1"; shift
  mkdir -p "$d"
  git init -q "$d"
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  local f
  for f in "$@"; do
    mkdir -p "$d/$(dirname "$f")"
    printf 'fixture\n' > "$d/$f"
  done
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" commit -qm fixture >/dev/null 2>&1
  printf '%s' "$d"
}
gen() {  # <dir> <provider> [base] [work]
  bash "$SC" --root "$1" --provider "$2" --base "${3:-main}" --work "${4:-dev}"
}

# test_scaffold_paths_per_provider
declare -A EXPECTED=(
  [github]=.github/workflows/sprint-loops-ci.yml
  [gitea]=.gitea/workflows/sprint-loops-ci.yml
  [forgejo]=.forgejo/workflows/sprint-loops-ci.yml
  [gitlab]=.gitlab-ci.yml
  [generic]=ci.sh
)
for provider in github gitea forgejo gitlab generic; do
  d=$(project "path-$provider" Cargo.toml)
  gen "$d" "$provider" >/dev/null || die test_scaffold_paths_per_provider "$provider generation failed"
  [ -f "$d/${EXPECTED[$provider]}" ] ||
    die test_scaffold_paths_per_provider "$provider did not write ${EXPECTED[$provider]}"
done
[ -x "$TMP_ROOT/path-generic/ci.sh" ] || die test_scaffold_paths_per_provider 'generic ci.sh is not executable'
pass test_scaffold_paths_per_provider

# test_scaffold_local_only_writes_nothing
LO=$(project local-only Cargo.toml)
before_lo=$(find "$LO" -type f -not -path '*/.git/*' | LC_ALL=C sort)
gen "$LO" local-only >/dev/null || die test_scaffold_local_only_writes_nothing 'local-only failed'
[ "$before_lo" = "$(find "$LO" -type f -not -path '*/.git/*' | LC_ALL=C sort)" ] ||
  die test_scaffold_local_only_writes_nothing 'local-only wrote a file'
pass test_scaffold_local_only_writes_nothing

# test_scaffold_refuses_existing_workflow_dir — directory-level, so a generated
# workflow can never sit beside a hand-written one.
EX=$(project existing-wf Cargo.toml .github/workflows/ci.yml)
existing_before=$(cksum "$EX/.github/workflows/ci.yml")
ex_out=$(gen "$EX" github)
[ ! -f "$EX/.github/workflows/sprint-loops-ci.yml" ] ||
  die test_scaffold_refuses_existing_workflow_dir 'wrote a second workflow beside the existing one'
[ "$existing_before" = "$(cksum "$EX/.github/workflows/ci.yml")" ] ||
  die test_scaffold_refuses_existing_workflow_dir 'modified the existing workflow'
case "$ex_out" in *'leaving the existing configuration alone'*) : ;; *) die test_scaffold_refuses_existing_workflow_dir "no message: $ex_out" ;; esac
pass test_scaffold_refuses_existing_workflow_dir

# test_scaffold_triggers_name_both_branches — non-default names prove the
# branches come from the caller's profile and not from a literal.
TB=$(project triggers Cargo.toml)
gen "$TB" github trunk working >/dev/null
grep -q 'branches: \[trunk, working\]' "$TB/.github/workflows/sprint-loops-ci.yml" ||
  die test_scaffold_triggers_name_both_branches "triggers wrong: $(grep branches "$TB/.github/workflows/sprint-loops-ci.yml")"
[ "$(grep -c 'branches: \[trunk, working\]' "$TB/.github/workflows/sprint-loops-ci.yml")" = 2 ] ||
  die test_scaffold_triggers_name_both_branches 'push and pull_request are not both covered'
TG=$(project triggers-gitlab Cargo.toml)
gen "$TG" gitlab trunk working >/dev/null
grep -q 'CI_COMMIT_BRANCH == "trunk"' "$TG/.gitlab-ci.yml" || die test_scaffold_triggers_name_both_branches 'gitlab base rule missing'
grep -q 'CI_COMMIT_BRANCH == "working"' "$TG/.gitlab-ci.yml" || die test_scaffold_triggers_name_both_branches 'gitlab work rule missing'
pass test_scaffold_triggers_name_both_branches

# test_scaffold_jobs_match_detection
R=$(project jobs-rust Cargo.toml)
gen "$R" github >/dev/null
grep -q '^  rust:' "$R/.github/workflows/sprint-loops-ci.yml" || die test_scaffold_jobs_match_detection 'no rust job'
grep -q '^  node:' "$R/.github/workflows/sprint-loops-ci.yml" && die test_scaffold_jobs_match_detection 'node job in a rust-only project'
grep -q 'cargo test' "$R/.github/workflows/sprint-loops-ci.yml" || die test_scaffold_jobs_match_detection 'rust job does not run cargo test'
PG=$(project jobs-poly Cargo.toml go.mod package.json)
gen "$PG" github >/dev/null
for job in rust go node; do
  grep -q "^  $job:" "$PG/.github/workflows/sprint-loops-ci.yml" ||
    die test_scaffold_jobs_match_detection "polyglot project missing the $job job"
done
pass test_scaffold_jobs_match_detection

# test_scaffold_uses_canonical_runner
CN=$(project canonical Cargo.toml tools/run-guards.sh)
gen "$CN" github >/dev/null
grep -q 'bash tools/run-guards.sh' "$CN/.github/workflows/sprint-loops-ci.yml" ||
  die test_scaffold_uses_canonical_runner 'canonical runner not invoked'
grep -q '^  rust:' "$CN/.github/workflows/sprint-loops-ci.yml" &&
  die test_scaffold_uses_canonical_runner 'per-language jobs emitted alongside the canonical runner'
pass test_scaffold_uses_canonical_runner

# test_scaffold_is_byte_stable — the guard runner compares two runs.
S1=$(project stable-1 Cargo.toml go.mod); gen "$S1" github >/dev/null
S2=$(project stable-2 Cargo.toml go.mod); gen "$S2" github >/dev/null
cmp -s "$S1/.github/workflows/sprint-loops-ci.yml" "$S2/.github/workflows/sprint-loops-ci.yml" ||
  die test_scaffold_is_byte_stable 'identical inputs produced different output'
pass test_scaffold_is_byte_stable

# test_scaffold_generic_ci_actually_fails — the generic host's output is a shell
# script, so it is the only generated configuration a fixture can execute. Shell
# is the language used because the guard suite already requires shellcheck, so
# the check is real rather than dependent on a toolchain that may be absent.
shell_project() {  # <name> <script-body> -> prints the project dir
  local d="$TMP_ROOT/$1"
  mkdir -p "$d"
  git init -q "$d"
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  printf '%s\n' "$2" > "$d/script.sh"
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" commit -qm fixture >/dev/null 2>&1
  printf '%s' "$d"
}

OKP=$(shell_project generic-ok '#!/usr/bin/env bash
echo ok')
gen "$OKP" generic >/dev/null
( cd "$OKP" && bash ./ci.sh >/dev/null 2>&1 ) ||
  die test_scaffold_generic_ci_actually_fails 'a clean project failed its generated ci.sh'

BADP=$(shell_project generic-bad '#!/usr/bin/env bash
if [ 1 -eq 1 ]; then
  echo unterminated')
gen "$BADP" generic >/dev/null
if ( cd "$BADP" && bash ./ci.sh >/dev/null 2>&1 ); then
  die test_scaffold_generic_ci_actually_fails 'a project with a broken script passed its generated ci.sh'
fi
pass test_scaffold_generic_ci_actually_fails

# test_scaffold_python_tolerates_no_tests — a narrow exit-5 allowance, never a
# blanket swallow that a CI truth check should reject.
PY=$(project python-tolerance pyproject.toml)
gen "$PY" github >/dev/null
grep -q 'rc" -eq 5' "$PY/.github/workflows/sprint-loops-ci.yml" ||
  die test_scaffold_python_tolerates_no_tests 'no exit-5 allowance'
grep -q '|| true' "$PY/.github/workflows/sprint-loops-ci.yml" &&
  die test_scaffold_python_tolerates_no_tests 'generated a blanket failure swallow'
grep -q 'continue-on-error' "$PY/.github/workflows/sprint-loops-ci.yml" &&
  die test_scaffold_python_tolerates_no_tests 'generated continue-on-error'
pass test_scaffold_python_tolerates_no_tests

printf 'scaffold-ci selftest: all fixtures passed\n'
