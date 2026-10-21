# Testing auxForever in game

Each test build gets a test page from Claude: one card per step with Pass, Fail and Skip, a note
and screenshots. Answers save by themselves and Claude reads them, so say "done" in the chat when
finished. The steps below are the same as on the page, for anyone testing without it.

If BugSack shows an error at any point, copy its full text into that step's note.

Current test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (private to Tyler)

## Current build: 0.8 build 5

Fixes from Tyler's test of build 4: the Post tab found no listings for gear with an ending
(Merc Sword of Agility: 4 listed at 16s, the Post tab showed none and took the usual price). Two
causes, each with a test that fails without its fix: the listings were filed under the old item
key while the Post tab reads them by the price key; and the listings counted as read after the
first version of the item, before the item's own name came, so the price was picked from the usual
one. Also new: "None for sale. Type a price to post." when nothing of that name is listed (Medicine
Staff of the Whale). Zip `auxForever-0.8-build5.zip`; `/reload` is enough. Test page build id
`0-8-build-5`.

- [ ] 1. Post tab, Merc Sword of Agility: once the bar turns gold, the table lists the swords of
      Agility for sale and the price line says "Same as the lowest listing". Screenshot.
- [ ] 2. Merc Sword of Healing: the same, with the Healing listings.
- [ ] 3. Medicine Staff of the Whale: once the bar turns gold, it says "None for sale. Type a price
      to post." (if nobody sells a Whale staff). Screenshot.

### 0.8 build 4

Fix from Tyler's test of build 3: the Post tab's bag list named gear without its ending, so two
Merc Swords with different endings were two rows that looked alike ("I think we failed this").
Rows, the item heading and "Posted 1 × ..." now show the full name. Zip
`auxForever-0.8-build4.zip`; `/reload` is enough. Test page build id `0-8-build-4`.

- [ ] 1. Post tab: gear in the bag list shows its ending ("[Merc Sword of the Eagle]"); two of one
      kind with different endings show two different names. Screenshot.
- [ ] 2. Pick the Medicine Staff: the heading shows its full name. Its listings are those of that
      exact name; if nobody sells that ending right now, the list is empty and Post says "Type a
      price to post". Compare with a Search tab search of the full name. Screenshot of both.
- [ ] 3. Only if you have gear with an ending up for sale: Auctions tab, its status (Tied, Undercut,
      Lowest) compares with listings of the same name. Skip otherwise.

Tested by Tyler 2026-10-20 (test page `0-8-build-4`, screenshots): step 1 passes (Medicine Staff
of the Whale, Merc Sword of Agility, Merc Sword of Healing). Step 2: the Whale staff showed no
listings, right (none listed in the search), but "Type a price to post" read as broken; Merc Sword
of Agility showed none though 4 were listed at 16s, a bug (fixed in build 5). Step 3 not done.

### 0.8 build 3

Tested by Tyler 2026-10-20 (test page `0-8-build-3`, screenshots, no marks): step 1 passes
(Medicine Staff of Arcane Protection Value 1g 15s, of the Wolf 1g 50s; the % column per ending);
step 2 failed as seen (two "[Merc Sword]" rows, split but named alike: fixed in build 4); step 3:
the Medicine Staff in the bags showed no listings, which is right only if nobody sold its ending
(not known, its name was hidden; build 4 step 2); step 4 unclear (Tyler's note "???", no gear of
his up); step 5 passes (Peacebloom posted).


Gear versions, the last 0.8 item: gear with a random ending is priced per ending (Tyler, 2026-10-20:
two Medicine Staffs of Arcane Protection have the same stats, so gear is grouped by name). Zip
`auxForever-0.8-build3.zip`. `/reload` is enough (no new files since build 2). Test page build id
`0-8-build-3`. Use the New theme.
Have two pieces of gear of one kind with different endings in your bags if you can (any "of the
..." items).

- [ ] 1. Search `medicine staff` (or any gear with endings), Full. Hover two rows with different
      endings. Value differs between endings (or says "?" for an ending aux has not priced yet; it
      learns it from this search, so hover again after the search). Screenshot.
- [ ] 2. Post tab: gear with two different endings shows as two items in the bag list. Skip if you
      have none.
- [ ] 3. Post tab, a piece of gear with an ending: the price matches the lowest listing of the same
      name (check it in a Search tab search of that name), not a cheaper ending. Screenshot. No need
      to post.
- [ ] 4. Auctions tab, if you have gear with an ending up: its status compares with the same name
      ("Tied with ...", "Undercut by ...", or "Lowest"). Skip if you have none up.
- [ ] 5. A trade good: post 1 as usual ("Posted 1"); Value in its tooltip as before.

### 0.8 build 2

Waylaid Crates (FB-020, Harro22; mockup options A and C, chosen by Tyler on 2026-10-20), on top of
build 1's gamepad support. Zip `auxForever-0.8-build2.zip`. **Full game restart** needed (new
files `gamepad.lua` and `tabs/search/crate.lua`). Test page build id `0-8-build-2`. Use the New
theme. Have a Waylaid Crate in your bags, and ideally a few of one of its bundle items.

