# Sprint 2 — End-to-End Tests

**Status:** not-yet-possible.

Same as prior sprints: the document-authoring layer is LLM-in-the-loop. Script
and protocol-bookkeeping layers are fully covered by 10-step selftest + the
unit/integration tests above.

**Unlocked by:** a future sprint adding CI (GitHub Actions running each
bundle's `install.sh` then `selftest.sh` on push). Sprint 3 is targeted at the
autonomy-loop patterns the user shared mid-sprint; CI is a strong candidate
for sprint 4 once those patterns settle.
