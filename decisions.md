# Architectural Decisions

## 2026-05-19 — `current-phase.sh` build/test disambiguator uses `completed-tasks.md` (sprint 0)
- **Context:** The original phase-detection script could not distinguish
  "Build Phase not yet started" from "Build Phase done; Test pending" — both
  states have an empty `agent-tasks.md` (for the current sprint) and an empty
  `test-report.md`. The script treated both as `test`, causing the agent to
  skip the Build Phase entirely on first invocation after Plan finalization.
- **Decision:** Add a single check after the existing "build in progress" line:
  if no `sprint $N` token exists in `agent-tasks/completed-tasks.md` either,
  the Build Phase has not started — report `build`. Otherwise fall through to
  the existing Test check.
- **Alternatives considered:** Replacing derived state with a declared
  `phase.txt` file written by each phase at transition time. Rejected because
  it violates the protocol's foundational principle that the filesystem IS
  the state machine — it would create a new failure mode (declared phase
  disagrees with on-disk artifacts) without removing any existing one.
- **Consequences:**
  - All future sprints' routing is correct end-to-end without manual override.
  - The protocol now formally relies on `completed-tasks.md` being the
    authoritative record that a sprint's Build Phase has run; helpers that
    consume completed tasks (none today, but conceivable) must preserve the
    `sprint $N` token in their entries.
  - An empty build plan (zero elementary tasks) would now loop on `build`
    forever — flagged as a follow-up; a sprint with zero build tasks should
    be invalid by the planner anyway.
  - The skill ships with a `scripts/selftest.sh` that guards every transition;
    any future change to `current-phase.sh` must be made alongside a selftest
    update if it adds a new phase or transition.

## 2026-05-20 — `commit-task.sh` back-fills commit hashes; opt-in via `PENDING` token (sprint 1)
- **Context:** The protocol's `completed-tasks.md` schema includes a `Commit:`
  field for each entry, but the helper that creates the commit did not fill
  it. Sprint 0 left three manual back-fill edits in its git log as a result.
- **Decision:** If `agent-tasks/completed-tasks.md` contains a literal
  `Commit:** PENDING` placeholder when `commit-task.sh` runs, the script
  captures the new commit's short hash, replaces the FIRST `PENDING`
  occurrence with the hash, and folds the edit into the same commit via
  `git commit --amend --no-edit`. No-op when no `PENDING` token exists.
- **Alternatives considered:** A separate post-commit "back-fill commit"
  (rejected — violates the one-commit-per-task contract). A pre-commit hook
  (rejected — adds a new install step and entangles with whatever the user's
  own hooks do). A declarative "task ledger" outside `completed-tasks.md`
  (rejected — duplicates state, drifts from filesystem-as-state-machine).
- **Consequences:**
  - Agents writing entries with `Commit:** PENDING` get automatic hash fill.
  - Existing entries (and any future entries the agent fills by hand) are
    untouched — back-compat is guaranteed by the `grep -q PENDING` guard.
  - The contract is now "one commit per task, even with amend"; if a future
    helper also needs to amend a task's commit, it must compose with this one.

## 2026-05-20 — Abort path: `abort-sprint.sh` + hoisted Exit-status check in `current-phase.sh` (sprint 1)
- **Context:** The `/loop-sprint` command advertised an `abort` subcommand,
  but no script implemented it and the Loop Phase doc only listed `success`
  and `failed` as exit statuses. There was no clean way to stop a sprint
  mid-flight without faking a failure-report.
- **Decision:** Add `scripts/abort-sprint.sh "<reason>"` that sets `sprint-meta.md`
  Exit status to `aborted`, records the end timestamp, appends an `## Abort
  note` section with the reason, and commits `sprint-N: aborted — <reason>`.
  Hoist the Exit-status check in `current-phase.sh` to the top so a closed
  sprint (any of `success`/`failed`/`aborted`) short-circuits to
  `ready-for-next-sprint` regardless of intermediate filesystem state.
- **Alternatives considered:** Reusing the failure path for aborts (rejected
  — semantic conflation: a failed sprint feeds the next sprint's research, an
  aborted sprint does not). Leaving abort undocumented (rejected — the
  command file already advertised it).
