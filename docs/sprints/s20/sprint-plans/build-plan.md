Finalized - DO NOT EDIT

# Sprint 20 Build Plan

## Intents
- [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md) — state: planned; acceptance criteria covered: a fresh project on each provider converges to CI in that host's format and `local-only` gets none; the configuration runs the languages the project contains; an existing configuration is never clobbered. Not covered this sprint: reconciliation as languages change, and proposed removal — INT-0012 parts 3 and 4.
- [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md) — state: active; relevance: provider truth is this sprint's prerequisite, and its CI truth check will later verify what this sprint generates. Not advanced here.

## Schema Tree
- CI that exists from Sprint 0
  - Detection
    - T-164: contract 4, bundle 0.20.0, and language detection
  - Generation
    - T-165: the per-host generator
  - Convergence
    - T-166: wire generation into convergence and `--check`
  - Contracts
    - T-167: document what is generated and how to opt out

## Execution Sequence

### T-164: Raise the contract to 4 and detect the project's languages
- **Intent:** [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md)
- **Touches:** `open-harnesses/scripts/book-paths.sh` (+3 bundle copies), `open-harnesses/scripts/bundle-version.sh` (+3), `claude-code/.claude-plugin/plugin.json`, `open-harnesses/scripts/detect-languages.sh` (new, +3), `open-harnesses/scripts/detect-languages.test.sh` (new, +3), `tools/check-bundle-sync.sh`, `tools/run-guards.sh`
- **Depends on:** (none)
- **Acceptance criterion:** the generated configuration runs the languages the project actually contains — this task supplies the detection that decides which.
- **Success criterion (EARS):**
  - **WHEN** `detect-languages.sh` runs in a project containing `Cargo.toml`, **THEN** it **SHALL** print `rust`; likewise `go.mod` → `go`, `pyproject.toml` or `requirements.txt` or `setup.py` → `python`, `package.json` → `node`, and any tracked `*.sh` → `shell`.
  - **WHEN** it runs in a project containing several of those manifests, **THEN** it **SHALL** print every matching token, one per line, in a stable sorted order.
  - **WHEN** it runs twice against the same project, **THEN** both runs **SHALL** produce byte-identical output, so the canonical runner's determinism check holds.
  - **WHEN** a canonical suite runner is present at `tools/run-guards.sh`, **THEN** it **SHALL** additionally print `canonical:tools/run-guards.sh`.
  - **WHEN** it runs in a project with none of those manifests, **THEN** it **SHALL** print nothing and exit 0.
- **Notes:** raise `BOOK_SUBSTRATE_CONTRACT_VERSION` to 4, and `bundle-version.sh` plus `plugin.json` to `0.20.0` together — the manifest guard fails if they disagree. Sprint 19 shipped code without raising the bundle version, so `0.18.0` currently names two different bundles; the raise closes that. Detection reads tracked files via git where possible so untracked scratch files do not decide a project's languages.

### T-165: Generate the host's CI configuration from the detected languages
- **Intent:** [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md)
- **Touches:** `open-harnesses/scripts/scaffold-ci.sh` (new, +3), `open-harnesses/scripts/scaffold-ci.test.sh` (new, +3), `tools/check-bundle-sync.sh`, `tools/run-guards.sh`
- **Depends on:** T-164
- **Acceptance criteria:** a fresh project on each supported provider converges to a CI configuration in that host's own format, and a project on `local-only` gets none; an existing CI configuration is never clobbered.
- **Success criterion (EARS):**
  - **WHEN** the provider is `github`, **THEN** the generator **SHALL** write `.github/workflows/sprint-loops-ci.yml`; **WHEN** it is `gitea`, `.gitea/workflows/sprint-loops-ci.yml`; **WHEN** `forgejo`, `.forgejo/workflows/sprint-loops-ci.yml`.
  - **WHEN** the provider is `gitlab`, **THEN** it **SHALL** write `.gitlab-ci.yml`; **WHEN** `generic`, an executable `ci.sh`; **WHEN** `local-only`, **THEN** it **SHALL** write nothing.
  - **WHEN** the host's workflow directory already contains any file, **THEN** the generator **SHALL** write nothing and report that it left the existing configuration alone.
  - **WHEN** a configuration is generated, **THEN** its triggers **SHALL** name both the profile's `base` and `work` branches.
  - **WHEN** a canonical runner token is present, **THEN** the generated configuration **SHALL** invoke that runner instead of the per-language jobs.
  - **WHEN** the generator runs twice with identical inputs, **THEN** both outputs **SHALL** be byte-identical.
