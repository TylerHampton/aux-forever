# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.6.0.2 build 1 (Post tab reads listings fresh)

Install the zip, then `/reload` (no full restart needed).

- [ ] 1. Talk to an auctioneer and run a Full scan. When it finishes, open the Post tab and click
  an item that has many listings at the same price (Scroll of Stamina was the example): the
  status bar fills, and each price shows as one row with the total for sale, as after Refresh.
- [ ] 2. The price box starts at the lowest listing in that table ("Same as the lowest listing").
- [ ] 3. Click a second item, then the first one again: each click reads the listings again
  (the status bar fills each time), with no BugSack error.
- [ ] 4. Post part of a stack (for example 1 of 2): after "Posted", the table reads the
  listings again (the status bar fills) and the price starts at the lowest listing again.

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
