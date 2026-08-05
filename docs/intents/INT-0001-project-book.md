# INT-0001 — Project Book as the single Sprint Loops authority

<!-- sprint-loop-intent-v2 -->
- **Intent ID:** INT-0001
- **State:** realized
- **Work evidence:** [Sprint 14 build plan](../sprints/s14/sprint-plans/build-plan.md), [Sprint 14 test plan](../sprints/s14/sprint-plans/test-plan.md)
- **Completion evidence:** [T-119 & T-120 completion](../work/completed-tasks.md)
- **Code evidence:** [Book path contract](../../open-harnesses/scripts/book-paths.sh), [migration helper](../../open-harnesses/scripts/migrate-to-book.sh), [Book validator](../../open-harnesses/scripts/check-book.sh)
- **Test evidence:** [Sprint 14 test report](../sprints/s14/sprint-tests/test-report.md)
- **Documentation evidence:** [Book intent schema](../../open-harnesses/schemas/intent.md), [root README](../../README.md)

## Intent
Replace the scattered root-level Sprint Loops state — `sprints/`,
`agent-tasks/`, `decisions.md`, and `confidence.txt` — with one canonical,
human-readable Project Book under `docs/`. The Book holds four kinds of content
with distinct authority:

- **Intent chapters** (`docs/intents/INT-NNNN-*.md`) are the durable semantic
  authority: one stable statement of each intent spanning unrealized and
  realized work, recording rationale, alternatives, and consequences in place.
- **Work ledgers** (`docs/work/tasks.md`, `completed-tasks.md`,
  `confidence.txt`) are the executable backlog and completion record.
- **Sprint records** (`docs/sprints/sN/`) are provenance for each sprint's
  research, plans, and tests.
- **Navigation and history** (`docs/SUMMARY.md`, `docs/history/`) are
  non-authoritative views: `SUMMARY.md` is navigation only, and migrated
  material under `history/` is preserved rationale, never a second decision
  store.

Non-goals: this intent does not change the five-phase loop, does not introduce a
writable `phase.txt` (routing stays artifact-derived), and does not require an
mdBook build step — the Book is plain Markdown that mdBook *can* render.

## Acceptance criteria
- `docs/` validates under `check-book.sh`: exactly one `schema-version: 2`
  marker, unique `INT-NNNN` ids, legal states, and state-appropriate evidence.
- One writable authority: no root `sprints/`, `agent-tasks/`, `decisions.md`, or
  `confidence.txt` remains, and a coexisting writable Book plus legacy layout is
  refused as split-brain rather than silently chosen.
- Every harness (Claude, Codex, Antigravity, open-harness helpers) resolves the
  same Book paths and derives the same Research → Plan → Build → Test → Loop
  routing from Book artifacts alone.
- Legacy state migrates losslessly: a pre/post path-and-content-hash inventory
  proves one-to-one preservation, with any exclusion explicitly reviewed.
- The canonical guard suite runs Book validation, migration and routing
  selftests, bundle parity, and adapter-semantics checks locally and in CI.

## Rationale
Conflating ephemeral per-sprint working memory with long-lived project memory is
the most common failure mode in agentic workflows. Scattered root files gave no
single place to state *why* an intent exists, forced decisions into an
append-only `decisions.md` ADR log divorced from the work it justified, and made
cross-harness routing depend on incidental filesystem layout. A single Book with
typed authority makes intent, work, and provenance legible to both humans and
every adapter, and lets the state machine derive phase from evidence rather than
a mutable pointer.

## Alternatives
- **Keep scattered root state, add an index.** Rejected: an index over four
  authorities removes neither split-brain risk nor the absence of a home for
  intent rationale.
- **A database or JSON state store.** Rejected: not human-diffable in review and
  hostile to the Markdown-first, mdBook-compatible showcase.
- **A writable `phase.txt` pointer.** Rejected: duplicates state the artifacts
  already imply and invites drift between the pointer and the truth on disk.
- **Per-harness state schemas.** Rejected: guarantees divergence; the whole point
  is one contract every adapter reads.

## Consequences
- A one-time migration per project (`migrate-to-book.sh`) plus a documented
  split-brain refusal path; downstream projects must migrate before writing Book
  state.
- `SUMMARY.md` must stay navigation-only; intent metadata lives solely in chapter
  files, enforced by `check-book.sh`.
- Adapters retain only genuine orchestration differences (Claude plan-mode and
  recurrence, Antigravity native artifacts); shared Book semantics stay
  identical.
- Historical ADR text survives under `docs/history/decisions-legacy.md` as
  non-authoritative reference; new decisions are recorded in the relevant intent.

## Transition history
- 2026-07-31: created as `proposed` — sprint 14 research identified the Book
  architecture as the replacement for scattered root state.
- 2026-07-31: `proposed → planned` — the sprint 14 build plan (T-110–T-120) was
  finalized around this intent.
- 2026-08-01: `planned → active` — the Book contract, Book-native
  initialization, lossless migration, and runtime evidence gates (T-110–T-113)
  landed, followed by the shared protocol, adapters, documentation, and parity
  policy (T-114–T-118).
- 2026-08-03: this repository was migrated to its own Book (T-119); canonical
  Book verification registration (T-120) is in progress to complete the arc.
- 2026-08-05: `active → realized` — T-119 and T-120 completed; the sprint 14
  guard suite concluded `success` on the Ubuntu/macOS CI matrix (head
  `96bb374`), confirming Book validation, migration/routing, parity, adapter
  semantics, operator-doc contracts, and shellcheck all green with determinism.
