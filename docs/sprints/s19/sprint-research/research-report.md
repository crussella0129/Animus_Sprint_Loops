# Sprint 19 Research Report

## Intents Reviewed
- [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md) — selected; relevance: this sprint delivers its first two parts, provider detection and the provider enum, and leaves the REST tier, the CI truth check, and base protection for later; current state: `proposed`, revised before this sprint to lead with detection.
- [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) — reviewed as the consumer; relevance: CI generation needs to know the host and its workflow directory, so provider truth is its prerequisite; current state: `proposed`, not advanced here.
- [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) — reviewed as context; relevance: introduced the remote profile and its `local-only` default; current state: `superseded`.
- [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md) — reviewed as context; relevance: the checkpoint gate it shipped is what makes a wrong provider *silent* rather than merely wrong; current state: `active`.

## 1. Sprint Goal

Make a project's provider a fact derived from its remote instead of an
unexamined default. Convergence infers the provider from `origin` when one is
not supplied, records what it inferred and from what, accepts the self-hosted
Git forges people actually use, and reports — without rewriting — a recorded
provider that disagrees with the current remote. Deliberately narrow: the REST
checkpoint tier, CI generation, and base protection stay in INT-0006 and
INT-0012 for later sprints.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| open-harnesses/scripts/deploy-substrate.sh | high | Line 17 sets `PROVIDER=local-only` as the default; the profile block is create-if-absent. Both halves of the defect live here. |
| claude-code/skills/sprint-loop/phases/01-init-sprint.md | high | Instructs the agent to run convergence with **no arguments**, which is what makes the default reachable in normal operation. |
| open-harnesses/scripts/remote-profile.sh | high | Strict enum `github\|gitlab\|generic\|local-only`, rejecting anything else with a diagnostic naming the accepted set. |
| open-harnesses/schemas/remote-profile.md | high | Documents the enum and states `local-only` performs no PR/MR — the contract that makes the wrong value look intentional. |
| open-harnesses/scripts/remote-adapter.sh | high | Line 180: `local-only` prints `no PR/MR opened` and **exits 0**. The silence is here. Only `github` and `gitlab` have CLI branches; everything else falls to push-and-print. |
| open-harnesses/scripts/deploy-substrate.test.sh | high | 16 fixtures; every one passes an explicit `--provider`, which is why no test ever exercised the default. |
| open-harnesses/scripts/remote-profile.test.sh | high | `test_profile_rejects_malformed` asserts `bitbucket` is rejected; adding enum values must not weaken that. |
| open-harnesses/scripts/remote-adapter.test.sh | medium | Provider dispatch fixtures; a new enum value needs a fallback-path fixture. |
| open-harnesses/scripts/check-substrate.sh | medium | Resolves the profile but never compares it to `origin`; a candidate site for the disagreement report, with the cost noted in F8. |
| open-harnesses/scripts/book-paths.sh | medium | Carries `book_gates_active()` from Sprint 18, if any new behavior needs version gating. |
| docs/work/remote-profile.md | medium | This repository's own profile, correctly `github` — it was written by hand during the Sprint 15 substrate work, not by an unattended Sprint 0, which is why the defect never surfaced here. |
| open-harnesses/particles/01-init-sprint.md | medium | The runtime-neutral Init particle; gained the substrate gate in Sprint 17 and needs the inference sentence. |
| antigravity-ide/global_workflows/sprint-loops.md | medium | Names the substrate helpers in prose only. |
| README.md | medium | Documents the convergence table and the branch model; the provider story belongs there. |
| tools/check-adapter-semantics.sh | medium | Scans active surfaces; new prose must satisfy it, and it rejects the retired branch term. |
| tools/check-bundle-sync.sh | low | Four-bundle parity; this sprint adds no new script file, so `REQUIRED_SCRIPTS` is unchanged. |
| tools/run-guards.sh | low | Suite registry; no new suite needed — the changes land in existing suites. |

## 3. External Sources

None required. Provider identification is done from the `origin` URL string,
and the hosts' URL shapes are already known from the profile schema and the
existing `gh`/`glab` dispatch.

## 4. Risks, Unknowns, Dependencies

**Findings**

- **F1 — The defect is deterministic and reproduced.** A fresh `git init` with
  `origin` set to `https://github.com/someone/some-project.git`, converged
  exactly as the Init contract instructs, produced `provider: local-only`. No
  code path reads the remote.
- **F2 — It is permanent once written.** The profile step is
  `if [ ! -f "$PROFILE" ]`, so convergence never revisits an existing profile.
  Re-running the "idempotent" entrypoint cannot repair it; only a hand-edit can.
- **F3 — The failure is silent by construction.** `remote-adapter.sh` exits 0
  for `local-only`, and nothing in the loop treats "no checkpoint opened" as
  anomalous. The sprint closes successfully. That is why the operator's
  experience was a loop that simply "worked local" rather than one that failed.
