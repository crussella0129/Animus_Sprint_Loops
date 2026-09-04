# Sprint 22 plan review resolutions

The independent read-only critic initially blocked locking for two reasons:

1. A clean tracked tree could depend on untracked files missing from the archive.
   Resolved with committed-archive baselines and test_untracked_dependency.
2. Mutation state accumulated across suites. Resolved with mandatory restoration,
   reversed-order cross-dependency fixtures, and independent shared-subject verdicts.

A second review accepted those changes but identified missing capture-error
verification. Resolved with test_capture_failure, injecting temporary-allocation
failure and checking nonzero exit, diagnostic, absence of PASS, and no execution.

The final verdict is recorded separately in critique.md.
