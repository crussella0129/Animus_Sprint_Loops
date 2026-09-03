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

# test_deploy_leaves_fresh_project_on_work — a fresh deploy creates the branches
# itself, so it must end on the work branch; otherwise its own verification
# reports substrate-misplaced and rolls the whole deploy back.
W="$TMP_ROOT/fresh-position"; mkdir -p "$W"
bash "$DS" --root "$W" --provider github --base main --work dev >/dev/null 2>&1 ||
  die test_deploy_leaves_fresh_project_on_work 'fresh deploy failed'
[ "$(git -C "$W" rev-parse --abbrev-ref HEAD)" = dev ] ||
  die test_deploy_leaves_fresh_project_on_work "ended on $(git -C "$W" rev-parse --abbrev-ref HEAD), expected dev"
[ "$(bash "$CS" --root "$W" 2>/dev/null)" = substrate-complete ] ||
  die test_deploy_leaves_fresh_project_on_work "not complete: $(bash "$CS" --root "$W" 2>/dev/null)"
pass test_deploy_leaves_fresh_project_on_work

# test_converge_refuses_from_base_branch — an existing project keeps its own
# checkout; convergence refuses rather than moving the operator's branch.
git -C "$W" checkout -q main
before_pos=$(snap "$W")
if bash "$DS" --root "$W" >/dev/null 2>"$W.err"; then
  die test_converge_refuses_from_base_branch 'converged from the base branch'
fi
grep -q 'switch to dev before converging' "$W.err" ||
  die test_converge_refuses_from_base_branch "no position diagnostic: $(cat "$W.err")"
[ "$before_pos" = "$(snap "$W")" ] ||
  die test_converge_refuses_from_base_branch 'refusal mutated the project'
[ "$(git -C "$W" rev-parse --abbrev-ref HEAD)" = main ] ||
  die test_converge_refuses_from_base_branch 'refusal moved the operator branch'
pass test_converge_refuses_from_base_branch

# ---------------------------------------------------------------------------
# Sprint 19: provider inference. Every fixture below omits --provider, which is
# the path all sixteen fixtures above skip — and the reason a default of
# local-only survived them while writing every hosted project into its own Book
# as having no remote.
# ---------------------------------------------------------------------------
RP="$SCRIPT_DIR/remote-profile.sh"
infer_fixture() {  # <name> [origin-url] -> prints the resolved provider
  local d="$TMP_ROOT/$1"
  mkdir -p "$d"
  git init -q -b main "$d"
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  if [ -n "${2:-}" ]; then git -C "$d" remote add origin "$2"; fi
  bash "$DS" --root "$d" >/dev/null 2>&1
  bash "$RP" --root "$d" provider 2>/dev/null
}

[ "$(infer_fixture gh-https https://github.com/o/r.git)" = github ] ||
  die test_infer_github_https "got '$(bash "$RP" --root "$TMP_ROOT/gh-https" provider 2>&1)'"
[ -f "$TMP_ROOT/gh-https/.github/dependabot.yml" ] ||
  die test_infer_github_https 'inferred github did not scaffold the updater config'
pass test_infer_github_https

[ "$(infer_fixture gh-scp git@github.com:o/r.git)" = github ] || die test_infer_github_ssh 'scp form'
[ "$(infer_fixture gh-ssh ssh://git@github.com/o/r.git)" = github ] || die test_infer_github_ssh 'ssh:// form'
[ "$(infer_fixture gh-upper https://GitHub.com/o/r.git)" = github ] || die test_infer_github_ssh 'mixed case host'
pass test_infer_github_ssh

[ "$(infer_fixture gl https://gitlab.example.net/o/r.git)" = gitlab ] || die test_infer_gitlab 'enterprise gitlab host'
[ -f "$TMP_ROOT/gl/renovate.json" ] || die test_infer_gitlab 'inferred gitlab did not scaffold renovate.json'
pass test_infer_gitlab

[ "$(infer_fixture cb https://codeberg.org/o/r.git)" = forgejo ] || die test_infer_forgejo_codeberg 'codeberg'
pass test_infer_forgejo_codeberg

# An unrecognized remote is generic, never local-only: generic still pushes the
# work branch and prints a compare URL, while local-only does nothing at all.
[ "$(infer_fixture unknown https://git.example.invalid/o/r.git)" = generic ] ||
  die test_infer_unknown_host_is_generic "got '$(bash "$RP" --root "$TMP_ROOT/unknown" provider 2>&1)'"
