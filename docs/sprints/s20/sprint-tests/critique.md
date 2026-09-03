# Test Critique — Sprint 20

## Concerns

### C-001: the locked plan contained a clause that specified the defect
- **Where:** `build-plan.md` T-166 / `deploy-substrate.sh` step 2d
- **Quote:** "**WHEN** convergence runs against a Book below contract 4, **THEN** it **SHALL** generate nothing, and the project **SHALL** be byte-identical to its pre-run state apart from the contract stamp."
- **Failure mode:** intent-drift
- **Why it matters:** convergence raises a project to the current contract *in the same run*, so "runs against a Book below contract 4" describes the state at entry — and every project is below 4 at entry until it converges. Implemented literally, a fresh project reads contract 1 and gets no CI, and an existing project upgrading to 4 skips the very thing the upgrade exists for, seeing CI only on a second convergence. The clause survived the plan critic, which checked that each EARS clause had a test rather than whether the clause described the behavior anyone wanted.
- **Suggested response:** fix-in-plan — **applied as a recorded deviation.** The step runs after the stamp, `test_converge_generates_ci_after_stamp` pins the ordering, and the plan's inertness fixture was replaced with tests of properties convergence can actually be in. The deviation is stated in T-166's completion entry rather than buried here. The generalizable lesson is that a version-gated step inside an operation that *changes the version* needs its evaluation point named explicitly in the plan, not left to the reader.

### C-002: the acceptance criterion asking for an observable job failure is met for one host of five
- **Where:** `INT-0012` Acceptance criteria / `unit-tests.md` T-165
- **Quote:** "a fixture project per language produces a job whose failure is observable when that language's tests fail"
- **Failure mode:** intent-coverage
- **Why it matters:** only `generic` produces an executable artifact, so only it can be run in a fixture. For GitHub, Gitea, Forgejo, and GitLab this sprint proves the generated file *contains* the language's real commands, not that a runner executes them and goes red. A YAML typo that makes a workflow unparseable would pass every test here.
- **Suggested response:** defer-with-rationale, already recorded at plan time and unchanged by delivery. `test_scaffold_generic_ci_actually_fails` executes the one runnable case in both directions. Closing the gap for the YAML hosts needs INT-0006's CI truth check plus a real hosted run, and this repository will supply the second of those the first time a generated workflow lands in a project that uses it. INT-0012 stays `active`.

### C-003: no fixture asserts the generated YAML parses
- **Where:** `unit-tests.md` T-165
- **Quote:** the generator fixtures assert paths, job names, trigger contents, and byte-stability
- **Failure mode:** weak-assertion
- **Why it matters:** this is the concrete form of C-002 and is cheaply fixable in a way C-002 is not. Every assertion greps for a substring, so a structurally invalid document — bad indentation under `jobs:`, an unquoted value — would satisfy all of them. The failure would surface only on a real host, in someone else's project.
- **Suggested response:** defer-with-rationale, recorded as carry-forward. A YAML parser is not a dependency this bundle can assume: the four bundles are dependency-free bash by design, and `python3` is present for the plugin-manifest guard but is not currently required by any `scripts/` helper. Adding a parse check means either taking that dependency into the runtime path or gating the fixture on `command -v python3`. Worth doing, worth deciding deliberately rather than as a side effect of this sprint.

### C-004: the generated Python step writes a pattern the next sprint's gate is built to reject
- **Where:** `scaffold-ci.sh` / `INT-0006` acceptance criteria
- **Quote:** `python -m pytest; rc=$?; [ "$rc" -eq 0 ] || [ "$rc" -eq 5 ]`
- **Failure mode:** hidden-dep
- **Why it matters:** INT-0006's CI truth check will assert that a workflow "must not neutralize failure with `continue-on-error` or a trailing `|| true`". This is a narrower relative of the same shape, and a truth check written from that criterion without knowing about this decision would flag Sprint 20's own output.
- **Suggested response:** defer-with-rationale, carried forward from the plan critique unchanged, because the risk is unchanged. The allowance accepts exactly pytest's documented "no tests collected" code and no other, and `test_scaffold_python_tolerates_no_tests` asserts the file contains neither `|| true` nor `continue-on-error`. INT-0006's check must permit a specific exit code while forbidding blanket swallowing; this is the second record of that requirement.

### C-005: contract 4 is the third raise in four sprints
- **Where:** `deploy-substrate.sh` / `book-paths.sh`
- **Quote:** `BOOK_SUBSTRATE_CONTRACT_VERSION=4`
- **Failure mode:** missing-risk
- **Why it matters:** every raise makes every existing project report `substrate-outdated` until it converges, and each convergence now writes more than the last. An operator dogfooding across several projects meets this three times in short succession, and this raise is the first that generates a *new file* rather than adding a gate.
- **Suggested response:** defer-with-rationale. The alternative — generating CI into existing projects unconditionally — is strictly more intrusive than a previewable version step, and `--check` names the pending file before anything is written. Recorded so the cumulative churn is visible rather than discovered.

## Confidence
proceed-with-caveats
