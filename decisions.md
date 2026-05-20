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

## 2026-05-20 — `commit-task.sh` back-fills commit hashes; opt-in via `PENDING` token (sprint 1)
- **Context:** The protocol's `completed-tasks.md` schema includes a `Commit:`
  field for each entry, but the helper that creates the commit did not fill
  it. Sprint 0 left three manual back-fill edits in its git log as a result.
- **Decision:** If `agent-tasks/completed-tasks.md` contains a literal
  `Commit:** PENDING` placeholder when `commit-task.sh` runs, the script
  captures the new commit's short hash, replaces the FIRST `PENDING`
  occurrence with the hash, and folds the edit into the same commit via
  `git commit --amend --no-edit`. No-op when no `PENDING` token exists.
- **Alternatives considered:** A separate post-commit "back-fill commit"
  (rejected — violates the one-commit-per-task contract). A pre-commit hook
  (rejected — adds a new install step and entangles with whatever the user's
  own hooks do). A declarative "task ledger" outside `completed-tasks.md`
  (rejected — duplicates state, drifts from filesystem-as-state-machine).
- **Consequences:**
  - Agents writing entries with `Commit:** PENDING` get automatic hash fill.
  - Existing entries (and any future entries the agent fills by hand) are
    untouched — back-compat is guaranteed by the `grep -q PENDING` guard.
  - The contract is now "one commit per task, even with amend"; if a future
    helper also needs to amend a task's commit, it must compose with this one.

## 2026-05-20 — Abort path: `abort-sprint.sh` + hoisted Exit-status check in `current-phase.sh` (sprint 1)
- **Context:** The `/loop-sprint` command advertised an `abort` subcommand,
  but no script implemented it and the Loop Phase doc only listed `success`
  and `failed` as exit statuses. There was no clean way to stop a sprint
  mid-flight without faking a failure-report.
- **Decision:** Add `scripts/abort-sprint.sh "<reason>"` that sets `sprint-meta.md`
  Exit status to `aborted`, records the end timestamp, appends an `## Abort
  note` section with the reason, and commits `sprint-N: aborted — <reason>`.
  Hoist the Exit-status check in `current-phase.sh` to the top so a closed
  sprint (any of `success`/`failed`/`aborted`) short-circuits to
  `ready-for-next-sprint` regardless of intermediate filesystem state.
- **Alternatives considered:** Reusing the failure path for aborts (rejected
  — semantic conflation: a failed sprint feeds the next sprint's research, an
  aborted sprint does not). Leaving abort undocumented (rejected — the
  command file already advertised it).
- **Consequences:**
  - The skill's three exit statuses (`success`, `failed`, `aborted`) now each
    have a defined invocation path and a defined effect on the next sprint.
  - `current-phase.sh` semantics are clearer: a sprint is "closed" iff Exit
    status is one of the three end states; otherwise derive from artifacts.
  - The new `aborted` transition is covered by `selftest.sh` step 09.
  - `abort-sprint.sh` calls `git commit` — projects without a git root will
    see a non-zero exit. Acceptable: the Build Phase protocol already
    requires a git root for per-task commits.

## 2026-05-20 — `finalize-plan.sh` rejects empty build-plans + `install.sh` per bundle (sprint 2)
- **Context:** Two flagged follow-ups: (a) an empty build-plan would route to
  `build` and loop forever because no task ever gets queued; (b) the user
  reported seeing duplicate `/sprint-loop` entries after the rename, surfacing
  a need for idempotent install (current path is manual `cp -r` + `chmod +x`).
- **Decision:**
  (a) `finalize-plan.sh` requires at least one `^### T-[0-9]+:` execution
      entry in `build-plan.md` before locking; refuses with a clear message
      otherwise.
  (b) Each bundle ships an `install.sh` that wipes the prior install at the
      target path before copying fresh — `claude-code/install.sh`,
      `codex-cli/install.sh`, `open-harnesses/install.sh`. Per-bundle (not a
      single repo-root installer) to preserve the "each subdirectory is a
      complete atomic unit" principle from sprint 0.
- **Alternatives considered:** Empty-plan detection in `current-phase.sh`
  (rejected — `current-phase.sh` should be derive-only, not modify the build
  flow). Single repo-root `install.sh` with `--target` (rejected — couples
  bundles to a parent script).
- **Consequences:**
  - The empty-build-plan failure mode is closed; selftest step 10 guards it.
  - Future installs/re-installs are one command, idempotent. The manual `cp`
    instructions in the READMEs remain valid as the explicit fallback.
  - Discovered (not fixed in this sprint): two flaws in sprint 1's back-fill
    — regex too lax + pre-amend hash captured. Sprint 3 will fix; manually
    correcting hashes in the meantime.
