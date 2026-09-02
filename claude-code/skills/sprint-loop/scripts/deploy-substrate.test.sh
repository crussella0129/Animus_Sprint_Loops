#!/usr/bin/env bash
# Fixtures for deploy-substrate.sh — two-branch deploy, updater routing,
# idempotency, rollback cleanup/preservation, and conflict refusal.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DS="$SCRIPT_DIR/deploy-substrate.sh"
CS="$SCRIPT_DIR/check-substrate.sh"
INIT="$SCRIPT_DIR/init-sprint.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-deploy.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM
pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

snap() {
  {
    find "$1" -type f -not -path '*/.git/*' -exec cksum {} +
    git -C "$1" show-ref
  } 2>/dev/null | LC_ALL=C sort | cksum
}
branch_set() {
  git -C "$1" for-each-ref --format='%(refname:short)' refs/heads |
    LC_ALL=C sort | paste -sd ' ' -
}

# test_deploy_hosted_targets_work + test_deploy_exact_branch_set
C="$TMP_ROOT/fresh"; mkdir -p "$C"
bash "$DS" --root "$C" --provider github --base main --work dev > /dev/null 2>"$C.err" ||
  die test_deploy_hosted_targets_work "deploy failed: $(cat "$C.err")"
[ "$(bash "$CS" --root "$C" 2>/dev/null)" = substrate-complete ] ||
  die test_deploy_hosted_targets_work 'not complete after deploy'
[ "$(branch_set "$C")" = 'dev main' ] ||
  die test_deploy_exact_branch_set "unexpected branches: $(branch_set "$C")"
[ -f "$C/.github/dependabot.yml" ] ||
  die test_deploy_hosted_targets_work 'no dependabot.yml scaffolded'
grep -q 'target-branch: "dev"' "$C/.github/dependabot.yml" ||
  die test_deploy_hosted_targets_work 'Dependabot does not target work'
git -C "$C" ls-files --error-unmatch .github/dependabot.yml >/dev/null 2>&1 ||
  die test_deploy_hosted_targets_work 'dependabot.yml not committed'
pass test_deploy_hosted_targets_work
pass test_deploy_exact_branch_set

# test_deploy_idempotent
before=$(snap "$C")
bash "$DS" --root "$C" >/dev/null 2>&1 || die test_deploy_idempotent 'rerun failed'
after=$(snap "$C")
[ "$before" = "$after" ] || die test_deploy_idempotent 'rerun changed state'
pass test_deploy_idempotent

# test_deploy_rolls_back
F="$TMP_ROOT/rollback"; mkdir -p "$F"
if DEPLOY_SUBSTRATE_FAIL_AFTER=branches bash "$DS" --root "$F" \
    --provider github --base main --work dev >/dev/null 2>"$F.err"; then
  die test_deploy_rolls_back 'injected failure did not fail'
fi
[ ! -e "$F/docs" ] || die test_deploy_rolls_back 'docs/ left behind'
[ ! -e "$F/.git" ] || die test_deploy_rolls_back '.git left behind'
[ ! -e "$F/.github" ] || die test_deploy_rolls_back 'updater config left behind'
pass test_deploy_rolls_back

# test_deploy_rollback_preserves_preexisting
P="$TMP_ROOT/preserve"; mkdir -p "$P/.github"
git init -q -b keep "$P"
printf 'seed\n' > "$P/seed.txt"
printf 'version: 2\n# project-owned\n' > "$P/.github/dependabot.yml"
git -C "$P" add seed.txt .github/dependabot.yml
git -C "$P" -c user.email=t@t -c user.name=t commit -q -m seed
seed_before=$(cksum "$P/seed.txt")
config_before=$(cksum "$P/.github/dependabot.yml")
keep_before=$(git -C "$P" rev-parse keep)
if DEPLOY_SUBSTRATE_FAIL_AFTER=branches bash "$DS" --root "$P" \
    --provider github --base main --work dev >/dev/null 2>"$P.err"; then
  die test_deploy_rollback_preserves_preexisting 'injected failure did not fail'
fi
[ "$seed_before" = "$(cksum "$P/seed.txt")" ] ||
  die test_deploy_rollback_preserves_preexisting 'seed file changed'
[ "$config_before" = "$(cksum "$P/.github/dependabot.yml")" ] ||
  die test_deploy_rollback_preserves_preexisting 'updater config changed'
[ "$keep_before" = "$(git -C "$P" rev-parse keep)" ] ||
  die test_deploy_rollback_preserves_preexisting 'pre-existing ref changed'
