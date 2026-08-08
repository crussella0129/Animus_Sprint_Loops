# INT-0003 — One sprint path for dependency updates

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0003
- **State:** active
- **Work evidence:** [T-130–T-135 build plan](../sprints/s16/sprint-plans/build-plan.md#execution-sequence)
- **Completion evidence:** none
- **Code evidence:** [T-130–T-135 completed records](../work/completed-tasks.md#t-130-sprint-16)
- **Test evidence:** [Sprint 16 test report](../sprints/s16/sprint-tests/test-report.md)
- **Documentation evidence:** [Dependency updates on work](../../README.md#dependency-updates-on-work)

## Intent
Keep Sprint Loops on one long-lived integration path: `work` is the only branch
that accepts ordinary sprint work and scheduled dependency-version intake;
`base` is reached only through the normal `work → base` sprint checkpoint.
Hosted updaters propose changes in PRs/MRs targeting `work`; they do not become
a second writer merely by opening those requests. The skill has no dedicated
dependency branch, dependency checkpoint, or dependency-sprint subtype.

At a sprint boundary, an updater PR targeting `work` is merged only when it is
current and green. A red updater PR remains unmerged and is repaired on its PR
head until green; when the host does not permit that repair, an ordinary
dependency-only sprint reproduces and fixes the update on `work`, then
supersedes the updater PR. No updater PR is merged in the middle of an active
sprint. The adapter's existing remote-authority and merge-policy boundaries
still govern every remote mutation.

Non-goals: rewriting published Git or finalized sprint provenance; removing
ephemeral updater-created PR heads; enabling automatic merges; weakening CI or
branch protections; or changing the five-phase loop.

## Acceptance criteria
- The remote-profile v2 contract contains exactly `provider`, `base`, `work`,
  and optional `mergePolicy`; substrate completeness requires exactly the
  configured `base` and `work` branches and no third long-lived branch.
- Sprint 0 deploy creates only `base` and `work`, and for hosted providers its
  create-if-absent updater configuration targets `work`; `local-only` creates
  no updater configuration, and an existing configuration is never clobbered.
- The phase and operator contracts state the boundary intake rule: merge an
  updater PR into `work` only when current and green; keep a red PR unmerged and
  repair it until green; never merge updater intake during an active sprint.
- `remote-adapter.sh` opens only the profile-defined `work → base` checkpoint
  and accepts no caller override that creates a checkpoint subtype.
- Every corpus checkpoint remains one ordinary sprint PR/MR from `work` to
  `base`; a dependency-only change uses the same sprint, plans, evidence, and
  checkpoint as any other work.
- This repository targets Dependabot version-update PRs at `dev`, runs CI for
  PRs targeting `dev`, carries the already-tested GitHub Actions v7 updates
  into the Sprint 16 `dev → main` checkpoint, and retains only `main` and `dev`
  as long-lived branches after that checkpoint merges.
- The canonical guards fail if the retired dependency-branch model reappears
  in an active adapter, schema, script, phase, root operator guide, updater
  configuration, or live remote profile; finalized sprint and Git/PR history
  remain unchanged.

## Rationale
The dedicated dependency branch was justified as protection against an updater
concurrently writing `work`. That premise was wrong for the hosted tools in
scope: Dependabot and Renovate open PRs/MRs against their configured target;
the target changes only when an authorized merge occurs. Scheduling those
merges at sprint boundaries preserves the single-writer discipline without a
parallel branch topology.

Consolidation removes a forced two-checkpoint path and the resulting special
terminology. It is also more flexible: routine green updates can ride the next
ordinary sprint, while a risky update can still occupy its own ordinary sprint
without changing the protocol.

## Alternatives
- **Revert Sprint 15 wholesale.** Rejected: the third branch was interwoven
  with the valuable substrate gate, transactional deploy, remote profile,
  provider adapters, boundary resync, parity checks, and test suites. A revert
  would discard the desired `dev → main` model as well as the flawed part.
- **Keep a third branch as an optional profile field.** Rejected: optionality
  leaves two active mental models, permits stale branch artifacts, and keeps
  the checkpoint override that created sprint subtypes.
- **Send scheduled updates directly to `base`.** Rejected: it bypasses the
  ordinary sprint integration path. Platform-mandated security-update behavior
  remains a host constraint rather than a Sprint Loops branch subtype.
- **Rewrite published history to erase the former model.** Rejected: finalized
  sprint records and merged PRs are truthful provenance. Current authority is
  changed by supersession and forward migration.

## Consequences
- Remote profiles move to marker/version 2 and the four-field shape. Earlier
  profiles require an explicit rewrite rather than silently retaining an
  unknown branch field.
- Hosted updater scaffolds target `work`; GitHub Dependabot uses
  `target-branch`, while Renovate uses its current `baseBranchPatterns` option.
- Projects must ensure CI runs for PRs whose base is `work`, not only for PRs
  whose base is the default branch.
- Boundary discipline replaces topology: updater PRs are reviewed and merged
  between sprints, never while sprint writes are active.
- GitHub routes Dependabot security-update PRs to the default branch even when
  scheduled version updates target another branch. That provider constraint is
  handled by the normal `base → work` resync and does not create a special
  Sprint Loops branch or sprint type.
- This repository's remote dependency branch is deleted only after Sprint 16
  reaches `main`, because GitHub reads `.github/dependabot.yml` from the default
  branch and the two Actions v7 changes must first be preserved on `dev`.

## Transition history
- 2026-08-08: created as `proposed` — Sprint 16 research found that hosted
  updaters propose PRs instead of mutating their target branch, so the
  dedicated dependency branch's concurrency rationale did not justify its
  mandatory second checkpoint and sprint subtype.
- 2026-08-08: `proposed → planned` — Sprint 16 tasks T-130–T-135 cover the
  strict profile contract, two-branch substrate/deploy behavior, one checkpoint
  path, live repository migration, regression enforcement, and Codex delivery.
- 2026-08-08: `planned → active` — Build began with T-130, the strict
  remote-profile v2 contract and resolver.
- 2026-08-08: implementation and pre-checkpoint verification completed —
  T-130–T-135, the installed Codex delivery, and the hosted Ubuntu/macOS guard
  matrix are green. The intent remains `active` until the human-approved
  checkpoint unlocks M-001 and the final remote-topology assertions.
