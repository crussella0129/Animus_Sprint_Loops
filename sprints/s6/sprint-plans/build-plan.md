Finalized - DO NOT EDIT

# Sprint 6 Build Plan

## Schema Tree
- Sprint Goal: enforced research budget (user priority #4)
  - Component A: counter + enforcement
    - T-001: add `scripts/research-budget.sh` + wire into `finalize-plan.sh` as a third gate (alongside empty-plan + decisions-reviewed); `## Budget Override` section satisfies the gate when budget exceeded
  - Component B: documentation
    - T-002: document the budget gate + override mechanism in `phases/02-research-phase.md`, `schemas/research-report.md`, and `open-harnesses/particles/02-research-phase.md`
  - Component C: cross-bundle sync + regression coverage
    - T-003: sync new script + updated `finalize-plan.sh`/`selftest.sh` to both bundles; selftest step 13 guards the gate

## Execution Sequence

### T-001: Add `research-budget.sh` + wire into `finalize-plan.sh`
- **Touches:** `open-harnesses/scripts/research-budget.sh` (new), `open-harnesses/scripts/finalize-plan.sh`
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** `research-budget.sh` is invoked from a project root with a current sprint's `research-report.md`, **THEN** it **SHALL** print `files=N sources=M` (where N is the count of *data rows* — header + separator rows excluded) and exit 0 if N≤20 AND M≤5, exit 1 otherwise.
  - **WHEN** the report has no `## ... Existing Code Survey` section, **THEN** the counter **SHALL** treat files as 0 (within budget) and not error.
  - **WHEN** `finalize-plan.sh` runs after `research-budget.sh` returns non-zero AND the current sprint's `research-report.md` lacks a `## Budget Override` heading followed by at least one non-whitespace body line before the next `## ` heading, **THEN** `finalize-plan.sh` **SHALL** exit non-zero with a clear message and not lock the plans.
  - **WHEN** `## Budget Override` is present with a non-whitespace body line, **THEN** `finalize-plan.sh` **SHALL** allow the lock (override accepted).
- **Notes:** Counter pattern: awk-slice the file between `^## ([0-9]+\. *)?Existing Code Survey` and the next `^## ` heading, then `grep -cE '^\| ' | tail -n +3`-style skip of the two header rows (header + `|-----|` separator). Same slicing for `## ... External Sources` with `grep -cE '^- \[.*\]\(http'`. For the override check: awk-slice between `^## Budget Override$` and the next `^## ` heading, test for any line matching `^[^[:space:]]` (non-whitespace lead — eliminates blank lines and indentation-only lines). All slicing uses awk with `/start/,/end/` patterns to stay portable.

### T-002: Document the budget gate + override
- **Touches:** `claude-code/skills/sprint-loop/phases/02-research-phase.md` (canonical claude copy — codex gets the propagation in T-003), `open-harnesses/schemas/research-report.md`, `open-harnesses/particles/02-research-phase.md`
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** an agent reads `phases/02-research-phase.md`, **THEN** the file **SHALL** mention the budget gate, the 20/5 thresholds, and the `## Budget Override` escape with non-empty justification requirement.
  - **WHEN** an agent reads `schemas/research-report.md`, **THEN** the schema **SHALL** show an optional `## Budget Override` section near the end with a placeholder for justification text.
  - **WHEN** an agent reads `open-harnesses/particles/02-research-phase.md`, **THEN** the quoted block **SHALL** mention the budget enforcement.

### T-003: Sync + selftest step 13
- **Touches:** `claude-code/skills/sprint-loop/scripts/{research-budget.sh,finalize-plan.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/scripts/{research-budget.sh,finalize-plan.sh,selftest.sh}`, `claude-code/skills/sprint-loop/{phases/02-research-phase.md,schemas/research-report.md}`, `codex-cli/skills/sprint-loops/{phases/02-research-phase.md,schemas/research-report.md}`, `open-harnesses/scripts/selftest.sh`
- **Depends on:** T-001, T-002
- **Success criterion (EARS):**
  - **WHEN** `md5sum` is run on `research-budget.sh`, `finalize-plan.sh`, `selftest.sh` across all 3 bundles, **THEN** the values **SHALL** match.
  - **WHEN** each bundle's `selftest.sh` is invoked, **THEN** it **SHALL** report `all 13 transitions matched`.
  - **WHEN** step 13 runs (research-report with 25 file rows + no override → finalize refuses; add override → finalize accepts), **THEN** both outcomes **SHALL** match expectations.
