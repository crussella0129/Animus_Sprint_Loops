# Sprint 22 Research Report

## Intents Reviewed
- [INT-0013](../../../intents/INT-0013-verification-integrity.md) — selected, active; reliable local confirmations and meaningful sensitivity verdicts.
- [INT-0007](../../../intents/INT-0007-integrity-sweep.md) — selected, proposed; remove the concrete vestigial runner entries already identified as T-177, without implementing the future computed sweep.

## 1. Sprint Goal
Make verification evidence current, failures diagnosable, and the canonical
suite free of the duplicate adapter checks. Advance T-179, T-180, and T-177
in one bounded sprint, preserving the Bash implementation and four-adapter contract.

## 2. Existing Code Survey
| File | Relevance | Notes |
|------|-----------|-------|
| tools/run-guards.sh | high | Captures then deletes diagnostics; records only suite script hash; contains two obsolete suite aliases. |
| tools/run-guards.test.sh | high | Synthetic extra-suite seam makes failure paths inexpensive to test. |
| tools/check-suite-sensitivity.sh | high | Trusts any past PASS; archives HEAD but reads baseline from an unbound working-tree report. |
| tools/check-suite-sensitivity.test.sh | high | Fabricates baseline hashes, so cannot detect stale evidence. |
| tools/check-merge-policy.sh | high | Compatibility shim executes adapter-semantics checker. |
| tools/check-merge-policy.test.sh | high | Compatibility shim executes adapter-semantics fixtures. |
| .github/workflows/ci.yml | high | Runs canonical runner and uploads only ndjson; stderr is retained in CI logs. |
| README.md | high | Explains baseline and sensitivity behavior; must state new freshness requirements. |
| tools/operator-docs.test.sh | medium | Existing documentation discoverability guard. |
| tools/check-bundle-sync.sh | medium | Verifies shared asset parity across four distributions. |
| tools/check-plugin-manifest.sh | medium | Enforces manifest/bundle version agreement. |
| open-harnesses/scripts/bundle-version.sh | medium | Current bundle version is 0.21.0. |
| docs/work/tasks.md | high | Existing T-177/T-179/T-180/T-181 define the observed problems. |
| docs/sprints/s21/sprint-tests/test-report.md | high | Prior sprint verification and known macOS nondeterminism. |

## 3. External Sources
No external design sources are needed. Read-only GitHub inspection confirmed
`dev` at `d765e33cf402b37d118069b9d6b2e597df8170f3`, `main` at
`80c0827905689e448816795c3c91725d89d23379`, and no open pull requests.
This sprint starts from the latest remote work-branch source.

## 4. Risks, Unknowns, Dependencies
- A suite hash alone excludes its subject and dependencies. Bind confirmations
  to the committed source tree and refuse dirty/unavailable or mismatched provenance.
- The plan critic identified an untracked-dependency gap: even a clean tracked
  tree can pass using files absent from HEAD. Add `--committed` to run qualifying
  baselines from one archive; normal working-tree reports cannot qualify.
- A PASS with a determinism mismatch is not a passing baseline. Missing,
  malformed, duplicate, stale, or failing baseline rows must not produce success.
- Diagnostics must preserve actual output while evidence hashes keep their
  existing normalization. Print both runs and the normalized diff for a mismatch.
- Baseline fixtures currently invent successful evidence; replace them with
  actual canonical-runner confirmations in self-contained repositories.
- Stock macOS uses Bash 3.2. Avoid associative arrays and preserve the shasum fallback.
- T-181's original macOS failure cannot be diagnosed from discarded output.
  Keep it open; captured diagnostics enable investigation if it recurs.
- T-178's version-literal guard and the broader INT-0007 sweep remain outside scope.
- Independent code review reproduced mutation leakage between suites, improper
  deduplication of distinct suites sharing a subject, and hash/report failures
  returning success. Include these in T-179's evidence-integrity boundary.
- Git Bash requires an explicit `/usr/bin:/bin` PATH in this execution environment.
  The installed shellcheck and Python availability must be resolved for canonical checks.

## 5. Recommended Approach
First preserve runner failure output, then add committed-tree provenance and
strict baseline validation, then remove compatibility shims and publish the
0.22.0 bundle identity and operator guidance. Use synthetic command-level
regressions and the canonical runner for integration. Retain one integrating
writer and independent read-only plan/test critics.

Alternative: re-run each pristine baseline in the sensitivity sweep. This is
stronger but doubles expensive suites; retain the existing report reuse design
with verifiable provenance instead. No caching or language migration is needed.

## Artifacts
- [Build plan](../sprint-plans/build-plan.md)
- [Test plan](../sprint-plans/test-plan.md)
- [Review findings](review.md)
