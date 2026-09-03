#!/usr/bin/env bash
# Fixtures for detect-languages.sh — manifest-driven language detection.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DL="$SCRIPT_DIR/detect-languages.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-detect.XXXXXX")
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
detect() { bash "$DL" --root "$1"; }

# test_detect_rust / test_detect_go / test_detect_node
[ "$(detect "$(project rust Cargo.toml)")" = rust ] || die test_detect_rust "got '$(detect "$TMP_ROOT/rust")'"
pass test_detect_rust
[ "$(detect "$(project go go.mod)")" = go ] || die test_detect_go "got '$(detect "$TMP_ROOT/go")'"
pass test_detect_go
[ "$(detect "$(project node package.json)")" = node ] || die test_detect_node "got '$(detect "$TMP_ROOT/node")'"
pass test_detect_node

# test_detect_python — any of three manifests, and never twice.
for manifest in pyproject.toml requirements.txt setup.py; do
  name="py-$(printf '%s' "$manifest" | tr '.' '-')"
  [ "$(detect "$(project "$name" "$manifest")")" = python ] ||
    die test_detect_python "$manifest did not yield python"
done
[ "$(detect "$(project py-two pyproject.toml requirements.txt)")" = python ] ||
  die test_detect_python 'two python manifests did not yield exactly one token'
pass test_detect_python

# test_detect_shell — tracked only, so scratch files do not decide a language.
[ "$(detect "$(project sh-tracked scripts/build.sh)")" = shell ] || die test_detect_shell 'tracked .sh not detected'
U=$(project sh-untracked README.md)
printf 'scratch\n' > "$U/scratch.sh"
[ -z "$(detect "$U")" ] || die test_detect_shell "untracked .sh was detected: $(detect "$U")"
pass test_detect_shell

# test_detect_polyglot — every token, one per line, sorted.
P=$(project poly Cargo.toml go.mod package.json pyproject.toml scripts/x.sh)
expected=$(printf 'go\nnode\npython\nrust\nshell')
[ "$(detect "$P")" = "$expected" ] || die test_detect_polyglot "got '$(detect "$P")'"
pass test_detect_polyglot

# test_detect_empty_project
E=$(project empty README.md)
[ -z "$(detect "$E")" ] || die test_detect_empty_project "got '$(detect "$E")'"
bash "$DL" --root "$E" >/dev/null 2>&1 || die test_detect_empty_project 'non-zero exit for an empty project'
pass test_detect_empty_project

# test_detect_is_deterministic — the guard runner compares two runs.
[ "$(detect "$P")" = "$(detect "$P")" ] || die test_detect_is_deterministic 'two runs differ'
pass test_detect_is_deterministic

# test_detect_canonical_runner
C=$(project canonical Cargo.toml tools/run-guards.sh)
c_out=$(detect "$C")
case "$c_out" in
  *'canonical:tools/run-guards.sh'*) : ;;
  *) die test_detect_canonical_runner "canonical token missing: $c_out" ;;
esac
[ "$(printf '%s\n' "$c_out" | head -n 1)" = rust ] ||
  die test_detect_canonical_runner 'the canonical token reordered the languages'
pass test_detect_canonical_runner

printf 'detect-languages selftest: all fixtures passed\n'