- **Consequences:**
  - The skill's three exit statuses (`success`, `failed`, `aborted`) now each
    have a defined invocation path and a defined effect on the next sprint.
  - `current-phase.sh` semantics are clearer: a sprint is "closed" iff Exit
    status is one of the three end states; otherwise derive from artifacts.
  - The new `aborted` transition is covered by `selftest.sh` step 09.
  - `abort-sprint.sh` calls `git commit` — projects without a git root will
    see a non-zero exit. Acceptable: the Build Phase protocol already
    requires a git root for per-task commits.

## 2026-05-20 — `finalize-plan.sh` rejects empty build-plans + `install.sh` per bundle (sprint 2)
- **Context:** Two flagged follow-ups: (a) an empty build-plan would route to
  `build` and loop forever because no task ever gets queued; (b) the user
  reported seeing duplicate `/sprint-loop` entries after the rename, surfacing
  a need for idempotent install (current path is manual `cp -r` + `chmod +x`).
- **Decision:**
  (a) `finalize-plan.sh` requires at least one `^### T-[0-9]+:` execution
      entry in `build-plan.md` before locking; refuses with a clear message
      otherwise.
  (b) Each bundle ships an `install.sh` that wipes the prior install at the
      target path before copying fresh — `claude-code/install.sh`,
      `codex-cli/install.sh`, `open-harnesses/install.sh`. Per-bundle (not a
      single repo-root installer) to preserve the "each subdirectory is a
      complete atomic unit" principle from sprint 0.
- **Alternatives considered:** Empty-plan detection in `current-phase.sh`
  (rejected — `current-phase.sh` should be derive-only, not modify the build
  flow). Single repo-root `install.sh` with `--target` (rejected — couples
  bundles to a parent script).
- **Consequences:**
  - The empty-build-plan failure mode is closed; selftest step 10 guards it.
  - Future installs/re-installs are one command, idempotent. The manual `cp`
    instructions in the READMEs remain valid as the explicit fallback.
  - Discovered (not fixed in this sprint): two flaws in sprint 1's back-fill
    — regex too lax + pre-amend hash captured. Sprint 3 will fix; manually
    correcting hashes in the meantime.

## 2026-05-20 — Line-anchored back-fill regex + accept off-by-one amend hash (sprint 3)
- **Context:** Sprint 1's `commit-task.sh` back-fill regex matched
  `Commit:** PENDING` as a substring inside other entries' description text,
  corrupting them on every subsequent commit. The same bug class also
  affected `current-phase.sh`'s `grep "sprint $N"` (matched prose like
  "flagged for sprint 3" inside completed-tasks descriptions).
- **Decision:**
  (a) Anchor the back-fill regex to a full line: `^- \*\*Commit:\*\* PENDING$`
      for both detection and substitution.
  (b) Anchor the current-phase greps to the schema's literal task-reference
      format: `\(sprint $N\)` (parens included), matching what
      `agent-tasks.md` and `completed-tasks.md` actually write.
  (c) Accept the off-by-one-amend hash as an intentional trade-off. The
      embedded hash is the pre-amend HEAD; the post-amend HEAD differs.
      Trying to make them match either requires two amends (still off by
      one — the second amend changes the hash) or a second commit (violates
      one-commit-per-task). Document that agents can find the actual commit
      via `git log --grep "sprint-N: T-XXX"`.
- **Alternatives considered:**
  - Two-amend back-fill aiming for hash equality. Rejected: still off by
    one because the second amend itself changes the hash.
  - A separate post-commit "back-fill commit" to embed the post-amend hash.
    Rejected: violates the one-commit-per-task contract.
  - A different placeholder token (e.g. `__COMMIT_HASH__`). Rejected as
    insufficient on its own — line anchoring is the right fix.
- **Consequences:**
  - Description text containing the literal substring `Commit:** PENDING`
    is now safe to write (documenting the bug, citing the placeholder, etc.).
  - `current-phase.sh` correctly distinguishes sprint references from prose
    that happens to mention a sprint number.
  - Selftest step 11 guards the back-fill regression. Any future change to
    the back-fill must keep step 11 green.

