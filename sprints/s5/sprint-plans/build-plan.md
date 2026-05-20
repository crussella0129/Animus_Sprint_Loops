Finalized - DO NOT EDIT

# Sprint 5 Build Plan

## Schema Tree
- Sprint Goal: subagent fan-out for adversarial critic review at Plan + Test phases
  - Component A: critic prompt templates
    - T-001: add `prompts/plan-critic.md` and `prompts/test-critic.md` in `open-harnesses/`
  - Component B: spawn-review-address protocol in phase docs
    - T-002: update `phases/03-plan-phase.md` + `phases/05-test-phase.md` (claude-code) and open-harnesses particles 03 + 07 with the critic-spawn workflow + a `critique.md` artifact under `sprint-plans/`
  - Component C: cross-bundle sync
    - T-003: copy prompts into both skill bundles; sync phase doc changes to codex (preserving its `/plan` opening); update codex SKILL.md "Subagent opportunity" to reference the critics

## Execution Sequence

### T-001: Add `prompts/plan-critic.md` and `prompts/test-critic.md` (canonical in open-harnesses)
- **Touches:** `open-harnesses/prompts/plan-critic.md` (new), `open-harnesses/prompts/test-critic.md` (new)
- **Depends on:** (none)
- **Success criterion (EARS):**
  - **WHEN** an agent reads `prompts/plan-critic.md`, **THEN** the prompt **SHALL** instruct the critic subagent to read `sprint-plans/build-plan.md` and `sprint-plans/test-plan.md`, identify specific failure modes (vague/missing EARS clauses, plan-test mismatch, missing risk coverage, ignored ADRs from `decisions.md`, hidden dependencies between tasks), and return a structured critique with sections `## Concerns` and `## Confidence` (one of `block` / `proceed-with-caveats` / `clean`).
  - **WHEN** an agent reads `prompts/test-critic.md`, **THEN** the prompt **SHALL** instruct the critic to read the just-written test artifacts (`sprint-tests/{unit,integration,e2e}-tests.md`), check that every EARS clause in `build-plan.md` has at least one corresponding `test_*`, identify gaps in assertion tightness, and return the same `## Concerns` / `## Confidence` structure.
- **Notes:** Prompts are markdown with a clear front-matter-ish opening describing the critic's role + the structured output format. They take no parameters — the critic infers paths from the sprint state.

### T-002: Wire spawn-review-address protocol into phase docs
- **Touches:** `claude-code/skills/sprint-loop/phases/03-plan-phase.md`, `claude-code/skills/sprint-loop/phases/05-test-phase.md`, `open-harnesses/particles/03-plan-phase.md`, `open-harnesses/particles/07-test-phase.md`
- **Depends on:** T-001
- **Success criterion (EARS):**
  - **WHEN** an agent reaches the end of Plan Phase (after plans written to disk, before `finalize-plan.sh`), **THEN** `phases/03-plan-phase.md` **SHALL** instruct it to spawn a critic subagent using the Agent tool with the `prompts/plan-critic.md` template, capture the response in `sprints/sN/sprint-plans/critique.md`, address each concern (fix-in-plan / defer-with-rationale / reject-the-critique), and proceed to `finalize-plan.sh` only after the critique is recorded with responses.
  - **WHEN** an agent reaches the end of Test Phase (after tests written + run, before `test-report.md`), **THEN** `phases/05-test-phase.md` **SHALL** instruct it to spawn a critic with `prompts/test-critic.md`, capture the response in `sprints/sN/sprint-tests/critique.md`, and address each concern (add missing tests / tighten assertions / defer to follow-up with rationale) before finalizing `test-report.md`.
  - **WHEN** an agent reads open-harnesses particles 03 or 07, **THEN** each quoted block **SHALL** mention the critic-spawn pattern with a fallback ("if your harness supports subagents, spawn a critic with the matching prompt; otherwise self-critique in a single message before locking").
- **Notes:** `critique.md` lives under `sprint-plans/` and `sprint-tests/` respectively, alongside the artifact it critiques. Schema for `critique.md` is minimal — `## Concerns` list with primary-agent responses, then `## Confidence` (the critic's bottom-line judgment). The primary agent's responses are inline so the audit trail is one file. No new schema file needed; the prompts document the structure.

### T-003: Sync to both skill bundles
- **Touches:** `claude-code/skills/sprint-loop/prompts/{plan-critic.md,test-critic.md}` (new), `codex-cli/skills/sprint-loops/prompts/{plan-critic.md,test-critic.md}` (new), `codex-cli/skills/sprint-loops/phases/{03-plan-phase.md,05-test-phase.md}`, `codex-cli/skills/sprint-loops/SKILL.md` (cross-reference critic prompts from Subagent opportunity section)
- **Depends on:** T-001, T-002
- **Success criterion (EARS):**
  - **WHEN** `md5sum` is run on `prompts/plan-critic.md` and `prompts/test-critic.md` across all 3 bundle locations (`open-harnesses/prompts/`, `claude-code/skills/sprint-loop/prompts/`, `codex-cli/skills/sprint-loops/prompts/`), **THEN** the values **SHALL** match.
  - **WHEN** `diff -q` is run on `phases/03-plan-phase.md` and `phases/05-test-phase.md` between claude-code/sprint-loop and codex-cli/sprint-loops, **THEN** phase 05 **SHALL** be byte-identical (phase 03 differs only in the opening — claude has `EnterPlanMode`, codex has `/plan`).
  - **WHEN** an agent reads codex's SKILL.md, **THEN** the "Subagent opportunity" section **SHALL** reference `prompts/plan-critic.md` and `prompts/test-critic.md` for adversarial-review subagent prompts.
  - **WHEN** each bundle's `selftest.sh` is invoked, **THEN** it **SHALL** exit 0 reporting `all 12 transitions matched` (selftest unchanged — critic step is LLM-execution-level, not bash-testable).
- **Notes:** No selftest extension this sprint; the critic step is exercised next time `/sprint-loop` runs through Plan or Test phase manually. Test report will note this limitation.
