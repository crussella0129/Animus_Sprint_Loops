# Sprint 20 Research Report

## Intents Reviewed
- [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) — selected; relevance: this sprint delivers its first two parts, per-provider CI at Sprint 0 and language detection, and leaves reconciliation over the project's life for a follow-on; current state: `proposed`.
- [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md) — selected as the prerequisite and the consumer; relevance: provider truth landed in Sprint 19, which is what makes per-host generation possible, and its CI truth check will later verify what this sprint generates; current state: `active`.
- [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) — reviewed as context; relevance: owns the two-branch model whose branches the generated triggers must name; current state: `superseded`.
- [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) — reviewed as the gating mechanism; relevance: a new convergence step that writes a file into an existing project must bind at a contract version; current state: `realized`.

## 1. Sprint Goal

Give every Sprint Loops project working continuous integration from Sprint 0, on
whichever host it lives on, covering the languages it actually contains. A fresh
project currently gets a dependency-updater config and **no CI at all**, so its
first checkpoint is green by absence — the false positive that makes a
reviewer's trust worthless. Deliberately excluded: reconciling the configuration
as the project's languages change over its life, which is INT-0012's second half
and depends on reading intent chapters.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| open-harnesses/scripts/deploy-substrate.sh | high | Step 2b writes the updater config per provider and is the exact shape a CI step follows: create-if-absent, tracked in `CREATED_*` for rollback, mirrored by a `--check` arm. |
| .github/workflows/ci.yml | high | This repository's own workflow, and the model for what a generated one must do: trigger on `push` and on `pull_request` to `[main, dev]`, run the canonical runner, and publish confirmations. |
| tools/run-guards.sh | high | The canonical-suite concept a generated workflow must invoke when a project has one. A fresh project has none, which is the central design problem (F3). |
| open-harnesses/scripts/remote-profile.sh | high | Provider enum now includes `gitea` and `forgejo` (Sprint 19), so per-host generation has real values to switch on. |
| open-harnesses/schemas/remote-profile.md | medium | Documents `base`/`work`; the generated triggers must name both branches or CI never runs on the branch sprints commit to. |
| open-harnesses/scripts/deploy-substrate.test.sh | high | 24 fixtures, including the updater-variant matrix that a CI-variant matrix should mirror; `snap()` gives file+ref comparison for no-clobber assertions. |
| open-harnesses/scripts/book-paths.sh | high | `BOOK_SUBSTRATE_CONTRACT_VERSION` and `book_gates_active()`; a new convergence step that writes into an existing project needs a version. |
| open-harnesses/scripts/check-substrate.sh | medium | Reports the substrate states; unchanged this sprint, but a contract raise makes every existing project report `substrate-outdated` until it converges. |
| tools/check-bundle-sync.sh | high | `REQUIRED_SCRIPTS` is an explicit inventory; each new helper is four copies plus an entry. |
| tools/run-guards.sh (registry) | high | `SUITES` plus `suite_cmd`/`suite_script_hash` arms for any new test file. |
| tools/check-plugin-manifest.sh | medium | Enforces `plugin.json` version equals `bundle-version.sh`; a contract raise means a bundle-version raise in five files. |
| claude-code/skills/sprint-loop/phases/01-init-sprint.md | medium | Byte-parity Init contract; documents what convergence creates and must name CI. |
| open-harnesses/particles/01-init-sprint.md | medium | Runtime-neutral Init particle, same addition in condensed form. |
| README.md | medium | The convergence table lists what convergence creates; CI belongs in it. |
| tools/operator-docs.test.sh | medium | Documentation contracts; a new generated artifact needs an assertion. |
| tools/check-adapter-semantics.sh | medium | Scans active surfaces; generated YAML and new prose must not trip the retired-term guard. |
| docs/work/remote-profile.md | low | This repository is `github` with an existing workflow, so it is the live no-clobber case. |

## 3. External Sources

None required. Gitea and Forgejo Actions are deliberately GitHub-Actions
compatible in workflow syntax (F2), and the remaining host is GitLab, whose
`.gitlab-ci.yml` shape is already known from the Renovate work in Sprint 16.
Every language's canonical commands are the ones this project already uses or
documents.

## 4. Risks, Unknowns, Dependencies

**Findings**

- **F1 — A fresh project gets no CI today.** Convergence writes an updater
  config and nothing else. Combined with a checkpoint that opens successfully,
  the first PR of every new project is green because nothing ran. This is the
  operator-reported symptom.
- **F2 — Three of the four hosts share one workflow format.** Gitea and Forgejo
  Actions consume GitHub Actions workflow syntax; only the directory differs
  (`.github/workflows/`, `.gitea/workflows/`, `.forgejo/workflows/`). So the
  four-host problem is really a **two-format** problem — Actions YAML and GitLab
  CI — which collapses most of the cost INT-0012's consequences anticipated.