## 2026-05-20 — Bake autonomy + workflow patterns into the skill (sprint 3)
- **Context:** User shared a set of autonomy/workflow patterns from another
  long-running session that worked well in practice: commit/push/merge
  without per-step confirmation, pre-flight rebase, project-sanity-gate
  before commit, defer-over-block, CI verify via separate `gh run list`
  after `gh run watch`, PR-body-via-heredoc, safety floor on
  permission/security controls. These are operational defaults, not new
  protocol mechanics.
- **Decision:** Bake them into `SKILL.md` body (two new sections:
  "Autonomous operation" + "Safety floor"), the skill's phase files
  (04-build: Pre-flight + defer-over-block; 05-test: CI verify; 06-loop:
  optional PR-merge step with heredoc body), and the open-harnesses
  particles (single-sentence integrations to preserve embedding density).
  Apply to both skill bundles' SKILL.md (Claude + Codex) so they share the
  same operational stance even though they have different routing details.
- **Alternatives considered:**
  - Add a `preflight.sh` helper script. Rejected — every project's gate is
    different; the protocol documents the expectation but doesn't ship a
    one-size-fits-all script.
  - Mandate the autonomy mode by default. Rejected — autonomy is the right
    default *only* when the user opts in (via `/loop`, `codex exec`, or an
    explicit "step away" signal). Default mode stays interactive.
- **Consequences:**
  - Future `/sprint-loop` runs invoked in autonomous mode pick up the same
    defaults that worked in the user's other session.
  - The safety floor is explicit: autonomy never includes weakening
    permissions, skipping pre-flight, bypassing hooks, or unattended
    hard-to-reverse actions.
  - The skill is opinionated about CI semantics for GitHub Actions
    specifically (the `gh run watch` exit-code unreliability). Other CI
    providers need analogous patterns; documented as "GitHub Actions
    specifically" so users with other CI know to translate.

## 2026-05-20 — Hard plan-mode primitive + EARS criteria + decisions-reviewed gate (sprint 4)
- **Context:** Three of sprint 3's flagged candidates, user-prioritized: (a) Plan Mode was a soft instruction ("engage plan mode now") relying on model compliance; (b) success criteria were freeform prose, risking drift from what tests check; (c) `decisions.md` existed but no phase mandated reading it, so a future sprint could violate prior ADRs unnoticed.
- **Decision:**
  (a) `phases/03-plan-phase.md` (claude-code) now mandates `EnterPlanMode` at phase entry and `ExitPlanMode` at phase exit. Codex retains `/plan`; open-harnesses keeps generic language (no harness primitive).
  (b) `schemas/build-plan.md` example shows EARS clauses (`WHEN <trigger> THEN <component> SHALL <response>`). `phases/03-plan-phase.md` mandates at-least-one EARS clause per task's success criterion. `phases/05-test-phase.md` derives one `test_*` per WHEN/THEN/SHALL triple. Particles 04 + 05 carry parallel additions.
  (c) `phases/02-research-phase.md` (and particle 02) now require reading `decisions.md` first and recording relevant ADRs in `## Decisions Reviewed`. `schemas/research-report.md` documents the section. `finalize-plan.sh` REFUSES to lock plans when `decisions.md` is non-empty AND the research-report lacks the section (skips on empty/absent `decisions.md` for sprint 0 / new projects). Selftest step 12 guards the gate.
- **Alternatives considered:** Mandating EARS as the only format (rejected — freeform fallback preserves back-compat). New script for the decisions-review check (rejected — `finalize-plan.sh` is already the gate). Hard plan-mode for Codex too (rejected — `/plan` is already wired as a user-driven primitive).
- **Consequences:**
  - Plan Mode is now an actual tool call (claude-code), not just an instruction.
  - Success criteria are mechanically test-scaffoldable; criteria-test drift is reduced.
  - Cross-sprint architectural drift is now an enforceable gate, not a hope. The first ADR-aware sprint is sprint 4 itself; its research-report's `## 0. Decisions Reviewed` section is the first dogfood instance.
  - Sprint 5+ research-reports must include the section (or `finalize-plan.sh` rejects).

