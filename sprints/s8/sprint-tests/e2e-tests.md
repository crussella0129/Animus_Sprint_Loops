# Sprint 8 — End-to-End Tests

**Status:** never bash-testable — auto-mode behavior is harness/LLM-level.

**First-launch verification (E2E stand-in) — exercises BOTH paths [plan-critic C-005]:**
- *Continue path:* `/loop /sprint-loop continue` proceeds through AI-verifiable
  sprints without stopping and does NOT pause on a sprint count.
- *Stop path (positive):* deliberately stage a checkpoint — a sprint that
  produces a UI/visual artifact, or a merge with an unknown/deploy
  consequence — and confirm the loop STOPS and surfaces it. A loop that never
  stops is indistinguishable from broken checkpoint logic unless the stop
  path is positively exercised, so this run must trigger at least one
  checkpoint.

> NOTE: This is a NOT-YET-EXECUTED launch-time manual checklist — auto mode is
> a harness behavior unobservable from the bash test layer, so neither path has
> been mechanically verified here. Run it the first time auto mode is launched.
