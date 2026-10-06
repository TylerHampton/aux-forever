# auxForever (Gemini)

The shared guide for every AI agent on this project is AGENTS.md, loaded here:

@./AGENTS.md

## Gemini specifics

- Gemini CLI runs on Tyler's Windows PC, in his copy of this repository. Use PowerShell commands.
  Ask before installing anything.
- Before starting: `git pull`. When done: run the tests if Lua 5.1 is installed, commit, `git push`,
  and update `docs/status.md`. If Lua is not installed, push and read the GitHub Actions result
  (the "Tests" workflow) before calling the work done.
- Zip for Tyler: `Compress-Archive -Path auxForever -DestinationPath auxForever.zip -Force` from the
  repository folder, then tell him where the file is. He replaces the `auxForever` folder in
  `World of Warcraft\_classic_beta_\Interface\AddOns` with the one in the zip.
- Claude Code also works on this repository, on its own branches. Never push to `main` or merge
  without Tyler asking.
- Claude keeps a test page for Tyler that Gemini cannot use. Keep `TESTING.md` "Current build" up
  to date with the in-game checks for your change, and ask Tyler for results in the chat.
