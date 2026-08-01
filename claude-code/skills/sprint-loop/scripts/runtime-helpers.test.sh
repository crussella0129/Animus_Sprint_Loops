#!/usr/bin/env bash
# Focused fixtures for Book-native runtime helpers and hard gates.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-runtime.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT
COUNT=0

fail() { echo "runtime-helpers.test: FAIL: $*" >&2; exit 1; }
pass() { COUNT=$((COUNT + 1)); }
run_script() {
  fixture=$1; script=$2; shift 2
  (cd "$fixture" && bash "$SCRIPT_DIR/$script" "$@")
}
expect_failure() {
  expected=$1; shift
  set +e
  output=$("$@" 2>&1)
  status=$?
  set -e
  [ "$status" -ne 0 ] || fail "expected failure containing: $expected"
  case "$output" in *"$expected"*) : ;; *) fail "missing diagnostic '$expected': $output" ;; esac
}
init_fixture() {
  F="$TMP_ROOT/$1"
  mkdir -p "$F"
  git -C "$F" init -q
  git -C "$F" config user.email sprint-loop@example.invalid
  git -C "$F" config user.name "Sprint Loop Test"
  run_script "$F" init-sprint.sh >/dev/null
}
plan_fixture() {
  init_fixture "$1"
  cat > "$F/docs/intents/INT-0001-runtime.md" <<'EOF'
# INT-0001 — Runtime

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0001
- **State:** planned
- **Work evidence:** [T-001 build plan](../sprints/s0/sprint-plans/build-plan.md#t-001-runtime)
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** none
- **Documentation evidence:** none

## Intent
Exercise runtime helpers.

## Acceptance criteria
The planned helper transition succeeds.

## Rationale
Fixture coverage.

## Alternatives
None.

## Consequences
The fixture carries valid Book metadata.

## Transition history
- 2026-08-01: created as `proposed`.
- 2026-08-01: accepted into sprint 0 as `planned`.
EOF
  cat > "$F/docs/sprints/s0/sprint-research/research-report.md" <<'EOF'
# Research
## Intents Reviewed
- [INT-0001](../../../intents/INT-0001-runtime.md) — selected
## Existing Code Survey
| File | Note |
|---|---|
## External Sources
EOF
  cat > "$F/docs/sprints/s0/sprint-plans/build-plan.md" <<'EOF'
# Build
### T-001: Runtime
- do it
EOF
  printf '# Test\n- verify it\n' > "$F/docs/sprints/s0/sprint-plans/test-plan.md"
  cat > "$F/docs/sprints/s0/sprint-plans/critique.md" <<'EOF'
# Critique
## Concerns
- none
## Confidence
clean
EOF
}
unlocked() {
  ! grep -qF 'Finalized - DO NOT EDIT' "$1/docs/sprints/s0/sprint-plans/build-plan.md"
  ! grep -qF 'Finalized - DO NOT EDIT' "$1/docs/sprints/s0/sprint-plans/test-plan.md"
}

# Intent review, legacy migration guidance, empty tasks, and critic gates all
# refuse before either plan changes.
plan_fixture no_intent
rm "$F/docs/intents/INT-0001-runtime.md"
expect_failure 'Book has no intent chapters' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "zero-intent Book partially locked plans"
pass

plan_fixture missing_intent
printf '# Research\n' > "$F/docs/sprints/s0/sprint-research/research-report.md"
expect_failure 'lacks a `## Intents Reviewed`' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "missing intent review partially locked plans"
pass

plan_fixture unlinked_intent
printf '# Research\n## Intents Reviewed\n- INT-0001\n' > "$F/docs/sprints/s0/sprint-research/research-report.md"
expect_failure 'must link at least one Book intent' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "unlinked intent review partially locked plans"
pass

plan_fixture missing_link_target
printf '# Research\n## Intents Reviewed\n- [INT-9999](../../../intents/INT-9999-missing.md)\n' > "$F/docs/sprints/s0/sprint-research/research-report.md"
expect_failure 'must link at least one Book intent' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "missing intent link target partially locked plans"
pass

plan_fixture legacy_heading
printf '# Research\n## Decisions Reviewed\n- ADR-1\n' > "$F/docs/sprints/s0/sprint-research/research-report.md"
expect_failure 'legacy `## Decisions Reviewed`' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "legacy heading partially locked plans"
pass

plan_fixture empty_build
printf '# Build\n- prose only\n' > "$F/docs/sprints/s0/sprint-plans/build-plan.md"
expect_failure 'no `### T-XXX:`' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "empty build plan partially locked plans"
pass

plan_fixture blocking_critic
sed 's/^clean$/block/' "$F/docs/sprints/s0/sprint-plans/critique.md" > "$F/crit.tmp"
mv "$F/crit.tmp" "$F/docs/sprints/s0/sprint-plans/critique.md"
expect_failure 'verdict is `block`' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "blocking critic partially locked plans"
pass

plan_fixture malformed_critic
cat > "$F/docs/sprints/s0/sprint-plans/critique.md" <<'EOF'
# Critique
## Concernsville
- not an exact contract heading
## ConfidenceBoost
clean
EOF
expect_failure 'does not match the exact critic contract' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "malformed critic partially locked plans"
pass

plan_fixture trailing_critic_verdict
sed 's/^clean$/clean extra/' "$F/docs/sprints/s0/sprint-plans/critique.md" > "$F/crit.tmp"
mv "$F/crit.tmp" "$F/docs/sprints/s0/sprint-plans/critique.md"
expect_failure 'does not match the exact critic contract' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "trailing critic verdict partially locked plans"
pass

plan_fixture duplicate_critic_verdict
cat >> "$F/docs/sprints/s0/sprint-plans/critique.md" <<'EOF'
## Confidence
clean
EOF
expect_failure 'does not match the exact critic contract' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "duplicate critic verdict partially locked plans"
pass

plan_fixture fenced_critic_verdict
cat > "$F/docs/sprints/s0/sprint-plans/critique.md" <<'EOF'
# Critique
## Concerns
- none
```markdown
## Confidence
clean
```
EOF
expect_failure 'does not match the exact critic contract' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "fenced critic verdict partially locked plans"
pass

plan_fixture invalid_test
: > "$F/docs/sprints/s0/sprint-plans/test-plan.md"
before=$(git hash-object "$F/docs/sprints/s0/sprint-plans/build-plan.md")
expect_failure 'missing or empty' run_script "$F" finalize-plan.sh
after=$(git hash-object "$F/docs/sprints/s0/sprint-plans/build-plan.md")
[ "$before" = "$after" ] && unlocked "$F" || fail "invalid test plan mutated build plan"
pass

# The old 20-file/5-source budget remains enforced; a non-empty override is
# explicit authority to proceed.
plan_fixture budget
{
  printf '# Research\n## Intents Reviewed\n- [INT-0001](../../../intents/INT-0001-runtime.md)\n## Existing Code Survey\n| File | Note |\n|---|---|\n'
  i=1; while [ "$i" -le 21 ]; do printf '| f%s | n |\n' "$i"; i=$((i + 1)); done
  printf '## External Sources\n'
} > "$F/docs/sprints/s0/sprint-research/research-report.md"
expect_failure 'research budget exceeded' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "budget gate partially locked plans"
cat >> "$F/docs/sprints/s0/sprint-research/research-report.md" <<'EOF'
## Budget Override
The cross-bundle inventory is intentionally broad.
EOF
run_script "$F" finalize-plan.sh >/dev/null
[ "$(head -n 1 "$F/docs/sprints/s0/sprint-plans/build-plan.md")" = 'Finalized - DO NOT EDIT' ] || fail "build plan not locked"
[ "$(head -n 1 "$F/docs/sprints/s0/sprint-plans/test-plan.md")" = 'Finalized - DO NOT EDIT' ] || fail "test plan not locked"
pass

plan_fixture source_budget
{
  printf '# Research\n## Intents Reviewed\n- [INT-0001](../../../intents/INT-0001-runtime.md)\n## Existing Code Survey\n| File | Note |\n|---|---|\n'
  printf '## External Sources\n'
  i=1
  while [ "$i" -le 6 ]; do
    printf -- '- [source %s](https://example.invalid/%s)\n' "$i" "$i"
    i=$((i + 1))
  done
} > "$F/docs/sprints/s0/sprint-research/research-report.md"
expect_failure 'research budget exceeded' run_script "$F" finalize-plan.sh
unlocked "$F" || fail "six-source budget gate partially locked plans"
pass

plan_fixture crlf_plans
for plan_name in build-plan.md test-plan.md; do
  plan_path="$F/docs/sprints/s0/sprint-plans/$plan_name"
  awk '{ printf "%s\r\n", $0 }' "$plan_path" > "$F/plan.tmp"
  mv "$F/plan.tmp" "$plan_path"
done
run_script "$F" finalize-plan.sh >/dev/null
for plan_name in build-plan.md test-plan.md; do
  plan_path="$F/docs/sprints/s0/sprint-plans/$plan_name"
  awk 'substr($0, length($0), 1) != "\r" { exit 1 }' "$plan_path" ||
    fail "finalization did not preserve uniform CRLF in $plan_name"
done
crlf_build=$(git hash-object "$F/docs/sprints/s0/sprint-plans/build-plan.md")
crlf_test=$(git hash-object "$F/docs/sprints/s0/sprint-plans/test-plan.md")
run_script "$F" finalize-plan.sh >/dev/null
[ "$crlf_build" = "$(git hash-object "$F/docs/sprints/s0/sprint-plans/build-plan.md")" ] ||
  fail "CRLF locked build plan was rewritten"
[ "$crlf_test" = "$(git hash-object "$F/docs/sprints/s0/sprint-plans/test-plan.md")" ] ||
  fail "CRLF locked test plan was rewritten"
pass

# A signal delivered after the first rename restores both original plans.
plan_fixture signal_finalize
build_before=$(git hash-object "$F/docs/sprints/s0/sprint-plans/build-plan.md")
test_before=$(git hash-object "$F/docs/sprints/s0/sprint-plans/test-plan.md")
MV_STUB="$F/mv-stub"
mkdir -p "$MV_STUB"
REAL_MV_BIN=$(command -v mv)
cat > "$MV_STUB/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source_path=${1-}
target_path=${2-}
"$REAL_MV_BIN" "$@"
case "$source_path|$target_path" in
  *.tmp.*"|"*/build-plan.md) kill -TERM "$PPID" ;;
