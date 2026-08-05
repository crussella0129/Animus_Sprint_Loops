# Sprint 2 — Integration Tests

| Test | Method | Result |
|------|--------|--------|
| `test_install_then_selftest` | `HOME=$TH bash claude-code/install.sh` → run `$TH/.claude/skills/sprint-loop/scripts/selftest.sh` | **PASS** — installed bundle's selftest exits 0 with all transitions matched. (At Build-Phase time the personal install copied still ran the 9-step selftest; once T-003 sync landed, both bundles plus the in-repo source all report 10/10.) |

**Totals: 1 passed / 0 failed / 1 total.**
