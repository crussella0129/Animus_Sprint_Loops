# Completed Tasks Log (Append-Only)

## T-001 (sprint 0)
- **Description:** Add "build not started" disambiguator to `current-phase.sh` so a finalized-plan sprint with no queued tasks reports `build` instead of `test`.
- **Completed:** 2026-05-19T21:55:00Z
- **Files modified:** `open-harnesses/scripts/current-phase.sh`
- **Commit:** `94f41eb`

## T-002 (sprint 0)
- **Description:** Add `scripts/selftest.sh` that drives every phase transition and asserts `current-phase.sh` output at each step. First run caught a bug in the test's own `sed` pattern (line failed to match the `**Exit status:**` markdown formatting); fixed in the same task.
- **Completed:** 2026-05-19T21:57:00Z
- **Files modified:** `open-harnesses/scripts/selftest.sh` (new)
- **Commit:** `453cd40`

## T-003 (sprint 0)
- **Description:** Sync the fixed `current-phase.sh` and the new `selftest.sh` into the claude-code/loop-sprint and codex-cli/sprint-loops bundles. Verified md5 identity across all three copies and ran both bundles' selftests (8/8 transitions pass each).
- **Completed:** 2026-05-19T21:59:00Z
- **Files modified:** `claude-code/skills/loop-sprint/scripts/{current-phase.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/scripts/{current-phase.sh,selftest.sh}`
- **Commit:** `8083b84`

## T-001 (sprint 1)
- **Description:** `commit-task.sh` now back-fills the new commit's short hash into the FIRST `Commit:` line containing PENDING in `agent-tasks/completed-tasks.md` and folds the edit into the same commit via `git commit --amend --no-edit`. Positive-case sanity-tested in a temp repo: placeholder → `ff380ad`, exactly one commit recorded. Back-compat: no-op when no placeholder present.
- **Completed:** 2026-05-20T04:00:00Z
- **Files modified:** `open-harnesses/scripts/commit-task.sh`
- **Commit:** `3ba16e4`

## T-002 (sprint 1)
- **Description:** Added `scripts/abort-sprint.sh` taking a one-line reason: sets `sprint-meta.md` Exit status to `aborted`, records the end timestamp, appends an `## Abort note` section, and commits `sprint-N: aborted — <reason>`. Updated open-harnesses particles `06-build-phase.md` and `08-loop-phase.md` to document the abort path and the `aborted` exit status.
- **Scope expansion:** Surfaced during Build that `current-phase.sh` only checked Exit status at the bottom (to distinguish `loop` from `ready-for-next-sprint`), so an `aborted` status set mid-sprint was masked by upstream filesystem checks (research-report empty → returned `research` instead of `ready-for-next-sprint`). Hoisted the exit-status check to the top of `current-phase.sh`; all 8 sprint-0 selftest transitions still pass (regression-clean), and abort now routes correctly. Files modified beyond the plan: `open-harnesses/scripts/current-phase.sh`.
- **Completed:** 2026-05-20T05:16:00Z
- **Files modified:** `open-harnesses/scripts/abort-sprint.sh` (new), `open-harnesses/scripts/current-phase.sh`, `open-harnesses/particles/06-build-phase.md`, `open-harnesses/particles/08-loop-phase.md`
- **Commit:** `df1c102`

## T-003 (sprint 1)
- **Description:** Extended `selftest.sh` with step 09 (init a second sprint, abort it via `abort-sprint.sh`, assert `current-phase.sh` reports `ready-for-next-sprint`); synced `commit-task.sh`, `abort-sprint.sh`, the hoisted `current-phase.sh`, and the new 9-step `selftest.sh` into both skill bundles; propagated the abort docs into both bundles' `phases/04-build-phase.md` and `phases/06-loop-phase.md`. Verified md5 identity across all 3 bundles for the 4 scripts, both bundles' selftests now report 9/9 transitions matched, and the touched phase files are byte-identical between claude-code and codex-cli.
- **Completed:** 2026-05-20T05:18:00Z
- **Files modified:** `claude-code/skills/loop-sprint/scripts/{commit-task.sh,abort-sprint.sh,current-phase.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/scripts/{commit-task.sh,abort-sprint.sh,current-phase.sh,selftest.sh}`, `open-harnesses/scripts/selftest.sh`, `claude-code/skills/loop-sprint/phases/{04-build-phase.md,06-loop-phase.md}`, `codex-cli/skills/sprint-loops/phases/{04-build-phase.md,06-loop-phase.md}`
- **Commit:** `83e0edf`

## T-001 (sprint 2)
- **Description:** `finalize-plan.sh` now refuses to lock a `build-plan.md` with zero `^### T-[0-9]+:` execution entries (would otherwise route to `build` and loop forever). Updated `selftest.sh` step 04 to write a real `### T-001: demo` entry, and added step 10 exercising the rejection path — finalize on an empty plan must exit non-zero AND leave the file unmodified. 10/10 selftest transitions pass.
- **Completed:** 2026-05-20T15:00:00Z
- **Files modified:** `open-harnesses/scripts/finalize-plan.sh`, `open-harnesses/scripts/selftest.sh`
- **Discovered flaws in sprint 1's back-fill (flagged for sprint 3):**
  1. The Commit-line regex isn't line-anchored, so it matched a literal
     substring inside this very `## T-001 (sprint 1)` description block. Must
     anchor with `^- \*\*Commit:\*\* <token>`.
  2. `git rev-parse --short HEAD` is captured BEFORE the amend, so the embedded
     hash is the pre-amend HEAD, not the final post-amend HEAD. The two differ.
     Fix: capture hash AFTER amend (or reverse the order — sed-write a marker,
     amend, then capture the amended HEAD into the file).
- **Commit:** `0fa8972` (manually corrected post-amend — sprint 1's back-fill embedded the pre-amend hash `1cdd538`)

## T-002 (sprint 2)
- **Description:** Added three idempotent installer scripts: `claude-code/install.sh` (target: `~/.claude/skills/sprint-loop/` + `~/.claude/commands/sprint-loop.md`, with `--project` flag for cwd-local install), `codex-cli/install.sh` (target: `~/.codex/skills/sprint-loops/` with AGENTS.md fragment reminder), `open-harnesses/install.sh [target]` (copies `scripts/` to a project root, default cwd). Each wipes the prior install at the target before copying — running twice is a no-op (verified by md5 tree-hash). Integration-tested: `install.sh` → `selftest.sh` end-to-end.
- **Completed:** 2026-05-20T15:10:00Z
- **Files modified:** `claude-code/install.sh` (new), `codex-cli/install.sh` (new), `open-harnesses/install.sh` (new)
- **Commit:** `2d53e35` (manual — sprint 1 back-fill bug fired again on the sprint-1 T-001 description text and missed this entry's actual Commit field)

## T-003 (sprint 2)
- **Description:** Synced the updated `finalize-plan.sh` (empty-plan rejection) and `selftest.sh` (10-step version with new step 10 for empty-plan rejection) into both skill bundles. Verified md5 identity across all 3 bundles. Both bundles' selftests now report `all 10 transitions matched`.
- **Completed:** 2026-05-20T15:15:00Z
- **Files modified:** `claude-code/skills/sprint-loop/scripts/{finalize-plan.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/scripts/{finalize-plan.sh,selftest.sh}`
- **Commit:** `c6c06b9` (manual — same back-fill bug; reworded the sprint-1 T-001 description so the literal substring no longer appears verbatim, breaking the recurrence cycle)

## T-001 (sprint 3)
- **Description:** Line-anchored the back-fill regex in `commit-task.sh` (`^- \*\*Commit:\*\* PENDING$`) so it no longer matches substrings inside other entries' description text. Tightened the corresponding greps in `current-phase.sh` to require `\(sprint $N\)` (literal parens, matching the schema's task-reference format) so prose mentions like "flagged for sprint 3" don't false-positive. Documented the off-by-one-amend hash as an intentional trade-off (single amend keeps it simple; agents can find the actual commit via `git log --grep "sprint-N: T-XXX"`). `selftest.sh` gains step 11 exercising line-anchored back-fill with a description containing the literal `Commit:** PENDING` substring AND a real anchored field — asserts the prose is untouched and the real field gets filled.
- **Scope expansion:** Tightening `current-phase.sh` was added mid-Build when the same bug-class corrupted routing in this sprint (matched "flagged for sprint 3"). Documented in `sprints/s3/sprint-meta.md`.
- **Completed:** 2026-05-20T15:50:00Z
- **Files modified:** `open-harnesses/scripts/{commit-task.sh,current-phase.sh,selftest.sh}`
- **Commit:** `89173b7` (manual — OLD personal-install back-fill fired one last time; mid-sprint sync of new commit-task.sh follows so the rest of sprint 3 uses the fixed version)

## T-002 (sprint 3)
- **Description:** Baked autonomy + workflow patterns into the skill: SKILL.md gained "Autonomous operation" (work independently in multi-turn loops, commit/push/merge without per-step confirmation, defer-over-block, one-PR-per-concept) and "Safety floor" (don't weaken permissions/security, don't `--no-verify` hooks, hard-to-reverse actions pause for confirmation even in autonomous mode); `phases/04-build-phase.md` gained a Pre-flight section (rebase against base + project sanity gate before each `commit-task.sh`) and a strengthened defer-over-block paragraph; `phases/05-test-phase.md` gained the CI verify pattern (separate `gh run list` after `gh run watch` because watch exit code is unreliable on Windows); `phases/06-loop-phase.md` gained an optional PR-merge step on CI green with `gh pr merge --merge --delete-branch` and a PR-body-via-heredoc snippet. Parallel single-sentence integrations added to open-harnesses particles 06/07/08 inside their existing quoted blocks (preserves embedding density for retrieval-based harnesses).
- **Completed:** 2026-05-20T16:00:00Z
- **Files modified:** `claude-code/skills/sprint-loop/SKILL.md`, `claude-code/skills/sprint-loop/phases/{04-build-phase.md,05-test-phase.md,06-loop-phase.md}`, `open-harnesses/particles/{06-build-phase.md,07-test-phase.md,08-loop-phase.md}`
- **Commit:** `0520555` (pre-amend; final HEAD `aa528ca` — back-fill working correctly, off-by-one is the documented trade-off)

## T-003 (sprint 3)
- **Description:** Synced the updated `commit-task.sh`, `current-phase.sh`, and `selftest.sh` to both skill bundles; md5-identical across all 3 bundles. Propagated the autonomy-related phase updates (`04-build-phase.md`, `05-test-phase.md`, `06-loop-phase.md`) from claude-code/sprint-loop to codex-cli/sprint-loops; `diff -q` empty. Added matching "Autonomous operation" and "Safety floor" H2 sections to codex's SKILL.md (kept codex's existing routing/approval-modes/subagent sections intact). Both bundles' selftests run 11/11.
- **Completed:** 2026-05-20T16:05:00Z
- **Files modified:** `claude-code/skills/sprint-loop/scripts/{commit-task.sh,current-phase.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/scripts/{commit-task.sh,current-phase.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/phases/{04-build-phase.md,05-test-phase.md,06-loop-phase.md}`, `codex-cli/skills/sprint-loops/SKILL.md`
- **Commit:** `1266b0f`

