# Sprint 20 Unit Tests

- **Tested head SHA:** recorded in `test-report.md`

## T-164 — language detection
New `detect-languages` suite, 9/9.

| Test | Clause | Result |
|---|---|---|
| `test_detect_rust`, `test_detect_go`, `test_detect_node` | a project with only that manifest prints only that token | PASS |
| `test_detect_python` | each of `pyproject.toml`, `requirements.txt`, `setup.py` yields `python`; two of them yield it once | PASS |
| `test_detect_shell` | a **tracked** `*.sh` yields `shell`; an untracked one does not | PASS |
| `test_detect_polyglot` | five manifests → five tokens, one per line, sorted | PASS |
| `test_detect_empty_project` | no manifests → no output, exit 0 | PASS |
| `test_detect_is_deterministic` | two runs are byte-identical | PASS |
| `test_detect_canonical_runner` | a project with `tools/run-guards.sh` also prints the canonical token, and it does not reorder the languages | PASS |

Preferring git's index for shell detection is the substantive choice: a
`find`-based check would let an untracked scratch file decide that a project is
a shell project, and generate a job for it.

## T-165 — the generator
New `scaffold-ci` suite, 9/9.

| Test | Clause | Result |
|---|---|---|
| `test_scaffold_paths_per_provider` | five hosts → five correct paths, and `generic`'s `ci.sh` is executable | PASS |
| `test_scaffold_local_only_writes_nothing` | the file listing is unchanged | PASS |
| `test_scaffold_refuses_existing_workflow_dir` | a non-empty workflow directory → nothing written, the existing file byte-identical, and a message saying so | PASS |
| `test_scaffold_triggers_name_both_branches` | `trunk`/`working` appear in **both** the push and pull_request triggers, and in both GitLab branch rules | PASS |
| `test_scaffold_jobs_match_detection` | a Rust-only project has a rust job running `cargo test` and no node job; a polyglot project has one job per language | PASS |
| `test_scaffold_uses_canonical_runner` | the canonical token produces one job invoking the runner and no per-language jobs | PASS |
| `test_scaffold_is_byte_stable` | identical inputs produce identical files | PASS |
| `test_scaffold_generic_ci_actually_fails` | the generated `ci.sh` **executes**: a clean project passes it, a project with a broken script fails it | PASS |
| `test_scaffold_python_tolerates_no_tests` | the generated Python step accepts exit 5 and contains no `\|\| true` and no `continue-on-error` | PASS |

Non-default branch names in the trigger fixture are deliberate: `main`/`dev`
would pass even if the generator hardcoded them.

**Two fixture defects were found and fixed during the task.** The executable
proof originally used a `package.json` whose contents were the literal word
`fixture`, so `npm install` failed for a reason unrelated to the assertion — it
now uses shell, which the guard suite already requires. And a leftover no-op
branch broke shellcheck outright.

## T-166 — CI as a convergence step
`deploy-substrate` suite.

| Test | Clause | Result |
|---|---|---|
| `test_converge_generates_ci` | a fresh GitHub project with no flags gets an inferred provider, an updater config, and a workflow with a rust job and both branches | PASS |
| `test_converge_generates_ci_after_stamp` | the marker ends at contract 4, pinning the step's position after the stamp | PASS |
| `test_converge_ci_idempotent` | a second convergence leaves every file and every git ref byte-identical | PASS |
| `test_converge_rolls_back_ci` | `DEPLOY_SUBSTRATE_FAIL_AFTER=ci` → the generated file is gone | PASS |
| `test_check_reports_pending_ci` | `--check` names the pending file and writes nothing | PASS |
| `test_hand_written_ci_survives` | a full convergence leaves an existing workflow directory byte-identical while completing everything else | PASS |
| `test_converge_local_only_gets_no_ci` | no workflow, no `.gitlab-ci.yml`, no `ci.sh` anywhere | PASS |

The ordering test exists because the first implementation got it wrong: the step
was wired *before* the stamp, so a fresh project read contract 1 and generated
nothing, and an upgrading project would have seen CI only on a second
convergence. See the plan deviation recorded in T-166's completion entry.

## T-167 — the operator contracts
`operator-docs` suite, 8/8, and `adapter-semantics`.

| Test | Clause | Result |
|---|---|---|
| `test_init_documents_ci_generation` | all three Init surfaces name the workflow directory, `.gitlab-ci.yml`, `ci.sh`, and `local-only`; the README carries the never-touched and permanent-deletion statements | PASS |
| `adapter-semantics` | every adapter authority and runtime contract still holds | PASS |

The assertion against the Antigravity workflow initially failed because the
phrase it searched for was split across a line break — correct prose, failing
`grep -F`. It now targets a token that sits on one line, which is a constraint
worth remembering for every prose assertion in this suite.
