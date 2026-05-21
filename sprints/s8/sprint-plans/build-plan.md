Finalized - DO NOT EDIT

# Sprint 8 Build Plan

## Schema Tree
- Sprint Goal: auto-mode stops = human-verification checkpoints, not arbitrary bounds (incl. unknown-consequence → stop)
  - Component A: SKILL.md philosophy
    - T-001: rewrite "Autonomous operation" + "Safety floor" around the checkpoint criterion (incl. unknown-blast-radius → checkpoint)
  - Component B: Loop-Phase merge re-scope + visual checkpoint + durable consistency guard
    - T-002: 06-loop-phase.md (claude+codex) + particle 08 merge re-scope & visual-review checkpoint; add committed `tools/check-merge-policy.sh`
  - Component C: command + README reframe
    - T-003: commands/sprint-loop.md + claude README — lead with checkpoint philosophy, bounding as optional aside

## Execution Sequence

### T-001: SKILL.md — checkpoint-based autonomy philosophy
- **Touches:** `claude-code/skills/sprint-loop/SKILL.md`
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** an agent reads SKILL.md "Autonomous operation", **THEN** it **SHALL** state the default is to run unattended to completion, halting ONLY at human-verification checkpoints (not at an arbitrary sprint count).
  - **WHEN** an agent reads the checkpoint criterion, **THEN** it **SHALL** enumerate four STOP categories: (a) visual/UX/aesthetic inspection; (b) an irreversible action whose safety tests/CI cannot verify **OR whose consequence/blast-radius the agent cannot determine**; (c) genuine product/scope ambiguity; (d) unrecoverable failure.
  - **WHEN** an agent reads the criterion, **THEN** it **SHALL** state AI-verifiable work (green tests/CI, reversible changes) proceeds autonomously — including merging a green PR whose consequence is known-and-reversible — and that an **unknown** consequence defaults to a checkpoint, not a merge. [C-002]
  - **WHEN** an agent reads about runaway control, **THEN** it **SHALL** state control = per-task commit rollback + the checkpoint stops + user interrupt, and that a count cap (`/loop N`) is OPTIONAL, not required. [C-003]
- **Notes:** sprint-3 safety-floor irreversible items survive as instances of category (b). Keep consistent with 06-loop-phase.md.

### T-002: Loop-Phase merge re-scope + visual checkpoint + committed consistency guard
- **Touches:** `claude-code/skills/sprint-loop/phases/06-loop-phase.md`, `codex-cli/skills/sprint-loops/phases/06-loop-phase.md`, `open-harnesses/particles/08-loop-phase.md`, `tools/check-merge-policy.sh` (new)
- **Depends on:** T-001
- **Success criterion (EARS):**
  - **WHEN** a PR-wrapped sprint reaches Loop Phase with green CI AND the merge's consequence is known-and-reversible, **THEN** `06-loop-phase.md` **SHALL** say the merge proceeds autonomously.
  - **WHEN** the merge would cause an unverifiable OR undeterminable real-world consequence (deploy / public release / unknown blast radius), **THEN** the doc **SHALL** make it a checkpoint: surface, do not merge. [C-002]
  - **WHEN** a sprint produced a visually-inspectable artifact, **THEN** the doc **SHALL** instruct surfacing/launching it for review as a checkpoint.
  - **WHEN** `tools/check-merge-policy.sh` is run, **THEN** it **SHALL** exit 0 only if claude 06, codex 06, particle 08, and SKILL.md each pair merge guidance with a checkpoint qualifier (no blanket "do NOT merge", no unconditional `gh pr merge`), and exit non-zero otherwise — a re-runnable regression guard (CI hook). [C-001]
- **Notes (C-004 granularity, deferred):** merge re-scope + visual checkpoint edit the same Loop-Phase close-out paragraphs across the same files → one coherent diff. Recorded as intentional.

### T-003: command + README reframe
- **Touches:** `claude-code/commands/sprint-loop.md`, `claude-code/README.md`
- **Depends on:** T-001, T-002
- **Success criterion (EARS):**
  - **WHEN** an agent reads `commands/sprint-loop.md` auto-mode section, **THEN** it **SHALL** lead with "runs unattended; stops only at human-verification checkpoints" and present bounding as an optional aside.
  - **WHEN** a reader reads `claude-code/README.md` auto-mode section, **THEN** it **SHALL** describe the checkpoint-stop philosophy and keep the Claude-specific note.
  - **WHEN** either doc is read, **THEN** neither **SHALL** recommend bounding as the primary unattended posture.
- **Notes:** No skill-script change → selftest stays 14.
