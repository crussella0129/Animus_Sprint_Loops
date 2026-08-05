# Sprint 1 Research Report

## 1. Sprint Goal

Close the highest-friction follow-ups from sprint 0 and the most concrete
protocol gap surfaced by today's survey: (a) make `commit-task.sh` back-fill
each task's commit hash into `completed-tasks.md` automatically, and (b)
implement the abort path that the `/loop-sprint` command already advertises but
no script supports today. Sync changes to all three bundles and extend
`selftest.sh` to cover the new abort transition.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| `open-harnesses/scripts/commit-task.sh` | **high** | 9-line helper; runs `git commit` and stops. No hash back-fill. The friction this caused in sprint 0 is visible as three manual back-fill edits in the git log. |
| `claude-code/commands/loop-sprint.md` | **high** | Documents an `abort` subcommand that maps to "mark current sprint as aborted in sprint-meta.md and close it out" — but no `scripts/abort-sprint.sh` exists; there is no documented procedure for what "close it out" entails. |
| `open-harnesses/scripts/` (full listing) | medium | Today: `commit-task.sh`, `current-phase.sh`, `current-sprint.sh`, `finalize-plan.sh`, `init-sprint.sh`, `selftest.sh`, `update-confidence.sh`. No `abort-sprint.sh`. |
| `open-harnesses/scripts/current-phase.sh` | medium | The Exit-status grep already accepts `aborted` (matches `success\|failed\|aborted`), so once `sprint-meta.md` is set to `aborted` the routing correctly reports `ready-for-next-sprint`. No script change needed in `current-phase.sh` to support abort. |
| `open-harnesses/scripts/selftest.sh` | medium | Drives 8 transitions but exercises only the `success` exit. The `aborted` branch is unverified. |
| `open-harnesses/particles/08-loop-phase.md`, skill bundles' `phases/06-loop-phase.md` | medium | Loop Phase says set exit status to `success` or `failed` — does not mention `aborted` as a path. Need a brief addition. |
| `sprints/s0/sprint-tests/test-report.md` | high | Source of the two technical-debt items inherited into this sprint's goal. |
| `decisions.md` | low | Sprint 0's ADR notes the empty-build-plan edge case as a consequence. Out of scope here; flagged again. |

## 3. External Sources

None. Both work items are entirely internal: a small shell-script change and a
protocol-documentation addition. The budget permits up to 5 external sources;
0 were needed.

## 4. Risks, Unknowns, Dependencies

- **Risk:** *`git commit --amend` interaction with hooks.* If the repo grows pre-commit hooks, amend re-runs them. Mitigation: this repo has no such hooks today; if added later, the amend is a no-op for any hook that hashes the same set of files.
- **Risk:** *Backwards compatibility with sprint 0 entries.* The back-fill only acts when the literal `PENDING` token is present in `completed-tasks.md`; sprint 0 entries (already filled) are untouched.
- **Risk:** *Mid-sprint helper version skew.* This sprint's own commits will use the OLD `commit-task.sh` (no back-fill), because the personal install at `~/.claude/skills/loop-sprint/scripts/` is what runs. The new version takes effect from sprint 2 onward — the same pattern as sprint 0's `current-phase.sh` fix. Sprint 1's hashes will be filled manually one last time.
- **Unknown:** *What `abort` should preserve.* Open question: should an aborted sprint preserve its plans (so the next sprint can resume) or discard them? Decision below: preserve. An abort is a "stop, retry later" signal, not a "this was a bad idea" signal — for the latter, the protocol's existing failure-report path is the right tool.
- **Dependency:** `git rev-parse`, `sed`. Already used elsewhere in the helpers.

## 5. Recommended Approach

**Primary:** Three elementary build tasks.

1. *Hash back-fill in `commit-task.sh`.* After the commit, capture the short
   hash, replace the first `Commit:** PENDING` in
   `agent-tasks/completed-tasks.md` with the actual hash, and amend the same
   commit. Scheme detailed in `backfill-scheme.md`.

2. *Abort path.* Add `scripts/abort-sprint.sh` that sets
   `sprint-meta.md` Exit status to `aborted`, records an end timestamp, appends
   an abort note (taking a one-line reason as `$1`), and commits with a
   `sprint-N: aborted — <reason>` message. Update the Loop Phase file to
   acknowledge `aborted` as a legitimate exit status, and add a one-line
   pointer to `abort-sprint.sh` from the Build Phase file (where abort is most
   likely to be invoked).

3. *Sync + selftest extension.* Copy `commit-task.sh` and new `abort-sprint.sh`
   into both bundles. Extend `selftest.sh` with a 9th step that aborts a
   freshly-initialized sprint and verifies `current-phase.sh` reports
   `ready-for-next-sprint`.

**Alternatives considered:**

- *Two commits per task instead of amend* (one for the task diff, one for the
  back-fill). Rejected: violates the protocol's one-commit-per-task contract
  and doubles the commit-log noise for a purely cosmetic write.
- *Drop the abort path entirely and remove `abort` from the command's
  documentation.* Rejected: aborting a sprint mid-flight is a real operational
  need (e.g., user changes mind, external blocker discovered). Better to
  implement it than retract the feature.
- *Address the empty-build-plan edge case in this sprint.* Deferred: the fix
  belongs in `finalize-plan.sh` (refuse to lock a plan with zero `T-XXX`
  entries) and is straightforward, but bundling it with the abort work would
  push to four build tasks and break elementary granularity. Flagged as a
  sprint 2 candidate.

**Rationale:** Two follow-ups that materially reduce friction (hash back-fill)
and close a real feature gap (abort) — both small, both testable, both
syncable in one task each. Together they make the skill more honest: the
command does what it says, and the protocol's bookkeeping doesn't ask the
agent to backfill hashes by hand.

## Artifacts

- `backfill-scheme.md` — design notes for the `commit-task.sh` change, with the proposed sed-based first-occurrence rule and rationale for using `git commit --amend`.
