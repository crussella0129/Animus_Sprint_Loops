# Sprint Loops for Claude Code

This directory ships the Claude Code adapter as one self-contained
`sprint-loop` skill. Projects keep their canonical Book v2 state under
`docs/`; the runtime-neutral contract lives in
[`phases/00-overview.md`](skills/sprint-loop/phases/00-overview.md), and the
intent lifecycle lives in
[`schemas/intent.md`](skills/sprint-loop/schemas/intent.md).

This README covers Claude-specific installation, invocation, Plan Mode,
recurrence, and troubleshooting. The
[`SKILL.md`](skills/sprint-loop/SKILL.md) router and phase files own runtime
behavior.

## Install as a plugin

Plugin installation is recommended because Claude Code manages the installed
copy and its scope. In Claude Code, add this repository's marketplace, install
the plugin, and reload active plugins:

```text
/plugin marketplace add crussella0129/Animus_Sprint_Loops
/plugin install sprint-loop@sprint-loops
/reload-plugins
```

The install view lets you choose user, project, or local scope. Plugin skills
are namespaced, so this installation is invoked explicitly as
`/sprint-loop:sprint-loop`.

To update the marketplace listing later, run:

```text
/plugin marketplace update sprint-loops
/reload-plugins
```

## Install as a standalone skill

Use the bundled Bash installer when the plugin system is unavailable. It
replaces only the selected `sprint-loop` skill directory with this checkout's
bundle.

User scope, available to local Claude Code sessions across projects:

```bash
bash claude-code/install.sh
# ~/.claude/skills/sprint-loop/
```

Project scope, run from the intended project root:

```bash
bash claude-code/install.sh --project
# ./.claude/skills/sprint-loop/
```

The installer makes the deterministic helper scripts executable. A standalone
installation is invoked explicitly as `/sprint-loop`. The helpers require
Bash at runtime.

## Remove duplicate entries

Choose one delivery method and scope for a project. A plugin-qualified
`/sprint-loop:sprint-loop` entry alongside an unqualified `/sprint-loop`
usually means both plugin and standalone copies are visible.

If keeping the plugin, remove only unwanted standalone or legacy copies from:

- `~/.claude/skills/sprint-loop/`
- `<project>/.claude/skills/sprint-loop/`
- `~/.claude/commands/sprint-loop.md`
- `<project>/.claude/commands/sprint-loop.md`

If keeping the standalone skill, uninstall `sprint-loop@sprint-loops` from
the relevant scope through the `/plugin` Installed view or:

```text
/plugin uninstall sprint-loop@sprint-loops
```

Do not edit Claude Code's plugin cache directly. After cleanup, run
`/reload-plugins` for plugin changes. Restart Claude Code if a top-level
`.claude/skills/` or `~/.claude/skills/` directory was first created after
the session began.

## Start, continue, or abort

Use the command matching the installation method:

| Action | Plugin installation | Standalone installation |
| --- | --- | --- |
| Start a sprint | `/sprint-loop:sprint-loop start "add JWT refresh tokens"` | `/sprint-loop start "add JWT refresh tokens"` |
| Continue from Book evidence | `/sprint-loop:sprint-loop continue` | `/sprint-loop continue` |
| Abort with a reason | `/sprint-loop:sprint-loop abort "dependency invalidated the sprint"` | `/sprint-loop abort "dependency invalidated the sprint"` |

The abort reason must be non-empty and fit on one line. You can also ask Claude
directly to start, continue, or resume a Sprint Loop. Ordinary documentation
work and the mere presence of `docs/` are not activation signals.

## Claude Code Plan Mode

Only the Plan phase uses Claude Code's native Plan Mode. It invokes
`EnterPlanMode` before composing the build and test plans and presents their
summary through `ExitPlanMode`; the user controls approval. Plan Mode,
approval choices, and auto-accept affect interaction only. They do not change
the Book contract, phase gates, permissions, or authority.

See the adapter-specific
[`03-plan-phase.md`](skills/sprint-loop/phases/03-plan-phase.md) for the exact
phase contract.

## Session-scoped recurrence

The user may start Claude Code's `/loop` around the explicit continue command:

```text
# Plugin installation
/loop /sprint-loop:sprint-loop continue

# Standalone installation
/loop /sprint-loop continue
```

Each recurrence re-routes from Book evidence on disk. The user starts and
stops `/loop`; the Sprint Loops skill does not schedule itself. Recurrence
does not bypass phase evidence or enlarge authority.

## Activation troubleshooting

1. **Confirm the command name.** Plugin skills use
   `/sprint-loop:sprint-loop`; standalone skills use `/sprint-loop`.
2. **For a plugin install, inspect `/plugin`.** Check the Installed and Errors
   views, update the `sprint-loops` marketplace if needed, then run
   `/reload-plugins`.
3. **For a standalone install, verify the entrypoint.** Confirm exactly one
   intended `SKILL.md` exists at
   `~/.claude/skills/sprint-loop/SKILL.md` or
   `<project>/.claude/skills/sprint-loop/SKILL.md`. Restart if the top-level
   skills directory was newly created during the current session.
4. **Use direct intent or the explicit command.** Documentation presence alone
   deliberately does not activate the skill.
5. **Run from the target project.** The helpers use the active project root as
   the Book root; launching against the wrong workspace routes the wrong state.

For Claude Code's current discovery and installation behavior, see the
official [skills documentation](https://code.claude.com/docs/en/slash-commands)
and [plugin documentation](https://code.claude.com/docs/en/discover-plugins).
