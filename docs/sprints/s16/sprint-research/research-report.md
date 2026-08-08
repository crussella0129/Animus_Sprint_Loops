# Sprint 16 Research Report

## Intents Reviewed
- [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) — created;
  relevance: defines the desired two-branch dependency-intake model; current
  state: `proposed`.
- [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) — revised;
  relevance: its substrate and `work → base` checkpoint remain valuable, but
  its dedicated dependency branch is replaced by INT-0003; current state:
  `superseded`.

## 1. Sprint Goal
Consolidate scheduled dependency updates onto the existing `work` branch so
Sprint Loops has one branch topology and one kind of corpus checkpoint. Remove
the dedicated dependency branch, its profile field, bootstrap behavior,
adapter override, tests, and operator terminology from every active bundle;
retarget hosted updater PRs to `work`; preserve the two GitHub Actions updates
already merged on the retiring remote branch; migrate this repository through
one ordinary Sprint 16 `dev → main` checkpoint; and leave finalized Sprint 15
and PR history truthful and unchanged.

## 2. Existing Code Survey
| File | Relevance | Notes |
|------|-----------|-------|
| `docs/intents/INT-0002-substrate-and-branch-model.md` | high | Realized authority that introduced the third branch; superseded rather than rewritten |
| `docs/sprints/s15/**` and `docs/work/completed-tasks.md` | high | Finalized provenance; must remain unchanged even though it records the former model |
| `.github/dependabot.yml` and `.github/workflows/ci.yml` | high | Live updater target is the retiring branch; CI currently filters PR bases to `main` only |
| `docs/work/remote-profile.md` | high | This repository's live profile declares the third branch and marker v1 |
| `{4 bundles}/schemas/remote-profile.md` | high | Public contract exposes an optional dependency branch; needs a strict v2 four-field shape |
| `{4 bundles}/scripts/remote-profile.sh` | high | Parses and emits the optional branch and silently ignores unknown keys today |
| `{4 bundles}/scripts/check-substrate.sh` | high | Makes the optional third branch part of substrate completeness |
| `{4 bundles}/scripts/deploy-substrate.sh` | high | Accepts branch flags, creates a third branch, and gates updater scaffolding on it |
| `{4 bundles}/scripts/remote-adapter.sh` | high | Its caller-supplied head override exists solely for a second checkpoint subtype |
| `{4 bundles}/scripts/sync-work-branch.sh` | medium | Behavior remains useful; only dependency-branch-specific rationale must be generalized |
| `{4 bundles}/scripts/{remote-profile,check-substrate,deploy-substrate,remote-adapter}.test.sh` | high | Fixtures encode the third branch and need positive two-branch plus regression coverage |
| `{claude,codex}/phases/01-init-sprint.md` | high | Substrate/deploy contract advertises an optional third branch |
| `{claude,codex}/phases/06-loop-phase.md` and `open-harnesses/particles/08-loop-phase.md` | high | Checkpoint remains work-to-base; resync wording still cites dependency-branch changes |
| `README.md` | high | Branch table and dependency-update section define the special branch/sprint path |
| `tools/{check-bundle-sync.sh,check-adapter-semantics.sh,run-guards.sh}` | high | Existing parity/canonical guards are the enforcement points for a no-remnants migration |
| Git commits `af3f473..e1b629e` | high | Third-branch work is interleaved with valuable substrate changes; no clean revert boundary exists |
| Remote PRs `#7`, `#8`, and `#9` | high | #7/#8 are merged only to the retiring branch; #9 merged `dev` to `main`, leaving `dev` one merge commit behind |

