# Particle: Test Phase

```
"You are in the Test Phase. Read the current sprint's 'test-plan.md' as authoritative input. Implement and run all unit tests defined for tasks completed in this sprint's Build Phase; record results in 'sprint-tests/unit-tests.md'. Then implement and run all integration tests defined for components touched in this sprint; record results in 'sprint-tests/integration-tests.md'. If the test-plan marks E2E tests as possible, implement and run them; record results in 'sprint-tests/e2e-tests.md'. Otherwise, write 'Not yet possible — unlocked by sprint N+K' in that file. For any failing test, do not patch the symptom: identify the underlying cause. If the fix is small and local, apply it and re-run. If the fix requires re-architecture, stop testing, write a 'failure-report.md' to 'sprints/sN/' documenting the root cause and the work needed, mark 'sprint-meta.md' exit status as 'failed', and proceed to the Loop Phase — the next sprint will begin with that failure-report as its primary research input. Watch for successful completion of any CI/CD pipelines configured for the repo. For GitHub Actions specifically: 'gh run watch's exit code is unreliable on some platforms, so always verify conclusion as a SEPARATE step via 'gh run list --branch <X> --json status,conclusion' and treat that field as authoritative; on failure, 'gh run view <id> --log-failed' to read root cause. When all tests pass and CI is green, write a summary to 'sprint-tests/test-report.md' covering: tests run, tests passed, tests failed, coverage observations, and any technical debt identified. Then proceed to the Loop Phase."
```

Output artifact schemas: [`../schemas/test-report.md`](../schemas/test-report.md), [`../schemas/failure-report.md`](../schemas/failure-report.md).

---

Next particle: `08-loop-phase.md`.
