# Sprint 11 Research Report

## Decisions Reviewed

All entries in `decisions.md` were read. The ones bearing on this sprint:

- **2026-05-19 current-phase.sh disambiguator** (sprint 0) — relevance: the DRY refactor touches the scripts this ADR governs; selftest.sh must stay green and be updated alongside any transition change. No transition semantics change this sprint.
- **2026-05-20 finalize-plan.sh gates + install.sh per bundle** (sprint 2) — relevance: establishes **bundle atomicity** ("each subdirectory is a complete atomic unit"). This sprint deliberately does NOT deduplicate the four bundles' identical scripts into a shared dir — that would violate this ADR. Instead it adds a *parity guard* that enforces the byte-identity the atomicity model silently depends on.
- **2026-05-20 line-anchored back-fill** (sprint 3) — relevance: any script change must keep selftest step 11 green; the refactor does not touch the back-fill.
- **2026-05-21 research budget enforced** (sprint 6) — relevance: `research-budget.sh` and `finalize-plan.sh` are refactor targets (both duplicate the sprint-number computation); their gate behavior must not change (selftest step 13).
- **2026-05-21 auto-mode stop criterion; merge AI-verifiable work** (sprint 8) — relevance: this ADR's consequences flag **"CI to run the guard + selftests is now the top backlog item — the guard only protects if something runs it."** No CI exists today; this sprint delivers it. Merging this sprint's green-CI PR autonomously is authorized by this ADR (and by the user's explicit "PR + auto-merge as the last step" instruction).
- **2026-05-22 plugin packaging / skill-only command** (sprints 9–10) — relevance: `check-plugin-manifest.sh` becomes a CI job; plugin.json currently carries **no version field** (trajectory item: version-stamping + `/plugin update` reload discipline).
- **2026-05-20 autonomy + workflow patterns baked into the skill** (sprint 3) — relevance: authored the CI-verify pattern in `phases/05-test-phase.md` and the loop-phase PR content this sprint extends with CI confirmations; the extension composes with (does not replace) that pattern.
- **2026-05-20 hard plan-mode + EARS criteria + decisions-reviewed gate** (sprint 4) — relevance: 05-test-phase's "one test per WHEN/THEN/SHALL triple" derivation governs the same file the CI-confirmation paragraph lands in; EARS derivation is untouched.

No prior decision is being violated. The bundle-sync guard *strengthens* the sprint-2 atomicity ADR rather than revising it.

## 1. Sprint Goal

Review the sprint-loop skill's own source (scripts, phases, schemas, tools, packaging), apply the refactors the review justifies, and produce an explicit improvement trajectory for future sprints. Delivery discipline: exactly one PR for the sprint, opened and auto-merged as the closing step, with the skill reloaded from the plugin at each sprint start.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| claude-code/skills/sprint-loop/SKILL.md | high | Routing + autonomy policy; loaded copy (plugin cache 6da2d66) verified byte-identical to repo HEAD |
| claude-code/skills/sprint-loop/phases/00-overview.md | high | Core protocol; consistent with scripts |
| claude-code/skills/sprint-loop/phases/01-init-sprint.md | med | Matches init-sprint.sh behavior |
| claude-code/skills/sprint-loop/phases/02-research-phase.md | high | Governs this phase; budget caps enforced via finalize-plan.sh |
| claude-code/skills/sprint-loop/phases/03-plan-phase.md | high | EnterPlanMode/ExitPlanMode hard primitive + critic protocol |
| claude-code/skills/sprint-loop/phases/04-build-phase.md | high | Pre-flight gate + defer-over-block; commit-per-task contract |
| claude-code/skills/sprint-loop/phases/06-loop-phase.md | high | PR/auto-merge policy; merge-on-green is AI-verifiable per sprint-8 ADR |
| claude-code/skills/sprint-loop/scripts/current-phase.sh | high | Clean; anchored greps per sprint-3 ADR |
| claude-code/skills/sprint-loop/scripts/current-sprint.sh | high | Canonical sprint-number helper; itself uses `ls \| grep` (SC2010) |
| claude-code/skills/sprint-loop/scripts/init-sprint.sh | high | Re-implements the LAST-sprint pipeline instead of calling current-sprint.sh |
| claude-code/skills/sprint-loop/scripts/commit-task.sh | med | GNU-only `sed -i '0,/…'`; documented pre-amend-hash quirk — leave as-is |
| claude-code/skills/sprint-loop/scripts/finalize-plan.sh | high | Duplicates LAST pipeline; three composable gates verified working |
| claude-code/skills/sprint-loop/scripts/research-budget.sh | high | Duplicates LAST pipeline; counter heuristics verified |
| claude-code/skills/sprint-loop/scripts/update-confidence.sh | med | No floor: `patched`/`failed` can drive confidence below 0.0 |
| claude-code/skills/sprint-loop/scripts/abort-sprint.sh | med | GNU-only `sed -i`; graceful no-tracked-change path |
| claude-code/skills/sprint-loop/scripts/selftest.sh | high | 14/14 green locally; the regression net for any script refactor |
| tools/check-merge-policy.sh + .test.sh | high | Guard green, fixture 4/4; SC2034 unused `GUARD` var in test |
| tools/check-plugin-manifest.sh | med | Green; python3-based, CI-safe on ubuntu runners |
| schemas/research-report.md + schemas/agent-tasks.md | med | Backlog schema only defines `(sprint N)` entries — no sprint-unassigned carry-forward form; `(backlog)` token would not collide with current-phase.sh's anchored `\(sprint $N\)` greps |
| decisions.md + agent-tasks/agent-tasks.md + completed-tasks.md (tail) | high | Backlog is EMPTY despite ADRs naming carry-forwards ("CI… top backlog item") — cross-sprint memory leak; trajectory items evaporate |

Directory-level comparisons (not file reads): `diff -rq` across all four bundles shows **scripts/ and schemas/ byte-identical in claude-code, codex-cli, antigravity-ide, open-harnesses**; prompts identical; phases differ only in 03 (plan-mode primitive) and 06 (harness-specific loop mechanics) between claude-code and codex-cli — both intentional per sprint-4/7 ADRs. `.github/workflows/` does not exist.

## 3. External Sources

- [array-test (crussella0129)](https://github.com/crussella0129/array-test) — user-authored design repo for deterministic, provable regression testing (Merkle DAG of content-addressed confirmations); reviewed during the Plan phase at the user's direction — see `## 6. Plan-phase addendum`.

(1/5 — no other external sources consulted; the rest of the evidence is local.)

## 4. Risks, Unknowns, Dependencies

- **Risk:** Cross-bundle parity is maintained by hand with no guard. One edit to a single bundle's script silently forks the four copies. (Mitigated by this sprint's parity guard.)
- **Risk:** The merge policy ("merge green-CI PRs autonomously") is currently vacuous — there is no CI, so "green CI" is unverifiable. This sprint's PR bootstraps CI *and* is the first PR gated by it.
- **Risk:** Refactoring scripts used by the very sprint in flight. Mitigated: refactors preserve behavior; selftest.sh runs from a throwaway temp project; per-task commits give rollback. The *running* skill executes from the plugin cache (pinned at 6da2d66), so mid-sprint edits to the repo cannot destabilize the in-flight loop.
- **Risk:** `gh pr merge --auto` requires repo auto-merge to be enabled; if not, fallback is watch-CI-then-merge (equivalent under the sprint-8 ADR — still gated on green CI). Resolve at Loop Phase.
- **Unknown:** shellcheck version on GitHub runners may flag differently than local 0.11.0. Mitigated: pin severity to `warning` and fix all local findings first; errors are already zero.
- **Dependency:** GitHub Actions availability on the repo (public repo, standard runners) — assumed present.
- **Unknown (accepted, out of scope):** BSD/macOS `sed -i` incompatibility in abort/commit scripts — queued as a trajectory item with a macOS CI matrix leg to make it observable, not fixed blind this sprint.

## 5. Recommended Approach

Primary: four elementary tasks in one PR-wrapped sprint —

1. **Bundle-parity guard**: `tools/check-bundle-sync.sh` asserting byte-identity of the shared assets across the four bundles (scripts ×4, schemas ×4, prompts ×3, phases 00/01/02/04/05 claude↔codex), with an explicit allowlist of intentionally divergent files; plus a fixture test proving it catches injected drift (same pattern as check-merge-policy.test.sh).
2. **DRY + lint refactor of scripts** (propagated identically to all four bundles): init-sprint.sh / finalize-plan.sh / research-budget.sh call `current-sprint.sh` instead of re-implementing the sprint-number pipeline; current-sprint.sh drops `ls | grep` for a glob loop (kills all four SC2010s); update-confidence.sh clamps at 0.0; fix SC2034 in check-merge-policy.test.sh. Behavior identical — selftest 14/14 stays green.
3. **CI**: `.github/workflows/ci.yml` running selftest.sh, check-merge-policy.sh + fixture test, check-plugin-manifest.sh, check-bundle-sync.sh + fixture test, and shellcheck (`-S warning`) on ubuntu-latest. This closes the sprint-8 "top backlog item" and makes the auto-merge policy meaningful.
4. **Trajectory**: `ROADMAP.md` at repo root (prioritized future-sprint candidates with rationale) + seed `agent-tasks/agent-tasks.md` with `(backlog)`-tagged carry-forwards (schema gains one line documenting the `(backlog)` form; token verified not to collide with current-phase.sh routing greps).

Alternative considered: **true deduplication** — a single canonical `scripts/` + `schemas/` source with install-time copying or symlinks. Rejected: violates the sprint-2 bundle-atomicity ADR (each bundle must be a complete, independently copyable unit), breaks the plugin's auto-discovery layout, and adds an install-time failure mode. A parity *guard* gets the same integrity without restructuring.

Alternative considered for trajectory: put carry-forwards only in ROADMAP.md (no backlog seeding). Rejected: the observed failure mode is precisely that decisions.md prose ("top backlog item") never became actionable backlog entries; the protocol's own long-term memory (`agent-tasks/`) is the right home, with ROADMAP.md as the human-readable rationale layer.

Rationale: every reviewed defect traces to one of two roots — hand-maintained duplication (bundles) and unenforced intentions (no CI, empty backlog). The four tasks close both roots with the smallest behavior-preserving diff, and the trajectory doc turns the remaining findings into future sprints instead of lost context.

## 6. Plan-phase addendum — array-test review (provenance for Component B)

At plan approval the user directed a review of https://github.com/crussella0129/array-test ("the testing phase could be even more deterministic and resilient if it lives in GitHub … these are just ideas … I do think working CI into that could help"). The repo is design-stage (sprint s0 complete; engine tasks T1–T8 unbuilt). Its architecture models the regression suite as a Merkle DAG of confirmations: content-addressed cells (`cell_key` = hash of code + deps + test + fixtures + seed + toolchain), hermetic execution with a run-twice determinism meta-check (D3), an append-only hash-chained ledger with a green Merkle root as certificate (D4), one sprint = one regression round (D5).

**Adopted this sprint (derived concepts, sized to a bash guard suite):** one canonical runner as the single suite definition for local + CI; per-suite ndjson confirmation records with normalized-output evidence hashes; the run-twice determinism meta-check in CI; CI conclusion on the head SHA as the authoritative confirmation recorded in test-report.md.

**Deferred (ROADMAP):** content-addressed cell keys + memoized skipping (suites run in seconds; cache-invalidation risk with no payoff yet), Merkle root + hash-chained ledger committed to the repo (commit churn; GitHub's immutable run logs + artifacts already give the audit surface), property/contract tiers (belong to array-test's own engine). Full integration is a future sprint gated on array-test T1–T5 shipping — the ROADMAP's "array-test integration first" refers to that engine integration, not to the derived concepts shipping now.

**Added risk (from this scope):** output-normalization brittleness — selftest prints mktemp paths, shellcheck output varies across versions, CRLF/locale differ between local git-bash and ubuntu runners. Mitigation: conservative normalization rules (strip temp paths, timestamps, CR), the `--determinism` double-run check itself, and `test_runner_nondeterminism_caught`; evidence hashes compare within a single environment (same run, or CI-run vs CI-rerun), never across OSes.

## Artifacts

None saved — all evidence is quoted inline or reproducible via the commands in section 2 (diff -rq across bundles; shellcheck summary; baseline suite runs: selftest 14/14, merge-policy 4/4 fixture catches, plugin-manifest OK).
