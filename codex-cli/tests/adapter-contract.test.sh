#!/usr/bin/env bash
# Static and fixture coverage for the current Codex adapter contract.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CODEX="$ROOT/codex-cli"
SKILL_ROOT="$CODEX/skills/sprint-loops"
SKILL="$SKILL_ROOT/SKILL.md"
PHASES="$SKILL_ROOT/phases"
README="$CODEX/README.md"
FRAGMENT="$SKILL_ROOT/AGENTS.md.fragment"
INSTALL="$CODEX/install.sh"
POWERSHELL_TEST="$CODEX/tests/adapter-contract.windows.ps1"
COUNT=0
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loops-codex-adapter.XXXXXX")
BG_PID=
ACTIVE_RELEASE=

cleanup_test() {
  if [ -n "$ACTIVE_RELEASE" ]; then
    : > "$ACTIVE_RELEASE" 2>/dev/null || true
  fi
  if [ -n "$BG_PID" ]; then
    kill "$BG_PID" 2>/dev/null || true
    wait "$BG_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP_ROOT"
}
trap cleanup_test EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() { echo "adapter-contract.test: FAIL: $*" >&2; exit 1; }
pass() { COUNT=$((COUNT + 1)); }
wait_for_file() {
  awaited=$1
  description=$2
  attempts=0
  while [ ! -e "$awaited" ] && [ "$attempts" -lt 5 ]; do
    sleep 1
    attempts=$((attempts + 1))
  done
  [ -e "$awaited" ] || fail "timed out waiting for $description"
}
require_text() {
  file=$1
  expected=$2
  grep -Fq -- "$expected" "$file" ||
    fail "$file lacks required text: $expected"
}
reject_pattern() {
  pattern=$1
  shift
  if grep -Ein -- "$pattern" "$@" >/dev/null; then
    fail "forbidden adapter pattern found: $pattern"
  fi
}

# Resolved skill path plus project-root cwd; never a bare project script path.
require_text "$SKILL" 'From `<project-root>`, run:'
require_text "$SKILL" 'bash "<skill-root>/scripts/current-phase.sh"'
require_text "$SKILL" 'If Codex started in a nested Git directory, use the Git top level.'
require_text "$PHASES/03-plan-phase.md" 'Re-running `bash "<skill-root>/scripts/current-phase.sh"`'
reject_pattern 'bash[[:space:]]+scripts/' "$SKILL" "$PHASES/03-plan-phase.md" "$PHASES/06-loop-phase.md"
pass

# Codex follows the active host mode; adapter instructions never switch it.
reject_pattern '(^|[^[:alnum:]/-])/plan([^[:alnum:]/-]|$)|EnterPlanMode|ExitPlanMode|use maximum effort|--ask-for-approval|--sandbox|switch (to|into).*(approval|permission|sandbox)|set .*(approval|permission|sandbox)' \
  "$SKILL" "$README" "$FRAGMENT" "$PHASES/03-plan-phase.md" "$PHASES/06-loop-phase.md"
require_text "$SKILL" 'Never change Codex sandbox, approval, or permission'
pass

