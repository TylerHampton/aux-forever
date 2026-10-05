# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.4.1, test build 3

A /reload is enough. Build 2's results (saved on the test page) led to these fixes.

**Before you start**
- [ ] 1. Install build 3. No BugSack error.
- [ ] 2. `/aux memory detail` right after login: seven lines (memory, Sniper, History, Search, Post,
      Tooltips, Events). Screenshot them.

**Prices**
- [ ] 3. Search linen cloth (Full): every price shows its copper, "1s 00c" included. Search
      medicine staff (no copper anywhere): prices read "12s".
- [ ] 4. The buy bar and the recipe cost line read short ("Buy for 12s").

**Search**
- [ ] 5. Medicine staff: Auction Bid shows "---" for auctions with no starting bid.
- [ ] 6. Fast lit, search medicine staff (no /exact): do rows show "of the Boar" style names?

**Sniper**
- [ ] 7. A trade good deal: the buy bar's "for sale" matches the table; no bigger button.
- [ ] 8. Buy a deal: Buy, then Confirm. The status says "waits while you buy"; it arrives by mail.
- [ ] 9. `/aux memory detail` at round 10, nothing selected. Screenshot.
- [ ] 10. `/aux memory detail` at round 40, nothing selected. Screenshot.

**Full scan**
- [ ] 11. Full scan, then `/aux memory detail`: "After a cleanup" far below build 2's 42.3 MB.

**Window**
- [ ] 12. Click the resize corner once, a few times: does it jump? Every time? Which way? Scale
      from `/aux`? Screenshots before and after.

**When you get to it**
- [ ] 13. Cancel undercut on a real undercut auction: "Cancelled, comes by mail", item arrives.
- [ ] 14. Bid on an auction whose Auction Bid is a price below its buyout: it shows on Bids.

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
