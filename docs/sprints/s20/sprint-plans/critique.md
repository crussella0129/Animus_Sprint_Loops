# Plan Critique — Sprint 20

## Concerns

### C-001: the intent asks for an observable failure that no bash fixture can produce
- **Where:** `INT-0012` Acceptance criteria / `test-plan.md`
- **Quote:** "a fixture project per language produces a job whose failure is observable when that language's tests fail"
- **Failure mode:** intent-drift
- **Why it matters:** the sprint generates workflow YAML for GitHub, Gitea, Forgejo, and GitLab, and nothing in a shell fixture can execute those runners. Taken literally, this criterion is unmeetable by the delivery, and a plan that quietly asserts the weaker property — "the file contains a rust job" — while claiming the criterion is a false pass at plan scale.
- **Suggested response:** fix-in-plan — **applied**, partially, and the remainder recorded. The `generic` provider's output is a shell script and *can* be executed, so `test_scaffold_generic_ci_actually_fails` runs it against a fixture whose test command fails and asserts a non-zero exit, and against one that passes and asserts zero. For the YAML hosts the sprint proves only that the generated commands are the language's real ones. Closing the gap properly requires INT-0006's CI truth check plus a real hosted run; the criterion stays unmet for those hosts and INT-0012 stays `active`.

### C-002: the sprint writes a failure-tolerance pattern that a later sprint is built to reject
- **Where:** `build-plan.md` T-165 Notes
- **Quote:** "`pytest` tolerating **only** exit 5 (no tests collected)"
- **Failure mode:** hidden-dep
- **Why it matters:** INT-0006's CI truth check will assert that generated workflows "must not neutralize failure with `continue-on-error` or a trailing `|| true`". An exit-code allowance is a narrower form of the same shape, and a truth check written from that criterion without knowing about this decision would flag Sprint 20's own output as a false-green pattern — one sprint's deliverable failing the next sprint's gate.
- **Suggested response:** defer-with-rationale, recorded so the later sprint inherits the decision rather than rediscovering it. The allowance is genuinely narrow: it accepts exactly pytest's documented "no tests collected" code and no other, so a real test failure still fails. The alternative — omitting the Python test step — produces a job that verifies nothing, which is worse. INT-0006's check must be written to permit a specific exit code and forbid blanket swallowing, and this critique is the record of why.

### C-003: contract 4 is the third version raise in four sprints
- **Where:** `build-plan.md` T-164
- **Quote:** "raise `BOOK_SUBSTRATE_CONTRACT_VERSION` to 4"
- **Failure mode:** missing-risk
- **Why it matters:** every raise makes every existing project report `substrate-outdated` until it converges. That is the designed upgrade path, but an operator dogfooding across several projects now meets it three times in short succession, and each convergence writes something new. The cumulative churn is a real cost that no single sprint's plan shows.
- **Suggested response:** defer-with-rationale. The alternative is generating CI unconditionally into existing projects, which is strictly more intrusive than an explicit, previewable version step. Convergence remains idempotent and `--check` still previews. Recorded so the pattern is visible if a fourth raise follows.

### C-004: sprint 19 shipped code without raising the bundle version
- **Where:** `build-plan.md` T-164 Notes
- **Quote:** "Sprint 19 shipped code without raising the bundle version, so `0.18.0` currently names two different bundles"
- **Failure mode:** evidence-drift
- **Why it matters:** the whole point of recording `Bundle version` in each sprint record is to answer "which bundle ran this sprint?" without inferring it. Two materially different bundles sharing `0.18.0` makes that answer wrong for sprint 19 — its record claims a version whose contents differ from the one sprint 18 recorded under the same number.
- **Suggested response:** fix-in-plan for the future, defer for the past. This sprint raises to `0.20.0`, restoring the sprint-number correspondence. Sprint 19's record is closed and is not being rewritten; the discrepancy is documented here instead. The deeper repair — making the raise structural rather than remembered — belongs with the roadmap's plugin-version-discipline item.

### C-005: pinning `actions/checkout@v4` ages out of our control
- **Where:** `build-plan.md` T-165 Notes
- **Quote:** "Pin `actions/checkout@v4`"
- **Failure mode:** missing-risk
- **Why it matters:** this repository's own workflow already uses `v7`, kept current by Dependabot. Generated files live in *other* projects, where our Dependabot config does not reach, so the pin will age wherever it lands.
- **Suggested response:** reject — the critique describes the intended design rather than a defect. Generation is create-if-absent and the project owns the file the moment it is written; the generated updater config is precisely what keeps its actions current thereafter. A floating major tag would trade a stale pin for an unannounced breaking change, which is worse for a project that may not look at its CI for months. `v4` is chosen over `v7` deliberately: self-hosted Gitea and Forgejo runners frequently mirror only older action releases.

## Confidence
clean
