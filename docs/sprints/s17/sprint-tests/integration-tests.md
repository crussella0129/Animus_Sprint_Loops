# Sprint 17 Integration Tests

Composed behavior across tasks, where a defect would appear only when two or
more of them are present together.

## `test_converge_round_trip` — T-137 + T-138 + T-139
**Status:** PASS

The full state machine over one fixture project, in
`deploy-substrate.test.sh`:

1. A complete Book is reset to contract version 1 (an older bundle's output).
2. `check-substrate.sh` reports `substrate-outdated:1->2` and exits non-zero.
3. `deploy-substrate.sh` converges: it stamps, then its own final verification
   observes `substrate-complete` and it exits 0 with the success line.
4. `check-substrate.sh` reports `substrate-complete` and exits 0.
5. A second convergence leaves every file and every git ref byte-identical.
6. `--check` then reports `converged (no pending steps)` and exits 0.

This is the composition the plan critic's C-002 identified as the sprint's real
risk: the stamp reads correct in isolation but, ordered after the final verify,
would fail convergence on exactly the projects it exists to upgrade. Step 3 is
the assertion that the ordering is right.

## `test_bundle_identity_reaches_sprint_record` — T-140 + T-141
**Status:** PASS

`test_init_records_bundle_version` initializes a sprint in a fixture that
contains **no `.claude-plugin/` directory at all** — the manual-install mode
from research F7 — and asserts the resulting `sprint-meta.md` carries exactly
one `- **Bundle version:**` field whose value equals the co-located
`bundle-version.sh` output. Together with the manifest-agreement fixtures in
`check-plugin-manifest.test.sh`, this closes the chain from the bundle's own
declaration to the sprint record, in both install modes.

## `test_routing_unchanged_for_unstamped_book` — backwards-compatibility regression
**Status:** PASS

The whole of `book-routing.test.sh` is the regression: every fixture in it
initializes a Book that is never stamped, and the entire phase walk
(`research → plan → build → test → loop → ready-for-next-sprint`), the
scaffold-only refresh, the legacy-only refusal, and the split-brain refusal all
assert the same tokens they asserted before this sprint. The named test asserts
the property directly rather than relying on that implication: it verifies the
fixture marker carries no `substrate-version` line, routes it, and re-verifies
that routing did not write one.

The `substrate-version` key is therefore invisible to routing in both
directions — an unstamped Book routes normally, and routing never stamps.

## Cross-bundle integration
**Status:** PASS

`check-bundle-sync.sh` and its 18-fixture test confirm the four bundles carry
byte-identical `scripts/` and `schemas/` sets after this sprint's additions,
including the new `bundle-version.sh` and its `REQUIRED_SCRIPTS` entry, and that
the two byte-parity phase contracts still match. The suite the local Test phase
runs and the suite CI runs are the same script, so they cannot diverge.
