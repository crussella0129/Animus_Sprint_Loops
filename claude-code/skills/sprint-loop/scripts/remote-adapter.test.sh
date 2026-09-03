#!/usr/bin/env bash
# Fixtures for remote-adapter.sh — open-once, refuse-second, generic fallback,
# never-merge, plus the sprint-18 checkpoint gate, composed title, and recorded
# checkpoint. gh/glab are stubbed on PATH; a local bare repo backs the push.
#
# Every fixture that expects a checkpoint to open now carries a Book with a
# closed sprint: at contract 3 the adapter refuses to checkpoint an open sprint,
# so a repo-and-profile-only fixture is refused as uninitialized.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RA="$SCRIPT_DIR/remote-adapter.sh"
INIT="$SCRIPT_DIR/init-sprint.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sprint-loop-adapter.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM
pass() { printf '  PASS  %s\n' "$1"; }
die() { printf '  FAIL  %s: %s\n' "$1" "$2" >&2; exit 1; }

make_repo() {  # <dir> <profile-body>
  git init -q --bare "$1.git"
  git init -q "$1"
  git -C "$1" checkout -q -b dev
  git -C "$1" config user.email t@t
  git -C "$1" config user.name t
  git -C "$1" commit -q --allow-empty -m init
  git -C "$1" remote add origin "$1.git"
  ( cd "$1" && SPRINT_LOOP_PROJECT_ROOT=. SPRINT_MODEL=selftest bash "$INIT" >/dev/null )
  stamp_contract "$1" 3
  mkdir -p "$1/docs/work"
  printf '# Remote Profile\n\n<!-- sprint-loop-remote-profile-v2 -->\n\n```\n%s\n```\n' \
    "$2" > "$1/docs/work/remote-profile.md"
}

stamp_contract() { printf 'schema-version: 2\nsubstrate-version: %s\n' "$2" > "$1/docs/.sprint-loop-book"; }

# The Book is created by make_repo; this only restores the contract stamp.
make_book() { stamp_contract "$1" 3; }

set_meta_field() {  # <dir> <field> <value>
  local m="$1/docs/sprints/s0/sprint-meta.md"
  FIELD="$2" VALUE="$3" awk '
    BEGIN { prefix="- **" ENVIRON["FIELD"] ":** " }
    { line=$0; sub(/\r$/, "", line) }
    substr(line, 1, length(prefix)) == prefix { print prefix ENVIRON["VALUE"]; next }
    { print line }
  ' "$m" > "$m.tmp" && mv "$m.tmp" "$m"
}

# Walk a Book to phase `loop`, then close it, so the checkpoint gate is satisfied.
advance_to_loop() {  # <dir>
  printf '# Research\n' > "$1/docs/sprints/s0/sprint-research/research-report.md"
  printf 'Finalized - DO NOT EDIT\n\n# Build\n' > "$1/docs/sprints/s0/sprint-plans/build-plan.md"
  printf 'Finalized - DO NOT EDIT\n\n# Test\n' > "$1/docs/sprints/s0/sprint-plans/test-plan.md"
  printf '# Completed\n## T-001 (sprint 0)\n' > "$1/docs/work/completed-tasks.md"
  printf '# Test report\npass\n' > "$1/docs/sprints/s0/sprint-tests/test-report.md"
  printf '# Critique\n## Concerns\n- none\n## Confidence\nclean\n' > "$1/docs/sprints/s0/sprint-tests/critique.md"
}
close_book() {  # <dir> <summary>
  advance_to_loop "$1"
  set_meta_field "$1" 'Exit status' success
  set_meta_field "$1" Summary "$2"
}
make_closed_book() {  # <dir> <summary>
  close_book "$1" "$2"
  git -C "$1" add -A
  git -C "$1" commit -qm book
}
phase_of() { ( cd "$1" && SPRINT_LOOP_PROJECT_ROOT=. bash "$SCRIPT_DIR/current-phase.sh" ); }

