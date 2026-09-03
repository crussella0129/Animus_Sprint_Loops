# Test Critique — Sprint 19

## Concerns

### C-001: a fixture passed without exercising anything, and only a stray diagnostic revealed it
- **Where:** `unit-tests.md` T-157 / `deploy-substrate.test.sh`
- **Quote:** "`test_existing_profile_untouched` originally created `docs/work` before the Book existed, so `init-sprint` refused, convergence never ran, and the profile was trivially unchanged"
- **Failure mode:** weak-assertion
- **Why it matters:** the fixture asserted a *negative* — "the profile did not change" — which is satisfied both when convergence correctly leaves it alone and when convergence never runs at all. It was caught only because the refusal printed a marker diagnostic into output that happened to be read. Every other negative assertion in the suite has the same shape and the same exposure.
- **Suggested response:** fix-in-plan — **applied**, and generalized. The fixture now asserts convergence emitted `substrate-complete` before asserting the profile is unchanged. The general rule — a "did not change" assertion must be paired with an assertion that the operation actually ran — is recorded as carry-forward, because the suite contains several such fixtures written before it was articulated.

### C-002: a cross-task dependency was missing from the plan, for the second sprint running
- **Where:** `build-plan.md` T-157 and T-158, both "Depends on: (none)"
- **Quote:** "the `codeberg.org → forgejo` clause fails until the enum accepts `forgejo` — the resolver rejects it and convergence rolls the entire deploy back"
- **Failure mode:** hidden-dep
- **Why it matters:** Sprint 18's worst defect was also an unplanned dependency — `substrate-misplaced` breaking `deploy-substrate`. This one is milder because it surfaced on the first manual probe rather than in CI, but the pattern is now twice-observed: the plan reasons about tasks as units of work and misses that one task's *output values* are another's *accepted inputs*.
- **Suggested response:** defer-with-rationale, and treat as evidence for existing carry-forward. T-154 already proposes that a plan changing a shared helper enumerate that helper's consumers; this sprint shows the rule needs to cover enumerated value sets as well as helpers — a task that emits a new value must name every validator that will see it. Recorded against T-154 rather than opening a second overlapping task.

### C-003: a local-path `origin` is untested
- **Where:** `unit-tests.md` T-157
- **Quote:** the inference fixture set covers HTTPS, SCP-form SSH, `ssh://`, an unknown host, no remote, and a non-`origin` remote
- **Failure mode:** negative-path
- **Why it matters:** an `origin` that is a filesystem path — `/srv/git/repo.git`, or a bare repo on a share, which is exactly how the adapter's own fixtures wire their remotes — matches neither URL branch, so the host resolves empty and the provider becomes `generic`. That is defensible behavior (a push to a path origin genuinely works, and the printed compare URL is merely useless rather than harmful), but it is unasserted, so nothing pins it.
- **Suggested response:** defer-with-rationale, recorded as carry-forward. `generic` is the correct answer and the code path is exercised indirectly by `test_infer_unknown_host_is_generic`, but the specific input shape deserves its own fixture. Adding it now would mean another full run of the slowest suite in the runner for a case whose behavior is already understood; it is queued instead.

### C-004: the canonical suite's wall time is becoming a cost of its own
- **Where:** `integration-tests.md` "A note on suite runtime"
- **Quote:** "the `deploy-substrate` suite grew from sixteen fixtures to twenty-four, each performing a full convergence"
- **Failure mode:** flake-risk
- **Why it matters:** not flakiness in the usual sense, but the same consequence. Each convergence fixture does a real `git init`, Book scaffold, sprint init, and verification; under `--determinism` every suite runs twice. The runner is now long enough that it is tempting to skip locally and lean on CI — which is precisely how the T-121 workaround became habitual over two sprints.
- **Suggested response:** defer-with-rationale, recorded as carry-forward. The runner's design is deliberately unmemoized (see ROADMAP §1, which defers content-addressed cells until array-test's engine ships), so speeding it up is a known, separately-scoped decision rather than an oversight. Naming it here so the cost is visible when that decision is revisited.

### C-005: this sprint delivers under half of its intent's acceptance criteria
- **Where:** `build-plan.md` Intents / `INT-0006`
- **Quote:** "Not covered this sprint: the REST checkpoint tier, the CI truth check, and base protection."
- **Failure mode:** intent-coverage
- **Why it matters:** six of INT-0006's thirteen acceptance criteria are proven; the rest are out of scope by design. A Loop phase reconciling against task completion rather than criteria would realize a chapter that is less than half delivered.
- **Suggested response:** defer-with-rationale — the partial scope is deliberate and was recorded in three places at plan time (the build plan's Intents line, the sprint metadata's `planned (partial)`, and the chapter's own Transition history). INT-0006 stays `active` at close. This concern exists to make the Loop phase's obligation explicit rather than to change the plan.

## Confidence
proceed-with-caveats
