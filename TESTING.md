# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.4.1, test build 5 (release check)

A /reload is enough. The test page has the same steps.

- [ ] 1. Build 5 installed, no BugSack error.
- [ ] 2. Sniper: with the mouse over the table the rows stay still; a clicked deal stays selected.
- [ ] 3. Sniper: with a deal selected the status says "Holding while a deal is selected"; clicking it
      again lets it go and the rounds go on.
- [ ] 4. Sniper: a gear deal shows "Checking the auction...", then "Buy for"; it buys and arrives.
- [ ] 5. Sniper: a trade good deal buys with Buy, then Confirm.
- [ ] 6. An empty search bar says "Type something to search for." and searches nothing.
- [ ] 7. Quick run: search and buy, Live, saved and clock searches, Post, Auctions tab, recipe search.
- [ ] 8. `/aux memory detail` at the end. Screenshot.

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