# All seven phases expose one machine-checkable contract shape.
phase_count=0
for phase in "$PHASES"/*.md; do
  phase_count=$((phase_count + 1))
  for heading in '## Outcome' '## Inputs' '## Authority' '## Exit evidence'; do
    heading_count=$(grep -cFx -- "$heading" "$phase" || true)
    [ "$heading_count" -eq 1 ] ||
      fail "$phase has $heading_count copies of $heading"
  done
done
[ "$phase_count" -eq 7 ] || fail "expected 7 Codex phases, found $phase_count"
pass

# Remote authority is positive, exact, singular, and not contradicted.
REMOTE_RULE='Push, merge, release, force-push, delete, and material scope expansion require an explicit request or a declared preauthorized-remote profile.'
remote_count=$(grep -Foh -- "$REMOTE_RULE" "$SKILL" "$FRAGMENT" "$PHASES"/*.md "$README" | wc -l | tr -d '[:space:]')
[ "$remote_count" -eq 1 ] || fail "expected one exact remote authority rule, found $remote_count"
reject_pattern 'proceeds autonomously|Commit, push, and merge|gh pr merge|--delete-branch|push.*without asking|force-push.*re-verify' \
  "$SKILL" "$FRAGMENT" "$PHASES/03-plan-phase.md" "$PHASES/06-loop-phase.md"
require_text "$README" 'The agent cannot create, infer, or'
require_text "$README" 'not a Codex built-in'
pass

# Shared checkouts retain one writer unless isolation is explicit.
WORKSPACE_RULE='Use subagents for bounded, disjoint read/review work; keep one integrating writer in a shared workspace. Parallel writers require explicit isolated worktrees.'
workspace_count=$(grep -Foh -- "$WORKSPACE_RULE" "$SKILL" "$FRAGMENT" "$PHASES"/*.md "$README" | wc -l | tr -d '[:space:]')
[ "$workspace_count" -eq 1 ] || fail "expected one exact shared-workspace rule, found $workspace_count"
pass

# Installer targets both supported scopes, survives paths with spaces, and is
# idempotent without nesting or stale files.
USER_HOME="$TMP_ROOT/user home"
PROJECT="$TMP_ROOT/project with spaces"
PROJECT_HOME="$TMP_ROOT/project user"
mkdir -p "$USER_HOME" "$PROJECT" "$PROJECT_HOME"
HOME="$USER_HOME" bash "$INSTALL" >/dev/null
USER_DST="$USER_HOME/.agents/skills/sprint-loops"
[ -f "$USER_DST/SKILL.md" ] || fail "user install missing SKILL.md"
[ ! -e "$USER_DST/.sprint-loops.install-owner" ] ||
  fail "user install retained its transaction marker"
ROUTING_PROJECT="$TMP_ROOT/routing project"
mkdir -p "$ROUTING_PROJECT"
route_output=$(
  cd "$ROUTING_PROJECT"
  bash "$USER_DST/scripts/current-phase.sh"
)
[ "$route_output" = uninitialized ] ||
  fail "installed helper did not route from a project cwd through its spaced path"
printf 'stale\n' > "$USER_DST/stale.txt"
HOME="$USER_HOME" bash "$INSTALL" >/dev/null
[ ! -e "$USER_DST/stale.txt" ] || fail "idempotent user install retained stale content"
[ ! -e "$USER_DST/.sprint-loops.install-owner" ] ||
  fail "user reinstall retained its transaction marker"
[ ! -d "$USER_DST/sprint-loops" ] || fail "user install nested the skill"
(
  cd "$PROJECT"
  git init -q
  HOME="$PROJECT_HOME" bash "$INSTALL" --project >/dev/null
)
PROJECT_DST="$PROJECT/.agents/skills/sprint-loops"
[ -f "$PROJECT_DST/SKILL.md" ] || fail "project install missing SKILL.md"
if HOME="$USER_HOME" bash "$INSTALL" --unknown >/dev/null 2>&1; then
  fail "installer accepted an unknown argument"
fi
if HOME="$USER_HOME" bash "$INSTALL" --project extra >/dev/null 2>&1; then
  fail "installer accepted trailing arguments"
fi
if find "$TMP_ROOT" -type d -name .codex -print | grep -q .; then
  fail "installer created a legacy .codex skill surface"
fi

REAL_CP=$(command -v cp)
CONCURRENT_HOME="$TMP_ROOT/concurrent home"
CONCURRENT_STUB="$TMP_ROOT/concurrent cp stub"
CONCURRENT_READY="$TMP_ROOT/concurrent.ready"
CONCURRENT_RELEASE="$TMP_ROOT/concurrent.release"
mkdir -p "$CONCURRENT_HOME" "$CONCURRENT_STUB"
cat > "$CONCURRENT_STUB/cp" <<'EOF'
#!/usr/bin/env sh
: > "$INSTALL_READY"
while [ ! -e "$INSTALL_RELEASE" ]; do
  sleep 1
done
exec "$REAL_CP" "$@"
EOF
chmod +x "$CONCURRENT_STUB/cp"
HOME="$CONCURRENT_HOME" PATH="$CONCURRENT_STUB:$PATH" \
  INSTALL_READY="$CONCURRENT_READY" INSTALL_RELEASE="$CONCURRENT_RELEASE" \
  REAL_CP="$REAL_CP" bash "$INSTALL" >"$TMP_ROOT/concurrent-first.log" 2>&1 &
BG_PID=$!
ACTIVE_RELEASE=$CONCURRENT_RELEASE
wait_for_file "$CONCURRENT_READY" "the first installer staging barrier"
if HOME="$CONCURRENT_HOME" bash "$INSTALL" \
  >"$TMP_ROOT/concurrent-second.log" 2>&1; then
  : > "$CONCURRENT_RELEASE"
  wait "$BG_PID" || true
  BG_PID=
  fail "a concurrent installer acquired the same target"
fi
grep -Fq 'another sprint-loops install holds' "$TMP_ROOT/concurrent-second.log" ||
  fail "concurrent installer did not report the target lock"
: > "$CONCURRENT_RELEASE"
if wait "$BG_PID"; then
  BG_PID=
  ACTIVE_RELEASE=
else
  BG_PID=
  ACTIVE_RELEASE=
  fail "the lock-owning installer failed after its barrier was released"
fi
CONCURRENT_DST="$CONCURRENT_HOME/.agents/skills/sprint-loops"
[ -f "$CONCURRENT_DST/SKILL.md" ] ||
  fail "the lock-owning installer did not activate its skill"
[ ! -d "$CONCURRENT_DST/sprint-loops" ] ||
  fail "concurrent installation nested a staged skill"

LOCKED_HOME="$TMP_ROOT/recovery locked home"
mkdir -p "$LOCKED_HOME/.agents/skills/sprint-loops"
printf 'keep\n' > "$LOCKED_HOME/.agents/skills/sprint-loops/prior.txt"
mkdir "$LOCKED_HOME/.agents/skills/.sprint-loops.install.lock"
printf 'recovery-required\n' \
  > "$LOCKED_HOME/.agents/skills/.sprint-loops.install.lock/owner"
if HOME="$LOCKED_HOME" bash "$INSTALL" >/dev/null 2>&1; then
  fail "installer ignored an existing recovery lock"
fi
grep -Fqx keep "$LOCKED_HOME/.agents/skills/sprint-loops/prior.txt" ||
  fail "recovery-lock refusal mutated the installed skill"
grep -Fqx recovery-required \
  "$LOCKED_HOME/.agents/skills/.sprint-loops.install.lock/owner" ||
  fail "recovery-lock refusal mutated lock evidence"

if (
  cd /
  HOME="$PROJECT_HOME" bash "$INSTALL" --project >/dev/null 2>&1
); then
  fail "project installer accepted a filesystem root"
fi
pass

# Refuse aliases/non-directories and preserve a prior install on source/copy
# failure.
ALIAS_HOME="$TMP_ROOT/alias home"
mkdir -p "$ALIAS_HOME/.agents/skills" "$TMP_ROOT/alias target"
ln -s "$TMP_ROOT/alias target" "$ALIAS_HOME/.agents/skills/sprint-loops"
if HOME="$ALIAS_HOME" bash "$INSTALL" >/dev/null 2>&1; then
  fail "installer replaced a symlink target"
fi
[ -L "$ALIAS_HOME/.agents/skills/sprint-loops" ] ||
  fail "installer mutated the symlink target"

DANGLING_HOME="$TMP_ROOT/dangling alias home"
mkdir -p "$DANGLING_HOME/.agents/skills"
ln -s "$TMP_ROOT/does-not-exist" \
  "$DANGLING_HOME/.agents/skills/sprint-loops"
if HOME="$DANGLING_HOME" bash "$INSTALL" >/dev/null 2>&1; then
  fail "installer replaced a dangling symlink target"
fi
[ -L "$DANGLING_HOME/.agents/skills/sprint-loops" ] ||
  fail "installer mutated the dangling symlink target"

FILE_HOME="$TMP_ROOT/file home"
mkdir -p "$FILE_HOME/.agents/skills"
printf 'keep\n' > "$FILE_HOME/.agents/skills/sprint-loops"
if HOME="$FILE_HOME" bash "$INSTALL" >/dev/null 2>&1; then
  fail "installer replaced a non-directory target"
fi
grep -Fqx keep "$FILE_HOME/.agents/skills/sprint-loops" ||
  fail "installer mutated the non-directory target"

printf 'preserve\n' > "$USER_DST/preserve.txt"
EMPTY_INSTALLER_DIR="$TMP_ROOT/empty installer"
mkdir -p "$EMPTY_INSTALLER_DIR"
cp "$INSTALL" "$EMPTY_INSTALLER_DIR/install.sh"
if HOME="$USER_HOME" bash "$EMPTY_INSTALLER_DIR/install.sh" >/dev/null 2>&1; then
  fail "installer with missing source succeeded"
fi
grep -Fqx preserve "$USER_DST/preserve.txt" ||
  fail "missing-source failure changed the prior install"

CP_STUB="$TMP_ROOT/cp stub"
mkdir -p "$CP_STUB"
cat > "$CP_STUB/cp" <<'EOF'
#!/usr/bin/env sh
exit 1
EOF
chmod +x "$CP_STUB/cp"
if HOME="$USER_HOME" PATH="$CP_STUB:$PATH" bash "$INSTALL" >/dev/null 2>&1; then
  fail "injected staged-copy failure succeeded"
fi
grep -Fqx preserve "$USER_DST/preserve.txt" ||
  fail "staged-copy failure changed the prior install"

REAL_MV=$(command -v mv)
REAL_RM=$(command -v rm)
ROLLBACK_HOME="$TMP_ROOT/rollback home"
ROLLBACK_STUB="$TMP_ROOT/rollback stubs"
ROLLBACK_DST="$ROLLBACK_HOME/.agents/skills/sprint-loops"
MV_FAIL_MARKER="$TMP_ROOT/activation-mv.failed"
RM_FAIL_MARKER="$TMP_ROOT/stage-rm.failed"
mkdir -p "$ROLLBACK_DST" "$ROLLBACK_STUB"
printf 'known-good\n' > "$ROLLBACK_DST/prior.txt"
cat > "$ROLLBACK_STUB/mv" <<'EOF'
#!/usr/bin/env sh
last=
for arg in "$@"; do
  last=$arg
done
if [ "$last" = "$FAIL_ACTIVATION_DST" ] &&
   [ ! -e "$FAIL_ACTIVATION_ONCE" ]; then
  : > "$FAIL_ACTIVATION_ONCE"
  exit 1
fi
exec "$REAL_MV" "$@"
EOF
cat > "$ROLLBACK_STUB/rm" <<'EOF'
#!/usr/bin/env sh
last=
for arg in "$@"; do
  last=$arg
done
case "$last" in
  *".sprint-loops.install."*)
    if [ ! -e "$FAIL_STAGE_RM_ONCE" ]; then
      : > "$FAIL_STAGE_RM_ONCE"
      exit 1
    fi
    ;;
esac
exec "$REAL_RM" "$@"
EOF
chmod +x "$ROLLBACK_STUB/mv" "$ROLLBACK_STUB/rm"
if HOME="$ROLLBACK_HOME" PATH="$ROLLBACK_STUB:$PATH" \
  FAIL_ACTIVATION_DST="$ROLLBACK_DST" \
  FAIL_ACTIVATION_ONCE="$MV_FAIL_MARKER" \
  FAIL_STAGE_RM_ONCE="$RM_FAIL_MARKER" \
  REAL_MV="$REAL_MV" REAL_RM="$REAL_RM" \
  bash "$INSTALL" >"$TMP_ROOT/rollback.log" 2>&1; then
  fail "injected activation failure succeeded"
fi
grep -Fqx known-good "$ROLLBACK_DST/prior.txt" ||
  fail "cleanup failure occurred before the prior install was restored"
if find "$ROLLBACK_HOME/.agents/skills" \
  -name '.sprint-loops.backup.*' -print | grep -q .; then
  fail "restored prior install also remained hidden as a backup"
fi
[ -d "$ROLLBACK_HOME/.agents/skills/.sprint-loops.install.lock" ] ||
  fail "cleanup failure did not retain a protective recovery lock"
if ! grep -Fq 'transaction artifacts remain protected' \
  "$TMP_ROOT/rollback.log"; then
  rollback_diagnostic=$(tr '\n' ' ' < "$TMP_ROOT/rollback.log")
  fail "cleanup failure diagnostic was: $rollback_diagnostic"
fi

COLLISION_HOME="$TMP_ROOT/external collision home"
COLLISION_STUB="$TMP_ROOT/external collision stub"
COLLISION_DST="$COLLISION_HOME/.agents/skills/sprint-loops"
COLLISION_HOLD="$TMP_ROOT/external collision staged tree"
COLLISION_ONCE="$TMP_ROOT/external collision.once"
mkdir -p "$COLLISION_DST" "$COLLISION_STUB"
printf 'known-good-collision\n' > "$COLLISION_DST/prior.txt"
cat > "$COLLISION_STUB/mv" <<'EOF'
#!/usr/bin/env sh
src=$1
dst=$2
if [ "$dst" = "$COLLISION_DST" ] && [ ! -e "$COLLISION_ONCE" ]; then
  : > "$COLLISION_ONCE"
  "$REAL_MV" "$src" "$COLLISION_HOLD"
  mkdir -p "$dst"
  printf 'intruder\n' > "$dst/intruder.txt"
  printf 'foreign-transaction\n' > "$dst/.sprint-loops.install-owner"
  exit 1
fi
exec "$REAL_MV" "$@"
EOF
chmod +x "$COLLISION_STUB/mv"
if HOME="$COLLISION_HOME" PATH="$COLLISION_STUB:$PATH" \
  COLLISION_DST="$COLLISION_DST" COLLISION_HOLD="$COLLISION_HOLD" \
  COLLISION_ONCE="$COLLISION_ONCE" REAL_MV="$REAL_MV" \
  bash "$INSTALL" >"$TMP_ROOT/external-collision.log" 2>&1; then
  fail "external destination collision reported success"
fi
grep -Fqx intruder "$COLLISION_DST/intruder.txt" ||
  fail "rollback deleted or replaced an unowned destination"
collision_backup=
for candidate in \
  "$COLLISION_HOME/.agents/skills"/.sprint-loops.backup.*; do
  [ -d "$candidate" ] || continue
  collision_backup=$candidate
  break
done
[ -n "$collision_backup" ] ||
  fail "external collision did not preserve the known-good backup"
grep -Fqx known-good-collision "$collision_backup/prior.txt" ||
  fail "external collision corrupted the preserved backup"
[ -d "$COLLISION_HOME/.agents/skills/.sprint-loops.install.lock" ] ||
  fail "external collision did not retain its recovery lock"
grep -Fq 'rollback found an unowned destination' \
  "$TMP_ROOT/external-collision.log" ||
  fail "external collision did not report the ownership mismatch"

SIGNAL_STUB="$TMP_ROOT/signal mv stub"
mkdir -p "$SIGNAL_STUB"
cat > "$SIGNAL_STUB/mv" <<'EOF'
#!/usr/bin/env sh
src=$1
dst=$2
block=0
if [ ! -e "$MV_BLOCKED" ]; then
  case "$MV_BLOCK_ON" in
    prior)
      [ "$src" = "$MV_EXPECT_DST" ] && block=1
      ;;
    activation)
      case "$src" in
        *".sprint-loops.install."*)
          [ "$dst" = "$MV_EXPECT_DST" ] && block=1
          ;;
      esac
      ;;
  esac
fi
if [ "$block" -eq 1 ]; then
  "$REAL_MV" "$@"
  : > "$MV_BLOCKED"
  : > "$MV_READY"
  while [ ! -e "$MV_RELEASE" ]; do
    sleep 1
  done
  exit 0
fi
exec "$REAL_MV" "$@"
EOF
chmod +x "$SIGNAL_STUB/mv"

run_signal_case() {
  label=$1
  block_on=$2
  signal_home="$TMP_ROOT/signal-$label home"
  signal_dst="$signal_home/.agents/skills/sprint-loops"
  signal_ready="$TMP_ROOT/signal-$label.ready"
  signal_release="$TMP_ROOT/signal-$label.release"
  signal_blocked="$TMP_ROOT/signal-$label.blocked"
  mkdir -p "$signal_dst"
  printf 'known-good-%s\n' "$label" > "$signal_dst/prior.txt"

  HOME="$signal_home" PATH="$SIGNAL_STUB:$PATH" \
    MV_BLOCK_ON="$block_on" MV_EXPECT_DST="$signal_dst" \
    MV_READY="$signal_ready" MV_RELEASE="$signal_release" \
    MV_BLOCKED="$signal_blocked" REAL_MV="$REAL_MV" \
    bash "$INSTALL" >"$TMP_ROOT/signal-$label.log" 2>&1 &
  BG_PID=$!
  ACTIVE_RELEASE=$signal_release
  wait_for_file "$signal_ready" "$label signal cutover barrier"
  kill -TERM "$BG_PID"
  : > "$signal_release"
  if wait "$BG_PID"; then
    signal_status=0
  else
    signal_status=$?
  fi
  BG_PID=
  ACTIVE_RELEASE=

  [ "$signal_status" -eq 143 ] ||
    fail "$label interruption exited $signal_status instead of 143"
  grep -Fqx "known-good-$label" "$signal_dst/prior.txt" ||
    fail "$label interruption did not restore the prior install"
  if find "$signal_home/.agents/skills" \
    \( -name '.sprint-loops.install.*' -o \
       -name '.sprint-loops.backup.*' \) -print | grep -q .; then
    fail "$label interruption left transaction artifacts"
  fi
}

run_signal_case prior prior
run_signal_case activation activation
pass

# Static operator examples cover POSIX and native Windows current locations.
require_text "$README" '$HOME/.agents/skills/sprint-loops'
require_text "$README" '$REPO_ROOT/.agents/skills/sprint-loops'
require_text "$README" '[IO.FileAttributes]::ReparsePoint'
require_text "$README" '-ErrorAction Stop'
require_text "$README" 'finally'
require_text "$README" 'Git for Windows Bash'
require_text "$README" 'when Codex itself runs inside WSL'
require_text "$README" 'Filesystem and Windows drive roots are refused.'
require_text "$README" '-Source $bundleSource'
require_text "$POWERSHELL_TEST" 'Invoke-Expression $functionBlock.Groups[1].Value'
require_text "$README" ".agents\\skills\\sprint-loops"
reject_pattern '\.codex[/\\]skills|project.*trusted' "$README" "$INSTALL" "$SKILL" "$FRAGMENT"

powershell_output=
if command -v pwsh >/dev/null 2>&1; then
  powershell_output=$(
    pwsh -NoProfile -File "$POWERSHELL_TEST" -RepositoryRoot "$ROOT"
  )
elif command -v pwsh.exe >/dev/null 2>&1 &&
     command -v wslpath >/dev/null 2>&1; then
  powershell_test_windows=$(wslpath -w "$POWERSHELL_TEST")
  powershell_root_windows=$(wslpath -w "$ROOT")
  powershell_output=$(
    pwsh.exe -NoProfile -File "$powershell_test_windows" \
      -RepositoryRoot "$powershell_root_windows"
  )
elif command -v pwsh.exe >/dev/null 2>&1 &&
     command -v cygpath >/dev/null 2>&1; then
  powershell_test_windows=$(cygpath -w "$POWERSHELL_TEST")
  powershell_root_windows=$(cygpath -w "$ROOT")
  powershell_output=$(
    pwsh.exe -NoProfile -File "$powershell_test_windows" \
      -RepositoryRoot "$powershell_root_windows"
  )
else
  powershell_open_braces=$(tr -cd '{' < "$POWERSHELL_TEST" | wc -c | tr -d '[:space:]')
  powershell_close_braces=$(tr -cd '}' < "$POWERSHELL_TEST" | wc -c | tr -d '[:space:]')
  [ "$powershell_open_braces" -eq "$powershell_close_braces" ] ||
    fail "PowerShell fallback found unbalanced braces"
  powershell_output='adapter-contract.windows: static syntax-shape fallback passed'
fi
printf '%s\n' "$powershell_output" |
  grep -Fq 'adapter-contract.windows:' ||
  fail "PowerShell adapter contract did not produce confirmation"
pass

# Description boundary and progressive disclosure remain lean.
EXPECTED_DESCRIPTION='Run or resume the Sprint Loops Book v2 workflow when the user explicitly invokes $sprint-loops or directly asks to start, continue, resume, or run a sprint loop. Do not use it for ordinary documentation work or merely because a docs directory exists.'
description=$(
  awk 'NR == 1 { next }
       /^---$/ { exit }
       /^description: / { sub(/^description: /, ""); print }' "$SKILL"
)
description_count=$(
  awk 'NR == 1 { next }
       /^---$/ { print count + 0; exit }
       /^description: / { count++ }' "$SKILL"
)
[ "$description_count" -eq 1 ] ||
  fail "SKILL frontmatter has $description_count description fields"
[ "$description" = "$EXPECTED_DESCRIPTION" ] ||
  fail "SKILL frontmatter description does not match the activation contract"
require_text "$SKILL" 'filesystem or documentation presence is never an activation'
reject_pattern 'project root contains|contains a `sprints/`|merely because.*documentation exists' "$SKILL"
require_text "$README" '[`phases/00-overview.md`](skills/sprint-loops/phases/00-overview.md)'
require_text "$README" '[`schemas/intent.md`](skills/sprint-loops/schemas/intent.md)'
require_text "$README" '**Human/client checkpoint:**'
require_text "$PHASES/06-loop-phase.md" 'Add each new intent to `docs/SUMMARY.md` once'
reject_pattern '^# Core Protocol|^## Directory schema|^## Build plan|^## Test plan|^## Approval mode' "$README" "$SKILL"
reject_pattern 'current-phase|scripts/|phases/|uninitialized|ready-for-next-sprint|^## Route' "$FRAGMENT"
skill_lines=$(wc -l < "$SKILL" | tr -d '[:space:]')
fragment_lines=$(wc -l < "$FRAGMENT" | tr -d '[:space:]')
[ "$skill_lines" -le 80 ] || fail "SKILL.md duplicates phase detail ($skill_lines lines)"
[ "$fragment_lines" -le 10 ] || fail "AGENTS fragment is not a short pointer ($fragment_lines lines)"
pass

echo "adapter-contract.test: $COUNT Codex adapter contracts passed"