STUB_BIN="$TMP_ROOT/bin"; mkdir -p "$STUB_BIN"
cat > "$STUB_BIN/gh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUBLOG"
if [ "${1:-}" = pr ] && [ "${2:-}" = list ]; then [ "${STUB_PR_EXISTS:-0}" = 1 ] && echo 42; exit 0; fi
if [ "${1:-}" = pr ] && [ "${2:-}" = create ]; then echo "https://example/pr/1"; exit 0; fi
exit 0
STUB
chmod +x "$STUB_BIN/gh"

GH_PROFILE='provider: github
base: main
work: dev'

# test_pr_opens_once
P1="$TMP_ROOT/once"; make_repo "$P1" "$GH_PROFILE"; make_closed_book "$P1" 'Widget support'
export STUBLOG="$P1.log"; : > "$STUBLOG"
PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 bash "$RA" --root "$P1" open-pr >/dev/null 2>&1 ||
  die test_pr_opens_once 'open-pr failed'
[ "$(grep -c 'pr create' "$STUBLOG")" = 1 ] || die test_pr_opens_once "expected 1 create, got $(grep -c 'pr create' "$STUBLOG")"
grep -q 'pr merge' "$STUBLOG" && die test_pr_opens_once 'merge was invoked'
pass test_pr_opens_once

# test_checkpoint_title_composed_from_book
grep -q 'title Sprint 0: Widget support' "$STUBLOG" ||
  die test_checkpoint_title_composed_from_book "composed title missing: $(cat "$STUBLOG")"
pass test_checkpoint_title_composed_from_book

# test_checkpoint_recorded_once + test_checkpoint_record_is_committed
P1_META="$P1/docs/sprints/s0/sprint-meta.md"
[ "$(grep -c -- '- \*\*Checkpoint:\*\*' "$P1_META")" = 1 ] ||
  die test_checkpoint_recorded_once 'checkpoint not recorded exactly once'
grep -qF -- '- **Checkpoint:** https://example/pr/1' "$P1_META" ||
  die test_checkpoint_recorded_once 'recorded checkpoint URL is wrong'
[ -z "$(git -C "$P1" status --porcelain -- docs)" ] ||
  die test_checkpoint_record_is_committed 'checkpoint record left the Book dirty'
pass test_checkpoint_recorded_once
pass test_checkpoint_record_is_committed

# A second open-pr neither opens a request nor changes the recorded field.
before_meta=$(git -C "$P1" hash-object "$P1_META")
PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=1 bash "$RA" --root "$P1" open-pr >/dev/null 2>&1 ||
  die test_checkpoint_recorded_once 'second open-pr errored'
[ "$(grep -c 'pr create' "$STUBLOG")" = 1 ] || die test_checkpoint_recorded_once 'opened a second request'
[ "$before_meta" = "$(git -C "$P1" hash-object "$P1_META")" ] ||
  die test_checkpoint_recorded_once 'second open-pr rewrote the record'
pass test_checkpoint_reopen_is_inert

# test_pr_refuses_existing_checkpoint
P2="$TMP_ROOT/second"; make_repo "$P2" "$GH_PROFILE"; make_closed_book "$P2" 'Second sprint'
export STUBLOG="$P2.log"; : > "$STUBLOG"
out=$(PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=1 bash "$RA" --root "$P2" open-pr 2>&1) ||
  die test_pr_refuses_existing_checkpoint 'open-pr errored'
grep -q 'pr create' "$STUBLOG" && die test_pr_refuses_existing_checkpoint 'opened a second PR'
printf '%s' "$out" | grep -qi 'already' || die test_pr_refuses_existing_checkpoint 'no already-open message'
pass test_pr_refuses_existing_checkpoint

# test_provider_fallback_generic
P3="$TMP_ROOT/generic"; make_repo "$P3" 'provider: generic
base: main
work: dev'
make_closed_book "$P3" 'Generic host'
out=$(bash "$RA" --root "$P3" open-pr 2>&1) || die test_provider_fallback_generic 'generic open-pr failed'
printf '%s' "$out" | grep -qi 'manually' || die test_provider_fallback_generic 'no fallback message'
pass test_provider_fallback_generic

