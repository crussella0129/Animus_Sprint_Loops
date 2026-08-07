# INT-0002 — Sprint Loops substrate: bootstrap gate, branch model, and provider-agnostic checkpoints

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0002
- **State:** planned
- **Work evidence:** [Sprint 15 build plan](../sprints/s15/sprint-plans/build-plan.md), [Sprint 15 test plan](../sprints/s15/sprint-plans/test-plan.md)
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** [Sprint 15 test report](../sprints/s15/sprint-tests/test-report.md)
- **Documentation evidence:** none

## Intent
Give Sprint Loops a first-class **substrate layer** so the branch topology,
bootstrap, and remote-checkpoint behavior live in the skill instead of being
reinvented per project. Four parts:

1. **Deterministic substrate gate.** Before any phase routing, a helper answers
   one question — *is this a live Sprint Loops project?* — by checking the Book,
   the work ledgers, the required branches, and a declared remote profile. If
   complete, hand off to `current-phase.sh`; if not, run Sprint 0 deploy.
2. **Sprint 0 deploy (owned by the skill).** An idempotent bootstrap that creates
   the Book scaffold, the branch topology (`main`, `dev`, optional `bump`), the
   ledgers, the remote profile, and the first real sprint. This replaces the
   external, per-project Sprint 0 instructions.
3. **Long-lived branch model.** `main` is the PR/MR-gated corpus; `dev` is where
   sprints commit and push at any time; `bump` is the Dependabot target. Each
   sprint opens **exactly one `dev→main` PR/MR** as its reversible checkpoint;
   after that merge, `dev` resyncs from `main`. The skill creates **no
   per-sprint branches**.
4. **Provider-agnostic checkpoints.** A Book-tracked remote profile declares the
   provider (`gh`/`glab`/generic), branch names, and merge policy. The Loop
   phase opens one PR/MR per sprint via the declared provider and stops for a
   human to approve the merge.

Non-goals: this intent does not change the five-phase loop, does not auto-merge
to `main` by default, and does not build the GECK launcher (GECK separately
becomes a wizard that emits the README loop-config that names a profile).

## Acceptance criteria
- A deterministic substrate check runs as the first routing step and yields
  `substrate-complete` (→ normal phase routing) or `substrate-absent` (→ Sprint 0
  deploy), with a specific diagnostic for a partial/broken substrate.
- Sprint 0 deploy idempotently produces a valid Book, `main`/`dev`/`bump`
  branches (bump optional), ledgers, a remote profile, and the first sprint;
  re-running it is a no-op.
- No skill script creates a per-sprint branch. Sprints operate on `dev`; a sprint
  close opens exactly one `dev→main` PR/MR and refuses to open a second for the
  same sprint.
- The remote profile selects the provider adapter (`gh`, `glab`, or a generic
  push-and-print-URL fallback), supplies branch names, and sets merge policy
  (default: human-approve).
- Dependency updates flow `bump →(fix)→ PR → main`; `dev` inherits them only via
  a boundary `main→dev` resync, and no writer other than the running sprint
  mutates `dev`.
- The bootstrap/branch/checkpoint instructions live in the skill bundles, not an
  external repository, and are covered by the canonical guard suite.

## Rationale
The skill today creates zero branches and closes sprints with local commits
only; every remote and branch decision is deferred to a one-line authority
boundary (`SKILL.md`) and to per-project improvisation. In practice that yielded
per-sprint branches and no PR in a downstream project (`contrapunctus`), and a
Sprint 0 that lives in a separate repo (`Animus_GECK`). Centralizing the
substrate makes histories consistent, gives every project the same reversible
`dev→main` checkpoints, and lets the "preauthorized-remote profile" the skill
already references finally have a schema.

## Alternatives
- **Per-sprint branches → PR to main.** Rejected: no persistent integration
  branch, and the checkpoint diffs muddle as sprints accumulate; it is the
  pattern being moved away from.
- **`dev` runs ahead of `main` with no resync.** Rejected: per-sprint PR diffs
  drift and `dev` misses `bump` fixes until a conflict forces a sync.
- **GitHub-only PR logic (`gh`).** Rejected: must also serve GitLab and arbitrary
  remotes; the profile abstraction is required.
- **Dependabot/`bump` pushes straight into `dev`.** Rejected: two concurrent
  writers on `dev` is the actual race; `main` must be the single confluence.
- **Keep Sprint 0 in `Animus_GECK`.** Rejected: that split is the disconnect this
  intent removes.

## Consequences
- New shared scripts (substrate check, Sprint 0 deploy, remote-profile resolver,
  provider adapters) and a Sprint 0/bootstrap phase, propagated across the four
  bundles under existing parity rules.
- A remote-profile schema and a decision about where it is tracked in the Book.
- Provider adapters add optional external CLI dependencies (`gh`, `glab`) only
  where a project selects them; the generic fallback stays dependency-free.
- Downstream projects must declare a profile (or accept a local-only default);
  `Animus_GECK` shrinks to a config wizard.
- Merges to `main` remain human-gated by default, preserving the corpus as a
  user-controlled, reversible checkpoint boundary.

## Transition history
- 2026-08-06: created as `proposed` — Sprint 15 research selected this substrate
  gap (branch/bootstrap/checkpoint layer absent from the skill) as the sprint
  goal; design decisions (long-lived `dev` with post-merge resync; GitHub +
  GitLab + generic providers; human-approved `dev→main` merges) locked with the
  project owner.
- 2026-08-06: `proposed → planned` — the sprint 15 build and test plans
  (T-122–T-129) were drafted around this intent and linked as Work evidence.
- 2026-08-06: `planned → active` — Sprint 15 Build began implementing the
  substrate layer (starting with T-122, the remote-profile contract).
