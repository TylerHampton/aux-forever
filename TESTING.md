# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.5, test build 4

A /reload is enough (no new files). Build 3: the banana tooltip matched (38c each), a Full scan
alone recorded Rough Dynamite at its lowest listing (30c); Linen Cloth read 32c with 23c listings,
fixed here.

- [ ] 1. Build 4 installed, no BugSack error.
- [ ] 2. Search Linen Cloth, then hover it in your bags: Value is within a copper or two of the
      cheapest listings.
- [ ] 3. Full scan: the bar at the bottom left says "Full scan: waiting for the auction house..."
      right away, then "reading auctions, N%", then nothing when done.
- [ ] 4. Post tab: right-click a bag item into the Post tab, then left-click the same stack in your
      bags: it picks up normally. Put it back, click Post: it posts.
- [ ] 5. Post tab: make the Post button fade (starting bid above the buyout), hover it: a tooltip
      says why.

Build 1 checklist (passed or skipped, kept for the release run): price data conversion, Full
scan memory (9.9 MB after a cleanup with 3,457 items of history), Sniper deals, posting,
FB-006 headers, right-click from the bags (FB-002), the other bag clicks, let go on a second
click, the quantity box itself, the recipe cost line and its place.

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
