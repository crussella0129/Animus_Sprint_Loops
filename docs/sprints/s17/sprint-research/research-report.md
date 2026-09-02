# Sprint 17 Research Report

## Intents Reviewed
- [INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) — selected and revised; relevance: this sprint is the whole intent; current state: `proposed`, revised during this research to add the bundle-older-than-Book acceptance criterion discovered in F6.
- [INT-0002](../../../intents/INT-0002-substrate-and-branch-model.md) — selected as context; relevance: owns the substrate gate and Sprint 0 deploy this sprint extends; current state: `superseded` by INT-0003 for the branch topology, but its substrate-layer decisions still describe the shipped code.
- [INT-0005](../../../intents/INT-0005-turn-and-checkpoint-contract.md), [INT-0006](../../../intents/INT-0006-provider-reach-and-ci-truth.md), [INT-0007](../../../intents/INT-0007-integrity-sweep.md), [INT-0008](../../../intents/INT-0008-escalation-and-flow.md), [INT-0009](../../../intents/INT-0009-sprint-identity.md) — reviewed as consumers, not advanced; relevance: each depends on the version-conditional gating this sprint makes possible; current state: `proposed`, unchanged.

## 1. Sprint Goal

Make "which substrate contract is this project on?" a fact recorded on disk, and
make one already-idempotent script the single entrypoint that spins a project
up, brings an older one to the current contract, and no-ops on a current one.
The sprint adds no phase gate and touches no routing logic. Its entire product
is the mechanism that later sprints will condition their gates on, plus the
bundle-version discipline needed to answer "which bundle ran this sprint?"
without inferring it from a cache path.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| open-harnesses/scripts/book-paths.sh | high | `book_marker_is_v2()` parses the marker; the natural home for a `book_substrate_version()` accessor and the bundle's implemented-version constant. |
| open-harnesses/scripts/check-substrate.sh | high | Builds a `missing` list and prints `substrate-complete`/`absent`/`partial:<list>`; exit 0 only for complete. Needs the fourth and fifth states. |
| open-harnesses/scripts/deploy-substrate.sh | high | Already an ordered, individually-guarded step list with `CREATED_*` tracking, a `rollback()` trap, a `COMMITTED` flag, and a `maybe_fail <step>` seam. Extension, not rewrite. |
| open-harnesses/scripts/deploy-substrate.test.sh | high | `test_deploy_idempotent` snapshots files **and** refs and requires an unchanged snapshot after re-run — the forcing function for a genuine no-op. Rollback fixtures already cover created-vs-preexisting. |
| open-harnesses/scripts/check-substrate.test.sh | high | Fixture helpers (`git_init_branches`, `make_book`, `make_profile`) are directly reusable for outdated/ahead fixtures. Includes a read-only assertion the new states must not break. |
| open-harnesses/scripts/init-sprint.sh | high | Writes the marker **create-if-absent** (`[ ! -e "$BOOK_MARKER" ]`), so it must not become a second writer of the version key. Its `# >>> sprint-loops >>>` owned-block pattern for `.gitignore` is the precedent for owned-region editing. |
| open-harnesses/scripts/current-phase.sh | high | Pure function from Book evidence to phase. Explicitly **not modified** this sprint; recorded so the boundary is auditable. |
| open-harnesses/scripts/remote-profile.sh | medium | The precedent for strict versioned markers: it refuses a v1 marker by name with a migration instruction rather than guessing. The substrate version should follow that shape. |
| open-harnesses/scripts/close-sprint.sh | medium | Precedent for appending missing anchored fields to migrated `sprint-meta.md` rather than rewriting the artifact — the pattern for adding `Bundle version`. |
| open-harnesses/scripts/sync-work-branch.sh | low | Unchanged; exercised at this sprint's own boundary and confirmed working against a merged checkpoint. |
| claude-code/skills/sprint-loop/SKILL.md | high | Argument list is closed (`continue`/`start`/`abort`, "any other argument is unsupported"), so `upgrade` must be added explicitly or it is refused by contract. |
| claude-code/skills/sprint-loop/phases/01-init-sprint.md | high | Owns the substrate-gate contract and enumerates its three outcomes; must gain the outdated branch. |
| claude-code/.claude-plugin/plugin.json | high | No `version` field. Carries name/description/author/homepage only. |
| .claude-plugin/marketplace.json | medium | Plugin entry resolves `source: ./claude-code`; version discipline must not break its structural contract. |
| tools/check-plugin-manifest.sh | high | Validates marketplace structure, source resolution, `plugin.json` name, and the no-duplicate-command regression. The place to enforce a version field and its agreement with the bundle. |
| tools/check-bundle-sync.sh | high | Enforces byte parity of `scripts/` and `schemas/` across four bundles plus a `REQUIRED_SCRIPTS` inventory. A version file outside those two directories is **not** covered by the current parity map. |
| tools/run-guards.sh | high | Suite registry; every new test script needs a `SUITES` entry plus `suite_cmd`/`suite_script_hash` arms. Runs each suite twice under `--determinism`. |
| tools/check-adapter-semantics.sh | medium | Asserts authority/runtime meanings survive adapter-specific wording across named file lists; SKILL.md and phase 01 are in those lists. |
| open-harnesses/schemas/sprint-meta.md | medium | Documents the anchored field set; `Bundle version` must be added here and in `init-sprint.sh` together. |
| antigravity-ide/global_workflows/sprint-loops.md | medium | Names `check-substrate.sh` and `deploy-substrate.sh` in prose only; a new substrate state needs a sentence here or the adapter's operators never learn it exists. |

