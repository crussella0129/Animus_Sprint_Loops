# Sprint 0 — End-to-End Tests

**Status:** not-yet-possible.

A real E2E would walk a fresh project through Research → Plan → Build → Test →
Loop with genuine artifacts and assert each phase's exit conditions and outputs.
The Build Phase of this sprint shipped only the scripts; there is no automated
mechanism yet for driving the LLM-authored phase outputs (research-report,
plans, etc.). The closest existing harness is `selftest.sh`, which exercises
the script layer end-to-end but not the document-authoring layer.

**Unlocked by:** sprint 1 — a follow-up sprint can use the now-hardened skill
to walk a full Research → Loop on a fresh project. The artifacts of that
sprint themselves become the E2E evidence: a complete `sprints/s0/` directory
under a separate project root, all eight phases executed via the routing
script, all per-task commits present.
