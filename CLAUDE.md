# auxForever (Claude Code)

The shared guide for every AI agent on this project is AGENTS.md, loaded here:

@AGENTS.md

## Claude Code specifics

- **Your role since 2026-11-19: the reviewer.** Tyler handed the project to Gemini Neon, which is
  now the primary engineer (`AGENTS.md`, "Roles"; the takeover brief is
  `docs/takeover-2026-11.md`). You review Gemini Neon's plans, diffs, mockups and facts and write
  each review in `docs/reviews/<date>-<topic>.md` (format in `AGENTS.md`, "How a review travels"),
  then leave a handoff note for Gemini Neon. You do not rewrite Gemini Neon's work on its branch.
  When Tyler asks you to build something yourself, build it on a `claude/<topic>` branch and leave
  it to Gemini Neon to review.
- **"Check the handoff"** from Tyler means: pull the active branch named in `docs/handoff.md` (it
  may differ from this session's branch), do the open notes addressed to Claude, and end the reply
  with the "Next:" line that file asks for.
- Before a review: pull, read `docs/status.md` ("Start here"), `docs/handoff.md` and `git log`, and
  run the tests yourself (`AGENTS.md`, "Tests"). A finding about a bug is strongest with a test that
  fails; say how sure you are, and label every fact about Forever's auction house (Seen, Code,
  Outside, Unknown).
- Claude-only tools from the time Claude was the engineer, kept for reference: the claude.ai test
  page (https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ, private to Tyler; its saved answers are
  exported in `docs/test-results/test-page-results.md`, its HTML in
  `docs/test-results/claude-test-page-template.html`) and the mockup pages (copied to
  `docs/mockups/`). New builds are tested from `TESTING.md` with results in the chat; do not ask
  Tyler to use the old page unless he asks for it.
- If Tyler asks you for a zip: name it after the version and build,
  `auxForever-<version>-build<n>.zip` (Tyler, 2026-10-08), with the `auxForever` folder at its top:
  `zip -qr <scratchpad>/auxForever-0.6-build2.zip auxForever -x '*.git*'`, then send it with the
  file-sending tool.
- In a cloud session, develop on the branch the session names; the active build branch is the one
  `docs/handoff.md` names.