- **F3 — "Invoke the project's canonical suite" is unanswerable for a fresh
  project.** A brand-new project has no runner. The generated workflow must
  therefore run *language-native* commands (`cargo test`, `go test ./...`,
  `pytest`, `npm test`, `shellcheck`) and prefer a canonical runner only when one
  is present. Naming the canonical suite is a substrate property this sprint
  should read but not require.
- **F4 — Triggers must name both branches or CI is decorative.** The two-branch
  model means sprints commit to `work` and open one `work → base` request. A
  workflow triggering only on `base` never runs on the branch that does the
  work, and never on the checkpoint. The generated triggers must come from the
  remote profile, not from a literal.
- **F5 — No-clobber must be directory-level, not file-level.** File-level
  create-if-absent would happily add a second workflow beside a project's
  hand-written one, producing two CI systems disagreeing about the same push.
  The rule has to be: if the host's workflow directory already contains any
  workflow, generate nothing.
- **F6 — This is a new convergence step that writes into existing projects.**
  Every behavioral change since Sprint 17 binds at a contract version. Writing a
  CI file into a project that has been running for months is more intrusive than
  a gate, so it binds at contract 4, and `--check` previews it first.
- **F7 — The updater-variant fixture matrix is the template.** Sprint 16's
  `test_deploy_updater_variants` already proves per-provider file routing with
  `local-only` getting nothing; the CI matrix is the same shape with more arms,
  and `snap()` already gives the no-clobber comparison.
- **F8 — Language detection must be manifest-driven to stay deterministic.**
  The guard runner's determinism meta-check compares normalized output across
  two runs, so detection must not depend on filesystem ordering or timestamps.
  Sorted, manifest-presence-based detection satisfies that.

**Risks**

- **Risk:** a generated workflow that fails on a fresh project is worse than
  none — it trains operators to ignore red. Mitigation: only emit a job for a
  language whose manifest is present, and keep each job to commands that pass on
  an empty-but-valid project of that language.
- **Risk:** detection misfires and scaffolds a job a project does not want.
  Mitigation: never clobber, and deleting the file is permanent because
  generation is create-if-absent.
- **Risk:** a contract raise makes every existing project report
  `substrate-outdated` until it converges. That is the designed upgrade path and
  is already exercised twice, but it is the third raise in four sprints.
- **Risk:** four bundles plus two new helpers plus a suite entry is a wide
  mechanical change, and the runner is already slow (Sprint 19 C-004).

**Unknowns**

- **Unknown:** whether `generic` should get a portable runner script or nothing.
  Leaning to a committed `ci.sh` plus a documented manual step: a host we cannot
  automate still benefits from one canonical command a human or a foreign CI can
  invoke.
- **Unknown:** whether to emit one job per language or one job running all
  detected languages. Leaning to one job per language, so a red leg names the
  language that failed.

**Dependencies**

- Provider truth from Sprint 19 (INT-0006), merged and green on `main`.

## 5. Recommended Approach

**Primary — two formats, manifest-driven detection, directory-level no-clobber,
gated at contract 4.**

1. **`detect-languages.sh`** (new): prints a sorted, deterministic list of
   language tokens from manifest presence — `rust` (Cargo.toml), `go` (go.mod),
   `python` (pyproject.toml/requirements.txt/setup.py), `node` (package.json),
   `shell` (any tracked `*.sh`). Prints a `canonical:<path>` token when a
   canonical runner is present.
2. **`scaffold-ci.sh`** (new): renders the detected jobs into the host's format —
   Actions YAML for `github`/`gitea`/`forgejo` (differing only in directory),
   `.gitlab-ci.yml` for `gitlab`, a portable `ci.sh` for `generic`, nothing for
   `local-only`. Triggers come from the remote profile's `base` and `work`.
   Refuses to write when the host's workflow directory already holds a workflow.
3. **Convergence step 2c**, mirroring the updater step: create-if-absent,
   tracked for rollback, with a matching `--check` arm, bound at contract 4.
4. **Contract 4 and bundle 0.20.0**, raised together with `plugin.json`.
5. **Documentation** in both Init contracts, the particle, the Antigravity
   workflow, and the README, plus an `operator-docs` assertion.

**Alternative considered — generate one universal workflow per host regardless
of language.** Rejected: it either runs nothing useful or fails on most
projects, and a red CI nobody believes is worse than none.

**Alternative considered — defer generation and ship only the CI truth check
from INT-0006.** Rejected as backwards: the check would tell every fresh project
that its zero-check green is invalid, without giving it any way to become valid.

**Deferred with rationale — reconciliation as languages change.** INT-0012's
parts 3 and 4 need to read intent chapters to learn a project's intended
languages, and removal must be proposed rather than applied. That is a distinct
mechanism from generation and is left for a follow-on sprint; INT-0012 stays
`active` at this sprint's close.

## Artifacts

No standalone artifacts. F1 was observed directly during Sprint 19's E2E work: a
converged fresh project contained `.github/dependabot.yml` and no
`.github/workflows/` directory at all.