## 2026-05-20 — Subagent fan-out: adversarial critic review at Plan + Test phases (sprint 5)
- **Context:** User priority #1 from sprint 3's flagged candidates. Today, the only "adversary" preventing a bad sprint is `finalize-plan.sh`'s structural checks (no empty plan, decisions-reviewed). That catches malformed plans, not BAD plans. Pedro Santanna's setup and OpenAI's adversarial-critic patterns spawn specialized critics for substantive review.
- **Decision:** Plan Phase (after `ExitPlanMode` returns + plans written, before `finalize-plan.sh`) and Test Phase (after tests run + CI green, before `test-report.md` finalize) each spawn a critic subagent with a templated prompt — `prompts/plan-critic.md` and `prompts/test-critic.md`. The critic returns a structured `## Concerns` list with a `## Confidence` verdict (clean / proceed-with-caveats / block). The primary agent saves the critique to `critique.md` alongside the artifact under review, addresses each concern inline (fix / defer-with-rationale / reject), and proceeds to lock-down only after the critique is recorded with responses. Harnesses without subagent primitives self-critique against the prompt's failure-mode list in a single message.
- **Alternatives considered:**
  - Synchronous in-line critic (no subagent). Rejected — conflates author and reviewer.
  - Critic with write access. Rejected — adversary becomes author; primary loses ownership of plan structure.
  - Hard gate via `finalize-plan.sh` requiring `critique.md`. Deferred to sprint 6+ once the pattern has been exercised manually.
- **Consequences:**
  - Every Plan and Test phase now produces a `critique.md` artifact (alongside the plans/tests), recording what the critic flagged and how the primary agent responded.
  - The protocol now has 2 review surfaces (structural via `finalize-plan.sh`, substantive via critic) rather than 1.
  - The first sprint to actually USE the protocol is sprint 6+; sprint 5 itself only added the protocol, didn't run under it.
  - Selftest cannot exercise the critic step (LLM execution required); the next manual sprint is the in-vivo test.

## 2026-05-21 — Enforced research budget via research-budget.sh + finalize-plan gate (sprint 6)
- **Context:** User priority #4 (last of the 3→2→5→1→4 list). The 20-file / 5-source research caps were honor-system; agents could blow past them silently.
- **Decision:** Added `scripts/research-budget.sh` (counts Existing-Code-Survey data rows + External-Sources URLs; exits non-zero over 20/5). `finalize-plan.sh` runs it as a THIRD pre-lock gate (after empty-plan + decisions-reviewed): over budget refuses to lock UNLESS the research-report has a `## Budget Override` heading with a non-whitespace body line. 30-min wall-clock cap stays honor-system (unmeasurable from a script across sessions).
- **Alternatives considered:** wall-clock enforcement (rejected — sprints span sessions); soft warn-only (rejected — reproduces the honor-system problem); per-sprint configurable budgets (rejected — config surface for marginal benefit).
- **Consequences:**
  - Research breadth is now bounded by default with an explicit, justified escape hatch.
  - `finalize-plan.sh` now has THREE composable gates; all three must pass to lock plans.
  - selftest step 13 guards the budget gate (refuse-over-budget + accept-with-override).
  - This sprint was the first to run sprint 5's critic protocol: the plan critic caught the counter-overcounting bug pre-build; the test critic BLOCKED on two real EARS-coverage gaps (sources branch + empty-override-body), both fixed before the test-report was finalized. The critic protocol earned its keep on its first live run.

## 2026-05-21 — All five sprint-3 critique priorities delivered (sprint 6 milestone note)
- The user's prioritized list from sprint 3 (3: hard plan-mode, 2: EARS criteria, 5: decisions-drift gate, 1: subagent fan-out, 4: research budget) is complete as of sprint 6. Sprints 4–6 delivered them in the instructed order. Remaining backlog is older carry-forward (CI workflow, critique.md hard-gate, abort no-git fallback) — none from the user's prioritized list.

