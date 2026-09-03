# Schema: remote profile

The remote profile is the Book-tracked declaration of a project's branch
topology and remote-checkpoint behavior. It lives at
`docs/work/remote-profile.md` and is resolved by `scripts/remote-profile.sh`.
It is the "declared preauthorized-remote profile" the adapters reference; it is
configuration, not semantic intent.

```markdown
# Remote Profile

<!-- sprint-loop-remote-profile-v2 -->

​```
provider: github
base: main
work: dev
mergePolicy: human-approve
​```
```

The resolver reads the **first fenced code block** and parses `key: value`
lines. Fields:

- `provider` — **required**; one of `github` | `gitlab` | `gitea` | `forgejo` |
  `generic` | `local-only`. Selects the checkpoint adapter (`gh`, `glab`, a
  push-and-print-URL fallback, or none). `gitea` and `forgejo` currently take
  the fallback; they are named separately from `generic` because they have their
  own API shape and their own CI directory.
- `base` — **required**; the PR/MR-gated corpus branch (e.g. `main`).
- `work` — **required**; the long-lived branch sprints commit to (e.g. `dev`).
- `mergePolicy` — optional; `human-approve` (default) or `auto-on-green`.

Rules:

- The `<!-- sprint-loop-remote-profile-v2 -->` marker must be present. Profiles
  using an earlier marker must be rewritten to the v2 four-field shape.
- A missing file, missing marker, missing required field, unknown `provider`, or
  unknown field/value is a resolution error with a specific diagnostic; extra
  keys are never ignored.
- `local-only` needs only `base`/`work`; no remote or provider CLI is required,
  and the Loop performs no PR/MR. It is correct only when the project genuinely
  has no `origin` remote — a hosted project recorded as `local-only` silently
  loses the entire remote half of the protocol, because the Loop opens no PR/MR
  and exits successfully.
- Convergence **infers** the provider from the `origin` remote when the profile
  is first created and no explicit provider is given: a host containing `github`
  or `gitlab` resolves to that provider, `codeberg.org` resolves to `forgejo`,
  any other remote resolves to `generic`, and only an absent `origin` resolves to
  `local-only`. What was inferred, and the URL it came from, is recorded as prose
  above the fenced block. Gitea and Forgejo are otherwise **declared, not
  inferred**: both are overwhelmingly self-hosted on arbitrary domains.
- An existing profile is never rewritten by convergence. `deploy-substrate.sh
  --check` reports a recorded provider that disagrees with the current `origin`,
  and leaves the repair to a person.
- The skill never creates a per-sprint branch: sprints work on `work`, and each
  sprint opens exactly one `work → base` PR/MR (unless `local-only`).
- Hosted dependency updaters target `work`; their PRs are boundary-gated input
  to the same ordinary sprint path, not another long-lived branch.
