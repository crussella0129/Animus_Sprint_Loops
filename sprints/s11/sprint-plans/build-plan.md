Finalized - DO NOT EDIT

# Sprint 11 Build Plan

## Schema Tree
- Sprint Goal: refactor the sprint-loop skill; make its testing deterministic and GitHub-resident (array-test-derived concepts — see research §6); set the improvement trajectory
  - Component A: Cross-bundle integrity
    - T-001: bundle-parity guard + fixture test
    - T-002: behavior-preserving DRY + lint refactor (propagated ×4 bundles)
    - T-003: confidence floor at 0.0 (behavior change, own commit, ×4 bundles)
  - Component B: Deterministic GitHub-based testing
    - T-004: canonical guard runner with confirmations + determinism meta-check
    - T-005: GitHub Actions CI wired to the runner
    - T-006: Test-phase protocol — CI confirmations recorded in test-report
  - Component C: Trajectory
    - T-007: `(backlog)` carry-forward form in schema + loop docs
    - T-008: ROADMAP.md + backlog seeding

Component B ships *derived concepts* from array-test (canonical runner, evidence-hashed confirmations, determinism double-run, CI-as-authority); full engine integration (content-addressed cells, memoized frontier, Merkle-root gate) is future work gated on array-test T1–T5 — see research-report §6 and ROADMAP.

## Execution Sequence

### T-001: Add `tools/check-bundle-sync.sh` asserting byte-parity of shared assets across the four bundles, plus a fixture test proving it catches drift.
- **Touches:** tools/check-bundle-sync.sh (new), tools/check-bundle-sync.test.sh (new)
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** `check-bundle-sync.sh` runs on a tree whose mapped assets are byte-identical, **THEN** the guard **SHALL** exit 0 and print a one-line OK summary.
  - **WHEN** any mapped mirror file differs in content from its canonical counterpart, **THEN** the guard **SHALL** exit non-zero naming the divergent path.
  - **WHEN** a mapped file is missing from a mirror, or a mirror's scripts/schemas set contains a file absent from the canonical set, **THEN** the guard **SHALL** exit non-zero naming the offending path.
  - **WHEN** `check-bundle-sync.test.sh` runs, **THEN** it **SHALL** build temp-tree fixtures covering injected content drift, a deleted mirror file, and an extra mirror file, assert the guard fails on each, assert the guard passes on a clean copy, and exit 0 only if all cases behave.
- **Notes:** Parity map (measured): `scripts/*` (9) + `schemas/*` (9) identical across claude-code/codex-cli/antigravity-ide/open-harnesses; `prompts/*` (2) across claude-code/codex-cli/open-harnesses; `phases/00,01,02,04,05` claude↔codex. Excluded by design (documented in header): phases/03 + 06 (harness-specific), SKILL.md, READMEs, installers, AGENTS.md.fragment, open-harnesses particles, antigravity global_workflows (condensed rewrites), and antigravity's empty untracked `phases/` dir. Conventions of `tools/check-merge-policy.sh`/`.test.sh` (ROOT resolution, named failures, temp-dir traps); root overridable so fixtures never touch the real tree.

