# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.6 build 8: Post panel spacing fixes

Branch `claude/upbeat-davinci-jqwq9d`. Build 7 tested 2026-10-10: the panel works (goblin, gear,
trade goods, vendor warning, bid note, posting, tooltips, Classic). Fixed here: PER ITEM ran into
the first price field, OF USUAL was cut off by the divider at the smallest window, and a trade
good with no deposit showed "-0c". `/reload` is enough (no new files).

- [ ] 1. Post tab, any item: PER ITEM and OF USUAL sit clearly above the first price field.
- [ ] 2. Make the window as narrow as it goes: OF USUAL is whole, left of the divider line.
- [ ] 3. Linen Cloth, quantity 1: the deposit line says 0c, not -0c.
- [ ] 4. Sniper: press Start and let one round finish with no deals (or Clear while it runs). The
  message under the table says gray items are left out and deals need 3 days with a Full scan.

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
