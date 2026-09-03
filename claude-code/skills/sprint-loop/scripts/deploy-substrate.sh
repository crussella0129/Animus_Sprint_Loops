#!/usr/bin/env bash
# Idempotent Sprint Loops convergence: bring a project to substrate-complete.
# One entrypoint for all three cases — it spins up a fresh project, brings an
# older one to this bundle's substrate contract version, and no-ops on a
# current one. Creates only what is missing — Book scaffold + first sprint,
# remote profile, updater config, base/work branches, contract stamp — then
# verifies. Transactional: any failure or signal before commit rolls back every
# artifact this run created, including the stamp.
# Usage: deploy-substrate.sh [--root <dir>] [--provider p] [--base b] [--work w]
#                            [--merge-policy m] [--check]
#   --check   read-only: name each pending convergence step and write nothing.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034 # Consumed by the sourced path contract.
SPRINT_LOOP_PROJECT_ROOT="${SPRINT_LOOP_PROJECT_ROOT:-.}"
PROVIDER=local-only; BASE=main; WORK=dev; MERGE_POLICY=human-approve; CHECK_ONLY=0
PROVIDER_EXPLICIT=0; PROVIDER_SOURCE=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) SPRINT_LOOP_PROJECT_ROOT="$2"; shift 2 ;;
    --provider) PROVIDER="$2"; PROVIDER_EXPLICIT=1; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --work) WORK="$2"; shift 2 ;;
    --merge-policy) MERGE_POLICY="$2"; shift 2 ;;
    --check) CHECK_ONLY=1; shift ;;
    *) echo "deploy-substrate: unknown argument $1" >&2; exit 2 ;;
  esac
done
. "$SCRIPT_DIR/book-paths.sh"
ROOT="$SPRINT_LOOP_PROJECT_ROOT"

fail() { printf 'deploy-substrate: %s\n' "$*" >&2; exit 1; }

# Infer the provider from the origin remote.
#
# The historical default was local-only, which wrote every hosted project into
# its own Book as having no remote — and because the Loop performs no PR/MR for
# local-only and exits 0, the whole remote half of the protocol disappeared
# without anything failing. Only a genuinely absent origin is local-only now; an
# origin whose host is unrecognized resolves to generic, which still pushes the
# work branch and prints a compare URL.
#
# Gitea and Forgejo are declarable but not inferable: both are overwhelmingly
# self-hosted on arbitrary domains, so no URL pattern identifies them the way
# github.com identifies GitHub. codeberg.org is the one widely known instance.
#
# The adapter pushes to `origin` exclusively, so a repository whose only remote
# has another name has no remote this protocol can reach, and local-only is the
# honest answer rather than a miss.
infer_provider() {
  infer_url=$(git -C "$ROOT" remote get-url origin 2>/dev/null) || infer_url=""
  if [ -z "$infer_url" ]; then
    printf 'local-only'
    return 0
  fi
  case "$infer_url" in
    *://*) infer_host=${infer_url#*://}; infer_host=${infer_host#*@}; infer_host=${infer_host%%/*} ;;
    *@*:*) infer_host=${infer_url#*@}; infer_host=${infer_host%%:*} ;;
    *) infer_host="" ;;
  esac
  infer_host=$(printf '%s' "$infer_host" | tr '[:upper:]' '[:lower:]')
  infer_host=${infer_host%%:*}
  case "$infer_host" in
    codeberg.org) printf 'forgejo' ;;
    *github*) printf 'github' ;;
    *gitlab*) printf 'gitlab' ;;
    *) printf 'generic' ;;
  esac
}

case "$(book_layout_state)" in
  legacy-only) fail "legacy layout present; migrate to the Book before deploy" ;;
  conflict) fail "$BOOK_SPLIT_BRAIN_DIAGNOSTIC" ;;
esac

PROFILE=$(book_join_root docs/work/remote-profile.md)

