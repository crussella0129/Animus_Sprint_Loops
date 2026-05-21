# Plan Critique — Sprint 7

Critic: general-purpose subagent via `prompts/plan-critic.md`. Returned
`## Confidence: block` with 7 concerns. Several were genuinely critical for an
unattended self-committing loop. The block was correct; the plan was
substantially redesigned before lock.

## Concerns + responses

### C-001: `confidence < 0.5` stop rests on an OPTIONAL, often-absent throttle — BLOCK
- **Response:** fix-in-plan. Auto mode now (a) treats absent `confidence.txt` as 1.0 (not a blocker) and (b) relies on the max-sprints guard as the real backstop. SKILL.md states this explicitly; confidence is a *soft* stop only when actively tracked.

### C-002: max-sprints guard has no persistence across cold re-arms — BLOCK (primary backstop was decorative)
- **Response:** fix-in-plan. Concrete mechanism added: a launch marker `sprints/.auto-sprints-remaining` (a plain integer file; gitignored with `sprints/`, so it's per-launch and local). The FIRST Loop-Phase re-arm creates it (default 5, or the value the user gave at launch); EACH re-arm reads it, stops if ≤ 0, else decrements and re-arms. Survives the fresh context of every `ScheduleWakeup` because it's on disk. T-002 owns creating/reading/decrementing it.

### C-003: "failure-report written" stop contradicts the failure→next-sprint design — fix
- **Response:** fix-in-plan. T-002 states explicitly: on exit status `failed` or `aborted`, the agent does NOT check off the roadmap goal and does NOT re-arm — it stops and reports for human review. (The protocol's failure→research handoff still works on a *manual* resume; auto mode deliberately stops rather than auto-driving into a recovery sprint unattended. Recorded as an intentional deviation.)

### C-004: unattended ExitPlanMode hang only "documented around," not resolved — BLOCK
- **Response:** fix-in-plan, properly this time. In auto/unattended mode the agent SKIPS the `EnterPlanMode`/`ExitPlanMode` primitives entirely (those exist for interactive human plan review, and `ExitPlanMode` would block on a human who isn't there). It writes the plans directly to disk and relies on the **plan-critic subagent** as the review gate. This is changed in BOTH the files where the gate lives — `phases/03-plan-phase.md` AND `SKILL.md` "Plan mode" — not just clarified downstream. Interactive mode keeps the plan-mode primitives.

### C-005: safety floor's "pause for hard-to-reverse" assumes a human; merge/push happen mid-sprint — BLOCK
- **Response:** fix-in-plan. Auto mode's safety translation: it commits and pushes **forward-only to the working branch**, but does NOT perform hard-to-reverse actions unattended — specifically NO merge to a base branch, NO force-push, NO branch deletion. A PR-wrapped sprint pushes the branch + opens the PR, then STOPS the loop (does not re-arm) and reports "PR ready for review." The user merges. Auto-merge is available only if the user explicitly opts in at launch. So the irreversible action is held, not just "not-re-armed-after."

### C-006: launch-counter has no owner (falls between T-002's two files) — fix
- **Response:** fix-in-plan. T-002 explicitly owns the launch marker (`sprints/.auto-sprints-remaining`): created on first re-arm, read/decremented on each. `phases/01-init-sprint.md` only documents `roadmap.md`; the counter lives in the Loop Phase re-arm step. Clear owner now.

### C-007: zero executable verification of the stop logic for a self-pushing loop — defer-with-protocol
- **Response:** defer-with-rationale + added protocol. The stop logic is LLM/harness-level and not bash-drivable, so the unit tests stay doc-presence. BUT the test plan now adds a **first-launch verification protocol**: the user's first auto-mode launch should set max-sprints=1 with a single roadmap item, observe exactly one re-arm, then confirm the loop STOPS on the now-empty queue. That bounded first run is the E2E stand-in, documented as the required verification step rather than "whenever the user launches."

## Confidence (post-response)
Was `block`; resolved. C-001/C-002/C-004/C-005 fixed in-plan with concrete mechanisms; C-003/C-006 fixed; C-007 deferred with an added first-launch protocol. Plan rewritten below before `finalize-plan.sh`.

---

## DESIGN PIVOT (post-critique, mid-Plan-Phase) — user clarification

After the block above, the user clarified a Claude Code fact I had wrong:
**"auto mode" is the auto-accept option selected at the plan-approval prompt
when exiting plan mode.** So plan mode + selecting auto-accept IS the
unattended mechanism — not a hang to engineer around.

Effect on the critique:
- **C-004 (ExitPlanMode hang): RESOLVED** — auto-accept is the answer to that
  prompt, not a blocker. The fix is to ensure plan mode engages and document
  selecting auto-accept; no auto-confirm hack needed.
- **C-001/C-002/C-003/C-006: OBSOLETED** — these were all about the
  ScheduleWakeup self-rearm + roadmap.md goal-queue + max-sprints-counter
  machinery I was inventing. That machinery is GONE. Recurrence is handled by
  the harness `/loop` (user-launched, user-stoppable); the skill no longer
  self-rearms, so there are no inert stop conditions to get wrong.
- **C-005 (safety floor under auto-accept): RETAINED** — still valid and still
  fixed. Auto-accept covers routine edits/commits, but T-002 reaffirms: no
  unattended merge-to-base / force-push / destructive ops without explicit
  opt-in (push branch + open PR, leave the merge for a human).
- **C-007 (verification): RETAINED as a first-launch check** — see test plan
  E2E section (bounded first run confirming plan mode engaged, auto-accept
  carried, next sprint fired, no unattended merge).

The redesigned plan is doc-only, claude-specific, and far lower-risk than the
machinery the critic rightly blocked. Re-running the plan critic on the
revised plan below before finalize (prior verdict was block + the plan is now
fundamentally different — it gets re-vetted).

---

## Second critic round (on the revised plan) — responses

Re-ran the plan critic on the simplified plan; it returned `block` again with
mostly-new, valid concerns:

- **C-004 (decisive): RESOLVED.** The safety floor in SKILL.md contradicted
  `phases/06-loop-phase.md` step 6 (`gh pr merge --merge --delete-branch`
  unconditionally). Brought `06-loop-phase.md` into T-002 scope and the
  particle 08 + codex copy into T-003: the merge step is now gated on
  interactive-or-explicit-opt-in. Added `test_loop_phase_merge_gated` (+ codex
  equivalent) — the test the critic correctly noted was missing.
- **C-003: RESOLVED.** The runaway risk moved to the user but wasn't
  documented. T-002 now recommends bounding (`/loop N ...`) and warns unbounded
  runs continue until interrupt; `test_skill_bounding_recommendation` covers it.
- **C-001: RESOLVED.** Prepended a DESIGN PIVOT banner to `research-report.md`
  so the locked research no longer contradicts the locked plan / pollutes the
  next sprint's inputs.
- **C-002: RESOLVED.** Softened the `/loop` cadence claim — the doc now says
  re-fire re-runs `current-phase.sh` and resumes (a checkable fact), not
  "re-fires each sprint" (an unverifiable harness-cadence assertion).
- **C-005 (granularity of T-003): deferred-with-rationale** — recorded in the
  T-003 notes (cohesive cross-bundle merge-gate + recurrence-note unit).
- **C-006: positive finding** — EARS↔test traceability otherwise clean.

Finalizing after these fixes (not re-running a third critic round): all
concerns are concrete, test-covered doc changes whose correctness the Test
Phase grep-verifies — notably `test_loop_phase_merge_gated` closes the exact
gap (test only checked SKILL.md) the critic flagged. Diminishing returns on a
third round; the safety-critical contradiction is now both fixed and tested.
