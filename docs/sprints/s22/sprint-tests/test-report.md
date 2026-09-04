# Sprint 22 Test Report

## Intent Verification
| Intent | Acceptance criterion | EARS / tests | Result | Intent evidence update |
|--------|----------------------|--------------|--------|------------------------|
| [INT-0013](../../../intents/INT-0013-verification-integrity.md) | Truthful, actionable failures and stable evidence | T-180 / failure, mismatch, second-run failure and known normalized digest fixtures | pass | This report attached; intent remains active |
| INT-0013 | Current committed baselines and independent mutations | T-179 / source provenance, invalid baseline, cross-dependent/shared-subject and contradictory confirmation fixtures | pass | Code and completion evidence retained |
| INT-0013 | Infrastructure errors cannot become PASS | T-179 / hash, capture and report-write fault injection | pass | This report attached |
| [INT-0007](../../../intents/INT-0007-integrity-sweep.md) | Remove known vestigial compatibility entries | T-177 / inventory and canonical adapter regression suite | pass for scoped cleanup | Intent remains active; computed sweep outstanding |
| INT-0013 | Correct guidance and consistent bundle identity | T-182 / operator-docs, plugin-manifest and bundle-sync | pass | Bundle version 0.22.0 |

## Summary
- Final focused Linux fixtures: 13 runner tests and 17 sensitivity tests pass.
- Full Linux canonical run: 19/19 suites pass under `--committed --determinism`;
  every determinism verdict is `ok`.
- After test-only assertion improvements: final Linux targeted run passes 3/3
  (both changed suites plus shell lint), and final Windows run passes 2/2;
  all determinism verdicts are `ok`.
- Real-repository E2E: the current committed report qualifies; the same report
  is refused after a source-tree change in an isolated clone.
- CI status at local Test exit: configured, not yet run for these unpushed
  commits. The checkpoint's hosted checks are a separate confirmation.
- Final independent test critique: clean. Earlier concerns and their fixes are
  recorded in [critique history](critique-history.md).

## Confirmation Provenance
- **Full-run head:** `dbc2a833b8b544d7f5550801ee98c979f2a60bd4`.
- **Full-run tree:** `a0ca17496fa973db13f73dee2b3477ce340af9c9`.
- **Final fixture head:** `7545986097d804db20737fbf4846e0c35c2abf5c`.
- Only the two fixture files changed between those heads; the full runtime
  implementation was unchanged. Final targeted checks cover both changed files.
- **Full Linux confirmations:** [19-suite report](guards-linux.ndjson).
- **Final confirmations:** [Linux](guards-linux-final.ndjson),
  [Windows Git Bash](guards-windows-final.ndjson).
- **Portable hash backend:** [shasum result](guards-shasum.ndjson).
- **E2E observations:** [current](sensitivity-current.txt),
  [stale](sensitivity-stale.txt).
- **Hosted CI conclusion:** none claimed at local close; see the checkpoint
  PR's checks after publication. Local Ubuntu WSL is not a macOS confirmation.

## Failures
No final test failures. The critic identified three assertion weaknesses after
the full run; commit `7545986` addresses them with exact digest expectations,
complete per-suite verdict assertions, and contradictory-confirmation rejection.
Those improvements passed the final targeted checks on both platforms.

## Technical Debt Identified
- T-178 remains open: mechanical prevention of version-literal assertions.
- T-181 remains open: the historical macOS nondeterminism was not reproduced or
  diagnosed here. Its duplicate suite alias is retired and future failures now
  preserve diagnostics.
- INT-0007 remains active: this sprint removes known vestigial entries but does
  not implement the planned computed sweep.

## Coverage Observations
The sensitivity mechanism establishes coupling, not general correctness.
Reports from ordinary working-tree runs cannot qualify as baselines. Committed
source-tree changes, including Book changes, require a fresh qualifying report.
The directory-symlink fixture may explicitly skip on hosts unable to create
real symlinks; Linux executed it successfully.
