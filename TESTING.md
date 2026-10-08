# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.5, test build 1

A full game restart is not needed for this build unless a step says so; a /reload is enough. Do
the steps in order. Price data first, because everything priced rests on it.

Price data (docs/price-data.md, "Plan for 0.5"):
- [ ] 1. Log in with your 0.4.1 price history: no BugSack error. Hover a trade good you scanned
      before: Value still shows a price (the old history was converted, not wiped), with
      "seen N days ago" after it in gray.
- [ ] 2. `/aux memory`, note the number. Run a Full scan. When it says "full scan complete",
      `/aux memory` again: after a cleanup the difference stays under about 1 MB.
- [ ] 3. After the Full scan, hover a few trade goods: Value, Today and "seen today" look sensible
      next to what the auction house shows. An item seen over a week ago shows its age darker.
- [ ] 4. Sniper: Start; it still finds deals with the default rule.

FB-003, posts that say nothing (Post tab, the left column under Duration):
- [ ] 5. Select a piece of gear, type a starting bid above the buyout: the Post button fades and
      the left column says "The starting bid is above the buyout."
- [ ] 6. Post an item normally: "Posting..." then, in green, "Posted 1 × <item>".
- [ ] 7. Pick an item on the left, then pick it up onto the cursor and click Post: "Not posted:
      the item is locked..." in red, also in chat.
- [ ] 8. If you have damaged gear: does it show in the Post tab's list? If it does, Post should
      say "Not posted: this item must be repaired first." (or show the game's own reason). Note
      what you see either way.

FB-006, the Recent Searches header (Garsterson's steps):
- [ ] 9. Scale 100%, make the window large, set Scale to 140% or 150%, open Search, Saved
      Searches, then shrink the window with the resize corner. Neither list's header sticks out
      past the window. Try the same with another sub tab open while resizing, then switch back.
- [ ] 10. The Post tab's two price lists: resize the window; their headers stay inside.

Clicks (docs/clicks.md) and FB-002:
- [ ] 11. Post tab: right-click a sellable item in your bags. It is selected in the Post tab
      (Blizzard's window does not appear). Try a bag addon too, if you use one.
- [ ] 12. Search tab: right-click a bag item searches it. Sniper tab: right-click, Shift-click or
      Alt-click a bag item switches to Search and searches it.
- [ ] 13. Right-click something that cannot be sold (soulbound gear): Blizzard's normal right-click
      (equip or use), nothing in aux.
- [ ] 14. Search results: click a row (the buy bar shows it), click it again: let go, the buy bar
      empties. Same in the Auctions and Bids tabs.
- [ ] 15. Post tab price lists: click a price (it is used), click it again (let go); right-click a
      price row searches the item.
- [ ] 16. Hover a result row, a row's icon, a Post bag item and a Saved Search: a gray line lists
      the clicks. Say if it is too much or easy to miss.

FB-001, the quantity box on the buy bar:
- [ ] 17. Select a trade good in Search. The box right of the quantity buttons is labeled QUANTITY,
      darker than the buttons, and shows the number being bought (the stack at first).
- [ ] 18. Click 5: the box says 5. Click in the box, type 37, press Enter: it asks the price for 37
      (Confirm 37...). Clear the box and click elsewhere: it shows the quantity again.
- [ ] 19. Does it read as a place to type? Screenshot welcome.

FB-007, recipe cost in the profession window (away from the auction house too):
- [ ] 20. Away from the auction house, open a profession and pick a recipe whose materials you
      have scanned. Under the reagent list: "Materials" and a price, in small gray text.
- [ ] 21. Hover the line: one row per material with its cost and "vendor" or "usual, N days ago";
      the total at the bottom. Does the total look right?
- [ ] 22. A recipe with a material aux has no price for: the price ends in a gray "+", and the
      tooltip says which material has "no price yet". A recipe with nothing priced says "no price
      yet".
- [ ] 23. Switch between a few recipes: the line changes with each, and does not overlap anything
      (screenshot welcome; the line's place is a guess until seen in game).

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