## 3. External Sources

None required. This sprint is entirely internal to the bundle: the marker
format, the substrate helpers, the guard suite, and the plugin manifest are all
project-owned artifacts, and every fact below was established by reading them.
The one external behavior the sprint depends on — that the Claude Code plugin
cache pins a commit — was observed directly rather than cited (see F7).

## 4. Risks, Unknowns, Dependencies

**Findings that constrain the design**

- **F1 — The marker is safely extensible.** `book_marker_is_v2()` requires
  exactly one line matching `^[[:space:]]*schema-version:` and exactly one
  matching `^schema-version:[[:space:]]*2[[:space:]]*$`. A `substrate-version:`
  line matches neither, so every existing parser in all four bundles reads an
  extended marker unchanged. This is the technical basis for INT-0004's
  compatibility claim, and it is now verified rather than assumed.
- **F2 — Two writers must not appear.** `init-sprint.sh` writes the marker only
  when absent. Convergence must own the version key exclusively; init must keep
  writing the bare `schema-version: 2` marker for a fresh Book and let
  convergence stamp it.
- **F3 — The convergence shape already exists.** `deploy-substrate.sh` has
  named steps, per-step creation tracking, a signal-safe rollback, and a
  `DEPLOY_SUBSTRATE_FAIL_AFTER` injection seam. A named step list with a
  terminal stamp step is an extension of the shipped design.
- **F4 — Idempotency is already enforced by fixture.** `test_deploy_idempotent`
  compares a checksum of every file plus every ref before and after a re-run.
  The stamp step must therefore write only when the value would change, or the
  existing suite goes red — a useful constraint rather than an obstacle.
- **F5 — Outdated is orthogonal to incomplete.** A Book can be structurally
  complete and behind the contract. Precedence must be explicit: a broken
  substrate outranks a stale one, so `substrate-partial` is reported first and
  `substrate-outdated` only when the substrate is otherwise complete. Exit 0
  stays reserved for `substrate-complete`.
- **F6 — The bundle can be older than the Book.** An operator who downgrades
  the plugin, or a second machine on an older bundle, meets a Book stamped
  ahead of the bundle's implemented version. Converging "backwards" would
  silently downgrade a project. This case was absent from INT-0004's acceptance
  criteria and has been added to the chapter. `remote-profile.sh`'s explicit
  refusal of a v1 marker is the precedent for the diagnostic.
