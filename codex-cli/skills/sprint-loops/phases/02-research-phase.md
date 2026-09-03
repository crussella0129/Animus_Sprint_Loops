# Phase 02 — Research

## Outcome

Produce an evidence-backed research report for a bounded sprint goal and create
or select at least one stable intent chapter that the sprint advances.

## Inputs

Use the installed bundle's `scripts/current-sprint.sh` helper with the project
root as its working directory, then inspect:

- relevant chapters under `docs/intents/`;
- the prior sprint's `failure-report.md`, when present;
- up to 20 relevant project files;
- up to 5 relevant external sources.

Spend at most 30 minutes of wall-clock-equivalent research. If a code/source
cap is exceeded for a genuinely cross-cutting problem, add a non-empty
`## Budget Override` justification.

Write
`docs/sprints/sN/sprint-research/research-report.md` using the schema. Its
`## Intents Reviewed` section must link at least one `INT-NNNN` chapter and
say whether it was created, selected, or revised. Include the five numbered
sections, reference every saved artifact, and invoke the installed bundle's
`scripts/research-budget.sh` helper with the project root as its working
directory. Add a `docs/SUMMARY.md` navigation link for any newly created
intent; the link makes the chapter reachable but carries no state.

## Authority

Intent chapters define the desired outcome and acceptance boundaries. Research
may discover that an intent needs revision, but the change must be made in the
relevant chapter's Intent, Acceptance criteria, Rationale, Alternatives, or
Consequences and any state change appended to Transition history. The research
report records how and why the sprint reached its recommendation; it does not
become a competing semantic authority.

Do not use navigation or migrated history as current project intent.

## Exit evidence

- At least one valid `docs/intents/INT-NNNN-*.md` chapter is selected or
  created, and every new chapter is reachable from `docs/SUMMARY.md`.
- The non-empty research report links every reviewed intent under the exact
  `## Intents Reviewed` heading.
- The report contains Sprint Goal, Existing Code Survey, External Sources,
  Risks/Unknowns/Dependencies, Recommended Approach, and referenced artifacts.
- `research-budget.sh` passes, or the report contains a justified override.
- The phase's exit artifacts are committed; the installed `scripts/check-tracked.sh` helper reports a clean Book.
- The installed `current-phase.sh` helper reports `plan`.

When complete, read `phases/03-plan-phase.md`.
