# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.7.1 build 2

Tyler (2026-10-17): "all these changes are going to just be .7.1". Build 1 was the same Auctions
tab and search fixes under the name 0.7.0.1 (never tested). Build 2 adds the deposit rounding
(FB-017) and the "Post tab starts on" setting (FB-018). Zip `auxForever-0.7.1-build2.zip`;
`/reload` is enough (no new files). Test page build id `0-7-1-build-2`. Have on hand: 20 Copper
Ore (or another cheap trade good) and 5 cheap identical items that are not trade goods (Linen
Bags). Steps, in the New theme:

Deposit (FB-017: what the game really takes):
- [ ] 1. Paste `/run print(C_AuctionHouse.SupportsCopperValues())` at the auction house; note
      true or false.
- [ ] 2. 20 Copper Ore, 8 hours: note the Deposit on aux's Post tab and in Blizzard's Sell tab.
      The same.
- [ ] 3. Note your exact money, post the 20 with aux, note it again: the difference is aux's
      Deposit.
- [ ] 4. As step 2 with one item that is not a trade good (gear or a Linen Bag).
- [ ] 5. As step 3 with that item.

Auctions tab (FB-015, FB-016):
- [ ] 6. Post 3 identical Linen Bags at one price, 1 more at another. Auctions tab: 4 rows, each
      Qty 1, none hidden under another.
- [ ] 7. Select one of the 3 and press Cancel: "Cancelling...", then "Cancelled, comes by mail",
      then it leaves the list. The other 2 stay.
- [ ] 8. "Blizzard UI", Blizzard's Auctions tab: the same auctions as aux.

Search (FB-014):
- [ ] 9. Type the full name of a piece of gear Blizzard's window lists: aux lists as many. If a
      chat line says an item "could not be read in time", note it and search again.
- [ ] 10. The same item from the suggestion (`/exact`): the same number.

Settings (FB-018):
- [ ] 11. Settings, Posting, "Post tab starts on": Undercut. Close and reopen the auction house:
      the Post tab is in Undercut mode. Set it back.

Classic theme:
- [ ] 12. Theme Classic, `/reload`, Auctions tab: your auctions, one row each.

The test page also has 9 questions for Tyler with answer boxes (no Pass or Fail): keep the
"Post tab starts on" setting; the rest of the cut-off deposit comment; Waylaid crates and writs;
CurseForge follow-ups for 0.7; and the older open questions in `docs/status.md` (Sniper single
listings, Sniper profit minimum, the FB-008 player's name, New theme tweaks, branch
`claude/exciting-brown-a9k99n`). Questions are steps with `ask: true` on the page; an answer
counts as done.

### 0.7 build 4

FB-013 (HoaxBox, iLvl and colored Req columns) and FB-012 (MDHippie, `AuxForeverAPI`), plus the
fast resize fix. Tested by Tyler on 2026-10-13: all 6 steps pass. Released as 0.7. The steps are
in git history (`TESTING.md` at commit 37336f7).

### 0.6.1.1 build 1

Fix for FB-011 (Gaddor): clicking an item's icon in the Post tab's bag list selects it. Tested by
Tyler on 2026-10-12 (screenshots): all 3 steps pass (icon click selects, name click selects,
right-click on the icon searches). Released as 0.6.1.1.

Earlier: 0.6.1 build 2 (weapon slots in Search, audit fixes), tested in game and released. Its
steps and results, kept for reference:

### 0.6.1 build 2

Tested by Tyler on 2026-10-11 (test page `0-6-1-build-2`, screenshots): steps 1 to 5 pass
(daggers, staves, cloth chests and bows only, In words "Daggers (weapons, one-handed)."). Step 6:
autocompletion works ("linen" completed to "linen bag/exact"); own auctions not checked, he had
none up. Tyler found step 6 confusing (two checks in one, the second needing auctions). Optional
steps 7 and 8 done: the game's names, now in `tests/forever_categories.lua`.

0.6.1 build 1 was the same weapon slot fix under the name 0.6.0.3. `/reload` is enough (no new
files). Steps, in the New theme:

- [ ] 1. Search tab, "Which items": Category Weapons, Type One-Handed, Slot Daggers, then Search.
      The search bar shows `weapons/one-handed/daggers`, the search is short, and only daggers
      are listed.
- [ ] 2. Same with Two-Handed and Staves: only staves.
- [ ] 3. Armor, Cloth, Chest: only cloth chest pieces (this worked before; check it still does).
- [ ] 4. Type `weapons/ranged/bows` in the search bar and press Enter: only bows, and the menus
      show Weapons, Ranged, Bows.
- [ ] 5. Filter Builder tab, after step 1: "In words" reads "Daggers (weapons, one-handed)".
- [ ] 6. After a search, type the first letters of an item from the results in the search bar:
      its name is offered. Your own auctions still show as yours (green) in the Auctions tab.

Optional (checks the category names the automated tests use; `docs/audit-classic-code.md`), with
the auction house open, paste each line into chat and take a screenshot of what it prints:

- [ ] 7. `/run for i,c in ipairs(AuctionCategories) do local t={} for _,s in ipairs(c.subCategories or {}) do t[#t+1]=s.name end print(i,c.name,table.concat(t,", ")) end`
- [ ] 8. `/run for _,s in ipairs(AuctionCategories[1].subCategories) do local t={} for _,x in ipairs(s.subCategories or {}) do t[#t+1]=x.name end print(s.name,table.concat(t,", ")) end`

## Before every release: the 5-minute check

Tyler (2026-10-07): the old 15-minute quick run was too long. This is one walk through the
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
one exists). One thing per step. If a step needs something the tester may not have (auctions
up, a second character, a rare item), say how to set it up or leave the step out (0.6.1 build 2,
step 6: two checks in one, the second needing auctions; Tyler found it confusing). The
pre-release check stays at six steps (Tyler's limit); do not move build steps into it. Older
detailed checklists: `docs/testing-history.md`.