## 2026-05-21 — Claude auto mode = plan-mode auto-accept + /loop; merge stays human-gated (sprint 7)
- **Context:** User wanted unattended multi-sprint operation. I initially designed a ScheduleWakeup self-rearm + roadmap.md goal-queue + max-sprints machinery; the plan critic blocked it (inert stop conditions, no cross-cold-rearm persistence). The user then clarified the actual Claude Code mechanism: **"auto mode" is the auto-accept option selected at the `ExitPlanMode` approval prompt.**
- **Decision:** Auto mode is two harness primitives, not custom machinery: (1) select auto-accept at `ExitPlanMode` (no per-step prompts through Build/Test/Loop); (2) launch under `/loop /sprint-loop continue` for recurrence (user-launched/stoppable; bound it). The skill ensures `EnterPlanMode` is the mandatory first action so the auto-accept prompt reliably appears. Claude-specific; Codex uses `codex exec`.
- **Safety:** auto-accept ≠ auto-merge. Unattended runs do NOT merge to a base branch, force-push, or delete branches — push the branch + open the PR + stop at "ready for review." The Loop Phase PR-merge step (all 3 bundle copies) is gated interactive-or-opt-in. This resolved a live contradiction the plan critic caught (SKILL.md safety floor vs an unconditional `gh pr merge` in 06-loop-phase.md).
- **Alternatives considered:** ScheduleWakeup self-rearm with stop-condition machinery (rejected — reinvents `/loop`; the user's stop control + bounding is simpler and the critic showed the machinery's guards were inert/unpersisted). Per-interval `/loop 30m` (documented as an option; self-paced/bounded is the recommended default).
- **Consequences:** runaway control is the user's (bounded launch + interrupt), documented where they launch. The critic protocol demonstrably earned its keep — two design-stage blocks prevented a broken/unsafe ship.

## 2026-05-21 — Auto-mode stop criterion = "halt only for what AI can't verify"; merge AI-verifiable work (sprint 8)
- **Context:** The user corrected the autonomy philosophy: sprint-loop should run mostly unattended and stop ONLY for things AI cannot verify, not at an arbitrary sprint count. This REVISES the sprint-7 ADR (which gated all unattended merges and recommended bounding), with the decision owner's (user's) explicit authorization.
- **Decision:** The loop runs to completion unattended and halts only at four human-verification checkpoints: (a) visual/UX inspection, (b) an irreversible action whose safety tests/CI can't verify OR whose consequence/blast-radius the agent can't determine (uncertainty itself = checkpoint, default to stop), (c) genuine product/scope ambiguity, (d) unrecoverable failure. AI-verifiable work proceeds — including merging a green-CI PR whose effect is known-and-reversible. Bounding (`/loop N`) is an OPTIONAL cap, not the recommended posture; runaway control = per-task commit rollback + the checkpoints + user interrupt.
- **Alternatives considered:** keep sprint-7's blanket no-unattended-merge (rejected — a green-CI merge is AI-verifiable; stopping for it contradicts the intent). Keep bounding as primary (rejected — against the stated intent). Remove the safety floor (rejected — the irreversible/unknown-consequence items ARE "human must approve what AI can't verify," so they survive as category (b)).
- **Consequences:**
  - Merge-on-green is autonomous; unknown/unverifiable consequence (deploy/release/opaque blast radius) and visual artifacts are checkpoints.
  - A committed, fuzz-tested `tools/check-merge-policy.sh` (+ `*.test.sh`) guards the SKILL.md↔loop-phase consistency that the sprint-7 C-004 contradiction exposed — robust against reword/whitespace/empty dodges (the first attempt at this guard was shown by the test critic to false-pass; the second actually enforces).
  - CI to run the guard + selftests is now the top backlog item — the guard only protects if something runs it.