# A Book stamped past this bundle is refused outright: converging backwards
# would silently downgrade the project. This guard precedes every write and the
# read-only report alike.
if [ -f "$BOOK_MARKER" ] && book_version=$(book_substrate_version 2>/dev/null); then
  if [ "$book_version" -gt "$BOOK_SUBSTRATE_CONTRACT_VERSION" ]; then
    fail "Book substrate contract version $book_version is ahead of this bundle's $BOOK_SUBSTRATE_CONTRACT_VERSION; upgrade the bundle instead of converging backwards"
  fi
fi

# Read-only drift report. Names every pending convergence step and writes
# nothing, so an operator can see what convergence would do before running it.
if [ "$CHECK_ONLY" -eq 1 ]; then
  pending=0
  say_pending() { pending=$((pending + 1)); printf 'pending: %s\n' "$*"; }
  case "$(book_layout_state)" in
    none) say_pending "create the Book scaffold and the first sprint" ;;
    book-only)
      ls -d "$BOOK_SPRINTS_DIR"/s* >/dev/null 2>&1 ||
        say_pending "create the first sprint" ;;
  esac
  if [ -f "$PROFILE" ]; then
    if check_prof=$(bash "$SCRIPT_DIR/remote-profile.sh" --root "$ROOT" 2>/dev/null); then
      PROVIDER=$(printf '%s\n' "$check_prof" | sed -n 's/^PROVIDER=//p')
      BASE=$(printf '%s\n' "$check_prof" | sed -n 's/^BASE=//p')
      WORK=$(printf '%s\n' "$check_prof" | sed -n 's/^WORK=//p')
      # Report, never repair. A recorded provider may have been set
      # deliberately, so a disagreement with the current origin is a
      # diagnosis for a person, not a pending convergence step.
      check_inferred=$(infer_provider)
      if [ "$PROVIDER" != "$check_inferred" ]; then
        printf 'provider-disagreement: profile records %s but origin implies %s (not changed)\n' \
          "$PROVIDER" "$check_inferred"
      fi
    else
      say_pending "repair the unreadable remote profile at $PROFILE"
    fi
  else
    if [ "$PROVIDER_EXPLICIT" -eq 0 ]; then PROVIDER=$(infer_provider); fi
    say_pending "create the remote profile at $PROFILE (provider=$PROVIDER base=$BASE work=$WORK)"
  fi
  case "$PROVIDER" in
    github)
      [ -f "$ROOT/.github/dependabot.yml" ] ||
        say_pending "create .github/dependabot.yml targeting $WORK" ;;
    gitlab|gitea|forgejo|generic)
      [ -f "$ROOT/renovate.json" ] ||
        say_pending "create renovate.json targeting $WORK" ;;
  esac
  if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    for check_br in "$BASE" "$WORK"; do
      git -C "$ROOT" show-ref --verify --quiet "refs/heads/$check_br" ||
        say_pending "create branch $check_br"
    done
  else
    say_pending "initialize a git repository on $BASE"
    say_pending "create branch $WORK"
  fi
  if [ "$(book_substrate_version 2>/dev/null || echo 1)" -ge 4 ]; then
    check_ci=$(bash "$SCRIPT_DIR/scaffold-ci.sh" --root "$ROOT" --provider "$PROVIDER"       --base "$BASE" --work "$WORK" --check 2>/dev/null | sed -n 's/^would create //p' | head -n 1)
    [ -n "$check_ci" ] && say_pending "create $check_ci"
  fi
  if [ ! -f "$BOOK_MARKER" ]; then
    say_pending "stamp substrate-version: $BOOK_SUBSTRATE_CONTRACT_VERSION"
  elif check_version=$(book_substrate_version 2>/dev/null); then
    [ "$check_version" -eq "$BOOK_SUBSTRATE_CONTRACT_VERSION" ] ||
      say_pending "stamp substrate-version: $BOOK_SUBSTRATE_CONTRACT_VERSION (currently $check_version)"
  else
    say_pending "repair the malformed substrate-version entry in $BOOK_MARKER"
  fi
  if [ "$pending" -eq 0 ]; then
    printf 'deploy-substrate: converged (no pending steps)\n'
    exit 0
  fi
  exit 1
fi

