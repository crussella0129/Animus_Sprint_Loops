# Sprint Loops for Open Harnesses

Use this distribution with OpenClaw, OpenCode, local models, custom runners,
GECK, or any runtime that can retrieve Markdown and execute shell commands.

`open-harnesses/` is the runtime-neutral distribution and physical shared-copy
reference for Sprint Loops scripts, schemas, and prompts. That maintenance role
does not make this directory—or any vendor adapter—the semantic owner of the
protocol. In a target project, the canonical Project Book schema v2 is rooted
at `docs/`.

Read the protocol from linked assets instead of reproducing it here:

- [Book overview and authority order](particles/00-overview.md)
- [intent lifecycle and evidence schema](schemas/intent.md)
- [repository-level harness guidance](../README.md)

## Install the helpers

From this repository, install the deterministic helpers into an existing
project:

```bash
bash open-harnesses/install.sh /path/to/project
```

Omit the target argument to use the current directory. The installer replaces
the target's entire `scripts/` directory with this bundle's helper directory,
then marks the shell files executable. Use it only when `scripts/` is dedicated
to Sprint Loops; otherwise package the helpers at a runtime-specific location
and resolve that location explicitly in your harness.

Run installed helpers with the target project root as the working directory:

```bash
bash scripts/current-phase.sh
```

## Index and retrieve particles

Index the Markdown files under [`particles/`](particles/) as individually
retrievable prompt units. Keep their filenames as stable retrieval keys. Make
[`schemas/`](schemas/) and [`prompts/`](prompts/) available by exact path so a
retrieved phase can request its output contract or critic.

Retrieve [`00-overview.md`](particles/00-overview.md) when a user directly
starts or resumes Sprint Loops. After that, use `current-phase.sh` output—not
chat memory or directory presence—to retrieve one phase particle. During Plan,
`03-plan-phase.md` explicitly composes the build and test plans with
`04-build-plan-schema.md` and `05-test-plan-schema.md` before routing to Build.

## Invocation and routing

Wire the following loop into the host runtime:

1. Activate only for direct sprint-loop intent.
2. Resolve the target project root and the installed helper location.
3. Run `current-phase.sh` from the project root.
4. Retrieve and inject the matching particle.
5. Execute until its evidence exit, then re-run the helper.

| Router output | Particle |
| --- | --- |
| `uninitialized` | [`01-init-sprint.md`](particles/01-init-sprint.md) |
| `research` | [`02-research-phase.md`](particles/02-research-phase.md) |
| `plan` | [`03-plan-phase.md`](particles/03-plan-phase.md), then [`04-build-plan-schema.md`](particles/04-build-plan-schema.md) and [`05-test-plan-schema.md`](particles/05-test-plan-schema.md) |
| `build` | [`06-build-phase.md`](particles/06-build-phase.md) |
| `test` | [`07-test-phase.md`](particles/07-test-phase.md) |
| `loop` | [`08-loop-phase.md`](particles/08-loop-phase.md) |
| `ready-for-next-sprint` | [`01-init-sprint.md`](particles/01-init-sprint.md) |

If the router reports legacy-only or split-brain state, surface its diagnostic
and migration guidance instead of choosing a phase or creating another writable
layout.

## Host-runtime boundary

The host decides how particles are injected, how tools are exposed, and whether
recurrence exists. Those orchestration choices do not change Book authority,
bypass evidence gates, or grant remote-operation permission. Persist durable
intent and state in the Project Book so another harness can resume from
`docs/` alone.
