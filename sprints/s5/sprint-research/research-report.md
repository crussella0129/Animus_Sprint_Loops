# Sprint 5 Research Report

## Decisions Reviewed

ADRs from `decisions.md` bearing on this sprint:

- **2026-05-20 — Bake autonomy + workflow patterns into the skill (sprint 3)** — relevant: sprint 5 expands the "autonomous operation" model to include adversarial review steps. Subagent fan-out fits naturally inside the existing autonomy posture (work independently, but with a critic gate) and does NOT weaken the safety floor.
- **2026-05-20 — Hard plan-mode primitive + EARS criteria + decisions-reviewed gate (sprint 4)** — relevant: the critic-review step lives at the END of Plan Phase (after EARS-formatted criteria are written, before `finalize-plan.sh` locks them) and at the END of Test Phase (after tests are written, before `test-report.md` is finalized). The critic specifically checks that EARS clauses are well-formed and that the Decisions-Reviewed entries are non-trivial.

No prior decision is being violated. This sprint adds a NEW review surface; it doesn't change any existing gate or schema.

## 1. Sprint Goal

User priority #1 from sprint 3's flagged candidates: **subagent fan-out** — at
Plan Phase and Test Phase, after producing the artifacts but BEFORE locking
them, spawn a critic subagent that adversarially reviews the work. The critic
returns concerns; the primary agent must address each concern (fix, defer
with rationale, or explicitly reject the critique) before proceeding to the
lock step. Adds critic prompt templates as first-class artifacts in the skill
bundles + open-harnesses, and instructs the spawn-review-address flow in the
relevant phase files.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| `claude-code/skills/sprint-loop/phases/03-plan-phase.md` | **high** | Where the Plan-critic step is inserted: after `ExitPlanMode` returns + plans are written to disk, BEFORE `finalize-plan.sh`. |
| `claude-code/skills/sprint-loop/phases/05-test-phase.md` | **high** | Where the Test-critic step is inserted: after tests are written + run, BEFORE writing `test-report.md`. |
| `codex-cli/skills/sprint-loops/phases/{03,05}-*.md` | high | Sync targets — Codex has its own subagent primitive ("Subagent opportunity" section in SKILL.md). |
| `codex-cli/skills/sprint-loops/SKILL.md` | medium | Already mentions Subagent opportunity; gets a cross-reference to the critic prompts. |
| `open-harnesses/particles/03-plan-phase.md`, `07-test-phase.md` | medium | Single-sentence integrations inside the existing quoted blocks. |
| (new) `claude-code/skills/sprint-loop/prompts/{plan-critic,test-critic}.md` | high | NEW: critic prompt templates. Live inside the skill bundle so the agent can reference them by path when spawning. |
| (new) `codex-cli/skills/sprint-loops/prompts/{plan-critic,test-critic}.md` | high | NEW: mirror for codex. |
| (new) `open-harnesses/prompts/{plan-critic,test-critic}.md` | high | NEW: canonical source for the templates. |

## 3. External Sources

The "adversarial review" pattern is well-documented in agentic-system
literature (Pedro Santanna's setup, OpenAI's adversarial critic patterns,
etc.) but the implementation here is internal: a prompt template + a
spawn-review-address protocol. No external code consulted.

## 4. Risks, Unknowns, Dependencies

- **Risk:** *Critic flakes — over-critiques or under-critiques.* The prompt template steers the critic toward specific failure modes (vague success criteria, plan-test mismatch, missing risks, untested EARS clauses) so the critique is structured. Worst case: the critic finds zero issues; the primary agent records "no critique returned, proceeded" and moves on.
- **Risk:** *Cost — every sprint now spawns 2 extra subagent calls (Plan + Test critics).* Acceptable: subagent calls are cheap relative to the per-sprint work they review, and the critic prevents bad plans from being committed.
- **Risk:** *Open-harnesses cannot spawn subagents.* Many local-LLM / custom-runner harnesses don't have a subagent primitive. The open-harnesses particle documents the pattern as "if your harness supports subagents, spawn a critic; otherwise self-critique in a single message before locking." Honest about the asymmetry.
- **Unknown:** *Whether the critic should have write access to the plan files (suggest fixes inline) or read-only with structured output.* Decision: read-only. The primary agent addresses concerns; the critic stays adversarial. Avoids the critic and primary fighting over the same file.
- **Dependency:** Claude Code's Agent tool (already used elsewhere); Codex subagents. No new external deps.

## 5. Recommended Approach

**Primary:** Three elementary tasks.

1. *Add critic prompt templates.* Create
   `open-harnesses/prompts/plan-critic.md` and
   `open-harnesses/prompts/test-critic.md`. Each is a self-contained prompt
   that, given the just-written plan/test artifact paths, returns a
   structured critique covering specific failure modes (vague EARS clauses,
   missing risk coverage, plan-test mismatch, ignored ADRs from
   `decisions.md`, etc.).
2. *Wire the spawn-review-address protocol into the phase docs.* Update
   `phases/03-plan-phase.md` (claude-code) — after `ExitPlanMode` returns
   and plans are written, BEFORE `finalize-plan.sh`, spawn a critic
   subagent with the `prompts/plan-critic.md` template, read the critique,
   address each item (fix, defer with rationale, or reject) and record the
   critique + responses in `sprint-plans/critique.md`. Same pattern for
   `phases/05-test-phase.md` with `prompts/test-critic.md` before writing
   `test-report.md`. Open-harnesses particles 03 + 07 get parallel
   integrations.
3. *Sync to both bundles + propagate.* Copy the prompts into both skill
   bundles. Sync phase doc additions to codex (with `/plan` opening preserved).
   No selftest extension is meaningful here (the critic step requires LLM
   execution, not testable via the bash harness). Document this limitation
   in the test-report — first sprint to use the new critic protocol is the
   real test.

**Alternatives considered:**

- *Synchronous critic in-line (not a subagent)*: have the primary agent self-critique in the same message. Rejected — it conflates author and reviewer; the user explicitly cited "Pedro Santanna's setup spawns specialized critics" as the desired pattern.
- *Critic with write access*: have the critic edit plan files directly to fix issues. Rejected — adversary becomes author; the primary agent loses ownership of the plan structure.
- *Hard gate via `finalize-plan.sh` requiring `critique.md`*: refuse to lock plans without a critique file. Deferred — adds enforcement complexity; can be added in sprint 6 once the pattern has been exercised manually for a few sprints.

**Rationale:** Subagent fan-out is the user's highest remaining priority
(#1 of 1-and-4 still open). The primary cost is a few hundred tokens per
subagent; the value is catching bad plans before they're committed. Three
tasks, all doc-level + new files, syncable cleanly. Sprint 6 will carry the
remaining items (research budget, CI workflow, optional hard-gate on
critique file).

## Artifacts

- (none — research is self-contained)