DEPLOY_ORIGINAL_HEAD=$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
SWITCHED_BRANCH=0
CREATED_BOOK=0; CREATED_PROFILE=0; CREATED_SPRINT=""; CREATED_GITDIR=0
CREATED_BRANCHES=""; CREATED_UPDATER=""; CREATED_CI=""; COMMITTED=0
STAMPED=0; PRIOR_MARKER=""

rollback() {
  [ "$COMMITTED" -eq 1 ] && return 0
  [ "$STAMPED" -eq 1 ] && printf '%s\n' "$PRIOR_MARKER" > "$BOOK_MARKER"
  if [ "$SWITCHED_BRANCH" -eq 1 ] && [ -n "$DEPLOY_ORIGINAL_HEAD" ]; then
    git -C "$ROOT" checkout -q "$DEPLOY_ORIGINAL_HEAD" >/dev/null 2>&1 || true
  fi
  for _b in $CREATED_BRANCHES; do git -C "$ROOT" branch -D "$_b" >/dev/null 2>&1 || true; done
  if [ -n "$CREATED_UPDATER" ]; then
    rm -f "$CREATED_UPDATER"
    rmdir "$(dirname "$CREATED_UPDATER")" 2>/dev/null || true
  fi
  if [ -n "$CREATED_CI" ]; then
    rm -f "$CREATED_CI"
    rmdir "$(dirname "$CREATED_CI")" 2>/dev/null || true
    rmdir "$(dirname "$(dirname "$CREATED_CI")")" 2>/dev/null || true
  fi
  [ -n "$CREATED_SPRINT" ] && rm -rf "$CREATED_SPRINT"
  [ "$CREATED_PROFILE" -eq 1 ] && rm -f "$PROFILE"
  [ "$CREATED_BOOK" -eq 1 ] && rm -rf "$BOOK_ROOT"
  [ "$CREATED_GITDIR" -eq 1 ] && rm -rf "$ROOT/.git"
  return 0
}
trap 'rollback' EXIT
trap 'exit 130' HUP INT TERM

# Test seam: fail deterministically after a named step to exercise rollback.
maybe_fail() { [ "${DEPLOY_SUBSTRATE_FAIL_AFTER:-}" = "$1" ] && fail "injected failure after $1"; return 0; }

# 1. Book scaffold + first sprint.
if [ "$(book_layout_state)" = none ]; then
  ( cd "$ROOT" && SPRINT_LOOP_PROJECT_ROOT=. bash "$SCRIPT_DIR/init-sprint.sh" >/dev/null ) ||
    fail "book scaffold/init failed"
  CREATED_BOOK=1
elif ! ls -d "$BOOK_SPRINTS_DIR"/s* >/dev/null 2>&1; then
  ( cd "$ROOT" && SPRINT_LOOP_PROJECT_ROOT=. bash "$SCRIPT_DIR/init-sprint.sh" >/dev/null ) ||
    fail "first sprint init failed"
  CREATED_SPRINT=$(ls -d "$BOOK_SPRINTS_DIR"/s* 2>/dev/null | LC_ALL=C sort -V | tail -1)
fi
maybe_fail book

# 2. Remote profile. Created only when absent — an existing profile is a Book
# field the operator may have set deliberately, and convergence reports on it
# (see --check) rather than rewriting it.
if [ ! -f "$PROFILE" ]; then
  if [ "$PROVIDER_EXPLICIT" -eq 0 ]; then
    PROVIDER=$(infer_provider)
    PROVIDER_SOURCE=$(git -C "$ROOT" remote get-url origin 2>/dev/null || printf '')
  fi
  mkdir -p "$(dirname "$PROFILE")"
  {
    printf '# Remote Profile\n\n<!-- sprint-loop-remote-profile-v2 -->\n\n'
    if [ "$PROVIDER_EXPLICIT" -eq 0 ]; then
      # Provenance sits outside the fenced block: the resolver reads the first
      # fence and rejects unknown keys, so this must never become a field.
      if [ -n "$PROVIDER_SOURCE" ]; then
        printf 'Provider inferred as `%s` from the origin remote `%s`.\n' "$PROVIDER" "$PROVIDER_SOURCE"
      else
        printf 'Provider recorded as `%s`: no origin remote was configured.\n' "$PROVIDER"
      fi
      printf 'Edit the block below to correct it; convergence never rewrites an existing profile.\n\n'
    fi
    printf '```\n'
    printf 'provider: %s\nbase: %s\nwork: %s\n' "$PROVIDER" "$BASE" "$WORK"
    printf 'mergePolicy: %s\n```\n' "$MERGE_POLICY"
  } > "$PROFILE"
  CREATED_PROFILE=1
