# auxForever (Gemini)

The shared guide for every AI agent on this project is AGENTS.md, loaded here:

@./AGENTS.md

## Gemini specifics

- **Your role since 2026-11-19 (Gemini Neon): the primary engineer.** Tyler: "Prep this project
  for a full takeover by Gemini Neon." You plan and build, own the active build branch, make the
  zips, write each build's steps in `TESTING.md`, read Tyler's results and run releases when he
  asks. Claude Code is now the reviewer (`AGENTS.md`, "Roles").
- **Background reference:** `docs/takeover-2026-11.md` holds Claude's 2026-11-19 handover notes
  (H-012 is already completed and closed in `docs/handoff.md`).
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
  `auxForever-0.9.1-build1.zip`), the `auxForever` folder at its top level:
  `zip -qr auxForever-0.9.1-build1.zip auxForever -x '*.git*'` from the repository root
  (`.gitignore` keeps zips out of commits). Give it to Tyler the way your environment allows; every
  push also builds one on GitHub Actions (the run's `auxForever-<version>-build<n>` artifact),
  which Tyler can download (bookmark the GitHub Actions run with a `.url.json` artifact). Always say
  whether `/reload` is enough or a full game restart is needed (any new file).
- **Testing with Tyler:** put the steps under "Current build" in `TESTING.md` (rules in `AGENTS.md`,
  "Tests", and at the bottom of `TESTING.md`), and also create an interactive side-pane HTML test
  checklist artifact (Pass/Fail/Skip toggles, one-click Copy buttons for queries/`/run` commands,
  per-step Ctrl+V screenshot pasting, and Copy results text + Copy/Download stitched screenshots
  sheet buttons; Tyler, 2026-11-21: "testing against a block of text is not as neat"). When
  stitching 3 or more screenshots, lay them out in a **2-column grid** (not one tall vertical strip,
  which chat downscales to 1024px high and compresses to unreadable ~300px widths). For short `/run`
  diagnostic output, ask Tyler to paste the text into the step's note rather than reading blurry
  screenshots, and never mark a Forever fact `Seen` if text is not crisp. Tyler pastes the copied
  summary and stitched PNG back in chat; write his answers under the build as "Results". Claude's
  claude.ai test page is retired; its history is in `docs/test-results/test-page-results.md`.
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
