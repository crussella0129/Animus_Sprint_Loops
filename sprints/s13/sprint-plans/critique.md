# Plan Critique — Sprint 13

**Mode: self-critique fallback.** The Agent tool (subagent spawning) was temporarily unavailable at critique time (three attempts, harness classifier outage); per phases/03 — "If your harness can't spawn subagents, self-critique against prompts/plan-critic.md's failure-mode list in a single message" — this critique was produced by the primary agent against the full failure-mode screen. Responses inline as **Response:**.

## Concerns

### C-001: T-001/T-002 sequencing breaks the per-task commit gate
- **Where:** `build-plan.md` T-001 Touches (finalize-plan.sh only) vs T-002 Touches (selftest.sh); selftest.sh line 39 (step 04's success-path finalize call).
- **Quote:** T-001: "Touches: {4 bundles}/scripts/finalize-plan.sh" — while selftest fixture updates sit in T-002.
- **Failure mode:** hidden-dep
- **Why it matters:** The moment T-001's gate lands, the existing selftest fails at step 04 (success-path finalize with NO critique fixture) — so T-001's own pre-flight sanity gate blocks its commit until T-002 lands. The plan's task boundary makes T-001 uncommittable in isolation.
- **Response: fix-in-plan — APPLIED.** T-001 now also carries the selftest changes the gate itself demands: valid-critique fixtures on every success-path finalize call PLUS the new finalize-gate selftest steps (refuse-missing, refuse-block, accept-valid). T-002 keeps the routing change and its routing-specific selftest steps. Both remain single-concern ("a gate and the tests that gate mandates" — same-change coupling the sprint-0 ADR requires).

### C-002: Sprint-1 abort ADR governs the same file the routing change edits
- **Where:** `research-report.md` Decisions Reviewed vs decisions.md "2026-05-20 — Abort path … hoisted Exit-status check in current-phase.sh (sprint 1)".
- **Failure mode:** ignored-ADR
- **Why it matters:** T-002 edits current-phase.sh; the sprint-1 ADR's hoisted abort short-circuit lives at the top of that file and must stay ahead of the new critique condition. Behavior is preserved (the edit is on the test→loop line only), but the gate exists to record the overlap.
- **Response: fix-in-plan — APPLIED.** Bullet added to Decisions Reviewed; T-002 notes now state the abort short-circuit precedes and is untouched (selftest step 09 remains the guard).

### C-003: Malformed-verdict refusal should say what "valid" looks like
- **Where:** `build-plan.md` T-001, refuse-malformed clause.
- **Failure mode:** EARS-vague (message quality)
- **Why it matters:** An agent hitting the malformed branch (e.g. it pasted the rubric's "One of:" list, or bolded the verdict) needs the fix in the error text, not just "malformed" — especially for downstream projects mid-upgrade.
- **Response: fix-in-plan — APPLIED.** T-001 notes now require the refusal message to state the expected shape: first non-empty line after `## Confidence` must START with `clean`, `proceed-with-caveats`, or `block` (optionally backticked).

### C-004: Selftest transition count left as "all N"
- **Where:** `build-plan.md` T-002 / `test-plan.md` `test_selftest_all_n`.
- **Failure mode:** EARS-vague (minor)
- **Why it matters:** "All N transitions" isn't a measurable response until N is pinned; the count is knowable at plan time.
- **Response: fix-in-plan — APPLIED.** Pinned: 15 existing + step 16 (finalize refuses missing critique) + step 17 (finalize refuses block verdict) + step 07's new negative stage (report-without-critique → `test`, folded into step 07's walk as an extra assert, not a new numbered step) = **"all 17 transitions matched"**; accept-valid is proven by every success-path lock.

## Screen results on the remaining failure modes
Plan-test tracing is 1:1 (each refuse/accept clause has a named test; both negative arms recorded); research risks all carry into tasks (gate ordering → test_gate_ordering; verdict edges → no_prose_false_match + malformed; routing regression → selftest + negative arm; antigravity non-binding → T-003/ROADMAP); granularity acceptable post-C-001 (same-change coupling is ADR-mandated); E2E plausible (matrix precedent from s12; s14 recorded as the first mechanically-gated sprint).

## Confidence

`proceed-with-caveats` — C-001 was the load-bearing catch (uncommittable task boundary); all four concerns APPLIED to the plans before lock. Note for the record: the Test-phase critic should return to a true subagent if the harness has recovered by then.
