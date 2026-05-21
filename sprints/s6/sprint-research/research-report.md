# Sprint 6 Research Report

## Decisions Reviewed

ADRs from `decisions.md` bearing on this sprint:

- **2026-05-20 — `finalize-plan.sh` rejects empty build-plans + `install.sh` per bundle (sprint 2)** — relevant: `finalize-plan.sh` is the canonical pre-lock enforcement gate. Sprint 6 extends it with a third check (research budget).
- **2026-05-20 — Hard plan-mode primitive + EARS criteria + decisions-reviewed gate (sprint 4)** — relevant: established the precedent for `finalize-plan.sh` enforcing research-report shape; sprint 6 extends the same pattern with a budget gate.
- **2026-05-20 — Subagent fan-out: adversarial critic review at Plan + Test phases (sprint 5)** — relevant: sprint 6 is the first to operationally test the critic protocol (dogfooding). The research-budget enforcement should NOT short-circuit the critic step — both gates run.

No prior decision is being violated. This sprint adds a budget gate that composes additively with the existing decisions-reviewed and empty-plan gates.

## 1. Sprint Goal

User priority #4 from sprint 3's flagged candidates (the last open item):
**enforced research budget**. The 20-files / 5-sources / 30-min cap in
`phases/02-research-phase.md` is honor-system today. Add
`scripts/research-budget.sh` that counts file and source references in
`research-report.md`, and a `finalize-plan.sh` gate that refuses to lock
plans when the budget is exceeded UNLESS the research-report includes a
`## Budget Override` section with a non-empty justification.

The 30-minute wall-clock cap remains honor-system (can't measure
wall-clock from a script); file/source counters become real.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| `open-harnesses/scripts/finalize-plan.sh` | **high** | Already has empty-plan + decisions-reviewed gates. Sprint 6 adds the budget gate alongside. |
| `open-harnesses/schemas/research-report.md` | high | Document the optional `## Budget Override` section. |
| `claude-code/skills/sprint-loop/phases/02-research-phase.md` | high | Document the budget enforcement + override mechanism. |
| `open-harnesses/particles/02-research-phase.md` | medium | Single-sentence integration inside the quoted block. |
| `open-harnesses/scripts/selftest.sh` | medium | Step 13: verify the budget gate fires when over-budget AND research-report lacks an override section. |
| (new) `open-harnesses/scripts/research-budget.sh` | high | Counter script — counts rows under `## ... Existing Code Survey` and URL-bearing lines under `## ... External Sources`; exits non-zero if over budget. |

## 3. External Sources

None. The counter is a simple grep over the report's documented sections.
Budget allows 5; 0 used.

## 4. Risks, Unknowns, Dependencies

- **Risk:** *Counter false-positives.* Mitigation: count markdown-table rows (`^\| ` prefix) under `## (...)? Existing Code Survey` and URL-bearing lines (`^- \[.*\]\(http`) under `## (...)? External Sources`. Tolerant of numeric-prefix variants (lesson from sprint 4's decisions-reviewed grep).
- **Risk:** *Override abuse.* The script requires the override section to have at least one non-blank body line. Docs say "use only when scope genuinely required more (e.g. cross-cutting refactor) — not as a default escape."
- **Risk:** *Sprint 0 with no `## 2.` section.* The counter exits gracefully (counts=0) when sections don't exist; well within budget.
- **Unknown:** *Soft warn vs hard gate.* Decision: HARD gate from day one. The override mechanism provides the escape. Soft enforcement reproduces the honor-system problem.
- **Dependency:** `bash`, `grep`, `awk`. No new deps.

## 5. Recommended Approach

**Primary:** Three elementary tasks.

1. *Add `scripts/research-budget.sh` + wire into `finalize-plan.sh`.*
   - `research-budget.sh` reads the current sprint's `research-report.md`,
     counts files in `## ... Existing Code Survey` table rows and URLs in
     `## ... External Sources` bullets. Emits `files=N sources=M` and
     exits 0 within budget (≤20 files AND ≤5 sources), 1 otherwise.
   - `finalize-plan.sh` invokes the script; on non-zero exit checks for a
     `## Budget Override` section with a non-empty body; refuses if missing.
2. *Document the budget enforcement.* Update `phases/02-research-phase.md`,
   `schemas/research-report.md`, and `particles/02-research-phase.md`.
3. *Sync + selftest step 13.* Copy the new script + updated `finalize-plan.sh`
   and `selftest.sh` to both bundles. Step 13: temp project, research-report
   with 25 file rows (over budget), no override → finalize refuses; add
   override → finalize accepts.

**Alternatives considered:**

- *Wall-clock enforcement* via `.sprint-start-time`. Rejected — sprints span sessions.
- *Soft warn-only mode.* Rejected — reproduces the honor-system problem.
- *Per-sprint configurable budgets.* Rejected — adds config surface for marginal benefit.

**Rationale:** The budget gate composes with existing gates. The override mechanism makes the budget realistic — sometimes scope genuinely demands more research.

## Artifacts

- (none — research is self-contained)
