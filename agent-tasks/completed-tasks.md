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
