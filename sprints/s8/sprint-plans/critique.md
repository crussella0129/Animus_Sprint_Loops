# Plan Critique — Sprint 8

Critic: general-purpose subagent via `prompts/plan-critic.md`. `## Confidence: block`.
Third plan-critic block across sprints 7–8; all valid. This sprint reverses
part of sprint 7, so the critic was especially watchful about re-introducing
the C-004 contradiction and removing both runaway brakes at once.

## Concerns + responses

### C-001: the C-004 consistency "guard" is a one-shot manual grep, not a committed regression test — BLOCK
- **Response:** fix-in-plan. Added a committed maintainer check `tools/check-merge-policy.sh` that asserts every merge-policy doc (claude 06, codex 06, particle 08) pairs merge guidance with the checkpoint qualifier and that SKILL.md agrees — re-runnable on every future edit, not one-shot. Run it in the Test Phase and reference it as the CI hook (CI is the standing backlog item). This is the durable guard the manual grep wasn't.

### C-002: "merge green CI" resolves the UNKNOWN-consequence case toward merge — BLOCK
- **Response:** fix-in-plan. Added an explicit rule/EARS clause: "can't verify" includes "can't determine the blast radius." When the agent cannot determine whether a merge is reversible / what it triggers, it defaults to a CHECKPOINT (stop + surface), not merge. The autonomous-merge path applies only when the consequence is known-and-reversible (or known to be just the PR landing) with green CI.

### C-003: removing both runaway brakes (bounding + no-merge) at once, interaction unanalyzed — BLOCK
- **Response:** fix-in-plan (record the reasoning). The runaway control is now explicitly: (1) per-task commit boundaries = rollback, (2) the four checkpoint stops INCLUDING the C-002 unknown-consequence default-to-stop, (3) user interrupt of `/loop`. A count cap is deliberately NOT required — per the user's explicit intent ("mostly let you do it; stop only for what AI can't verify"). Recorded in research §4 + a decisions ADR so the combined posture is a stated decision, not a silent one. Bounding stays available as an optional cap.

### C-004: T-002 bundles merge re-scope + the net-new visual-review checkpoint — granularity
- **Response:** defer-with-rationale (critic offered this). They edit the same Loop-Phase merge/close-out paragraphs across the same three files, so one coherent diff is cleaner than two near-overlapping ones. Recorded.

### C-005: E2E stand-in only exercises the continue path, not the stop path
- **Response:** fix-in-plan. The first-launch verification now includes a POSITIVE checkpoint test: deliberately stage a checkpoint (a sprint producing a visual artifact, or an unknown-consequence merge) and confirm the loop STOPS and surfaces — so the brake is exercised, not just the autonomy path.

## Confidence (post-response)
Was `block`. C-001 (durable check script), C-002 (unknown→checkpoint), C-003
(recorded reasoning), C-005 (positive stop-path E2E) fixed in-plan; C-004
deferred with rationale. Finalizing after applying these to the plan below.
