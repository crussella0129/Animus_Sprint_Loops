# Sprint 3 — End-to-End Tests

**Status:** not-yet-possible.

Same constraint as prior sprints: the document-authoring layer is
LLM-in-the-loop. The script and protocol-bookkeeping layers are fully
exercised by the 11-step `selftest.sh` and the unit + integration tests.

**Unlocked by:** a CI workflow (GitHub Actions running each bundle's
`install.sh` then `selftest.sh` on push) is the natural sprint-4+ candidate.

## Sprint-on-sprint observation

This sprint's autonomy-bake-in changes the operating mode of *future*
sprints. The user shared these patterns mid-sprint 2; sprint 3 codified
them. Sprint 4 onwards should test the new autonomy mode operationally
(does the agent actually defer-over-block, run pre-flight, verify CI
correctly), which is itself a form of E2E.