Tested by Tyler 2026-10-20 (test page `0-8-build-2`, screenshots, no marks; judged from the
screenshots): steps 1, 3, 4, 5 and 6 pass, step 2 skipped. Journeyman Ore's tooltip listed 10
Silver Ore 1g 50s (gold, cheapest) and 20 Iron Ore 2g 19s 60c; Alt-click searched `[Silver
Ore];[Iron Ore]` and the bottom bar said "Crate  Journeyman Ore  cheapest fill  10 Silver Ore  1g
50s  next  20 Iron Ore  2g 18s 31c"; Recent listed "Crate  Journeyman Ore  (2 bundles)";
Shift-click searched the crate; a Linen Cloth posted ("Posted 1 × Linen Cloth").

- [ ] 1. Hover the crate in your bags. Under aux's Value line: "Cheapest way to fill it", then each
      bundle with a price (or "no price yet" for items aux has not seen), the cheapest in gold.
      Screenshot.
- [ ] 2. If you carry some of a bundle's item: that row says "(N in bags)" and is priced only for
      the rest. Skip if you carry none.
- [ ] 3. Open aux at the auction house, Alt-click the crate in your bags. The Search tab searches
      every bundle's item, and the bottom bar says "Crate  <name>  cheapest fill  ..." and "next
      ...". Screenshot.
- [ ] 4. Recent searches (the clock button, or Saved Searches): the search is listed as "Crate
      <name>  (N bundles)". Click it: it runs again with the same bottom line.
- [ ] 5. Shift-click the crate: aux searches the crate itself, as before.
- [ ] 6. With mouse and keyboard, post 1 of a cheap trade good: "Posted 1" (nothing else changed).

### 0.8 build 1