## T-001 (sprint 4)
- **Description:** Replaced the soft "Engage plan mode now" instruction in `phases/03-plan-phase.md` with a hard tool-call protocol — `EnterPlanMode` at phase entry, plan synthesis with filesystem reads only, `ExitPlanMode` with a two-section summary for user approval, then drop to normal mode to write `build-plan.md` and `test-plan.md` and run `finalize-plan.sh`. SKILL.md "Plan mode" section rewritten to describe the tool-call protocol explicitly. Codex retains `/plan`; open-harnesses keeps generic language.
- **Completed:** 2026-05-20T19:10:00Z
- **Files modified:** `claude-code/skills/sprint-loop/phases/03-plan-phase.md`, `claude-code/skills/sprint-loop/SKILL.md`
- **Commit:** `44d82b8`

## T-002 (sprint 4)
- **Description:** EARS-format (`WHEN <trigger> THEN <component> SHALL <response>`) success criteria adopted across the schema and the Plan/Test phase docs. `schemas/build-plan.md` example updated; `phases/03-plan-phase.md` mandates EARS for each task's success criterion; `phases/05-test-phase.md` documents one-`test_*`-per-WHEN/THEN/SHALL-triple derivation. Open-harnesses particles 04 (Build Plan Schema) and 05 (Test Plan Schema) gained single-sentence EARS integrations inside their quoted blocks. Freeform criteria still parse as fallback.
- **Completed:** 2026-05-20T19:25:00Z
- **Files modified:** `open-harnesses/schemas/build-plan.md`, `open-harnesses/particles/04-build-plan-schema.md`, `open-harnesses/particles/05-test-plan-schema.md`, `claude-code/skills/sprint-loop/phases/03-plan-phase.md`, `claude-code/skills/sprint-loop/phases/05-test-phase.md`
- **Commit:** `66f6ad7`

## T-003 (sprint 4)
- **Description:** Mandatory `decisions.md` read enforced at plan-lock time. `phases/02-research-phase.md` now instructs reading `decisions.md` first and recording relevant ADRs in a `## Decisions Reviewed` section (with explicit acknowledgment of any proposed revisions). `schemas/research-report.md` documents the section. `open-harnesses/particles/02-research-phase.md` got a matching single-sentence integration. `finalize-plan.sh` gained a pre-lock gate: when `decisions.md` is non-empty and has any `## ` entries, the current sprint's research-report MUST contain a `## Decisions Reviewed` (or `## N. Decisions Reviewed`) heading. The grep pattern is permissive over numeric prefixes (line-anchored discipline from sprint 3). Skips on empty/absent decisions.md so sprint 0 / new projects work unchanged. Sanity-tested all four cases: empty-decisions-skips-check, non-empty-without-section-refuses, non-empty-with-section-accepts, numbered-heading-accepts.
- **Completed:** 2026-05-20T19:45:00Z
- **Files modified:** `open-harnesses/scripts/finalize-plan.sh`, `open-harnesses/schemas/research-report.md`, `open-harnesses/particles/02-research-phase.md`, `claude-code/skills/sprint-loop/phases/02-research-phase.md`
- **Commit:** `fcdf7e1`

## T-004 (sprint 4)
- **Description:** Selftest step 12 added (exercises the Decisions-Reviewed gate via temp project with non-empty `decisions.md` + research-report missing the section → finalize-plan must refuse). Synced `finalize-plan.sh` and `selftest.sh` to both bundles (md5 identical across all 3). Synced `schemas/{build-plan.md,research-report.md}` to both bundles (diff-clean). Synced `phases/02-research-phase.md` and `phases/05-test-phase.md` verbatim to codex bundle. Adapted codex `phases/03-plan-phase.md` to keep `/plan` opening while inheriting EARS guidance and the Decisions-reviewed gate documentation (claude retains the `EnterPlanMode`/`ExitPlanMode` opening from T-001). Both bundles' selftests report `all 12 transitions matched`.
- **Completed:** 2026-05-20T20:00:00Z
- **Files modified:** `claude-code/skills/sprint-loop/scripts/{finalize-plan.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/scripts/{finalize-plan.sh,selftest.sh}`, `claude-code/skills/sprint-loop/schemas/{build-plan.md,research-report.md}`, `codex-cli/skills/sprint-loops/schemas/{build-plan.md,research-report.md}`, `codex-cli/skills/sprint-loops/phases/{02-research-phase.md,03-plan-phase.md,05-test-phase.md}`, `open-harnesses/scripts/selftest.sh`
- **Commit:** `69fa7f9`

## T-001 (sprint 5)
- **Description:** Added two critic prompt templates as canonical files in `open-harnesses/prompts/`. `plan-critic.md` instructs the critic subagent to screen for 7 failure modes (vague EARS, plan-test mismatch, missing risk coverage, hidden deps, ignored ADRs, granularity violations, E2E drift) and return a structured `## Concerns` + `## Confidence` (clean / proceed-with-caveats / block) critique. `test-critic.md` mirrors for the Test Phase, screening for EARS-clause coverage gaps, weak assertions, stub leakage, integration scope drift, E2E cop-out, missing negative-paths, flake risk. Both prompts are read-only — the critic identifies; the primary agent decides.
- **Completed:** 2026-05-20T20:45:00Z
- **Files modified:** `open-harnesses/prompts/plan-critic.md` (new), `open-harnesses/prompts/test-critic.md` (new)
- **Commit:** `2e62a14`

## T-002 (sprint 5)
- **Description:** Wired the spawn-review-address protocol into `claude-code/skills/sprint-loop/phases/03-plan-phase.md` (new "Critic review (before lock)" section between ExitPlanMode and finalize) and `phases/05-test-phase.md` (new "Critic review (before finalizing test-report)" section between CI verify and finalize). Both instruct: spawn Agent with the matching critic prompt → save critique to `sprint-{plans,tests}/critique.md` → address each concern inline (fix / defer / reject) → only then lock. Fallback documented for harnesses without subagent primitives: self-critique against the same prompt's failure-mode list. Open-harnesses particles 03 and 07 got parallel single-sentence integrations inside their existing quoted blocks pointing to `../prompts/{plan,test}-critic.md`.
- **Completed:** 2026-05-20T20:55:00Z
- **Files modified:** `claude-code/skills/sprint-loop/phases/03-plan-phase.md`, `claude-code/skills/sprint-loop/phases/05-test-phase.md`, `open-harnesses/particles/03-plan-phase.md`, `open-harnesses/particles/07-test-phase.md`
- **Commit:** `24cad86`

## T-003 (sprint 5)
- **Description:** Copied both critic prompt templates into `claude-code/skills/sprint-loop/prompts/` and `codex-cli/skills/sprint-loops/prompts/` — md5-identical across all 3 locations. Synced `phases/05-test-phase.md` claude→codex (verbatim, byte-identical). For `phases/03-plan-phase.md`, claude's EnterPlanMode opening was kept; codex's `/plan` opening was restored, with the same "Critic review (before lock)" section preserved in both. Added a paragraph to codex's `SKILL.md` "Subagent opportunity" section cross-referencing both critic prompts and the protocol. Both bundles' selftests stay at 12/12 (no selftest extension this sprint — the critic step is LLM-execution-level, exercised by next manual sprint).
- **Completed:** 2026-05-20T21:05:00Z
- **Files modified:** `claude-code/skills/sprint-loop/prompts/{plan-critic.md,test-critic.md}` (new), `codex-cli/skills/sprint-loops/prompts/{plan-critic.md,test-critic.md}` (new), `codex-cli/skills/sprint-loops/phases/{03-plan-phase.md,05-test-phase.md}`, `codex-cli/skills/sprint-loops/SKILL.md`
- **Commit:** `001d701`

## T-001 (sprint 6)
- **Description:** Added `scripts/research-budget.sh` — counts data rows under `## (N. )? Existing Code Survey` (awk-slices the section, counts `^\|` lines, subtracts 2 for header+separator) and URL bullets under `## (N. )? External Sources`; prints `files=N sources=M`, exits non-zero if N>20 or M>5. Wired into `finalize-plan.sh` as a third gate: when over budget, requires a `## Budget Override` heading with a non-whitespace body line, else refuses to lock. Two real bugs caught during Build by running: (1) the plan critic's C-001 overcounting (separator `|---|` doesn't match `^\| ` with a space — switched to `^\|` and subtract 2); (2) `finalize-plan.sh` referenced `$SCRIPT_DIR` without defining it (crash under `set -u`) — added the standard `SCRIPT_DIR` resolution. Cosmetic awk `\.`→`[.]` cleanup.
- **Completed:** 2026-05-21T00:05:00Z
- **Files modified:** `open-harnesses/scripts/research-budget.sh` (new), `open-harnesses/scripts/finalize-plan.sh`
- **Commit:** `e8c08d1`

