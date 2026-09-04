# Sprint 21 Build Plan

## Intents
- [INT-0013](../../../intents/INT-0013-verification-integrity.md) — state: planned;
  acceptance criteria covered: the runner completes on Windows/MSYS2 and POSIX CI
  with the same suite set and verdicts; line-ending detection uses a primitive
  proven to observe a CR on every supported host and the fixture uses that same
  primitive; a suite whose subject is replaced by an inert stub fails, checked
  mechanically and reported by name; every negative assertion is paired with
  proof the command ran; no fixture asserts equality against a version
  constant's current literal; the console summary never reports a determinism
  mismatch for a suite whose two runs agreed.

## Schema Tree
- Verification that can fail
  - The operator's machine
    - T-172: one line-ending primitive, used by the code and its fixture
  - The runner's own honesty
    - T-173: the determinism label stops lying
  - A mechanical floor under the suites
    - T-174: the neutered-subject sensitivity check, over a published suite list
  - The two assertion shapes
    - T-175: pair negative assertions; drop version literals
  - Identity and documentation
    - T-176: bundle 0.21.0 and the tool's documented limit

## Execution Sequence

### T-172: Detect line endings with a primitive that can see a carriage return
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- **Touches:** `{open-harnesses,claude-code/skills/sprint-loop,codex-cli/skills/sprint-loop,antigravity-ide}/scripts/book-paths.sh`,
  `.../scripts/finalize-plan.sh`, `.../scripts/runtime-helpers.test.sh`
- **Depends on:** (none)
- **Acceptance criterion:** Line-ending detection anywhere in the corpus uses a
  primitive proven to observe a carriage return on every supported host, and the
  fixture that asserts line-ending preservation uses that same primitive rather
  than one that silently reports every file as LF.
- **Success criterion (EARS):**
  - **WHEN** `book_first_line_is_crlf` is called with a file whose first line
    ends in CRLF, **THEN** it **SHALL** return success, on a host whose `awk`
    cannot observe a carriage return.
  - **WHEN** `book_first_line_is_crlf` is called with an LF-only file, **THEN**
    it **SHALL** return failure.
  - **WHEN** `book_first_line_is_crlf` is called with an empty file, **THEN** it
    **SHALL** return failure rather than reporting an error.
  - **WHEN** `book-paths.sh` is sourced, **THEN** `BOOK_CR` **SHALL** be exactly
    one byte.
  - **WHEN** `finalize-plan.sh` locks a plan whose lines end in CRLF, **THEN**
    every line of the locked plan including the prepended header **SHALL** end
    in CRLF.
  - **WHEN** `finalize-plan.sh` locks an LF-only plan, **THEN** no line of the
    locked plan **SHALL** end in CR.
  - **WHEN** this repository's already-locked plans are audited with the new
    primitive, **THEN** the sprint **SHALL** record how many contain mixed line
    endings, and repair or explicitly accept every file found.
- **Notes:** `IFS= read -r` is the only primitive that observes a CR on the
  affected host; `awk`, `grep -q` and `$(...)` do not, and `grep -c` contradicts
  `grep -q` on the same input. Evidence in
  `../sprint-research/line-ending-probe.txt`. The fixture must check every line,
  not sample the first, because the defect produces a *mixed* file. The audit
  clause closes the research unknown the first draft of this plan dropped
  (C-002): the fix removes the cause, and the audit says whether it already did
  damage worth repairing.

### T-173: Stop the runner mislabelling deterministic failures
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- **Touches:** `tools/run-guards.sh`
- **Depends on:** (none)
- **Acceptance criterion:** The runner's console summary never reports a
  determinism mismatch for a suite whose two runs agreed.
- **Success criterion (EARS):**
  - **WHEN** a suite fails under `--determinism` and its two runs produced the
    same evidence hash and exit code, **THEN** the console line **SHALL NOT**
    contain `det-mismatch`.
  - **WHEN** a suite's two runs disagree under `--determinism`, **THEN** the
    console line **SHALL** contain `det-mismatch`.
- **Notes:** `det` is set to the `"ok"` payload on agreement, so `${det:+…}`
  expands in both directions. The ndjson field is already correct; only the
  human-facing line lies. The suite-list interface the runner also needs
  moved to T-174, its only consumer, so this task carries one observable
  outcome (C-004).

### T-174: Require every suite to fail when its subject is neutered
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- **Touches:** new `tools/check-suite-sensitivity.sh`, new
  `tools/check-suite-sensitivity.test.sh`, `tools/run-guards.sh`
