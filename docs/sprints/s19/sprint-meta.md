# Sprint 19 Meta

- **Sprint number:** 19
- **Book schema version:** 2
- **Start timestamp:** 2026-09-03T02:14:06Z
- **End timestamp:** 2026-09-03T04:48:15Z
- **Model:** Claude Opus 5
- **Bundle version:** 0.18.0
- **Exit status:** success
- **Token count:** (filled at Loop Phase if observable)
- **Summary:** Infer the provider from the origin remote at Sprint 0 instead of defaulting every hosted project to local-only.
- **Intents:** [INT-0006](../../intents/INT-0006-provider-reach-and-ci-truth.md) — active (partial: detection and enum delivered; REST tier, CI truth check, and base protection outstanding)
- **Completion evidence:** T-157-T-160 made the provider a fact derived from origin instead of a local-only default; guards run 33715133221 green on both legs for head facd325; the reported symptom retested end to end on a fresh repository