- **F4 — Gitea and Forgejo cannot be reliably inferred.** They are
  overwhelmingly self-hosted on arbitrary domains; there is no `gitea.com`
  equivalent of `github.com` that most instances share. GitHub is `github.com`
  (and enterprise hosts usually contain `github`); GitLab is `gitlab.com` or a
  host containing `gitlab`; `codeberg.org` is a well-known Forgejo instance.
  Everything else is unidentifiable from a URL alone. Adding these values to the
  enum is therefore for **explicit declaration**, not for inference.
- **F5 — `generic` is the correct fallback, and it is strictly better than
  `local-only`.** When a remote exists but its host is unrecognized, `generic`
  still pushes `work` and prints the compare URL; `local-only` does nothing at
  all. So the rule is: no remote → `local-only`; remote present but unrecognized
  → `generic`. The current default gets this exactly backwards for every hosted
  project.
- **F6 — Both URL forms must be handled**: `https://host/owner/repo.git`,
  `git@host:owner/repo.git`, and `ssh://git@host/owner/repo.git`. Only the host
  segment matters.
- **F7 — The enum is strict and tested.** `remote-profile.test.sh` asserts
  `bitbucket` is rejected; adding values must extend the accepted set without
  weakening that rejection or the diagnostic that names the set.
- **F8 — The disagreement report belongs in `--check`, not in a new substrate
  state.** `check-substrate.sh` runs before routing on every invocation, so a
  new state there would change routing-adjacent output for every existing
  project and would need contract-version gating — a cost out of proportion to a
  report. `deploy-substrate.sh --check` is already read-only, already exits
  non-zero when work is pending, and is already the "what would convergence do"
  surface. **No contract-version raise is needed this sprint**, because
  inference only affects the create-if-absent branch and existing projects are
  untouched.
- **F9 — Updater routing must follow the enum.** `gitlab|generic` currently gets
  `renovate.json`; `gitea` and `forgejo` must join that arm or projects on those
  hosts would silently get no updater config — the same class of omission this
  sprint exists to fix.
- **F10 — Every deploy fixture passes an explicit `--provider`.** That is why 16
  passing fixtures never caught this. The new fixtures must exercise the
  *absence* of the flag, which is the path real operators take.

**Risks**

- **Risk:** inference misfires on a host containing `github` or `gitlab` that is
  not that product. Mitigated by the explicit override, by recording what was
  inferred and from what, and by the fact that a wrong hosted guess still
  produces a working push-and-compare path rather than silence.
- **Risk:** changing the default alters behavior for a project that deliberately
  wanted `local-only` while having a remote configured. Mitigated: existing
  profiles are never rewritten, and the operator can still pass
  `--provider local-only` explicitly.
- **Risk:** recording provenance inside the profile could break the resolver,
  which rejects unknown keys. Mitigated by writing it as prose *outside* the
  fenced block, which the parser does not read.

**Unknowns**

- **Unknown:** whether `forgejo` and `gitea` should be one enum value or two.
  Leaning to two: they have diverged, and a project should be able to say which
  it is even while both currently take the same fallback path.

**Dependencies**

- None. This sprint adds no new helper and needs no contract-version change.

## 5. Recommended Approach

**Primary — infer at creation, declare explicitly for the rest, report
disagreement without rewriting.**

1. `deploy-substrate.sh` gains provider inference, used **only** when
   `--provider` is absent and the profile is being created: no `origin` →
   `local-only`; host contains `github` → `github`; host contains `gitlab` →
   `gitlab`; `codeberg.org` → `forgejo`; any other remote → `generic`. The
   inferred value and the URL it came from are printed and recorded as prose
   above the profile's fenced block.
2. `remote-profile.sh` and the schema accept `gitea` and `forgejo`, and the
   updater routing extends to them.
3. `deploy-substrate.sh --check` reports a recorded provider that disagrees with
   what `origin` implies, and never rewrites it — a Book field the operator may
   have set deliberately is not convergence's to overwrite.
4. The Init contracts, the particle, the Antigravity workflow, and the README
   state that convergence infers the provider and how to override it.

**Alternative considered — ask the operator at Sprint 0.** Correct, and it makes
the value explicit rather than guessed. Rejected as the primary path because it
adds a blocking question to every bootstrap for an answer that is derivable in
the overwhelming majority of cases; it remains the right fallback when the
operator wants a host that cannot be inferred, which is exactly what the
explicit flag already provides.

**Alternative considered — default to `generic` instead of inferring.** A
one-character fix that removes the silence, since `generic` pushes and prints a
compare URL. Rejected as insufficient: it still guesses, and it would leave
GitHub projects without `gh` integration or a Dependabot config.

## Artifacts

No standalone artifacts. F1 and F5 were observed directly by running convergence
against throwaway repositories at commit `16d2eab`, once with no `--provider`
and once with `--provider github`.
