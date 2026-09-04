# Sprint 22 test review resolutions

The independent test critic blocked the initial evidence for three concrete
assertion weaknesses. All were addressed in test-only commit `7545986`:

- **C-001:** Stable evidence hashes were not asserted directly. Added fixed,
  independently computed SHA-256 expectations for `steady\n` and normalized
  output, with Linux/macOS temp-path, timestamp and CR variations.
- **C-002:** Multi-suite fixtures only required B's verdict. Added exactly-one
  correct verdict assertions for every selected suite, in both orders and each
  individual control, for both cross-dependent and shared-subject cases.
- **C-003:** Mutation error fixtures had no populated contradictory row. Added a
  valid PASS confirmation paired with harness exit 1; it must be unscorable,
  with no scored verdict.

Runtime implementation remains identical to the full 19-suite deterministic
pass at `dbc2a83`. Final targeted confirmations at `7545986` rerun the changed
fixtures and shell lint. The final critic verdict is recorded in critique.md.
