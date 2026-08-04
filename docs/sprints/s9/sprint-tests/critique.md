# Sprint 9 Test Critique

> Critic subagent unavailable (API 529 Overloaded, repeated). Per protocol
> fallback, an inline adversarial pass was run that EXERCISED false-pass attempts
> against `tools/check-plugin-manifest.sh` rather than asserting coverage.

## Concerns
- **Every EARS clause has a real, executed assertion** (verified, not claimed):
  marketplace name/plugin-entry/source, plugin.json name, source→SKILL.md
  resolution. Adversarial mutations all caught: plugin.json name wrong (ADV-1),
  source = "./foo" (ADV-4), no sprint-loop entry (ADV-6), source dir missing
  (ADV-2), plugin.json absent (ADV-3), corrupt JSON. No false-pass observed.
- **One harness self-bug found and fixed mid-test:** initial adversarial cases
  used `$T` unexported to the python child, so two mutations silently no-op'd and
  reported spurious "false-pass". Re-run with `T="$T" python3` confirmed the
  checker catches them. (Lesson echoes sprint 3/8: verify the test actually
  mutates before trusting a PASS.)
- **Deferred E2E is honest:** picker count is a launch-time UI surface, not
  bash-observable; documented with an exact reproduce procedure (e2e-tests.md).
- **Open (carried, not a test gap):** 4→2 guaranteed, 4→1 needs dropping the
  command — surfaced to the user as a choice (plan critique C-002).

## Confidence
clean — no false-pass under adversarial mutation; coverage is real and the only
unverifiable item (picker count) is correctly deferred to human verification.
