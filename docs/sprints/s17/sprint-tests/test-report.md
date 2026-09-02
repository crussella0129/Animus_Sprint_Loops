# Sprint 17 Test Report

**Verdict: PASS with caveats.** Every acceptance criterion of
[INT-0004](../../../intents/INT-0004-substrate-contract-versioning.md) has an
executed, named test, and the authoritative confirmation is green on both CI
legs. Five critique concerns are recorded, one of which was discharged by that
CI result; the other four are deferred with rationale and two become
carry-forward work.

## Authoritative confirmation

| Field | Value |
|---|---|
| Tested head SHA | `21deff426d216754902aee82a4ae14512df10fb2` |
| Workflow | `guards` |
| Run | [33662373769](https://github.com/crussella0129/Animus_Sprint_Loops/actions/runs/33662373769) |
| Conclusion | **success** |
| `guards (ubuntu-latest)` | success |
| `guards (macos-latest)` | success |

CI runs the same entry point the local Test phase runs —
`bash tools/run-guards.sh --determinism` — so the two cannot drift. On the CI
matrix all 16 suites pass, including `selftest`, which is the suite that fails
locally for the platform-specific reason below.

## Local canonical run

`bash tools/run-guards.sh --determinism --out guards-report.ndjson`:
**15/16 PASS**, and **every suite recorded `"determinism":"ok"`** — both runs of
each suite produced identical normalized evidence hashes and identical exit
codes. No suite was flagged nondeterministic.

The single local failure is `selftest`, inside `runtime-helpers.test.sh`:

```text
runtime-helpers.test: FAIL: finalization did not preserve uniform CRLF in build-plan.md
```

This is backlog defect **T-121**, not a regression. It reproduces byte-identically
from an unmodified `0f8f35d` checkout — the sprint-16 close, before any sprint-17
work — and from this sprint's head. Windows/MSYS2 GNU awk strips a trailing `\r`,
so `finalize-plan.sh`'s CRLF detection misclassifies a CRLF plan. It does not
reproduce on POSIX, which is why the CI conclusion above is authoritative and why
the phase contract asks for it.

## Intent acceptance criteria

| INT-0004 acceptance criterion | Evidence | Result |
|---|---|---|
| Converges in one command | `test_converge_stamps_unstamped_book`, `test_converge_verifies_after_stamp`, repository self-convergence | PASS |
| Second run changes nothing and reports the no-op | `test_deploy_idempotent`, `test_converge_idempotent`, `test_converge_check_is_readonly` | PASS (see C-003) |
| Failure at any step rolls back | `test_converge_rolls_back_stamp`, `test_deploy_rolls_back`, `test_deploy_rollback_preserves_preexisting` | PASS (see C-001) |
| Un-converged Book routes byte-identically | `test_routing_unchanged_for_unstamped_book` plus the whole unstamped `book-routing` phase walk | PASS |
| Four substrate states distinguished | `test_substrate_complete_when_versions_match`, `…_outdated_when_book_behind`, `…_partial_outranks_version`, `test_substrate_absent` | PASS |
| Marker parsed unchanged in all four bundles | `test_marker_v2_survives_version_key` + `bundle-sync` byte parity | PASS |
| Ahead Book refused, naming both versions | `test_substrate_ahead_when_book_newer`, `test_converge_refuses_ahead_book` | PASS |
| Bundle version recorded in every install mode | `test_init_records_bundle_version` (no plugin manifest present), `test_manifest_requires_version`, `test_manifest_version_must_match_bundle` | PASS |

Negative paths are covered directly rather than by implication: malformed,
zero-valued, and duplicated stamps; an ahead Book; a missing version helper;
multi-line helper output; a missing manifest field; a mismatched manifest
version; and an injected mid-convergence failure.

## What the sprint proved about itself

This repository is a Sprint Loops project, so the sprint upgraded its own
substrate as the E2E case: `substrate-outdated:1->2` → `--check` naming exactly
one pending step and writing nothing → convergence → `substrate-complete`, with
a one-line diff, a byte-identical re-run, and `current-phase.sh` reporting the
same phase before and after.

## Caveats carried into Loop

- **C-001** — "rolls back at *any* step" is exercised at two of five injection
  points; the other three are strict subsets of the same rollback function.
  Deferred, recorded as carry-forward.
- **C-005** — `run-guards.sh` prints `det-mismatch` for *any* failing suite in a
  `--determinism` run, because `${det:+ …}` tests whether the field is set rather
  than whether it mismatched. The recorded ndjson confirmation is correct; only
  the console summary is wrong. Deferred as out of scope for locked plans,
  recorded as carry-forward.
- **C-003**, **C-004** — deferred with rationale, no follow-on work.
- **`test_installed_bundle_parity`** — cannot pass until the Sprint 17
  checkpoint merges and the operator runs `/plugin update sprint-loop`, because
  the plugin cache pins a commit. Recorded as a post-merge human-verification
  item rather than claimed.

## Verdict

Pass. Final critique verdict: `proceed-with-caveats`.
