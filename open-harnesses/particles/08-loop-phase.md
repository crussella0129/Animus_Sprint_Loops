# Particle: Loop Phase

```
"Reconcile each sprint intent against its acceptance criteria and completion/code/test/documentation evidence. Move an eligible intent to realized, or retain active/defer it with a reason, and append Transition history. Record durable rationale, alternatives, and consequences in the stable intent; create and navigate a new intent for a distinct outcome. Append deferred executable work to docs/work/tasks.md as (backlog) [intent: INT-NNNN]. Optionally invoke update-confidence.sh, commit coherent remaining Book updates with a scoped boundary, and require check-book.sh to pass. Unless already aborted, then invoke the installed bundle's scripts/close-sprint.sh <success|failed> \"<one-line completion evidence>\" helper from the project root; success requires a test report with final clean/proceed-with-caveats critique and failed requires failure-report provenance. Invoke current-phase.sh and require ready-for-next-sprint. Then open exactly one work -> base PR/MR via the installed bundle's scripts/remote-adapter.sh open-pr, driven by the remote profile (schemas/remote-profile.md): at most one per sprint, never merged under mergePolicy human-approve, and no per-sprint branch created; after a merge to base, scripts/sync-work-branch.sh resyncs work. At the resulting sprint boundary, hosted-updater PRs targeting work are intake only: never merge them during an active sprint; merge only when current and green under the remote-authority boundary; keep red intake unmerged and repair its head until green; if the provider prevents head repair, use an ordinary dependency-only sprint on work and supersede the unmergeable updater PR, with no checkpoint or sprint subtype. Compact context by selecting only Book evidence relevant to the next Research Phase."
```

Schemas: [`../schemas/intent.md`](../schemas/intent.md),
[`../schemas/agent-tasks.md`](../schemas/agent-tasks.md), and
[`../schemas/sprint-meta.md`](../schemas/sprint-meta.md).
Helpers: [`../scripts/close-sprint.sh`](../scripts/close-sprint.sh),
[`../scripts/update-confidence.sh`](../scripts/update-confidence.sh),
[`../scripts/check-book.sh`](../scripts/check-book.sh), and
[`../scripts/current-phase.sh`](../scripts/current-phase.sh).

---

Loop closed. Re-inject `01-init-sprint.md` for sprint N+1.

## Turn Contract

A sprint is one turn. Once a sprint is open, continue through its phases and
stop only at one of four boundaries: a blocking product ambiguity, a claim that
needs human judgment to verify, an explicit abort, or the merge boundary once
the checkpoint is open under `mergePolicy: human-approve`. The contract is
advisory — no helper runs when a turn simply ends — but the evidence a premature
stop leaves behind is enforced: `substrate-outdated` and `substrate-misplaced`
are reported before routing, the checkpoint is refused while the sprint is open,
plan finalization and sprint close are refused while the Book carries
uncommitted state, and a task commit is refused from any branch that is not the
profile's work branch.

