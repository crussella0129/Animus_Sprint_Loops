# Plan Critique — Sprint 19

## Concerns

### C-001: the read-only property of the disagreement report had no named test
- **Where:** `build-plan.md` T-159 / `test-plan.md` "T-159 unit tests"
- **Quote:** "**WHEN** a disagreement is reported, **THEN** the project **SHALL** remain byte-identical."
- **Failure mode:** plan-test-mismatch
- **Why it matters:** report-don't-rewrite is the property that makes this reconciliation safe to run against projects whose provider an operator set deliberately. It was folded into another test's tail assertion rather than named, so a regression that started repairing profiles could pass a reading of the test list.
- **Suggested response:** fix-in-plan — **applied.** `test_check_disagreement_is_readonly` now asserts every file and every git ref is byte-identical after a disagreement is reported.

### C-002: a repository with a remote that is not named `origin` would be recorded as `local-only`
- **Where:** `build-plan.md` T-157
- **Quote:** "**WHEN** the repository has no `origin` remote, **THEN** the profile **SHALL** record `provider: local-only`."
- **Failure mode:** missing-risk
- **Why it matters:** a project whose only remote is named `upstream` is a hosted project, and recording it as `local-only` reproduces exactly the symptom this sprint exists to remove — silently, and for a reason the operator would find surprising.
- **Suggested response:** defer-with-rationale, with a test added. `local-only` is the correct answer here rather than a bug: the checkpoint adapter pushes to `origin` exclusively, so a project without an `origin` has no remote this protocol can reach, and recording a hosted provider would produce a checkpoint that fails at push time instead of a profile that is honest about what the loop can do. `test_infer_non_origin_remote_is_local_only` now asserts the behavior deliberately rather than leaving it as an accident of the implementation.

### C-003: the sprint plans against an intent whose majority of criteria are out of scope
- **Where:** `build-plan.md` Intents
- **Quote:** "Not covered this sprint: the REST checkpoint tier, the CI truth check, and base protection."
- **Failure mode:** intent-drift
- **Why it matters:** five of INT-0006's eleven acceptance criteria are outside this sprint. A Loop phase that reconciles the intent against "did the sprint's tasks complete" rather than against the criteria could realize a chapter that is less than half delivered — the same trap INT-0005 avoided only because its outstanding parts were written down first.
- **Suggested response:** fix-in-plan — **applied**, in three places so it cannot be missed at Loop. The build plan's Intents line enumerates what is not covered, the sprint metadata records `planned (partial: detection and enum only)`, and INT-0006's Transition history states that it will remain `active` at this sprint's close rather than realized.

### C-004: substring matching on the host will misfire on names that merely contain a provider's name
- **Where:** `build-plan.md` T-157 Notes
- **Quote:** "Enterprise hosts containing `github` or `gitlab` are matched deliberately"
- **Failure mode:** missing-risk
- **Why it matters:** `github-mirror.internal` or `notgithub.example.com` would be inferred as GitHub. The `gh` CLI would then be dispatched against a host that does not speak its API.
- **Suggested response:** defer-with-rationale. The failure is bounded and self-announcing: `gh` fails, the adapter falls through to push-and-print-compare-URL, and the operator sees the wrong provider recorded in a Book field with the inferred URL beside it — which is exactly the provenance the sprint adds. The alternative, matching only exact hostnames, would fail every genuine enterprise GitHub and GitLab install, which is a far more common case than a decoy hostname. The explicit `--provider` override covers the remainder.

### C-005: the provenance prose sits outside a fence the resolver depends on
- **Where:** `build-plan.md` T-157 Notes
- **Quote:** "Provenance must sit outside the fence: the resolver reads the first fenced block and rejects unknown keys."
- **Failure mode:** hidden-dep
- **Why it matters:** the profile's parseability now depends on prose being placed *before* the first fence and never after it. Nothing enforces that placement, and a later edit that moves it — or a template change that adds a second fenced block — would break resolution for every project.
- **Suggested response:** fix-in-plan, partially — `test_infer_records_provenance` already asserts that `remote-profile.sh` still resolves a profile carrying provenance, which turns the coupling into a tested property rather than a convention. The residual risk is a future second fenced block, which is a resolver-contract question rather than a Sprint 19 one; recorded here so it is not rediscovered.

## Confidence
clean