## 2026-05-22 — sprint-loop ships as a Claude Code plugin (repo-as-marketplace) (sprint 9)
- **Context:** The user saw FOUR identical `/sprint-loop` picker entries, persistent across fresh Claude Code instances, while every other (plugin-delivered) skill showed once. An exhaustive filesystem sweep found exactly ONE bare personal install (`~/.claude/skills/sprint-loop` + `~/.claude/commands/sprint-loop.md`) plus the repo's own source bundles — nothing to "delete." Root cause: a bare personal install is scanned by both the user root (`~/.claude`) and the project root (`<cwd>/.claude`); when Claude Code is launched from the home dir those roots are the SAME directory, so the skill and its command are each enumerated twice → 4. Plugin-delivered skills live in the plugin tree (loaded once), which is why only sprint-loop duplicated.
- **Decision:** Deliver the claude-code bundle as a Claude Code plugin. Repo root gains `.claude-plugin/marketplace.json` (one plugin `sprint-loop`, local `source: "./claude-code"`); `claude-code/.claude-plugin/plugin.json` describes it. No files moved — the existing `skills/sprint-loop/` + `commands/sprint-loop.md` become the plugin's auto-discovered content. Recommended install becomes `/plugin marketplace add crussella0129/sprint-loops` + `/plugin install sprint-loop@sprint-loops`; the manual `cp`-into-`~/.claude` path stays as an explicit fallback. `tools/check-plugin-manifest.sh` validates the manifests (valid JSON, required fields, source resolves to the skill).
- **Alternatives considered:** "just don't run from home" (rejected — environmental advice, not structural; the user explicitly wanted the structural fix); drop the command on the bare install to halve 4→2 (rejected — doesn't change the delivery difference vs the other skills); ship skill-only in the plugin for exactly one entry (deferred — see consequences; trades away the `/sprint-loop continue` command surface the user drives under `/loop`).
- **Consequences:**
  - Plugin delivery loads the skill ONCE regardless of launch directory — the root-collision doubling cannot occur (the skill no longer lives in `~/.claude/skills`/`commands`). This is robust even if the exact doubling mechanism differs.
  - Guaranteed result is 4 → at most 2 (the skill + its `/sprint-loop` command). Reaching exactly ONE entry = an optional skill-only variant (drop the command), surfaced to the user rather than decided unilaterally, because it removes a command surface they actively use AND its effect is only observable at launch.
  - The picker count is a launch-time UI surface, not bash-verifiable; it is the documented human-verification (E2E) checkpoint. Manifest correctness IS fully bash-tested.
  - Bundle atomicity (sprint-0/2 ADR) preserved — additive manifests only, no moves; `install.sh` and `selftest.sh` (still 14/14) untouched.
  - The codex-cli and open-harnesses bundles are unchanged; this plugin packaging is Claude-Code-specific.

## 2026-05-22 — sprint-loop skill IS the /sprint-loop command; legacy command dropped (sprint 10)
- **Context:** Sprint 9 (plugin packaging) took the picker from 4→2 but deferred 2→1 to the user, because the bundle shipped BOTH a `skills/sprint-loop/SKILL.md` and a same-named `commands/sprint-loop.md`. Investigation (authorized by the user) against the official `example-plugin` reference established: (1) `commands/*.md` is a legacy format "loaded identically to `skills/<name>/SKILL.md`" — so a command + same-named skill is a DUPLICATE definition of `/sprint-loop` (the second picker entry); (2) a user-invoked skill carrying `argument-hint:` IS the slash command, with args via `$ARGUMENTS`; (3) a skill can hold both `description` (model-invoked) and `argument-hint` (user-invoked). The user then explicitly authorized the skill-only build.
- **Decision:** The skill becomes the single source of `/sprint-loop`. Added `argument-hint:` + an Invocation section folding the command's verb routing (no-arg/continue, `start <goal>`, `loop`, `abort`) into `SKILL.md`; DELETED `claude-code/commands/sprint-loop.md` (+ its dir); updated `install.sh` (skill-only) and both READMEs; added a `check-plugin-manifest.sh` regression guard that fails if a `commands/sprint-loop.md`, an empty `commands/` dir, or a missing `argument-hint:` reappears. `allowed-tools` is deliberately NOT set (the loop needs full tool access).
- **Alternatives considered:** keep both surfaces (rejected — that IS the duplicate); command-only (rejected — the skill carries the phases/scripts/auto-trigger; the command was the thin legacy file); decide unilaterally (rejected — sprint-9 ADR reserved this for the user; honored via explicit go-ahead).
- **Consequences:**
  - The skill-only plugin yields exactly ONE `/sprint-loop` picker entry, behaving like the other (plugin) skills. Codex-cli + open-harnesses untouched (Claude-Code-specific).
  - **Unverifiable caveat (C-2):** no positive evidence that `argument-hint` preserves the skill's model-invocation/auto-trigger; this is a launch-time E2E check. If auto-trigger regressed, the fix is a one-line revert of the `argument-hint` frontmatter line — explicit `/sprint-loop` invocation is unaffected regardless.
  - Bare-install fallback is now skill-only; from the home dir a bare install still shows 2 (the single skill double-scanned by user==project root) — only the PLUGIN reaches 1. Plugin install is the recommended path.
