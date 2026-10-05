# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.4.1, test build 4 (release check)

A /reload is enough. The test page has the same steps.

**Before you start**
- [ ] 1. Build 4 installed, no BugSack error.
- [ ] 2. `/aux memory detail` at login. Screenshot.

**Window**
- [ ] 3. Clicks on the resize corner change nothing; dragging resizes; it never jumps.

**Prices**
- [ ] 4. Linen cloth (Full): every price shows its copper ("1s 00c"). Medicine staff: "12s".
- [ ] 5. The buy bar reads short ("Buy for 12s").
- [ ] 6. Auction Bid shows "---" without a starting bid; real starting bids still show.

**Sniper**
- [ ] 7. A trade good deal: the buy bar offers no more than the table's For sale.
- [ ] 8. Buy, then Confirm: "waits while you buy" meanwhile; it arrives by mail.
- [ ] 9. `/aux memory detail` at round 10, nothing selected. Screenshot.
- [ ] 10. `/aux memory detail` at round 40, nothing selected. Screenshot.

**Full scan**
- [ ] 11. Full scan, then `/aux memory detail`: "After a cleanup" far below 42.3 MB.

**Quick run before release**
- [ ] 12. Search and buy one gear auction and a few of a trade good; prices match the mail.
- [ ] 13. Live repeats with a countdown; Pause and Resume work.
- [ ] 14. A favorite and a clock menu search both run.
- [ ] 15. Post one trade good and one piece of gear; lowest price matched by default.
- [ ] 16. Auctions tab checks prices and shows statuses.
- [ ] 17. Recipe search shows the cost line in the bottom bar.

**Optional**
- [ ] 18. Fast lit, medicine staff (no /exact): suffix names shown?
- [ ] 19. Cancel undercut on a real undercut auction; it arrives by mail.

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
