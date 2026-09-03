# Sprint 19 Build Plan

## Intents
- [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md) — state: planned; acceptance criteria covered: inference from a recognized `origin`; `local-only` only when there is no remote; `generic` for an unrecognized remote; explicit `--provider` wins; an existing profile is reported on but never rewritten; `gitea` and `forgejo` accepted with unknown values still rejected. Not covered this sprint: the REST checkpoint tier, the CI truth check, and base protection.
- [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) — state: proposed; relevance: CI generation needs provider truth as its prerequisite. Not advanced by this sprint.

## Schema Tree
- Know the provider
  - Detection
    - T-157: infer the provider from `origin` at profile creation
  - Declaration
    - T-158: accept `gitea` and `forgejo`, and route their updater config
  - Reconciliation
    - T-159: report a recorded provider that disagrees with `origin`
  - Contracts
    - T-160: document inference and the override

## Execution Sequence

### T-157: Infer the provider from the origin remote when one is not supplied
- **Intent:** [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md)
- **Touches:** `open-harnesses/scripts/deploy-substrate.sh` (+3 bundle copies), `open-harnesses/scripts/deploy-substrate.test.sh` (+3 bundle copies)
- **Depends on:** (none)
- **Acceptance criteria:** convergence with no `--provider` against a recognized remote writes that provider and records the URL it inferred from; with no remote it writes `local-only`; against an unrecognized remote it writes `generic`; an explicit `--provider` always wins.
- **Success criterion (EARS):**
  - **WHEN** convergence creates a profile with no `--provider` and `origin` is `https://github.com/o/r.git`, **THEN** the profile **SHALL** record `provider: github`.
  - **WHEN** `origin` is `git@github.com:o/r.git` or `ssh://git@github.com/o/r.git`, **THEN** the profile **SHALL** record `provider: github`, so the SSH forms resolve identically to HTTPS.
  - **WHEN** `origin`'s host contains `gitlab`, **THEN** the profile **SHALL** record `provider: gitlab`; **WHEN** the host is `codeberg.org`, **THEN** it **SHALL** record `provider: forgejo`.
  - **WHEN** an `origin` exists whose host matches no known provider, **THEN** the profile **SHALL** record `provider: generic` and **SHALL NOT** record `local-only`.
  - **WHEN** the repository has no `origin` remote, **THEN** the profile **SHALL** record `provider: local-only`.
  - **WHEN** `--provider` is supplied, **THEN** the profile **SHALL** record that value regardless of `origin`.
  - **WHEN** a profile already exists, **THEN** convergence **SHALL NOT** modify it.
  - **WHEN** a provider is inferred, **THEN** convergence **SHALL** print the inferred value with the URL it came from, and **SHALL** record both as prose outside the profile's fenced block.
- **Notes:** extract the host from `https://host/…`, `git@host:…`, and `ssh://git@host/…`, strip any `user@`, and lowercase before matching. Enterprise hosts containing `github` or `gitlab` are matched deliberately — `gh` and `glab` generally work against them, and a wrong hosted guess still yields a working push-and-compare path, unlike `local-only`. Provenance must sit outside the fence: the resolver reads the first fenced block and rejects unknown keys.

### T-158: Accept gitea and forgejo, and give them an updater config
- **Intent:** [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md)
- **Touches:** `open-harnesses/scripts/remote-profile.sh` (+3), `open-harnesses/schemas/remote-profile.md` (+3), `open-harnesses/scripts/deploy-substrate.sh` (+3), `open-harnesses/scripts/remote-profile.test.sh` (+3), `open-harnesses/scripts/remote-adapter.test.sh` (+3)
- **Depends on:** (none)
- **Acceptance criterion:** `remote-profile.sh` accepts `gitea` and `forgejo` and rejects an unknown value with a diagnostic naming the accepted set.
- **Success criterion (EARS):**
  - **WHEN** a profile declares `provider: gitea` or `provider: forgejo`, **THEN** `remote-profile.sh` **SHALL** resolve it and print that value.
  - **WHEN** a profile declares an unknown provider, **THEN** `remote-profile.sh` **SHALL** exit non-zero with a diagnostic naming every accepted value.
  - **WHEN** convergence creates a profile whose provider is `gitea` or `forgejo`, **THEN** it **SHALL** scaffold `renovate.json` targeting the work branch.
  - **WHEN** `open-pr` runs against a `gitea` or `forgejo` profile, **THEN** it **SHALL** take the push-and-compare fallback and **SHALL NOT** invoke a provider CLI.
- **Notes:** the fixture asserting `bitbucket` is rejected must keep passing — widening the enum must not weaken the rejection. Gitea and Forgejo are declarable but not inferable, so no inference fixture claims to produce them except `codeberg.org`.

### T-159: Report a recorded provider that disagrees with the origin remote
- **Intent:** [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md)
- **Touches:** `open-harnesses/scripts/deploy-substrate.sh` (+3), `open-harnesses/scripts/deploy-substrate.test.sh` (+3)
- **Depends on:** T-157
- **Acceptance criterion:** a profile already written stays authoritative — convergence reports a disagreement between the recorded provider and the current `origin` rather than silently rewriting it.
- **Success criterion (EARS):**
  - **WHEN** `--check` runs against a profile recording `local-only` while `origin` implies `github`, **THEN** it **SHALL** report the disagreement naming both values and **SHALL NOT** modify the profile.
  - **WHEN** `--check` runs against a profile whose recorded provider matches what `origin` implies, **THEN** it **SHALL** report no disagreement.
  - **WHEN** `--check` runs against a `local-only` profile in a repository with no `origin`, **THEN** it **SHALL** report no disagreement.
  - **WHEN** a disagreement is reported, **THEN** the project **SHALL** remain byte-identical.
- **Notes:** this is the surface an operator uses to find projects bootstrapped with the wrong value; T-156 covers acting on it. Report, never repair: a provider the operator set deliberately is not convergence's to overwrite.

### T-160: Document inference, the override, and the fallback in the adapter contracts
- **Intent:** [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md)
- **Touches:** `claude-code/skills/sprint-loop/phases/01-init-sprint.md`, `codex-cli/skills/sprint-loops/phases/01-init-sprint.md`, `open-harnesses/particles/01-init-sprint.md`, `antigravity-ide/global_workflows/sprint-loops.md`, `README.md`, `tools/operator-docs.test.sh`
- **Depends on:** T-157, T-158
- **Acceptance criterion:** the operator-facing statement of provider detection exists — the documented counterpart to the inference the other tasks build.
- **Success criterion (EARS):**
  - **WHEN** an adapter's Init contract is read, **THEN** it **SHALL** state that convergence infers the provider from `origin`, that an unrecognized remote becomes `generic`, that no remote becomes `local-only`, and how to override with an explicit provider.
  - **WHEN** the README is read, **THEN** it **SHALL** name every accepted provider value and state that an existing profile is reported on rather than rewritten.
  - **WHEN** the adapter documentation set is scanned after this change, **THEN** `check-adapter-semantics.sh` and `operator-docs.test.sh` **SHALL** both exit 0.
- **Notes:** `phases/01-init-sprint.md` is byte-parity between claude-code and codex-cli — edit one and copy. Avoid the retired branch-model term, which cost Sprint 17 a rework cycle.
