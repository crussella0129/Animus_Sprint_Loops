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

expect_fail() { # $1 desc ; $2 required exact stderr line ; fixture already mutated
  # Exit 1 plus an exact full diagnostic line are both required. A crash,
  # another non-zero status, or a partial/regex match must not count as caught.
  local desc="$1" expected="$2" out rc
  total=$((total+1))
  rc=0
  out=$(BUNDLE_SYNC_ROOT="$T" bash "$GUARD" 2>&1) || rc=$?  # || keeps set -e out of the expected-failure path
  if [ "$rc" -eq 0 ]; then
    echo "FAIL (false pass): $desc"
  elif [ "$rc" -ne 1 ]; then
    echo "FAIL (wrong exit $rc): $desc"
  elif ! printf '%s\n' "$out" | grep -Fqx -- "$expected"; then
    echo "FAIL (wrong diagnostic): $desc (wanted exact line: $expected)"
  else
    echo "PASS caught: $desc"; pass=$((pass+1))
  fi
}

# baseline: clean copy must pass
mkfix; expect_pass "baseline clean copy passes"

# bad 1: content drift in a mirror script
mkfix; printf '\n# drifted\n' >> "$T/codex-cli/skills/sprint-loops/scripts/current-phase.sh"
expect_fail "content drift in mirror script" 'DIVERGED: codex-cli/skills/sprint-loops/scripts/current-phase.sh differs from open-harnesses/scripts/current-phase.sh'

# bad 2: mirror file deleted
mkfix; rm "$T/antigravity-ide/skills/sprint-loop/schemas/test-report.md"
expect_fail "deleted mirror schema" 'MISSING: antigravity-ide/skills/sprint-loop/schemas/test-report.md (reference: open-harnesses/schemas/test-report.md)'

# bad 3: extra file in a compared bundle's mapped set
mkfix; printf '#!/usr/bin/env bash\n' > "$T/codex-cli/skills/sprint-loops/scripts/rogue-helper.sh"
expect_fail "extra file in compared scripts/" 'EXTRA: codex-cli/skills/sprint-loops/scripts/rogue-helper.sh (absent from reference open-harnesses/scripts/)'

# bad 4: divergent shared phase (claude vs codex)
mkfix; printf '\ndrifted paragraph\n' >> "$T/codex-cli/skills/sprint-loops/phases/05-test-phase.md"
expect_fail "drifted shared phase 05" 'DIVERGED: codex-cli/skills/sprint-loops/phases/05-test-phase.md differs from claude-code/skills/sprint-loop/phases/05-test-phase.md'

# Book core 1: one bundle loses the shared path contract
mkfix; rm "$T/claude-code/skills/sprint-loop/scripts/book-paths.sh"
expect_fail "missing Book path contract" 'MISSING: claude-code/skills/sprint-loop/scripts/book-paths.sh (reference: open-harnesses/scripts/book-paths.sh)'

# Book core 2: synchronized deletion still violates the required inventory
mkfix
rm "$T/open-harnesses/scripts/book-paths.sh" \
  "$T/claude-code/skills/sprint-loop/scripts/book-paths.sh" \
  "$T/codex-cli/skills/sprint-loops/scripts/book-paths.sh" \
  "$T/antigravity-ide/skills/sprint-loop/scripts/book-paths.sh"
expect_fail "Book path contract deleted from every bundle" 'MISSING REQUIRED SHARED ASSET: scripts/book-paths.sh'

# Book core 3: validator bytes diverge
mkfix; printf '\n# drifted Book validator\n' >> "$T/antigravity-ide/skills/sprint-loop/scripts/check-book.sh"
expect_fail "divergent Book validator" 'DIVERGED: antigravity-ide/skills/sprint-loop/scripts/check-book.sh differs from open-harnesses/scripts/check-book.sh'

# Book core 4: migration helper bytes diverge
mkfix; printf '\n# drifted migration\n' >> "$T/codex-cli/skills/sprint-loops/scripts/migrate-to-book.sh"
expect_fail "divergent Book migration helper" 'DIVERGED: codex-cli/skills/sprint-loops/scripts/migrate-to-book.sh differs from open-harnesses/scripts/migrate-to-book.sh'

