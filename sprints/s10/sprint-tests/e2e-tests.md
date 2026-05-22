# Sprint 10 E2E — launch-time, NOT bash-observable

- `e2e_single_entry` — **DEFERRED to human verification.** After
  `/plugin marketplace add crussella0129/sprint-loops` + `/plugin install
  sprint-loop@sprint-loops` (skill-only) and removing any bare install, launching
  Claude Code from the home dir should show EXACTLY ONE `/sprint-loop` entry, and
  `/sprint-loop continue`, `/sprint-loop start "<goal>"`, and
  `/loop /sprint-loop continue` should all work (the skill IS the slash command).
- `e2e_auto_trigger_survives` — **DEFERRED, the C-2 caveat.** Confirm the skill
  still auto-triggers on sprint-loop intent / a present `sprints/` dir after the
  `argument-hint` addition. If it does NOT, that is the only regression and the
  fix is a one-line revert of the `argument-hint` frontmatter line (explicit
  `/sprint-loop` invocation is unaffected either way).
