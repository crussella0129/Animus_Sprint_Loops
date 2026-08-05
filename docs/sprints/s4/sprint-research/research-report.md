# Sprint 4 Research Report

## 0. Decisions Reviewed

Per the new convention this sprint is establishing (T-003), explicitly listing
the architectural decisions from `decisions.md` that bear on this sprint's
work:

- **2026-05-19 `current-phase.sh` build/test disambiguator** (sprint 0) — relevant: the routing model. This sprint doesn't touch routing.
- **2026-05-20 commit-task.sh back-fills hashes** (sprint 1) — relevant: how the commit-task contract works. This sprint doesn't change the commit boundary.
- **2026-05-20 abort path + Exit-status hoist** (sprint 1) — relevant: the closed-sprint short-circuit in `current-phase.sh`. Unaffected.
- **2026-05-20 finalize-plan rejects empty build-plans + install.sh per bundle** (sprint 2) — relevant: `finalize-plan.sh` already has a pre-flight check that refuses on schema-violation. Sprint 4 T-003 extends the same gate.
- **2026-05-20 Line-anchored back-fill regex + accept off-by-one amend hash** (sprint 3) — relevant: regex patterns in helpers. Sprint 4's `finalize-plan.sh` extension follows the same line-anchored discipline.
- **2026-05-20 Bake autonomy + workflow patterns into the skill** (sprint 3) — relevant: this sprint is the first to operate under the autonomy directives explicitly. T-001 (hard plan-mode primitive) sharpens the "Use Plan Mode for the Plan Phase" line from SKILL.md by wiring the actual tool call.

No prior decision is being violated. T-003's new gate strengthens (not contradicts) the sprint-2 empty-plan check.

## 1. Sprint Goal

Three of sprint 3's flagged candidates, in user-prioritized order:

(3) **Hard plan-mode primitive.** Replace the soft "engage plan mode now"
instruction in `phases/03-plan-phase.md` with an explicit `EnterPlanMode` /
`ExitPlanMode` tool-call protocol the agent runs at phase-entry and
phase-exit. Claude-Code-specific (Codex already uses `/plan`; open-harnesses
keeps the generic instruction).

(2) **EARS-format success criteria.** `schemas/build-plan.md` requires
success criteria in EARS form (`WHEN <trigger> THEN <component> SHALL
<response>`) so the Test Phase can scaffold tests mechanically.
`phases/03-plan-phase.md` instructs the format; `phases/05-test-phase.md`
documents how to derive tests from EARS clauses.

(5) **Cross-sprint architectural drift detection.** `phases/02-research-phase.md`
mandates reading `decisions.md` at start of Research; `schemas/research-report.md`
gains a "## Decisions Reviewed" section listing relevant ADRs and explicitly
acknowledging any proposal to revise/violate one. `finalize-plan.sh` gains a
pre-lock check: refuse to finalize unless the sprint's `research-report.md`
contains a "Decisions Reviewed" section.

Sync to all 3 bundles + extend selftest.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| `claude-code/skills/sprint-loop/phases/03-plan-phase.md` | **high** | Currently says "**Engage plan mode now. Use maximum effort.**" — soft directive. Will gain a concrete `EnterPlanMode`/`ExitPlanMode` tool-call sequence. |
| `open-harnesses/scripts/finalize-plan.sh` | high | Already enforces non-empty build-plan + `### T-XXX:` presence. Will gain a third check: research-report must contain `## Decisions Reviewed` heading (skip when `decisions.md` is empty/absent — new projects). |
| `open-harnesses/schemas/build-plan.md` | high | Current success-criterion field is freeform prose. EARS format added as the recommended structure. |
| `open-harnesses/schemas/research-report.md` | high | Adds a `## Decisions Reviewed` section near the top (after sprint goal, before existing sections — or just at the start). |
| `open-harnesses/particles/02-research-phase.md`, `03-plan-phase.md` | medium | Particles get parallel single-sentence additions inside their existing quoted blocks. |
| `open-harnesses/particles/04-build-plan-schema.md`, `05-test-plan-schema.md` | medium | Build-plan composition particle references "success criterion" — needs an EARS-format note. Test-plan composition particle references unit-test derivation — gains an EARS-driven scaffolding note. |
| `claude-code/skills/sprint-loop/phases/05-test-phase.md`, `codex-cli/skills/sprint-loops/phases/05-test-phase.md` | medium | Test phase doc gains an EARS-decomposition snippet for unit-test generation. |
| `open-harnesses/scripts/selftest.sh` | medium | Step 12 (new) — verify `finalize-plan.sh` refuses to lock plans when research-report lacks the Decisions Reviewed section AND `decisions.md` is non-empty. |