- **Depends on:** (none)
- **Acceptance criterion:** A suite whose subject is replaced by an inert stub
  fails. This is checked mechanically for every suite in the runner's list, and
  a suite that still passes against a neutered subject is reported by name.
- **Success criterion (EARS):**
  - **WHEN** the tool runs against a suite whose subject has been replaced by a
    stub that exits 0 and prints nothing, and the suite still passes, **THEN**
    the tool **SHALL** report that suite as `INSENSITIVE` by name and **SHALL**
    exit non-zero.
  - **WHEN** every scored suite fails against its neutered subject, **THEN** the
    tool **SHALL** exit 0.
  - **WHEN** a suite has no subject script, **THEN** the tool **SHALL** report
    it as `no-subject` and **SHALL NOT** count it as a failure.
  - **WHEN** the supplied guard report records a suite's baseline status as
    anything other than PASS, **THEN** the tool **SHALL** report that suite as
    `skipped:baseline-not-pass` and **SHALL NOT** score it.
  - **WHEN** the tool runs, **THEN** it **SHALL NOT** modify any file under the
    repository working tree.
  - **WHEN** suite names are supplied as arguments, **THEN** the tool **SHALL**
    score only those suites.
  - **WHEN** `run-guards.sh --list-suites` is invoked, **THEN** it **SHALL**
    print every suite name in the runner's list, one per line, and exit 0
    without running any suite.
  - **WHEN** `run-guards.sh --list-subjects` is invoked, **THEN** it **SHALL**
    print one `<suite>` and `<subject-path>` pair for every suite that has a
    subject script, and **SHALL** omit suites that are their own subject.
- **Notes:** Prototyped during planning: copy the repository (`git archive HEAD`
  extracted to a temp directory) so root resolution stays faithful, then replace
  the subject in the copy. A scripts-only copy breaks the `tools/` suites' root
  resolution and would have scored three of them "sensitive" for the wrong
  reason. The baseline comes from `guards-report.ndjson` rather than a per-suite
  control run, because one suite already exceeds 120 s and doubling the runner
  is what T-163 exists to avoid. `suite_subject()` and the two listing flags live
  in `run-guards.sh` and are owned by this task, so the suite list has exactly
  one definition and this tool cannot drift from it.

### T-175: Pair every negative assertion with proof the command ran
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- **Touches:** `{4 bundles}/scripts/*.test.sh`, `tools/*.test.sh` excluding
  `tools/operator-docs.test.sh`, which T-176 owns
- **Depends on:** T-172, T-174
- **Acceptance criterion:** Every fixture asserting that something did not
  change is paired, in the same fixture, with proof that the command under test
  actually ran and succeeded; and no fixture asserts equality against a version
  constant's current literal value.
- **Success criterion (EARS):**
  - **WHEN** a fixture asserts that a file, branch or setting did not change,
    **THEN** that fixture **SHALL** also assert that the command under test
    exited successfully.
  - **WHEN** a fixture depends on the substrate contract version, **THEN** it
    **SHALL** assert the relationship it needs against
    `BOOK_SUBSTRATE_CONTRACT_VERSION` rather than that constant's current
    literal value.
  - **WHEN** the sweep is complete, **THEN** the sensitivity check from T-174
    **SHALL** report no suite as `INSENSITIVE`.
- **Notes:** 51 negative assertions across nine suites; `deploy-substrate`
  carries 26. Generalize the existing `assert_check_ran_quietly`
  (`deploy-substrate.test.sh:385`); follow the repaired `check-tracked.test.sh:82`
  form for the version relationship.

### T-176: Record the bundle's identity and the check's documented limit
- **Intent:** [INT-0013](../../../intents/INT-0013-verification-integrity.md)
- **Touches:** `README.md`, `{4 bundles}/scripts/bundle-version.sh`,
  `claude-code/.claude-plugin/plugin.json`, `tools/operator-docs.test.sh`
- **Depends on:** T-174
- **Acceptance criterion:** Supports the sensitivity criterion by making the
  check discoverable and its scope honest.
- **Success criterion (EARS):**
  - **WHEN** an operator reads the README's verification section, **THEN** it
    **SHALL** state that the sensitivity check proves a suite is coupled to its
    subject and does not prove the suite would detect a subtly wrong answer.
  - **WHEN** `bundle-version.sh` is invoked in any bundle, **THEN** it **SHALL**
    report `0.21.0`, and the plugin manifest **SHALL** agree.
- **Notes:** No substrate contract raise — nothing here binds a new gate on an
  existing project, so `substrate-version` stays at 4.