pass test_infer_unknown_host_is_generic

[ "$(infer_fixture noremote)" = local-only ] || die test_infer_no_remote_is_local_only 'no remote'
{ [ ! -f "$TMP_ROOT/noremote/.github/dependabot.yml" ] && [ ! -f "$TMP_ROOT/noremote/renovate.json" ]; } ||
  die test_infer_no_remote_is_local_only 'local-only scaffolded an updater'
pass test_infer_no_remote_is_local_only

# The adapter pushes to `origin` exclusively, so a repository whose only remote
# has another name has no remote this protocol can reach.
NO="$TMP_ROOT/upstream-only"; mkdir -p "$NO"
git init -q -b main "$NO"; git -C "$NO" config user.email t@t; git -C "$NO" config user.name t
git -C "$NO" remote add upstream https://github.com/o/r.git
bash "$DS" --root "$NO" >/dev/null 2>&1
[ "$(bash "$RP" --root "$NO" provider)" = local-only ] ||
  die test_infer_non_origin_remote_is_local_only "got '$(bash "$RP" --root "$NO" provider)'"
pass test_infer_non_origin_remote_is_local_only

EX="$TMP_ROOT/explicit"; mkdir -p "$EX"
git init -q -b main "$EX"; git -C "$EX" config user.email t@t; git -C "$EX" config user.name t
git -C "$EX" remote add origin https://github.com/o/r.git
bash "$DS" --root "$EX" --provider local-only >/dev/null 2>&1
[ "$(bash "$RP" --root "$EX" provider)" = local-only ] ||
  die test_explicit_provider_wins "explicit flag lost to inference"
pass test_explicit_provider_wins

# Provenance is prose outside the fenced block; the resolver reads the first
# fence and rejects unknown keys, so it must never become a field.
grep -qF 'https://github.com/o/r.git' "$TMP_ROOT/gh-https/docs/work/remote-profile.md" ||
  die test_infer_records_provenance 'source URL not recorded'
grep -qF 'inferred as `github`' "$TMP_ROOT/gh-https/docs/work/remote-profile.md" ||
  die test_infer_records_provenance 'inferred value not recorded'
bash "$RP" --root "$TMP_ROOT/gh-https" >/dev/null 2>&1 ||
  die test_infer_records_provenance 'provenance broke profile resolution'
grep -qF 'inferred as' "$TMP_ROOT/explicit/docs/work/remote-profile.md" &&
  die test_infer_records_provenance 'explicit provider claimed to be inferred'
pass test_infer_records_provenance

# An existing profile is a Book field the operator may have set deliberately.
# The Book must be created before the profile, or init-sprint sees a docs/ tree
# with no marker and refuses — which would leave the profile untouched for the
# wrong reason and pass this fixture without convergence ever running.
UT="$TMP_ROOT/untouched"; mkdir -p "$UT"
git init -q -b main "$UT"; git -C "$UT" config user.email t@t; git -C "$UT" config user.name t
git -C "$UT" remote add origin https://github.com/o/r.git
( cd "$UT" && SPRINT_LOOP_PROJECT_ROOT=. SPRINT_MODEL=selftest bash "$INIT" >/dev/null )
printf '# Remote Profile\n\n<!-- sprint-loop-remote-profile-v2 -->\n\n```\nprovider: local-only\nbase: main\nwork: dev\n```\n' \
  > "$UT/docs/work/remote-profile.md"
untouched_before=$(cksum "$UT/docs/work/remote-profile.md")
bash "$DS" --root "$UT" >"$UT.out" 2>&1 ||
  die test_existing_profile_untouched "convergence failed, so the fixture would pass for the wrong reason: $(cat "$UT.out")"
grep -q substrate-complete "$UT.out" ||
  die test_existing_profile_untouched "convergence did not complete: $(cat "$UT.out")"
[ "$untouched_before" = "$(cksum "$UT/docs/work/remote-profile.md")" ] ||
  die test_existing_profile_untouched 'convergence rewrote an existing profile'
[ "$(bash "$RP" --root "$UT" provider)" = local-only ] ||
  die test_existing_profile_untouched 'the recorded provider changed'
pass test_existing_profile_untouched

