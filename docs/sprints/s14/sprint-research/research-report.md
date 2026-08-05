# Sprint 14 Research Report

## Decisions Reviewed

- **2026-05-19 — `current-phase.sh` build/test disambiguator uses `completed-tasks.md`** (sprint 0) — preserve the invariant that phase is derived from evidence, but move the evidence into the Book and version its schema.
- **2026-05-20 — `finalize-plan.sh` rejects empty build-plans + install per bundle** (sprint 2) — retain bundle atomicity and the empty-plan gate; installation paths and Codex guidance need updating.
- **2026-05-20 — Hard plan-mode primitive + EARS criteria + decisions-reviewed gate** (sprint 4) — retain EARS and architectural-drift protection, but revise the Codex `/plan` assumption and replace `decisions.md` review with Book-intent alignment.
- **2026-05-20 — Subagent fan-out: adversarial critic review at Plan + Test** (sprint 5) — retain critics, while changing Codex guidance to bounded read/review delegation with one integrating writer unless worktrees are isolated.
- **2026-05-21 — Auto-mode stop criterion = halt only for what AI cannot verify** (sprint 8) — preserve the stop criterion, but express remote writes and merges as requiring an explicitly authorized automation profile rather than deriving authority from local commit rollback.
- **2026-07-03 — Bundle parity is guarded, not deduplicated** (sprint 11) — preserve physical bundle atomicity and byte parity for the harness-neutral Book core; make Codex orchestration an intentional adapter divergence.
- **2026-07-04 — Scripts are BSD/macOS-portable** (sprint 12) — preserve POSIX portability and the macOS CI proof while changing paths and adding Book validation.
- **2026-07-04 — Critic protocol is structurally enforced** (sprint 13) — preserve the hard critique gates under Book paths.

This sprint intentionally revises the prior ADR model. `decisions.md` will cease to be an active authority: rationale, alternatives, consequences, and transition history will live with stable intent chapters in the project Book. Existing ADR content must be migrated losslessly into Book history rather than deleted. The filesystem remains the state machine, but its canonical state surface moves from scattered root artifacts to a versioned, validated Book under `docs/`.

## 1. Sprint Goal

Refactor Sprint Loops so a project's `docs/` directory becomes its authored Book: a human-readable guide and the canonical graph of project intent, including both realized behavior and unrealized work. Each intent receives a stable ID, lifecycle state, rationale, and evidence links to either plans/tasks or code/tests/commits. Move sprint and task artifacts beneath that Book, replace active ADRs with colocated intent history, provide a safe migration path, and refactor the Codex adapter into lean GPT-5.6-oriented guidance that respects current skill discovery, planning, subagent, permission, and shared-workspace behavior.

## 2. Existing Code Survey

| File | Relevance | Notes |
|------|-----------|-------|
| `decisions.md` | high | Active ADR authority that must become lossless Book history and colocated intent rationale. |
| `codex-cli/skills/sprint-loops/SKILL.md` | high | Duplicates orchestration, assumes `/plan`, changes approval policy by phase, and grants blanket push/merge authority. |
| `codex-cli/skills/sprint-loops/AGENTS.md.fragment` | high | Repeats workflow mechanics; should become a small durable pointer to the Book and skill. |
| `codex-cli/README.md` | high | Contains stale skill paths and a second copy of the complete protocol, creating drift. |
| `codex-cli/skills/sprint-loops/phases/03-plan-phase.md` | high | Hard-codes `/plan`, `decisions.md`, and an unavailable generic Agent tool; needs outcome/evidence contracts. |
| `codex-cli/skills/sprint-loops/phases/04-build-phase.md` | high | Uses root task paths, blanket per-task commits, and unsafe assumptions about parallel writers. |
| `codex-cli/skills/sprint-loops/phases/06-loop-phase.md` | high | Appends ADRs, contains force-push guidance, and conflates verified local completion with remote authority. |
| `README.md` | high | Defines the cross-harness contract and currently advertises legacy root paths and stale Codex installation. |
| `ROADMAP.md` | medium | Stores rationale separately from the actionable backlog; its content belongs in the Book migration. |
| `codex-cli/skills/sprint-loops/scripts/init-sprint.sh` | high | Creates root state and ignores sprints; must initialize a tracked Book and avoid split-brain layouts. |
| `codex-cli/skills/sprint-loops/scripts/current-phase.sh` | high | Derives phase from legacy paths; should resolve a versioned layout and keep artifact-based routing. |
| `codex-cli/skills/sprint-loops/scripts/finalize-plan.sh` | high | Enforces the ADR review gate; must enforce intent review and Book-path invariants instead. |
| `codex-cli/skills/sprint-loops/schemas/decisions.md` | high | ADR-lite schema to replace with a stable intent-chapter schema. |
| `tools/check-bundle-sync.sh` | high | Defines shared versus divergent assets; Book core must remain parity-guarded across adapters. |
| `tools/check-bundle-sync.test.sh` | high | Fixtures must cover new shared assets and reject missing, extra, or divergent Book files. |
| `tools/run-guards.sh` | high | Canonical suite registry must include Book validation/migration and Codex-specific checks. |
| `codex-cli/skills/sprint-loops/scripts/selftest.sh` | high | Hard-codes legacy layout across routing, ignore, ADR, and task-ledger fixtures. |
| `claude-code/skills/sprint-loop/SKILL.md` | medium | Shared semantics move to the Book; Claude-only plan/recurrence mechanics remain adapter-specific. |
| `open-harnesses/particles/00-overview.md` | medium | Condensed runtime-neutral contract must describe the Book without reimplementing path heuristics in prose. |
| `antigravity-ide/global_workflows/sprint-loops.md` | medium | Its Rosetta-Stone sync model needs explicit mapping into Book intent, task, and evidence states. |

