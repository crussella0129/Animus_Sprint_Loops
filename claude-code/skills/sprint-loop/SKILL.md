---
name: sprint-loop
description: Run or resume the Sprint Loops Book v2 workflow when the user explicitly invokes /sprint-loop or directly asks to start, continue, resume, or run a sprint loop. Do not use it for ordinary documentation work or merely because a docs directory exists.
argument-hint: "[ continue | start <goal> | abort <reason> ]"
---

# Sprint Loops for Claude Code

This adapter activates and routes the shared Sprint Loops workflow. The
selected phase file owns its phase contract; the Project Book owns durable
project meaning and state.

## Activation

Honor the frontmatter boundary. A Book marker may confirm a direct resume
request, but filesystem or documentation presence is never an activation
signal by itself.

## Resolve roots

- `${CLAUDE_SKILL_DIR}` is the absolute directory of this loaded skill.
  Require it, and quote every bundled path resolved beneath it.
- `<project-root>` is the target repository's Git top level or, outside Git,
  the active workspace root. Never treat the skill directory as the project.

Resolve both once. If the target project is ambiguous, ask before writing.
Run every helper with `<project-root>` as the working directory.

## Arguments

The invocation arguments are `$ARGUMENTS`.

- No argument or `continue` resumes the state reported by the router.
- `start <goal>` retains `<goal>` as the requested sprint objective. It may
  initialize only when the router reports `uninitialized` or
  `ready-for-next-sprint`; resume or explicitly abort an active sprint first.
- `abort <reason>` invokes
  `bash "${CLAUDE_SKILL_DIR}/scripts/abort-sprint.sh" "<reason>"`. Require one
  non-empty, one-line reason.
- Any other argument is unsupported. Never use an argument to jump directly
  to a phase.

## Route

From `<project-root>`, run:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/current-phase.sh"
```

Load only the matching contract:

- `uninitialized` or `ready-for-next-sprint` →
  `${CLAUDE_SKILL_DIR}/phases/01-init-sprint.md`
- `research` → `${CLAUDE_SKILL_DIR}/phases/02-research-phase.md`
- `plan` → `${CLAUDE_SKILL_DIR}/phases/03-plan-phase.md`
- `build` → `${CLAUDE_SKILL_DIR}/phases/04-build-phase.md`
- `test` → `${CLAUDE_SKILL_DIR}/phases/05-test-phase.md`
- `loop` → `${CLAUDE_SKILL_DIR}/phases/06-loop-phase.md`

Read `${CLAUDE_SKILL_DIR}/phases/00-overview.md` only to interpret the Book
contract or a layout diagnostic. Resolve legacy-only state through
`${CLAUDE_SKILL_DIR}/scripts/migrate-to-book.sh`; never create a second
writable state tree. After satisfying Exit evidence, re-run the router and
stop at the boundary the user requested.

## Book and Claude Code authority

Book schema v2 keeps semantic intent in `docs/intents/`, work state in
`docs/work/`, sprint provenance in `docs/sprints/`, and navigation-only
views in `docs/SUMMARY.md`. The filesystem is the state machine; lower-
authority evidence cannot silently redefine intent.

`${CLAUDE_SKILL_DIR}/phases/03-plan-phase.md` owns Claude Code Plan Mode.
For session-scoped recurrence, the user may start
`/loop /sprint-loop continue`; each invocation routes from Book evidence,
and the user starts and stops recurrence. Plan Mode, plan approval,
auto-accept, and `/loop` affect orchestration only: none enlarges authority,
changes active permissions, bypasses a phase gate, or validates unverifiable
evidence. Do not weaken permission or security controls to keep a loop moving.

Push, merge, release, force-push, delete, and material scope expansion require an explicit request or a declared preauthorized-remote profile. The remote profile is declared per `schemas/remote-profile.md` and drives the one-PR/MR-per-sprint `work -> base` checkpoint (human-approve by default); the substrate gate `scripts/check-substrate.sh` establishes and verifies it, and the skill creates no per-sprint branch.
