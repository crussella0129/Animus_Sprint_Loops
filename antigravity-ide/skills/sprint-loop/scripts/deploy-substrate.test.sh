#!/usr/bin/env bash
# Fixtures for deploy-substrate.sh — create/idempotent/rollback/refuse-conflict.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DS="$SCRIPT_DIR/deploy-substrate.sh"
CS="$SCRIPT_DIR/check-substrate.sh"
INIT="$SCRIPT_DIR/init-sprint.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-deploy.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM
pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

snap() { { find "$1" -type f -not -path '*/.git/*' -exec cksum {} + ; git -C "$1" show-ref; } 2>/dev/null | LC_ALL=C sort | cksum; }

# test_deploy_creates_complete_substrate
C="$TMP_ROOT/fresh"; mkdir -p "$C"
bash "$DS" --root "$C" --provider github --base main --work dev --bump bump >/dev/null 2>"$C.err" ||
  die test_deploy_creates_complete_substrate "deploy failed: $(cat "$C.err")"
[ "$(bash "$CS" --root "$C" 2>/dev/null)" = substrate-complete ] ||
  die test_deploy_creates_complete_substrate 'not complete after deploy'
for b in main dev bump; do
  git -C "$C" show-ref --verify --quiet "refs/heads/$b" || die test_deploy_creates_complete_substrate "missing branch $b"
done
[ -f "$C/.github/dependabot.yml" ] || die test_deploy_creates_complete_substrate 'no dependabot.yml scaffolded'
grep -q 'target-branch: "bump"' "$C/.github/dependabot.yml" || die test_deploy_creates_complete_substrate 'dependabot not targeting bump'
git -C "$C" ls-files --error-unmatch .github/dependabot.yml >/dev/null 2>&1 || die test_deploy_creates_complete_substrate 'dependabot.yml not committed'
pass test_deploy_creates_complete_substrate

# test_deploy_idempotent
before=$(snap "$C")
bash "$DS" --root "$C" >/dev/null 2>&1 || die test_deploy_idempotent 'rerun failed'
after=$(snap "$C")
[ "$before" = "$after" ] || die test_deploy_idempotent 'rerun changed state'
pass test_deploy_idempotent

# test_deploy_rolls_back_on_failure
F="$TMP_ROOT/rollback"; mkdir -p "$F"
if DEPLOY_SUBSTRATE_FAIL_AFTER=branches bash "$DS" --root "$F" --provider github --base main --work dev --bump bump \
    >/dev/null 2>"$F.err"; then
  die test_deploy_rolls_back_on_failure 'injected failure did not fail'
fi
[ ! -e "$F/docs" ] || die test_deploy_rolls_back_on_failure 'docs/ left behind'
[ ! -e "$F/.git" ] || die test_deploy_rolls_back_on_failure '.git left behind'
[ ! -e "$F/.github" ] || die test_deploy_rolls_back_on_failure 'dependabot config left behind'
pass test_deploy_rolls_back_on_failure

# test_deploy_refuses_conflict
X="$TMP_ROOT/conflict"; mkdir -p "$X"
( cd "$X" && SPRINT_LOOP_PROJECT_ROOT=. bash "$INIT" --scaffold-only >/dev/null )
mkdir -p "$X/sprints/s0"; printf 'legacy\n' > "$X/sprints/s0/state.txt"
if bash "$DS" --root "$X" >/dev/null 2>"$X.err"; then die test_deploy_refuses_conflict 'conflict accepted'; fi
grep -qiE 'split-brain|conflict|legacy' "$X.err" || die test_deploy_refuses_conflict 'no conflict diagnostic'
pass test_deploy_refuses_conflict

# test_deploy_updater_variants — gitlab→renovate, local-only→none, bump-gated, no-clobber
G="$TMP_ROOT/gitlab"; mkdir -p "$G"
bash "$DS" --root "$G" --provider gitlab --base main --work dev --bump bump >/dev/null 2>&1 ||
  die test_deploy_updater_variants 'gitlab deploy failed'
[ -f "$G/renovate.json" ] || die test_deploy_updater_variants 'no renovate.json for gitlab'
grep -q '"baseBranches": \["bump"\]' "$G/renovate.json" || die test_deploy_updater_variants 'renovate not baseBranches bump'
[ ! -f "$G/.github/dependabot.yml" ] || die test_deploy_updater_variants 'gitlab wrote dependabot.yml'

L="$TMP_ROOT/localonly"; mkdir -p "$L"
bash "$DS" --root "$L" --provider local-only --base main --work dev >/dev/null 2>&1 ||
  die test_deploy_updater_variants 'local-only deploy failed'
{ [ ! -f "$L/.github/dependabot.yml" ] && [ ! -f "$L/renovate.json" ]; } ||
  die test_deploy_updater_variants 'local-only scaffolded an updater'

NB="$TMP_ROOT/nobump"; mkdir -p "$NB"
bash "$DS" --root "$NB" --provider github --base main --work dev >/dev/null 2>&1 ||
  die test_deploy_updater_variants 'no-bump deploy failed'
[ ! -f "$NB/.github/dependabot.yml" ] || die test_deploy_updater_variants 'bump-disabled scaffolded dependabot'

E2="$TMP_ROOT/existing"; mkdir -p "$E2/.github"
printf 'version: 2\n# hand-written\n' > "$E2/.github/dependabot.yml"
before_cfg=$(cksum "$E2/.github/dependabot.yml")
bash "$DS" --root "$E2" --provider github --base main --work dev --bump bump >/dev/null 2>&1 ||
  die test_deploy_updater_variants 'existing-config deploy failed'
[ "$before_cfg" = "$(cksum "$E2/.github/dependabot.yml")" ] ||
  die test_deploy_updater_variants 'clobbered an existing dependabot.yml'
pass test_deploy_updater_variants

printf 'deploy-substrate selftest: all fixtures passed\n'
