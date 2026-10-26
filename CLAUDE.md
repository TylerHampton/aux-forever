# auxForever (Claude Code)

The shared guide for every AI agent on this project is AGENTS.md, loaded here:

@AGENTS.md

## Claude Code specifics

- Develop on the branch the session names, started from the latest `main`. Releases up to
  0.6.0.2 (PR #21, 2026-10-10) are merged into `main`.
- Tyler's test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (how to use it:
  `docs/status.md`, Start here). Mockups for him are HTML artifacts too.
- Zip for Tyler: named after the version and build, `auxForever-<version>-build<n>.zip` (for
  example `auxForever-0.6-build2.zip`), so his downloads never collide or get mixed up (Tyler,
  2026-10-08). `zip -qr <scratchpad>/auxForever-0.6-build2.zip auxForever -x '*.git*'`, then send
  it with the file-sending tool. The folder inside is always `auxForever`.
- Claude is the primary engineer; Gemini (Gemini 4 Argon) gives second opinions in `docs/reviews/`
  (`AGENTS.md`, "Roles"). Check each finding before acting on it, and answer it in the file.
- **"Check the handoff"** from Tyler means: pull the active branch named in `docs/handoff.md` (it
  may differ from this session's branch), do the open notes addressed to Claude, and end the reply
  with the "Next:" line that file asks for.
- Other agents (Gemini via Antigravity / Gemini CLI) also work on this repository: pull before
  starting, check `docs/status.md` ("Start here") and `git log`, and leave `docs/status.md` up to
  date when done so either agent can pick up where the other left off.
