# Test Critique — Sprint 17

## Concerns

### C-001: "rolls back at any convergence step" is proved at two of five injection points
- **Where:** `INT-0004` Acceptance criteria / `unit-tests.md` T-139
- **Quote:** "A failure injected at **any** convergence step rolls back every artifact that run created, leaving the project at its prior contract version."
- **Failure mode:** intent-coverage
- **Why it matters:** the criterion quantifies over every step, but only `DEPLOY_SUBSTRATE_FAIL_AFTER=branches` and `=stamp` are exercised. Injection after `book`, `profile`, and `updater` is untested, so a rollback defect specific to an early abort would not be caught.
- **Suggested response:** defer-with-rationale. Rollback is a single function whose behavior is determined by which `CREATED_*` variables are set, and the two exercised points bracket it: `branches` fails after every creating step has run, and `test_deploy_rolls_back` asserts that the Book, the updater config, and the git directory are all gone afterwards, while `test_deploy_rollback_preserves_preexisting` asserts nothing pre-existing was touched. The untested points therefore exercise strict subsets of the same code path with strictly fewer artifacts to undo. `stamp` is tested separately because it is the one step that *restores* content rather than deleting it. Recorded as carry-forward rather than claimed as covered.

### C-002: the local suite never executed five of the sprint's own fixtures
- **Where:** `unit-tests.md` T-137 "Execution note" and T-141
- **Quote:** "These four ran in a focused harness driving the installed `claude-code` bundle rather than through `selftest`, because `selftest` aborts earlier on backlog defect **T-121**"
- **Failure mode:** evidence-drift
- **Why it matters:** the recorded local guard run reports `selftest FAIL`, and the four T-137 fixtures plus the T-141 legacy-close fixture sit downstream of the aborting assertion. The evidence that they pass comes from harnesses written for this sprint, not from the canonical suite — a weaker provenance than every other result in this record.
- **Suggested response:** defer-with-rationale, conditional on CI — **condition met, concern discharged.** The blocking defect is pre-existing and platform-specific: it reproduces byte-identically from an unmodified `0f8f35d` checkout and does not reproduce on POSIX, which is why the CI matrix — where `selftest` runs to completion and executes these fixtures in place — is the authoritative confirmation for this sprint, as the phase contract requires. Re-review after the evidence change: [run 33662373769](https://github.com/crussella0129/Animus_Sprint_Loops/actions/runs/33662373769) concluded `success` on head `21deff42` with both `ubuntu-latest` and `macos-latest` green, so `selftest` — and with it all five fixtures named here — executed and passed inside the canonical suite. T-121 remains queued as backlog for the Windows-local path.

### C-003: the plain convergence re-run reports its end state, not explicitly "nothing changed"
- **Where:** `INT-0004` Acceptance criteria / `e2e-tests.md`
- **Quote:** "a second run of that command changes nothing **and reports the no-op**"
- **Failure mode:** weak-assertion
- **Why it matters:** a second `deploy-substrate.sh` prints `substrate-complete (…contract=2)` — the verified end state — which a reader could mistake for work having been done. The explicit no-op wording lives in `--check` ("converged (no pending steps)").
- **Suggested response:** defer-with-rationale. The criterion is met, in two forms that are both asserted: the machine-checkable form is `test_deploy_idempotent`'s file-and-ref snapshot equality, and the human-readable form is `--check`'s `converged (no pending steps)`, asserted in `test_converge_check_is_readonly` and reproduced in the repository's own E2E record. Changing the success line of the primary command to distinguish "created" from "already current" is a legitimate improvement but is not required by the criterion and would churn the string that `test_converge_verifies_after_stamp` asserts.

### C-004: the manifest fixtures seed themselves from the live repository
- **Where:** `unit-tests.md` T-140 / `tools/check-plugin-manifest.test.sh`
- **Quote:** "`test_manifest_baseline_passes` | the real packaging surface is valid — proves the mutations below fail for their own reason"
- **Failure mode:** flake-risk
- **Why it matters:** `make_fixture` copies `marketplace.json`, `plugin.json`, `SKILL.md`, and `bundle-version.sh` out of the working tree, so every fixture inherits repository state. A future breakage in the real manifest would fail all six fixtures rather than the one guard that owns that assertion.
- **Suggested response:** defer-with-rationale. The coupling is deliberate and follows `check-bundle-sync.test.sh`: seeding from the real surface is what makes a mutation test meaningful, and the baseline case exists precisely so a repository-state failure is distinguishable from a mutation failure. The `plugin-manifest` suite runs the guard against the real repository immediately before `plugin-manifest-test` in the canonical runner, so the ordering already separates the two signals.

### C-005: the guard runner labels a passing determinism check as a mismatch
- **Where:** `e2e-tests.md` / `tools/run-guards.sh`
- **Quote:** "`FAIL  selftest  243s  (status=FAIL det-mismatch)`" while the recorded confirmation for the same suite reads `"determinism":"ok"`
- **Failure mode:** evidence-drift
- **Why it matters:** the console summary uses `${det:+ det-mismatch}`, which expands whenever the determinism field is *set* rather than when it *mismatched*. Any failing suite in a `--determinism` run is therefore reported as nondeterministic even when both runs agreed exactly. It caused a misreading of this sprint's own evidence, and would do so again on any future red suite.
- **Suggested response:** defer-with-rationale. The recorded ndjson confirmation — the actual evidence artifact, and what CI uploads — is correct; only the human-facing summary line is wrong. Fixing it is a one-line change in a file this sprint already touched, but it is unrelated to INT-0004 and belongs in its own scoped task rather than being folded into a sprint whose plans are locked. Queued as carry-forward.

## Confidence
proceed-with-caveats
