---
description: Sprint Loops control — start, continue, loop, or abort a sprint.
---

Invoke the sprint-loops skill. Arguments: $ARGUMENTS

If no arguments: run `scripts/current-phase.sh` and continue from wherever the project is.
If `start <goal>`: initialize a new sprint with the goal `$ARGUMENTS`.
If `loop`: jump to the Loop Phase.
If `abort`: mark current sprint as aborted in `sprint-meta.md` and close it out.
