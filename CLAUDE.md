# auxForever (Claude Code)

The shared guide for every AI agent on this project is AGENTS.md, loaded here:

@AGENTS.md

## Claude Code specifics

- Develop on the branch the session names, started from the latest `main`. Releases up to
  0.6.0.1 (PR #18, 2026-10-10) are merged into `main`.
- Tyler's test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (how to use it:
  `docs/status.md`, Start here). Mockups for him are HTML artifacts too.
- Zip for Tyler: named after the version and build, `auxForever-<version>-build<n>.zip` (for
  example `auxForever-0.6-build2.zip`), so his downloads never collide or get mixed up (Tyler,
  2026-10-09). `zip -qr <scratchpad>/auxForever-0.6-build2.zip auxForever -x '*.git*'`, then send
  it with the file-sending tool. The folder inside is always `auxForever`.
- Other agents (Gemini) also work on this repository: pull before starting, and leave
  `docs/status.md` up to date when done.
