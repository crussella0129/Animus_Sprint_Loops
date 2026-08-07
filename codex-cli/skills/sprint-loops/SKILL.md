---
name: sprint-loops
description: Run or resume the Sprint Loops Book v2 workflow when the user explicitly invokes $sprint-loops or directly asks to start, continue, resume, or run a sprint loop. Do not use it for ordinary documentation work or merely because a docs directory exists.
---

# Sprint Loops for Codex

This file is the Codex adapter and router. The selected phase file owns the
phase contract; the Project Book owns durable project meaning and state.

## Activation

Honor the frontmatter boundary. A Book marker may confirm a direct resume
request, but filesystem or documentation presence is never an activation
signal by itself.

## Resolve roots

- `<skill-root>` is the directory containing this loaded `SKILL.md`. Resolve
  it from the skill path Codex supplied, and quote it in every command.
- `<project-root>` is the repository or workspace root for the target project.
  If Codex started in a nested Git directory, use the Git top level. For a
  non-Git project, use the active workspace root. Do not treat `<skill-root>`
  as the project.

Resolve both once. If multiple target projects make `<project-root>` ambiguous,
ask before writing.

## Route

From `<project-root>`, run:

```bash
bash "<skill-root>/scripts/current-phase.sh"
```

Load only the matching phase contract:

- `uninitialized` or `ready-for-next-sprint` → `phases/01-init-sprint.md`
- `research` → `phases/02-research-phase.md`
- `plan` → `phases/03-plan-phase.md`
- `build` → `phases/04-build-phase.md`
- `test` → `phases/05-test-phase.md`
- `loop` → `phases/06-loop-phase.md`

Read `phases/00-overview.md` only when the Book contract or a layout diagnostic
needs interpretation. A legacy/conflict diagnostic must be resolved through
the overview and migration helper; never create a second writable state tree.
After satisfying a phase's Exit evidence, re-run the router from
`<project-root>`. Stop at the boundary the user requested.

## Authority and collaboration

Local work remains bounded by the user's request, the active phase, and the
Book's intent authority. Never change Codex sandbox, approval, or permission
settings to make a phase proceed; surface an unavailable capability instead.

Push, merge, release, force-push, delete, and material scope expansion require an explicit request or a declared preauthorized-remote profile. The remote profile is declared per `schemas/remote-profile.md` and drives the one-PR/MR-per-sprint `work -> base` checkpoint (human-approve by default); the substrate gate `scripts/check-substrate.sh` establishes and verifies it, and the skill creates no per-sprint branch.

Use subagents for bounded, disjoint read/review work; keep one integrating writer in a shared workspace. Parallel writers require explicit isolated worktrees.
