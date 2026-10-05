# Adding Gemini to the project

Written for Tyler, 2026-10-05. Gemini (and any other AI) learns the project from `AGENTS.md` at the
top of the repository; `GEMINI.md` loads it automatically. There are two ways to use Gemini on
this repository. Both can be used alongside Claude.

## Starting point

Everything up to version 0.2 is merged into `main` (pull request #1, 2026-10-05). Every agent
starts from `main` and works on its own branch.

## Option 1: Jules (in the browser, works like Claude here)

Jules is Google's coding agent that works on GitHub repositories in the cloud and hands back a
pull request. Nothing to install.

1. Go to https://jules.google and sign in with the Google account that has your subscription.
2. Connect GitHub when it asks, and allow it the `TylerHampton/aux-forever` repository.
3. In the repository's settings in Jules, find the environment setup script and paste:
   `sudo apt-get update && sudo apt-get install -y lua5.1 zip`
   (this lets it run the addon's tests).
4. Pick the repository, pick the branch `main`, and describe the task.
5. Jules shows a plan, works, and opens a pull request. Check that the "Tests" check on the pull
   request is green.
6. To try it in game: on the pull request's "Checks" tab open the Tests run, and download
   "auxForever" under Artifacts. Unzip it and copy the `auxForever` folder into your AddOns
   folder, replacing the old one.

## Option 2: Gemini CLI (on your PC, in a terminal)

Gemini CLI runs in a terminal window on your computer and edits a copy of the repository there.

One-time setup:

1. Install Git for Windows: https://git-scm.com/download/win (defaults are fine).
2. Install Node.js, the "LTS" version (20 or newer): https://nodejs.org
3. Open PowerShell (Start menu, type PowerShell) and run:
   `npm install -g @google/gemini-cli`
4. Get a copy of the repository:
   `cd $HOME`
   `git clone https://github.com/TylerHampton/aux-forever.git`
   `cd aux-forever`
5. Start Gemini there: `gemini`. Choose to sign in with Google, using the account with your
   subscription. It loads `GEMINI.md` (and through it `AGENTS.md`) by itself; `/memory show`
   displays what it loaded.

Optional, makes testing faster: link the AddOns folder to the copy, so Gemini's changes show up in
game after a `/reload` (or a full restart for new files) with no zip. First move your current
`Interface\AddOns\auxForever` folder somewhere safe, then in PowerShell (one line):

`cmd /c mklink /J "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\auxForever" "$HOME\aux-forever\auxForever"`

The catch: whatever Gemini has half-finished is what the game loads.

## Starting a session (either option)

Open with something like:

> Read AGENTS.md and docs/status.md. Then: <the task>. Work on a new branch, add tests, update
> TESTING.md and docs/status.md, and give me the zip when done.

## Keeping Claude and Gemini from colliding

- One agent per branch at a time. Give each task its own branch.
- Each agent pulls before starting and updates `docs/status.md` when done, so the next one (of
  either kind) picks up where it stopped.
- The "Tests" check on GitHub runs on every push, whoever made it. Red means not ready.
- Merging into `main` is your call. Merge one finished branch, then start the next task from
  the new `main`.
