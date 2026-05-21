# Phase 01 — Initialize Sprint

Initialize the current sprint's filesystem state. The helper script does this
deterministically:

```bash
bash scripts/init-sprint.sh
```

This will: verify/create the `sprints/` directory at the project root; determine
the next sprint number (highest existing `sN` + 1, or 0 if none exist); create
`sprints/sN/` containing `sprint-research/research-report.md`,
`sprint-plans/build-plan.md`, `sprint-plans/test-plan.md`, and
`sprint-tests/` with `unit-tests.md`, `integration-tests.md`, `e2e-tests.md`,
`test-report.md`; create and populate `sprint-meta.md` (sprint number, ISO 8601
start timestamp, model identifier, exit status `in-progress`); create the
persistent `agent-tasks/` directory with `agent-tasks.md` and `completed-tasks.md`
if missing; create `decisions.md` at the project root if missing; and drop an
idempotent `.gitignore` block that excludes the **ephemeral** sprint working
memory (`sprints/`, `*.tmp`) while keeping the **long-term** memory tracked
(`decisions.md`, `agent-tasks/`, `confidence.txt` — the architectural-drift
gate and task ledger depend on these living in the repo). The block is
marker-guarded, so re-running init never duplicates it and any existing
`.gitignore` is preserved.

If you cannot run the script, perform every step above by hand. See
`schemas/sprint-meta.md` for the `sprint-meta.md` format. The `agent-tasks/`
directory is persistent and shared across all sprints — never recreate it if it
already exists.

Once all directories and files exist, **when complete, read `phases/02-research-phase.md`.**
