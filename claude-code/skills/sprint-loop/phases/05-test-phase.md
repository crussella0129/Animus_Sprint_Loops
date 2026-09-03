# Phase 05 — Test

## Outcome

Verify the locked EARS promises and the linked intent acceptance criteria with
reproducible evidence, then produce either a reviewed pass report or a
failure report.

## Inputs

Read:

- `docs/sprints/sN/sprint-plans/build-plan.md` and `test-plan.md`;
- the acceptance criteria in every linked `docs/intents/INT-NNNN-*.md`;
- completed task and commit evidence in `docs/work/completed-tasks.md`;
- `prompts/test-critic.md`.

Derive at least one named test for every EARS clause: WHEN supplies the
arrangement and SHALL supplies the assertion. Also prove each affected intent
acceptance criterion through the test plan's traceability map. Record unit,
integration, and E2E results under
`docs/sprints/sN/sprint-tests/`. When E2E is not yet possible, name the
unlocking intent or sprint and give a rationale.

Use the project's canonical suite runner when one exists, retain its
per-suite confirmations, and record the tested head SHA plus authoritative CI
conclusion. External actions remain subject to the active harness's authority
rules.

On the pass path, run a read-only critic from the installed bundle's
`prompts/test-critic.md`, save and address the critique at
`sprint-tests/critique.md`, then re-run the critic after any evidence change.
Write `sprint-tests/test-report.md` only when the final critique has the exact
required headings and a `clean` or `proceed-with-caveats` verdict. Add that
report as Test evidence to each verified intent, but do not mark an intent
`realized` until its required completion and realization evidence is complete.

If a failure requires re-architecture, stop local patching and write
`docs/sprints/sN/failure-report.md` with affected intents, unmet acceptance
criteria, root cause, evidence, and recommended next state.

## Authority

Intent acceptance criteria are the semantic test oracle. Locked EARS clauses
are sprint-level promises derived from that oracle; the test plan and result
files are verification provenance. A passing implementation that violates an
intent boundary is not a successful sprint. Amend the intent explicitly only
when the desired outcome truly changed, never to make a failing test pass.

## Exit evidence

Exactly one route is complete:

- **Pass:** non-empty unit/integration/E2E result artifacts, a final
  `sprint-tests/critique.md` with `clean` or `proceed-with-caveats`, non-empty
  `sprint-tests/test-report.md`, and linked Test evidence on verified intents.
- **Re-architecture failure:** non-empty `failure-report.md` naming affected
  intents and evidence. A test critique/report is not required on this route.

- The phase's exit artifacts are committed; the installed `scripts/check-tracked.sh` helper reports a clean Book.

On the pass route, `test-report.md` plus a structurally valid critique with an
accepted final verdict are required for `current-phase.sh` to report `loop`.
A `block` or malformed critique remains in Test. A non-empty failure report
routes directly to `loop`.

When complete, read `phases/06-loop-phase.md`.
