# Agent Tasks (Persistent Backlog)

- [ ] T-101 (backlog): array-test engine integration — guards as content-addressed cells, memoized frontier runs, Merkle-root Loop gate; GATED on array-test T1–T5 shipping (see ROADMAP.md §1) — touches: tools/run-guards.sh, phases/05+06, schemas/test-report.md
- [ ] T-104 (backlog): plugin version field + per-sprint bump + documented /plugin update reload; skill prints bundle version at Init — touches: claude-code/.claude-plugin/plugin.json, READMEs, claude-code SKILL.md, scripts/init-sprint.sh
- [ ] T-105 (backlog): abort-sprint.sh no-git graceful fallback — touches: {4 bundles}/scripts/abort-sprint.sh, selftest.sh
- [ ] T-106 (backlog): antigravity bundle parity decision (grow translation layer vs document thin-adapter) — touches: antigravity-ide/global_workflows/sprint-loops.md, antigravity-ide/README.md
- [ ] T-107 (backlog): launch-time E2E harness for picker count + auto-trigger survival — touches: tools/, .github/workflows/ci.yml
- [ ] T-108 (backlog): record confidence before→after in sprint-meta at Loop close — touches: {4 bundles}/scripts/update-confidence.sh, phases/06, schemas/sprint-meta.md
- [ ] T-109 (backlog): dev-branch working model — at Init (sprint 0), establish/verify a long-lived work branch ("dev" or user-named) alongside main; sprints develop on it and each sprint's PR targets main; at launch, elicit approve-merge vs auto-merge unless the initial prompt already specified it (user request, s11) — touches: {4 bundles}/scripts/init-sprint.sh, phases/01+06, claude-code SKILL.md, schemas/sprint-meta.md
- [ ] T-112 (sprint 14): add lossless idempotent legacy-to-Book migration — touches: migrate-to-book.sh, selftest.sh
- [ ] T-113 (sprint 14): rewire runtime helpers and hard gates to Book evidence — touches: abort-sprint.sh, commit-task.sh, finalize-plan.sh, research-budget.sh, update-confidence.sh, selftest.sh
- [ ] T-114 (sprint 14): rewrite the harness-neutral protocol around intent and evidence — touches: phases, schemas, prompts, particles
- [ ] T-115 (sprint 14): refactor the Codex adapter for current GPT-5.6 and Codex behavior — touches: Codex SKILL, AGENTS fragment, phases, installer, README
- [ ] T-116 (sprint 14): align Claude and Antigravity adapter semantics with the Book — touches: Claude SKILL/phases, Antigravity workflow
- [ ] T-117 (sprint 14): consolidate repository and bundle operator documentation — touches: root and bundle READMEs, ROADMAP
- [ ] T-118 (sprint 14): extend parity policy for the Book core and divergent adapters — touches: bundle-sync and semantic guards/tests
- [ ] T-119 (sprint 14): migrate this repository into its own Book — touches: docs, legacy root state, .gitignore
- [ ] T-120 (sprint 14): register Book verification in the canonical deterministic guard suite — touches: run-guards.sh, fixtures, CI registration
