---
name: sprint-loop
description: Provide the installed Book v2 scripts and schemas for the /sprint-loops Antigravity workflow. Use only while that workflow is active or when the user directly asks to run or resume a Sprint Loop; do not activate for ordinary documentation work.
---

# Sprint Loops runtime resources

This directory is the Antigravity workflow's `<skill-root>`. The installed
`global_workflows/sprint-loops.md` file owns adapter routing and native-artifact
synchronization; do not recreate a second protocol here.

When this skill is directly activated for explicit Sprint Loop intent, load the
corresponding installed `sprint-loops` global workflow and follow it with this
directory as `<skill-root>`. Run scripts from the target project root. Use
`schemas/` when authoring Book artifacts, and write durable state only to the
Book schema version 2 under the target project's `docs/` directory.