## 3. External Sources
- [GitHub Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) — `target-branch` makes Dependabot inspect that branch and open version-update PRs against it; it does not directly write the target. The same option does not reroute security updates.
- [GitHub: About the dependabot.yml file](https://docs.github.com/en/code-security/concepts/supply-chain-security/about-the-dependabot-yml-file) — GitHub reads the configuration from `.github/dependabot.yml` on the default branch, which determines the safe remote-deletion order.
- [Renovate configuration options](https://docs.renovatebot.com/configuration-options/#basebranchpatterns) — `baseBranchPatterns` is the current option for selecting a non-default branch such as `dev`; `baseBranches` is its former name.
- [GitHub: Deleting and restoring branches in a pull request](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request) — merged/closed PR branches can be deleted and restored, supporting a recoverable post-merge cleanup.

## 4. Risks, Unknowns, Dependencies
- **Risk — schema migration:** silently accepting the old optional field would
  preserve stale branch requirements. Use a v2 marker, strict known-field
  parsing, and an explicit failure for earlier profiles.
- **Risk — losing updates:** remote PRs #7/#8 placed `actions/checkout@v7` and
  `actions/upload-artifact@v7` only on the retiring branch. Reapply those two
  line changes on `dev` before deleting any ref.
- **Risk — unsafe deletion order:** `main` still tells Dependabot to target the
  retiring branch. Keep that branch until the green Sprint 16 checkpoint is
  merged and `main` contains the new configuration.
- **Risk — untested updater PRs:** this repository's workflow only names `main`
  in its `pull_request.branches` filter. Add `dev` so updater PRs can satisfy
  the green-before-merge boundary rule.
- **Risk — breaking useful substrate:** a wholesale Sprint 15 revert would
  remove the desired remote profile, bootstrap, adapters, resync, guards, and
  long-lived `dev → main` model along with the flawed branch.
- **Dependency — boundary synchronization:** live `dev` is one merge commit
  behind `main` after PR #9. Sync `main → dev` before Build changes are pushed.
- **Dependency — remote authority:** the final `dev → main` merge and subsequent
  remote branch deletion remain human-approved checkpoints under the current
  profile; local code and installation can complete before them.
- **Unknown resolved — open PR state:** the earlier report that #7/#8 were open
  is stale. Both are merged, all updater head branches are deleted, and there
  are currently zero open PRs or issues.

## 5. Recommended Approach
**Primary — targeted forward supersession.** Keep the Sprint 15 substrate and
replace only the dedicated dependency path. Introduce remote-profile v2 with
`provider`/`base`/`work`/`mergePolicy`; make substrate and deploy strictly
two-branch; scaffold Dependabot or Renovate against `work`; remove the remote
adapter's arbitrary checkpoint head; encode boundary intake in Init/operator
docs; update all four byte-identical bundles and their fixtures; and add a
canonical active-surface regression guard against revival of the retired
model. Migrate this repository's profile/config/CI, reapply the two Actions v7
changes as ordinary Sprint 16 work, run the deterministic suite, reinstall the
Codex bundle, and open one normal `dev → main` Sprint 16 PR.

After that PR is human-approved and merged, resync `main → dev`, verify both
branches carry the updater target and Actions versions, then delete the local
and remote dependency branch. The deletion is intentionally post-merge because
the default branch remains the live Dependabot authority until then.

**Alternative considered — revert Sprint 15 or its post-sprint commits.**
Rejected. The branch idea was introduced across the same commits as the useful
substrate, while post-sprint commits mixed updater behavior with quick-start,
mdBook, installer, and adapter improvements. Reverting would either destroy
good architecture or leave partial remnants. A forward intent supersession and
active-surface guard is smaller, auditable, and honest.

## Artifacts
- [INT-0003](../../../intents/INT-0003-dependency-updates-on-work.md) — new
  semantic authority for the consolidated model.
- [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) — preserved
  realized history, now explicitly superseded.
- GitHub PR evidence: [#7](https://github.com/crussella0129/Animus_Sprint_Loops/pull/7),
  [#8](https://github.com/crussella0129/Animus_Sprint_Loops/pull/8), and
  [#9](https://github.com/crussella0129/Animus_Sprint_Loops/pull/9).

## Budget Override
The survey exceeds the 20-file nominal cap only when the four required
self-contained bundles and their byte-identical tests are counted physically.
They form one cross-cutting public contract enforced by `check-bundle-sync.sh`;
grouping mirrored paths above avoids pretending a single adapter is the whole
surface while preserving the necessary no-remnants audit.
