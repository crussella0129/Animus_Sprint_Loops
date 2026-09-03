# INT-0012 — CI that exists from Sprint 0 and tracks what the project actually is

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0012
- **State:** active
- **Work evidence:** [T-164–T-167 build plan](../sprints/s20/sprint-plans/build-plan.md#execution-sequence), [Sprint 20 test plan](../sprints/s20/sprint-plans/test-plan.md)
- **Completion evidence:** [T-164–T-167 completion records](../work/completed-tasks.md#t-164-sprint-20)
- **Code evidence:** [language detection](../../open-harnesses/scripts/detect-languages.sh), [the per-host generator](../../open-harnesses/scripts/scaffold-ci.sh), [the convergence step](../../open-harnesses/scripts/deploy-substrate.sh)
- **Test evidence:** [Sprint 20 test report](../sprints/s20/sprint-tests/test-report.md), [Sprint 20 E2E record](../sprints/s20/sprint-tests/e2e-tests.md)
- **Documentation evidence:** [CI exists from Sprint 0](../../README.md#ci-exists-from-sprint-0), [Init phase contract](../../claude-code/skills/sprint-loop/phases/01-init-sprint.md)

## Intent
Every Sprint Loops project should have working continuous integration from
Sprint 0, on whichever host it lives on, covering the languages and platforms it
actually uses — and that configuration should stay true as the project changes,
rather than being a one-shot guess made on day one.

1. **Per-provider CI at Sprint 0.** Convergence writes the host's own CI
   configuration, create-if-absent and never clobbering: GitHub Actions under
   `.github/workflows/`, GitLab CI as `.gitlab-ci.yml`, Gitea and Forgejo
   Actions under their own workflow directories, and for `generic` a portable
   runner script plus a documented manual step. `local-only` gets none, because
   it genuinely has no host. Gitea and Forgejo Actions consume GitHub Actions
   workflow syntax, so the four hosts are really **two formats** — Actions YAML
   and GitLab CI — differing for three of them only by directory.

   "Never clobbering" is **directory-level, not file-level**: if the host's
   workflow directory already holds any workflow, generate nothing. A
   file-level check would add a second workflow beside a project's hand-written
   one, leaving two CI systems disagreeing about the same push.
2. **Language and platform detection.** Which jobs are written follows from what
   the project contains — `Cargo.toml`, `go.mod`, `pyproject.toml`,
   `package.json`, shell scripts, and so on — and from the platforms the project
   targets, not from a fixed template. Detection is manifest-driven and sorted,
   because the canonical runner's determinism meta-check compares normalized
   output across two runs.

   A **fresh project has no canonical suite**, so generated jobs run
   language-native commands and prefer a canonical runner only when one is
   already present. Requiring one would make the first sprint of every new
   project impossible.

   Triggers are read from the remote profile's `base` and `work`, never
   hardcoded: a workflow that triggers only on `base` never runs on the branch
   sprints commit to, nor on the checkpoint itself.
3. **Reconciliation over the project's life.** As intents introduce a new
   language or a new platform target, the missing jobs are added; as a language
   or target genuinely leaves the project, its jobs are removed. This is a
   recurring check with a reported diagnosis, not a Sprint 0 event: the question
   "does this project's CI still match what this project is?" has an answer at
   every sprint boundary.
4. **Removal is proposed, never silent.** Adding a missing job is safe. Deleting
   one is not — a workflow may exist for a reason the detector cannot see. The
   reconciler reports a job it believes is unneeded and why; a human or an
   explicit intent authorizes the removal.

Verifying that the configuration can actually fail — the workflow triggers on
the right branches, invokes the canonical suite, swallows nothing, and a head
SHA with zero observed checks is not a pass — belongs to
[INT-0006](INT-0006-provider-reach-and-ci-truth.md). This intent covers what is
generated and how it stays current.

## Acceptance criteria
- A fresh project on each supported provider converges to a CI configuration in
  that host's own format, and a project on `local-only` gets none.
- The generated configuration runs the languages the project actually contains;
  a fixture project per language produces a job whose failure is observable when
  that language's tests fail.
- An existing CI configuration is never clobbered or rewritten by convergence.
- After a project gains a language, the reconciler reports the missing job by
  name; after it loses one, the reconciler reports the now-unneeded job by name
  and does not delete it on its own.
- The reconciliation runs at a sprint boundary, and its diagnosis is readable
  without running a sprint.
- A project whose CI configuration is hand-written and complete produces a clean
  reconciliation, with no proposal to add or remove anything.

## Rationale
Sprint 0 currently scaffolds a dependency-updater config and no CI at all, so a
fresh project's first checkpoint is green by absence — the exact false positive
that makes a reviewer's trust worthless. Observed repeatedly on real projects:
Sprint Loops set up against GitHub without the right workflow files present.

The lifecycle half matters as much as the bootstrap half. A project's language
set is not static: an intent introduces a service in a new language, or a
platform target is added or dropped, and CI written at Sprint 0 silently stops
describing the project. Because a Sprint Loops project already records its
intended outcomes in the Book, the information needed to notice that drift is
present — this intent connects it to the configuration that is supposed to
verify it.

Removal is deliberately asymmetric with addition. A missing job is a gap the
detector can prove; an extra job may encode a requirement no manifest reveals —
a nightly platform check, a security scan, a deployment. Proposing removal and
requiring authorization keeps the reconciler from deleting the thing that was
protecting the project.

## Alternatives
- **One universal workflow for every project.** Either runs nothing useful or
  fails on most projects. Language detection is the minimum that produces a
  configuration worth trusting.
- **Scaffold once at Sprint 0 and never revisit.** What exists today for the
  updater config. It leaves CI describing the project as it was on day one.
- **Reconcile automatically, including deletions.** Faster, and it eventually
  deletes a workflow that was load-bearing for a reason not visible in any
  manifest.
- **Delegate entirely to the host's starter templates.** Each host's defaults
  differ, none of them know the project's canonical suite, and it puts the
  configuration outside the Book's reach for reconciliation.

## Consequences
- Language detection is heuristic and will occasionally scaffold a job a project
  does not want. Create-if-absent plus never-clobber keeps that recoverable: the
  operator deletes it and it is not recreated.
- Generated CI must invoke the project's canonical suite, so a project without
  one gets a configuration that runs nothing meaningful. Naming the canonical
  suite becomes part of what a complete substrate means.
- Supporting four host formats means four generators and four fixture sets, and
  each new host is real ongoing cost. That argues for a small shared job model
  rendered per host rather than four hand-written templates.
- The reconciler reads the Book to learn a project's intended languages and
  targets, which makes intent chapters load-bearing for configuration. An intent
  that introduces a language without saying so will not be noticed.

## Transition history
- 2026-09-03: created as `proposed` — derived from operator feedback item 9.a
  and from the pre-merge review of Sprint 18, where the operator reported real
  projects set up against GitHub without the right workflow files and asked that
  every supported host reach a comprehensive CI base at Sprint 0, with the
  configuration adding and subtracting jobs as the project's languages and
  platform targets change. Split from
  [INT-0006](INT-0006-provider-reach-and-ci-truth.md), which keeps knowing and
  reaching the provider and refusing an unverified green.
- 2026-09-03: revised during Sprint 20 Research — recorded that Gitea and
  Forgejo share GitHub's workflow syntax so the four hosts are two formats;
  that no-clobber must be directory-level or a generated workflow can sit beside
  a hand-written one; that a fresh project has no canonical suite, so generated
  jobs must be language-native and prefer a runner only when present; and that
  triggers must come from the remote profile so CI actually runs on the work
  branch and the checkpoint.
- 2026-09-03: `proposed → planned` — Sprint 20 tasks T-164–T-167 cover
  contract 4, language detection, the per-host generator, the convergence step,
  and the operator contracts. Reconciliation and proposed removal (parts 3 and
  4) are deliberately out of that sprint, so this intent will remain `active` at
  its close. The acceptance criterion asking for an observable job failure is
  met only for the `generic` provider, whose output is an executable script;
  for the YAML hosts it needs INT-0006's CI truth check and a real hosted run.
- 2026-09-03: `planned → active` — Build began with T-164, contract 4 and
  manifest-driven language detection.
- 2026-09-03: Sprint 20 delivered generation — T-164 through T-167 — and the
  intent remains `active`. Parts 3 and 4, reconciling jobs as a project's
  languages change and proposing rather than performing removals, are untouched.
  The criterion asking for an observable job failure is met only for `generic`,
  whose output is an executable script; for the four YAML hosts the sprint proves
  the generated file carries the language's real commands, and closing that gap
  needs INT-0006's CI truth check plus a real hosted run. CI green on both legs
  for head `51fb955`.
