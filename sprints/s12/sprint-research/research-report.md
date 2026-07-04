# Sprint 12 Research Report

## Decisions Reviewed

- **2026-05-20 commit-task.sh back-fill via PENDING token** (sprint 1) — relevance: the portable rewrite of the back-fill must preserve the contract exactly: first-match-only, fold-into-same-commit via amend, no-op when no placeholder. No revision proposed.
- **2026-05-20 abort path: abort-sprint.sh + hoisted Exit-status check** (sprint 1) — relevance: T-001 rewrites abort-sprint.sh's two `sed -i` lines, which ARE this ADR's implementation (Exit-status flip, end-timestamp fill, abort note). Behavior preserved verbatim; selftest step 09 guards the transition. (Added per plan-critique C-001.)
- **2026-05-20 line-anchored back-fill regex** (sprint 3) — relevance: the GNU `0,/…/` sed range being replaced IS this ADR's implementation. The replacement (awk exact-line match) must be at least as anchored — whole-line equality is strictly tighter than the current regex. Selftest step 11 is the guard and must stay green.
- **2026-05-19 selftest guards every transition** (sprint 0) — relevance: selftest.sh itself contains two `sed -i` calls being made portable; the 14 transitions must still pass byte-for-byte in behavior.
- **2026-05-20 bundle atomicity / install.sh per bundle** (sprint 2) — relevance: script fixes propagate ×4 bundles; sprint-11's bundle-sync guard enforces this mechanically now.
- **2026-07-03 parity guard + canonical runner + CI confirmations** (sprint 11) — relevance: this sprint executes that ADR's declared follow-up (T-102, including the normalize() broadening annotated from test-critique C-004); new CI matrix legs must keep running the canonical runner unchanged; any suite behavior change surfaces as evidence-hash drift, which is expected and fine (hashes compare within one environment only, per the recorded semantics).
- **2026-05-21 stop criterion / merge-on-green** (sprint 8) — relevance: authorizes the Loop-phase merge on green CI; unchanged.

No prior decision is being violated; sprint 3's back-fill ADR gets a strictly-tighter reimplementation, explicitly acknowledged here.

## 1. Sprint Goal

Backlog T-102: make the skill's scripts portable to macOS/BSD userland (no GNU-only sed/hash constructs), broaden the runner's output normalization so macOS temp paths don't break determinism hashing, and add a `macos-latest` leg to the CI matrix so portability is continuously *observed*, not assumed. One PR, merged on green CI (both legs).

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| claude-code/skills/sprint-loop/scripts/abort-sprint.sh | high | 2× `sed -i` (BSD requires `-i ''`) — lines 36–37 |
| claude-code/skills/sprint-loop/scripts/commit-task.sh | high | `sed -i "0,/…/{…}"` — BOTH GNU-isms in one line (in-place + first-match range) |
| claude-code/skills/sprint-loop/scripts/selftest.sh | high | 2× `sed -i` (steps 06, 08); also the regression net for every fix here |
| tools/check-merge-policy.test.sh | high | `sed -i '/green/Id'` — GNU `I` (case-insensitive) flag + in-place |
| tools/run-guards.sh | high | `sha256sum` (stock macOS ships `shasum -a 256` instead); normalize() strips only `/tmp/tmp.*` — macOS mktemp yields `/var/folders/…/T/tmp.*` |
| .github/workflows/ci.yml | high | Single ubuntu-latest job → needs os matrix; shellcheck presence on macos runners unverified |
| claude-code/skills/sprint-loop/scripts/finalize-plan.sh | med | Precedent: already uses the portable `> tmp && mv` write pattern the sed -i sites will adopt |
| scripts/{current-sprint,init-sprint,research-budget,update-confidence}.sh | med | Audited clean — POSIX-portable after sprint 11's refactor |
| tools/check-bundle-sync.sh + .test.sh | med | Audited clean (cmp/cp/mktemp portable); enforces ×4 propagation of the fixes |
| tools/check-plugin-manifest.sh | low | python3-based; macos runners ship python3 |

