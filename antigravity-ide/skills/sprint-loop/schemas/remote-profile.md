# Schema: remote profile

The remote profile is the Book-tracked declaration of a project's branch
topology and remote-checkpoint behavior. It lives at
`docs/work/remote-profile.md` and is resolved by `scripts/remote-profile.sh`.
It is the "declared preauthorized-remote profile" the adapters reference; it is
configuration, not semantic intent.

```markdown
# Remote Profile

<!-- sprint-loop-remote-profile-v1 -->

​```
provider: github
base: main
work: dev
bump: bump
mergePolicy: human-approve
​```
```

The resolver reads the **first fenced code block** and parses `key: value`
lines. Fields:

- `provider` — **required**; one of `github` | `gitlab` | `generic` | `local-only`.
  Selects the checkpoint adapter (`gh`, `glab`, a push-and-print-URL fallback,
  or none).
- `base` — **required**; the PR/MR-gated corpus branch (e.g. `main`).
- `work` — **required**; the long-lived branch sprints commit to (e.g. `dev`).
- `bump` — optional; the Dependabot target branch. Omit (or set `none`) to
  disable the `bump` leg.
- `mergePolicy` — optional; `human-approve` (default) or `auto-on-green`.

Rules:

- The `<!-- sprint-loop-remote-profile-v1 -->` marker must be present.
- A missing file, missing marker, missing required field, unknown `provider`, or
  unknown `mergePolicy` is a resolution error with a specific diagnostic.
- `local-only` needs only `base`/`work`; no remote or provider CLI is required,
  and the Loop performs no PR/MR.
- The skill never creates a per-sprint branch: sprints work on `work`, and each
  sprint opens exactly one `work → base` PR/MR (unless `local-only`).
