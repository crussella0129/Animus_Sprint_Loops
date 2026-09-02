# Particle: Initialize Sprint

> Inject when the phase helper reports `uninitialized` or
> `ready-for-next-sprint`.

```
"Invoke the installed bundle's scripts/init-sprint.sh helper with the project root as the working directory. It must classify existing state before writing, refuse legacy-only or split-brain layouts, preserve existing Book and .gitignore content, establish missing docs/ Book schema-v2 scaffolding, and initialize the next docs/sprints/sN/ provenance record. Initialization does not invent project intent or create root state authorities. Verify the marker, Book navigation, docs/intents/, docs/work/ ledgers, new sprint metadata fields, and a current-phase result of research."
```

Substrate gate, before initialization:

```
"Run the installed bundle's scripts/check-substrate.sh from the project root before initializing. substrate-complete proceeds to Init. substrate-absent and substrate-outdated:<book>-><bundle> both run the same idempotent scripts/deploy-substrate.sh, which creates only what is missing, stamps the substrate contract version, and verifies; re-running it on a current project changes nothing, and --check names the pending steps without writing. substrate-ahead:<book>-><bundle> means the Book was stamped by a newer bundle: update the bundle instead of converging backwards. substrate-partial:<diagnostic> names the element to repair first."
```

Schema: [`../schemas/sprint-meta.md`](../schemas/sprint-meta.md).
Helpers: [`../scripts/init-sprint.sh`](../scripts/init-sprint.sh) and
[`../scripts/current-phase.sh`](../scripts/current-phase.sh).

---

Next particle: `02-research-phase.md`.
