# Particle: Test Plan Schema

```
"To compose the test-plan, walk the build-plan's execution sequence in order. For each elementary task, define the unit tests required: input, expected output, and any required stubs or mocks. For each component (parent node in the schema tree), define the integration tests covering interaction between its child tasks. Finally, if the current state of the build will permit End-to-End system testing after this sprint completes, define the E2E tests: full system invocations with mock-real input data, observable outputs, and pass/fail criteria. If E2E testing is not yet possible, state so explicitly and identify what future sprint will unlock it. Review for local correctness (each test is well-formed and runnable) and global correctness (the test suite as a whole verifies the sprint goal). Write to 'test-plan.md' following the schema below."
```

Output artifact schema: [`../schemas/test-plan.md`](../schemas/test-plan.md).

---

Next particle: `06-build-phase.md`.