[ "$(branch_set "$P")" = keep ] ||
  die test_deploy_rollback_preserves_preexisting "created refs survived: $(branch_set "$P")"
[ ! -e "$P/docs" ] ||
  die test_deploy_rollback_preserves_preexisting 'created Book survived'
pass test_deploy_rollback_preserves_preexisting

# test_deploy_refuses_conflict
X="$TMP_ROOT/conflict"; mkdir -p "$X"
( cd "$X" && SPRINT_LOOP_PROJECT_ROOT=. bash "$INIT" --scaffold-only >/dev/null )
mkdir -p "$X/sprints/s0"; printf 'legacy\n' > "$X/sprints/s0/state.txt"
if bash "$DS" --root "$X" >/dev/null 2>"$X.err"; then
  die test_deploy_refuses_conflict 'conflict accepted'
fi
grep -qiE 'split-brain|conflict|legacy' "$X.err" ||
  die test_deploy_refuses_conflict 'no conflict diagnostic'
pass test_deploy_refuses_conflict

# test_deploy_updater_variants — hosted providers target work; local-only none.
G="$TMP_ROOT/gitlab"; mkdir -p "$G"
bash "$DS" --root "$G" --provider gitlab --base main --work dev >/dev/null 2>&1 ||
  die test_deploy_updater_variants 'gitlab deploy failed'
[ "$(branch_set "$G")" = 'dev main' ] ||
  die test_deploy_updater_variants "unexpected GitLab branches: $(branch_set "$G")"
[ -f "$G/renovate.json" ] || die test_deploy_updater_variants 'no Renovate config for gitlab'
grep -q '"baseBranchPatterns": \["dev"\]' "$G/renovate.json" ||
  die test_deploy_updater_variants 'GitLab Renovate does not target work'
[ ! -f "$G/.github/dependabot.yml" ] ||
  die test_deploy_updater_variants 'gitlab wrote dependabot.yml'

N="$TMP_ROOT/generic"; mkdir -p "$N"
bash "$DS" --root "$N" --provider generic --base main --work dev >/dev/null 2>&1 ||
  die test_deploy_updater_variants 'generic deploy failed'
[ "$(branch_set "$N")" = 'dev main' ] ||
  die test_deploy_updater_variants "unexpected generic branches: $(branch_set "$N")"
grep -q '"baseBranchPatterns": \["dev"\]' "$N/renovate.json" ||
  die test_deploy_updater_variants 'generic Renovate does not target work'

L="$TMP_ROOT/localonly"; mkdir -p "$L"
bash "$DS" --root "$L" --provider local-only --base main --work dev >/dev/null 2>&1 ||
  die test_deploy_updater_variants 'local-only deploy failed'
{ [ ! -f "$L/.github/dependabot.yml" ] && [ ! -f "$L/renovate.json" ]; } ||
  die test_deploy_updater_variants 'local-only scaffolded an updater'
pass test_deploy_updater_variants

# test_deploy_no_clobber
E="$TMP_ROOT/existing"; mkdir -p "$E/.github"
printf 'version: 2\n# hand-written\n' > "$E/.github/dependabot.yml"
before_cfg=$(cksum "$E/.github/dependabot.yml")
bash "$DS" --root "$E" --provider github --base main --work dev >/dev/null 2>&1 ||
  die test_deploy_no_clobber 'existing-config deploy failed'
[ "$before_cfg" = "$(cksum "$E/.github/dependabot.yml")" ] ||
  die test_deploy_no_clobber 'clobbered an existing dependabot.yml'

R="$TMP_ROOT/existing-renovate"; mkdir -p "$R"
printf '{"extends":["project-owned"]}\n' > "$R/renovate.json"
before_renovate=$(cksum "$R/renovate.json")
bash "$DS" --root "$R" --provider generic --base main --work dev >/dev/null 2>&1 ||
  die test_deploy_no_clobber 'existing-Renovate deploy failed'
[ "$before_renovate" = "$(cksum "$R/renovate.json")" ] ||
  die test_deploy_no_clobber 'clobbered an existing renovate.json'
pass test_deploy_no_clobber

# The bundle's own contract version drives the fixtures.
# shellcheck source=book-paths.sh
. "$SCRIPT_DIR/book-paths.sh"
V=$BOOK_SUBSTRATE_CONTRACT_VERSION
marker_of() { printf '%s/docs/.sprint-loop-book' "$1"; }

