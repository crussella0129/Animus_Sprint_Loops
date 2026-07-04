#!/usr/bin/env bash
# Fixture test for check-bundle-sync.sh — proves the guard catches drift.
# Copies the mapped bundle assets into a throwaway tree, mutates it into
# known-bad states, and asserts the guard exits non-zero. Never touches
# tracked files. The guard is pointed at each fixture via BUNDLE_SYNC_ROOT.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/tools/check-bundle-sync.sh"
pass=0; total=0

TMPDIRS=()
cleanup() { for d in "${TMPDIRS[@]:-}"; do [ -n "$d" ] && rm -rf "$d"; done; }
trap cleanup EXIT

mkfix() { # copy the mapped subtrees into a temp root
  T=$(mktemp -d)
  TMPDIRS+=("$T")
  local b
  for b in claude-code/skills/sprint-loop codex-cli/skills/sprint-loops antigravity-ide/skills/sprint-loop; do
    mkdir -p "$T/$b"
    cp -r "$ROOT/$b/scripts" "$T/$b/scripts"
    cp -r "$ROOT/$b/schemas" "$T/$b/schemas"
  done
  mkdir -p "$T/open-harnesses"
  cp -r "$ROOT/open-harnesses/scripts" "$T/open-harnesses/scripts"
  cp -r "$ROOT/open-harnesses/schemas" "$T/open-harnesses/schemas"
  cp -r "$ROOT/open-harnesses/prompts" "$T/open-harnesses/prompts"
  cp -r "$ROOT/claude-code/skills/sprint-loop/prompts" "$T/claude-code/skills/sprint-loop/prompts"
  cp -r "$ROOT/codex-cli/skills/sprint-loops/prompts" "$T/codex-cli/skills/sprint-loops/prompts"
  mkdir -p "$T/claude-code/skills/sprint-loop/phases" "$T/codex-cli/skills/sprint-loops/phases"
  local p
  for p in 00-overview 01-init-sprint 02-research-phase 04-build-phase 05-test-phase; do
    cp "$ROOT/claude-code/skills/sprint-loop/phases/$p.md" "$T/claude-code/skills/sprint-loop/phases/$p.md"
    cp "$ROOT/codex-cli/skills/sprint-loops/phases/$p.md" "$T/codex-cli/skills/sprint-loops/phases/$p.md"
  done
}

expect_pass() { # $1 desc
  local desc="$1"; total=$((total+1))
  if BUNDLE_SYNC_ROOT="$T" bash "$GUARD" >/dev/null 2>&1; then
    echo "PASS $desc"; pass=$((pass+1))
  else
    echo "FAIL (false reject): $desc"
  fi
}

expect_fail() { # $1 desc ; $2 required stderr pattern (ERE) ; fixture already mutated
  # Non-zero exit alone is NOT enough — the guard's EARS contract is to NAME
  # the offending path. Requiring the pattern keeps this fixture from going
  # vacuous the way the merge-policy fixture once did (a crash or silent
  # exit-1 must not count as "caught").
  local desc="$1" pattern="$2" out rc
  total=$((total+1))
  rc=0
  out=$(BUNDLE_SYNC_ROOT="$T" bash "$GUARD" 2>&1) || rc=$?  # || keeps set -e out of the expected-failure path
  if [ "$rc" -eq 0 ]; then
    echo "FAIL (false pass): $desc"
  elif ! printf '%s' "$out" | grep -qE "$pattern"; then
    echo "FAIL (wrong failure — path not named): $desc (wanted /$pattern/)"
  else
    echo "PASS caught: $desc"; pass=$((pass+1))
  fi
}

# baseline: clean copy must pass
mkfix; expect_pass "baseline clean copy passes"

# bad 1: content drift in a mirror script
mkfix; printf '\n# drifted\n' >> "$T/codex-cli/skills/sprint-loops/scripts/current-phase.sh"
expect_fail "content drift in mirror script" 'DIVERGED: codex-cli/skills/sprint-loops/scripts/current-phase\.sh'

# bad 2: mirror file deleted
mkfix; rm "$T/antigravity-ide/skills/sprint-loop/schemas/test-report.md"
expect_fail "deleted mirror schema" 'MISSING: antigravity-ide/skills/sprint-loop/schemas/test-report\.md'

# bad 3: extra file in a mirror's mapped set
mkfix; printf '#!/usr/bin/env bash\n' > "$T/open-harnesses/scripts/rogue-helper.sh"
expect_fail "extra file in mirror scripts/" 'EXTRA: open-harnesses/scripts/rogue-helper\.sh'

# bad 4: divergent shared phase (claude vs codex)
mkfix; printf '\ndrifted paragraph\n' >> "$T/codex-cli/skills/sprint-loops/phases/05-test-phase.md"
expect_fail "drifted shared phase 05" 'DIVERGED: codex-cli/skills/sprint-loops/phases/05-test-phase\.md'

echo "bundle-sync fixture test: $pass/$total behaved"
[ "$pass" = "$total" ] && exit 0 || exit 1
