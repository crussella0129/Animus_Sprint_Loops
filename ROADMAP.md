# Roadmap — sprint-loops improvement trajectory

Written at sprint 11 (the self-review/refactor sprint). Each item below is a
future-sprint candidate, ordered by expected leverage. The actionable form of
this list lives in `agent-tasks/agent-tasks.md` as `(backlog)` entries (see
`schemas/agent-tasks.md`); this file carries the rationale. When a sprint picks
an item up, its Build Phase promotes the backlog entry to `(sprint N)`.

## 1. array-test engine integration

[array-test](https://github.com/crussella0129/array-test) models regression
testing as a Merkle DAG of content-addressed confirmations. Sprint 11 adopted
its *derived concepts* (canonical runner `tools/run-guards.sh`, per-suite
ndjson confirmations with normalized evidence hashes, the run-twice
determinism meta-check, CI-conclusion-as-authority). The full integration —
guards as content-addressed cells, memoized frontier-only re-runs, a Merkle
root as the Loop-phase gate — is **gated on array-test's engine shipping
(its T1–T5: content addressing, DAG resolver, hermetic runner, ledger,
frontier selection)**. When that lands, sprint-loops' Test phase becomes an
array-test round: `R_k` per sprint, green root fed to Loop.

**Deliberately deferred at sprint 11** (revisit when array-test T1–T5 exist):
- *Content-addressed cell keys + memoized skipping* — the guard suites run in
  seconds; a cache adds invalidation risk with no runtime payoff yet.
- *Merkle root + hash-chained ledger committed to the repo* — CI-run commit
  churn; GitHub's immutable run logs + uploaded artifacts already provide the
  audit surface at this scale.
- *Property/contract/formal tiers* — belong to array-test's own engine, not
  to a bash guard suite.

## 2. macOS/BSD portability + CI matrix leg

`abort-sprint.sh`, `commit-task.sh`, and `selftest.sh` use GNU-only `sed -i`
(and a GNU `0,/…/` address range in the back-fill). BSD/macOS sed breaks on
both. Fix portably (or document the GNU requirement), and add a `macos-latest`
leg to the CI matrix so the incompatibility is *observable* instead of
theoretical — the leg is the test.

## 3. critique.md hard-gate in finalize-plan.sh

Deferred since sprint 5: `finalize-plan.sh` could refuse to lock plans when
`sprints/sN/sprint-plans/critique.md` is absent, making the critic protocol
structurally enforced rather than instruction-enforced. The critic has caught
real defects in sprints 6, 7, 8, and 11 — it has earned the gate. (Test-phase
analogue: gate `test-report.md` on `sprint-tests/critique.md`.)

## 4. Plugin version discipline + documented reload

`claude-code/.claude-plugin/plugin.json` has no `version` field. Add one, bump
it each merged sprint, and document `/plugin update sprint-loop` (or
marketplace refresh) as the *reload step* a user runs so the next sprint picks
up the just-merged skill — the plugin cache pins a commit, so without a reload
a running loop keeps executing the old bundle. Also worth adding: the skill
printing its own bundle commit/version at Init so sprint-meta records which
skill version ran the sprint.

## 5. abort-sprint.sh no-git fallback

Old carry-forward (sprint 1 ADR consequence): `abort-sprint.sh` assumes a git
root for its close-out commit. In a non-git project the abort still works on
disk but exits non-zero. Detect and degrade gracefully.

## 6. Antigravity bundle parity

The antigravity-ide bundle carries scripts + schemas but its protocol layer is
a 49-line translation file (`global_workflows/sprint-loops.md`) that lags the
claude/codex phase docs (no critic protocol, no research budget, no CI
confirmations detail beyond the sprint-11 pointer sentence, and a PowerShell
installer driving bash scripts). Decide: either grow the translation layer to
full parity or document it as a deliberately thin adapter. Note (sprint 13):
antigravity's Plan sync-step adds the `Finalized - DO NOT EDIT` header *manually*
rather than via `finalize-plan.sh`, so the new critique gate (and every other
finalize-plan gate) does not bind there — the translation layer would need to
either call the script or replicate the gate to enforce the critic protocol.

## 7. Launch-time E2E harness

Two deferred human-verification checks would become automatable with a
launch-time harness (spawn a headless Claude Code session against a fixture
project): the picker-entry count (sprint 9/10) and `argument-hint`
auto-trigger survival (sprint 10's C-2). Today these are manual launch checks;
a scriptable E2E would move them into CI.

## 8. Confidence surfacing in sprint-meta

`confidence.txt` changes silently at Loop. Record the before → after value in
`sprint-meta.md` at close so a sprint's confidence trajectory is readable from
the sprint record without git archaeology.

## 9. Dev-branch working model + merge-mode election (user request, sprint 11)

At Init (sprint 0), establish — or verify the existence of — a long-lived
work branch (`dev` by default, name user-specifiable) alongside `main`.
Sprints develop on the work branch; each sprint's close opens a PR from it
back to `main`. With that model in place, the skill should **elicit the merge
mode at launch — approve-merge (human approves each sprint's PR) vs
auto-merge (merge on green CI proceeds autonomously) — unless the initial
prompt already specified it.** This turns the current implicit
branch-per-sprint convention into a declared, verifiable protocol step
(recordable in `sprint-meta.md`), and makes the merge-mode decision an
explicit contract instead of an inference from the prompt.
