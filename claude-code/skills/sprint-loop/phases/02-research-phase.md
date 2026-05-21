# Phase 02 — Research

Your goal is to produce a comprehensive `research-report.md` in the current
sprint's `sprint-research/` directory.

**First action: read `decisions.md` at the project root.** Identify which prior
architectural decisions (ADRs) bear on this sprint's proposed work. These
become the report's `## Decisions Reviewed` section (required when
`decisions.md` has entries — `finalize-plan.sh` enforces this gate before
plans can be locked). If you intend to revise or violate a prior decision,
say so explicitly with the rationale.

Operate within a budget: review at most **20 files** from the existing codebase
(prioritize files most relevant to the sprint goal), read at most **5 external
sources** (official documentation, Stack Overflow, GitHub issues, vendor docs),
and spend at most **30 minutes** of wall-clock equivalent effort. After hitting
any budget limit, stop gathering and write the report.

**The 20-file / 5-source caps are enforced.** `finalize-plan.sh` runs
`research-budget.sh`, which counts the data rows of your `## Existing Code
Survey` table and the URL bullets under `## External Sources`. If either
exceeds its cap, the plans cannot be locked **unless** the report includes a
`## Budget Override` section with a non-empty justification (one paragraph
explaining why the scope genuinely required more — e.g. a cross-cutting
refactor). Use the override sparingly; it is an escape hatch for real
breadth, not a default. The 30-minute cap remains honor-system (a script
can't measure wall-clock across sessions).

The report must contain:

0. **`## Decisions Reviewed`** — required when `decisions.md` has entries;
   lists the relevant ADRs and explicitly acknowledges any proposed revisions.
1. A summary of the sprint goal in your own words.
2. A survey of relevant existing code with file paths and brief descriptions.
3. Findings from external sources with URLs.
4. Identified risks, unknowns, and dependencies.
5. A recommended approach with at least one alternative considered.

You may save evidential artifacts — code snippets, error logs, screenshots, PDFs,
downloaded docs — to the `sprint-research/` directory alongside the report.
Reference each artifact by filename within the report.

Follow `schemas/research-report.md` for the report format.

**Stop condition:** `research-report.md` is written, contains all five required
sections, and references every external source and saved artifact.

**When complete, read `phases/03-plan-phase.md`.**
