# auxForever (Gemini)

The shared guide for every AI agent on this project is AGENTS.md, loaded here:

@./AGENTS.md

## Gemini specifics

- Gemini (via Antigravity or Gemini CLI) runs on Tyler's Windows PC, in his local copy of this
  repository (`C:\Users\tyler\.gemini\antigravity\scratch\aux-forever`). Use PowerShell commands.
  Ask before installing anything.
- Before starting: `git fetch --all --prune` and `git pull` on the active branch.
- Working in tandem with Claude Code:
  - Read `docs/status.md` ("Start here") and `git log` first to see what Claude or a previous
    session built and which branch is active.
  - One agent works on a branch at a time. When continuing an active build, pull the latest of
    that branch; when starting parallel work, create a separate `gemini/<topic>` branch from
    `main`.
  - Never push to `main` or merge a pull request without Tyler asking.
- When done: run the tests (`tests/load_test.lua` in both themes and `tests/timing_test.lua`) if
  Lua 5.1 is installed, commit, `git push`, and update `docs/status.md` and `TESTING.md`. If Lua
  is not installed locally, push and read the GitHub Actions result (the "Tests" workflow) before
  calling the work done.
- Packaging and installing for Tyler:
  - Name the zip `auxForever-<version>-build<n>.zip` (matching Claude's naming so builds never
    collide) or `auxForever.zip`:
    `Compress-Archive -Path auxForever -DestinationPath auxForever-<version>-build<n>.zip -Force`
  - Because Antigravity also has access to `C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\auxForever`,
    you can copy the updated `auxForever` folder directly into `AddOns` for Tyler as well as
    providing the zip, and tell him whether `/reload` is enough or a full game restart is needed.
