# Sprint 21 Integration Tests

## Line-ending preservation end to end

| Test | Clause | Result |
|------|--------|--------|
| `test_finalize_preserves_uniform_crlf` | WHEN a CRLF plan is locked THEN every line including the prepended header SHALL end in CRLF | pass |
| `test_finalize_preserves_uniform_lf` | WHEN an LF-only plan is locked THEN no line SHALL end in CR | pass |
| `test_runtime_helpers_suite_completes` | (INT-0013 criterion: the runner completes on this host) | pass |

`runtime-helpers.test.sh` reports **37 Book runtime fixtures passed, exit 0**.
It has aborted at its CRLF assertion since sprint 18, leaving roughly 330 lines
of later assertions — every contract-3 gate fixture among them — unexecuted
locally for four sprints.

**What the newly reachable assertions found.** Not a fixture problem. Three
further assertions used the same blind `awk substr` idiom, and once they could
run they exposed a defect in four production scripts:
`abort-sprint.sh`, `close-sprint.sh`, `commit-task.sh` and `remote-adapter.sh`
each decided a file's line endings with `if (sub(/\r$/, "", $0)) ORS="\r\n"`.
That substitution returns 0 on a host whose awk cannot observe a carriage
return, so all four silently rewrote CRLF Book files as LF on Windows. The
decision now comes from the shared primitive and is handed to awk.

This is the case the plan anticipated and asked to be treated as findings rather
than an open-ended repair obligation. It turned out to be in scope: the intent's
criterion is that line-ending detection *anywhere in the corpus* uses a primitive
that can observe a CR, and these four were part of the corpus.

## The sensitivity check against the real corpus

| Test | Clause | Result |
|------|--------|--------|
| `test_full_sweep_reports_no_insensitive_suite` | WHEN the sweep is complete THEN it SHALL report no suite as INSENSITIVE | pass, after one finding |
| `test_sensitivity_leaves_worktree_clean` | WHEN the tool runs THEN the working tree SHALL be unchanged | pass |

Full sweep record: `sensitivity-sweep.md`. Of 21 suites: 13 `sensitive`,
7 `no-subject`, 1 `skipped` (harness-subject).

The first real sweep reported **one INSENSITIVE suite, `merge-policy-test`** —
the mechanism finding something on its first run over the corpus. The suite was
not at fault: the subject mapping written in T-174 named
`tools/check-merge-policy.sh`, which is a sprint-14 compatibility shim that
`exec`s `check-adapter-semantics.sh`. Neutering the shim changed nothing the
suite observes. Mapping corrected to the script the suite actually exercises,
after which it scores `sensitive` and the sweep is clean.

The finding exposed something larger that is **not** fixed here: both
`check-merge-policy.sh` and `check-merge-policy.test.sh` are shims for the
adapter-semantics pair, so the canonical runner has executed
`check-adapter-semantics.sh` and its fixtures **twice on every run since
sprint 14**. With `adapter-semantics-test` measured at 805s, that is a large
share of the wall time T-163 exists to address. Recorded as T-177.