fi
prof=$(bash "$SCRIPT_DIR/remote-profile.sh" --root "$ROOT") || fail "invalid remote profile"
PROVIDER=$(printf '%s\n' "$prof" | sed -n 's/^PROVIDER=//p')
BASE=$(printf '%s\n' "$prof" | sed -n 's/^BASE=//p')
WORK=$(printf '%s\n' "$prof" | sed -n 's/^WORK=//p')
MERGE_POLICY=$(printf '%s\n' "$prof" | sed -n 's/^MERGEPOLICY=//p')
maybe_fail profile

# Position. Convergence writes, so it must not run from the base branch of a
# project that already has one. A fresh deploy is exempt: it creates the
# branches itself and checks out work below.
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 &&
   git -C "$ROOT" show-ref --verify --quiet "refs/heads/$WORK"; then
  deploy_head=$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)
  if [ "$deploy_head" != "$WORK" ]; then
    fail "HEAD is $deploy_head but the work branch is $WORK; switch to $WORK before converging"
  fi
fi

# 2b. Dependency-updater config (create-if-absent, work-targeted).
# github -> Dependabot; gitlab/generic -> Renovate; local-only -> none. A fresh
# project has no manifests, so the config is a starter (github-actions / recommended).
case "$PROVIDER" in
  github)
    updater="$ROOT/.github/dependabot.yml"
    if [ ! -f "$updater" ]; then
      mkdir -p "$ROOT/.github"
      {
        printf '# Dependabot opens scheduled version-update PRs against the work branch.\n'
        printf '# Merge only at sprint boundaries when green; add ecosystems as the project grows.\n'
        printf 'version: 2\nupdates:\n'
        printf '  - package-ecosystem: "github-actions"\n    directory: "/"\n'
        printf '    schedule:\n      interval: "weekly"\n'
        printf '    target-branch: "%s"\n' "$WORK"
      } > "$updater"
      CREATED_UPDATER="$updater"
    fi ;;
  gitlab|gitea|forgejo|generic)
    updater="$ROOT/renovate.json"
    if [ ! -f "$updater" ]; then
      {
        printf '{\n'
        printf '  "$schema": "https://docs.renovatebot.com/renovate-schema.json",\n'
        printf '  "extends": ["config:recommended"],\n'
        printf '  "baseBranchPatterns": ["%s"]\n' "$WORK"
        printf '}\n'
      } > "$updater"
      CREATED_UPDATER="$updater"
    fi ;;
esac
maybe_fail updater


# 2c. Stamp the substrate contract version.
#
# Ordering is load-bearing twice over. It runs BEFORE the final verification,
# because check-substrate.sh reports substrate-outdated for a complete but
# unstamped Book — a stamp placed after the verify would make convergence fail
# on exactly the projects it exists to upgrade. It also runs before the git
# step, so a fresh deploy commits the stamped marker rather than leaving the
# working tree dirty. The write happens only when the value would change, which
# is what keeps a converged re-run a byte-for-byte no-op.
if [ -f "$BOOK_MARKER" ]; then
  current_version=$(book_substrate_version) ||
    fail "$BOOK_SUBSTRATE_VERSION_DIAGNOSTIC: $BOOK_MARKER"
  if [ "$current_version" -ne "$BOOK_SUBSTRATE_CONTRACT_VERSION" ]; then
    PRIOR_MARKER=$(cat "$BOOK_MARKER")
    stamp_tmp="$BOOK_MARKER.stamp.$$"
    if awk -v v="$BOOK_SUBSTRATE_CONTRACT_VERSION" '
        { sub(/\r$/, "") }
        /^[[:space:]]*substrate-version:/ { next }
        { print }
        END { print "substrate-version: " v }
      ' "$BOOK_MARKER" > "$stamp_tmp"; then
      STAMPED=1
      mv "$stamp_tmp" "$BOOK_MARKER" || fail "stamping the substrate version failed"
    else
      rm -f "$stamp_tmp"
      fail "stamping the substrate version failed"
    fi
  fi
