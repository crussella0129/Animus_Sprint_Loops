# Sprint 17 Meta

- **Sprint number:** 17
- **Book schema version:** 2
- **Start timestamp:** 2026-09-02T16:02:47Z
- **End timestamp:** 2026-09-02T18:00:32Z
- **Model:** Claude Opus 5
- **Bundle version:** unversioned (installed bundle 4acc1fd6e0b9; this sprint introduced bundle-version.sh at 0.17.0)
- **Exit status:** success
- **Token count:** (filled at Loop Phase if observable)
- **Summary:** Stamp a substrate contract version into the Book marker and make `deploy-substrate.sh` the single idempotent spin-up, upgrade, and no-op convergence entrypoint, with the running bundle version recorded per sprint.
- **Intents:** [INT-0004](../../intents/INT-0004-substrate-contract-versioning.md) — planned
- **Completion evidence:** T-137-T-142 delivered versioned substrate convergence; guards run 33662373769 green on ubuntu-latest and macos-latest for head 21deff42; this repository converged its own Book from contract 1 to 2 with a byte-identical re-run
