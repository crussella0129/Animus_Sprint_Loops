# Sprint 0 Research Report

## 1. Sprint Goal

Improve the `loop-sprint` Claude Code skill by hardening its phase-detection
script (`current-phase.sh`) so it correctly distinguishes "Build Phase not yet
started" from "Build Phase done; Test pending," and add a permanent self-test that
exercises every phase transition so this class of regression can't recur. Apply
the same change consistently across all three script copies (open-harnesses,
claude-code/loop-sprint, codex-cli) since the skill ships the same scripts in
each.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| `open-harnesses/scripts/current-phase.sh` | **high** | Canonical phase-detection script; contains the discrimination bug between Build (not started) and Test. |
| `claude-code/skills/loop-sprint/scripts/current-phase.sh` | high | Byte-identical copy of the canonical script; inherits the bug. |
| `codex-cli/skills/sprint-loops/scripts/current-phase.sh` | high | Byte-identical copy; inherits the bug. |
| `open-harnesses/scripts/init-sprint.sh` | medium | Creates `agent-tasks.md` and `completed-tasks.md` with schema headers (no `sprint N` strings) — relevant because the bug's grep targets are header-only at sprint start. |
| `open-harnesses/scripts/finalize-plan.sh` | medium | Prepends the `Finalized - DO NOT EDIT` header that the plan check in `current-phase.sh` keys on. |
| `open-harnesses/scripts/commit-task.sh` | low | Commit boundary; unaffected. |
| `open-harnesses/schemas/agent-tasks.md`, `completed-tasks.md` | medium | Define the `(sprint N)` token format that the grep checks look for. |
| `open-harnesses/particles/06-build-phase.md` (and `04-build-phase.md` in skill bundles) | medium | Build particle explicitly says "append each task from build-plan ... to the bottom of agent-tasks.md" and "delete the task entry from agent-tasks.md, and append it to completed-tasks.md" — confirms `completed-tasks.md` is the legitimate disambiguator. |
| All three `phases/00-overview.md` (skill bundles) | low | Document the current phase-detection table; will need a one-line update if the table mentions the discrimination explicitly (it does not). |

## 3. External Sources

(None — the protocol is fully self-described in this repository. The canonical
source is `open-harnesses/`; the skill bundles are byte-identical copies. No
external reference, vendor doc, or third-party issue is relevant; the budget
permits up to 5 external sources and 0 were needed.)

## 4. Risks, Unknowns, Dependencies

- **Risk:** *Self-referential change.* This sprint runs in the same repo whose
  `current-phase.sh` is being changed. Mitigation: the installed skill
  (`~/.claude/skills/loop-sprint/scripts/current-phase.sh`) is what drives
  routing during the sprint, and is not modified until after the Loop Phase. The
  in-repo copies change in the Build Phase, but the routing-time script is
  unaffected mid-sprint.
- **Risk:** *Backwards compatibility.* No existing repos in the wild yet (the
  skill was just published), so the change is safe to land directly.
- **Unknown:** *Sprints whose build plan has zero tasks.* The protocol does not
  forbid an empty build plan; with the fix, such a sprint would loop on `build`
  forever. This is a pre-existing edge case the protocol itself doesn't address
  and is out of scope for this sprint — flag it as a follow-up.
- **Dependency:** `bash` 4+, `grep`, `sort`. Already required by the helper
  scripts; no new dependency introduced.

## 5. Recommended Approach

**Primary:** Add a single additional check in `current-phase.sh` after the
existing "build in progress" check. If no sprint-N tasks are queued AND no
sprint-N tasks have been completed (i.e., `completed-tasks.md` has no
`sprint $N` line), the Build Phase has not started — report `build`. Otherwise
fall through to the existing Test check. This is one extra `grep` in the hot
path; cost is negligible.

Then add `selftest.sh` to the canonical `scripts/` that drives `current-phase.sh`
through every transition (uninitialized → research → plan → build (not started) →
build (in progress) → test → loop → ready-for-next-sprint) and asserts the
expected output at each step. Sync both files to the two skill bundles.

**Alternative considered:** Re-architect `current-phase.sh` as a small state
machine reading a single `phase.txt` file written by each phase as it transitions.
*Rejected:* it violates the protocol's "filesystem IS the state machine" principle
(replaces derived state with declared state, creating a new failure mode where
`phase.txt` and the actual filesystem disagree). The single-grep fix preserves
the derived-state design.

**Rationale:** The bug is a *missing disambiguator*, not a structural flaw. The
filesystem already carries the information needed (the appearance of `sprint $N`
in `completed-tasks.md` proves the Build Phase ran). Use that signal; do not add
a new state surface.

## Artifacts

- `bug-trace.txt` — minimal reproduction of the misdetection, with the line numbers and explanation of why the existing two checks are insufficient.