## 3. External Sources

EARS format is well-documented (Alistair Mavin et al., 2009 onward). The
format is simple enough that the schema example suffices without consulting
external references. Budget allows 5; 0 used.

## 4. Risks, Unknowns, Dependencies

- **Risk:** *`EnterPlanMode` / `ExitPlanMode` tool semantics.* Plan mode in Claude Code typically blocks Edit/Write; the Plan Phase still needs to WRITE the plan files. Mitigation: instruct the agent to do the reasoning + plan synthesis in plan mode, then `ExitPlanMode` (presents plans for user approval), then in normal mode write the plan files to disk and run `finalize-plan.sh`.
- **Risk:** *EARS as mandatory format may be overkill for trivial tasks.* Mitigation: schema example shows EARS as recommended; the protocol allows freeform notes alongside. Requirement: "at least one EARS clause per success criterion," not "every word is EARS."
- **Risk:** *`finalize-plan.sh` decisions-review check fires on sprint 0 of a new project* (no `decisions.md` to review yet). Mitigation: check passes if `decisions.md` is empty OR absent. Only fires when there ARE ADRs and the research-report ignored them.
- **Unknown:** *Section naming.* Decision: `## Decisions Reviewed` (no numeric prefix; schema-stable, doesn't collide with existing 1-5 numbering).
- **Dependency:** `bash`, `sed`, `grep`. No new dependencies.

## 5. Recommended Approach

**Primary:** Four elementary tasks.

1. *Hard plan-mode primitive in claude-code's 03-plan-phase.md.* Replace
   the soft "Engage plan mode now" line with a concrete protocol: at phase
   entry invoke `EnterPlanMode`, reason through plan synthesis in plan
   mode (filesystem reads only), invoke `ExitPlanMode` with the two plan
   summaries; in normal mode, write the plan files to disk and run
   `finalize-plan.sh`. Update SKILL.md "Plan mode" section accordingly.
2. *EARS-format success criteria.* Update `schemas/build-plan.md` to show
   EARS clauses in the example. Update `phases/03-plan-phase.md` (both
   skill bundles) and `open-harnesses/particles/04-build-plan-schema.md`
   to require EARS for each task's success criterion. Update
   `phases/05-test-phase.md` (both bundles) and `open-harnesses/particles/
   05-test-plan-schema.md` to document EARS-to-test scaffolding (one
   `test_*` per WHEN/THEN/SHALL triple).
3. *Mandatory decisions.md read + finalize-plan.sh enforcement.* Update
   `phases/02-research-phase.md` (both bundles) and `open-harnesses/
   particles/02-research-phase.md` to require reading `decisions.md` at
   phase start. Update `schemas/research-report.md` to add a `##
   Decisions Reviewed` section. Update `finalize-plan.sh` to refuse to
   lock plans unless the current sprint's `research-report.md` contains
   that section heading (skip the check if `decisions.md` is empty/absent).
4. *Sync to both bundles + extend selftest with step 12.* Copy updated
   scripts to both bundles, propagate schema and phase additions, extend
   `selftest.sh` with a step asserting `finalize-plan.sh` refuses when
   `decisions.md` is non-empty AND research-report lacks the Decisions
   Reviewed section.

**Alternatives considered:**

- *Hard plan-mode for Codex too.* Rejected: Codex's `/plan` is already a
  user-driven slash command; the SKILL.md tells the user to invoke it.
- *EARS replacing freeform entirely.* Rejected: backward-compat matters.
  EARS is recommended; freeform alongside is allowed.
- *New script for the decisions-review check.* Rejected: `finalize-plan.sh`
  is already the plan-lock gate; one gate is simpler than two.

**Rationale:** All three changes tighten the protocol's contract without
inventing new mechanisms. Plan-mode goes soft → hard (tool call), success
criteria gain a parseable format, decisions get a mandatory read at the
right gate. Sprint 5 candidates (subagent fan-out, enforced research budget)
carry forward unchanged.

## Artifacts

- (none — research is self-contained)
