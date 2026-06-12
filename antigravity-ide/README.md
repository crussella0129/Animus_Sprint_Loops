# Sprint Loops — Antigravity IDE

This directory provides the Sprint Loops skill specifically adapted for **Antigravity IDE**.

Sprint Loops decomposes long-horizon coding work into numbered sprints, each a five-phase sequence — **Research → Plan → Build → Test → Loop**. 

## The Translation Layer

Antigravity IDE has a highly-optimized native **Planning Mode** (`implementation_plan.md`, `task.md`, `walkthrough.md`). Instead of fighting this native engine, this skill acts as a **translation layer**:
1. It instructs the Antigravity agent to use its native planning mode and artifacts to do the actual thinking and execution.
2. It forces the agent to **sync** its output into the cross-harness Sprint Loops filesystem schema (`sprints/sN/`, `agent-tasks/`).

This means you get the best of both worlds: Antigravity's fluid native experience, and a filesystem "Rosetta Stone" that allows other agents (like Claude Code or Codex) to seamlessly pick up the same project.

## Installation

Antigravity IDE defines custom skills via "global workflows." To install this skill:

**On Windows:**
Run the provided PowerShell script to copy the global workflow definition to your Antigravity configuration directory:
```powershell
.\antigravity-ide\install.ps1
```

**On Mac/Linux:**
Manually copy the workflow file into your Antigravity global workflows directory:
```bash
mkdir -p ~/.gemini/config/global_workflows
cp antigravity-ide/global_workflows/sprint-loops.md ~/.gemini/config/global_workflows/
```

## Usage: Step-by-Step

In any project running Sprint Loops (or a new project), follow these steps to execute a sprint natively in Antigravity:

### Step 1: Start the Sprint
Invoke the workflow with the slash command and your goal for the sprint.
> `/sprint-loops start working on feature X`

*Antigravity will inspect the filesystem, initialize `sprints/s0/` if needed, and enter the **Research** phase. It will conclude by creating a `research-report.md`.*

### Step 2: Approve the Plan
Once Research is complete, Antigravity enters the **Plan** phase and will present you with its native `implementation_plan.md` artifact.
1. Review the plan in the Antigravity UI.
2. Provide feedback or approve the plan.
*Upon approval, Antigravity will automatically **sync** this plan into `sprints/sN/sprint-plans/build-plan.md` and `test-plan.md` to ensure cross-harness compatibility.*

### Step 3: Let it Build
Antigravity will enter the **Build** phase and create a native `task.md` checklist.
*As it works through the tasks, it will commit the code per-task and sync the completed tasks into `agent-tasks/completed-tasks.md`.*

### Step 4: Testing & Wrap-up
Antigravity automatically moves into the **Test** phase to verify its work and write `test-report.md`. It will then conclude the sprint in the **Loop** phase by presenting a native `walkthrough.md` of what was accomplished and marking the `sprint-meta.md` as completed.

### Resuming Work
If you pause or close the IDE during a sprint, simply run:
> `/sprint-loops continue`

The agent will read the filesystem state, figure out exactly which phase it was in, and pick up right where it left off.
