# INT-0006 — Know the provider, reach it without a vendor CLI, and never trust a green that never ran

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0006
- **State:** planned
- **Work evidence:** [T-157–T-160 build plan](../sprints/s19/sprint-plans/build-plan.md#execution-sequence), [Sprint 19 test plan](../sprints/s19/sprint-plans/test-plan.md)
- **Completion evidence:** none
- **Code evidence:** none
- **Test evidence:** none
- **Documentation evidence:** none

## Intent
Three failures that all end with a human doing the machine's job: a project that
does not know which provider it is on, an environment that cannot open its own
checkpoint, and a checkpoint that reports green because nothing ran.

1. **Provider detection at Sprint 0.** `deploy-substrate.sh` defaults
   `PROVIDER=local-only`, and the Init contract instructs the agent to run it
   with no arguments — so a repository whose `origin` is `github.com` is written
   into its own Book as `local-only`, permanently. Convergence must infer the
   provider from the `origin` remote when one is not supplied, record what it
   inferred and from what, and refuse to guess silently. A project with no
   remote is `local-only` because it genuinely is, not by default.
2. **A provider enum that covers the hosts in use.** `github`, `gitlab`,
   `generic`, and `local-only` omit Gitea and Forgejo, which are neither GitHub
   nor "generic" — they have their own API shape and their own CI directory.
   Add them rather than flattening them into `generic`. They are values a
   project **declares**, not values inference can produce: both are
   overwhelmingly self-hosted on arbitrary domains, so no URL pattern
   identifies them the way `github.com` identifies GitHub.
3. **A third provider tier beneath the vendor CLIs.** Add a direct REST path
   using `curl` and a token from the environment, then the prefilled compare URL,
   then a `sprint-checkpoint.md` handoff artifact in the sprint record carrying
   the exact title and body. Any environment with a shell finishes its own
   sprint; any environment without a token hands off verbatim instead of
   improvising.
4. **A CI truth check.** Assert the properties that produce false greens: the
   workflow must trigger on requests targeting both `base` and `work`; it must
   invoke the project's canonical suite; it must not neutralize failure with
   `continue-on-error` or a trailing `|| true`; and a head SHA with **zero
   observed checks is not a pass**.
5. **Best-effort base protection.** Convergence attempts provider branch
   protection where the CLI, permissions, and host allow it, and records the
   outcome — `enforced`, `unavailable`, or `declined` — in the remote profile,
   printing manual steps when it cannot.

Generating the CI configuration itself belongs to
[INT-0012](INT-0012-ci-scaffolding-lifecycle.md); this intent covers knowing the
provider, reaching it, and refusing to believe a green that never ran.

## Acceptance criteria
- Convergence run with no `--provider` in a repository whose `origin` is a
  GitHub, GitLab, Gitea, or Forgejo URL writes that provider into the profile,
  and records the URL it inferred from.
- Convergence run with no `--provider` and no `origin` writes `local-only`.
- Convergence run with no `--provider` against a remote whose host is not
  recognized writes `generic`, never `local-only` — an unrecognized host still
  pushes and prints a compare URL, while `local-only` does nothing at all.
- An explicit `--provider` always wins over inference.
- A profile already written stays authoritative: convergence reports a
  disagreement between the recorded provider and the current `origin` rather
  than silently rewriting it.
- `remote-profile.sh` accepts `gitea` and `forgejo` and rejects an unknown value
  with a diagnostic naming the accepted set.
- With no provider CLI installed but a token present, a checkpoint is opened
  through the REST path with the same title and body the CLI path produces.
- With neither CLI nor token, the work branch is pushed, a prefilled compare URL
  is printed, and `sprint-checkpoint.md` carries the exact title and body.
- A workflow missing the work-branch trigger, missing the canonical suite
  invocation, or swallowing failure is rejected with a diagnostic naming which
  property failed.
- A test report cannot record a passing CI conclusion for a head SHA against
  which zero checks were observed.
- The base-protection outcome is readable from the remote profile after
  convergence, on every provider value including `local-only`.

## Rationale
The provider default is the highest-consequence defect found so far, and it is
deterministic rather than an agent error. Reproduced at Sprint 18's close: a
fresh `git init` with `origin` set to a GitHub URL, converged exactly as the Init
contract instructs, produced `provider: local-only`. Every downstream behavior
then follows correctly from a wrong premise — `remote-adapter.sh` prints
`local-only profile; no PR/MR opened` and exits 0, no updater config is
scaffolded, and the loop appears to be "working local" with nothing failing. The
profile is create-if-absent, so re-running convergence never corrects it; only a
hand-edit does. A single unexamined default silently removes the entire remote
half of the protocol.

VS Code fork environments have terminals; what they lack is an authenticated
vendor CLI. Treating the CLI as the only automated path forces the sprint to end
with a handoff for reasons that have nothing to do with the loop.

The CI half is the same failure in a different place: a checkpoint that looks
green because no workflow was configured to run against that branch is worse
than a red one, because it consumes the reviewer's trust.

## Alternatives
- **Ask the operator for the provider at Sprint 0.** Correct but adds a blocking
  question to every bootstrap, and the answer is almost always derivable from
  `origin`. Inference with an explicit override and a recorded rationale is
  better; the question remains the fallback when inference is ambiguous.
- **Default to `generic` instead of `local-only`.** Fails more loudly, which is
  an improvement, but still guesses. Detection is the actual fix.
- **Flatten Gitea and Forgejo into `generic`.** Loses the API path and the CI
  directory that make them automatable, for hosts that are common in
  self-hosted setups.
- **Require the vendor CLI.** Simple and already implemented; it is what
  produces the handoff. Retained as the preferred path when present, rejected as
  the only one.
- **Fail the sprint when CI is unverifiable.** Too strict for `local-only` and
  generic hosts, where there is no CI to verify. The check binds where a
  provider is declared.

## Consequences
- Inference reads the `origin` URL, so a project behind an SSH alias or a
  corporate proxy host may not match a known pattern. Those fall to `generic`
  with the inferred URL recorded, and the operator overrides explicitly.
- Every project bootstrapped before this intent lands carries whatever provider
  Sprint 0 defaulted to. A one-time reconciliation — report the disagreement,
  do not auto-rewrite — is part of the delivery, because silently rewriting a
  Book field the operator may have set deliberately is worse than reporting it.
- The environment must be able to hold a token, and the skill must never read,
  print, or record its value — only its presence. Any implementation that echoes
  a token into a log or a Book artifact is a defect.
- Server-side protection cannot be a hard gate: it needs authentication,
  repository permission, and a host that offers it. The enforceable half of
  branch discipline stays local, in [INT-0005](INT-0005-turn-and-checkpoint-contract.md).
- The zero-checks rule will block closes on repositories that legitimately run
  no CI. It binds only where the remote profile declares a provider with CI.

## Transition history
- 2026-09-02: created as `proposed` — derived from operator feedback items 7.a
  and 9.a, and carrying the remote half of item 2.a that INT-0005 leaves out.
- 2026-09-03: revised before the Sprint 18 merge — added provider detection as
  the leading concern after reproducing the `local-only` default at Sprint 0,
  added Gitea and Forgejo to the provider enum, added the profile-disagreement
  reconciliation, and moved CI *generation* out to INT-0012 so this chapter
  covers knowing and reaching the provider while that one covers what gets
  generated and how it is maintained.
- 2026-09-03: Sprint 19 Research refined the detection rule — an unrecognized
  remote resolves to `generic` rather than `local-only`, because the current
  default gets exactly that case backwards for every hosted project; and
  recorded that `gitea` and `forgejo` are declarable but not inferable, so the
  enum addition serves explicit declaration rather than detection.
- 2026-09-03: `proposed → planned` — Sprint 19 tasks T-157–T-160 cover provider
  inference, the enum widening with its updater routing, the report-don't-rewrite
  reconciliation, and the operator-facing contracts. The REST checkpoint tier,
  the CI truth check, and base protection are deliberately out of that sprint, so
  this intent will remain `active` at its close rather than realized.
