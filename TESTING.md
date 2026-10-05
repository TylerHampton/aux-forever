# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.4.1, test build 2

Full game restart needed (a file was removed).

**Before you start**
- [ ] 1. Install build 2 and restart the game. No BugSack error; chat says auxForever loaded.
- [ ] 2. `/aux memory` right after login. The line ends in "item list N items" (maybe "still
      checking"). Note the line.
- [ ] 3. `/aux`: the settings list has no "crafting cost" line.

**Prices**
- [ ] 4. Search linen cloth, look at the buy bar and the Post tab too: prices read "7s" or
      "1g 92s", never "7s 00c". Prices with copper still show it ("1s 23c").

**Search**
- [ ] 5. Fast on, search `15/25/usable/armor/cloth/uncommon`: note whether gear rows show the
      suffix ("of the Owl").
- [ ] 6. Saved Searches: Alt-drag a favorite to another place. It moves and stays.
- [ ] 7. Clock button: the pin on a recent search appears on hover and stays over the pin itself.

**Recipes**
- [ ] 8. Search in aux from a profession window: the cost is in the bottom bar right of Clear;
      the line next to the sub tabs shows only counts.
- [ ] 9. Narrow window: the cost line ends in "..." and never covers the credit text.
- [ ] 10. Shift-click a recipe: only Blizzard's own action, no aux search.

**Sniper**
- [ ] 11. Gone deals sit below every deal you can still buy.
- [ ] 12. Buy a cheap deal: bought at the shown price, arrives by mail.
- [ ] 13. `/aux memory` at round 10. Note the line.
- [ ] 14. `/aux memory` at round 40. "After a cleanup" close to round 10's. Note the line.

**Post**
- [ ] 15. An item only in the reagent bag is listed and posts.
- [ ] 16. A green item with a bid lower than its buyout posts without an error.

**Auctions and Bids**
- [ ] 17. Cancel undercut on a real undercut auction: "Cancelled, comes by mail", item arrives.
- [ ] 18. Bid on a cheap item: it shows on the Bids tab; Bid and Buyout follow the selected row.

**Other**
- [ ] 19. Full scan once: it finishes without an error.
- [ ] 20. Filter Builder: each dropdown opens and picks a value.
- [ ] 21. `/aux memory` about 10 minutes after login: "still checking" is gone. Note the line.

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
