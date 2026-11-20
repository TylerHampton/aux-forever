# Test results from Claude's test pages

- `test-page-results.md`: every answer Tyler saved on Claude's claude.ai test page, build by build
  (0.6 build 4 to 0.8.2.2 build 2), exported on 2026-11-19 when the project passed to Gemini Neon.
  Screenshots are not included (they show game chat and characters; this repository is public).
- `claude-test-page-template.html`: the page itself, as it was for 0.8.2.2 build 2. It ran only on
  claude.ai (it saved answers through claude.ai's page database, `window.claude`), so it does not
  save anything when opened elsewhere. Kept as a reference for how steps were laid out: one card
  per step with what to do, what to expect, Pass / Fail / Skip, a note and screenshots.

Since 2026-11-19 builds are tested from `TESTING.md` with results given in the chat (`AGENTS.md`,
"Tests").
