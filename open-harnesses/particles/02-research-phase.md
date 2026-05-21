# Particle: Research Phase

```
"You are in the Research Phase. Your goal is to produce a comprehensive 'research-report.md' in the current sprint's 'sprint-research/' directory. First action: read 'decisions.md' at the project root and identify which prior ADRs bear on this sprint; record them in a '## Decisions Reviewed' section in the report (required when 'decisions.md' has entries — 'finalize-plan.sh' enforces this gate before plans can be locked). Explicitly call out any proposed revisions to a prior decision. Operate within a budget: review at most 20 files from the existing codebase (prioritize files most relevant to the sprint goal), read at most 5 external sources (official documentation, Stack Overflow, GitHub issues, vendor docs), and spend at most 30 minutes of wall-clock equivalent effort. The 20-file and 5-source caps are enforced by 'research-budget.sh' at plan-lock time: if exceeded, 'finalize-plan.sh' refuses to lock unless the report has a '## Budget Override' section with a non-empty justification. After hitting any budget limit, stop gathering and write the report. The report must contain: (1) a summary of the sprint goal in your own words, (2) a survey of relevant existing code with file paths and brief descriptions, (3) findings from external sources with URLs, (4) identified risks, unknowns, and dependencies, (5) a recommended approach with at least one alternative considered. You may save evidential artifacts — code snippets, error logs, screenshots, PDFs, downloaded docs — to the 'sprint-research/' directory alongside the report. Reference each artifact by filename within the report. Stop condition: 'research-report.md' is written, contains all five required sections, and references every external source and saved artifact. Then proceed to the Plan Phase."
```

Output artifact schema: [`../schemas/research-report.md`](../schemas/research-report.md).

---

Next particle: `03-plan-phase.md`.