fi
maybe_fail stamp

# 2d. CI configuration (create-if-absent, contract 4 and above).
#
# A fresh project otherwise reaches its first checkpoint with no CI at all, so
# that checkpoint is green because nothing ran. Bound at a contract version
# because writing a CI file into a project that has been running for months is
# more intrusive than a gate: an existing project gets it only when it converges,
# and --check previews it first.
#
# This step runs AFTER the stamp deliberately. Convergence raises the project
# to the current contract in the same run, so evaluating the version before the
# stamp would mean CI first appears on the *second* convergence — the run that
# upgrades a project would silently skip the thing the upgrade is for.
if [ "$(book_substrate_version 2>/dev/null || echo 1)" -ge 4 ]; then
  ci_before=$(bash "$SCRIPT_DIR/scaffold-ci.sh" --root "$ROOT" --provider "$PROVIDER"     --base "$BASE" --work "$WORK" --check 2>/dev/null | sed -n 's/^would create //p' | head -n 1)
  if [ -n "$ci_before" ]; then
    bash "$SCRIPT_DIR/scaffold-ci.sh" --root "$ROOT" --provider "$PROVIDER"       --base "$BASE" --work "$WORK" >/dev/null || fail "generating the CI configuration failed"
    [ -f "$ROOT/$ci_before" ] && CREATED_CI="$ROOT/$ci_before"
  fi
fi
maybe_fail ci

# 3. Git repo + branches.
if ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$ROOT" init -q -b "$BASE" || fail "git init failed"
  CREATED_GITDIR=1
fi
if ! git -C "$ROOT" rev-parse -q --verify HEAD >/dev/null 2>&1; then
  git -C "$ROOT" add -A -- docs >/dev/null 2>&1 || true
  [ -n "$CREATED_UPDATER" ] && git -C "$ROOT" add -A -- "$CREATED_UPDATER" >/dev/null 2>&1 || true
  git -C "$ROOT" -c user.email=sprint-loops@local -c user.name=sprint-loops \
    commit -q --allow-empty -m "sprint-0: substrate" || fail "initial commit failed"
fi
branch_list="$BASE $WORK"
# shellcheck disable=SC2086 # branch names are single tokens by construction.
for br in $branch_list; do
  if ! git -C "$ROOT" show-ref --verify --quiet "refs/heads/$br"; then
    git -C "$ROOT" branch "$br" HEAD || fail "creating branch $br failed"
    CREATED_BRANCHES="$CREATED_BRANCHES $br"
  fi
done

# Leave a freshly created project on its work branch. Sprints happen on work,
# and the substrate gate reports any other position as misplaced.
if [ -n "$CREATED_BRANCHES" ] || [ "$CREATED_GITDIR" -eq 1 ]; then
  if [ "$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")" != "$WORK" ]; then
    git -C "$ROOT" checkout -q "$WORK" || fail "cannot check out the work branch $WORK"
    SWITCHED_BRANCH=1
  fi
fi
maybe_fail branches

# 4. Verify.
result=$(bash "$SCRIPT_DIR/check-substrate.sh" --root "$ROOT" 2>/dev/null) || true
[ "$result" = substrate-complete ] || fail "post-deploy verification failed: $result"

COMMITTED=1
trap - EXIT HUP INT TERM
printf 'deploy-substrate: substrate-complete (provider=%s base=%s work=%s mergePolicy=%s contract=%s)\n' \
  "$PROVIDER" "$BASE" "$WORK" "$MERGE_POLICY" "$BOOK_SUBSTRATE_CONTRACT_VERSION"
