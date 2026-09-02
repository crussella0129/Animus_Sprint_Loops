# INT-0006 — Checkpoints without a vendor CLI, and CI that can actually fail

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0006
- **State:** proposed
- **Work evidence:** none
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** none
- **Documentation evidence:** none

## Intent
Two failures that both end with a human doing the machine's job: an environment
that cannot open its own checkpoint, and a checkpoint that reports green because
nothing ran.

1. **A third provider tier.** Beneath `gh` and `glab`, add a direct REST path
   using `curl` and a token from the environment, then the prefilled compare
   URL, then a `sprint-checkpoint.md` handoff artifact in the sprint record
   carrying the exact title and body. Any environment with a shell finishes its
   own sprint; any environment without a token hands off verbatim instead of
   improvising.
2. **Language-aware CI scaffolding at convergence.** Detect project languages
   from their manifests and write a workflow create-if-absent, patterned on this
   repository's canonical-runner design. Never clobber an existing workflow.
3. **A CI truth check.** A helper asserts the properties that produce false
   greens: the workflow must trigger on pull requests targeting both `base` and
   `work`; it must invoke the project's canonical suite; it must not neutralize
   failure with `continue-on-error` or a trailing `|| true`; and a head SHA with
   zero observed checks is not a pass.
4. **Best-effort base protection.** Convergence attempts provider branch
   protection where the CLI, permissions, and host allow it, and records the
   outcome — `enforced`, `unavailable`, or `declined` — in the remote profile,
   printing manual steps when it cannot.

## Acceptance criteria
- With no provider CLI installed but a token present, a checkpoint is opened
  through the REST path with the same title and body the CLI path produces.
- With neither CLI nor token, the work branch is pushed, a prefilled compare URL
  is printed, and `sprint-checkpoint.md` contains the exact title and body.
- Per-language fixture projects converge to a workflow whose test job fails when
  the project's tests fail.
- A workflow missing the work-branch trigger, missing the canonical suite
  invocation, or swallowing failure is rejected with a diagnostic naming which
  property failed.
- A test report cannot record a passing CI conclusion for a head SHA against
  which zero checks were observed.
- Base protection outcome is readable from the remote profile after
  convergence, on every provider value including `local-only`.

## Rationale
VS Code fork environments — Antigravity, Cursor — have terminals; what they lack
is an authenticated vendor CLI. Treating the CLI as the only automated path
forces the sprint to end with a handoff to another agent or to the operator,
which breaks the one-sprint-per-turn property from INT-0005 for reasons that
have nothing to do with the loop. A token and `curl` are available nearly
everywhere the CLI is not.

The CI half is the same failure in a different place: a checkpoint that looks
green because no workflow was configured to run against that branch is worse
than a red one, because it consumes the reviewer's trust. Sprint 0 currently
scaffolds an updater config but no CI, so a fresh project's first checkpoint is
green by absence.

## Alternatives
- **Require the vendor CLI.** Simple and already implemented; it is what
  produces the handoff. Rejected as the sole path, retained as the preferred
  one when present.
- **Ship a provider SDK.** Contradicts the bundle's dependency-free premise.
  `curl` is already assumed by the environments in question.
- **Scaffold one universal workflow.** A single generic workflow either runs
  nothing useful or fails on most projects. Language detection is the minimum
  that produces a workflow worth trusting.
- **Fail the sprint when CI is unverifiable.** Too strict for `local-only` and
  generic hosts, where there is no CI to verify. The check binds where a
  provider is declared.

## Consequences
- The environment must be able to hold a token, and the skill must never read,
  print, or record its value — only its presence. Any implementation that echoes
  the token into a log or a Book artifact is a defect.
- Language detection is heuristic and will occasionally scaffold a workflow a
  project does not want. Create-if-absent plus never-clobber keeps that
  recoverable; the operator deletes it and it is not recreated.
- Server-side protection cannot be a hard gate, because it needs authentication,
  repository permission, and a host that offers it. The enforceable half of
  branch discipline stays local, in INT-0005.
- The zero-checks rule will block closes on repositories that legitimately run
  no CI. It binds only where the remote profile declares a provider with CI.

## Transition history
- 2026-09-02: created as `proposed` — derived from operator feedback items 7.a
  and 9.a, and carrying the remote half of item 2.a that INT-0005 leaves out.