## T-002 (sprint 6)
- **Description:** Documented the budget gate + override. `phases/02-research-phase.md` now states the 20/5 caps are enforced, names `research-budget.sh`, and explains the `## Budget Override` escape (non-empty justification, sparing use; 30-min cap stays honor-system). `schemas/research-report.md` gained an optional `## Budget Override` section in the template. `open-harnesses/particles/02-research-phase.md` got a parallel single-sentence integration inside its quoted block.
- **Completed:** 2026-05-21T00:12:00Z
- **Files modified:** `claude-code/skills/sprint-loop/phases/02-research-phase.md`, `open-harnesses/schemas/research-report.md`, `open-harnesses/particles/02-research-phase.md`
- **Commit:** `de77822`

## T-003 (sprint 6)
- **Description:** Added selftest step 13 (over-budget research-report with no override → finalize refuses + not locked; add `## Budget Override` → locks). Synced `research-budget.sh` (new), `finalize-plan.sh`, `selftest.sh` to both bundles (md5-identical across all 3). Synced `schemas/research-report.md` and `phases/02-research-phase.md` to codex (diff-clean vs claude). Both bundles' selftests report `all 13 transitions matched`.
- **Completed:** 2026-05-21T00:20:00Z
- **Files modified:** `open-harnesses/scripts/selftest.sh`, `claude-code/skills/sprint-loop/scripts/{research-budget.sh,finalize-plan.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/scripts/{research-budget.sh,finalize-plan.sh,selftest.sh}`, `claude-code/skills/sprint-loop/schemas/research-report.md`, `codex-cli/skills/sprint-loops/{schemas/research-report.md,phases/02-research-phase.md}`
- **Commit:** `accba20`

## T-001 (sprint 7)
- **Description:** Made `EnterPlanMode` the explicit mandatory first action in claude-code `phases/03-plan-phase.md` (not prose). Added a "The plan-approval prompt is where you choose auto mode" section: interactive → review/approve normally; unattended → select auto-accept ("auto mode") at the ExitPlanMode prompt — that selection is what carries Build/Test/Loop without per-step confirmation. Resolves the earlier ExitPlanMode-hang misconception (auto-accept IS the answer to that prompt).
- **Completed:** 2026-05-21T01:30:00Z
- **Files modified:** `claude-code/skills/sprint-loop/phases/03-plan-phase.md`
- **Commit:** `5d79d89`

## T-002 (sprint 7)
- **Description:** SKILL.md "Plan mode" now states the ExitPlanMode prompt is where auto-accept ("auto mode") is selected for unattended runs. "Autonomous operation" rewritten as two mechanisms (auto-accept selection + `/loop /sprint-loop continue` recurrence with re-fire → re-run current-phase.sh → resume), fixed the old "merge your own PRs" line, and added a bounding recommendation (unbounded loop runs until interrupt). "Safety floor" gained an explicit "auto-accept ≠ auto-merge" clause. Crucially, `phases/06-loop-phase.md` step 6 PR-merge is now GATED: interactive/opt-in merges; unattended auto mode leaves the PR open for human review — resolving the live SKILL.md-vs-loop-phase auto-merge contradiction the plan critic caught (C-004).
- **Completed:** 2026-05-21T01:40:00Z
- **Files modified:** `claude-code/skills/sprint-loop/SKILL.md`, `claude-code/skills/sprint-loop/phases/06-loop-phase.md`
- **Commit:** `f7cc3cb`

## T-003 (sprint 7)
- **Description:** Documented the unattended launch in `commands/sprint-loop.md` (`/loop 3 /sprint-loop continue` + auto-accept selection + bounding + no-auto-merge). Propagated the PR-merge gate to `codex-cli/skills/sprint-loops/phases/06-loop-phase.md` (unattended `codex exec` leaves PR open) and to `open-harnesses/particles/08-loop-phase.md` (human-gated merge + a note that a recurring-invocation primitive like `/loop` can drive recurrence). Added an "Unattended / auto mode (Claude-specific)" section to `claude-code/README.md` noting Codex's equivalent is `codex exec`.
- **Completed:** 2026-05-21T01:50:00Z
- **Files modified:** `claude-code/commands/sprint-loop.md`, `codex-cli/skills/sprint-loops/phases/06-loop-phase.md`, `open-harnesses/particles/08-loop-phase.md`, `claude-code/README.md`
- **Commit:** `3729291`

## T-001 (sprint 8)
- **Description:** Reframed SKILL.md autonomy around the human-verification stop criterion. "Autonomous operation" now allows committing/pushing/merging AI-verifiable work without per-step pauses. New "The stop criterion: halt only for what AI cannot verify" section enumerates the four checkpoint categories — (a) visual/UX, (b) irreversible OR unknown-blast-radius (default-to-stop on uncertainty), (c) product ambiguity, (d) unrecoverable failure — and states AI-verifiable work (green CI, reversible, known-reversible merges) proceeds. Bounding demoted to optional; runaway control = commit-rollback + checkpoints + interrupt. "Safety floor" reframed as the non-negotiable subset (the category-2 items).
- **Completed:** 2026-05-21T03:00:00Z
- **Files modified:** `claude-code/skills/sprint-loop/SKILL.md`
- **Commit:** `65eb24c`

## T-002 (sprint 8)
- **Description:** Re-scoped the Loop-Phase PR-merge step in all three copies (claude 06, codex 06, particle 08): merge AI-verifiable green-CI work autonomously when the consequence is known-and-reversible; STOP and surface when the effect is unverifiable OR undeterminable (deploy/release/unknown blast radius — "can't verify" includes "can't determine the consequence"). Added a visual-review checkpoint (surface UI/rendered artifacts for human inspection). Added committed `tools/check-merge-policy.sh` — a durable, re-runnable consistency guard (CI hook) that asserts all merge-policy docs pair merge guidance with a checkpoint qualifier, retain no blanket "do NOT merge", and that SKILL.md agrees. Proven to catch injected drift (exits non-zero), then revert clean.
- **Completed:** 2026-05-21T03:15:00Z
- **Files modified:** `claude-code/skills/sprint-loop/phases/06-loop-phase.md`, `codex-cli/skills/sprint-loops/phases/06-loop-phase.md`, `open-harnesses/particles/08-loop-phase.md`, `tools/check-merge-policy.sh` (new)
- **Commit:** `1882ed1`

## T-003 (sprint 8)
- **Description:** Reframed `commands/sprint-loop.md` and `claude-code/README.md` auto-mode sections to lead with "runs unattended; stops only at human-verification checkpoints," listing the categories and stating AI-verifiable work (incl. known-reversible merges) proceeds. Demoted bounding to an optional cap (`/loop N`), no longer the headline. Kept the Claude-specific note. Launch example simplified to `/loop /sprint-loop continue`.
- **Completed:** 2026-05-21T03:25:00Z
- **Files modified:** `claude-code/commands/sprint-loop.md`, `claude-code/README.md`
- **Commit:** `2d6c6b2`

## T-001 (sprint 11)
- **Description:** Added tools/check-bundle-sync.sh — cross-bundle parity guard enforcing the measured map (scripts+schemas ×4 bundles, prompts ×3, phases 00/01/02/04/05 claude↔codex; intentional divergences documented in header; BUNDLE_SYNC_ROOT override for fixtures). Fixture test proves real catches: content drift, deleted mirror file, extra mirror file, drifted shared phase — 5/5, plus clean-baseline pass. Guard green on the real tree.
- **Completed:** 2026-07-03T00:00:00Z
- **Files modified:** `tools/check-bundle-sync.sh` (new), `tools/check-bundle-sync.test.sh` (new)
- **Commit:** `3f0a626`

## T-002 (sprint 11)
- **Description:** Behavior-preserving refactor: current-sprint.sh now derives the sprint number with a glob/case loop (no `ls | grep`, SC2010 gone) and is the single source for init-sprint.sh / finalize-plan.sh / research-budget.sh (each calls it via SCRIPT_DIR; `-1` maps to their existing empty-case paths). Propagated byte-identically to codex-cli, antigravity-ide, open-harnesses (bundle-sync green). Fixed check-merge-policy.test.sh: SC2034's unused GUARD was the smell for a REAL bug — `"$GUARD_T"` invoked a quoted "bash /path" string (exit 127), so all three drift cases passed vacuously since sprint 8; now invoked as `bash "$GUARD_T"`. Making the test real exposed a second latent false-pass: case 3's phrase-level sed spanned the hard-wrapped SKILL.md line 98 and silently no-opped; mutation now deletes permit lines wholesale. Fixture 4/4 genuinely caught; selftest 14/14; shellcheck -S warning clean; current-sprint.sh prints 11 here, -1 on bare/empty trees.
- **Completed:** 2026-07-03T00:00:00Z
- **Files modified:** `{claude-code/skills/sprint-loop,codex-cli/skills/sprint-loops,antigravity-ide/skills/sprint-loop,open-harnesses}/scripts/{current-sprint.sh,init-sprint.sh,finalize-plan.sh,research-budget.sh}`, `tools/check-merge-policy.test.sh`
- **Commit:** `83066af`

## T-003 (sprint 11)
- **Description:** update-confidence.sh now clamps at a 0.0 floor for `patched`/`failed` (mirroring the existing 1.0 cap for `pass`); a negative confidence is meaningless for the <0.5 task-count throttle. Verified: 0.2 + failed -> 0.0; 0.9 + pass -> 1.0. Propagated ×4 bundles; bundle-sync green; lint clean.
- **Completed:** 2026-07-03T00:00:00Z
- **Files modified:** `{4 bundles}/scripts/update-confidence.sh`
- **Commit:** `fb1ec77`