esac
EOF
chmod +x "$MV_STUB/mv"
set +e
(cd "$F" && PATH="$MV_STUB:$PATH" REAL_MV_BIN="$REAL_MV_BIN" \
  bash "$SCRIPT_DIR/finalize-plan.sh" >/dev/null 2>&1)
signal_status=$?
set -e
[ "$signal_status" -ne 0 ] || fail "signal injection did not interrupt plan finalization"
[ "$build_before" = "$(git hash-object "$F/docs/sprints/s0/sprint-plans/build-plan.md")" ] ||
  fail "signal left build plan mutated"
[ "$test_before" = "$(git hash-object "$F/docs/sprints/s0/sprint-plans/test-plan.md")" ] ||
  fail "signal left test plan mutated"
unlocked "$F" || fail "signal left a partial plan lock"
pass

# Back-fill only the first exact placeholder while retaining its evidence and
# leaving prose and the later placeholder untouched.
init_fixture commit
git -C "$F" add -A
git -C "$F" commit -qm 'fixture base'
cat > "$F/completed-lf.md" <<'EOF'
# Completed Tasks
Prose mentions - **Commit:** PENDING without being an evidence line.
## T-001 (sprint 0)
- **Completed:** 2026-08-01T00:00:00Z
- **Files modified:** src/example.txt
- **Commit:** PENDING
## T-002 (sprint 0)
- **Completed:** 2026-08-01T00:01:00Z
- **Files modified:** src/later.txt
- **Commit:** PENDING
EOF
awk '{ printf "%s\r\n", $0 }' "$F/completed-lf.md" > "$F/docs/work/completed-tasks.md"
rm "$F/completed-lf.md"
mkdir -p "$F/src"
printf 'done\n' > "$F/src/example.txt"
printf 'keep staged\n' > "$F/unrelated-staged.txt"
git -C "$F" add unrelated-staged.txt
printf 'keep unstaged\n' > "$F/unrelated-unstaged.txt"
run_script "$F" commit-task.sh T-001 'finish runtime fixture' -- src/example.txt >/dev/null
pending_count=$(awk '
  { sub(/\r$/, "", $0) }
  $0 == "- **Commit:** PENDING" { n++ }
  END { print n+0 }
' "$F/docs/work/completed-tasks.md")
[ "$pending_count" -eq 1 ] || fail "wrong placeholder count after commit"
grep -qF 'Prose mentions - **Commit:** PENDING' "$F/docs/work/completed-tasks.md" || fail "prose was changed"
grep -qF -- '- **Completed:** 2026-08-01T00:00:00Z' "$F/docs/work/completed-tasks.md" || fail "timestamp lost"
ref=$(awk '
  { sub(/\r$/, "", $0) }
  /^- \*\*Commit:\*\* `/ {
    sub(/^- \*\*Commit:\*\* `/, ""); sub(/`$/, ""); print; exit
  }
' "$F/docs/work/completed-tasks.md")
[ -n "$ref" ] && git -C "$F" cat-file -e "$ref^{commit}" || fail "commit evidence is not resolvable"
awk 'substr($0, length($0), 1) != "\r" { exit 1 }' "$F/docs/work/completed-tasks.md" ||
  fail "commit evidence did not preserve ledger CRLF"
git -C "$F" diff --cached --name-only | grep -qFx unrelated-staged.txt ||
  fail "task commit consumed an unrelated staged file"
[ -f "$F/unrelated-unstaged.txt" ] && ! git -C "$F" ls-files --error-unmatch unrelated-unstaged.txt >/dev/null 2>&1 ||
  fail "task commit consumed an unrelated unstaged file"
git clone -q --no-hardlinks "$F" "$TMP_ROOT/commit-clone"
git -C "$TMP_ROOT/commit-clone" cat-file -e "$ref^{commit}" ||
  fail "recorded task commit does not survive a normal clone"
pass

# Closing before Loop evidence is a forbidden state transition.
for guarded_phase in research build test; do
  init_fixture "close_guard_$guarded_phase"
  META="$F/docs/sprints/s0/sprint-meta.md"
  if [ "$guarded_phase" != research ]; then
    printf '# Research\n' > "$F/docs/sprints/s0/sprint-research/research-report.md"
    printf 'Finalized - DO NOT EDIT\n\n# Build\n' > "$F/docs/sprints/s0/sprint-plans/build-plan.md"
    printf 'Finalized - DO NOT EDIT\n\n# Test\n' > "$F/docs/sprints/s0/sprint-plans/test-plan.md"
  fi
  if [ "$guarded_phase" = build ]; then
    printf '# Tasks\n- [ ] T-001 (sprint 0): pending\n' > "$F/docs/work/tasks.md"
  elif [ "$guarded_phase" = test ]; then
    printf '# Completed\n## T-001 (sprint 0)\n' > "$F/docs/work/completed-tasks.md"
  fi
  meta_before=$(git hash-object "$META")
  expect_failure "current phase is $guarded_phase" run_script "$F" close-sprint.sh success 'premature evidence'
  [ "$meta_before" = "$(git hash-object "$META")" ] ||
    fail "premature close mutated meta during $guarded_phase"
done
pass

# Abort and close touch Book meta only, preserve CRLF, use terminal-state
# idempotence, and support migrated meta lacking newer completion fields.
init_fixture abort
META="$F/docs/sprints/s0/sprint-meta.md"
awk '{ printf "%s\r\n", $0 }' "$META" > "$F/meta.tmp"
mv "$F/meta.tmp" "$META"
printf 'unchanged\n' > "$F/sentinel.txt"
git -C "$F" add -A
git -C "$F" commit -qm 'fixture base'
sentinel=$(git hash-object "$F/sentinel.txt")
abort_before=$(git hash-object "$META")
printf '#!/usr/bin/env sh\nexit 1\n' > "$F/.git/hooks/pre-commit"
chmod +x "$F/.git/hooks/pre-commit"
expect_failure 'original Book and index restored' run_script "$F" abort-sprint.sh 'dependency\path unavailable'
[ "$abort_before" = "$(git hash-object "$META")" ] ||
  fail "failed abort commit left terminal metadata"
rm "$F/.git/hooks/pre-commit"
run_script "$F" abort-sprint.sh 'dependency\path unavailable' >/dev/null
grep -qF -- '- **Exit status:** aborted' "$META" || fail "abort status missing"
grep -qF '## Abort note (' "$META" || fail "abort note missing"
grep -qF 'dependency\path unavailable' "$META" || fail "abort reason missing"
awk 'substr($0, length($0), 1) != "\r" { exit 1 }' "$META" ||
  fail "abort did not preserve uniform CRLF"
awk '{ sub(/\r$/, "") } /^- \*\*End timestamp:\*\* [0-9][0-9][0-9][0-9]-.*Z$/ { found=1 } END { exit !found }' "$META" ||
  fail "abort timestamp missing"
[ "$sentinel" = "$(git hash-object "$F/sentinel.txt")" ] || fail "abort changed unrelated file"
pass

init_fixture close_failure_cross
META="$F/docs/sprints/s0/sprint-meta.md"
printf '# Research\n' > "$F/docs/sprints/s0/sprint-research/research-report.md"
printf 'Finalized - DO NOT EDIT\n\n# Build\n' > "$F/docs/sprints/s0/sprint-plans/build-plan.md"
printf 'Finalized - DO NOT EDIT\n\n# Test\n' > "$F/docs/sprints/s0/sprint-plans/test-plan.md"
printf '# Completed\n## T-001 (sprint 0)\n' > "$F/docs/work/completed-tasks.md"
printf '# Failure\nverification failed\n' > "$F/docs/sprints/s0/failure-report.md"
failure_meta_before=$(git hash-object "$META")
expect_failure 'as success: passing test report and critique are required' \
  run_script "$F" close-sprint.sh success 'contradictory evidence'
[ "$failure_meta_before" = "$(git hash-object "$META")" ] ||
  fail "success/failure evidence crossing mutated meta"
pass

init_fixture close_blocking_critic
META="$F/docs/sprints/s0/sprint-meta.md"
printf '# Research\n' > "$F/docs/sprints/s0/sprint-research/research-report.md"
printf 'Finalized - DO NOT EDIT\n\n# Build\n' > "$F/docs/sprints/s0/sprint-plans/build-plan.md"
printf 'Finalized - DO NOT EDIT\n\n# Test\n' > "$F/docs/sprints/s0/sprint-plans/test-plan.md"
printf '# Completed\n## T-001 (sprint 0)\n' > "$F/docs/work/completed-tasks.md"
printf '# Test report\npass\n' > "$F/docs/sprints/s0/sprint-tests/test-report.md"
cat > "$F/docs/sprints/s0/sprint-tests/critique.md" <<'EOF'
# Critique
## Concerns
- acceptance gap
## Confidence
block
EOF
[ "$(run_script "$F" current-phase.sh)" = test ] ||
  fail "blocking test critique routed to Loop"
expect_failure 'current phase is test' \
  run_script "$F" close-sprint.sh success 'blocked critique'
pass

init_fixture close
META="$F/docs/sprints/s0/sprint-meta.md"
awk '!/Book schema version/ && !/Completion evidence/' "$META" > "$F/meta.tmp"
mv "$F/meta.tmp" "$META"
printf '# Research\n' > "$F/docs/sprints/s0/sprint-research/research-report.md"
printf 'Finalized - DO NOT EDIT\n\n# Build\n' > "$F/docs/sprints/s0/sprint-plans/build-plan.md"
printf 'Finalized - DO NOT EDIT\n\n# Test\n' > "$F/docs/sprints/s0/sprint-plans/test-plan.md"
printf '# Completed\n## T-001 (sprint 0)\n' > "$F/docs/work/completed-tasks.md"
printf '# Test report\npass\n' > "$F/docs/sprints/s0/sprint-tests/test-report.md"
cat > "$F/docs/sprints/s0/sprint-tests/critique.md" <<'EOF'
# Critique
## Concerns
- none
## Confidence
clean
EOF
awk '{ printf "%s\r\n", $0 }' "$META" > "$F/meta.tmp"
mv "$F/meta.tmp" "$META"
printf 'do not rewrite\n' > "$F/docs/sprints/s0/sprint-tests/unit-tests.md"
git -C "$F" add -A
git -C "$F" commit -qm 'migrated fixture'
artifact=$(git hash-object "$F/docs/sprints/s0/sprint-tests/unit-tests.md")
pass_meta_before=$(git hash-object "$META")
expect_failure 'as failed: a non-empty failure report is required' \
  run_script "$F" close-sprint.sh failed 'contradictory evidence'
[ "$pass_meta_before" = "$(git hash-object "$META")" ] ||
  fail "failed/pass evidence crossing mutated meta"
printf '#!/usr/bin/env sh\nexit 1\n' > "$F/.git/hooks/pre-commit"
chmod +x "$F/.git/hooks/pre-commit"
expect_failure 'original Book and index restored' \
  run_script "$F" close-sprint.sh success 'tests: sprint-tests\test-report.md; commits: HEAD'
[ "$pass_meta_before" = "$(git hash-object "$META")" ] ||
  fail "failed close commit left terminal metadata"
rm "$F/.git/hooks/pre-commit"
run_script "$F" close-sprint.sh success 'tests: sprint-tests\test-report.md; commits: HEAD' >/dev/null
grep -qF -- '- **Exit status:** success' "$META" || fail "close status missing"
grep -qF -- '- **Completion evidence:** tests: sprint-tests\test-report.md; commits: HEAD' "$META" || fail "completion evidence missing"
awk 'substr($0, length($0), 1) != "\r" { exit 1 }' "$META" ||
  fail "close did not preserve uniform CRLF"
awk '{ sub(/\r$/, "") } /^- \*\*End timestamp:\*\* [0-9][0-9][0-9][0-9]-.*Z$/ { found=1 } END { exit !found }' "$META" ||
  fail "close timestamp missing"
closed=$(git hash-object "$META")
run_script "$F" close-sprint.sh success 'ignored on idempotent close' >/dev/null
[ "$closed" = "$(git hash-object "$META")" ] || fail "closed meta was rewritten"
[ "$artifact" = "$(git hash-object "$F/docs/sprints/s0/sprint-tests/unit-tests.md")" ] || fail "close rewrote sprint artifact"
pass

init_fixture confidence
run_script "$F" update-confidence.sh failed >/dev/null
[ "$(cat "$F/docs/work/confidence.txt")" = 0.7 ] || fail "failed delta changed"
run_script "$F" update-confidence.sh patched >/dev/null
[ "$(cat "$F/docs/work/confidence.txt")" = 0.6 ] || fail "patched delta changed"
run_script "$F" update-confidence.sh pass >/dev/null
[ "$(cat "$F/docs/work/confidence.txt")" = 0.7 ] || fail "pass delta changed"
[ ! -e "$F/confidence.txt" ] || fail "legacy confidence authority created"
pass

echo "runtime-helpers.test: $COUNT Book runtime fixtures passed"
