# sprint-loops
A lightweight protocol for autonomous software development, for Claude Code, Codex, and Open Harnesses, like OpenClaw and OpenCode

# Sprint Loops

A structured agentic workflow system for long-horizon coding work. Sprint Loops decomposes work into numbered sprints, each a five-phase sequence (Research → Plan → Build → Test → Loop), with persistent state on disk and a clean separation between working memory and the rolling backlog.

This document covers three deployment targets:

1. **[Open Harnesses](#section-1-open-harnesses)** — OpenClaw, local LLMs, custom runners, any agent that can read files and run shell commands.
2. **[Claude Code](#section-2-claude-code)** — Anthropic's terminal coding agent, using the native skills system.
3. **[Codex CLI](#section-3-codex-cli)** — OpenAI's terminal coding agent, using its skills system + `AGENTS.md`.

The core protocol — filesystem layout, phase exit conditions, schemas — is identical across all three. What changes is how the agent discovers and routes through the phases.

---

## Core Protocol (applies to all three)

### Directory Schema

```
project-root/
├── decisions.md                      # ADR-style architectural decisions log
├── confidence.txt                    # Optional: confidence scalar (Kalman-style throttle)
├── agent-tasks/                      # PERSISTENT — survives across sprints
│   ├── agent-tasks.md                # Current backlog (append at bottom, consume from top)
│   └── completed-tasks.md            # Append-only log of finished tasks
└── sprints/                          # EPHEMERAL — one subdirectory per sprint
    ├── s0/
    │   ├── sprint-meta.md
    │   ├── sprint-research/
    │   │   ├── research-report.md
    │   │   └── [artifacts]
    │   ├── sprint-plans/
    │   │   ├── build-plan.md         # Locked after Plan Phase
    │   │   └── test-plan.md          # Locked after Plan Phase
    │   └── sprint-tests/
    │       ├── unit-tests.md
    │       ├── integration-tests.md
    │       ├── e2e-tests.md
    │       └── test-report.md
    ├── s1/
    └── sN/
```

### Why Two State Surfaces

- **`sprints/sN/`** is *working memory* — what this sprint is doing, ephemeral, never modified after the sprint closes.
- **`agent-tasks/`** is *long-term memory* — what has ever been done, what is still pending, persistent across all sprints.

Conflating these is the most common failure mode in agentic workflows. The filesystem IS the state machine. Trust the disk.

### Phase Exit Conditions (Quick Reference)

| Phase | Exit artifact | Exit condition |
|-------|--------------|----------------|
| Initialize | All directories + files exist, `sprint-meta.md` populated | Filesystem matches schema |
| Research | `research-report.md` with all 5 sections | Report complete, artifacts referenced |
| Plan | `build-plan.md` + `test-plan.md` both finalized | Both files prepended with `Finalized - DO NOT EDIT` |
| Build | All tasks in `agent-tasks.md` for this sprint completed or blocked | Git commits exist for each completed task |
| Test | `test-report.md` written (or `failure-report.md`) | All tests run, CI green or failure documented |
| Loop | `sprint-meta.md` finalized, git tree clean | Ready to invoke Initialize for sprint N+1 |

---

# Section 1: Open Harnesses

> For OpenClaw, local LLMs, custom runners, GECK, or any agent runtime that can read markdown files and execute shell commands.

This section is the **canonical, runtime-agnostic specification**. Everything else (Claude Code skill, Codex skill) is a thin adapter over this. Particles are delimited by `"quoted blocks"` so they can be embedded individually into Oovra or any vector store.

## Invocation Model

Open harnesses retrieve particles by semantic match. The agent's harness should:

1. Detect sprint-loop intent (user says "start a sprint", "continue the loop", etc.).
2. Run `current-phase.sh` (or equivalent) to inspect the filesystem and determine the active phase.
3. Retrieve the matching phase particle.
4. Inject it as a user-role or system-role message.
5. Execute. Loop.

## Particle: Loop Overview

> Inject first when a user invokes the sprint loop system.

```
"You have entered a Sprint Loop. You will work in numbered sprints. Each sprint is a five-phase sequence: Research → Plan → Build → Test → Loop. Each phase has its own particle with detailed instructions; retrieve the particle matching your current phase before acting. Do not skip phases. Do not merge phases. The current phase ends only when its exit artifact is written to disk. Determine your current phase by inspecting the filesystem: if no 'sprints/' directory exists, you are pre-initialization; if the latest sprint's 'research-report.md' is missing or empty, you are in Research; if research is complete but plans lack the 'Finalized - DO NOT EDIT' header, you are in Plan; if plans are finalized but 'agent-tasks.md' still contains incomplete tasks for the current sprint, you are in Build; if all build tasks are done but 'test-report.md' or 'failure-report.md' is missing, you are in Test; if both exist and 'sprint-meta.md' exit status is still 'in-progress', you are in Loop."
```

## Particle: Initialize Sprint

> Inject once at the start of every sprint, before Research.

```
"Initialize the current sprint's filesystem state. First, verify the existence of a 'sprints/' directory at the project root; create it if missing. Then determine the current sprint number: list all 'sN' subdirectories within 'sprints/', find the highest N, and add 1. If no 'sN' subdirectories exist, this is sprint 0. Create the new 'sprints/sN/' directory and within it create: 'sprint-research/' containing 'research-report.md'; 'sprint-plans/' containing 'build-plan.md' and 'test-plan.md'; 'sprint-tests/' containing 'unit-tests.md', 'integration-tests.md', 'e2e-tests.md', and 'test-report.md'. Also create 'sprint-meta.md' at 'sprints/sN/sprint-meta.md' populated with: sprint number, start timestamp (ISO 8601), model identifier, and exit status set to 'in-progress'. Next, at the project root, verify the existence of the 'agent-tasks/' directory containing 'agent-tasks.md' and 'completed-tasks.md'; create any that are missing as empty files. The 'agent-tasks/' directory is persistent and shared across all sprints. Finally, verify the existence of 'decisions.md' at the project root; create it as an empty file if missing. Once all directories and files exist, proceed to the Research Phase."
```

**Schema for `sprint-meta.md`:**

```markdown
# Sprint N Meta

- **Sprint number:** N
- **Start timestamp:** YYYY-MM-DDTHH:MM:SSZ
- **End timestamp:** (filled at Loop Phase)
- **Model:** (e.g., your model identifier)
- **Exit status:** in-progress | success | failed | aborted
- **Token count:** (filled at Loop Phase if observable)
- **Summary:** (one-line description of sprint goal, filled after Plan Phase)
```

## Particle: Research Phase

```
"You are in the Research Phase. Your goal is to produce a comprehensive 'research-report.md' in the current sprint's 'sprint-research/' directory. Operate within a budget: review at most 20 files from the existing codebase (prioritize files most relevant to the sprint goal), read at most 5 external sources (official documentation, Stack Overflow, GitHub issues, vendor docs), and spend at most 30 minutes of wall-clock equivalent effort. After hitting any budget limit, stop gathering and write the report. The report must contain: (1) a summary of the sprint goal in your own words, (2) a survey of relevant existing code with file paths and brief descriptions, (3) findings from external sources with URLs, (4) identified risks, unknowns, and dependencies, (5) a recommended approach with at least one alternative considered. You may save evidential artifacts — code snippets, error logs, screenshots, PDFs, downloaded docs — to the 'sprint-research/' directory alongside the report. Reference each artifact by filename within the report. Stop condition: 'research-report.md' is written, contains all five required sections, and references every external source and saved artifact. Then proceed to the Plan Phase."
```

**Schema for `research-report.md`:**

```markdown
# Sprint N Research Report

## 1. Sprint Goal
(One paragraph in agent's own words.)

## 2. Existing Code Survey
| File | Relevance | Notes |
|------|-----------|-------|
| path/to/file.rs | high | Owns the X invariant |

## 3. External Sources
- [Source Title](url) — relevance summary

## 4. Risks, Unknowns, Dependencies
- **Risk:** ...
- **Unknown:** ...
- **Dependency:** ...

## 5. Recommended Approach
Primary: ...
Alternative considered: ...
Rationale: ...

## Artifacts
- `snippet-01.rs` — sample implementation
- `error-trace.txt` — observed failure mode
```

## Particle: Plan Phase

```
"You are in the Plan Phase. Read 'sprint-research/research-report.md' from the current sprint as authoritative input. You will produce two artifacts in sequence: 'sprint-plans/build-plan.md' first, then 'sprint-plans/test-plan.md'. Both must follow the schemas defined in the Build Plan and Test Plan particles. Do not begin building. Do not edit any source files outside the plan documents. When both plans are complete and reviewed for local and global correctness, prepend the line 'Finalized - DO NOT EDIT' to the top of each, then update 'sprint-meta.md' with a one-line sprint summary and proceed to the Build Phase."
```

## Particle: Build Plan Schema

```
"To compose the build-plan, decompose the sprint goal into a schema tree. The root is the sprint goal. Each child node is a critical component. Each leaf is an elementary task. A task is elementary if and only if it can be completed in a single tool-call loop without re-reading the plan — concretely: it touches at most one logical concern, has a single observable success criterion, and produces a single coherent diff. Do not decompose below this granularity. After the tree is complete, linearize it into an execution sequence honoring dependencies — a task may only follow tasks it depends on. For each linearized task, record: a stable task ID (e.g., T-001), a one-sentence description, the files it will touch, its dependencies (by task ID), its success criterion, and any execution notes. Write all of this to 'build-plan.md' following the schema below. Review for local correctness (each task is well-formed) and global correctness (the sequence as a whole accomplishes the sprint goal) before finalizing."
```

**Schema for `build-plan.md`:**

```markdown
# Sprint N Build Plan

## Schema Tree
- Sprint Goal
  - Component A
    - T-001: ...
    - T-002: ...
  - Component B
    - T-003: ...

## Execution Sequence

### T-001: <one-sentence description>
- **Touches:** path/to/file.rs
- **Depends on:** (none) | T-XXX
- **Success criterion:** function `foo` exists, signature matches spec, compiles
- **Notes:** use existing `Bar` trait from `bar.rs`
```

## Particle: Test Plan Schema

```
"To compose the test-plan, walk the build-plan's execution sequence in order. For each elementary task, define the unit tests required: input, expected output, and any required stubs or mocks. For each component (parent node in the schema tree), define the integration tests covering interaction between its child tasks. Finally, if the current state of the build will permit End-to-End system testing after this sprint completes, define the E2E tests: full system invocations with mock-real input data, observable outputs, and pass/fail criteria. If E2E testing is not yet possible, state so explicitly and identify what future sprint will unlock it. Review for local correctness (each test is well-formed and runnable) and global correctness (the test suite as a whole verifies the sprint goal). Write to 'test-plan.md' following the schema below."
```

**Schema for `test-plan.md`:**

```markdown
# Sprint N Test Plan

## Unit Tests
### T-001 unit tests
- `test_foo_happy_path`: input X → output Y
- `test_foo_empty_input`: input ∅ → error E
- Stubs: `MockBar`

## Integration Tests
### Component A integration
- `test_component_a_pipeline`: T-001 + T-002 composed → output Z

## End-to-End Tests
- **Status:** possible | not-yet-possible
- (if possible) `test_full_workflow`: ...
- (if not) Unlocked by: sprint N+K when component C exists
```

## Particle: Build Phase

```
"You are in the Build Phase. The current sprint's 'build-plan.md' is finalized and must not be edited. Read it as authoritative input. Open 'agent-tasks/agent-tasks.md'. Append each task from the build-plan's execution sequence to the bottom of 'agent-tasks.md' in the order given, preserving task IDs and descriptions. Tasks are consumed from the top of 'agent-tasks.md' — never reorder them based on preference. Execute tasks in order. Deviate only when a task is genuinely blocked by a missing dependency that the plan did not anticipate; in that case, leave the blocking task in place, skip to the next executable task, and note the blockage in 'sprint-meta.md' under a 'blockages' section. For every task you complete: verify the success criterion is met, delete the task entry from 'agent-tasks.md', and append it to 'completed-tasks.md' with a completion timestamp and the file paths actually modified. After every task completion, run 'git add -A && git commit -m \"sprint-N: T-XXX <description>\"' to create a commit boundary. When all tasks in the current sprint's build-plan are either completed or documented as blocked, proceed to the Test Phase."
```

**Schema for `agent-tasks.md`:**

```markdown
# Agent Tasks (Persistent Backlog)

- [ ] T-001 (sprint N): <description> — touches: <files>
- [ ] T-002 (sprint N): <description> — touches: <files>
```

**Schema for `completed-tasks.md`:**

```markdown
# Completed Tasks Log (Append-Only)

## T-001 (sprint N)
- **Description:** ...
- **Completed:** YYYY-MM-DDTHH:MM:SSZ
- **Files modified:** path/to/file.rs
- **Commit:** <git hash>
```

## Particle: Test Phase

```
"You are in the Test Phase. Read the current sprint's 'test-plan.md' as authoritative input. Implement and run all unit tests defined for tasks completed in this sprint's Build Phase; record results in 'sprint-tests/unit-tests.md'. Then implement and run all integration tests defined for components touched in this sprint; record results in 'sprint-tests/integration-tests.md'. If the test-plan marks E2E tests as possible, implement and run them; record results in 'sprint-tests/e2e-tests.md'. Otherwise, write 'Not yet possible — unlocked by sprint N+K' in that file. For any failing test, do not patch the symptom: identify the underlying cause. If the fix is small and local, apply it and re-run. If the fix requires re-architecture, stop testing, write a 'failure-report.md' to 'sprints/sN/' documenting the root cause and the work needed, mark 'sprint-meta.md' exit status as 'failed', and proceed to the Loop Phase — the next sprint will begin with that failure-report as its primary research input. Watch for successful completion of any CI/CD pipelines configured for the repo. When all tests pass and CI is green, write a summary to 'sprint-tests/test-report.md' covering: tests run, tests passed, tests failed, coverage observations, and any technical debt identified. Then proceed to the Loop Phase."
```

**Schema for `test-report.md`:**

```markdown
# Sprint N Test Report

## Summary
- Unit tests: P passed / F failed / T total
- Integration tests: P passed / F failed / T total
- E2E tests: P passed / F failed / T total (or N/A)
- CI status: green | red | not-configured

## Failures
(If any — root cause analysis, not just symptom description)

## Technical Debt Identified
## Coverage Observations
```

## Particle: Loop Phase

```
"You are in the Loop Phase. First, update 'sprint-meta.md' for the current sprint: set the end timestamp (ISO 8601), record the token count if observable, and set the exit status to 'success' if all tests passed or 'failed' if a failure-report was written. Second, compact context: do NOT re-inject prior sprint research, plans, or completed-task logs into your working context unless they are explicitly needed for the next sprint's research. The persistent state lives on disk; trust it. Third, if any architectural decisions were made during this sprint that future sprints will need to understand, append a brief entry to 'decisions.md' at the project root following the ADR-lite schema. Fourth, verify the git working tree is clean — if any uncommitted changes remain, commit them with a 'sprint-N: cleanup' message. Finally, return to the Initialize Sprint particle and begin sprint N+1."
```

**Schema for `decisions.md` entries:**

```markdown
## YYYY-MM-DD — <short title> (sprint N)
- **Context:** Why this decision needed to be made.
- **Decision:** What we chose.
- **Alternatives considered:** What we did not choose, and why.
- **Consequences:** What this commits us to going forward.
```

## Failure Semantics

When a sprint fails (test phase produces irrecoverable failures requiring re-architecture):

1. Test Phase writes `sprints/sN/failure-report.md`.
2. `sprint-meta.md` exit status is set to `failed`.
3. Loop Phase still runs — closes out the failed sprint cleanly.
4. The next sprint's Research Phase begins by reading the prior `failure-report.md` as its primary input.
5. Sprint numbering does not reset. A failed sprint still counts.

**Schema for `failure-report.md`:**

```markdown
# Sprint N Failure Report

## What Failed
Specific tests, components, or invariants that broke.

## Root Cause
Underlying cause — not symptoms.

## Required Re-architecture
What the next sprint needs to do differently.

## State at Failure
- Completed tasks before failure: T-001, T-002
- Task in progress at failure: T-003
- Tasks not started: T-004, T-005
```

## Confidence Throttle (Optional)

Track a `confidence` scalar across sprints. Initialize at 1.0. After each sprint:

- All tests pass → `confidence = min(1.0, confidence + 0.1)`
- Any unit/integration failures patched in-sprint → `confidence -= 0.1`
- Failure-report written → `confidence -= 0.3`

Use confidence to gate sprint ambition: when `confidence < 0.5`, the next sprint's build-plan must have ≤ 5 elementary tasks. Mirrors covariance update in a Kalman filter — research is measurement, plan is prediction, build is state update, test is innovation, loop is covariance update.

Store in `project-root/confidence.txt` as a single float.

## Suggested Oovra / Particle Store Layout

```
sprint-loops/00-overview.md
sprint-loops/01-init-sprint.md
sprint-loops/02-research-phase.md
sprint-loops/03-plan-phase.md
sprint-loops/04-build-plan-schema.md
sprint-loops/05-test-plan-schema.md
sprint-loops/06-build-phase.md
sprint-loops/07-test-phase.md
sprint-loops/08-loop-phase.md
```

One particle per file. Each particle has a single semantic surface so embeddings stay tight and retrieval ranking stays clean.

## Reference Helper Scripts

These are optional but recommended. The agent shouldn't be counting sprint numbers when `bash` is right there.

**`scripts/current-sprint.sh`** — print the current sprint number:

```bash
#!/usr/bin/env bash
set -euo pipefail
if [ ! -d sprints ]; then echo "-1"; exit 0; fi
ls sprints/ 2>/dev/null | grep -E '^s[0-9]+$' | sed 's/^s//' | sort -n | tail -1 || echo "-1"
```

**`scripts/current-phase.sh`** — inspect filesystem and print active phase:

```bash
#!/usr/bin/env bash
set -euo pipefail
N=$(./scripts/current-sprint.sh)
if [ "$N" = "-1" ]; then echo "uninitialized"; exit 0; fi
D="sprints/s$N"
if [ ! -s "$D/sprint-research/research-report.md" ]; then echo "research"; exit 0; fi
if ! grep -q "Finalized - DO NOT EDIT" "$D/sprint-plans/build-plan.md" 2>/dev/null; then echo "plan"; exit 0; fi
if ! grep -q "Finalized - DO NOT EDIT" "$D/sprint-plans/test-plan.md" 2>/dev/null; then echo "plan"; exit 0; fi
if grep -q "sprint $N" agent-tasks/agent-tasks.md 2>/dev/null; then echo "build"; exit 0; fi
if [ ! -s "$D/sprint-tests/test-report.md" ] && [ ! -s "$D/failure-report.md" ]; then echo "test"; exit 0; fi
if ! grep -q "Exit status:.*\(success\|failed\|aborted\)" "$D/sprint-meta.md" 2>/dev/null; then echo "loop"; exit 0; fi
echo "ready-for-next-sprint"
```

**`scripts/commit-task.sh <task-id> <description>`** — commit a completed task:

```bash
#!/usr/bin/env bash
set -euo pipefail
N=$(./scripts/current-sprint.sh)
git add -A
git commit -m "sprint-$N: $1 $2"
```

---

# Section 2: Claude Code

> For Anthropic's Claude Code, using the native skills system.

## Why a Skill, Not a Prompt

A loop prompt is always loaded — every session pays the token cost whether you're sprinting or not. A skill is conditionally invoked via its description, so it only enters context when relevant. Skills also support subordinate files and bash helpers, which matches the per-phase particle model exactly.

## Installation

```bash
mkdir -p ~/.claude/skills/sprint-loops
cd ~/.claude/skills/sprint-loops
# Drop the files below in place
```

Or for project-scoped installation:

```bash
mkdir -p .claude/skills/sprint-loops
```

## Skill Directory Layout

```
~/.claude/skills/sprint-loops/
├── SKILL.md                          # Description + routing
├── phases/
│   ├── 00-overview.md
│   ├── 01-init-sprint.md
│   ├── 02-research-phase.md
│   ├── 03-plan-phase.md
│   ├── 04-build-phase.md
│   ├── 05-test-phase.md
│   └── 06-loop-phase.md
├── schemas/
│   ├── sprint-meta.md
│   ├── research-report.md
│   ├── build-plan.md
│   ├── test-plan.md
│   ├── agent-tasks.md
│   ├── completed-tasks.md
│   ├── test-report.md
│   ├── failure-report.md
│   └── decisions.md
└── scripts/
    ├── current-sprint.sh
    ├── current-phase.sh
    ├── init-sprint.sh
    ├── commit-task.sh
    ├── finalize-plan.sh
    └── update-confidence.sh
```

## `SKILL.md`

```markdown
---
name: sprint-loops
description: Structured five-phase workflow (Research → Plan → Build → Test → Loop) for long-horizon coding tasks. Use when the user asks to start a sprint, continue a sprint loop, run an iteration, work in numbered sprints, or invokes phrases like "sprint loop", "start a sprint", "continue the loop", or "next sprint". Also use when a project root contains a `sprints/` directory and the user asks to resume work.
---

# Sprint Loops

You are working in a Sprint Loop. Each sprint is a five-phase sequence with persistent state on disk.

## Routing

1. Run `scripts/current-phase.sh` to determine the active phase.
2. Read the corresponding file from `phases/`:
   - `uninitialized` → `phases/01-init-sprint.md`
   - `research` → `phases/02-research-phase.md`
   - `plan` → `phases/03-plan-phase.md`
   - `build` → `phases/04-build-phase.md`
   - `test` → `phases/05-test-phase.md`
   - `loop` → `phases/06-loop-phase.md`
   - `ready-for-next-sprint` → `phases/01-init-sprint.md`
3. Execute the instructions in that phase file. When the phase exit condition is met, re-run step 1.

## Authoritative inputs

- `phases/00-overview.md` — read first if this is your first interaction with the skill in this session.
- `schemas/` — read the relevant schema file when producing any artifact.
- The filesystem IS the state machine. Trust the disk.

## Plan mode

During the Plan Phase, engage plan mode and use maximum effort. The Plan Phase produces two artifacts (`build-plan.md` and `test-plan.md`); do not touch source files.

## Git discipline

Every completed task in the Build Phase ends with a git commit via `scripts/commit-task.sh`. Loop Phase verifies a clean working tree before incrementing the sprint number.
```

## Slash Command Wrappers (Optional)

Add to `~/.claude/commands/` (or project-level `.claude/commands/`):

**`~/.claude/commands/sprint.md`:**

````markdown
---
description: Sprint Loops control — start, continue, loop, or abort a sprint.
---

Invoke the sprint-loops skill. Arguments: $ARGUMENTS

If no arguments: run `scripts/current-phase.sh` and continue from wherever the project is.
If `start <goal>`: initialize a new sprint with the goal `$ARGUMENTS`.
If `loop`: jump to the Loop Phase.
If `abort`: mark current sprint as aborted in `sprint-meta.md` and close it out.
````

Usage: `/sprint start "add JWT refresh tokens"`, `/sprint continue`, `/sprint loop`, `/sprint abort`.

## Phase Files

Each file in `phases/` contains the corresponding particle from Section 1, lightly adapted:

- **`phases/00-overview.md`** — the Loop Overview particle
- **`phases/01-init-sprint.md`** — the Initialize Sprint particle, with a final line: "When complete, read `phases/02-research-phase.md`."
- **`phases/02-research-phase.md`** — the Research particle, with a final line: "When complete, read `phases/03-plan-phase.md`."
- **`phases/03-plan-phase.md`** — the Plan particle, plus: "Engage plan mode now. Use maximum effort. Read `schemas/build-plan.md` and `schemas/test-plan.md` for output format. When both plans are finalized, read `phases/04-build-phase.md`."
- **`phases/04-build-phase.md`** — the Build particle, with `scripts/commit-task.sh` as the commit mechanism.
- **`phases/05-test-phase.md`** — the Test particle.
- **`phases/06-loop-phase.md`** — the Loop particle.

## Why This Works Better in Claude Code

- **Skill discovery is automatic** — the description triggers when sprint-loop intent is detected.
- **Phase files are lazy-loaded** — only the active phase enters context.
- **Bash helpers do the deterministic work** — sprint numbering, phase detection, git commits. LLMs are bad at counting `s0, s1, s2`; shell scripts aren't.
- **Plan mode is engaged at the right moment** — only during the Plan Phase, not always.

---

# Section 3: Codex CLI

> For OpenAI's Codex CLI, using its skills system and `AGENTS.md`.

## Codex-Specific Considerations

Codex CLI has its own conventions worth respecting:

- **Skills are the supported primitive** for reusable instruction bundles (custom prompts are deprecated as of 2026).
- **`AGENTS.md`** is the equivalent of `CLAUDE.md` and is loaded once per session at startup.
- **`/plan` slash command** gives you plan mode natively.
- **`--ask-for-approval`** flag controls autonomy — relevant for Build Phase commit semantics.
- **`codex exec`** is the non-interactive runner — useful for CI-driven sprint loops.
- **Subagents** can parallelize independent tasks within a Build Phase.

## Installation

Skills live in your Codex home directory (defaults to `~/.codex/`):

```bash
mkdir -p ~/.codex/skills/sprint-loops
```

For project-scoped use, Codex also reads from `.codex/` at the project root, but project-scoped configs require the project to be trusted.

## Skill Directory Layout

Same structure as Claude Code, with one extra file (the AGENTS.md fragment for project integration):

```
~/.codex/skills/sprint-loops/
├── SKILL.md                          # Codex skill metadata + routing
├── AGENTS.md.fragment                # Drop-in fragment for project AGENTS.md
├── phases/
│   ├── 00-overview.md
│   ├── 01-init-sprint.md
│   ├── 02-research-phase.md
│   ├── 03-plan-phase.md
│   ├── 04-build-phase.md
│   ├── 05-test-phase.md
│   └── 06-loop-phase.md
├── schemas/
│   └── [same as Claude Code section]
└── scripts/
    └── [same as Claude Code section]
```

## `SKILL.md` (Codex variant)

````markdown
---
name: sprint-loops
description: Structured five-phase workflow (Research → Plan → Build → Test → Loop) for long-horizon coding tasks. Trigger when the user mentions sprint loops, starting a sprint, continuing a sprint, or when the project root contains a `sprints/` directory.
---

# Sprint Loops

Five-phase workflow for long-horizon agentic coding work.

## Routing

1. Run `bash scripts/current-phase.sh` from the project root.
2. Read the matching `phases/` file:
   - `uninitialized` or `ready-for-next-sprint` → `phases/01-init-sprint.md`
   - `research` → `phases/02-research-phase.md`
   - `plan` → `phases/03-plan-phase.md` (also invoke `/plan` slash command)
   - `build` → `phases/04-build-phase.md`
   - `test` → `phases/05-test-phase.md`
   - `loop` → `phases/06-loop-phase.md`
3. Execute. When the phase exit condition is met, re-route.

## Plan mode integration

When entering the Plan Phase, suggest the user run `/plan` for native Codex plan mode. The plan-phase file's job is to produce `build-plan.md` and `test-plan.md` — these are the planning artifacts that survive across turns.

## Approval mode guidance

- **Research, Plan, Loop** phases work fine with `--ask-for-approval on-request` (default).
- **Build Phase** benefits from `workspace-write` sandbox + `--ask-for-approval never` for batch task execution, since every task ends in a git commit that provides rollback.
- **Test Phase** can run with `workspace-write` + `on-request` for safety.

Never use `--yolo` or `--dangerously-bypass-approvals-and-sandbox` for sprint loops — the whole point of the system is auditable, recoverable iteration.

## State on disk

The filesystem IS the state machine. Persistent state lives in `sprints/` and `agent-tasks/`. Trust the disk; do not re-derive state from chat history.

## Subagent opportunity

When the Build Phase has multiple independent tasks (no shared dependencies in the build-plan's execution sequence), consider spawning subagents for parallelization. Each subagent handles one task and commits its own diff. The parent agent merges results and proceeds.
````

## `AGENTS.md.fragment`

Drop this into your project's `AGENTS.md` to tell Codex the project uses Sprint Loops:

```markdown
## Sprint Loops

This project uses the Sprint Loops workflow. Work is organized into numbered sprints under `sprints/sN/`, with a persistent backlog in `agent-tasks/`.

When asked to start, continue, or work on a sprint:
1. Invoke the `sprint-loops` skill.
2. Run `bash scripts/current-phase.sh` to determine the active phase.
3. Follow the phase instructions in `<skill-root>/phases/`.

Do not bypass the workflow. Do not edit `build-plan.md` or `test-plan.md` after they contain the `Finalized - DO NOT EDIT` header. Every Build-Phase task ends in a git commit.
```

## Non-Interactive Mode (CI / Automation)

Codex's `codex exec` makes Sprint Loops scriptable in CI:

```bash
# Run a single sprint end-to-end in CI
codex exec --ask-for-approval on-request \
  --sandbox workspace-write \
  "Continue the sprint loop. Use the sprint-loops skill. Run until the current sprint reaches the Loop Phase, then stop."
```

This is genuinely useful for nightly autonomous iteration on long-running projects — kick off a sprint at midnight, wake up to either a clean test report or a failure-report you can read with your coffee.

## Hooks Integration (Optional)

Codex supports lifecycle hooks. You can wire `agent-turn-complete` to fire a notification when a sprint phase completes:

```toml
# ~/.codex/config.toml
notify = ["sh", "-c", "if grep -q 'success' sprints/s$(./scripts/current-sprint.sh)/sprint-meta.md 2>/dev/null; then osascript -e 'display notification \"Sprint complete\" with title \"Sprint Loops\"'; fi"]
```

## Why This Works in Codex

- **Skills are the right primitive** — same reasoning as Claude Code, plus Codex specifically deprecated custom prompts in favor of skills.
- **`AGENTS.md` integration** — projects self-describe as Sprint-Loops-enabled.
- **`codex exec`** enables autonomous overnight sprints.
- **Approval modes map cleanly** to phase semantics — Build Phase wants more autonomy, other phases want more oversight.
- **Subagent support** is genuinely useful for parallelizable Build Phases.

---

## Cross-Harness Compatibility

A repo using Sprint Loops can be worked on by any of the three harnesses interchangeably. The filesystem state is the contract:

- `sprints/sN/` and `agent-tasks/` mean the same thing everywhere.
- Phase files are content-identical across harnesses (only the routing layer differs).
- `decisions.md` and `confidence.txt` are universal.
- Git history is the source of truth for what actually happened.

This means you can start a sprint on Claude Code at your desk, continue it on Codex in a CI run overnight, and resume it on an OpenClaw node the next morning — without any state translation. The project itself is the protocol.

## License and Distribution

Suggested: MIT or Apache-2.0 for the protocol spec and reference scripts. The skill bundles can ship as separate releases targeted at each harness:

- `sprint-loops-protocol` — the spec, schemas, and reference shell scripts (this document, plus `scripts/`).
- `sprint-loops-claude-code` — drop-in `~/.claude/skills/sprint-loops/` bundle.
- `sprint-loops-codex` — drop-in `~/.codex/skills/sprint-loops/` bundle.
- `sprint-loops-particles` — Oovra-ready individual `.md` particles.

GitHub release strategy: one repo, three install paths in the README, with the protocol as the canonical reference. If folded into GECK, "GECK Loops" becomes a fourth section here — the GECK adapter — without changing anything in the first three.