Construct sweep (repo-wide greps, not per-file reads): no `mapfile`/`readarray`/`declare -A`/`${var^^}`/`&>`/`grep -P`/`date -d`/`readlink -f` anywhere — the only bash-version-sensitive construct is `${h1:0:12}` (valid in bash 3.2, macOS's /bin/bash). Full GNU-ism inventory = the 6 `sed -i` sites, 1 `0,/` range, 1 `I` flag, `sha256sum`, and the normalize() pattern.

## 3. External Sources

None consulted (0/5). The macos-runner unknowns (shellcheck preinstalled? default bash version?) are cheaper to neutralize by construction (conditional `brew install shellcheck` step; target bash-3.2 syntax, already satisfied) than to research — and the new CI leg itself is the authoritative verification.

## 4. Risks, Unknowns, Dependencies

- **Risk:** the back-fill rewrite touches the sprint-1/3 ADR contract (one commit per task, line-anchored, first-match-only). Mitigation: awk whole-line equality match (tighter than the regex), selftest step 11 must pass, plus a temp-dir double-PENDING check that only the FIRST placeholder is filled.
- **Risk:** evidence hashes in guards-report.ndjson change for suites whose scripts change (script_hash) — expected; determinism compares within a run pair, and cross-environment comparison was never promised (sprint-11 ADR).
- **Unknown (neutralized by construction):** shellcheck on macos-latest — the workflow gains an install-if-missing step, so presence is guaranteed either way.
- **Unknown (accepted):** macOS `/bin/bash` is 3.2; audit found no post-3.2 constructs. The macos CI leg is the proof; if it exposes one, the fix is in-sprint.
- **Dependency:** none external — I cannot run macOS locally (Windows host), so the macos leg IS the test environment. This is precisely why T-102 bundles the matrix leg with the fixes.

## 5. Recommended Approach

Primary, 4 elementary tasks:

1. **Portable in-place edits:** replace all 6 `sed -i` sites with the `sed 'expr' file > file.tmp && mv file.tmp file` pattern already used by finalize-plan.sh (for check-merge-policy.test.sh's case-insensitive delete: `grep -iv green` to tmp + mv). commit-task.sh's `0,/` range becomes `awk -v h="$HASH"` whole-line-equality first-match replacement. Propagate script changes ×4 bundles.
2. **Portable hashing + normalization in run-guards.sh:** `hash_stdin()` helper — `sha256sum` when present, else `shasum -a 256`; normalize() gains a `/var/folders/...` (and generic `${TMPDIR}`-shaped) substitution alongside `/tmp/tmp.*`.
3. **CI matrix:** `strategy.matrix.os: [ubuntu-latest, macos-latest]`, `runs-on: ${{ matrix.os }}`, artifact names suffixed per-OS (upload-artifact@v4 forbids duplicate names), plus an install-shellcheck-if-missing step (brew on macOS).
4. **Selftest hardening for the back-fill edge:** extend selftest step 11's fixture (or add a step 15) asserting the double-PENDING first-match-only behavior the awk rewrite must preserve.

Alternative considered: `perl -pi -e` for in-place edits (perl is universal incl. macOS). Rejected: introduces a second language dependency into scripts that are otherwise pure sh-toolchain, and the tmp+mv pattern is already the repo's precedent (finalize-plan.sh).

Alternative considered: GNU-ify the runners instead (brew install gnu-sed/coreutils and prepend PATH on macOS). Rejected: fixes CI while leaving real macOS users broken — the point of T-102 is the scripts working on stock BSD userland, not making CI lie about it.

Rationale: smallest diff that makes every script BSD-clean, with the macos CI leg as a permanent, self-verifying regression net — and zero contract changes to the back-fill/abort semantics ADRs.

## Artifacts

None saved — grep inventories reproduced in section 2; the construct sweep commands are one-liners recorded in the sprint transcript.
