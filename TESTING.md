# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.5, test build 3

A /reload is enough (no new files). Build 2: everything passed except two small things, fixed here
(gold prices in the cost tooltip, the cut-off Post message). New in build 3: tooltips show the
price of your latest scan (Tyler's decision, docs/price-data.md).

- [ ] 1. Build 3 installed, no BugSack error.
- [ ] 2. Search Tel'Abim Banana (or any trade good), then hover one in your bags: Value is close to
      the cheapest listings you just saw, "seen today". If the usual price is far off, a gray
      "usually ..." line shows under it.
- [ ] 3. Run a Full scan without searching first (wait for the 15 minutes if needed). Then
      `/aux price ` and Shift-click a trade good you have not searched today. The first line's price
      should be close to what the auction house shows for it. Screenshot please.
- [ ] 4. Recipe cost tooltip: prices white, the header says "Prices from your latest scans", each
      material "seen today" or "vendor".
- [ ] 5. Post tab: an item on your mouse pointer and Post: the red line fits (two lines at most).
- [ ] 6. Sniper: Start, deals still show.

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
