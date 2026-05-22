# Sprint 9 Test Report

## Summary
Packaged the claude-code bundle as a Claude Code plugin (repo-as-marketplace) to
structurally fix the 4× `/sprint-loop` picker duplication the user hit when
launching from the home directory. All bash-verifiable criteria pass.

## Results
- **Unit (8/8 PASS)** — manifests valid + structurally correct; checker passes on
  good repo and fails (with named messages) on missing-skill and bad-JSON.
- **Integration (3/3 PASS)** — no bundle files moved; selftest still 14/14;
  manifests not gitignored.
- **E2E (1, DEFERRED)** — picker count is a launch-time UI surface; documented as
  the human-verification checkpoint (see e2e-tests.md).

## Root cause (recorded)
`sprint-loop` was the lone *bare personal install* (skill in `~/.claude/skills` +
command in `~/.claude/commands`). Those roots are scanned as both "user" and
"project"; when Claude Code is launched from the home dir they are the SAME
directory, so each surface is enumerated twice → 4 identical entries. Every other
picker entry is plugin-delivered (loaded once from the plugin tree), which is why
only sprint-loop duplicated. The fix matches that delivery model.

## What's deferred / open
- **4 → 2 is guaranteed by plugin delivery; 4 → 1 is not.** Shipping the skill
  AND a same-named command yields up to 2 surfaces. Reaching exactly one entry
  means dropping the command — but that removes the `/sprint-loop continue`
  surface the user drives under `/loop`. Surfaced to the user as a choice rather
  than decided unilaterally (see plan critique C-002).
- Test-critic: see critique note in this sprint's plans dir.

## CI
No GitHub Actions workflow in this repo yet (standing backlog item). Verification
is the local checker + selftest, both green.