## T-004 (sprint 11)
- **Description:** Added tools/run-guards.sh — canonical suite runner (single suite definition for local Test phase + CI; array-test-derived). Emits one ndjson confirmation per suite {suite, script_hash, status, evidence_hash, duration_s, ts} with normalized output hashing (CR/temp-path/ISO-timestamp stripped); --determinism runs each suite twice and fails on hash/rc mismatch; RUN_GUARDS_EXTRA_SUITES injects stub suites for testing; fails fast (exit 2) if the confirmations file is unwritable — a runner that can't record must not report success. Verified: 7/7 green with well-formed records; failing stub -> status FAIL + exit 1 with later suites still recorded; $RANDOM stub under --determinism -> named on stderr, "determinism":"mismatch", exit 1; all 7 real suites determinism-ok. guards-report.ndjson added to .gitignore.
- **Completed:** 2026-07-03T00:00:00Z
- **Files modified:** `tools/run-guards.sh` (new), `.gitignore`
- **Commit:** `d035d04`

## T-005 (sprint 11)
- **Description:** Added .github/workflows/ci.yml — first CI for the repo (closes the sprint-8 ADR's "top backlog item"). Push (all branches) + PR-to-main triggers; single ubuntu-latest job runs `tools/run-guards.sh --determinism`, publishes the ndjson confirmations to the step summary and uploads them as an artifact (both `if: always()`). YAML validated: triggers, run-guards invocation, step-summary write, artifact upload all asserted (test_yaml_parses PASS). Live green-path conclusion is the Test phase's E2E check after branch push.
- **Completed:** 2026-07-03T00:00:00Z
- **Files modified:** `.github/workflows/ci.yml` (new)
- **Commit:** `6c9e29b`

## T-006 (sprint 11)
- **Description:** Test-phase protocol now records CI confirmations: schemas/test-report.md (×4 bundles) gains a `## CI Confirmation` block (head SHA, run ID/URL, authoritative conclusion via gh run list, confirmations reference, and the "CI not configured — local confirmations only" fallback); phases/05-test-phase.md (claude+codex identical) gains a "Canonical runner & confirmations" section directing the Test Phase at the project's canonical runner with CI-conclusion-on-head-SHA as authoritative; one-sentence integrations in open-harnesses particle 07 and antigravity global_workflows Phase 5. All presence greps pass; bundle-sync + merge-policy green.
- **Completed:** 2026-07-03T00:00:00Z
- **Files modified:** `{4 bundles}/schemas/test-report.md`, `{claude,codex}/phases/05-test-phase.md`, `open-harnesses/particles/07-test-phase.md`, `antigravity-ide/global_workflows/sprint-loops.md`
- **Commit:** `3b8eba4`

## T-007 (sprint 11)
- **Description:** Documented the `(backlog)` carry-forward entry form: schemas/agent-tasks.md (×4 bundles) now defines both entry forms — `(sprint N)` (routing-relevant) and `(backlog)` (sprint-unassigned, T-1xx IDs, promoted by a future Build phase, never affects routing). Loop docs (claude 06, codex 06, oh particle 08) instruct appending deferred follow-ups as `(backlog)` entries so carry-forwards live as actionable backlog, not decisions.md prose. Routing safety verified with a real fixture (2 `(backlog)` entries present at plan/build/test states — phase output identical to empty backlog; earlier attempt was caught appending nothing due to a printf option-parse and redone). bundle-sync + merge-policy green.
- **Completed:** 2026-07-03T00:00:00Z
- **Files modified:** `{4 bundles}/schemas/agent-tasks.md`, `{claude,codex}/phases/06-loop-phase.md`, `open-harnesses/particles/08-loop-phase.md`
- **Commit:** `347fab8`

## T-008 (sprint 11)
- **Description:** Added ROADMAP.md — the improvement trajectory: 8 prioritized future-sprint candidates with rationale (1 array-test engine integration gated on its T1–T5, incl. the explicit Merkle/memoization deferral rationale; 2 macOS/BSD portability + CI matrix leg; 3 critique.md hard-gate; 4 plugin version + documented /plugin update reload; 5 abort no-git fallback; 6 antigravity parity decision; 7 launch-time E2E harness; 8 confidence surfacing in sprint-meta). Seeded agent-tasks.md with T-101..T-108 (backlog) entries — 8/8 match the documented form; routing unaffected (current-phase still correct).
- **Completed:** 2026-07-03T00:00:00Z
- **Files modified:** `ROADMAP.md` (new), `agent-tasks/agent-tasks.md`
- **Commit:** `b11aea0`

## T-001 (sprint 12)
- **Description:** All GNU-only in-place edits removed (promoted from backlog T-102): abort-sprint.sh's two `sed -i` calls merged into one two-expression sed via tmp+mv; commit-task.sh's GNU `0,/…/` range replaced by awk whole-line-equality first-match-only back-fill (exactly equivalent match set, per plan-critique C-004); selftest.sh's two `sed -i` fixture edits → tmp+mv; check-merge-policy.test.sh's GNU `I` flag → `grep -iv` with the exit-1 nuance guarded. Propagated ×4 bundles. Verified: zero `sed -i` matches, shellcheck clean, selftest 14/14 (abort step 09 + back-fill step 11 exercised the rewrites), merge-policy fixture 4/4, bundle-sync parity green.
- **Completed:** 2026-07-04T00:00:00Z
- **Files modified:** `{4 bundles}/scripts/{abort-sprint.sh,commit-task.sh,selftest.sh}`, `tools/check-merge-policy.test.sh`
- **Commit:** `d4166c7`

## T-004 (sprint 12)
- **Description:** selftest step 15: double-PENDING fixture asserting the back-fill's first-match-only contract — first anchored placeholder filled with backticked hash, second placeholder AND prose token mention untouched. Negative arm verified: a throwaway commit-task.sh with the awk done-guard stripped makes step 15 FAIL (fill-all regression genuinely caught). Selftest now reports "all 15 transitions matched". Propagated ×4; lint + bundle-sync green.
- **Completed:** 2026-07-04T00:00:00Z
- **Files modified:** `{4 bundles}/scripts/selftest.sh`
- **Commit:** `a365317`

## T-002 (sprint 12)
- **Description:** run-guards.sh portable hashing + normalization: hash_stdin() auto-detects sha256sum vs shasum -a 256 with RUN_GUARDS_HASH_TOOL as the explicit test seam (plan-critique C-003); both call sites switched. normalize() now strips /private/var/folders/... and /var/folders/... (macOS mktemp) ahead of the /tmp/tmp.* rule. Verified: hash seam yields identical digests via both tools on the real function; per-run-varying /var/folders stub under --determinism -> ok; full round 7/7 with every unchanged suite's evidence hash byte-equal to the s11 committed baseline (only selftest re-baselined — its output legitimately grew step 15); shellcheck clean.
- **Completed:** 2026-07-04T00:00:00Z
- **Files modified:** `tools/run-guards.sh`
- **Commit:** `99ddc58`

## T-003 (sprint 12)
- **Description:** CI workflow now runs the guard suite on an os-matrix: ubuntu-latest + macos-latest, fail-fast: false (a red leg preserves the other leg's evidence), per-OS artifact names (guards-report-<os>, upload-artifact@v4 duplicate-name rule), and an install-shellcheck-if-missing step (brew path for macOS; no-ops on ubuntu). Runner invocation unchanged. YAML assertions all pass (test_yaml_matrix). The macos leg's live green run is the sprint's E2E, verified at Test phase.
- **Completed:** 2026-07-04T00:00:00Z
- **Files modified:** `.github/workflows/ci.yml`
- **Commit:** `55bf553`

## T-001 (sprint 13)
- **Description:** finalize-plan.sh gains a fourth gate (executing the sprint-5 ADR's deferred hard gate): a valid plan critique.md is required to lock. Gate checks non-empty file + `## Concerns` heading + the `## Confidence` verdict (first non-empty line after the heading, awk-extracted, line-scoped so prose "block"/"unblocked" can't false-match) starting with clean/proceed-with-caveats (backticked or bare); block/malformed/missing refuse with a shape-stating message. Empty-plan check hoisted out of the lock loop to run BEFORE the critique gate (keeps selftest's empty-plan step isolating its own failure). selftest: write_ok_critique helper + fixtures on the two success-path finalize calls (steps 04, 13); new steps 16 (refuse-missing) + 17 (refuse-block then lock-on-valid). "all 17 transitions matched". Verified edges: malformed verdict → exit 1 unlocked; prose false-match → locks. POSIX-portable; propagated ×4; bundle-sync + shellcheck green.
- **Completed:** 2026-07-04T00:00:00Z
- **Files modified:** `{4 bundles}/scripts/{finalize-plan.sh,selftest.sh}`
- **Commit:** `ecae152`

## T-002 (sprint 13)
- **Description:** current-phase.sh test→loop pass path now requires sprint-tests/critique.md alongside test-report.md (existence-only; content validation stays at lock time). Failure path (failure-report.md) is exempt and still routes loop, and the sprint-1 abort short-circuit at the top of the file is untouched (precedes the edited line). selftest step 07 split into 07a (report, no critique → test) + 07b (report + critique → loop). Verified all three routing edges + negative arm (reverting the routing change makes 07a FAIL). Propagated ×4; bundle-sync green; selftest 17/17.
- **Completed:** 2026-07-04T00:00:00Z
- **Files modified:** `{4 bundles}/scripts/{current-phase.sh,selftest.sh}`
- **Commit:** `2a0b8fb`

## T-003 (sprint 13)
- **Description:** Documented both gates where agents read. claude 03 + codex 03 (per-copy): finalize gate list corrected from stale "two gates" to four (adding the previously-undocumented budget gate + the new critique gate). phases/05 (claude=codex parity): a "Routing gate (sprint 13)" note that the state machine won't leave Test on the pass path until sprint-tests/critique.md exists (failure path exempt). open-harnesses particles 03 + 07: one-sentence integrations of each gate. ROADMAP §6: note that antigravity's manual-header Plan flow bypasses finalize-plan.sh so the critique gate can't bind there (T-106 input). All presence greps pass; bundle-sync + merge-policy green.
- **Completed:** 2026-07-04T00:00:00Z
- **Files modified:** `claude+codex phases/03-plan-phase.md`, `claude+codex phases/05-test-phase.md`, `open-harnesses/particles/{03-plan-phase,07-test-phase}.md`, `ROADMAP.md`
- **Commit:** `274bd46`

## T-001 addendum (sprint 13 test phase)
- **Description:** Test critic (proceed-with-caveats) drove three finalize-plan.sh parser improvements applied during Test phase: (C-001) verdict parsing now reduces to a bare token + EXACT-matches, so `cleanish`/`blocked` near-misses refuse instead of slipping through prefix globs; (C-002) parser accepts BOTH the inline `## Confidence: <verdict>` form (modeled in phase docs) and the heading-then-next-line form; (C-003) selftest steps 16/17 now assert the refusal MESSAGES (names critic protocol / states verdict shape), not just exit code. All 5 committed critiques still parse to accept. Re-propagated ×4; selftest 17/17; run-guards 7/7.
- **Completed:** 2026-07-04T00:00:00Z
- **Files modified:** `{4 bundles}/scripts/{finalize-plan.sh,selftest.sh}`
- **Commit:** `f579a09`

## T-110 (sprint 14)
- **Description:** Defined the Book v2 path/layout contract, stable intent lifecycle metadata, evidence rules, split-brain detection, structural validation, and focused positive/negative fixtures across all four bundles.
- **Completed:** 2026-08-01T04:40:56Z
- **Files modified:** `{4 bundles}/schemas/intent.md`, `{4 bundles}/scripts/{book-paths.sh,check-book.sh,check-book.test.sh}`, Sprint 14 planning artifacts and task ledgers
- **Commit:** `f40d7a7`

## T-111 (sprint 14)
- **Description:** Made fresh initialization and phase routing Book-native, including tracked scaffold creation, stable navigation, legacy/conflict refusal, artifact-derived transitions, and modular full-phase fixtures.
- **Completed:** 2026-08-01T06:23:27Z
- **Files modified:** `{4 bundles}/scripts/{init-sprint.sh,current-sprint.sh,current-phase.sh,selftest.sh,book-routing.test.sh}`, task ledgers
- **Commit:** `29bde47`

## T-112 (sprint 14)
- **Description:** Added a lossless, idempotent legacy-to-Book migration with exact path/type/SHA-256 provenance, one-authority cutover, verified rollback, concurrent-change detection, split-brain and alias refusal, full Book tracking checks, and Windows-safe navigation migration.
- **Completed:** 2026-08-01T14:43:49Z
- **Files modified:** `{4 bundles}/scripts/{init-sprint.sh,migrate-to-book.sh,migrate-to-book.test.sh}`, task ledgers
- **Commit:** `07add19`

## T-113 (sprint 14)
- **Description:** Rewired runtime gates to Book evidence, including transactional plan locking, exact intent/critic/budget validation, Loop-only evidence-aligned closeout, failure-safe metadata commits, CRLF preservation, explicit per-task path authority, and clone-durable commit evidence.
- **Completed:** 2026-08-01T16:19:44Z
- **Files modified:** `{4 bundles}/scripts/{abort-sprint.sh,close-sprint.sh,commit-task.sh,finalize-plan.sh,research-budget.sh,update-confidence.sh,runtime-helpers.test.sh,selftest.sh}`, task ledgers
- **Commit:** `33cb34d`

## T-114 (sprint 14)
- **Description:** Rewrote the harness-neutral protocol around Book v2 intent authority, evidence, provenance, and non-authoritative views; removed active decision schemas; made planning/build/test/loop lifecycle transitions explicit; and hardened plan/test gates with existing-linked-intent and exact accepted-critique validation.
- **Completed:** 2026-08-01T20:07:39Z
- **Files modified:** `{claude-code,codex-cli}/skills/sprint-loop*/{phases,prompts}/**`, `open-harnesses/{particles,prompts}/**`, `{4 bundles}/schemas/**`, `{4 bundles}/scripts/{critic-contract.sh,finalize-plan.sh,current-phase.sh,book-routing.test.sh,runtime-helpers.test.sh}`, task ledgers
- **Commit:** `2ce56ff`

## T-115 (sprint 14)
- **Description:** Refactored the Codex adapter for current `.agents/skills` discovery and GPT-5.6-oriented progressive disclosure: explicit activation, resolved skill/project roots, uniform four-heading phase contracts, single-statement remote and shared-workspace authority, Book-native planning/Loop evidence, and a short optional AGENTS pointer. Hardened POSIX and native PowerShell installation with independent source/target resolution, per-target locks, transaction ownership markers, non-destructive rollback, terminating signal handling, Windows/WSL path boundaries, and executable race/failure/collision fixtures; all nine cross-platform adapter contracts pass.
- **Completed:** 2026-08-02T02:28:04Z
- **Files modified:** `codex-cli/{README.md,install.sh}`, `codex-cli/skills/sprint-loops/{SKILL.md,AGENTS.md.fragment,phases/{03-plan-phase.md,06-loop-phase.md}}`, `codex-cli/tests/{adapter-contract.test.sh,adapter-contract.windows.ps1}`, task ledgers
- **Commit:** `3e8ccb3`

## T-116 (sprint 14)
- **Description:** Aligned Claude and Antigravity on the same Book v2 authority, lifecycle, and evidence contract while retaining only native Plan Mode, recurrence, and review-artifact projections. Made Antigravity self-contained at its official workflow and skill locations with coherent transactional installation, full path-chain alias refusal, compensating rollback, retained recovery evidence, and executable mapping/install fixtures.
- **Completed:** 2026-08-02T03:32:16Z
- **Files modified:** `claude-code/skills/sprint-loop/{SKILL.md,phases/{03-plan-phase.md,06-loop-phase.md}}`, `claude-code/tests/adapter-contract.test.sh`, `antigravity-ide/{global_workflows/sprint-loops.md,install.ps1,skills/sprint-loop/SKILL.md,tests/adapter-contract.windows.ps1}`, task ledgers
- **Commit:** `6d8fb46`

## T-117 (sprint 14)
- **Description:** Consolidated repository and bundle operator documentation around Project Book schema v2: one root authority/adapter map, linked shared contracts, current adapter-specific installation and invocation, and no duplicated legacy protocol. Quarantined the unchanged nine-item ROADMAP as non-authoritative T-119 migration input and added executable link, legacy-authority, and adapter-scope contracts.
- **Completed:** 2026-08-02T03:50:19Z
- **Files modified:** `README.md`, `ROADMAP.md`, `{claude-code,antigravity-ide,open-harnesses}/README.md`, `tools/operator-docs.test.sh`, task ledgers
- **Commit:** `5bf757b`

## T-118 (sprint 14)
- **Description:** Extended Book parity from byte-synchronized shared assets to explicit required inventories, hidden-file and physical-entry checks, and semantic adapter contracts for Book v2 anchors, authority roles, native boundaries, remote safety, and legacy-authority rejection. Updated Claude plugin metadata and retained compatibility shims for the T-120 runner transition.
- **Completed:** 2026-08-02T20:35:25Z
- **Files modified:** `.claude-plugin/{marketplace.json}`, `claude-code/.claude-plugin/plugin.json`, `tools/{check-bundle-sync.sh,check-bundle-sync.test.sh,check-adapter-semantics.sh,check-adapter-semantics.test.sh,check-merge-policy.sh,check-merge-policy.test.sh}`, task ledgers
- **Commit:** `d345724`

## T-119 (sprint 14)
- **Description:** Dogfooded the Book architecture by migrating this repository into its own `docs/` Book with `migrate-to-book.sh`: sprint history (`s0`–`s14`), work ledgers, `confidence.txt`, and legacy `decisions.md` (as non-authoritative `docs/history/decisions-legacy.md`) moved under `docs/` with a transactional, verified cutover. A pre/post SHA-256 inventory proved 146/146 files preserved one-to-one (0 missing, 0 mismatch); the migration wrote `docs/history/migration-provenance.md` and the proof is recorded in `docs/sprints/s14/migration-verification.md` with a reviewed exclusions list of NONE. Authored `docs/intents/INT-0001-project-book.md` (state `active`; work evidence links the sprint 14 build and test plans; all SUMMARY navigation and evidence links resolve). Post-migration layout is `book-only` — no root `sprints/`, `agent-tasks/`, `decisions.md`, or `confidence.txt` remains — and `check-book.sh` validates 1 intent chapter with routing unchanged (sprint 14 / build) before and after cutover. Inspected the three previously-tracked per-sprint `guards-report.ndjson` confirmations (only suite metadata + SHA-256 hashes; no secrets/paths) and kept them tracked. Preserved project-owned `.DS_Store`/`Thumbs.db` ignores outside the scaffold's marker, and back-filled the stale sprint-13 T-001 addendum commit evidence (`f579a09`) so the ledger's only pending entry is this task.
- **Completed:** 2026-08-03T00:00:00Z
- **Files modified:** migrated legacy state into `docs/**` (sprints, work ledgers, history, `INT-0001`, `SUMMARY.md`, `migration-verification.md`); removed root `sprints/`, `agent-tasks/`, `decisions.md`, `confidence.txt`; `.gitignore`
- **Commit:** `e37ee2ab51bb302345569bede0f86bdbd6476802`

## T-120 (sprint 14)
- **Description:** Registered canonical Book verification in `tools/run-guards.sh`: added `adapter-semantics` (`check-adapter-semantics.sh`), `adapter-semantics-test`, and `operator-docs` to the `SUITES` list, the `suite_cmd` dispatcher, and the `suite_script_hash` fingerprinter (registration-completeness verified — every suite name resolves in all three), and expanded the `shellcheck` suite to cover the intentionally divergent Codex scripts plus every bundle's installer and adapter-contract test (all clean at `-S warning`). The canonical suite now executes Book validation + migration/routing selftests (via `selftest`), bundle parity, Codex/adapter semantic checks, operator-doc contracts, shellcheck, and the `--determinism` meta-check from one entry point shared by the local Test phase and CI. Made the migration/bundle-sync symlink-rejection fixtures portable with a `can_symlink` capability guard that skips (rather than fails) where the host cannot create a real symlink — the 3 symlink negatives in `migrate-to-book.test.sh` (propagated byte-identically ×4 bundles) and the bundle-sync `SYMLINK:` negative — keeping them strong on POSIX CI while letting the suite run clean on Windows git-bash; this also removed a spurious determinism mismatch caused by an unnormalized temp path leaking from a symlink test that wrongly proceeded. Full local `run-guards.sh --determinism`: **9/10 suites PASS with `determinism:ok`**. The one remaining local failure is `selftest`'s chained `runtime-helpers` CRLF-preservation assertions, which fail only under Windows git-bash GNU awk 5.4.0 (it strips trailing `\r`, so both `finalize-plan.sh`'s `\r`-detection and the test's `\r`-assertion misfire); green on the authoritative Ubuntu/macOS CI. Filed as backlog `T-121` (not a T-120 regression — pre-existing T-113 code, unmasked once the symlink fixtures stopped aborting `selftest` early).
- **Completed:** 2026-08-04T00:00:00Z
- **Files modified:** `tools/run-guards.sh`, `{4 bundles}/scripts/migrate-to-book.test.sh`, `tools/check-bundle-sync.test.sh`, task ledgers
- **Commit:** `b240e2374c001bdd8ba7596d43ebd03a72cb76a5`

## T-122 (sprint 15)
- **Intent:** [INT-0002](../intents/INT-0002-substrate-and-branch-model.md)
- **Description:** Added the Book-tracked **remote-profile** contract — the schema (`schemas/remote-profile.md`) plus `remote-profile.sh`, which resolves and validates `provider` (github|gitlab|generic|local-only), `base`, `work`, `bump` (optional → `none`), and `mergePolicy` (default `human-approve`) from a fenced key/value block in `docs/work/remote-profile.md` guarded by a `sprint-loop-remote-profile-v1` marker. Missing file, missing marker, missing required field, unknown provider, or unknown mergePolicy each fail with a specific diagnostic; `local-only` validates with no remote requirement. Fixtures (`remote-profile.test.sh`): resolve-all + field-query, reject-malformed (missing file / unknown provider / missing base / missing marker with exact diagnostics), and local-only defaults — 3/3 green. Propagated byte-identically ×4 bundles; shellcheck clean; bundle-sync parity green.
- **Completed:** 2026-08-06T00:00:00Z
- **Files modified:** `{4 bundles}/scripts/{remote-profile.sh,remote-profile.test.sh}`, `{4 bundles}/schemas/remote-profile.md`, `docs/intents/INT-0002-substrate-and-branch-model.md`, task ledgers
- **Commit:** `842594c37d3a2f9f3d6f11f9a3483c513637daa3`

## T-123 (sprint 15)
- **Intent:** [INT-0002](../intents/INT-0002-substrate-and-branch-model.md)
- **Description:** Added `check-substrate.sh` — the deterministic gate that runs in front of phase routing. It composes the Book leg (`book_layout_state` + `check-book`), ledger presence (`tasks.md`/`completed-tasks.md`), the resolved remote profile, and `git show-ref` branch presence for `base`/`work` (and `bump` when enabled), printing exactly one of `substrate-complete` (exit 0), `substrate-absent` (fresh: no Book and no profile), or `substrate-partial:<diagnostic>` naming each missing element. Read-only (no repository mutation; `current-phase.sh` untouched). Fixtures (`check-substrate.test.sh`, 7/7 green): complete, absent, partial-no-branches (names `branch:dev`), partial-no-profile, read-only (working-tree + `current-phase.sh` unchanged), complete-without-bump (bump disabled → not required), and local-only-complete (no remote required). Propagated ×4; shellcheck clean; bundle-sync parity green.
- **Completed:** 2026-08-06T00:00:00Z
- **Files modified:** `{4 bundles}/scripts/{check-substrate.sh,check-substrate.test.sh}`, task ledgers
- **Commit:** `d02577be2942701e88c3903fa68ed0d568330762`

## T-124 (sprint 15)
- **Intent:** [INT-0002](../intents/INT-0002-substrate-and-branch-model.md)
- **Description:** Added `deploy-substrate.sh` — the idempotent, transactional Sprint 0 bootstrap. It brings a project to `substrate-complete` by creating only what is missing: the Book scaffold + first sprint (via `init-sprint.sh`), the remote profile (written from `--provider/--base/--work/--bump/--merge-policy` flags, defaulting to `local-only`/`main`/`dev`/no-bump/`human-approve`), and the `base`/`work`/(`bump`) branches (from an initial commit when the repo is unborn). It short-circuits to a no-op when `check-substrate` already reports complete, refuses `legacy-only`/`conflict` layouts with a diagnostic (migration, not deploy), and verifies `substrate-complete` before committing. Failure or signal before commit triggers a rollback trap that deletes exactly the branches/sprint/profile/Book/`.git` this run created (tracked via `CREATED_*` flags); a `DEPLOY_SUBSTRATE_FAIL_AFTER` test seam injects failures. Fixtures (`deploy-substrate.test.sh`, 4/4 green): fresh→complete (+branch assertions), idempotent re-run (state snapshot unchanged), rollback-on-injected-failure (no `docs/`/`.git` left behind), and refuse-conflict. Propagated ×4; shellcheck clean; bundle-sync parity green.
- **Completed:** 2026-08-06T00:00:00Z
- **Files modified:** `{4 bundles}/scripts/{deploy-substrate.sh,deploy-substrate.test.sh}`, task ledgers
- **Commit:** `b1c5e259cacea28fb9d7303cbc6b22953fdc43f1`

## T-125 (sprint 15)
- **Intent:** [INT-0002](../intents/INT-0002-substrate-and-branch-model.md)
- **Description:** Added `remote-adapter.sh` — the provider-agnostic sprint checkpoint. Driven by the resolved profile, it opens exactly one `work→base` PR/MR via `gh` (GitHub) or `glab` (GitLab), and never merges (merging is the human-approve boundary). `pr-exists` queries the provider for an open `work→base` PR/MR; `open-pr` refuses to open a second when one exists, is a no-op under `local-only`, and falls back to pushing `work` + printing the compare URL when the provider CLI is absent/unauthenticated or `provider: generic`. Fixtures (`remote-adapter.test.sh`, 4/4 green) stub `gh` on `PATH` and back the push with a local bare repo: open-once (exactly one `pr create`, no `pr merge`), refuse-second (existing PR → no create + "already" message), generic fallback (prints "manually" URL, exit 0), and human-approve-never-merges. Propagated ×4; shellcheck clean; bundle-sync parity green.
- **Completed:** 2026-08-06T00:00:00Z
- **Files modified:** `{4 bundles}/scripts/{remote-adapter.sh,remote-adapter.test.sh}`, task ledgers
- **Commit:** `14dd38625ebce3da6563ee319c4dfe4d8925772c`

## T-126 (sprint 15)
- **Intent:** [INT-0002](../intents/INT-0002-substrate-and-branch-model.md)
- **Description:** Added `sync-work-branch.sh` — the boundary resync that brings `base` into `work` (fast-forward or merge) so `work`/`dev` inherits everything on `base`/`main` (notably `bump` dependency fixes) with `base` as the single confluence. It refuses when the tracked working tree is dirty (`git status --porcelain --untracked-files=no`), writes only `work` (asserts `base` is byte-unchanged before/after), and aborts + refuses on a merge conflict rather than leaving a half-merged state. Fixtures (`sync-work-branch.test.sh`, 3/3 green): brings-base-into-work (`main` head becomes an ancestor of `dev`), refuses-dirty (modified tracked file → refusal, `dev` unchanged), writes-only-work (`main` ref unchanged). Propagated ×4; shellcheck clean; bundle-sync parity green.
- **Completed:** 2026-08-06T00:00:00Z
- **Files modified:** `{4 bundles}/scripts/{sync-work-branch.sh,sync-work-branch.test.sh}`, task ledgers
- **Commit:** `3500f214e419ced59f71e22c06825c39a68bbdf5`

## T-127 (sprint 15)
- **Intent:** [INT-0002](../intents/INT-0002-substrate-and-branch-model.md)
- **Description:** Rewired the phase and adapter docs onto the substrate layer. `01-init-sprint.md` (byte-synced claude↔codex) gains a **Substrate gate (first action)** section: run `check-substrate.sh` first → `substrate-complete` proceeds, `substrate-absent` runs Sprint 0 `deploy-substrate.sh`, `substrate-partial:<diag>` resolves the named gap; the skill creates no per-sprint branch. Both (divergent) `06-loop-phase.md` docs gain a **Remote checkpoint** section: open exactly one `work→base` PR/MR via `remote-adapter.sh open-pr` (per `schemas/remote-profile.md`), at most one per sprint, never merged under `human-approve`, no per-sprint branch, with `sync-work-branch.sh` resyncing `work` after a merge. `SKILL.md` (claude + codex) now reference the remote-profile schema, the one-PR/MR-per-sprint checkpoint, and the substrate gate; the antigravity workflow and open-harnesses particle 08 got parallel integrations. The substrate/bootstrap contract now lives in the skill, not an external repo. Bundle-sync parity, adapter-semantics, and operator-docs all green. (Folded the Sprint 0 contract into `01-init` rather than a separate phase file to keep the synced-phase parity map unchanged.)
- **Completed:** 2026-08-06T00:00:00Z
- **Files modified:** `{claude,codex} phases/{01-init-sprint,06-loop-phase}.md`, `{claude,codex} SKILL.md`, `antigravity-ide/global_workflows/sprint-loops.md`, `open-harnesses/particles/08-loop-phase.md`, task ledgers
- **Commit:** `5e4af8865a5c42e448c7bda008f4fc83b5fe0857`

## T-128 (sprint 15)
- **Intent:** [INT-0002](../intents/INT-0002-substrate-and-branch-model.md)
- **Description:** Registered the substrate layer in the canonical guard system. `tools/run-guards.sh` gains 5 suites — `remote-profile`, `check-substrate`, `deploy-substrate`, `remote-adapter`, `sync-work-branch` — in `SUITES`, `suite_cmd`, and `suite_script_hash` (registration-completeness verified: 15/15 suites resolve in all three); the existing `shellcheck` glob already covers the new scripts. `tools/check-bundle-sync.sh` `REQUIRED_SCRIPTS` gains the 10 new shared files so a missing/extra/divergent copy fails parity with the specific asset. `tools/check-adapter-semantics.sh` gains `check_profile_contract` (each adapter must reference `schemas/remote-profile.md` and carry the "no per-sprint branch" commitment), wired for Claude/Codex/Antigravity; `check-adapter-semantics.test.sh` gains two non-vacuous negatives (omit the profile reference → fail; drop the no-per-sprint-branch commitment → fail), each asserting its exact diagnostic. Verified: shellcheck clean; adapter-semantics baseline satisfied; all 5 new suites green via their registered copies; bundle-sync parity green. (No bundle-script changes — propagation happened per-task in T-122–T-126.)
- **Completed:** 2026-08-06T00:00:00Z
- **Files modified:** `tools/{run-guards.sh,check-bundle-sync.sh,check-adapter-semantics.sh,check-adapter-semantics.test.sh}`, task ledgers
- **Commit:** `061a85d447450f2563e6b3b7be313a7598932289`

## T-129 (sprint 15)
- **Intent:** [INT-0002](../intents/INT-0002-substrate-and-branch-model.md)
- **Description:** Dogfooded the substrate layer by retrofitting this repository. Declared `docs/work/remote-profile.md` (provider `github`, base `main`, work `dev`, bump `bump`, `mergePolicy: human-approve`) and created the `dev` and `bump` branches from `main`, pushed to `origin`. `check-substrate.sh .` now reports **`substrate-complete`** and the profile resolves to the declared fields. Pre/post inventory: **before** = branches {`main`,`sprint-14`,`sprint-15`}, no profile; **after** = the same plus `dev`+`bump` branches (local + `origin`) and the new `docs/work/remote-profile.md` — the only additions; the Book, ledgers, and existing history are unchanged, and routing is unaffected (`current-phase` still tracks the in-progress sprint). Wiring Dependabot (`.github/dependabot.yml`) to the `bump` branch and configuring `main` branch protection are the operator's follow-ups.
- **Completed:** 2026-08-06T00:00:00Z
- **Files modified:** `docs/work/remote-profile.md` (new); repository branches `dev`, `bump` (created + pushed to origin)
- **Commit:** `258c1decf46734bff2e1fe9cc28d672f8f3ccdec`

## T-130 (sprint 16)
- **Description:** Replaced the Book-tracked remote-profile contract with strict v2 across all four bundles. The schema now declares only `provider`, `base`, `work`, and optional/defaulted `mergePolicy`; the resolver emits and queries only those fields, rejects the v1 marker with a migration diagnostic, rejects unknown profile keys instead of silently ignoring them, and rejects unsupported field queries. Expanded fixtures cover exact four-field output, legacy-marker rejection, unknown-key rejection, unknown-query rejection, required-field/provider diagnostics, and local-only defaults. Verified the canonical fixture suite, shellcheck, diff hygiene, and byte-identical bundle parity.
- **Intent:** [INT-0003](../intents/INT-0003-dependency-updates-on-work.md)
- **Completed:** 2026-08-08T04:56:08Z
- **Files modified:** `docs/intents/INT-0003-dependency-updates-on-work.md`, `{4 bundles}/schemas/remote-profile.md`, `{4 bundles}/scripts/{remote-profile.sh,remote-profile.test.sh}`, task ledgers
- **Commit:** `d70ae202e5a5b218d2eaf802686b9603f20dd558`

## T-131 (sprint 16)
- **Description:** Simplified the substrate gate and transactional Sprint 0 deploy to the profile's `base`/`work` topology across all four bundles. The gate now requires only those two configured refs. Deploy creates only base/work on a fresh repository, scaffolds Dependabot or current Renovate `baseBranchPatterns` against `work` for hosted providers, creates no updater for local-only, rebinds behavior from the resolved profile, and preserves create-if-absent/no-clobber semantics. Expanded fixtures prove exact fresh branch set, hosted target routing, idempotency, fresh rollback cleanup, byte/ref preservation of seeded pre-existing state under rollback, conflict refusal, GitHub/GitLab/generic/local variants, and no-clobber behavior. Targeted suites, shellcheck, diff hygiene, and bundle parity passed.
- **Intent:** [INT-0003](../intents/INT-0003-dependency-updates-on-work.md)
- **Completed:** 2026-08-08T05:01:39Z
- **Files modified:** `{4 bundles}/scripts/{check-substrate.sh,check-substrate.test.sh,deploy-substrate.sh,deploy-substrate.test.sh}`, task ledgers
- **Commit:** `b647ee31c0e81180502653e6f133e86ea846d313`

## T-132 (sprint 16)
- **Description:** Removed the caller-supplied checkpoint-head override from the provider adapter, leaving the remote profile's `work → base` path as the only corpus checkpoint. Updated adapter fixtures to prove one open, existing-checkpoint refusal, generic fallback, human-approve non-merge, and override rejection before provider invocation. Generalized boundary resync semantics while retaining positive ancestry, dirty refusal, and base-immutability coverage. Rewired Claude, Codex, Open Harnesses, and Antigravity contracts to require hosted-updater intake only between sprints: merge only when current/green and authorized; keep red PRs unmerged and repair until green; if the provider head cannot be repaired, use an ordinary dependency-only sprint and supersede the PR, with no checkpoint/sprint subtype. Targeted adapter/resync suites, static four-adapter contract checks, shellcheck, adapter semantics, bundle parity, and active-distribution scans passed.
- **Intent:** [INT-0003](../intents/INT-0003-dependency-updates-on-work.md)
- **Completed:** 2026-08-08T05:06:41Z
- **Files modified:** `{4 bundles}/scripts/{remote-adapter.sh,remote-adapter.test.sh,sync-work-branch.sh,sync-work-branch.test.sh}`, `{claude,codex}/phases/{01-init-sprint.md,06-loop-phase.md}`, `open-harnesses/particles/08-loop-phase.md`, `antigravity-ide/global_workflows/sprint-loops.md`, task ledgers
- **Commit:** `076365d27f73aa84b5850c601370774e187553f0`

## T-133 (sprint 16)
- **Description:** Migrated this repository onto the v2 two-branch model. The live profile now declares only `main`/`dev`; Dependabot targets `dev` with ordinary `deps` commits; CI runs on pull requests to either corpus branch; and the Actions v7 upgrades formerly isolated on the retired path are preserved. Replaced the operator guide with one boundary-intake rule: accept a current green updater PR between sprints, repair red updates without merging, or use an ordinary dependency-only sprint when the provider head cannot be repaired. Documented GitHub's default-branch security-update exception and the required resync. Verified the source resolver and substrate gate, operator-doc fixtures, exact config anchors, diff parity with `origin/bump` for the preserved Actions payload, diff hygiene, and absence of the retired term on the edited active surfaces.
- **Intent:** [INT-0003](../intents/INT-0003-dependency-updates-on-work.md)
- **Completed:** 2026-08-08T05:09:09Z
- **Files modified:** `docs/work/remote-profile.md`, `.github/dependabot.yml`, `.github/workflows/ci.yml`, `README.md`, task ledgers
- **Commit:** `5c4456caa54d65c25c3345cbde0adaf179002443`

## T-134 (sprint 16)
- **Description:** Added a positive-inventory regression guard over the complete active Claude, Codex, Antigravity, and Open Harness distributions plus the root operator guide, live remote profile, Dependabot configuration, and CI workflow. It rejects the retired branch-model term case-insensitively, including underscore and camel-case identifiers, with repository-relative path/line diagnostics while leaving finalized Book and Git history outside the scan. Expanded the isolated mutation matrix to prove failures independently in adapter, schema, script, installer, phase, operator-guide, live-profile, and updater-config surfaces; prove embedded ordinary words remain safe; and prove historical exclusions are deliberate. The final matrix passed 57/57, independent review found no acceptance gap, bundle parity passed, shellcheck passed, and the canonical two-pass runner recorded 15/15 suites with matching deterministic evidence.
- **Intent:** [INT-0003](../intents/INT-0003-dependency-updates-on-work.md)
- **Completed:** 2026-08-08T06:34:32Z
- **Files modified:** `tools/check-adapter-semantics.sh`, `tools/check-adapter-semantics.test.sh`, task ledgers
- **Commit:** `184e376a4acfba7a5a34ab110815f615864d0e32`

## T-135 (sprint 16)
- **Description:** Reinstalled the revised Codex bundle to the native Windows user scope with the exact transactional installer published in `codex-cli/README.md`. Verified the source and installed trees have the same 49 relative files and SHA-256 hashes, and that no install lock, staging directory, backup directory, or ownership marker remains. Executed the installed router against this Book (`build` before task-ledger completion) and the installed v2 resolver against the live profile; it emitted exactly `PROVIDER=github`, `BASE=main`, `WORK=dev`, and `MERGEPOLICY=human-approve` with no retired branch output.
- **Intent:** [INT-0003](../intents/INT-0003-dependency-updates-on-work.md)
- **Completed:** 2026-08-08T06:36:58Z
- **Files modified:** `C:/Users/charl/.agents/skills/sprint-loops` (transactional user-scope replacement), task ledgers
- **Commit:** `0af4c726cd54c3a33ca8d3a56a94699e1339d1e5`

## T-137 (sprint 17)
- **Description:** Added the substrate contract version to the shared Book path contract in all four bundles: `BOOK_SUBSTRATE_CONTRACT_VERSION=2` (the version this bundle implements), a `BOOK_SUBSTRATE_VERSION_DIAGNOSTIC` constant, and `book_substrate_version()`, which prints `1` for a marker carrying no `substrate-version` entry, prints the stamped value when exactly one well-formed positive-integer entry is present, and refuses a malformed, zero, non-numeric, or repeated entry with a diagnostic naming the marker path. `book_marker_is_v2()` is unchanged and verified to still accept a stamped marker, which is the technical basis for the sprint's backwards-compatibility claim. Fixtures added to `runtime-helpers.test.sh` in all four bundles; verified 3/3 in a focused harness because the suite aborts earlier on backlog defect T-121, a Windows-only CRLF detection failure present identically at HEAD.
- **Intent:** [INT-0004](../intents/INT-0004-substrate-contract-versioning.md)
- **Completed:** 2026-09-02T16:31:00Z
- **Files modified:** `{4 bundles}/scripts/book-paths.sh`, `{4 bundles}/scripts/runtime-helpers.test.sh`, task ledgers
- **Commit:** `a3e10e3324a36f7408e952277dd59c7442525aa4`

## T-138 (sprint 17)
- **Description:** Taught `check-substrate.sh` two contract-version states in all four bundles: `substrate-outdated:<book>-><bundle>` when the substrate is structurally complete but behind this bundle, and `substrate-ahead:<book>-><bundle>` when it is stamped past this bundle, which is refused rather than converged backwards. Both exit non-zero; exit 0 remains reserved for `substrate-complete`. A malformed stamp joins the `missing` list as `book-substrate-version`, preserving the precedence rule that a broken substrate outranks a stale one. The three existing complete-path fixtures were converged with a `stamp` helper driven by the bundle constant rather than a hardcoded number, and six fixtures were added covering outdated, complete-after-stamp, ahead, malformed, partial-outranks-version, and read-onlyness of the new states: 12/12 pass. The backwards-compatibility claim is now asserted directly in `book-routing.test.sh` by `test_routing_unchanged_for_unstamped_book`, which proves an unstamped Book routes normally and that routing never writes the stamp.
- **Intent:** [INT-0004](../intents/INT-0004-substrate-contract-versioning.md)
- **Completed:** 2026-09-02T16:44:00Z
- **Files modified:** `{4 bundles}/scripts/check-substrate.sh`, `{4 bundles}/scripts/check-substrate.test.sh`, `{4 bundles}/scripts/book-routing.test.sh`, task ledgers
- **Commit:** `f57d631e9121b83830606d031d73d28bc7a364ac`

## T-139 (sprint 17)
- **Description:** Turned `deploy-substrate.sh` into the single convergence entrypoint in all four bundles. Added a contract-version stamp step that writes only when the value would change, an `--check` read-only drift report that names each pending step and exits non-zero while pending, and an ahead-Book refusal that precedes every write and the report alike. Step ordering is load-bearing twice: the stamp runs before the final verification, because once T-138 landed a complete-but-unstamped Book reports `substrate-outdated` and a stamp placed after the verify would fail convergence on exactly the projects it exists to upgrade; and it runs before the git step so a fresh deploy commits the stamped marker instead of leaving the tree dirty. Rollback captures the prior marker and restores it, extending the existing `DEPLOY_SUBSTRATE_FAIL_AFTER` seam with a `stamp` point. Six fixtures added; the pre-existing `test_deploy_idempotent` file-and-ref snapshot passes unmodified, which is the no-op proof. 14/14 pass, shellcheck clean, four-bundle parity intact.
- **Intent:** [INT-0004](../intents/INT-0004-substrate-contract-versioning.md)
- **Completed:** 2026-09-02T17:02:00Z
- **Files modified:** `{4 bundles}/scripts/deploy-substrate.sh`, `{4 bundles}/scripts/deploy-substrate.test.sh`, task ledgers
- **Commit:** `ee5a252c490a97ce4839bc79c598baed2d2dba0c`

## T-140 (sprint 17)
- **Description:** Gave the bundle a readable identity. `scripts/bundle-version.sh` (0.17.0) ships in all four bundles and prints exactly one version line; it lives in `scripts/` rather than the plugin manifest because the manual installer copies `skills/sprint-loop/` with no `.claude-plugin/` beside it, and because `scripts/` is already covered by the parity guard and shellcheck with no new guard case. `claude-code/.claude-plugin/plugin.json` gained a matching `version`, and `check-plugin-manifest.sh` now requires the field to exist and to equal the bundle's own output, naming both values when they disagree — closing the deferred roadmap item on plugin version discipline. The guard gained a `PLUGIN_MANIFEST_ROOT` override matching the existing `BUNDLE_SYNC_ROOT`/`ADAPTER_SEMANTICS_ROOT` seams, and a new `tools/check-plugin-manifest.test.sh` proves each assertion independently on isolated fixtures: 6/6 pass, including a passing baseline. Registered as the `plugin-manifest-test` suite in the canonical runner and added to `REQUIRED_SCRIPTS`. Parity 4/4, bundle-sync fixtures 18/18, shellcheck clean.
- **Intent:** [INT-0004](../intents/INT-0004-substrate-contract-versioning.md)
- **Completed:** 2026-09-02T17:20:00Z
- **Files modified:** `{4 bundles}/scripts/bundle-version.sh`, `tools/check-plugin-manifest.sh`, `tools/check-plugin-manifest.test.sh`, `tools/check-bundle-sync.sh`, `tools/run-guards.sh`, `claude-code/.claude-plugin/plugin.json`, task ledgers
- **Commit:** `612439de0a1fc1345695df0ea78b73cea1269e5d`

## T-141 (sprint 17)
- **Description:** New sprint records now name the bundle that ran them. `init-sprint.sh` reads the co-located `bundle-version.sh` and writes `- **Bundle version:**` after `Model`, degrading to `unknown` rather than failing if the helper is unavailable; the `sprint-meta.md` schema documents the field and states explicitly that records predating it remain valid. `test_init_records_bundle_version` in `book-routing.test.sh` asserts exactly one such field matching the helper's output, in a fixture that has no plugin manifest at all — the manual-install mode from research F7. The existing `runtime-helpers.test.sh` close fixture now also strips `Bundle version`, making it a genuine pre-sprint-17 record, and asserts close neither requires nor invents the field. Verified in a focused harness (init records it; a legacy record closes successfully without it) because the full suite aborts earlier on backlog defect T-121. Also normalized a literal newline that a tooling quirk had introduced into a `printf` in `book-routing.test.sh` during T-138.
- **Intent:** [INT-0004](../intents/INT-0004-substrate-contract-versioning.md)
- **Completed:** 2026-09-02T17:34:00Z
- **Files modified:** `{4 bundles}/scripts/init-sprint.sh`, `{4 bundles}/schemas/sprint-meta.md`, `{4 bundles}/scripts/book-routing.test.sh`, `{4 bundles}/scripts/runtime-helpers.test.sh`, task ledgers
- **Commit:** `8885841e1b70f0184ca3390cbbe87aaa738ba48a`

## T-142 (sprint 17)
- **Description:** Made convergence reachable from the operator surfaces. The Claude Code argument list is closed, so `upgrade` is defined explicitly in `SKILL.md` and advertised in `argument-hint`; it runs the substrate check, then convergence, and reports the resulting state without starting a sprint. Both byte-parity copies of `phases/01-init-sprint.md` gained the `substrate-outdated` and `substrate-ahead` outcomes and now describe deploy as the one idempotent command for spin-up and upgrade alike. The Antigravity workflow's bootstrap sentence was extended the same way. `open-harnesses/particles/01-init-sprint.md` never named the substrate gate at all — a gap predating this sprint — so it received the whole gate rather than a half-statement of it. The root README gained a "Convergence: spin-up and upgrade are one command" section with the three starting states, the marker format, the `--check` preview, and the plugin-reload step. Two named contracts were added to `operator-docs.test.sh` (4/4 pass). `check-adapter-semantics.sh` initially failed this task, correctly: four comments and two diagnostics used the word "bump" — the retired branch-model term the sprint-16 guard rejects across active surfaces. The wording was changed rather than the guard; it now reports all adapter contracts satisfied.
- **Intent:** [INT-0004](../intents/INT-0004-substrate-contract-versioning.md)
- **Completed:** 2026-09-02T17:58:00Z
- **Files modified:** `claude-code/skills/sprint-loop/SKILL.md`, `claude-code/skills/sprint-loop/phases/01-init-sprint.md`, `codex-cli/skills/sprint-loops/phases/01-init-sprint.md`, `antigravity-ide/global_workflows/sprint-loops.md`, `open-harnesses/particles/01-init-sprint.md`, `README.md`, `tools/operator-docs.test.sh`, `tools/check-plugin-manifest.sh`, `{4 bundles}/scripts/check-substrate.test.sh`, task ledgers
- **Commit:** `5f85a5ba3800b69c1d9ef8594c729847d552f138`