## 3. External Sources

- [OpenAI Codex manual](https://developers.openai.com/codex/codex-manual.md) — current guidance says skills use progressive disclosure, `AGENTS.md` is durable layered repository guidance, and subagents are best used for bounded parallel work while write-heavy parallelism needs isolation.
- [OpenAI GPT-5.6 model guidance](https://developers.openai.com/api/docs/guides/model-guidance?model=gpt-5.6) — favors lean prompts, single-statement autonomy boundaries, explicit success criteria, relevant tools only, and representative validation; this directly supports shrinking the Codex adapter.
- [mdBook `SUMMARY.md` documentation](https://rust-lang.github.io/mdBook/format/summary.html) — establishes a linkable ordered hierarchy and supports draft chapters, making it a useful renderer-compatible navigation contract without making rendering the state authority.
- [The Rust Programming Language source repository](https://github.com/rust-lang/book) — confirms the Book model as maintained Markdown source with a buildable navigation surface rather than a monolithic generated document.

## 4. Risks, Unknowns, Dependencies

- **Risk — split-brain state:** silently supporting both root artifacts and `docs/` writes could produce two different active sprints. Migration must be dual-read/single-write: Book wins, legacy-only can be detected, and conflicting dual layouts fail loudly.
- **Risk — declared-state drift:** an intent status can disagree with its links. A validator must require unrealized intent to link to a task/plan and realized intent to link to completion plus code/test/documentation evidence.
- **Risk — history loss:** replacing ADRs outright could erase rationale. Legacy decisions must become a historical appendix or intent-history entries before the old file stops being authoritative.
- **Risk — tracked volume:** historical sprint research and test artifacts will become versioned documentation instead of ignored scratch. The migration should preserve them but keep generated/transient files ignored.
- **Risk — adapter drift:** Codex needs meaningful divergence, but shared semantics must still change atomically across Claude, Codex, Antigravity, and open-harness bundles.
- **Risk — unsafe concurrency:** all local Codex subagents share a workspace unless isolation is explicitly provided. Parallel research/review is safe; parallel commits are not the default.
- **Risk — remote authority:** a green local tree or CI result does not itself authorize pushes, merges, releases, or destructive actions. The adapter needs explicit interactive, unattended-local, and preauthorized-remote profiles.
- **Unknown — renderer commitment:** the Book should be mdBook-compatible, but requiring `mdbook` in every downstream project would add a dependency unrelated to the state machine. Rendering should initially remain optional.
- **Unknown — semantic proof strength:** paths and task IDs prove traceability, not that code fully realizes intent. Tests and critic review remain necessary evidence gates.
- **Dependency:** bundle parity guard, canonical guard runner, and macOS shell portability must remain green throughout the migration.

## 5. Recommended Approach

Primary: make `docs/` itself the Book and the only write target for new state. Use plain Markdown with anchored, machine-validated metadata so the system remains portable and renderer-neutral:

```text
docs/
├── README.md                 # Book contract and reader entry point
├── SUMMARY.md                # validated navigation; mdBook-compatible
├── intents/
│   ├── README.md             # lifecycle and index
│   └── INT-0001-<slug>.md    # intent, state, criteria, rationale, evidence, history
├── work/
│   ├── tasks.md              # unrealized executable work
│   └── completed-tasks.md    # append-only completion/evidence ledger
├── sprints/
│   └── sN/                   # tracked research, plans, critiques, tests, meta
└── history/
    └── decisions-legacy.md   # migrated, non-authoritative ADR history
```

Intent lifecycle:

```text
proposed → planned → active → realized
    │          ↑         │
    └→ deferred ─────────┘
         any state → superseded | abandoned
```

Every `INT-NNNN` chapter contains the normative intent and acceptance criteria. `planned`, `active`, and `deferred` entries link to `T-NNN` work and/or sprint plans; `realized` entries link to a completed task plus code, test, or documentation evidence. Rationale, alternatives, consequences, and a transition log live in the same chapter, replacing active ADRs. `SUMMARY.md` provides navigation but is not a second state store. Phase remains derived from sprint artifacts; a shared Book validator rejects duplicate IDs, invalid transitions, missing links, evidence-free realized intent, and conflicting legacy/Book layouts.

Adopt explicit schema versioning and a migration helper. Fresh projects initialize only `docs/`. Legacy-only projects remain detectable and receive an idempotent migration path. If both layouts exist without matching migration provenance, helpers stop instead of guessing. After migration, helpers read and write only the Book.

Refactor Codex around four concise contracts: outcome, authoritative inputs, allowed mutations/authority, and exit evidence. Use current `$sprint-loops` skill discovery, resolve helpers from the skill directory, make planning mode conditional, use the available plan/status mechanism instead of telling the agent to invoke `/plan`, delegate only bounded independent work by default, and keep one integrating writer/committer in a shared worktree. Move operator setup and automation profiles to the README; reduce `AGENTS.md.fragment` to a Book pointer and activation hint.

Alternative considered: keep the existing root layout and generate a read-only Book from ADRs, tasks, and completed sprints. Rejected because the generated Book would be a projection rather than the source of intent, leaving the same scattered authorities and drift problems.

Alternative considered: make a separate `docs/book/state.toml` the authoritative state and render Markdown from it. Deferred because it creates a second representation and a parser/runtime dependency. A later Rust helper may replace anchored Markdown validation if the schema becomes too complex; for this iteration, portable shell validation and explicit Markdown contracts preserve bundle self-containment.

Alternative considered: nest everything under `docs/book/`. Rejected for the first version because the user's proposed contract is that `/docs` is the project Book; the extra level adds indirection without a second documentation domain to justify it.

## Artifacts

- No separate evidential artifacts were saved; the surveyed files and external sources above are the evidence set.