# test_merge_policy_human_approve
P4="$TMP_ROOT/merge"; make_repo "$P4" 'provider: github
base: main
work: dev
mergePolicy: human-approve'
make_closed_book "$P4" 'Human approve'
export STUBLOG="$P4.log"; : > "$STUBLOG"
PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 bash "$RA" --root "$P4" open-pr >/dev/null 2>&1 ||
  die test_merge_policy_human_approve 'open-pr failed'
grep -q 'pr merge' "$STUBLOG" && die test_merge_policy_human_approve 'merge invoked under human-approve'
pass test_merge_policy_human_approve

# test_head_override_rejected
PH="$TMP_ROOT/head"; make_repo "$PH" "$GH_PROFILE"; make_closed_book "$PH" 'Head override'
export STUBLOG="$PH.log"; : > "$STUBLOG"
if PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 \
   bash "$RA" --root "$PH" --head alternate open-pr >"$PH.out" 2>&1; then
  die test_head_override_rejected 'head override was accepted'
fi
grep -q 'unknown argument --head' "$PH.out" ||
  die test_head_override_rejected 'no unknown-argument diagnostic'
[ ! -s "$STUBLOG" ] || die test_head_override_rejected 'provider was invoked'
pass test_head_override_rejected

# test_checkpoint_refused_before_close — walk one Book through every open phase.
PG="$TMP_ROOT/gate"; make_repo "$PG" "$GH_PROFILE"
set_meta_field "$PG" Summary 'Gated sprint'
export STUBLOG="$PG.log"; : > "$STUBLOG"
refuse_at() {  # <expected-phase>
  local got; got=$(phase_of "$PG")
  [ "$got" = "$1" ] || die test_checkpoint_refused_before_close "expected phase $1, got $got"
  if PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 bash "$RA" --root "$PG" open-pr >"$PG.out" 2>&1; then
    die test_checkpoint_refused_before_close "checkpoint opened during $1"
  fi
  grep -q "phase: $1" "$PG.out" ||
    die test_checkpoint_refused_before_close "diagnostic does not name phase $1: $(cat "$PG.out")"
  [ ! -s "$STUBLOG" ] || die test_checkpoint_refused_before_close "provider invoked during $1"
}
refuse_at research
printf '# Research\n' > "$PG/docs/sprints/s0/sprint-research/research-report.md"
refuse_at plan
printf 'Finalized - DO NOT EDIT\n\n# Build\n' > "$PG/docs/sprints/s0/sprint-plans/build-plan.md"
printf 'Finalized - DO NOT EDIT\n\n# Test\n' > "$PG/docs/sprints/s0/sprint-plans/test-plan.md"
refuse_at build
printf '# Completed\n## T-001 (sprint 0)\n' > "$PG/docs/work/completed-tasks.md"
refuse_at test
printf '# Test report\npass\n' > "$PG/docs/sprints/s0/sprint-tests/test-report.md"
printf '# Critique\n## Concerns\n- none\n## Confidence\nclean\n' > "$PG/docs/sprints/s0/sprint-tests/critique.md"
refuse_at loop
set_meta_field "$PG" 'Exit status' success
git -C "$PG" add -A; git -C "$PG" commit -qm closed
PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 bash "$RA" --root "$PG" open-pr >/dev/null 2>&1 ||
  die test_checkpoint_refused_before_close 'closed sprint was still refused'
[ "$(grep -c 'pr create' "$STUBLOG")" = 1 ] ||
  die test_checkpoint_refused_before_close 'closed sprint did not open exactly one request'
pass test_checkpoint_refused_before_close

# test_checkpoint_refuses_placeholder_summary
PP="$TMP_ROOT/placeholder"; make_repo "$PP" "$GH_PROFILE"; advance_to_loop "$PP"; set_meta_field "$PP" 'Exit status' success
export STUBLOG="$PP.log"; : > "$STUBLOG"
if PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 bash "$RA" --root "$PP" open-pr >"$PP.out" 2>&1; then
  die test_checkpoint_refuses_placeholder_summary 'placeholder Summary accepted'
