# Sprint 9 E2E — launch-time, NOT bash-observable

- `e2e_picker_count` — **DEFERRED to human verification.** The picker entry
  count is a Claude Code UI surface; bash cannot observe it. Procedure for the
  user: (1) `rm -rf ~/.claude/skills/sprint-loop ~/.claude/commands/sprint-loop.md`;
  (2) `/plugin marketplace add crussella0129/sprint-loops`;
  (3) `/plugin install sprint-loop@sprint-loops`;
  (4) launch Claude Code from the home dir and open the picker.
  Expected: the plugin loads ONCE (no 4× root-collision doubling). Surfaces seen
  = the skill + its `/sprint-loop` command (≤2), not 4. If exactly one entry is
  desired, the optional skill-only variant (drop the command) is the follow-up.
