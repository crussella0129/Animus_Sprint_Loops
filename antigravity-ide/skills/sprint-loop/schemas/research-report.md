# Schema: `research-report.md`

Lives at
`docs/sprints/sN/sprint-research/research-report.md`. It is Research
provenance, not a replacement for stable intent. Research must create or select
at least one intent chapter and record every relevant chapter under the exact
`## Intents Reviewed` heading used by `finalize-plan.sh`.

```markdown
# Sprint N Research Report

## Intents Reviewed
- [INT-0001](../../../intents/INT-0001-short-title.md) — selected | created | revised; relevance: ...; current state: ...

## 1. Sprint Goal
(One paragraph in the agent's own words, bounded by the reviewed intent.)

## 2. Existing Code Survey
| File | Relevance | Notes |
|------|-----------|-------|
| path/to/file.rs | high | Owns the X invariant |

## 3. External Sources
- [Source Title](url) — relevance summary

## 4. Risks, Unknowns, Dependencies
- **Risk:** ...
- **Unknown:** ...
- **Dependency:** ...

## 5. Recommended Approach
Primary: ...
Alternative considered: ...
Rationale: ...

## Artifacts
- `snippet-01.rs` — sample implementation
- `error-trace.txt` — observed failure mode

## Budget Override
(OPTIONAL — a non-empty justification required only when the code survey
exceeds 20 file rows or External Sources exceeds 5 URLs.)
```

Update the reviewed intent chapter when research changes its desired outcome,
acceptance criteria, rationale, alternatives, or consequences, and append a
Transition history entry for any state change. Do not bury such changes only in
the sprint report.

`research-budget.sh` reports the file/source count.
`finalize-plan.sh` requires at least one Book intent and at least one
Markdown-linked intent under `## Intents Reviewed`; it rejects a legacy
review heading as a substitute.
