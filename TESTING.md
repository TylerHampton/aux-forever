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

## Before every release: the quick run

A short pass over everything, so a release never breaks something old. About 15 minutes.

- [ ] Log in: no BugSack error. `/aux` lists the settings.
- [ ] Auction house: aux opens instead of Blizzard's window; Blizzard UI toggles it; Escape closes.
- [ ] Search a name (`linen cloth`) and a filter (`armor/cloth/45/50/uncommon`); right-click a row
      searches that item; Shift-click and Alt-click from bags search it.
- [ ] Buy one gear auction and a few of a trade good; the price paid matches the button and the mail.
- [ ] Live: a search repeats with a countdown; Pause and Resume work.
- [ ] Saved Searches and the clock menu: a favorite runs; pin and unpin work.
- [ ] Sniper: Start, a round completes, Stop.
- [ ] Post: post one trade good and one piece of gear; the lowest price is matched by default.
- [ ] Auctions tab: prices are checked and statuses show; Cancel works on one auction.
- [ ] Bids tab lists your bids.
- [ ] Recipe search from a profession window shows the cost line.
- [ ] `/aux memory` reads a sensible size.

## For agents

Add the in-game checks for each change to "Current build" above (and to the build's test page, if
one exists); move them into the quick run when they become part of what every release must keep
working. Older detailed checklists: `docs/testing-history.md`.
