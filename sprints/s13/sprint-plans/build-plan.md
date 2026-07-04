Finalized - DO NOT EDIT

# Sprint 13 Build Plan

## Schema Tree
- Sprint Goal: structurally enforce the critic protocol — plan critique gates the lock; test critique gates the pass-path routing (backlog T-103, executing the sprint-5 ADR's deferral)
  - Component A: Lock-time enforcement
    - T-001: fourth gate in finalize-plan.sh (valid plan critique)
  - Component B: State-machine enforcement
    - T-002: test→loop pass path requires sprint-tests/critique.md + selftest coverage
  - Component C: Documentation
    - T-003: gate lines in phases 03/05, oh particles 03/07, ROADMAP §6 antigravity note

Execution order: T-001 → T-002 → T-003.

## Execution Sequence

### T-001: Fourth gate in finalize-plan.sh — refuse to lock without a valid plan critique — plus the selftest changes the gate itself demands; propagate ×4.
- **Touches:** {4 bundles}/scripts/finalize-plan.sh, {4 bundles}/scripts/selftest.sh (valid-critique fixtures on every success-path finalize call; new steps 16 refuse-missing + 17 refuse-block)
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** `finalize-plan.sh` runs and `sprints/sN/sprint-plans/critique.md` is missing or empty, **THEN** it **SHALL** refuse with a message directing the agent to the phases/03 critic protocol, leaving plans unlocked.
  - **WHEN** the critique's `## Confidence` first non-empty line starts with `block` (backticked or bare), **THEN** it **SHALL** refuse ("fix and re-critique").
  - **WHEN** the critique lacks a `## Concerns` heading or lacks a recognizable verdict line, **THEN** it **SHALL** refuse as malformed.
  - **WHEN** the verdict line starts with `clean` or `proceed-with-caveats` (backticked or bare) and a `## Concerns` heading exists, **THEN** the gate **SHALL** pass and the existing three gates **SHALL** behave exactly as before.
  - **WHEN** prose elsewhere in the critique contains the word "block" (e.g. "unblocked", quoting the rubric), **THEN** the gate **SHALL NOT** false-refuse (verdict parsing is scoped to the first non-empty line after `^## Confidence`).
- **Notes:** Gate ordered LAST (after empty-plan, decisions-reviewed, budget) so selftest steps 10/12/13 keep isolating their own gates. POSIX-portable awk/grep only. Verdict regex: `^\`?(clean|proceed-with-caveats)\`?([^a-z-]|$)` on the extracted line; `block` handled the same way for the refuse case. The malformed-refusal message SHALL state the expected shape (first non-empty line after `## Confidence` starts with `clean`, `proceed-with-caveats`, or `block`, optionally backticked) — critique C-003. Selftest fixtures ride in THIS task because the gate makes the old success paths red — a gate and the tests it mandates are one change (critique C-001; sprint-0 ADR coupling).

### T-002: Test→loop pass path requires the test critique; selftest updated in the same change; propagate ×4.
- **Touches:** {4 bundles}/scripts/current-phase.sh, {4 bundles}/scripts/selftest.sh
- **Depends on:** T-001 (selftest's success-path finalize fixtures need the plan-critique fixture the T-001 gate demands)
- **Success criterion (EARS):**
  - **WHEN** `test-report.md` is non-empty but `sprint-tests/critique.md` is absent/empty, **THEN** `current-phase.sh` **SHALL** report `test` (pass path stays in Test until the critic has run).
  - **WHEN** both `test-report.md` and `sprint-tests/critique.md` are non-empty, **THEN** it **SHALL** report `loop`.
  - **WHEN** `failure-report.md` is non-empty (failure path), **THEN** routing **SHALL** report `loop` with no critique requirement (exemption preserved).
  - **WHEN** `selftest.sh` runs, **THEN** it **SHALL** report "all 17 transitions matched" (15 existing + 16 refuse-missing + 17 refuse-block from T-001; step 07 becomes a two-stage walk whose first stage asserts report-without-critique → `test`).
- **Notes:** Routing check is existence-only (derive-only state machine); content validation is T-001's lock-time job. The sprint-1 abort short-circuit at the top of current-phase.sh precedes the edited line and is untouched — selftest step 09 remains its guard (critique C-002).

### T-003: Document both gates where agents read; note the antigravity non-binding surface.
- **Touches:** claude-code phases/03-plan-phase.md, codex-cli phases/03-plan-phase.md (per-copy — intentionally divergent files), phases/05-test-phase.md (claude=codex parity edit), open-harnesses/particles/03-plan-phase.md, open-harnesses/particles/07-test-phase.md, ROADMAP.md (§6)
- **Depends on:** T-001, T-002 (documents shipped behavior, not intent)
- **Success criterion (EARS):**
  - **WHEN** each edited doc is read, **THEN** it **SHALL** state the respective gate: 03 — finalize-plan.sh refuses without a valid critique.md (verdict `clean`/`proceed-with-caveats`); 05/07 — the state machine will not leave Test on the pass path until `sprint-tests/critique.md` exists.
  - **WHEN** `check-bundle-sync.sh` and `check-merge-policy.sh` run after the edits, **THEN** both **SHALL** pass (05 stays claude↔codex identical; loop-doc signals untouched).
  - **WHEN** ROADMAP §6 is read, **THEN** it **SHALL** note antigravity's manual-header flow bypasses the plan gate (T-106 input).
- **Notes:** One or two sentences per doc; no schema changes.
