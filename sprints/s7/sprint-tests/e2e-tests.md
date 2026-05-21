# Sprint 7 — End-to-End Tests

**Status:** never bash-testable — auto mode is a Claude Code harness behavior
(plan-mode auto-accept + `/loop`).

**First-launch verification (E2E stand-in, per plan-critic C-007):** the first
unattended launch should be bounded — `/loop 2 /sprint-loop continue` — and
confirm: (a) plan mode engaged, (b) auto-accept carried Build/Test/Loop with
no per-step prompts, (c) the next sprint fired, (d) NO merge-to-base happened
unattended (PR left open for review). This is the verification step to run the
first time auto mode is used in anger.
