# Sprint 2 Test Report

## Summary
- Unit tests: 12 passed / 0 failed / 12 total
- Integration tests: 1 passed / 0 failed / 1 total
- E2E tests: 0 / 0 / 0 (N/A — not yet possible; unlocked by CI, sprint 4 candidate)
- CI status: not-configured

## Failures
None at the unit/integration level. One real protocol bug was uncovered DURING
the sprint (in sprint 1's back-fill) — not part of sprint 2's plan but
manifesting on every `commit-task.sh` run. The bug is documented under each
sprint-2 completed-tasks entry; the regex flaw and pre-amend-hash flaw are
both flagged for sprint 3.

## Technical Debt Identified
- **Sprint 1 back-fill regex** matches `Commit:** PENDING` anywhere in the file,
  including inside description text. Must anchor with `^- \*\*Commit:\*\*
  PENDING`. Fix in sprint 3.
- **Sprint 1 back-fill hash capture** runs `git rev-parse --short HEAD` BEFORE
  the amend, so the embedded hash is pre-amend (not the final post-amend HEAD
  that appears in `git log`). Reorder: write a recognizable marker → amend →
  back-fill the marker with the post-amend hash → amend again (or use a
  different mechanism that captures the hash atomically). Fix in sprint 3.
- **Autonomy-loop patterns** the user shared mid-sprint (from another session)
  are a sprint 3 candidate: bake the standing directives into SKILL.md and the
  Build/Test/Loop phase files (commit/push/merge without asking; pre-flight
  rebase; defer-over-block; CI verify pattern with separate `gh run list`;
  PR body via heredoc; safety floor on permission/security controls).

## Coverage Observations
- `finalize-plan.sh`'s new rejection path is exercised by selftest step 10
  and a dedicated unit test. Future changes to the rejection criterion must
  update both.
- `install.sh` per bundle is idempotency-tested via tree-md5 comparison —
  any future divergence in install output catches as a md5 mismatch.
- Integration coverage now spans `install.sh` → `selftest.sh` end-to-end for
  the Claude Code bundle. The open-harnesses path is also install-tested.
  Codex bundle has install + selftest covered but no AGENTS.md round-trip
  test (it's a `cat >>` op, low-risk).
