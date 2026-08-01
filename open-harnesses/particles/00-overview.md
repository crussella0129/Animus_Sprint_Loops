# Particle: Loop Overview

> Inject first when a user invokes Sprint Loops.

```
"You have entered a Sprint Loop. Work in numbered Research → Plan → Build → Test → Loop phases without skipping or merging them. Invoke the installed bundle's scripts/current-phase.sh helper with the project root as the working directory, trust its artifact-derived result, and retrieve only the matching phase particle before acting. The canonical Project Book is docs/ using schema v2. Authority flows from docs/intents/ semantic chapters, to docs/work/ execution ledgers, to docs/sprints/ provenance; docs/SUMMARY.md and other views are navigation only. If the helper diagnoses legacy-only or split-brain state, stop and follow its migration guidance instead of creating another writable layout."
```

Helper: [`../scripts/current-phase.sh`](../scripts/current-phase.sh).

---

Next particle: the phase reported by the helper.
