# Phase 01 — Initialize Sprint

## Substrate gate (first action)

Before routing or initializing anything, run the installed bundle's
`scripts/check-substrate.sh` from the project root. It reports one of:

- `substrate-complete` — Book, ledgers, the configured `base`/`work` branches,
  and a resolvable remote profile all exist, at this bundle's substrate contract
  version. Proceed with Init below.
- `substrate-absent` — a fresh project. Run **convergence**,
  `scripts/deploy-substrate.sh`, which creates the Book, the `main`/`dev`
  branches, the ledgers, the remote profile (see `schemas/remote-profile.md`),
  the first sprint, and the contract stamp. The skill creates **no per-sprint
  branch** — sprints work on `work`/`dev`.

  **The provider is inferred from the `origin` remote.** A host containing
  `github` or `gitlab` resolves to that provider, `codeberg.org` resolves to
  `forgejo`, any other remote resolves to `generic`, and only an absent `origin`
  resolves to `local-only` — a hosted project recorded as `local-only` opens no
  checkpoint and exits successfully, which is silent rather than wrong-looking.
  Pass `--provider <github|gitlab|gitea|forgejo|generic|local-only>` to override;
  Gitea and Forgejo must be declared this way, since both are self-hosted on
  arbitrary domains. What was inferred, and the URL it came from, is recorded in
  the profile. An existing profile is never rewritten:
  `scripts/deploy-substrate.sh --check` reports a recorded provider that
  disagrees with the current `origin` and leaves the repair to a person.

  **Convergence also generates the host's CI configuration** from the languages
  the project contains — `.github/workflows/sprint-loops-ci.yml` for `github`,
  `.gitea/` and `.forgejo/workflows/` for those hosts, `.gitlab-ci.yml` for
  `gitlab`, an executable `ci.sh` for `generic`, and nothing for `local-only`.
  Without it a fresh project reaches its first checkpoint with no CI at all, so
  that checkpoint is green because nothing ran. If the host's workflow directory
  already holds anything, convergence generates nothing and leaves the existing
  configuration alone. Generation is create-if-absent, so deleting a generated
  file is permanent — that is how a project opts out.
- `substrate-outdated:<book>-><bundle>` — the substrate is complete but predates
  this bundle's contract. Run the **same** helper: spin-up and upgrade are one
  idempotent command that creates only what is missing, stamps the contract
  version, and verifies. Re-running it on a current project changes nothing.
  `scripts/deploy-substrate.sh --check` names the pending steps without writing.
- `substrate-ahead:<book>-><bundle>` — the Book was stamped by a newer bundle
  than the one running. Do not converge; it would downgrade the project. Update
  the installed bundle instead.
- `substrate-partial:<diagnostic>` — resolve the named missing element (migrate a
  legacy Book, declare the remote profile, create the missing branch, or repair a
  malformed contract stamp) before continuing.

## Dependency-update intake (sprint boundary only)

Hosted updaters propose PRs/MRs against the profile's `work` branch; opening a
request does not mutate `work`. Inspect those requests only between sprints,
before new sprint writes begin—never merge updater intake during an active
sprint.

- Merge an updater PR into `work` only when it is current and green in CI, and the
  adapter's remote-authority boundary permits the merge.
- Keep a red updater PR unmerged and repair its PR head until green.
- If the provider does not permit repairing that head, run an ordinary
  dependency-only sprint that reproduces and fixes the update on `work`, then
  supersede the unmergeable updater PR. It uses the same plan, evidence, and
  `work → base` checkpoint as every other sprint; there is no checkpoint or
  sprint subtype.

## Outcome

Create or extend one tracked Book schema v2 and initialize the next numbered
sprint without creating legacy root authorities.

## Inputs

Invoke the installed bundle's `scripts/init-sprint.sh` helper with the
project root as its working directory. The harness adapter resolves the
installed bundle path.

The helper classifies existing state before writing. It refuses legacy-only and
split-brain layouts, preserves existing Book content and project
`.gitignore` entries, creates missing Book scaffolding, and chooses the next
`docs/sprints/sN/` number. Set `SPRINT_MODEL` before invoking it if the
model identifier is known.

The initialized metadata includes Sprint number, Book schema version, start
timestamp, model, `in-progress` status, Summary, Intents, and Completion
evidence fields.

## Authority

Initialization establishes containers and provenance only. It does not invent
project intent. Existing `docs/intents/` chapters remain semantic authority;
existing `docs/work/` ledgers remain execution state; existing sprint records
remain provenance. `docs/SUMMARY.md` receives stable navigation links only.

Do not hand-create parallel legacy state surfaces. Use the installed
`migrate-to-book.sh` helper when initialization diagnoses legacy state.

## Exit evidence

All of the following exist:

- `docs/.sprint-loop-book` declares schema version 2.
- `docs/README.md`, `docs/SUMMARY.md`, `docs/intents/`,
  `docs/work/`, and `docs/sprints/` exist.
- `docs/work/tasks.md`, `docs/work/completed-tasks.md`, and
  `docs/work/confidence.txt` exist without overwriting prior content.
- The new `docs/sprints/sN/` contains initialized research, plan, test, and
  metadata artifacts, and `SUMMARY.md` links its metadata.
- The installed `current-phase.sh` helper reports `research`.

When complete, read `phases/02-research-phase.md`.
