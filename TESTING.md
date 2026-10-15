# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.7 build 1

Gamepad support (`docs/gamepad.md`). Zip `auxForever-0.7-build1.zip`. **Full game restart**
needed (new file `gamepad.lua`). Test page build id `0-7-build-1`. Tested in game on 2026-10-13 by
the contributor (New theme): all steps below pass, taint log clean (nothing
blocked), no BugSack error. Not tested yet: the Classic theme, a PlayStation controller.

Set up: Forever's gamepad mode on (Options, Controls, gamepad), BugSack enabled. Steps, in the New
theme, using only the controller:

- [x] 1. Talk to an auctioneer: aux opens with a gold frame on a control of the Search tab and a
      strip under the window showing A, B, X and LB RB with your controller's icons.
- [x] 2. Move around the Search tab with the D-pad: the gold frame goes to the nearest control in
      each direction, and the strip's words change (a button: Select; a text box: Type).
- [x] 3. Gold frame on Rarity, A, down twice, A: Rarity changes to the option picked.
- [x] 4. Run a search, move onto a cheap result, A, then Y (Buy), then Y (Confirm): it is bought.
- [x] 5. Down past the last result shown: the list scrolls.
- [x] 6. RB through the tabs: each opens at once; after Bids the frame goes to Settings, Full scan
      and Blizzard UI. LB goes back.
- [x] 7. A on Settings: the frame stays inside the Settings popup; B closes it and aux stays open.
- [x] 8. Post tab: pick an item with A; reach -, + and Max with the D-pad and press them; Y posts.
- [x] 9. Post tab: X on an item in the bag list searches it on the Search tab.
- [x] 10. Sniper: Y starts it. A on a deal: once checked, the frame moves to Buy; A, then A
      (Confirm): it is bought. B on the buy bar goes back to the deal. Y stops it. (To get a deal
      soon, set "% of usual" to 100 and "profit at least" to 1c, then set them back.)
- [x] 11. Auctions tab: select an auction of yours, Y: it is cancelled (costs its deposit).
- [x] 12. B until aux closes: no popup, no freeze. Log out: no BugSack error.

Not checked by a test step: the post confirmation popup in gamepad mode (the server's warning did
not come up during testing; covered by the automated tests), Bids with Y (no bid was up).

The last build before this one, 0.6.1.1 build 1, was tested in game and released. Its steps and
results, kept for reference:

### 0.6.1.1 build 1

Fix for FB-011 (Gaddor): clicking an item's icon in the Post tab's bag list now selects it.
Zip `auxForever-0.6.1.1-build1.zip`. `/reload` is enough (no new files). Test page build id
`0-6-1-1-build-1`. 
Tested by Tyler on 2026-10-12 (screenshots): all 3 steps pass. Steps, in the New theme:

- [x] 1. Post tab: in the list of bag items on the left, click an item's **icon** (the picture, not
      the name). The item is selected: its row lights up and the price panel fills in.
- [x] 2. Click a different item's **name**. That item is selected (this worked before; check it
      still does).
- [x] 3. Right-click an item's **icon**. aux switches to the Search tab and searches that item.
## Current build: 0.7 build 4

FB-013 (HoaxBox): an iLvl column and the level column renamed Req, colored by how far it is from
your level. FB-012 (MDHippie): `AuxForeverAPI`, prices for other addons. Build 2 (Tyler, before
testing build 1): columns in the order iLvl, Req, Item, For sale, so the units for sale are not
next to the item levels. Build 3 (Tyler, testing build 2): after a fast resize to the smallest
window, the table's right columns ran past the edge; the tables now follow every resize. Build 4 (Tyler): "Req first always", so Req, iLvl, Item,
For sale. Zip `auxForever-0.7-build4.zip`. **Full game restart** if no 0.7 build was loaded after a restart (new
file `core/api.lua`), else `/reload`. Test page build id `0-7-build-4`.
Tested by Tyler on 2026-10-13 (test page, screenshots; only step 4 marked Pass, the others judged
from their screenshots): all 6 pass. Armor, Cloth listed Req, iLvl, Item, For sale with an item
level on every row (iLvl = Req + 5 throughout) and none for Linen Cloth; the Req colors at level 24
were right in both themes (29+ red, 27 to 28 orange, 25 yellow, 18 to 24 green, 17 and below
gray); sorting by Req works both ways (the screenshots sort Req, not iLvl); the API printed
`20 0` for Linen Cloth (20c, seen today; 851 were listed at 20c). Steps, in the New theme:

- [x] 1. Search tab: search a gear category (for example Armor, Cloth). The table starts with
      **Req**, then **iLvl**, then **Item**, then **For sale**, and every gear row has a number
      under iLvl. Search
      Linen Cloth: iLvl is empty.
- [x] 2. Same results: the Req numbers are colored by your level. At level 24: 29 and up red, 27
      to 28 orange, 25 to 26 yellow, 18 to 24 green, 17 and below gray.
- [x] 3. Click the iLvl header: the rows sort by item level; click again for the other way.
- [x] 4. With search results showing, drag the bottom right corner **fast**, all the way to the
      smallest size, a few times, also fast back and forth. Every time, the table ends inside the
      window: the % column is the last one and nothing runs past the right edge. Then look at
      Sniper, Auctions and Bids at the smallest size: iLvl, Req and their numbers fit.
- [x] 5. After a Full scan (or a search for Linen Cloth), paste in chat:
      `/run print(AuxForeverAPI.GetLatestPrice(2589))`. It prints two numbers: the price in copper
      (the Value in Linen Cloth's tooltip; 1s 25c prints 125) and how many days ago it was seen.
- [x] 6. Settings, theme Classic, `/reload`, and repeat step 2: the colors read well, the gray too.

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
