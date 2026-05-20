Finalized - DO NOT EDIT

# Sprint 2 Build Plan

## Schema Tree
- Sprint Goal: idempotent install + empty-build-plan check, synced across all bundles
  - Component A: empty-build-plan rejection
    - T-001: `finalize-plan.sh` refuses to lock a `build-plan.md` with zero `### T-XXX:` entries; `selftest.sh` updated to (i) pass with a real task header and (ii) gain a new step asserting rejection of an empty plan
  - Component B: idempotent install scripts
    - T-002: add `claude-code/install.sh`, `codex-cli/install.sh`, and `open-harnesses/install.sh` — each wipes prior install at the target path then copies fresh
  - Component C: cross-bundle sync
    - T-003: sync the updated `finalize-plan.sh` and `selftest.sh` into both skill bundles; verify md5 identity; both bundles' selftests run green at the new step count

## Execution Sequence

### T-001: Add empty-build-plan rejection to `finalize-plan.sh` and update `selftest.sh`
- **Touches:** `open-harnesses/scripts/finalize-plan.sh`, `open-harnesses/scripts/selftest.sh`
- **Depends on:** (none)
- **Success criterion:** When `finalize-plan.sh` runs on a sprint whose
  `build-plan.md` has no `^### T-[0-9]+:` line, it exits non-zero with a clear
  message ("refusing to finalize build-plan.md: no `### T-XXX:` execution
  entries found") and leaves the file unchanged. When at least one such header
  exists, it locks both plans as today. `selftest.sh` is updated so its step
  04 plan content includes `### T-001: demo` (otherwise the existing pass-path
  regresses) AND adds a new step exercising the rejection path on a
  zero-task plan.
- **Notes:** Use `grep -qE '^### T-[0-9]+:'` for the check. The new selftest
  step should NOT exit the script on script-level `set -e` — it must catch
  finalize-plan.sh's non-zero exit and assert it. Use `if bash "$T/scripts/finalize-plan.sh"; then ...fail...; else ...pass...; fi`.

### T-002: Add idempotent `install.sh` per bundle
- **Touches:** `claude-code/install.sh` (new), `codex-cli/install.sh` (new), `open-harnesses/install.sh` (new)
- **Depends on:** (none)
- **Success criterion:** Three new executable shell scripts that:
  - `claude-code/install.sh [--project]`: wipes `~/.claude/skills/sprint-loop/` and `~/.claude/commands/sprint-loop.md` (or `.claude/...` under cwd with `--project`), then copies `skills/sprint-loop` and `commands/sprint-loop.md` to the target; `chmod +x` the scripts; prints what it removed and what it installed.
  - `codex-cli/install.sh [--project]`: same pattern for `~/.codex/skills/sprint-loops/`.
  - `open-harnesses/install.sh [target-dir]`: wipes `<target>/scripts/` if present, copies `scripts/` to it; default target = cwd.
  Running each script twice in a row yields the same end state (true idempotency); script output makes it clear when a prior install was removed.
- **Notes:** Each script begins by resolving `SCRIPT_DIR` via `BASH_SOURCE` (same pattern the helpers use), so `bash claude-code/install.sh` works from any cwd. None of the scripts should follow symlinks or delete outside the documented target. The three READMEs gain a "Recommended: `bash <bundle>/install.sh`" line next to the existing manual `cp` snippets (which stay as the explicit fallback).

### T-003: Sync the updated scripts into both skill bundles
- **Touches:** `claude-code/skills/sprint-loop/scripts/{finalize-plan.sh,selftest.sh}`, `codex-cli/skills/sprint-loops/scripts/{finalize-plan.sh,selftest.sh}`
- **Depends on:** T-001
- **Success criterion:** `md5sum` of `finalize-plan.sh` and `selftest.sh`
  identical across `open-harnesses/scripts/`, `claude-code/skills/sprint-loop/scripts/`, and `codex-cli/skills/sprint-loops/scripts/`. Both bundles' `selftest.sh` exits 0 and reports the new transition count (the existing 9 plus the new rejection step → 10).
- **Notes:** Re-assert exec bits after copies. The new `install.sh` files are
  per-bundle (not duplicated across bundles), so no script-sync needed for
  them — they ARE the deliverable, one per directory.