fi
grep -qi 'summary' "$PP.out" || die test_checkpoint_refuses_placeholder_summary "diagnostic does not name the field: $(cat "$PP.out")"
[ ! -s "$STUBLOG" ] || die test_checkpoint_refuses_placeholder_summary 'provider was invoked'
pass test_checkpoint_refuses_placeholder_summary

# test_checkpoint_rejects_malformed_title / test_checkpoint_accepts_conforming_title
PT="$TMP_ROOT/title"; make_repo "$PT" "$GH_PROFILE"; make_closed_book "$PT" 'Title rules'
export STUBLOG="$PT.log"; : > "$STUBLOG"
if PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 \
   bash "$RA" --root "$PT" --title 'checkpoint' open-pr >"$PT.out" 2>&1; then
  die test_checkpoint_rejects_malformed_title 'malformed title accepted'
fi
grep -q 'Sprint <N>: <description>' "$PT.out" ||
  die test_checkpoint_rejects_malformed_title "no title-shape diagnostic: $(cat "$PT.out")"
[ ! -s "$STUBLOG" ] || die test_checkpoint_rejects_malformed_title 'provider was invoked'
pass test_checkpoint_rejects_malformed_title

PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 \
  bash "$RA" --root "$PT" --title 'Sprint 0: something else' open-pr >/dev/null 2>&1 ||
  die test_checkpoint_accepts_conforming_title 'conforming title refused'
grep -q 'title Sprint 0: something else' "$STUBLOG" ||
  die test_checkpoint_accepts_conforming_title "supplied title not passed through: $(cat "$STUBLOG")"
pass test_checkpoint_accepts_conforming_title

# test_checkpoint_gates_inert_below_contract_3 — an un-converged Book keeps the
# pre-sprint behavior exactly, including opening a checkpoint mid-sprint.
PI="$TMP_ROOT/inert"; make_repo "$PI" "$GH_PROFILE"
stamp_contract "$PI" 2
export STUBLOG="$PI.log"; : > "$STUBLOG"
[ "$(phase_of "$PI")" = research ] || die test_checkpoint_gates_inert_below_contract_3 'fixture is not mid-sprint'
PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 bash "$RA" --root "$PI" open-pr >/dev/null 2>&1 ||
  die test_checkpoint_gates_inert_below_contract_3 'contract-2 open-pr failed'
[ "$(grep -c 'pr create' "$STUBLOG")" = 1 ] ||
  die test_checkpoint_gates_inert_below_contract_3 'contract-2 Book was gated'
grep -q 'title Sprint checkpoint: dev -> main' "$STUBLOG" ||
  die test_checkpoint_gates_inert_below_contract_3 "contract-2 title changed: $(cat "$STUBLOG")"
pass test_checkpoint_gates_inert_below_contract_3

# test_forgejo_uses_fallback_checkpoint — gitea and forgejo are declarable
# today and take the push-and-compare fallback; the REST tier is later scope.
PFJ="$TMP_ROOT/forgejo"; make_repo "$PFJ" 'provider: forgejo
base: main
work: dev'
make_closed_book "$PFJ" 'Forgejo host'
export STUBLOG="$PFJ.log"; : > "$STUBLOG"
fj_out=$(PATH="$STUB_BIN:$PATH" STUB_PR_EXISTS=0 bash "$RA" --root "$PFJ" open-pr 2>&1) ||
  die test_forgejo_uses_fallback_checkpoint 'forgejo open-pr failed'
printf '%s' "$fj_out" | grep -qi 'manually' ||
  die test_forgejo_uses_fallback_checkpoint "no fallback message: $fj_out"
[ ! -s "$STUBLOG" ] || die test_forgejo_uses_fallback_checkpoint 'a provider CLI was invoked'
pass test_forgejo_uses_fallback_checkpoint

printf 'remote-adapter selftest: all fixtures passed\n'
