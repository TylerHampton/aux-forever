# auxForever (Gemini)

The shared guide for every AI agent on this project is AGENTS.md, loaded here:

@./AGENTS.md

## Gemini specifics

- **Your role since 2026-11-19 (Gemini Neon): the primary engineer.** Tyler: "Prep this project
  for a full takeover by Gemini Neon." You plan and build, own the active build branch, make the
  zips, write each build's steps in `TESTING.md`, read Tyler's results and run releases when he
  asks. Claude Code is now the reviewer (`AGENTS.md`, "Roles").
- **First session: read `docs/takeover-2026-11.md` in full.** It is Claude's complete handover:
  where things stand, every open decision and question, how each piece of the workflow is done, and
  what Claude learned that is not written elsewhere. Then do note H-012 in `docs/handoff.md`.
- **Environment:**
  - **Remote mode (Antigravity Linux VM, default):** Runs on a Debian Linux VM with `git` connected
    to GitHub and bash commands. Install Lua once if it is missing:
    `sudo apt-get update && sudo apt-get install -y lua5.1 zip`. Run the checks from `AGENTS.md`,
    "Tests" (from `auxForever/`: `lua5.1 ../tests/load_test.lua`, the same with `classic`, the
    syntax check, then `lua5.1 tests/lint_globals.lua` from the root). `timing_test.lua` and
    `fuzz_test.lua` run inside `load_test.lua`; do not run them alone. `luajittex --luaonly` was
    used when Lua 5.1 was not installed; prefer `lua5.1` (the game is Lua 5.1).
  - **Local Windows mode (if used):** Use PowerShell commands
    (`Compress-Archive -Path auxForever -DestinationPath auxForever-<version>-build<n>.zip -Force`)
    and ask before installing anything.
- **Zips for Tyler:** `auxForever-<version>-build<n>.zip` (for example
  `auxForever-0.8.2.2-build3.zip`), the `auxForever` folder at its top level:
  `zip -qr auxForever-0.8.2.2-build3.zip auxForever -x '*.git*'` from the repository root
  (`.gitignore` keeps zips out of commits). Give it to Tyler the way your environment allows; every
  push also builds one on GitHub Actions (the run's "auxForever" artifact), which Tyler can
  download. Always say whether `/reload` is enough or a full game restart is needed (any new file).
- **Testing with Tyler:** put the steps under "Current build" in `TESTING.md` (rules in `AGENTS.md`,
  "Tests", and at the bottom of `TESTING.md`). Tyler answers in the chat with Pass or Fail per step,
  notes and screenshots; write them under the build as "Results". Claude's claude.ai test page is
  not available to you; its history is in `docs/test-results/test-page-results.md`.
- Before starting: `git fetch origin '+refs/heads/*:refs/remotes/origin/*'` and `git pull` on the
  active branch (named in `docs/handoff.md`).
- **"Check the handoff"** from Tyler means: pull the active branch named in `docs/handoff.md`, do
  the open notes addressed to you, and end your reply with the "Next:" line that file asks for.
- Reviews from Claude arrive in `docs/reviews/` with a handoff note: check each finding (code, a
  test, Blizzard's code), fix the real ones with a test that fails without the fix, and answer each
  finding in the same file (`AGENTS.md`, "How a review travels").
- Never push to `main` or merge a pull request without Tyler asking.
- When done: run the tests (both themes, syntax check, lint), commit, `git push`, and update
  `docs/status.md` (and `TESTING.md` if addon code changed).
