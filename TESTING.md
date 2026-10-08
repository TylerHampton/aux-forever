# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.6 build 1, the new look (branch `claude/ui-kit-look`)

Only colors and shapes changed, nothing about searching, buying or posting. `/reload` is enough
after copying the folder (no new files). Compare each screen with the matching screen on the "New"
page of the Paper file.

- [ ] 1. Open the auction house: no BugSack error. The window is near black with square corners, a
  darker band along the top and bottom, "aux" white and "Forever" gold, the open tab outlined in
  gold.
- [ ] 2. Search tab: search `cloth`. Column headers are raised gray plates; click "Buyout each"
  twice: the name turns white with a gold arrow that flips. Click a row: it turns gold with a gold
  bar on its left. Moving the mouse over other rows only lightens them.
- [ ] 3. Buy bar: the quantity boxes are gray, the chosen one outlined in gold; the Buy button has a
  gold outline and label. Press Buy: Confirm turns green. Cancel.
- [ ] 4. Sub tabs, Live, Fast/Full: the open sub tab is outlined in gold. Live on is outlined in
  gold; Fast/Full shows the chosen one in dark gold.
- [ ] 5. Post, Auctions, Bids, Sniper: open each. Nothing looks broken (text cut off, a button with
  no outline, an orange fill left from before). Post: Match lowest / Undercut and 12h/24h/48h show
  the chosen one in dark gold.
- [ ] 6. Settings (gear): set Background to 50%. The whole window fades, including the top and
  bottom bands. Set it back.

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