- **Notes:** the generator takes `--provider`, `--base`, and `--work` as arguments; convergence passes the values it resolved from the remote profile, so "triggers come from the profile" is proven at the convergence layer by the integration fixture rather than inside the generator. `github`, `gitea`, and `forgejo` share one Actions renderer differing only by directory. Pin `actions/checkout@v4`, which self-hosted Gitea and Forgejo runners can generally resolve. Language jobs must pass on an empty-but-valid project: `npm test --if-present`, and `pytest` tolerating **only** exit 5 (no tests collected). That narrow allowance is deliberate and must not be written as `|| true`, which INT-0006's later truth check is designed to reject.

### T-166: Generate CI as a convergence step
- **Intent:** [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md)
- **Touches:** `open-harnesses/scripts/deploy-substrate.sh` (+3), `open-harnesses/scripts/deploy-substrate.test.sh` (+3)
- **Depends on:** T-164, T-165
- **Acceptance criterion:** a fresh project on each supported provider converges to a CI configuration in that host's own format.
- **Success criterion (EARS):**
  - **WHEN** convergence runs against a Book at contract 4 or above with no CI configuration present, **THEN** it **SHALL** generate the host's configuration and record it for rollback.
  - **WHEN** convergence runs against a Book below contract 4, **THEN** it **SHALL** generate nothing, and the project **SHALL** be byte-identical to its pre-run state apart from the contract stamp.
  - **WHEN** a failure is injected after the CI step, **THEN** rollback **SHALL** remove the generated configuration.
  - **WHEN** convergence runs twice against a converged project, **THEN** every file and every git ref **SHALL** remain byte-identical.
  - **WHEN** `--check` runs against a project missing its CI configuration, **THEN** it **SHALL** name the pending generation step and write nothing.
- **Notes:** mirror step 2b exactly — create-if-absent, `CREATED_*` tracking, a matching `--check` arm. The step runs after the updater config and before the stamp, so a rollback triggered later removes it.

### T-167: Document what convergence generates and how to opt out
- **Intent:** [INT-0012](../../../intents/INT-0012-ci-scaffolding-lifecycle.md)
- **Touches:** `claude-code/skills/sprint-loop/phases/01-init-sprint.md`, `codex-cli/skills/sprint-loops/phases/01-init-sprint.md`, `open-harnesses/particles/01-init-sprint.md`, `antigravity-ide/global_workflows/sprint-loops.md`, `README.md`, `tools/operator-docs.test.sh`
- **Depends on:** T-165
- **Acceptance criterion:** the operator-facing statement of what is generated exists — the documented counterpart to the generation the other tasks build.
- **Success criterion (EARS):**
  - **WHEN** an adapter's Init contract is read, **THEN** it **SHALL** name the file convergence generates for each provider and state that `local-only` gets none.
  - **WHEN** the README is read, **THEN** it **SHALL** state that an existing CI configuration is never touched and that deleting a generated one is permanent, because generation is create-if-absent.
  - **WHEN** the adapter documentation set is scanned after this change, **THEN** `check-adapter-semantics.sh` and `operator-docs.test.sh` **SHALL** both exit 0.
- **Notes:** `phases/01-init-sprint.md` is byte-parity between claude-code and codex-cli — edit one and copy. Avoid the retired branch-model term.
