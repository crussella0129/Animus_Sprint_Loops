# Sprint 2 Research Report

## 1. Sprint Goal

Close two of sprint 1's flagged follow-ups plus the install-hygiene concern
surfaced by the user this turn: (a) add an idempotent `install.sh` per
distributable bundle so re-installing or renaming never leaves stale copies
behind, and (b) make `finalize-plan.sh` refuse to lock a build-plan with zero
`T-XXX` execution entries (the empty-plan failure mode flagged in sprint 0's
decisions and sprint 1's test report). Sync changes across all three bundles
and extend `selftest.sh` accordingly.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| `open-harnesses/scripts/finalize-plan.sh` | **high** | 20-line helper; today it requires only that both plan files are non-empty. An empty execution sequence would still lock; the protocol would then route `build` → no tasks ever queue → infinite loop on `build`. |
| `open-harnesses/schemas/build-plan.md` | high | Defines the canonical execution-sequence task header: `### T-001: <one-sentence description>`. The empty-plan check should grep for `^### T-[0-9]+:` (matches at least one such header). |
| `open-harnesses/scripts/selftest.sh` | high | Today's selftest uses an arbitrary string for `build-plan.md` (`echo "build content"`), which is fine for pre-finalize but doesn't carry a `### T-XXX:` header. The empty-plan check would BREAK the existing selftest unless updated. |
| `claude-code/README.md`, `codex-cli/README.md`, `open-harnesses/README.md` | medium | Each currently documents a multi-step manual install (`cp -r ...`, `cp ...`, `chmod +x ...`). `install.sh` per bundle reduces this to one command and makes it idempotent — wipes any prior install at the target path before copying. |
| (none today) `install.sh` per bundle | high | Three new files: `claude-code/install.sh` (handles `~/.claude/skills/sprint-loop/` + `~/.claude/commands/sprint-loop.md`), `codex-cli/install.sh` (handles `~/.codex/skills/sprint-loops/`), `open-harnesses/install.sh` (copies `scripts/` to a target project root). Each per-bundle so the "each subdirectory is a complete atomic unit" principle (decisions.md sprint 0) holds. |
| `sprints/s1/sprint-tests/test-report.md` | high | Source of the empty-build-plan and CI follow-ups. |

## 3. External Sources

None. All work is internal to the protocol and helpers; the budget permits up
to 5 external sources and 0 were needed.

## 4. Risks, Unknowns, Dependencies

- **Risk:** *Empty-plan check rejects in-progress plans.* During Plan Phase the
  agent might run `finalize-plan.sh` before adding `T-XXX` entries by accident.
  The script will refuse with a clear message — that's the right behavior, not
  a regression.
- **Risk:** *Existing `selftest.sh` step 04 breaks.* The selftest writes `"build content"` into `build-plan.md` (no `T-XXX` header) and then calls `finalize-plan.sh`. With the new check active, finalize would refuse → step 04 fails. **Fix in T-002 itself**: update the selftest's build-plan content to include a `### T-001: demo` header. The selftest test for empty-plan rejection becomes a NEW selftest step exercising the negative path.
- **Risk:** *Install scripts on non-bash systems.* Windows users without git-bash can't run `install.sh`. Mitigation: README install snippets remain valid; `install.sh` is an additive convenience, not the only path.
- **Unknown:** *Whether to keep the documented manual `cp -r` install in the READMEs.* Recommendation: keep it (it's the explicit fallback) but mention `install.sh` as the recommended path.
- **Dependency:** `bash`, `cp`, `rm`, `chmod` (`mkdir -p`). Already required.

## 5. Recommended Approach

**Primary:** Three elementary build tasks.

1. *Empty-build-plan check in `finalize-plan.sh`.* When finalizing
   `build-plan.md`, additionally require at least one `^### T-[0-9]+:` line.
   Refuse with a clear error otherwise. Update `selftest.sh` so step 04's
   simulated plan contains `### T-001: demo`, AND add a new selftest step
   asserting that an empty plan IS rejected.
2. *Idempotent `install.sh` per bundle.* Three new scripts:
   - `claude-code/install.sh` — wipes `~/.claude/skills/sprint-loop/` and `~/.claude/commands/sprint-loop.md` if present, then copies the skill + command; supports `--project` flag for `.claude/` relative to cwd.
   - `codex-cli/install.sh` — same pattern for `~/.codex/skills/sprint-loops/`.
   - `open-harnesses/install.sh` — copies `scripts/` into a target project root (default: cwd), wiping the prior `scripts/` if present.
   Each script announces what it removed and what it installed.
3. *Sync* — propagate `finalize-plan.sh` and `selftest.sh` updates to both skill
   bundles; verify md5 identity; both bundles' selftests run with the updated
   step count.

**Alternatives considered:**

- *One universal `install.sh` at repo root with `--target` flags.* Rejected: breaks the "each subdirectory is a complete atomic unit" principle from sprint 0's decisions ADR. A single repo-root script implies the bundles depend on its presence.
- *Add CI now (GitHub Actions running `selftest.sh` on push).* Deferred to sprint 3. CI adds external surface (workflow file, runner concerns, matrix across bundles) that warrants its own sprint.
- *Address `abort-sprint.sh` no-git fallback now.* Deferred — lower priority per sprint 1's test report; every protocol-compliant project root IS a git repo.

**Rationale:** Two concrete improvements that close real flagged debt. The
install scripts answer this turn's user pain forward (any future rename
collapses to `bash install.sh`). The empty-plan check eliminates the
infinite-build-loop failure mode flagged twice now. Both are testable, both
sync cleanly, and together they require ~4 file additions/edits — proportional
to a sprint.
