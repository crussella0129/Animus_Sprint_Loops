# Sprint 22 integration verification

Full-run head: `dbc2a833b8b544d7f5550801ee98c979f2a60bd4`.
Final assertion-strengthening head: `7545986097d804db20737fbf4846e0c35c2abf5c`.

## Executed targeted checks
- Windows Git Bash: `run-guards.sh --determinism` with `run-guards-test` and
  `suite-sensitivity` passes 2/2; both confirmations have `determinism:ok`.
- Linux: canonical `run-guards-test`, `adapter-semantics`, and
  `adapter-semantics-test` pass 3/3 after the duplicate aliases were removed.
  The retained adapter fixture took 186 seconds in this targeted run.
- Linux: canonical `operator-docs`, `plugin-manifest`, and `bundle-sync` pass
  3/3 for version 0.22.0.
- Linux: the `shasum` backend passes the canonical runner fixture suite, as
  does the default `sha256sum` backend.
- ShellCheck 0.11.0 passes the changed runner, sensitivity, fixture, guidance,
  and bundle-version scripts. No project dependency was added for linting.

## Full committed-source check
The complete canonical runner passed **19/19 suites** with `--committed
--determinism`; every row reports `PASS` and `determinism:ok`. Recorded suite
durations total 1,218 seconds. Source tree:
`a0ca17496fa973db13f73dee2b3477ce340af9c9`.
The adapter mutation fixtures passed all 57 cases in each run.
Evidence: [full Linux confirmations](guards-linux.ndjson),
[initial Windows confirmations](guards-windows-initial.ndjson),
[portable shasum confirmation](guards-shasum.ndjson).

The test critic requested stronger assertions after this run. Commit `7545986`
changes only the two fixture files; runtime code and unrelated suites are
unchanged. Final targeted determinism runs cover both changed suites and Linux
shell lint. Linux passes **3/3** with every determinism verdict `ok`:
[final Linux confirmations](guards-linux-final.ndjson). Windows passes **2/2**
with both determinism verdicts `ok`:
[final Windows confirmations](guards-windows-final.ndjson).

## Platform boundary
These are local Windows Git Bash and Ubuntu WSL confirmations. Hosted CI is
configured but has not run for the unpushed implementation. No macOS result is
claimed; T-181 remains open. ShellCheck ran from a temporary local extraction,
using the same command and warning threshold as the canonical CI suite.
