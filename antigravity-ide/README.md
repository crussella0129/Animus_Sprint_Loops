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

1. Copy `global_workflows/sprint-loops.md` into your Antigravity global workflows directory:
   - On Windows: `~\.gemini\config\global_workflows\sprint-loops.md`
   - On Mac/Linux: `~/.gemini/config/global_workflows/sprint-loops.md`

2. To do this automatically on Windows, run the provided script from the repository root (not implemented yet, just copy it manually for now, or use the provided powershell script if created).

## Usage

In any project running Sprint Loops (or a new project), just tell Antigravity:

> `/sprint-loops start working on feature X`

The agent will automatically map its actions to the five phases and keep the `sprints/` directory up to date!