# test_gitea_gets_renovate — a declared self-hosted forge must not silently get
# no updater config, which is the same class of omission as the wrong provider.
GT="$TMP_ROOT/gitea"; mkdir -p "$GT"
bash "$DS" --root "$GT" --provider gitea --base main --work dev >/dev/null 2>&1 ||
  die test_gitea_gets_renovate 'gitea deploy failed'
[ -f "$GT/renovate.json" ] || die test_gitea_gets_renovate 'no Renovate config for gitea'
grep -q '"baseBranchPatterns": \["dev"\]' "$GT/renovate.json" ||
  die test_gitea_gets_renovate 'gitea Renovate does not target work'
FJ="$TMP_ROOT/forgejo"; mkdir -p "$FJ"
bash "$DS" --root "$FJ" --provider forgejo --base main --work dev >/dev/null 2>&1 ||
  die test_gitea_gets_renovate 'forgejo deploy failed'
[ -f "$FJ/renovate.json" ] || die test_gitea_gets_renovate 'no Renovate config for forgejo'
pass test_gitea_gets_renovate

# ---------------------------------------------------------------------------
# T-159: --check reports a recorded provider that disagrees with origin, and
# never repairs it. This is the surface an operator uses to find projects
# bootstrapped before inference existed.
# ---------------------------------------------------------------------------
DG="$TMP_ROOT/disagree"; mkdir -p "$DG"
git init -q -b main "$DG"; git -C "$DG" config user.email t@t; git -C "$DG" config user.name t
git -C "$DG" remote add origin https://github.com/o/r.git
bash "$DS" --root "$DG" --provider local-only >/dev/null 2>&1 ||
  die test_check_reports_disagreement 'seed deploy failed'
disagree_before=$(snap "$DG")
dg_out=$(bash "$DS" --root "$DG" --check 2>&1)
case "$dg_out" in
  *'provider-disagreement'*) : ;;
  *) die test_check_reports_disagreement "no disagreement reported: $dg_out" ;;
esac
case "$dg_out" in *local-only*) : ;; *) die test_check_reports_disagreement 'recorded value not named' ;; esac
case "$dg_out" in *github*) : ;; *) die test_check_reports_disagreement 'inferred value not named' ;; esac
pass test_check_reports_disagreement

[ "$disagree_before" = "$(snap "$DG")" ] ||
  die test_check_disagreement_is_readonly 'the disagreement report mutated the project'
[ "$(bash "$RP" --root "$DG" provider)" = local-only ] ||
  die test_check_disagreement_is_readonly 'the recorded provider was repaired'
pass test_check_disagreement_is_readonly

AG="$TMP_ROOT/agree"; mkdir -p "$AG"
git init -q -b main "$AG"; git -C "$AG" config user.email t@t; git -C "$AG" config user.name t
git -C "$AG" remote add origin https://github.com/o/r.git
bash "$DS" --root "$AG" >/dev/null 2>&1 || die test_check_silent_on_agreement 'seed deploy failed'
# Both silence assertions below prove the check *ran* before proving it stayed
# quiet. A bare "this substring is absent" test passes just as happily when the
# command fails outright, which is how a feature can break under a green suite.
assert_check_ran_quietly() {  # <test-name> <dir>
  local out
  out=$(bash "$DS" --root "$2" --check 2>&1) ||
    die "$1" "--check exited non-zero: $out"
  case "$out" in
    *'converged (no pending steps)'*) : ;;
    *) die "$1" "--check did not run to completion: $out" ;;
  esac
  case "$out" in
    *'provider-disagreement'*) die "$1" "reported a disagreement: $out" ;;
  esac
}

assert_check_ran_quietly test_check_silent_on_agreement "$AG"
pass test_check_silent_on_agreement

# Its own fixture: reusing another test's directory means this one passes
# vacuously if that test is renamed, reordered, or removed.
NR="$TMP_ROOT/silent-noremote"; mkdir -p "$NR"
git init -q -b main "$NR"; git -C "$NR" config user.email t@t; git -C "$NR" config user.name t
bash "$DS" --root "$NR" >/dev/null 2>&1 || die test_check_silent_without_remote 'seed deploy failed'
[ "$(bash "$RP" --root "$NR" provider)" = local-only ] ||
  die test_check_silent_without_remote 'fixture is not the no-remote case'
assert_check_ran_quietly test_check_silent_without_remote "$NR"
pass test_check_silent_without_remote

printf 'deploy-substrate selftest: all fixtures passed\n'
