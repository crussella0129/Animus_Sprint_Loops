# Latest-version review — Sprint 22

Reviewed baseline: `d765e33cf402b37d118069b9d6b2e597df8170f3`.

- **P1 / correctness — mutation leaks between suites.** Independent review
  reproduced an insensitive second suite scoring sensitive because the first
  subject remained neutered in the shared copy. Restore after every run,
  including unscorable paths; verify order independence.
- **P1 / correctness — infrastructure failures report success.** A failing
  hash backend produces empty hashes and PASS; failed confirmation appends are
  ignored. Require successful capture, hashing, and writes before confirming.
- **P2 / correctness — subject deduplication skips distinct tests.** Two
  suites may legitimately test one subject. A sensitive suite cannot establish
  that its sibling is sensitive; score each independently after removing shims.

- **P1 / correctness — stale sensitivity evidence (T-179).**
  `baseline_status()` reads only status. A historical PASS can qualify a changed
  test or broken subject at HEAD as sensitive. A `status:PASS` row with
  `determinism:mismatch` also qualifies, and an absent/nonpassing baseline can
  lead to a successful zero-scored sweep. Bind results to the actual source.
- **P2 / maintainability — discarded failure diagnostics (T-180).**
  `run_once()` removes captured output before the runner decides what failed.
  The console and CI artifacts cannot explain the assertion that failed.
  Preserve and print failure output, and both outputs plus a normalized diff
  when determinism disagrees.
- **P2 / performance — duplicate compatibility suites (T-177).**
  The merge-policy entries execute the adapter-semantics pair a second time.
  The canonical names already exist; remove the shims and their registrations.

Security: no new external-service or credential handling is needed for these
changes. Temporary mutation remains confined to repository copies.
Correctness needs improvement in baseline validation; performance has the
specific redundant work above; diagnostics currently impede maintainability.
The shared adapter parity guard, Book evidence gates, and synthetic runner
fixture seam provide useful foundations for making these changes safely.

## Sprint resolution
| Finding | Resolution | Verification |
|---------|------------|--------------|
| Stale baselines | T-179: committed-archive mode, tree/suite hashes, strict confirmation validation | Baseline integrity, source provenance, untracked dependency fixtures |
| Mutation leaks | T-179: restore each subject before any verdict or continuation | Cross-dependent suites together, separately and in reversed order |
| Shared-subject deduplication | T-179: score each distinct suite | Sensitive and insensitive siblings against the same subject |
| Infrastructure success on failure | T-179: require capture, hash, and append success | Fault-injected capture/hash/report-write fixtures |
| Discarded diagnostics | T-180: retained captures, both mismatch runs, normalized diff | Failure, mismatch and second-run-only failure fixtures |
| Duplicate compatibility checks | T-177: remove shims and registrations | Inventory and canonical adapter regression suite |

The implementation review found one additional portability defect in the new
containment check: a physical subject path was compared with a lexical temp
root. Commit `5dcac0a` canonicalizes the temp root before deriving paths. Added
trailing-slash, parent-component and symlink-root fixtures pass on Linux; the
independent reviewer confirmed the fix with no further findings.

See [unit evidence](../sprint-tests/unit-tests.md) and
[integration evidence](../sprint-tests/integration-tests.md) for executed checks.
