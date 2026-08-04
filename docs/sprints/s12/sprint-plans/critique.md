# Plan Critique — Sprint 12

Critic: subagent (general-purpose) run with `prompts/plan-critic.md`. Verdict: `proceed-with-caveats`.
Primary-agent responses inline as **Response:**.

## Concerns

### C-001: Sprint-1 Abort-path ADR missing from Decisions Reviewed
- **Failure mode:** ignored-ADR
- **Why it matters:** T-001 rewrites abort-sprint.sh's two `sed -i` lines — the literal implementation of the sprint-1 abort ADR's contract; the gate exists to record exactly this overlap.
- **Response: fix-in-plan — APPLIED.** Added the abort-path ADR bullet to `## Decisions Reviewed` (behavior preserved; selftest step 09 + T-001's abort EARS clause are the guards).

### C-002: T-002's baseline-hash EARS clause is unsatisfiable as written
- **Failure mode:** plan-test-mismatch
- **Why it matters:** By execution order (T-001 → T-004 → T-002), selftest's output already changed ("all 15 transitions"), so its evidence hash cannot equal the s11 baseline; the unscoped clause could never pass while the test plan silently narrowed it.
- **Response: fix-in-plan — APPLIED.** Build-plan clause now scoped to "suites whose scripts are unchanged this sprint", matching `test_runner_baseline_hashes`.

### C-003: test_hash_fallback has no seam to reach the real hash_stdin — vacuous-test risk
- **Failure mode:** plan-test-mismatch (executability/vacuity)
- **Why it matters:** run-guards.sh isn't source-safe, so the test would either test a pasted copy (the sprint-11 meta-lesson's false-pass class) or need an impractical PATH shim on this host.
- **Response: fix-in-plan — APPLIED.** T-002 now specifies an explicit seam: `hash_stdin()` honors `RUN_GUARDS_HASH_TOOL=shasum|sha256sum` (default: auto-detect). `test_hash_fallback` invokes the real runner with the override on a stub suite and asserts the digest equals the sha256sum digest of the same normalized input. (Critic verified `shasum` exists locally at /usr/bin/core_perl/shasum, so the test is executable here.)

### C-004: Two factual inventory errors that will misdirect the builder
- **Failure mode:** EARS-vague (supporting-claim accuracy)
- **Response: fix-in-plan — APPLIED.** (1) "three call sites" corrected to the verified **two** (suite_script_hash, run_once). (2) "strictly tighter" corrected to "**exactly equivalent match set**" — the existing anchored BRE has no wildcards, so awk whole-line equality is equivalence, guarded by selftest steps 11 + 15; the equivalence claim is the accurate review-record statement.

## Verified-clean notes
Carried from the critic verbatim in spirit: sed -i inventory exact; grep -iv faithful incl. the `|| true` nuance; canonical-only grep sufficient via bundle-sync transitivity; normalize() ordering correct; s11 baseline committed + same-environment; "14 transitions" references elsewhere are historical artifacts; E2E plausible (push-trigger matrix + per-OS artifact names + fail-fast:false).

## Confidence
`proceed-with-caveats` — all four concerns applied in-plan before `finalize-plan.sh`.
