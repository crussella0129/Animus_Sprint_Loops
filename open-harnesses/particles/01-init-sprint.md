# Particle: Initialize Sprint

> Inject once at the start of every sprint, before Research.

```
"Initialize the current sprint's filesystem state. First, verify the existence of a 'sprints/' directory at the project root; create it if missing. Then determine the current sprint number: list all 'sN' subdirectories within 'sprints/', find the highest N, and add 1. If no 'sN' subdirectories exist, this is sprint 0. Create the new 'sprints/sN/' directory and within it create: 'sprint-research/' containing 'research-report.md'; 'sprint-plans/' containing 'build-plan.md' and 'test-plan.md'; 'sprint-tests/' containing 'unit-tests.md', 'integration-tests.md', 'e2e-tests.md', and 'test-report.md'. Also create 'sprint-meta.md' at 'sprints/sN/sprint-meta.md' populated with: sprint number, start timestamp (ISO 8601), model identifier, and exit status set to 'in-progress'. Next, at the project root, verify the existence of the 'agent-tasks/' directory containing 'agent-tasks.md' and 'completed-tasks.md'; create any that are missing as empty files. The 'agent-tasks/' directory is persistent and shared across all sprints. Verify the existence of 'decisions.md' at the project root; create it as an empty file if missing. Finally, drop an idempotent (marker-guarded) '.gitignore' block excluding the ephemeral sprint working memory ('sprints/', '*.tmp') while keeping long-term memory tracked ('decisions.md', 'agent-tasks/', 'confidence.txt'); preserve any existing '.gitignore' contents. Once all directories and files exist, proceed to the Research Phase."
```

Output artifact schema: [`../schemas/sprint-meta.md`](../schemas/sprint-meta.md).
Helper script: [`../scripts/current-sprint.sh`](../scripts/current-sprint.sh) prints the active sprint number.

---

Next particle: `02-research-phase.md`.
