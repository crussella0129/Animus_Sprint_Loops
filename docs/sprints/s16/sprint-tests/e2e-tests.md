# Sprint 16 End-to-End Test Results

- **Published test-hardened head:** `026d6faffeba53c87db2610202e4da865304ede2`
- **Implemented-path result:** 2 passed / 0 failed / 2 executed.
- **Post-checkpoint result:** 2 pending by design; M-001 is gated on a human-approved `dev → main` merge.

## Executed

### `test_fresh_hosted_project_two_branch_flow` — pass

An ephemeral GitHub-profile project was exercised through the installed Codex
runtime as one chain:

1. `deploy-substrate.sh` created an exact `main`/`dev` branch set and a
   create-if-absent Dependabot config targeting `dev`.
2. The installed router reported `research`; synthetic locked plans, completion
   evidence, test results, critique, and report advanced it to `loop`; closing
   the sprint advanced it to `ready-for-next-sprint`.
3. A local bare origin plus a `gh` provider stub observed exactly one
   `--head dev --base main` create call. A second adapter call detected the open
   checkpoint and created none.

Confirmation:
`fresh-hosted-e2e: deploy main/dev -> route research/loop/ready -> one dev/main checkpoint: PASS`.

### `test_canonical_guards_deterministic` — pass

The canonical runner executed every registered suite twice. The retained
[guards-report.ndjson](guards-report.ndjson) contains 15 unique confirmations,
all `status: PASS` and all `determinism: ok`; shellcheck used version 0.11.0.
That file byte-matches the Ubuntu artifact from
[guards #31245249580](https://github.com/crussella0129/Animus_Sprint_Loops/actions/runs/31245249580),
which succeeded on both Ubuntu and macOS at the exact published head.

## Post-Loop Checkpoints (not yet executable)

### `test_post_merge_remote_preconditions` — pending

The current default branch is still `eb1cb385...`, so it does not yet contain
the v2 profile, Dependabot `dev` target, `dev` PR CI coverage, or the carried
Actions v7 payload. The test unlocks only after the Sprint 16 PR is green and a
human approves its merge. No deletion is attempted before those assertions pass.

### `test_post_merge_remote_topology` — pending

M-001 must first resync merged `main → dev` and receive explicit authority to
delete the local and remote retired branch. The final read-only assertion will
require remote long-lived branches exactly `main`/`dev`, both containing the
migration payload, and no open PR naming the retired branch. INT-0003 remains
`active` until this observable checkpoint passes.
