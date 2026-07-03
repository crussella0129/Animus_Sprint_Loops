# Plan Critique — Sprint 11

Critic: subagent (general-purpose) run with `prompts/plan-critic.md`. Verdict: `proceed-with-caveats`.
Primary-agent responses are inline under each concern as **Response:**.

## Concerns

### C-001: T-005's EARS clauses never verify T-005's own deliverable
- **Where:** `build-plan.md` T-005 success criterion / `test-plan.md` "T-005 unit tests (protocol edits)"
- **Quote:** "WHEN the schema/phase edits are applied, **THEN** `check-bundle-sync.sh` **SHALL** still exit 0 (parity preserved on mapped files)." — and the other two clauses ("check-merge-policy … still report all docs consistent", "current-phase.sh SHALL report the same phase as with an empty backlog").
- **Failure mode:** EARS-vague | plan-test-mismatch
- **Why it matters:** All three T-005 clauses are non-regression properties; a literal no-op satisfies every one. Nothing asserts the CI-confirmation block actually exists, the canonical-runner paragraph exists, or the `(backlog)` form is documented.
- **Suggested response:** fix-in-plan — add one positive-content EARS clause per edited artifact and matching `test_*` entries.
- **Response: fix-in-plan — APPLIED.** The protocol-edit tasks (now T-006/T-007 after the C-002 split) each carry positive-content EARS clauses (grep-testable presence of the CI-confirmation fields + no-CI fallback, the canonical-runner paragraph, the `(backlog)` documentation line, the loop-doc backlog-append sentence) with matching `test_*` entries in the test plan.

### C-002: T-005 bundles two unrelated concerns (Component B + Component C)
- **Failure mode:** granularity
- **Why it matters:** Four distinct doc changes spanning two components; the task is a seam, not one logical concern with one coherent diff.
- **Suggested response:** fix-in-plan — split into T-005a (Test-phase CI confirmations) and T-005b (`(backlog)` form).
- **Response: fix-in-plan — APPLIED.** Split into T-006 (Test-phase CI confirmations: test-report schema ×4 + 05 docs + open-harnesses particle 07 + antigravity workflow line) and T-007 (`(backlog)` form: agent-tasks schema ×4 + loop docs ×3). Full sequence renumbered T-001…T-008.

### C-003: Component B has no research provenance ("array-test-derived" appears from nowhere)
- **Failure mode:** missing-risk
- **Why it matters:** The plan grew from 4 to 6 tasks after research was written; run-guards.sh's normalization-brittleness risk (mktemp paths, shellcheck version variance, CRLF/locale local-vs-ubuntu) was never analyzed in §4; sprint-goal wording drifted; ROADMAP "array-test integration first (future)" reads as contradicting Component B shipping array-test-derived machinery now.
- **Suggested response:** fix-in-plan — record provenance + normalization risk; clarify "derived-concepts now, full integration later."
- **Response: fix-in-plan — APPLIED.** research-report.md gains `## 6. Plan-phase addendum` recording the user directive (review https://github.com/crussella0129/array-test during plan approval), the review evidence, an External Sources entry (1/5), and the normalization-brittleness risk with its mitigation (normalization rules + the `--determinism` double-run + `test_runner_nondeterminism_caught`). Build-plan Component B note now states: derived concepts this sprint; full engine integration is future work gated on array-test T1–T5.

### C-004: T-002 is four changes, one of them behavior-altering
- **Failure mode:** granularity
- **Why it matters:** The confidence floor is a behavior change hiding inside a "behavior identical" refactor; weakens the rollback story.
- **Suggested response:** at minimum pull the confidence-floor change into its own task.
- **Response: fix-in-plan — APPLIED.** Confidence floor extracted to T-003 (own task, own EARS, own commit). T-002 is now strictly behavior-preserving (DRY reuse + SC2010 + SC2034).

### C-005: Decisions Reviewed omits two ADRs that govern files T-005 edits
- **Failure mode:** ignored-ADR
- **Response: fix-in-plan — APPLIED.** Added relevance lines for the sprint-3 autonomy ADR (CI-verify pattern in 05, loop-phase content) and the sprint-4 EARS/plan-mode ADR (05's test derivation) to `## Decisions Reviewed`.

### C-006: T-005's routing test consumes T-006's artifact (inverted dependency)
- **Failure mode:** hidden-dep
- **Response: fix-in-plan — APPLIED.** `test_routing_backlog_safe` reworded to use a temp-fixture `agent-tasks.md` (same fixture pattern as the bundle-sync tests), independent of the real seeded backlog. (Critic independently verified the underlying non-collision claim against current-phase.sh's anchored greps.)

### C-007: Minor coverage gaps between EARS clauses and tests (bundle)
- **Failure mode:** plan-test-mismatch
- **Response: mixed — APPLIED as suggested.**
  - (a) fix-in-plan: added `test_sync_extra_caught` (extra file injected into a mirror's scripts/ set → guard fails).
  - (b) fix-in-plan for the static part: `test_yaml_parses` now also asserts the workflow writes to `$GITHUB_STEP_SUMMARY`. defer-with-rationale for the red-CI E2E: GitHub's non-zero-step→failed-run semantics are platform behavior, and the runner's failure path is covered by `test_runner_fail_recorded`; forcing a live red run would require pushing a deliberately broken commit to the shared repo.
  - (c) fix-in-plan: added `test_init_no_sprints` (init in bare temp dir → creates s0) and `test_finalize_no_sprints` (finalize in bare temp dir → non-zero "no sprints found") so every documented `-1` mapping has a test.

### C-008: Antigravity bundle silently misses T-005's phase-doc propagation
- **Failure mode:** missing-risk
- **Response: fix-in-plan — APPLIED.** `antigravity-ide/global_workflows/sprint-loops.md` added to T-006's Touches (one sentence pointing the Test phase at the canonical runner + CI confirmation). Residual antigravity parity work stays a ROADMAP item. Also noted: `antigravity-ide/skills/sprint-loop/phases/` is an EMPTY untracked local dir (not a missing propagation target); recorded here so the parity map's exclusion is explicit.

## Confidence

`proceed-with-caveats` — C-001 and C-003 addressed before lock (both APPLIED above); remaining items applied or explicitly deferred with rationale. Proceeding to finalize-plan.sh.
