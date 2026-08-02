# Sprint Loops for Antigravity IDE

This bundle adds the `/sprint-loops` workflow to Antigravity and packages the
runtime scripts and schemas that workflow resolves. In every target project,
`docs/` is the canonical Project Book schema v2; Antigravity's native
artifacts are review views over that Book.

Contract and adapter references:

- [Antigravity workflow](global_workflows/sprint-loops.md)
- [installed runtime skill entry](skills/sprint-loop/SKILL.md)
- [Book intent schema](skills/sprint-loop/schemas/intent.md)
- [shared Book overview](../open-harnesses/particles/00-overview.md)

## Install

### Transactional PowerShell install

From the repository root, run:

```powershell
pwsh -File .\antigravity-ide\install.ps1
```

The installer stages, validates, and activates both official Antigravity
surfaces as one recoverable transaction:

- `~/.gemini/config/global_workflows/sprint-loops.md`
- `~/.gemini/config/skills/sprint-loop/`

An existing pair is backed up before activation and restored if either new
surface fails to activate. Installs are serialized by a per-config lock. If an
incomplete rollback retains a recovery lock, inspect its `RECOVERY.txt` before
retrying.

Use `-ConfigRoot` to target a different Antigravity configuration root:

```powershell
pwsh -File .\antigravity-ide\install.ps1 -ConfigRoot 'D:\Antigravity\config'
```

The workflow and skill are placed beneath that root in `global_workflows/` and
`skills/sprint-loop/` respectively.

### Manual POSIX copy

For a first-time manual install on macOS, Linux, or another POSIX shell, copy
both surfaces:

```bash
ANTIGRAVITY_CONFIG="${HOME}/.gemini/config"
mkdir -p "${ANTIGRAVITY_CONFIG}/global_workflows"
mkdir -p "${ANTIGRAVITY_CONFIG}/skills/sprint-loop"
cp antigravity-ide/global_workflows/sprint-loops.md \
  "${ANTIGRAVITY_CONFIG}/global_workflows/sprint-loops.md"
cp -R antigravity-ide/skills/sprint-loop/. \
  "${ANTIGRAVITY_CONFIG}/skills/sprint-loop/"
chmod +x "${ANTIGRAVITY_CONFIG}/skills/sprint-loop/scripts/"*.sh
```

Manual copying is not transactional. Prefer the PowerShell installer for
upgrades when `pwsh` is available.

## Invoke

Reload Antigravity after installation if the workflow is not immediately
visible. Open the target project and invoke:

```text
/sprint-loops
```

State the sprint goal in the request. To resume later, invoke
`/sprint-loops continue`. The workflow resolves its installed runtime skill,
runs the Book phase router from the project root, and resumes from Book
evidence.

## Native artifact mapping

| Antigravity artifact | Project Book meaning |
| --- | --- |
| `implementation_plan.md` | Review view of unrealized intent and current sprint planning. Durable outcomes and rationale live in `docs/intents/`; executable plans live in `docs/sprints/sN/sprint-plans/`. |
| `task.md` | Review view of work state. Canonical task state lives in `docs/work/tasks.md` and `docs/work/completed-tasks.md`. |
| `walkthrough.md` | Review view of realization evidence. An intent becomes `realized` only after its Book chapter links completion plus code, test, or documentation evidence. |

These artifacts never become a second state store. Another supported harness
must be able to resume the project from `docs/` without Antigravity chat or
native artifacts.