Gamepad support, contributed by nokkty (GitHub issue #27, `docs/gamepad.md`), brought onto
0.7.1.1. Zip `auxForever-0.8-build1.zip`. **Full game restart** needed (new file `gamepad.lua`).
Test page build id `0-8-build-1`. Use the New theme. nokkty tested all of it with a controller on
0.7 (section "0.7 build 1" below); these steps check that it still works on top of 0.7.1.1 and,
most of all, that nothing changed for mouse and keyboard players.

With mouse and keyboard (gamepad mode off):

- [ ] 1. Open aux: no strip under the window, everything as before. Post 1 of a cheap trade good:
      "Posted 1".
- [ ] 2. Search tab, a favorite search (star one first if you have none): right-click it. The
      game's usual popup asks "Are you sure you want to remove this search from your favorites?";
      Yes removes it.

With a controller: Tyler will not test these (2026-10-20); they are for players with a
controller who want to help. Options, Controls, turn on gamepad mode.

- [ ] 3. Talk to an auctioneer: aux opens with a gold frame on a control and a strip under the
      window showing the controller's buttons. Move with the D-pad; RB and LB switch tabs.
- [ ] 4. Search `linen cloth` (typing it on the keyboard is fine), then with the pad: move onto a
      result, A, then Y (Buy), then Y (Confirm): "Bought 1 × Linen Cloth".
- [ ] 5. Post tab: pick a trade good with A, wait until the bar at the bottom turns gold, press Y:
      "Posted". Pressing Y before the bar turns gold does nothing.
- [ ] 6. Press B until aux closes: no freeze, no popup. Log out: no BugSack error.

### 0.7 build 1 (gamepad, on nokkty's fork)

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

### 0.7.1.1 build 2


Fixes from FB-021 (sarrathsilentstrider could not post Rough Stone at 5c with the lowest at 7c)
and from the new slow auction house in the tests, which plays each tab against answers that come
a second later (`tests/slow_server.lua`, `tests/timing_test.lua`). Zip
`auxForever-0.7.1.1-build2.zip`; `/reload` is enough. Test page build id `0-7-1-1-build-2`. Use
the New theme. Have a cheap trade good several players sell (Linen Cloth, Rough Stone, Copper Ore)
and one cheap piece of gear. Build 2 adds gear with only a buyout (step 7) and a look at whether
Blizzard's window takes copper for gear (step 8); build 1 was not tested.

Tested by Tyler 2026-10-19 (test page `0-7-1-1-build-2`, screenshots): steps 1, 2, 5, 6 pass
(Light Feather listed at 7c: 4c typed and posted with Match lowest, 5c typed and posted with
Undercut on, "Your own price" both times; 1 Linen Cloth bought; Sniper watching with 97 deals).
Steps 3 and 4 could not be seen by hand: the listings arrive too fast ("I cant even move that
fast"); the timing tests cover them. Step 7: the sword was posted with bid equal to buyout (11s),
which Blizzard's list shows as buyout only; the empty starting bid case was not tried by hand
(covered by a test). Step 8: Blizzard's window has a copper box for gear, but the 10s 50c post
there does not seem to have gone through (`docs/forever-auction-house.md`, section 4).

- [ ] 1. Post tab: pick the trade good, wait until the bar at the bottom turns gold. Click the
      Buyout box, type a price 2c below the lowest listing, press Enter. Post is bright and the
      line under the price says "Your own price". Set the amount to 1 and Post: "Posted 1".
- [ ] 2. Click Undercut, then type a price 2c below the lowest again and press Enter. Post is
      bright. Post 1: "Posted 1".
- [ ] 3. Pick another item and, before the bar turns gold, type a price in the Buyout box. When
      the bar turns gold, your price is still there ("Your own price"). No need to post.
- [ ] 4. Pick another item and look at the Post button right away: faded, "Reading the
      listings..." next to it, until the bar turns gold. Skip if it is too quick to see.
- [ ] 5. Search `linen cloth` and buy 1 (Buy, then Confirm): "Bought 1 × Linen Cloth".
- [ ] 6. Sniper: Start. When a deal shows up, click it, then click it again to let go: the status
      goes back to "Watching" and the rounds go on. Skip if no deal shows up in a few minutes.
- [ ] 7. Post tab, a piece of gear: clear the Starting bid box (right-click it), type a buyout,
      press Enter. Post is bright and the note says "No starting bid, so it posts as buyout
      only". Post it at a price you are happy with: "Posted 1".
- [ ] 8. Blizzard UI button, Sell tab, put a piece of gear in: does its price box have a copper
      field (g, s and c), or only gold and silver? Screenshot. This decides whether aux may keep
      rounding gear prices to whole silver.

### 0.7.1 build 3

Build 3 takes out two things from build 2, after Tyler's test (2026-10-17): the deposit rounding
(Forever returns `SupportsCopperValues()` true, so it never applied) and the "Post tab starts on"
setting (Tyler: keep it as it is). The rest is build 2 (FB-014 to FB-016), tested. Zip
`auxForever-0.7.1-build3.zip`; `/reload` is enough. Test page build id `0-7-1-build-3`.
Tested by Tyler 2026-10-17 (screenshots): all 6 pass. Settings shows only Default duration;
Undercut stayed on across posts and reset on reopening; the item keys printed (below); the
Auctions tab said "Tied with 4 others" at 6s for Ritual Belt of Arcane Protection, which matches
the 5 listed under its exact key (his own plus 4); Classic shows one row per auction. Steps:

- [ ] 1. Settings (gear): Posting has only Default duration (no "Post tab starts on").
- [ ] 2. Post tab: click Undercut, post one cheap item, pick another item, post it. Both in
      Undercut mode. Close the auction house and open it again: Match lowest.
- [ ] 3. Post one cheap piece of gear that others also sell (Ritual Bands, or any green gear with
      several listings), then paste in chat:
      `/run for i=1,C_AuctionHouse.GetNumOwnedAuctions() do local a=C_AuctionHouse.GetOwnedAuctionInfo(i) local k=a.itemKey print("mine",a.itemLink,k.itemID,k.itemLevel,k.itemSuffix) end`
      Screenshot the chat.
- [ ] 4. In aux, search that item's name (Full mode), then paste:
      `/run for _,r in ipairs(C_AuctionHouse.GetBrowseResults()) do local k=r.itemKey print("listed",k.itemID,k.itemLevel,k.itemSuffix,r.totalQuantity,r.minPrice) end`
      Screenshot the chat and aux's results.
- [ ] 5. Auctions tab, Check prices: screenshot the row (Lowest other, Status) next to Blizzard's
      Sell tab for the same item.
- [ ] 6. Theme Classic, `/reload`, Auctions tab with that auction up: one row per auction.

### 0.7.1 build 2

Tested by Tyler 2026-10-17 (test page `0-7-1-build-2`, screenshots): two identical Ritual Bands
of Spirit showed as two rows; both cancelled and left the list; "tigerstrike mantle" found 2 in
aux and in Blizzard's window; `SupportsCopperValues()` is true; deposits matched the game for
Linen Cloth and Ritual Bands (1s each, 1s taken); "Post tab starts on" worked but Tyler did not
want it. The Classic step could not be done (no auctions left). Seen on the side: the Auctions tab
said "Only one listed" for the Ritual Bands while aux's Post tab had listed others of the same
version a minute before (9s, 1g 55s); steps 3 to 5 of build 3 check it.

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
