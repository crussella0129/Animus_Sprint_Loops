# Sprint 13 Research Report

## Decisions Reviewed

- **2026-05-20 subagent critic review at Plan + Test phases** (sprint 5) — relevance: THIS sprint implements that ADR's explicitly deferred alternative: "Hard gate via finalize-plan.sh requiring critique.md. Deferred to sprint 6+ once the pattern has been exercised manually." The pattern has now been exercised in sprints 6, 7, 8, 11, and 12, catching real defects each time. Not a revision — a scheduled completion.
- **2026-05-19 current-phase.sh disambiguator; selftest guards every transition** (sprint 0) — relevance: the test-phase analogue changes `current-phase.sh` routing (test → loop now additionally requires the test critique on the pass path), which per this ADR REQUIRES a selftest update in the same change. Honored: selftest gains gate steps and existing steps gain critique fixtures.
- **2026-05-20 finalize-plan.sh rejects empty build-plans** (sprint 2) + **2026-05-21 research budget gate** (sprint 6) + **2026-05-20 decisions-reviewed gate** (sprint 4) — relevance: finalize-plan.sh becomes a FOUR-gate lock. The new critique gate runs LAST so the existing selftest refusal steps (10, 12, 13) keep exercising their own gates rather than refusing early for the wrong reason.
- **2026-07-03 canonical runner / CI confirmations** (sprint 11) — relevance: no new suite is added; selftest (already registered in run-guards.sh) carries the new steps, so CI coverage is automatic. Selftest's evidence hash will re-baseline (output grows) — the documented, expected class.
- **2026-07-04 BSD/macOS portability** (sprint 12) — relevance: all new script code must stay POSIX-portable (no `sed -i`, no GNU-only flags); the macos CI leg enforces this on push.
- **2026-05-20 abort path + hoisted Exit-status check** (sprint 1) — relevance: the routing edit touches current-phase.sh, whose top-of-file abort short-circuit is this ADR's mechanism; the edit is confined to the test→loop line, the short-circuit stays first, selftest step 09 guards it. (Added per plan-critique C-002.)

No prior decision is violated; sprint 5's deferral is being executed as designed.

## 1. Sprint Goal

Backlog T-103: make the critic protocol *structurally* enforced instead of instruction-enforced — `finalize-plan.sh` refuses to lock plans without a valid plan critique, and the Test phase cannot route to Loop on the pass path without a test critique on disk.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| claude-code/skills/sprint-loop/scripts/finalize-plan.sh | high | Three existing composable gates (empty-plan, decisions-reviewed, budget); critique gate becomes the fourth, ordered last |
| claude-code/skills/sprint-loop/scripts/current-phase.sh | high | Line 26: test → loop when test-report or failure-report non-empty; pass path gains `sprint-tests/critique.md` requirement (failure path exempt — failure-report skips the critic by design) |
| claude-code/skills/sprint-loop/scripts/selftest.sh | high | 5 finalize-plan.sh call sites (steps 04, 10, 12, 13×2) + step 07 (test-report → loop): success paths need critique fixtures; new refusal steps needed |
| sprints/s11+s12 plan/test critique.md (4 files) | high | Real verdict format: `## Confidence` heading, first non-empty line begins with the (usually backticked) token — `clean` \| `proceed-with-caveats` \| `block` |
| claude-code/skills/sprint-loop/prompts/plan-critic.md + test-critic.md | med | Prompts mandate exactly the three verdicts and the `## Concerns` structure the parser will check |
| claude-code/skills/sprint-loop/phases/03-plan-phase.md + codex 03 | med | Critic section says "do NOT proceed to finalize on unaddressed block" — gate line to add (per-copy; 03 is intentionally divergent) |
| claude-code/skills/sprint-loop/phases/05-test-phase.md (claude=codex) | med | Critic-before-test-report section — routing-gate line to add (parity-mapped, one edit ×2) |
| open-harnesses/particles/03-plan-phase.md + 07-test-phase.md | low | One-sentence integrations of both gates |
| antigravity-ide/global_workflows/sprint-loops.md | low | Its Plan sync-step adds the lock header MANUALLY, bypassing finalize-plan.sh — gate cannot bind there; deferred to T-106 (antigravity parity decision), noted explicitly |

## 3. External Sources

None consulted (0/5) — all design inputs are in-repo (the four real critiques are the format corpus).

## 4. Risks, Unknowns, Dependencies

- **Risk (gate ordering):** if the critique gate ran before the existing gates, selftest steps 10/12/13 would refuse for the wrong reason and false-pass. Mitigation: critique gate runs LAST; each existing refusal step's fixture ALSO gets a valid critique so the step still isolates its own gate.
- **Risk (verdict parsing):** `block` as a bare substring could false-match prose ("unblocked"). Mitigation: parse only the FIRST non-empty line after `^## Confidence`, require it to START with an optionally-backticked verdict token; anything else = malformed = refuse.
- **Risk (routing change):** any current-phase.sh change risks transition regressions. Mitigation: selftest updated in the same commit (sprint-0 ADR), including a new negative step (test-report present, critique absent → still `test`).
- **Dependency/back-compat:** downstream projects mid-sprint at upgrade time: plans already locked are untouched (gate only fires at lock time); a project in Test with a report but no critique will re-route to `test` — correct per protocol, and the fix (write the critique) is the protocol's own requirement. Failure path (failure-report.md) intentionally exempt on both gates.
- **Known non-binding surface:** antigravity's manual-header flow bypasses finalize-plan.sh (see survey; T-106).

## 5. Recommended Approach

Primary, 3 elementary tasks:

1. **Plan gate in finalize-plan.sh (×4 bundles):** fourth gate, ordered last — `sprints/sN/sprint-plans/critique.md` must exist, contain a `## Concerns` heading, and its `## Confidence` first non-empty line must start with `clean` or `proceed-with-caveats` (optionally backticked). `block`, missing verdict, missing file, or missing Concerns → refuse with a message naming what to do (run the critic per phases/03).
2. **Test-phase routing gate in current-phase.sh (×4) + selftest coverage (×4):** pass path requires `sprint-tests/critique.md` non-empty alongside `test-report.md` (existence check only — routing stays derive-only and cheap; verdict semantics live in the phase docs); failure-report path unchanged. Selftest: step 07 fixture writes the critique; new steps — finalize refuses without critique / refuses on `block` / accepts on valid; test-report-without-critique routes `test`. Steps renumber to "all 19 transitions" (or as counted).
3. **Doc lines:** claude 03 + codex 03 (per-copy), 05 (parity ×2), oh particles 03 + 07, one antigravity deferral note in ROADMAP §6 text (not the workflow file — the gate can't bind there yet).

Alternative considered: a separate `finalize-test-report.sh` helper for the test-phase analogue. Rejected: adds a new script ×4 + suite registration for what the existing routing derivation already expresses; the state machine IS the enforcement point on the test side.

Alternative considered: semantic verdict parsing for the test critique too (in current-phase.sh). Rejected: routing must stay derive-only and fast (sprint-0 ADR spirit); the lock-time script is where content validation belongs.

Rationale: completes the sprint-5 ADR with the minimum enforcement surface: one content-validating gate at the only lock point, one existence check in the state machine, zero new scripts.

## Artifacts

None saved — the four committed critiques cited in the survey are the format corpus.
