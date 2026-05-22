# Sprint 10 Plan Critique

> Critic subagent ran successfully this time (general-purpose). Verdict:
> proceed-with-caveats, with two decisive items. Responses below.

## Concerns + responses
- **C-1 (reference existence) — RESOLVED.** The critic searched the repo tree;
  `example-plugin` lives in the installed marketplace
  (`~/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/`,
  confirmed on disk). Research citation updated to the absolute path. Premise
  ("commands/*.md loaded identically to skills/<name>/SKILL.md") is verifiable.
- **C-2 (auto-trigger regression) — STANDS, UNVERIFIABLE.** The reference shows
  model-invoked (`example-skill`: description-as-trigger, no argument-hint) and
  user-invoked (`example-command`: argument-hint + allowed-tools) as DISTINCT
  modes. No positive evidence that adding `argument-hint` preserves the skill's
  model-invocation/auto-trigger. This is launch-time behavior, not bash-testable.
  → becomes an explicit E2E check AND a caveat surfaced to the user.
- **C-3 ($ARGUMENTS) — RESOLVED.** User-invoked skills use `$ARGUMENTS` (verbatim
  in example-command). Folding uses the same syntax; `test_skill_routes_verbs`
  to be tightened to assert `$ARGUMENTS` appears.
- **C-4 (authorization) — DECISIVE / HONORED.** Sprint-9 ADR committed to
  surfacing the command-removal decision to the user, not deciding it
  unilaterally. The user authorized INVESTIGATION (and chose "investigate
  whether skill+command=2"), not removal. Per the stop criterion (product
  decision the user reserved + an unverifiable effect, C-2), the sprint PAUSES at
  plan; build proceeds only on explicit go-ahead.
- **C-5 (install.sh substring test too loose) — ACCEPTED.** Tighten
  `test_install_sh_skill_only` to assert NO `commands` / `CMD_` token remains.
- **C-6 (stale descriptive README refs) — ACCEPTED.** T-002 must also update the
  descriptive "+ /sprint-loop command" text (root README layout row + tree
  comment; claude-code README layout-table row + "explicit control" section),
  not just the copy instruction. Add assertions.
- **C-7 (guard dormant without CI) — ACKNOWLEDGED.** No `.github/` exists; the new
  guard, like check-merge-policy.sh + selftest, runs by hand only. A minimal CI
  workflow is the standing top backlog item; note the guard is dormant until CI.
- **C-8 (atomicity) — clean.** Removal stays within the claude-code bundle.

## Confidence
proceed-with-caveats → **HELD at plan.** Mechanics are sound and the test gaps
(C-3/C-5/C-6) are easily tightened, but C-4 (reserved decision) + C-2 (unverifiable
auto-trigger) require explicit user authorization before T-002 deletes the command.

## Authorization (post-critique)
User explicitly authorized the skill-only build ("Yes — build skill-only (1 entry)")
in response to the go/no-go question, after reviewing the investigation findings
and the C-2 auto-trigger caveat. C-4 satisfied; build proceeds.
