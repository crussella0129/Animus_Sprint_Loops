# Schema: `research-report.md`

Lives at `sprints/sN/sprint-research/research-report.md`. Exit artifact of the
Research Phase. Must contain the five numbered sections below, plus the
`## Decisions Reviewed` section whenever `decisions.md` has any entries
(`finalize-plan.sh` enforces this).

```markdown
# Sprint N Research Report

## Decisions Reviewed
(Required when `decisions.md` has entries. List the ADRs from `decisions.md` that
bear on this sprint's work, with one line of relevance each. Explicitly call out
any proposal to revise or violate a prior decision; if none, say "No prior
decision is being violated.")
- **YYYY-MM-DD <short title>** (sprint N) — relevance: ...

## 1. Sprint Goal
(One paragraph in agent's own words.)

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
(OPTIONAL — include only when the Existing Code Survey exceeds 20 file rows or
External Sources exceeds 5 URLs. `finalize-plan.sh` refuses to lock plans when
over budget unless this section is present with a non-empty justification.
Explain why the scope genuinely required the extra breadth — e.g. a
cross-cutting refactor touching many files. Do not use as a default escape.)
```
