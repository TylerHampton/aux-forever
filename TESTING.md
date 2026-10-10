# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.6 build 7: the new Post panel, plus build 6's Sniper checks

Branch `claude/upbeat-davinci-jqwq9d`. Build 6 was never tested, so its three Sniper steps are here
too. **Full game restart needed** (new texture: the warning triangle; the goblin picture changed).

Post tab (New theme):
- [ ] 1. Goblin: the Undercut button shows the new goblin (faded while off, bright while on).
- [ ] 2. Gear: pick a piece of gear. Three columns: the item, Count and Duration on the left; Match
  lowest / Undercut / ? over two narrow price fields with the % under OF USUAL in the middle; on
  the right Total, Auction house cut 5%, You get, the deposit and a wide Post button at the bottom.
- [ ] 3. Trade goods: pick cloth. Quantity instead of Count, one Price field, and under You get a
  gray line with the amount each and what a vendor pays.
- [ ] 4. Vendor warning: on an item a vendor buys, type a price below what the vendor pays. A red
  box with the red warning triangle says "Vendor pays more" with the vendor's amount, and You get
  turns red. Raise the price again: the box goes away.
- [ ] 5. Gear with the starting bid equal to the buyout: a gray second line under the price note
  says "Bid equals buyout, so it posts as buyout only".
- [ ] 6. Make the window as narrow as it goes (resize grip). Nothing overlaps: the % stays left of
  the line, the receipt and the Post button stay whole.
- [ ] 7. Post one cheap item. It posts; the message shows in the left column under Duration.
  Hovering the deposit line explains the deposit; hovering ? explains Match lowest and Undercut.
- [ ] 8. Classic theme (Settings, Theme, Classic, Reload now): the Post tab looks right, the
  warning box is readable. Switch back to New.

Sniper (from build 6):
- [ ] 9. Start and let one round finish. No gray item (gray name) is in the list, not even
  "below vendor". Fading Echo is gone.
- [ ] 10. The deals left have a usual price that looks believable for what the item is. Note any
  that still look like junk, with a screenshot.
- [ ] 11. Stop. With no deals, the message under the table says gray items are left out and deals
  need 3 days with a Full scan.

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