### T-002: Behavior-preserving refactor — scripts reuse `current-sprint.sh`, `ls | grep` removed (SC2010), SC2034 fixed; propagated byte-identically to all four bundles.
- **Touches:** {claude-code/skills/sprint-loop,codex-cli/skills/sprint-loops,antigravity-ide/skills/sprint-loop,open-harnesses}/scripts/{current-sprint.sh,init-sprint.sh,finalize-plan.sh,research-budget.sh}, tools/check-merge-policy.test.sh
- **Depends on:** T-001 (guard exists to verify propagation)
- **Success criterion (EARS):**
  - **WHEN** `selftest.sh` runs after the refactor, **THEN** all 14 transitions **SHALL** pass.
  - **WHEN** `current-sprint.sh` runs in this repo, **THEN** it **SHALL** print `11`; **WHEN** it runs where `sprints/` is absent or has no `sN` dirs, **THEN** it **SHALL** print `-1`.
  - **WHEN** `init-sprint.sh` runs in a bare temp dir, **THEN** it **SHALL** create `sprints/s0`; **WHEN** `finalize-plan.sh` runs in a bare temp dir, **THEN** it **SHALL** exit non-zero with "no sprints found"; **WHEN** `research-budget.sh` runs in a bare temp dir, **THEN** it **SHALL** print `files=0 sources=0` and exit 0.
  - **WHEN** `shellcheck -S warning` runs over the canonical scripts and tools/*.sh, **THEN** it **SHALL** report zero findings.
  - **WHEN** `check-bundle-sync.sh` runs after propagation, **THEN** it **SHALL** exit 0.
- **Notes:** Strictly behavior-preserving. init-sprint.sh gains SCRIPT_DIR resolution (same idiom as siblings); `-1` maps to each caller's existing empty-case path.

### T-003: Clamp `update-confidence.sh` at a 0.0 floor; propagate ×4.
- **Touches:** {4 bundles}/scripts/update-confidence.sh
- **Depends on:** T-002 (lands on the refactored file set)
- **Success criterion (EARS):**
  - **WHEN** `update-confidence.sh failed` runs with confidence.txt at 0.2, **THEN** confidence.txt **SHALL** read 0.0.
  - **WHEN** `update-confidence.sh pass` runs with confidence.txt at 0.9, **THEN** confidence.txt **SHALL** read 1.0 (existing cap unchanged).
- **Notes:** Deliberate behavior change (own commit): a negative confidence is meaningless for the ≤5-task throttle check; floor mirrors the existing 1.0 cap.

### T-004: Add `tools/run-guards.sh` — single canonical suite runner emitting ndjson confirmations with normalized evidence hashes and a `--determinism` double-run mode.
- **Touches:** tools/run-guards.sh (new)
- **Depends on:** T-001, T-002 (suite includes bundle-sync; scripts lint-clean)
- **Success criterion (EARS):**
  - **WHEN** `run-guards.sh` runs and every suite passes, **THEN** it **SHALL** exit 0 and write exactly one ndjson line per suite containing suite name, 64-hex script_hash and evidence_hash, status PASS, duration, and UTC timestamp.
  - **WHEN** any suite fails, **THEN** the runner **SHALL** record `"status":"FAIL"` for that suite, continue the remaining suites, and exit non-zero.
  - **WHEN** `--determinism` is set, **THEN** each suite **SHALL** run twice and the runner **SHALL** exit non-zero naming any suite whose two normalized evidence hashes differ.
  - **WHEN** suite output contains temp paths, timestamps, or CR line endings, **THEN** normalization **SHALL** strip them such that two identical passing runs in the same environment yield equal evidence hashes.
- **Notes:** Suite list (in order): selftest, merge-policy guard, merge-policy fixture test, plugin-manifest, bundle-sync guard, bundle-sync fixture test, shellcheck (`-S warning`, canonical scripts + tools). `--out <path>` (default ./guards-report.ndjson). sha256 via `sha256sum`. Evidence hashes compare within one environment only (research §6 risk note). Nondeterminism detection exercised via a stub suite in the Test phase.

### T-005: Add `.github/workflows/ci.yml` running the canonical runner with determinism check on every push and PR to main.
- **Touches:** .github/workflows/ci.yml (new)
- **Depends on:** T-004
- **Success criterion (EARS):**
  - **WHEN** the workflow file is parsed as YAML, **THEN** parsing **SHALL** succeed with `on.push` (all branches) and `on.pull_request` (base main) triggers, a `tools/run-guards.sh --determinism` invocation, and a step writing to `$GITHUB_STEP_SUMMARY`.
  - **WHEN** a commit is pushed to any branch, **THEN** CI **SHALL** run the guard suite and upload guards-report.ndjson as an artifact (also on failure).
  - **WHEN** any guard suite fails or is nondeterministic in CI, **THEN** the workflow run conclusion **SHALL** be failure.
- **Notes:** ubuntu-latest; actions/checkout@v4 + actions/upload-artifact@v4 with `if: always()`. Red-CI E2E deliberately not exercised live (deferred with rationale — critique C-007b); green-path conclusion verified E2E in the Test phase.

### T-006: Test-phase protocol — record CI confirmations in test-report; point the Test phase at the canonical runner.
- **Touches:** schemas/test-report.md (×4 bundles), phases/05-test-phase.md (claude + codex, identical edit), open-harnesses/particles/07-test-phase.md, antigravity-ide/global_workflows/sprint-loops.md (one sentence)
- **Depends on:** T-004 (references the runner), T-001 (05-test-phase and test-report schema are parity-mapped)
- **Success criterion (EARS):**
  - **WHEN** `schemas/test-report.md` is read after the edit, **THEN** it **SHALL** contain a CI-confirmation block with head SHA, run ID/URL, and conclusion fields, plus a "CI not configured — local confirmations only" fallback line.
  - **WHEN** `phases/05-test-phase.md` is read after the edit, **THEN** it **SHALL** contain a paragraph directing the Test phase to invoke the project's canonical runner (where one exists) and record its confirmations, with CI conclusion on the head SHA as authoritative.
  - **WHEN** the edits are applied, **THEN** `check-bundle-sync.sh` **SHALL** exit 0 (claude↔codex 05 stays identical; schema ×4 parity holds).
- **Notes:** Extends (does not replace) the sprint-3 ADR's CI-verify pattern in 05. Antigravity gets one pointer sentence in its workflow file (residual parity is a ROADMAP item — critique C-008).

### T-007: Document the `(backlog)` carry-forward entry form in the agent-tasks schema and loop docs.
- **Touches:** schemas/agent-tasks.md (×4 bundles), phases/06-loop-phase.md (claude + codex, per-copy edit), open-harnesses/particles/08-loop-phase.md
- **Depends on:** T-001 (agent-tasks schema is parity-mapped)
- **Success criterion (EARS):**
  - **WHEN** `schemas/agent-tasks.md` is read after the edit, **THEN** it **SHALL** document the `- [ ] T-1xx (backlog): … — touches: …` form (sprint-unassigned carry-forward, promoted to `(sprint N)` when queued by a Build phase).
  - **WHEN** each loop doc is read after the edit, **THEN** it **SHALL** contain a sentence appending flagged follow-ups to the backlog as `(backlog)` entries.
  - **WHEN** a fixture `agent-tasks.md` contains only `(backlog)` entries, **THEN** `current-phase.sh` **SHALL** report the same phase as with an empty backlog (no routing collision).
  - **WHEN** `check-merge-policy.sh` and `check-bundle-sync.sh` run after the edits, **THEN** both **SHALL** still pass.
- **Notes:** Routing safety pre-verified against current-phase.sh's anchored `\(sprint $N\)` greps (critique C-006 confirmed independently); test uses a temp fixture, not the real backlog.

### T-008: Add ROADMAP.md (prioritized future-sprint trajectory) and seed the persistent backlog with `(backlog)` entries.
- **Touches:** ROADMAP.md (new), agent-tasks/agent-tasks.md
- **Depends on:** T-007 (`(backlog)` form documented before use)
- **Success criterion (EARS):**
  - **WHEN** ROADMAP.md is read, **THEN** it **SHALL** list the prioritized future-sprint candidates (array-test engine integration; macOS/BSD portability + CI matrix leg; critique.md hard-gate; plugin versioning + `/plugin update` reload; abort no-git fallback; antigravity parity; launch-time E2E harness; confidence surfacing) each with a rationale, plus the explicit deferral rationale for Merkle-root/memoization.
  - **WHEN** the backlog is read after seeding, **THEN** every seeded entry **SHALL** match the documented `- [ ] T-1xx (backlog): … — touches: …` form.
- **Notes:** ROADMAP links array-test (https://github.com/crussella0129/array-test) and names its engine tasks (T1–T5) as the integration precondition.
