> **DESIGN PIVOT (post-plan-critique):** §1/§4/§5 below describe an earlier
> design (ScheduleWakeup self-rearm, `roadmap.md` goal queue, max-sprints
> guard). The user clarified that Claude Code's "auto mode" is the auto-accept
> option selected at the `ExitPlanMode` approval prompt — so that machinery was
> dropped. The build-plan is the source of truth: ensure plan mode engages,
> document selecting auto-accept, drive recurrence with the harness `/loop`
> (user-launched/stoppable), and keep merge-to-base human-gated. See
> `sprint-plans/critique.md` "DESIGN PIVOT".

# Sprint 7 Research Report

## Decisions Reviewed

ADRs from `decisions.md` bearing on this sprint:

- **2026-05-20 — Bake autonomy + workflow patterns into the skill (sprint 3)** — relevant: this sprint EXTENDS the "Autonomous operation" section with the actual self-rearm mechanism. The safety floor established there (don't weaken permissions, don't bypass hooks, hard-to-reverse actions pause) MUST continue to hold in auto mode — unattended ≠ unsafe.
- **2026-05-20 — Subagent fan-out: adversarial critic review (sprint 5)** — relevant: in auto mode the Plan/Test critics still run; auto mode must not skip them to "save time." The critic block is a legitimate stop-and-think point even unattended.
- **2026-05-21 — .gitignore for ephemeral working memory + abort empty-commit guard (direct change)** — relevant: auto mode runs many sprints unattended; commits must not fail. The abort guard and the gitignore interaction are already handled; auto mode inherits them.
- **2026-05-20 — Hard plan-mode primitive (sprint 4)** — relevant: under `/loop`, plan mode (`EnterPlanMode`/`ExitPlanMode`) presents a plan for approval. In UNATTENDED mode there is no human to approve the ExitPlanMode summary — auto mode must account for this (plan mode's approval gate becomes a no-op / auto-proceed when truly unattended). Flag for the design.

No prior decision is violated. This sprint adds an autonomy *driver* on top of the existing autonomy *posture*; the safety floor is explicitly preserved.

## 1. Sprint Goal

Add a Claude-specific **auto mode** to the `sprint-loop` skill: when launched
under `/loop` (self-paced), the Loop Phase re-arms the loop via `ScheduleWakeup`
so the next sprint starts automatically — no per-sprint check-in. Define the
**stop conditions** (so it doesn't run away), the **goal source** for each
unattended sprint (so it knows what to work on), and reaffirm the **safety
floor**. Claude-specific: Codex already has `codex exec` for non-interactive
runs; open-harnesses gets only a generic mention.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| `claude-code/skills/sprint-loop/SKILL.md` | **high** | "Autonomous operation" section gets the auto-mode protocol (how to launch, re-arm, stop, goal source). |
| `claude-code/skills/sprint-loop/phases/06-loop-phase.md` | **high** | The re-arm step lives here: after closing a sprint, in auto mode, call `ScheduleWakeup` with `/sprint-loop continue` (else stop per a condition). |
| `claude-code/skills/sprint-loop/phases/01-init-sprint.md` | medium | Auto mode's next-sprint goal comes from a goal queue; init/loop docs reference it. |
| `claude-code/commands/sprint-loop.md` | high | Document `/loop /sprint-loop continue` as the auto-mode launch; add an `auto` note. |
| `open-harnesses/particles/08-loop-phase.md` | low | One generic sentence: harnesses with a scheduling primitive can re-arm; see the Claude bundle. |
| (new) goal-queue convention (`roadmap.md`) | high | Auto mode pulls the next sprint goal from a user-pre-filled `roadmap.md` checklist; stops when empty. Documented, not a script (keeps it light + optional). |
| `ScheduleWakeup` tool (harness primitive) | high | Only available in `/loop` dynamic mode. The re-arm passes the same `/sprint-loop continue` prompt; delaySeconds ~60 (floor) to start the next sprint promptly. |

## 3. External Sources

None — `/loop` and `ScheduleWakeup` are Claude Code harness primitives documented in-tool; no external lookup needed. Budget: 0 of 5 used.

## 4. Risks, Unknowns, Dependencies

- **Risk: runaway loop.** A self-rearming loop with no stop condition burns tokens and makes unwanted commits unattended. **Mitigation (core of this sprint):** explicit stop conditions — (a) goal queue empty, (b) a `failure-report.md` was written (stop for human review), (c) confidence < 0.5 (the throttle already exists), (d) a max-sprints-per-launch guard, (e) any uncommitted dirty state that can't be resolved. Loop Phase checks ALL before re-arming; if any trips, it does NOT call `ScheduleWakeup` and instead reports and stops.
- **Risk: plan-mode approval gate has no human in unattended mode.** `ExitPlanMode` normally waits for user approval. Unattended, that would hang. **Mitigation:** document that in auto mode the plan is recorded to `build-plan.md`/`test-plan.md` (the durable artifact) and the agent proceeds; the critic review (sprint 5) is the substantive gate that replaces human plan approval when unattended.
- **Risk: safety floor erosion.** "Just do its thing" must not mean "auto-accept dangerous perms." **Mitigation:** reaffirm — auto mode still declines permission/security weakening, still pauses for hard-to-reverse actions (force-push to base, infra deletion); it pauses by NOT re-arming and reporting, rather than proceeding.
- **Unknown: goal source.** Where do unattended sprint goals come from? **Decision:** an optional `roadmap.md` at the project root — a checklist of sprint-level goals. Auto mode pops the top unchecked item as the next sprint goal and checks it off when the sprint closes. If `roadmap.md` is absent/empty, auto mode stops cleanly ("no queued goals"). Manual mode is unchanged (user gives the goal per `/sprint-loop start <goal>`).
- **Dependency:** `ScheduleWakeup` (claude-only), `/loop` skill. No new scripts.

## 5. Recommended Approach

**Primary:** Three elementary tasks (all claude-code doc-level; no scripts → selftest unchanged at 14).

1. *Auto-mode protocol in SKILL.md.* Expand "Autonomous operation": launch via `/loop /sprint-loop continue`; the Loop Phase self-rearms with `ScheduleWakeup` (same prompt, ~60s); STOP conditions enumerated; goal source = `roadmap.md`; safety floor reaffirmed (stop-by-not-rearming, never by weakening safety).
2. *Re-arm + stop + goal step in `phases/06-loop-phase.md`.* After the existing close-out steps, add an "Auto mode (under /loop)" block: check stop conditions → if clear AND a next goal exists in `roadmap.md`, check off the completed goal, then `ScheduleWakeup(prompt="/sprint-loop continue", delaySeconds≈60)`; else end the turn with a status report (do NOT re-arm). Also note the unattended plan-mode behavior.
3. *Command + goal-queue docs + light cross-bundle note.* `commands/sprint-loop.md`: document `/loop /sprint-loop continue` (auto) and `roadmap.md`. Add the `roadmap.md` convention to `phases/01-init-sprint.md` (claude). One generic sentence in `open-harnesses/particles/08-loop-phase.md`. No codex change (it has `codex exec`); note claude-specificity in `claude-code/README.md`.

**Alternatives considered:**
- *Interval `/loop 30m /sprint-loop continue`* instead of self-paced. Rejected as the default — sprints vary wildly in length; a fixed interval risks firing mid-sprint or idling. Self-paced re-arm only fires after a sprint closes. (Documented as an option for users who want a hard cadence.)
- *Pull next goal from `agent-tasks/agent-tasks.md`.* Rejected — that backlog is TASK-level (within a sprint); sprint-level goals are coarser. A separate `roadmap.md` keeps the two state surfaces clean (consistent with the sprint-0 "two state surfaces" ADR).
- *No goal queue — auto mode just re-runs until interrupted.* Rejected — without a goal source, a closed sprint has nothing to do; better to stop cleanly than spin.

**Rationale:** The re-arm is a few lines of instruction, but the VALUE and the RISK are entirely in the stop conditions + goal source + safety reaffirmation. Getting those right is the sprint. Claude-specific by design; minimal cross-bundle footprint.

## Artifacts
- (none — research is self-contained)
