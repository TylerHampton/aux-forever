# auxForever (Gemini)

The shared guide for every AI agent on this project is AGENTS.md, loaded here:

@./AGENTS.md

## Gemini specifics

- **Environment:**
  - **Remote mode (Antigravity Linux VM, default):** Runs on a Debian Linux VM with `git` connected
    to GitHub and bash commands. Run the Lua 5.1 test suite from `auxForever/` with
    `luajittex --luaonly ../tests/load_test.lua`,
    `luajittex --luaonly ../tests/load_test.lua classic`, and
    `luajittex --luaonly ../tests/timing_test.lua` (or `lua5.1` when installed). Build zips from the
    repository root with `zip -qr auxForever-<version>-build<n>.zip auxForever -x '*.git*'`.
  - **Local Windows mode (if used):** Use PowerShell commands (`Compress-Archive -Path auxForever -DestinationPath auxForever-<version>-build<n>.zip -Force`) and ask before installing anything.
- Before starting: `git fetch origin '+refs/heads/*:refs/remotes/origin/*'` and `git pull` on the
  active branch.
- Your role (Tyler, 2026-10-26): the supporting model, for second opinions. Claude Code stays the
  primary engineer. Reviews go in `docs/reviews/`, never as edits to Claude's code; the format is
  in `AGENTS.md`, "Roles".
- **"Check the handoff"** from Tyler means: pull the active branch named in `docs/handoff.md`, do
  the open notes addressed to you, and end your reply with the "Next:" line that file asks for.
- Working in tandem with Claude Code:
  - Read `docs/status.md` ("Start here"), `docs/handoff.md` and `git log` first to see what Claude
    or a previous session built and which branch is active.
  - One agent works on a branch at a time. When continuing an active build or review, pull the
    latest of that branch; when starting parallel work, create a separate `gemini/<topic>` branch
    from `main`.
  - Never push to `main` or merge a pull request without Tyler asking.
- When done: run the tests (`tests/load_test.lua` in both themes and `tests/timing_test.lua`),
  commit, `git push`, and update `docs/status.md` (and `TESTING.md` if addon code changed).
