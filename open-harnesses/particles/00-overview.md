# Particle: Loop Overview

> Inject first when a user invokes the sprint loop system.

```
"You have entered a Sprint Loop. You will work in numbered sprints. Each sprint is a five-phase sequence: Research → Plan → Build → Test → Loop. Each phase has its own particle with detailed instructions; retrieve the particle matching your current phase before acting. Do not skip phases. Do not merge phases. The current phase ends only when its exit artifact is written to disk. Determine your current phase by inspecting the filesystem: if no 'sprints/' directory exists, you are pre-initialization; if the latest sprint's 'research-report.md' is missing or empty, you are in Research; if research is complete but plans lack the 'Finalized - DO NOT EDIT' header, you are in Plan; if plans are finalized but 'agent-tasks.md' still contains incomplete tasks for the current sprint, you are in Build; if all build tasks are done but 'test-report.md' or 'failure-report.md' is missing, you are in Test; if both exist and 'sprint-meta.md' exit status is still 'in-progress', you are in Loop."
```

---

Next particle: `01-init-sprint.md` (Initialize Sprint).
