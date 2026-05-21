# Sprint 8 Research Report

## Decisions Reviewed

- **2026-05-21 — Claude auto mode = plan-mode auto-accept + /loop; merge stays human-gated (sprint 7)** — DIRECTLY revised by this sprint. Sprint 7 gated PR-merge as "interactive or opt-in only" and recommended bounding unattended runs (`/loop N ...`). The user has clarified the intent: sprint-loop should run mostly unattended and stop ONLY for what AI cannot verify. So the merge gate and the bounding emphasis are re-scoped (not removed wholesale): merging AI-verifiable (green-CI) work is allowed unattended; the stop criterion becomes "human-verification checkpoints," not an arbitrary sprint count. This is a deliberate, recorded revision of the sprint-7 decision, made on the decision-owner's (user's) instruction.
- **2026-05-20 — Bake autonomy + workflow patterns into the skill (sprint 3)** — relevant: the "Safety floor" originated here. It is NOT discarded; it is re-expressed as a SUBSET of the human-verification-checkpoint criterion (irreversible actions whose safety tests can't confirm = things a human must approve).
- **2026-05-20 — Subagent fan-out (sprint 5)** — relevant: the Plan/Test critics remain the in-loop substantive review and are themselves AI-verifiable steps that do NOT require a human stop.

This sprint REVISES the sprint-7 decision (with the user's explicit authorization) rather than violating it silently.

## 1. Sprint Goal

Reframe auto mode's stop philosophy. Replace "bound the run + blanket
no-unattended-merge" with a principled criterion the user stated: **run
unattended; halt ONLY when something needs human verification that AI cannot
do** — visual/UX/aesthetic inspection, approval of consequential actions
whose correctness tests/CI cannot validate, genuine product/scope ambiguity,
or an unrecoverable failure needing human diagnosis. Everything AI can verify
(green tests/CI, reversible changes) proceeds autonomously, including merging.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| `claude-code/skills/sprint-loop/SKILL.md` | **high** | "Autonomous operation" + "Safety floor" carry the bounding emphasis + the auto-accept≠auto-merge clause. Both reframed around the verification-checkpoint criterion. |
| `claude-code/skills/sprint-loop/phases/06-loop-phase.md` | **high** | Sprint-7 merge gate ("unattended → do NOT merge") is re-scoped: merge green-CI work unattended; stop for unverifiable consequences (deploy/release/visual). Add the "launch for visual review" checkpoint. |
| `codex-cli/skills/sprint-loops/phases/06-loop-phase.md` | medium | Same re-scope, codex-flavored. |
| `open-harnesses/particles/08-loop-phase.md` | medium | Same re-scope in the quoted block. |
| `claude-code/commands/sprint-loop.md` | medium | Drop "bound it" as the headline; describe the checkpoint-stop philosophy. |
| `claude-code/README.md` | low | Auto-mode section: same reframe. |

## 3. External Sources

None — this is a philosophy/wording reframe of existing in-repo docs informed
directly by the user's stated intent. Budget: 0 of 5.

## 4. Risks, Unknowns, Dependencies

- **Risk: re-introducing the C-004 contradiction.** Sprint 7's critic caught SKILL.md and 06-loop-phase.md disagreeing about merging. The reframe must keep them CONSISTENT — both say "merge AI-verifiable work; stop for unverifiable." A negative-grep test (sprint-7 `test_no_unconditional_merge` style, inverted) guards it.
- **Risk: "AI cannot verify" is fuzzy.** Mitigation: enumerate concrete checkpoint categories rather than leaving it abstract — (a) visual/UX/layout/aesthetics, (b) irreversible + non-test-verifiable (force-push to a shared branch, destructive data ops, public release/deploy with real-world effect), (c) genuine product/scope ambiguity (two valid interpretations, can't pick without intent), (d) unrecoverable failure (failure-report territory). Routine reversible + test-green work is explicitly NOT a checkpoint.
- **Risk (compound): removing both runaway brakes at once.** Sprint 7 had two — bounding + no-unattended-merge. Sprint 8 re-scopes both. Recorded decision: runaway control becomes per-task commit rollback + the four checkpoint stops (incl. the unknown-consequence default-to-stop) + user interrupt; a count cap is deliberately optional per the user's stated intent. The unknown-consequence checkpoint is what keeps auto-merge from being reckless.
- **Risk: losing the genuine safety floor.** The irreversible-action items stay — but reframed as instances of (b), i.e. "a human must approve what AI can't verify," which is the user's OWN criterion, not externally-imposed caution.
- **Unknown: does merging trigger deploy?** Project-dependent. Decision: the doc says "merge AI-verifiable work, BUT if the merge itself causes an unverifiable real-world effect (production deploy, public release), that's a checkpoint — surface it." Project-agnostic and correct.
- **Dependency:** none new; doc-only. Selftest unchanged at 14.

## 5. Recommended Approach

**Primary:** Three doc tasks (claude-code-centric, light cross-bundle).

1. *SKILL.md reframe.* Rewrite "Autonomous operation" so the default is run-to-completion-unattended; replace the bounding recommendation with the checkpoint criterion (bounding demoted to "optional, if you want a cap"). Rewrite the "Safety floor" / auto-accept≠auto-merge clause as the checkpoint taxonomy: PROCEED on AI-verifiable; STOP+surface on the four checkpoint categories. Merging green-CI work is explicitly allowed unattended.
2. *06-loop-phase.md re-scope (+ codex + particle).* The PR-merge step: merge on green CI unattended (it's AI-verifiable); stop only if the merge has an unverifiable consequence (deploy/release) or the sprint produced something needing visual review — in which case surface/launch it for the human (the "launch the app for visual review" pattern). Keep all copies consistent.
3. *Command + README reframe.* `commands/sprint-loop.md`: lead with "runs unattended; stops at human-verification checkpoints," bounding as an aside. README auto-mode section: same.

**Alternatives considered:**
- *Leave sprint-7 as-is.* Rejected — the user (decision owner) explicitly corrected the philosophy.
- *Remove the safety floor entirely.* Rejected — the irreversible-action items ARE legitimate "human must approve what AI can't verify" checkpoints; they survive, just reframed under the user's own criterion rather than as blanket caution.
- *Keep blanket no-unattended-merge.* Rejected — a green-CI merge is AI-verifiable; stopping for it contradicts the stated intent.

**Rationale:** This makes the stop policy match the user's mental model: maximize autonomy, halt only at genuine human-in-the-loop necessities. The risk is re-introducing inconsistency between SKILL.md and the loop-phase doc, which a consistency test guards.

## Artifacts
- (none — self-contained)
