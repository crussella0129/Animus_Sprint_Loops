# Sprint 12 E2E Tests

- **Status:** possible

## test_ci_matrix_e2e — PASS

Pushed `sprint-12`; the `guards` workflow ran ONE run with TWO matrix jobs.

Authoritative verification (per phase-05 CI pattern):

- **Head SHA:** `c76d73b486f8db087f55571ada52f533a0e43d49`
- **Run:** 28694240195 — https://github.com/crussella0129/sprint-loops/actions/runs/28694240195
- **Run conclusion:** `completed` / **`success`**
- **Per-job (gh run view --json jobs):**
  - `guards (ubuntu-latest)` → **success**
  - `guards (macos-latest)` → **success**
- **Artifacts:** `guards-report-ubuntu-latest` (891 B) and `guards-report-macos-latest` (903 B) — 7 confirmations each.

**The macos job is the sprint's core proof:** on BSD userland with macOS bash,
the canonical runner executed all 7 suites — selftest's 15 transitions (which
drive the rewritten portable abort-sprint.sh and the awk back-fill end-to-end
inside a real git repo), both fixture tests, the plugin-manifest check,
bundle-sync across all four bundles, and shellcheck — twice each under
`--determinism`, with every suite `"determinism":"ok"`, on a host where the
shasum fallback is the expected auto-detect path (which tool auto-detect
actually selected is not recorded in the run evidence — the shasum path's
correctness is proven by the seam test `test_hash_fallback`; noted per
test-critique C-002). Portability is now continuously observed on every
push, not assumed.

**E2E totals: 1 passed / 0 failed / 1 total.**
