# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.6 build 3: the New look, Classic look switch, zebra rows, the new Settings menu

Branch `claude/eager-dijkstra-drmz2k` (Webster's build 1 plus this). Builds 1 and 2 were never
tried in game, so their checks are folded in here. Build 3 changes only the Settings menu (the
mockup Tyler approved). Only looks and Settings changed, nothing about searching,
buying or posting. `/reload` is enough after copying the folder (no new files).

- [ ] 1. Open the auction house: no BugSack error. The window is near black (a little lighter than
  pure black) with square corners and a darker band along the top and bottom. Search tab, open the
  Filter Builder: every text box has a gray edge and is easy to tell apart from the panel.
- [ ] 2. Search `cloth`: every second row is a little lighter (dark gray zebra rows). Column
  headers are raised plates; click "Buyout each" twice: the name turns white with a gold arrow that
  flips. Click a row: it turns gold with a gold bar on its left. The mouse over other rows only
  lightens them, also on a striped row.
- [ ] 3. Buy bar: the chosen quantity box is outlined in gold, the Buy button has a gold outline and
  label. Press Buy: Confirm turns green. Cancel.
- [ ] 4. Post, Auctions, Bids, Sniper: open each. Nothing looks broken (text cut off, a button with
  no outline, an orange fill left from before). Settings (gear): Background 50% fades the whole
  window, bands included. Set it back.
- [ ] 5. Settings (gear): the menu is wide with two columns, like the mockup: Window and Posting on
  the left, Tooltip lines on the right, switches instead of boxes. Switch Value off, hover an item in
  your bags: no "Value" line; switch it on: it is back. Posting, Bid prices: Item; open the Post tab
  and pick an item: a bid table sits next to the buyouts. Set it back to Off: it goes away.
- [ ] 6. Settings, Look: click Classic. "Classic after a reload" and a Reload now button appear.
  Click Reload now, open the auction house: slate panels, rounded corners, amber accent, zebra rows
  in the search results, no BugSack error. Open each tab once. Then Settings, New, Reload now: the
  New look is back.

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
