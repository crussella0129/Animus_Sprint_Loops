Finalized - DO NOT EDIT

# Sprint 12 Build Plan

## Schema Tree
- Sprint Goal: macOS/BSD portability for all skill scripts + a macos-latest CI leg as the permanent regression net (backlog T-102)
  - Component A: Portable scripts
    - T-001: replace all GNU-only in-place edits (sed -i, 0,/ range, I flag)
    - T-004: selftest step 15 — first-match-only back-fill guard
  - Component B: Portable runner
    - T-002: hash_stdin() fallback + broadened normalize() in run-guards.sh
  - Component C: Observability
    - T-003: CI os-matrix (ubuntu + macos) with per-OS artifacts

Execution order: T-001 → T-004 (guard the rewrite immediately) → T-002 → T-003 (E2E last).

## Execution Sequence

### T-001: Replace all GNU-only in-place edit constructs with portable equivalents; propagate ×4 bundles.
- **Touches:** {4 bundles}/scripts/{abort-sprint.sh,commit-task.sh,selftest.sh}, tools/check-merge-policy.test.sh
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** `grep -rn "sed -i" claude-code/skills/sprint-loop/scripts tools` runs after the change, **THEN** it **SHALL** return zero matches.
  - **WHEN** `selftest.sh` runs, **THEN** all 14 transitions **SHALL** pass (abort step 09 and back-fill step 11 included).
  - **WHEN** `abort-sprint.sh "<reason>"` runs in a temp git project, **THEN** sprint-meta.md **SHALL** show Exit status `aborted`, the real end timestamp, and the abort note (same behavior as before, no GNU sed).
  - **WHEN** `commit-task.sh` runs against a completed-tasks.md containing an anchored PENDING placeholder, **THEN** it **SHALL** back-fill it with the backticked short hash and amend into the same commit (sprint-1/3 ADR contract preserved).
  - **WHEN** `check-merge-policy.test.sh` runs, **THEN** it **SHALL** report 4/4 caught (case-insensitive green-line deletion preserved via `grep -iv`).
- **Notes:** tmp+mv pattern per finalize-plan.sh precedent. commit-task.sh uses `awk -v h="$HASH"` with whole-line equality (`$0 == "- **Commit:** PENDING"`) + `done` flag — an exactly equivalent match set to the anchored no-wildcard regex it replaces (plan-critique C-004), guarded by selftest steps 11 + 15. `grep -iv` exits 1 when everything matches; guard with `|| true` on the pipeline into tmp.

### T-004: Selftest step 15 — double-PENDING fixture proving first-match-only back-fill; propagate ×4.
- **Touches:** {4 bundles}/scripts/selftest.sh
- **Depends on:** T-001 (guards the awk rewrite)
- **Success criterion (EARS):**
  - **WHEN** `selftest.sh` runs, **THEN** it **SHALL** report "all 15 transitions matched", with step 15 asserting: first anchored PENDING → backticked hash, second anchored PENDING → untouched, prose `Commit:** PENDING` mention → untouched.
  - **WHEN** the back-fill is (hypothetically) changed to fill more than the first placeholder, **THEN** step 15 **SHALL** fail.
- **Notes:** Extends the step-11 fixture family; runs inside the selftest temp repo (git identity already configured there).

### T-002: Portable hashing + broadened temp-path normalization in the canonical runner.
- **Touches:** tools/run-guards.sh
- **Depends on:** T-001 (suite scripts already portable when the runner re-hashes them)
- **Success criterion (EARS):**
  - **WHEN** `run-guards.sh` runs on a host with `sha256sum` (git-bash/ubuntu), **THEN** evidence hashes for suites whose scripts are unchanged this sprint **SHALL** equal the sprint-11 committed baseline (normalization additions are no-ops on current output; suites changed this sprint re-baseline and must be internally deterministic).
  - **WHEN** `run-guards.sh` runs on a host with only `shasum` (stock macOS), **THEN** hashing **SHALL** transparently use `shasum -a 256` with identical output format (64-hex).
  - **WHEN** a stub suite emits `/var/folders/ab/xyz/T/tmp.QQQ` or `/private/var/folders/...` paths that vary per run under `--determinism`, **THEN** normalization **SHALL** strip them and the suite **SHALL** report `"determinism":"ok"`.
  - **WHEN** `shellcheck -S warning tools/run-guards.sh` runs, **THEN** it **SHALL** report zero findings.
- **Notes:** `hash_stdin()` helper replaces the two inline `sha256sum | cut` sites (suite_script_hash, run_once — verified inventory, plan-critique C-004); it honors `RUN_GUARDS_HASH_TOOL=shasum|sha256sum` as an explicit test seam (default auto-detect) so `test_hash_fallback` exercises the REAL function, not a copy (plan-critique C-003). normalize() gains the two `/var/folders` rules ordered before the `/tmp/tmp.` rule (private-prefixed first).

### T-003: CI os-matrix — ubuntu-latest + macos-latest, per-OS artifacts, shellcheck-if-missing.
- **Touches:** .github/workflows/ci.yml
- **Depends on:** T-002 (runner must be portable before the macos leg exists)
- **Success criterion (EARS):**
  - **WHEN** the workflow YAML is parsed, **THEN** it **SHALL** contain `strategy.matrix.os == [ubuntu-latest, macos-latest]` with `fail-fast: false`, `runs-on: ${{ matrix.os }}`, artifact name `guards-report-${{ matrix.os }}`, a shellcheck install-if-missing step, and the unchanged `run-guards.sh --determinism` invocation.
  - **WHEN** a commit is pushed to the sprint branch, **THEN** BOTH matrix jobs **SHALL** run the canonical runner and conclude success (the E2E portability proof).
- **Notes:** `fail-fast: false` so a macos failure doesn't cancel the ubuntu evidence (and vice versa). Install step: `if ! command -v shellcheck >/dev/null; then brew install shellcheck; fi` (brew implies macOS path; on ubuntu shellcheck is preinstalled so the conditional no-ops).
