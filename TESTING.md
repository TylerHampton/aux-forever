# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.6 build 5: coin colors, Theme, Bid prices out of Settings

Branch `claude/eager-dijkstra-drmz2k`. Build 4 passed in game (2026-10-09; results in
`docs/status.md`), so only what changed after it is checked here. `/reload` is enough (no new files).

- [ ] 1. Search `linen cloth`, select a row. The Buy button reads "Buy 20 for 4s 60c" with the s in
  silver and the c in copper, as in the table. Press it: Confirm shows its price the same way.
  Cancel.
- [ ] 2. Settings (gear): the row is called Theme (not Look). There is no Bid prices row; Posting
  has only Default duration. Pick Classic: "Classic theme after a reload". Pick New again.
- [ ] 3. Sniper: Start, wait for a few deals. The Profit each column is green with silver s and
  copper c. Stop.
- [ ] 4. A recipe search (Alt-click a recipe in the profession window, or a saved Recipe search):
  the bottom line's "materials", "sells" and "profit" amounts have colored s, g and c.
- [ ] 5. Theme Classic, Reload now: the Search and Buy buttons are dark amber with an amber
  outline (not solid amber), and the prices on them are readable. Back to New, Reload now.

## Before every release: the 5-minute check

Tyler (2026-10-08): the old 15-minute quick run was too long. This is one walk through the
auction house, about 5 minutes, that touches every tab once. Everything else is covered by the
automated tests (run on every push) and by the build steps of the version, which test whatever
changed.

- [ ] 1. Log in and talk to an auctioneer: aux opens, no BugSack error.
- [ ] 2. Search `linen cloth` and buy 1 with the buy bar (Buy, then Confirm): it is bought.
- [ ] 3. Post tab: post one item at the price aux picks: it says "Posted".
- [ ] 4. Auctions tab: that item is listed with a status.
- [ ] 5. Sniper tab: Start, wait for one round, Stop.
- [ ] 6. Open a profession window: the Materials line shows under a recipe's reagents.

Agents: keep this list at six steps or fewer. Add a step only for something that broke in a
release before, and say which.

## For agents

Add the in-game checks for each change to "Current build" above (and to the build's test page, if
one exists). The pre-release check stays at six steps (Tyler's limit); do not move build steps
into it. Older detailed checklists: `docs/testing-history.md`.
