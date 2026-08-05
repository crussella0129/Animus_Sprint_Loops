# Sprint 14 Meta

- **Sprint number:** 14
- **Start timestamp:** 2026-07-31T23:49:54Z
- **End timestamp:** 2026-08-05T03:19:01Z
- **Model:** GPT-5.6-sol (T-110–T-118); Claude Opus 4.8 (continued T-119–T-120, Test, Loop)
- **Exit status:** success
- **Token count:** (not observable)
- **Summary:** Replaced scattered Sprint Loops state with a `docs/` Project Book (v2) and refactored the Codex adapter for current GPT-5.6 behavior. Shipped the Book contract, Book-native init/routing, lossless migration, evidence-gated runtime helpers, the harness-neutral protocol, all three adapters, operator docs, and parity policy (T-110–T-118), then dogfooded by migrating this repository into its own Book — 146/146 files preserved by SHA-256, `book-only`, `INT-0001` authored (T-119) — and registered canonical Book verification in the deterministic guard suite (T-120). Confidence 1.0. Local canonical run 9/10 suites PASS (all `determinism: ok`); the one exception is a Windows-git-bash GNU-awk `\r`-stripping quirk in `runtime-helpers` CRLF assertions (green on the authoritative Ubuntu/macOS CI; backlogged as T-121). Authoritative CI confirmation is captured on the sprint-14 PR.