# Book core 5: a compared bundle grows an unshared migration helper
mkfix; cp "$T/open-harnesses/scripts/migrate-to-book.sh" "$T/claude-code/skills/sprint-loop/scripts/migrate-to-book-local.sh"
expect_fail "extra Book migration helper" 'EXTRA: claude-code/skills/sprint-loop/scripts/migrate-to-book-local.sh (absent from reference open-harnesses/scripts/)'

# Book schema 1: intent schema goes missing from one bundle
mkfix; rm "$T/codex-cli/skills/sprint-loops/schemas/intent.md"
expect_fail "missing Book intent schema" 'MISSING: codex-cli/skills/sprint-loops/schemas/intent.md (reference: open-harnesses/schemas/intent.md)'

# Book schema 2: intent schema bytes diverge
mkfix; printf '\nDrifted intent rule.\n' >> "$T/claude-code/skills/sprint-loop/schemas/intent.md"
expect_fail "divergent Book intent schema" 'DIVERGED: claude-code/skills/sprint-loop/schemas/intent.md differs from open-harnesses/schemas/intent.md'

# Book schema 3: a compared bundle grows an unshared intent schema
mkfix; cp "$T/open-harnesses/schemas/intent.md" "$T/antigravity-ide/skills/sprint-loop/schemas/intent-local.md"
expect_fail "extra Book intent schema" 'EXTRA: antigravity-ide/skills/sprint-loop/schemas/intent-local.md (absent from reference open-harnesses/schemas/)'

# Flat set 1: hidden regular extras participate in parity
mkfix; printf '# hidden drift\n' > "$T/codex-cli/skills/sprint-loops/scripts/.rogue-helper.sh"
expect_fail "hidden extra helper" 'EXTRA: codex-cli/skills/sprint-loops/scripts/.rogue-helper.sh (absent from reference open-harnesses/scripts/)'

# Flat set 2: expected entries may not be symlinks
mkfix
rm "$T/codex-cli/skills/sprint-loops/scripts/check-book.sh"
ln -s book-paths.sh "$T/codex-cli/skills/sprint-loops/scripts/check-book.sh"
expect_fail "symlinked shared helper" 'SYMLINK: codex-cli/skills/sprint-loops/scripts/check-book.sh'

# Flat set 3: directories and other non-regular entries are rejected, not walked
mkfix; mkdir "$T/antigravity-ide/skills/sprint-loop/schemas/rogue-directory"
expect_fail "unexpected schema directory" 'NON-REGULAR: antigravity-ide/skills/sprint-loop/schemas/rogue-directory'

# Pair diagnostics distinguish a missing physical phase reference from drift
mkfix; rm "$T/claude-code/skills/sprint-loop/phases/05-test-phase.md"
expect_fail "missing shared phase reference" 'MISSING REFERENCE: claude-code/skills/sprint-loop/phases/05-test-phase.md'

# Required inventories catch synchronized deletion in every shared category
mkfix
rm "$T/open-harnesses/schemas/intent.md" \
  "$T/claude-code/skills/sprint-loop/schemas/intent.md" \
  "$T/codex-cli/skills/sprint-loops/schemas/intent.md" \
  "$T/antigravity-ide/skills/sprint-loop/schemas/intent.md"
expect_fail "Book intent schema deleted from every bundle" 'MISSING REQUIRED SHARED ASSET: schemas/intent.md'

mkfix
rm "$T/open-harnesses/prompts/plan-critic.md" \
  "$T/claude-code/skills/sprint-loop/prompts/plan-critic.md" \
  "$T/codex-cli/skills/sprint-loops/prompts/plan-critic.md"
expect_fail "shared prompt deleted from every bundle" 'MISSING REQUIRED SHARED ASSET: prompts/plan-critic.md'

echo "bundle-sync fixture test: $pass/$total behaved"
[ "$pass" = "$total" ] && exit 0 || exit 1
