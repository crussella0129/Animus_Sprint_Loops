Sensitivity sweep — Sprint 21 (T-174 / T-175)

Baseline: guards-report.ndjson (21/21 PASS under --determinism).
Command:  bash tools/check-suite-sensitivity.sh --report <baseline>

SUITE                    VERDICT        SUBJECT
------------------------ -------------- -------
selftest                 no-subject     (is its own subject)
merge-policy             no-subject     (is its own subject)
merge-policy-test        INSENSITIVE    tools/check-merge-policy.sh
plugin-manifest          no-subject     (is its own subject)
plugin-manifest-test     sensitive      tools/check-plugin-manifest.sh
bundle-sync              no-subject     (is its own subject)
bundle-sync-test         sensitive      tools/check-bundle-sync.sh
adapter-semantics        no-subject     (is its own subject)
adapter-semantics-test   sensitive      tools/check-adapter-semantics.sh
operator-docs            no-subject     (is its own subject)
remote-profile           sensitive      claude-code/skills/sprint-loop/scripts/remote-profile.sh
check-substrate          sensitive      claude-code/skills/sprint-loop/scripts/check-substrate.sh
check-tracked            sensitive      claude-code/skills/sprint-loop/scripts/check-tracked.sh
detect-languages         sensitive      claude-code/skills/sprint-loop/scripts/detect-languages.sh
scaffold-ci              sensitive      claude-code/skills/sprint-loop/scripts/scaffold-ci.sh
deploy-substrate         sensitive      claude-code/skills/sprint-loop/scripts/deploy-substrate.sh
remote-adapter           sensitive      claude-code/skills/sprint-loop/scripts/remote-adapter.sh
sync-work-branch         sensitive      claude-code/skills/sprint-loop/scripts/sync-work-branch.sh
run-guards-test          skipped        harness-subject (scored by its own fixtures)
suite-sensitivity        sensitive      tools/check-suite-sensitivity.sh
shellcheck               no-subject     (is its own subject)

check-suite-sensitivity: these suites PASS with their subject neutered: merge-policy-test
  each is asserting something that does not depend on the script it tests
SWEEP_EXIT=1

RESOLUTION of the one INSENSITIVE verdict:
  merge-policy-test's declared subject was tools/check-merge-policy.sh, but that
  file is a sprint-14 compatibility shim that execs check-adapter-semantics.sh.
  Neutering the shim changed nothing the suite observes. The subject mapping was
  wrong, not the suite: corrected to tools/check-adapter-semantics.sh, after which
  the suite scores 'sensitive'. The duplication the finding exposed — the runner
  executing check-adapter-semantics.sh and its fixtures twice per run since
  sprint 14 — is recorded as T-177, not fixed here.

Re-score after the correction:
merge-policy-test        sensitive      tools/check-adapter-semantics.sh
