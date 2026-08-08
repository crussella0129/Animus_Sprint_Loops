#!/usr/bin/env bash
# Fixtures for check-substrate.sh — two-branch complete/absent/partial/read-only.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CS="$SCRIPT_DIR/check-substrate.sh"
INIT="$SCRIPT_DIR/init-sprint.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-substrate.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM
pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

git_init_branches() {  # <dir> <branch>...
  local d="$1"; shift
  git init -q "$d"
  git -C "$d" checkout -q -b _setup
  git -C "$d" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  local b
  for b in "$@"; do git -C "$d" branch -f "$b" _setup; done
}
make_book() { ( cd "$1" && SPRINT_LOOP_PROJECT_ROOT=. bash "$INIT" --scaffold-only >/dev/null ); }
make_profile() {  # <dir> <body>
  mkdir -p "$1/docs/work"
  printf '# Remote Profile\n\n<!-- sprint-loop-remote-profile-v2 -->\n\n```\n%s\n```\n' \
    "$2" > "$1/docs/work/remote-profile.md"
}
run() { bash "$CS" --root "$1" 2>/dev/null; }

# test_substrate_two_branch_complete
C="$TMP_ROOT/complete"; git_init_branches "$C" main dev; make_book "$C"
make_profile "$C" 'provider: github
base: main
work: dev'
[ "$(run "$C")" = substrate-complete ] || die test_substrate_two_branch_complete "got '$(run "$C")'"
bash "$CS" --root "$C" >/dev/null 2>&1 || die test_substrate_two_branch_complete 'exit non-zero for complete'
pass test_substrate_two_branch_complete

# test_substrate_absent
A="$TMP_ROOT/absent"; mkdir -p "$A"
[ "$(run "$A")" = substrate-absent ] || die test_substrate_absent "got '$(run "$A")'"
if bash "$CS" --root "$A" >/dev/null 2>&1; then die test_substrate_absent 'exit 0 for absent'; fi
pass test_substrate_absent

# test_substrate_partial_no_branches
NB="$TMP_ROOT/nobranch"; git_init_branches "$NB" main; make_book "$NB"
make_profile "$NB" 'provider: github
base: main
work: dev'
case "$(run "$NB")" in substrate-partial:*branch:dev*) : ;; *) die test_substrate_partial_no_branches "got '$(run "$NB")'";; esac
pass test_substrate_partial_no_branches

# test_substrate_partial_no_profile
NP="$TMP_ROOT/noprofile"; git_init_branches "$NP" main dev; make_book "$NP"
case "$(run "$NP")" in substrate-partial:*profile*) : ;; *) die test_substrate_partial_no_profile "got '$(run "$NP")'";; esac
pass test_substrate_partial_no_profile

# test_substrate_is_readonly
R="$TMP_ROOT/ro"; git_init_branches "$R" main dev; make_book "$R"
make_profile "$R" 'provider: github
base: main
work: dev'
snap() { find "$1" -type f -not -path '*/.git/*' -exec cksum {} + | LC_ALL=C sort | cksum; }
before=$(snap "$R"); ph_before=$(cksum "$SCRIPT_DIR/current-phase.sh")
run "$R" >/dev/null
after=$(snap "$R"); ph_after=$(cksum "$SCRIPT_DIR/current-phase.sh")
[ "$before" = "$after" ] || die test_substrate_is_readonly 'working tree mutated'
[ "$ph_before" = "$ph_after" ] || die test_substrate_is_readonly 'current-phase.sh changed'
pass test_substrate_is_readonly

# test_substrate_local_only_complete
LO="$TMP_ROOT/local"; git_init_branches "$LO" main dev; make_book "$LO"
make_profile "$LO" 'provider: local-only
base: main
work: dev'
[ "$(run "$LO")" = substrate-complete ] || die test_substrate_local_only_complete "got '$(run "$LO")'"
pass test_substrate_local_only_complete

printf 'check-substrate selftest: all fixtures passed\n'
