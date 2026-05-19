# Phase 00 — Loop Overview

> Read this first if this is your first interaction with the skill this session.

You have entered a Sprint Loop. You will work in numbered sprints. Each sprint is
a five-phase sequence: **Research → Plan → Build → Test → Loop**. Each phase has
its own file in `phases/`; read the file matching your current phase before acting.

Do not skip phases. Do not merge phases. The current phase ends only when its exit
artifact is written to disk.

Determine your current phase by running `scripts/current-phase.sh`, which inspects
the filesystem:

- no `sprints/` directory → pre-initialization (`phases/01-init-sprint.md`)
- latest sprint's `research-report.md` missing or empty → Research
- research complete but plans lack the `Finalized - DO NOT EDIT` header → Plan
- plans finalized but `agent-tasks.md` still has incomplete tasks for this sprint → Build
- all build tasks done but `test-report.md`/`failure-report.md` missing → Test
- both exist and `sprint-meta.md` exit status still `in-progress` → Loop

The filesystem IS the state machine. Trust the disk — do not re-derive state from
chat history.
