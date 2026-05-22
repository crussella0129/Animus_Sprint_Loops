# Sprint 10 Test Report

## Summary
Collapsed the plugin's two `/sprint-loop` surfaces to exactly one: the skill now
carries `argument-hint` (so it IS the `/sprint-loop` slash command, args via
`$ARGUMENTS`) and the redundant legacy `commands/sprint-loop.md` was deleted.
All bash-verifiable criteria pass (18/18 unit+integration).

## Results
- **Unit 16/16, Integration 2/2 PASS.** Skill frontmatter/body correct;
  command + dir removed; install.sh + both READMEs scrubbed of command refs
  while retaining the `/plugin` install path; regression guard added.
- **Regression guard (adversarial):** checker fails on a re-added command file,
  on an empty `commands/` dir, and on a missing `argument-hint:` line — verified
  by direct mutation. No false-pass.
- **E2E (2, DEFERRED):** single-entry picker count + auto-trigger survival are
  launch-time UI behaviors → human-verification checkpoints (see e2e-tests.md).

## Critics
- Plan-critic: proceed-with-caveats; held at plan for explicit user authorization
  (C-4, sprint-9 deferral contract) — user authorized; tightened tests (C-3/C-5/C-6).
- Test-critic: proceed-with-caveats; flagged un-asserted empty-dir clause (now
  guarded) and the missing in-repo evidence trail (this report + filled artifacts).

## Open / deferred
- `allowed-tools` absence is verified but not machine-guarded (intentional — a
  future maintainer may legitimately set it; over-guarding rejected).
- Auto-trigger survival (C-2) is the user's launch-time check; one-line revert if
  it regressed.
- CI to run check-plugin-manifest.sh + check-merge-policy.sh + selftest.sh on push
  remains the standing top backlog item (guards are run-by-hand until then).