# test_converge_stamps_unstamped_book + test_converge_verifies_after_stamp —
# a complete but unstamped Book is the upgrade case this entrypoint exists for.
U="$TMP_ROOT/converge"; mkdir -p "$U"
bash "$DS" --root "$U" --provider github --base main --work dev >/dev/null 2>&1 ||
  die test_converge_stamps_unstamped_book 'initial deploy failed'
# Reset it to contract version 1 to model a project deployed by an older bundle.
printf 'schema-version: 2\n' > "$(marker_of "$U")"
git -C "$U" -c user.email=t@t -c user.name=t commit -q -am 'unstamp' 2>/dev/null || true
[ "$(bash "$CS" --root "$U" 2>/dev/null)" = "substrate-outdated:1->$V" ] ||
  die test_converge_stamps_unstamped_book "expected outdated, got '$(bash "$CS" --root "$U" 2>/dev/null)'"
out=$(bash "$DS" --root "$U" 2>"$U.err") ||
  die test_converge_verifies_after_stamp "convergence failed: $(cat "$U.err")"
case "$out" in *substrate-complete*) : ;; *) die test_converge_verifies_after_stamp "no success line: $out" ;; esac
[ "$(grep -c 'substrate-version' "$(marker_of "$U")")" = 1 ] ||
  die test_converge_stamps_unstamped_book 'expected exactly one substrate-version line'
grep -qFx "substrate-version: $V" "$(marker_of "$U")" ||
  die test_converge_stamps_unstamped_book 'stamp value wrong'
grep -qFx 'schema-version: 2' "$(marker_of "$U")" ||
  die test_converge_stamps_unstamped_book 'schema-version line was not preserved'
[ "$(bash "$CS" --root "$U" 2>/dev/null)" = substrate-complete ] ||
  die test_converge_stamps_unstamped_book 'not complete after convergence'
pass test_converge_stamps_unstamped_book
pass test_converge_verifies_after_stamp

# test_deploy_idempotent for the stamp: a converged project is a byte no-op.
before_conv=$(snap "$U")
bash "$DS" --root "$U" >/dev/null 2>&1 || die test_converge_idempotent 'converged re-run failed'
[ "$before_conv" = "$(snap "$U")" ] || die test_converge_idempotent 'converged re-run changed state'
pass test_converge_idempotent

# test_converge_check_is_readonly
printf 'schema-version: 2\n' > "$(marker_of "$U")"
before_check=$(snap "$U")
if check_out=$(bash "$DS" --root "$U" --check 2>&1); then
  die test_converge_check_is_readonly 'exit 0 with a pending step'
fi
case "$check_out" in *"stamp substrate-version: $V"*) : ;; *) die test_converge_check_is_readonly "pending stamp not reported: $check_out" ;; esac
[ "$before_check" = "$(snap "$U")" ] || die test_converge_check_is_readonly 'check mutated the project'
bash "$DS" --root "$U" >/dev/null 2>&1 || die test_converge_check_is_readonly 'convergence after check failed'
check_out=$(bash "$DS" --root "$U" --check 2>&1) ||
  die test_converge_check_is_readonly 'check exits non-zero on a converged project'
case "$check_out" in *'no pending steps'*) : ;; *) die test_converge_check_is_readonly "converged check output: $check_out" ;; esac
pass test_converge_check_is_readonly

# test_converge_refuses_ahead_book — never converge backwards.
printf 'schema-version: 2\nsubstrate-version: 99\n' > "$(marker_of "$U")"
before_ahead=$(snap "$U")
if bash "$DS" --root "$U" >/dev/null 2>"$U.ahead"; then
  die test_converge_refuses_ahead_book 'ahead Book accepted'
fi
grep -q '99' "$U.ahead" && grep -q "$V" "$U.ahead" ||
  die test_converge_refuses_ahead_book "diagnostic names neither version: $(cat "$U.ahead")"
[ "$before_ahead" = "$(snap "$U")" ] || die test_converge_refuses_ahead_book 'ahead refusal mutated the project'
pass test_converge_refuses_ahead_book

# test_converge_rolls_back_stamp
printf 'schema-version: 2\n' > "$(marker_of "$U")"
marker_before=$(cksum "$(marker_of "$U")")
if DEPLOY_SUBSTRATE_FAIL_AFTER=stamp bash "$DS" --root "$U" >/dev/null 2>&1; then
  die test_converge_rolls_back_stamp 'injected failure did not fail'
fi
[ "$marker_before" = "$(cksum "$(marker_of "$U")")" ] ||
  die test_converge_rolls_back_stamp 'marker not restored after rollback'
pass test_converge_rolls_back_stamp

printf 'deploy-substrate selftest: all fixtures passed\n'
