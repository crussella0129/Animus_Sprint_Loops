# Sprint 22 end-to-end verification

Full-run head: `dbc2a833b8b544d7f5550801ee98c979f2a60bd4`.
Final fixture head: `7545986097d804db20737fbf4846e0c35c2abf5c`.

## Fixture-repository workflow — PASS
The sensitivity fixtures build real Git repositories containing the canonical
runner, sensitivity checker, subject scripts, and suites. Baselines are produced
by `run-guards.sh --committed`, then consumed through archive extraction,
mutation, runner execution and confirmation validation. Linux executes all 17
fixtures; the final Windows runner also passes its sensitivity suite twice.

Coupled/uncoupled controls prove opposite verdicts. Committing a changed subject
invalidates a real prior report without changing the suite script. Untracked
dependencies cannot qualify. Two cross-dependent suites score consistently in
both orders and separately, and two suites sharing a subject both receive
verdicts. Harness exits without confirmations are explicitly unscorable.

## Real repository workflow
The full canonical report at `dbc2a83` was accepted by the actual
`suite-sensitivity` check, which reported the suite sensitive with exit 0.
After strengthening fixtures, the final targeted report at `7545986` was also
accepted: [current-source result](sensitivity-current.txt). An isolated local
clone then committed an additional file; the same report was refused with
`baseline-source-mismatch`, exit 1, and an unscorable verdict:
[stale-source result](sensitivity-stale.txt). The real working tree was unchanged.
