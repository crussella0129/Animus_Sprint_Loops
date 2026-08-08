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

printf 'deploy-substrate selftest: all fixtures passed\n'
