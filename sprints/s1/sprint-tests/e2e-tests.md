# Sprint 1 — End-to-End Tests

**Status:** not-yet-possible.

Same constraint as sprint 0: there is no automated mechanism for driving the
LLM-authored phase outputs (research-report, plans, etc.). The script layer
and protocol bookkeeping are now fully exercised by the 9-step `selftest.sh`
and the unit tests above — but the document-authoring layer (the actual
agent loop) is still validated only by running this very sprint end-to-end
manually (as we are doing now).

**Unlocked by:** a sprint 2 candidate is adding a CI workflow that runs
`selftest.sh` on push for all three bundles. That CI run would constitute the
first automated E2E gate for the script layer. The document-authoring layer
remains an LLM-in-the-loop concern by design.

## Sprint-on-sprint observation

This sprint's own end-to-end execution serves as ad-hoc E2E evidence: the
hardened `current-phase.sh` (sprint 0) routed this sprint correctly from
Plan → Build without manual override — recorded in `sprint-meta.md`. Sprint 2
will exercise the back-filled `commit-task.sh` and the abort path the same
way, automatically.
