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
