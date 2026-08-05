# Sprint 4 — End-to-End Tests

**Status:** not-yet-possible.

Same constraint: document-authoring layer is LLM-in-the-loop. The script and
schema/phase-doc layers are now covered by 22 unit tests + 12-step selftest
across both bundles.

**Sprint-on-sprint observation:** this sprint's own research-report uses
`## 0. Decisions Reviewed` (with numeric prefix). `finalize-plan.sh` accepted
it because the grep pattern is permissive over numeric prefixes
(`^## ([0-9]+\. *)?Decisions Reviewed` matches both `## Decisions Reviewed`
and `## 0. Decisions Reviewed`). Sprint 5+ research-reports should
standardize on the no-numeric form per the schema example.

**Unlocked by:** sprint 5+ candidates (subagent fan-out, enforced research
budget, CI workflow).
