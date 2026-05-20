# Architectural Decisions

## 2026-05-19 — `current-phase.sh` build/test disambiguator uses `completed-tasks.md` (sprint 0)
- **Context:** The original phase-detection script could not distinguish
  "Build Phase not yet started" from "Build Phase done; Test pending" — both
  states have an empty `agent-tasks.md` (for the current sprint) and an empty
  `test-report.md`. The script treated both as `test`, causing the agent to
  skip the Build Phase entirely on first invocation after Plan finalization.
- **Decision:** Add a single check after the existing "build in progress" line:
  if no `sprint $N` token exists in `agent-tasks/completed-tasks.md` either,
  the Build Phase has not started — report `build`. Otherwise fall through to
  the existing Test check.
- **Alternatives considered:** Replacing derived state with a declared
  `phase.txt` file written by each phase at transition time. Rejected because
  it violates the protocol's foundational principle that the filesystem IS
  the state machine — it would create a new failure mode (declared phase
  disagrees with on-disk artifacts) without removing any existing one.
- **Consequences:**
  - All future sprints' routing is correct end-to-end without manual override.
  - The protocol now formally relies on `completed-tasks.md` being the
    authoritative record that a sprint's Build Phase has run; helpers that
    consume completed tasks (none today, but conceivable) must preserve the
    `sprint $N` token in their entries.
  - An empty build plan (zero elementary tasks) would now loop on `build`
    forever — flagged as a follow-up; a sprint with zero build tasks should
    be invalid by the planner anyway.
  - The skill ships with a `scripts/selftest.sh` that guards every transition;
    any future change to `current-phase.sh` must be made alongside a selftest
    update if it adds a new phase or transition.
