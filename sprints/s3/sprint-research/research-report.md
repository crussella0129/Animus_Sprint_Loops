# Sprint 3 Research Report

## 1. Sprint Goal

Two strands, both flagged by sprint 2:

(a) **Fix the two real bugs in sprint 1's commit-task.sh back-fill** that
manifested every commit of sprint 2: (i) the `Commit:** PENDING` regex isn't
line-anchored so it matched a literal substring inside another entry's
description text, and (ii) the embedded short hash is captured BEFORE the
`git commit --amend` so it differs from the final post-amend HEAD that appears
in `git log`.

(b) **Bake the autonomy / loop workflow patterns** the user shared from
another session into the skill — so a future `/sprint-loop` run picks up the
same operational defaults: commit/push without per-step confirmation,
pre-flight rebase, defer-over-block, CI verify with a separate `gh run list`
after `gh run watch`, PR-body-via-heredoc, and a safety floor on
permission/security controls.

Sync everything to all three bundles and extend `selftest.sh` to cover the
back-fill regression.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| `open-harnesses/scripts/commit-task.sh` | **high** | 7-line back-fill block. Regex `grep -q "Commit:\*\* PENDING"` and `sed "0,/Commit:\*\* PENDING/{...}"` both unanchored. Hash captured via `git rev-parse --short HEAD` BEFORE amend; correct order is to amend first then capture, OR write a recognizable marker, amend, and `sed`-back-fill the marker. |
| `open-harnesses/scripts/selftest.sh` | high | 10-step harness today. A back-fill regression step would: set up a temp git repo with `completed-tasks.md` containing both a real `Commit:** PENDING` field AND a description that literally mentions "Commit:** PENDING"; run `commit-task.sh`; assert (i) the actual Commit field got the hash, (ii) the description's literal text was NOT modified, and (iii) the embedded hash equals `git rev-parse --short HEAD` (post-amend). |
| `claude-code/skills/sprint-loop/SKILL.md` | high | Description and routing. Will gain "Autonomous operation" and "Safety floor" sections in the body (not the YAML description, which stays scoped to invocation triggers). |
| `claude-code/skills/sprint-loop/phases/04-build-phase.md`, `phases/05-test-phase.md`, `phases/06-loop-phase.md` | high | Where pre-flight rebase, defer-over-block emphasis, CI verify pattern, and PR-merge-on-green pattern land. |
| `codex-cli/skills/sprint-loops/phases/{04,05,06}-*.md` | high | Sync targets. |
| `open-harnesses/particles/{06-build-phase,07-test-phase,08-loop-phase}.md` | medium | Open-harness particles get parallel single-sentence additions inside their existing quoted blocks. |

## 3. External Sources

None. The autonomy patterns are user-provided from another session (treated as
spec input). The back-fill bugs are observed directly in this repo's history.
Budget allows up to 5; 0 used.

## 4. Risks, Unknowns, Dependencies

- **Risk:** *Fix-then-amend ordering edge cases.* If the first commit succeeds
  but the amend fails (e.g. due to a hook), the placeholder is half-replaced
  and a stale commit lives on disk. Mitigation: keep the current order (write
  → amend) but capture the hash via `git log -1 --format=%h` AFTER the amend
  and `sed` it in, then do a SECOND amend. Two-amend approach is robust;
  worst case the SECOND amend fails and the placeholder is filled but the
  commit hash diverges by one amend — still better than today (off by one
  AND placeholder mismatched).
- **Risk:** *Autonomy directives in SKILL.md description conflict with
  description's primary job (skill discovery).* Mitigation: keep YAML
  description scoped to invocation triggers; put autonomy guidance in the
  body (Claude reads SKILL.md on invocation).
- **Risk:** *Particle additions dilute embedding surface for retrieval-based
  open harnesses.* Mitigation: keep additions to single-sentence
  integrations within existing quoted blocks; no new sections inside
  particles.
- **Unknown:** *Whether the protocol should mandate any CI tool.* Decision:
  NO — CI integration is documented as the user's optional choice; the
  protocol's contract is "watch for CI completion if configured." The CI
  verify pattern (separate `gh run list` after `gh run watch`) is added as
  guidance for the GitHub Actions case specifically.
- **Dependency:** `bash`, `sed`, `git rev-parse`, `git log`, `git commit
  --amend`. No new dependencies.

## 5. Recommended Approach

**Primary:** Three elementary tasks.

1. *Back-fill correctness fix in `commit-task.sh` + selftest regression test.*
   - Regex anchored to full line: `^- \*\*Commit:\*\* PENDING$` for both the
     grep guard and the sed substitution range. Eliminates substring false
     positives.
   - Hash captured POST-amend via two-stage amend: first amend folds the
     working tree, `git log -1 --format=%h` captures the final HEAD, sed
     fills the placeholder, second amend folds in the back-fill.
   - Extend `selftest.sh` with step 11: a temp git repo where
     `completed-tasks.md` has a description literally containing
     `Commit:** PENDING` PLUS a real anchored `Commit:** PENDING` field on
     its own line; run `commit-task.sh`; assert (a) description unchanged,
     (b) field filled with a hash, (c) embedded hash equals
     `git log -1 --format=%h`.

2. *Bake autonomy + workflow patterns into the skill.*
   - SKILL.md body: add "Autonomous operation" (work independently when
     invoked for a multi-turn loop; commit/push without per-step
     confirmation; defer-over-block) and "Safety floor" (don't weaken
     permission/security controls; surface declines and continue).
   - `phases/04-build-phase.md`: add a "Pre-flight" line at the top of the
     task-execution section (when on a branch: `git fetch && git rebase
     origin/<base>` before the first commit; run the project's sanity gate
     before `commit-task.sh`). Strengthen the defer-over-block note.
   - `phases/05-test-phase.md`: add a "CI verify" subsection — if the repo
     has GitHub Actions, after `gh run watch` ALWAYS run `gh run list
     --branch <X> --json status,conclusion` as a separate step (watch exit
     code is unreliable on some platforms).
   - `phases/06-loop-phase.md`: add a "PR merge" optional step — if the
     sprint produced a PR: on CI green, `gh pr merge <n> --merge
     --delete-branch` and sync local main; on CI fail, `gh run view <id>
     --log-failed` and fix on the same branch.
   - Particles `06-build-phase.md`, `07-test-phase.md`, `08-loop-phase.md`
     in open-harnesses: parallel single-sentence additions inside the
     existing quoted blocks.

3. *Sync to both bundles + propagate phase additions.* Copy updated scripts
   to both skill bundles, copy updated phase files between claude-code and
   codex-cli, verify md5/diff, both bundles' selftests run at 11 steps.

**Alternatives considered:**

- *Drop the back-fill feature entirely.* Rejected: it's useful when correct.
- *Switch to a different placeholder token.* Rejected as insufficient on its
  own — line anchoring is the right fix.
- *Add a `preflight.sh` helper script.* Rejected: every project's gate is
  different; the protocol documents the expectation but doesn't ship a
  one-size-fits-all script.

**Rationale:** Both strands address real friction. The back-fill fix removes
the per-commit manual-correction tax that's been visible in sprint 2's
history. The autonomy bake-in honors the user's mid-sprint direction without
inventing scope they didn't ask for. Three tasks, all testable, all
cross-bundle-consistent.

## Artifacts

- (none — research is fully self-contained in this report)