- **F7 — Bundle identity is currently only a cache path.** The plugin cache
  pins a commit: this session loaded
  `…/sprint-loops/sprint-loop/4acc1fd6e0b9/…`, which is the sprint-16 checkpoint
  merge on `main`, while an earlier session's recorded permissions reference
  `6da2d662476b`. Nothing inside the bundle states its own version. A
  `plugin.json` version alone is insufficient, because the manual
  `install.sh` path installs `skills/sprint-loop/` **without** any
  `.claude-plugin/` directory — so the version must live inside the skill
  bundle to be readable in every install mode.
- **F8 — Parity coverage has a hole for non-script files.**
  `check-bundle-sync.sh` maps `scripts/`, `schemas/`, `prompts/`, and two
  bundles' `phases/`. A version file at the skill root is covered by none of
  them. Either it lives under `scripts/` or the parity map grows a case.

**Risks**

- **Risk:** the stamp step rewrites a file present in every existing project.
  Mitigation: surgical, write-only-on-change, verified by F4's existing fixture.
- **Risk:** callers that treat any non-zero `check-substrate.sh` exit as fatal
  will now see a new failing state on projects that were previously complete.
  Mitigation: the phase contract routes it to convergence; the diagnostic names
  the exact command; the state is only reachable after this bundle ships.
- **Risk:** Init that converges automatically now writes more than a sprint.
  Mitigation: convergence output is printed, and its rollback already covers
  every artifact it creates.
- **Risk:** four-bundle parity plus guard registration makes even a small helper
  a wide change. Mitigation: no new helper script is proposed — the work lands
  in existing scripts plus one version file.

**Unknowns**

- **Unknown:** whether `--check` belongs on `deploy-substrate.sh` or as a
  separate mode of `check-substrate.sh`. Leaning to the former: the router-facing
  gate should keep printing exactly one token, while a step-level drift report is
  a deploy concern.
- **Unknown:** whether the first stamped value should be `2` (with absent
  meaning `1`) or `1` (with absent meaning `0`). Leaning to absent = 1 and this
  sprint shipping 2, so "unstamped" is a real version rather than a null.

**Dependencies**

- None external. The two-branch model (INT-0002, INT-0003) is settled and
  shipped; this sprint neither extends nor contradicts it.

## 5. Recommended Approach

**Primary — extend the shipped shape, add no new helper script.**

1. `book-paths.sh` gains `BOOK_SUBSTRATE_VERSION` (the version this bundle
   implements) and a `book_substrate_version()` accessor that returns `1` when
   the key is absent and refuses a malformed value.
2. `deploy-substrate.sh` becomes the convergence entrypoint: the existing
   creation steps, plus a terminal stamp step that writes only on change, plus
   `--check` for a read-only, step-level drift report.
3. `check-substrate.sh` gains `substrate-outdated:<from>-><to>` when otherwise
   complete, and a distinct diagnostic when the Book is ahead of the bundle.
4. Bundle identity: a version file inside the skill bundle, `plugin.json` gains
   a matching `version`, `check-plugin-manifest.sh` enforces the agreement, and
   `init-sprint.sh` plus the `sprint-meta.md` schema record `Bundle version`.
5. Documentation: SKILL.md gains the `upgrade` argument, phase 01 gains the
   outdated branch, and the Antigravity workflow gains the corresponding
   sentence.

**Alternative considered — a numbered migrations directory,** one script per
version transition, applied in order. Rejected for this sprint: with a single
transition and convergence steps that all create-if-absent, a migration runner
adds an ordering and discovery mechanism with nothing yet to order. It becomes
the right design the first time a step must *modify* an existing artifact rather
than create a missing one, and the step list should be structured so that change
is additive.

**Rationale.** Every element of the primary approach already has a working
precedent in this repository: versioned markers with explicit refusal
(`remote-profile.sh`), transactional multi-step writes with rollback and a
failure-injection seam (`deploy-substrate.sh`), owned-region editing
(`init-sprint.sh`), and appending anchored fields to migrated metadata
(`close-sprint.sh`). The sprint's risk is concentrated in one place — writing to
a marker file every project owns — and the existing idempotency fixture already
tests exactly that property.

## Artifacts

No standalone research artifacts were produced. Every finding above is a direct
citation of a surveyed file in this repository at `dev` commit `7f50492`.
