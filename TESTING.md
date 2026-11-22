# Testing auxForever in game

Each test build has its steps under "Current build" below. Tyler runs them in game and answers in
the chat: Pass or Fail for each step by its number, a note where something looked wrong, and
screenshots. The engineer (Gemini Neon since 2026-11-19) writes the answers under the build as
"Results". Until 2026-11-19 Claude made a claude.ai test page per build; everything those pages
saved is exported in `docs/test-results/test-page-results.md`.

If BugSack shows an error at any point, copy its full text into that step's note.

## Current build: 0.9 build 4 (tested 2026-11-22)

Built 2026-11-22 (Gemini Neon, commit `79e40dc`): Phase 3 **Narrower Sniper** (`FB-055`: Option A
slim Watch bar with quick chips, **More...** menu for Forever Categories + Search Favorites, and
**Quality** picker), **Default buy quantity** (`FB-066`: `1` vs `Stack` under Settings > Buying +
`/aux buy quantity`), Fast tooltip-word search fix on random-suffix greens (`FB-064`, RushJet1), and
right-column Settings hover tooltips anchored to the left so they stay inside the window.
Zip `auxForever-0.9-build4.zip`; **`/reload` is enough** if you already installed Build 2 or 3 (a
full game restart is only needed if upgrading from before Build 2 because of `Bindings.xml`).

- [x] 1. Narrower Sniper Watch bar and fast category rounds (`FB-055`). Open the **Sniper** tab and
      check that the new slim **Watch** bar sits cleanly below Start/Stop with **All**, **Trade
      Goods**, **Consumables**, **Recipes**, **More... v**, and **Quality: Common+ v** (no overlap
      with the Deals row or Buy bar). Click **Trade Goods** and click **Start**: confirm round 1
      finishes in a few seconds instead of ~38s+. While Sniper is still running, click
      **Consumables** (or pick **Rare+** under Quality): confirm it restarts right away instead of
      waiting for the old round to finish.
- [x] 2. Narrower Sniper with Search Favorites (`FB-055`). On the Search tab, make sure you have at
      least one Favorite pinned (for example search `linen cloth/exact;copper ore/exact` and star/pin
      it). Switch to the **Sniper** tab, click **More... v**, confirm both **CATEGORIES** and
      **SEARCH FAVORITES** appear cleanly, click your Favorite, and confirm the button shows its
      name and Sniper watches just that search.
- [x] 3. Default buy quantity (`FB-066`) and right-column tooltip anchor. Open **Escape > Options >
      AddOns > auxForever** (or type `/aux settings`). Point the mouse at **Stack prices by default**
      on the right column: confirm the hover tooltip now opens to the left inside the window. Under
      **BUYING**, confirm **Default quantity** shows `1` and `Stack` (`1` highlighted). Click
      **Stack**, go to Search, search `linen cloth/exact`, click the row, and confirm the buy bar
      starts at `20` (full stack). Click **1** in Settings (or type `/aux buy quantity 1`) and
      confirm selecting another trade good starts at `1` again.
- [x] 4. Fast tooltip-word search on generic green rings (`FB-064`). On the **Search** tab in
      **Fast** mode, run `armor/miscellaneous/finger/spell` (or `armor/miscellaneous/finger/healing`).
      Confirm generic green rings with `Equip:` spell/healing stats (such as `"of the Channeler"` or
      `"of Healing"`) now appear in Fast mode.
- [x] 5. Optional 0-gold `FB-064` sample-link diagnostic. Right after running
      `armor/miscellaneous/finger` in Fast mode, paste this line in chat and share what `FB64:`
      prints (checks the first random-suffix ring to tell us whether Forever populated
      `GetItemKeySampleLink` or used our fallback):
      `/run local C=C_AuctionHouse for _,x in ipairs(C.GetBrowseResults())do local k=x.itemKey if(k.itemSuffix or 0)~=0 then local i=C.GetItemKeyInfo(k)print('FB64:',i and i.itemName,C.GetItemKeySampleLink(k)~=nil)break end end`
- [x] 6. Clean standalone E10 probe (0 gold, idle at AH). Make sure Sniper is **stopped** and no
      Full scan is running, wait 2 seconds, paste Line 1 and press Enter:
      `/run local C=C_AuctionHouse print('E10 send:',C.IsThrottledMessageSystemReady()) C.SearchForItemKeys({C.MakeItemKey(2589),C.MakeItemKey(2770),C.MakeItemKey(2447),C.MakeItemKey(2835)},{{sortOrder=0,reverseSort=false}})`
      Wait 3 seconds, paste Line 2 and press Enter, and share `E10 send:` and `E10:`:
      `/run local r=C_AuctionHouse.GetBrowseResults() print('E10:',#r,C_AuctionHouse.HasFullBrowseResults(),r[1] and r[1].itemKey.itemID,r[1] and r[1].minPrice,r[2] and r[2].itemKey.itemID)`

### Results (Tyler, 2026-11-22)

All 6 steps verified from Tyler's notes and screenshots (0 Lua errors):
1. Narrower Sniper Watch bar and fast category rounds (`FB-055`): **Pass** (screenshot confirmed
   clean Watch bar alignment with zero overlap against Deals or Buy bar; Trade Goods rounds ran
   `491 items in 0.1s` to `0.2s`, reaching round 52 cleanly, compared to `37.7s` for the whole AH.
   Zero usual-price deals appeared because the notice showed `2` days of Full scans so far after
   Tyler's recent data wipe, needing 3 days).
2. Narrower Sniper with Search Favorites (`FB-055`): **Pass** (screenshot confirmed `More... v`
   popup renders cleanly above the table with all 9 Forever `CATEGORIES` and `SEARCH FAVORITES`
   below).
3. Default buy quantity (`FB-066`) and right-column Settings tooltip anchor: **Pass** (explicitly
   marked Pass by Tyler).
4. Fast tooltip-word search on generic green rings (`FB-064`): **Pass** (2 screenshots confirmed
   Fast mode returned 30+ generic green rings with `Equip:` spell stats, including multiple
   `"of the Channeler"`, `"of the Prophet"`, `"of the Sorcerer"`, and `"of the Hierophant"` rings,
   with `Equip: Increases healing done by spells and effects...` visible in hover tooltips).
5. Optional `FB-064` sample-link diagnostic: **Settled [Seen]** (chat printed
   `FB64: Marble Ring of Fire Protection true`, confirming `C_AuctionHouse.GetItemKeySampleLink`
   returns a real sample link during browse on Forever so Fast tooltip-word searches match with 0
   extra requests).
6. Clean standalone E10 probe (`SearchForItemKeys`): **Settled [Seen]** (chat printed
   `E10 send: true` while idle, followed 3 seconds later by `E10: 0 true nil nil nil`. Confirmed
   Forever's `C_AuctionHouse.SearchForItemKeys` answers cleanly with 0 results even for common trade
   goods; keep using `SendBrowseQuery`).

## 0.9 build 3 (tested 2026-11-22)

Built 2026-11-22 (Gemini Neon): Phase 2 Blizzard **Options > AddOns > auxForever** settings panel
and `/aux settings` (`FB-057`), plus Build 2's approved visual and UX follow-ups: minimalist Option
B item tooltips (no `for N`, compact `today` / `3d` / dimmed `9d`), aligned Professions crafting
hover tooltip (`today` and `(%)` before prices), **Right-click bag to sell** on by default
(`FB-062`), approved UI wordiness trims (`T1` to `T6`), and extra bottom breathing room in the AH
Settings gear popup.
Zip `auxForever-0.9-build3.zip`; **`/reload` is enough** if you already installed Build 2 (a full
game restart is only needed if upgrading directly from 0.8.2.2 or Build 1 because of
`Bindings.xml`).

- [x] 1. Minimalist item tooltips (Option B). Open your bags and point the mouse at a stack of more
      than 1 item (for example a stack of Elixir of Wisdom or Linen Cloth) without holding Shift.
      Confirm `for N` is gone from Vendor and Value, Value shows the full stack price with a compact
      age (`today`, `1d`, `3d`, or darker `9d`), and holding Shift drops Vendor and Value to the
      plain 1-item price.
- [x] 2. Aligned Professions crafting hover tooltip (`T5`). Open a Professions window, pick a recipe
      that uses multiple materials (for example Elixir of Wisdom or Rough Sharpening Stone), and
      point the mouse at the **Materials** line under the reagents without clicking. Confirm the
      subtitle reads `From your latest scans`, the age (`today`, `3d`, or `vendor`) and `(% )` sit
      in front of each cost so all prices line up down the right edge, the output row shows the item
      name without `sells for`, and the cut row reads `After 5% AH cut`.
- [x] 3. Blizzard Options > AddOns > auxForever and `/aux settings` (`FB-057`). Away from the
      auction house, type `/aux settings` in chat and press Enter. Confirm Blizzard's Options window
      opens straight to **AddOns > auxForever** with the two-column layout, **Clear post prices**
      and **Clear item cache** buttons at the bottom, and the keybinds note on the bottom left. Also
      try opening it through **Escape > Options > AddOns > auxForever** and flipping a switch (for
      example **Confirm before buying**): walk to the auction house, click the Settings gear (top
      right), and confirm that same switch already matches (and that the bottom of the gear popup
      has clean breathing room).
- [x] 4. Maintenance Clear buttons with confirmation (`FB-057`). In **Options > AddOns >
      auxForever**, click **Clear post prices** (or **Clear item cache**): confirm a Blizzard
      confirmation popup appears first, click **Cancel**, and confirm nothing was cleared. (Only
      click **Accept** if you actually want to wipe saved Post prices or the item cache; if you test
      Accept on Clear item cache, names rebuild automatically as you play.)
- [x] 5. Right-click bag to sell default on (`FB-062`) and UI trims (`T1` to `T6`). Check Settings
      to confirm **Right-click bag to sell** starts on (note: if you toggled it off during Build 2,
      your saved toggle is preserved; typing `/aux right click post on` turns it on). Glance at the
      trimmed labels: on the Search tab with nothing selected, the buy bar reads `Gear: one at a
      time. Trade goods: cheapest first.`; selecting gear reads `N at this price`; on the Post tab
      the receipt reads `AH cut (5%)` and `Deposit`; on the Sniper tab while watching with no deals,
      the shorter 2-line message appears.

### Results (Tyler, 2026-11-22)

All 5 steps passed in game:
1. Minimalist item tooltips (Option B): Pass.
2. Aligned Professions crafting hover tooltip: Pass.
3. Blizzard Options > AddOns > auxForever and `/aux settings`: Pass (screenshot confirmed clean
   two-column layout inside Blizzard Options, `auxForever 0.9` header, synced switches, keybinds
   note, and Clear buttons; `Settings.RegisterCanvasLayoutCategory` / `Settings.OpenToCategory` now
   confirmed **Seen** on Forever; noticed right-column hover tooltip uses `ANCHOR_RIGHT` and can
   clip near the right edge of the window, worth flipping right-column rows to `ANCHOR_LEFT`).
4. Maintenance Clear buttons with confirmation: Pass.
5. Right-click bag to sell default on and UI trims `T1` to `T6`: Pass.

## 0.9 build 2 (tested 2026-11-21)

Built 2026-11-21 (Gemini Neon): Phase 1 QoL switches, keybinds, cleaner tooltip ages, and S-09.
Adds full-stack tooltip prices by default with Shift for 1 item (`FB-058`), live Professions cost
line toggle (`FB-061`), right-click bag item to always open Post (`FB-062`), Auto Full scan on AH
open (`FB-032`), `Bindings.xml` buy/confirm/cancel keybinds (`FB-063`), removes `seen ` from
tooltip ages, and hides bogus "Starting bids" totals on trade goods with no buyout (`S-09`).
Zip `auxForever-0.9-build2.zip`; **full game restart required** (adds new file `auxForever/Bindings.xml`).

- [x] 1. Full-stack tooltips by default and no `seen ` prefix (`FB-058`). Open your bags and point
      the mouse at a stack of more than 1 item (for example a stack of Linen Cloth) WITHOUT holding
      Shift: Vendor and Value show the stack total with `for N` and an age without `seen ` (for
      example `today` or `1 day ago`). Now hold Shift on that same stack: Vendor and Value drop to
      the plain single-item price (no `for N`).
- [x] 2. Settings switches (`FB-061`, `FB-062`, `FB-032`). Open the auction house and click the
      Settings gear (top right). Check that all rows fit cleanly inside the popup with no overlap:
      Right-click bag to sell, Auto Full scan, Professions cost line on the left; Stack prices by
      default on the right. Open a Professions window, flip **Professions cost line** off then back
      on: the Materials and Profit line under reagents disappears and reappears immediately with no
      `/reload`.
- [x] 3. Right-click bag item to sell (`FB-062`). Turn **Right-click bag to sell** on in Settings,
      click the Search tab, then right-click a sellable item in your bags: aux switches to the Post
      tab and loads that item. Click back to Search and Shift-click a bag item: it still searches
      on the Search tab instead of switching to Post.
- [x] 4. Keybinds (`FB-063`, after full game restart). Press Escape > Options > Keybindings and
      scroll to the **auxForever** section. Confirm all 4 bindings appear: **Buy**, **Confirm
      purchase**, **Cancel / decline purchase**, and **Buy or confirm**. Bind one (for example Buy
      to a spare key, or Confirm/Cancel with "Confirm before buying" on), open Search, search
      `linen cloth/exact`, click the cheapest row, and test pressing your bound key. (If you turn
      on Confirm before buying, pressing Buy twice should NOT confirm; pressing Cancel should
      cancel without spending gold.)
- [x] 5. Post receipt with no price (`S-09`). On the Post tab, click a trade good (like Linen
      Cloth) in your bags, click the Price box, and delete the price so the box is blank: the
      receipt on the right reads `Total, N items` with `-` for Total, Cut, and You get (never
      `Starting bids` and no red vendor warning).
- [ ] 6. Clean re-test of E9: 1-request gear lookup (0 gold). **Make sure Sniper is stopped and no
      Full scan is running.** Put any piece of green gear with a random ending into the very first
      slot of your backpack (top-left slot of bag 0). At the auction house, paste line 1 and press
      Enter:
      `/run local C=C_AuctionHouse local id=C_Container.GetContainerItemID(0,1) _G.E9=id and C.MakeItemKey(id) print('E9 send:',id,C.IsThrottledMessageSystemReady()) if E9 then C.SendSellSearchQuery(E9,{{sortOrder=0,reverseSort=false}},false) end`
      Wait 3 seconds, paste line 2 and press Enter, and share both `E9 send:` and `E9:` lines (or
      a chat screenshot):
      `/run local C=C_AuctionHouse local n=C.GetNumItemSearchResults(E9) local r=C.GetItemSearchResultInfo(E9,1) print('E9:',E9.itemID,n,C.HasSearchResults(E9),r and r.itemLink,r and r.auctionID)`
- [ ] 7. Clean re-test of E10: 1-request batch watch list (0 gold). Still idle at the auction house
      (no Sniper, no Full scan), paste line 1 and press Enter:
      `/run local C=C_AuctionHouse print('E10 send:',C.IsThrottledMessageSystemReady()) C.SearchForItemKeys({C.MakeItemKey(2589),C.MakeItemKey(2770),C.MakeItemKey(2447),C.MakeItemKey(2835)},{{sortOrder=0,reverseSort=false}})`
      Wait 3 seconds, paste line 2 and press Enter, and share both `E10 send:` and `E10:` lines (or
      a chat screenshot):
      `/run local r=C_AuctionHouse.GetBrowseResults() print('E10:',#r,C_AuctionHouse.HasFullBrowseResults(),r[1] and r[1].itemKey.itemID,r[1] and r[1].minPrice,r[2] and r[2].itemKey.itemID)`

### Results (Tyler, 2026-11-21)

1. Pass (screenshot: Elixir of Wisdom stack of 13 shows `Vendor: 13  for 13` and `Value: 13 (93%)  for 13  today`; Tyler wants `"for 13"` removed and cleaner minimalist age styling, mockup first).
2. Pass (2 screenshots: Settings popup fits cleanly, bottom-left row slightly tight to bottom border; Professions hover tooltip works; Tyler wants percentages in front of prices so cost numbers align down the right edge).
3. Pass (Tyler: invert default to **on** so it welcomes players coming from Blizzard's default AH).
4. Pass (`Bindings.xml` confirmed working in game after full restart).
5. Pass (screenshot: Elixir of Minor Defense with `0c` shows `Total, 16 items -`, `Auction house cut 5% -`, `You get -`, `vendor pays 80c`, no `Starting bids`, no red warning).
6. `E9 send: 4567 true`, `E9: 4567 0 true nil nil` (`HasSearchResults == true` confirmed server answered for item 4567 with 0 listings; still Unknown whether suffixed variants return when listed).
7. `E10 send: false`, `E10: 0 false nil nil nil` (throttle was still busy right after E9, so E10 was not sent; remains Unknown).
All 6 UI wordiness trims approved (`T1` to `T6`).

## 0.9 build 1 (tested 2026-11-21)

Built 2026-11-21 (Gemini Neon): 0.9 foundation pass. Fixes FB-056 (dungeon/tooltip Lua error
hardening and 7 missing tooltip stack-count readers), adds a timeout for Forever's frozen AH
throttle (`wait_throttle`), fixes Sniper duplicate K^2 gear requests and its wiped "Bought ..."
message, fixes Search splitting one gear ending into two rows, fixes synchronous Buy/Post/Cancel
events and multi-item Post hangs, prevents scan timeouts from wiping rows or marking Sniper deals
"Sold", adds scan priority rules, and fixes Buy bar and Waylaid Crate caching quirks.
Zip `auxForever-0.9-build1.zip`; `/reload` is enough (no new files).

- [x] 1. Tooltip stack counts and no errors (FB-056). Open your mailbox (if you have mail with a
      stacked item) or a vendor window, hold Shift, and point the mouse at a stack of items (for
      example a stack of Linen Cloth). The tooltip shows Vendor and Value with `for N` (matching
      the stack size), with no BugSack error. Also watch for any Lua errors if you run a dungeon
      where someone makes conjured water.
- [x] 2. Buy bar guard and Post check. On the Search tab, search `linen cloth/exact`, click the
      cheapest row, click the QUANTITY box, delete the `1` so the box is empty, and press Enter:
      nothing is bought. Then switch to the Post tab, pick an item you want to sell, and post one:
      it posts cleanly with no 5-second hang.
- [ ] 3. Sniper bought confirmation (optional: only if you see a cheap deal worth buying). On the
      Sniper tab, click Start, click a deal you want, and click Buy. After the purchase finishes,
      the bottom bar keeps the green "Bought 1 x ..." message on screen instead of immediately
      flipping back to "Select a row to buy it", and the Buy button hides.
- [ ] 4. Experiment E9: 1-request gear lookup (spends 0 gold). Put any piece of green gear with a
      random ending (for example Merc Sword of the Owl or Ritual Belt of Healing) into the very
      first slot of your backpack (top-left slot of bag 0). Open the auction house, paste line 1
      into chat and press Enter:
      `/run local C=C_AuctionHouse C.SendSellSearchQuery(C.MakeItemKey(C_Container.GetContainerItemID(0,1)),{{sortOrder=0,reverseSort=false}},true)`
      Wait 2 seconds, paste line 2 into chat and press Enter, and copy the `E9:` line into your
      reply:
      `/run local C=C_AuctionHouse local k=C.MakeItemKey(C_Container.GetContainerItemID(0,1)) local n=C.GetNumItemSearchResults(k) local r=C.GetItemSearchResultInfo(k,1) print('E9:',n,r and r.itemLink,r and r.auctionID)`
- [ ] 5. Experiment E10: 1-request batch watch list (spends 0 gold). Still at the auction house,
      paste line 1 into chat and press Enter:
      `/run local C=C_AuctionHouse C.SearchForItemKeys({C.MakeItemKey(2589),C.MakeItemKey(2770),C.MakeItemKey(2447),C.MakeItemKey(2835)},{{sortOrder=0,reverseSort=false}})`
      Wait 2 seconds, paste line 2 into chat and press Enter, and copy the `E10:` line into your
      reply:
      `/run local r=C_AuctionHouse.GetBrowseResults() print('E10:',#r,r[1] and r[1].itemKey.itemID,r[1] and r[1].minPrice,r[2] and r[2].itemKey.itemID,r[2] and r[2].minPrice)`

### Results (Tyler, 2026-11-21)

1. Pass (stack counts show; asked for FB-058 full-stack default next). 2. Pass (empty Quantity box
+ Enter buys nothing). 3. Not tested (2 of 3 Full scan days recorded so far; screenshot confirmed
scan priority kept an active Full scan running while Sniper stayed on Watching). 4 & 5. Both printed
`0 nil nil` while Full scan and Sniper were active; inconclusive, carried to build 2 idle probes.
Build 2 preferences chosen: FB-058 Shift label plain (`Value: 5s`), include `S-09` in build 2.

## 0.8.2.2 build 4 (passed, Tyler, 2026-11-20)

Built 2026-11-20 (Gemini Neon): adds build 3's quarter-second rest after buying (not tested yet) plus
two contributor pull requests: gamepad item comparison beside aux's window (PR #41, nokkty) and
Full scan cooldown/no-answer feedback (PR #37, Dragoy; most of PR #37 already shipped in 0.8.2).
Zip `auxForever-0.8.2.2-build4.zip`; `/reload` is enough (no new files).

- [x] 1. The rest after buying (FB-051, carried over from build 3). Search tab: search
      `linen cloth/exact`, click the cheapest row, keep `1` picked, click Buy and then at once click
      it again. The bar says "Bought 1 × Linen Cloth", the button is faded only for a blink, and
      chat shows one "You won an auction for Linen Cloth (x1)" line. In your reply: Pass or Fail,
      and does the rest still feel too long?
- [x] 2. Mouse tooltip sanity check. On the Search tab, point the mouse at the icon of any gear row
      (for example `linen belt/exact`). The item's tooltip still shows next to the mouse as before
      (and your equipped comparison tooltip if you wear something in that slot), with no BugSack
      error.
- [ ] 3. Only if you play with a gamepad; otherwise Skip (PR #41, nokkty). Turn on gamepad mode.
      Search `usable/weapons` (Fast), press D-pad down onto a gear row for a slot where you wear
      something: the item's tooltip appears to the right of aux's window (or left if aux sits on the
      right edge of the screen), and your worn item's comparison stacks directly under it. Press
      D-pad down past the bottom row to scroll: both tooltips follow each row. Press D-pad left or
      right to leave the list: both tooltips disappear.

### Results (Tyler, 2026-11-20)

1. Pass. 2. Pass (screenshot: Linen Belt tooltip and Equipped comparison tooltip show next to the
mouse as before, with click hints). 3. Skipped (controller test left to gamepad users; PR #41 was
tested in game by nokkty and covered by automated tests).

## 0.8.2.2 build 3 (not tested; superseded by build 4)

Built by Claude on 2026-11-19 as the last change before the takeover. The only change from build 2:
Buy rests a quarter second after a purchase (half a second in build 2, which Tyler found "still
feels too long"; FB-051). Its check is step 1 of build 4.

## 0.8.2.2 build 2 (tested 2026-11-17)

Build 1 passed every step (Tyler, 2026-11-17). Build 2 makes the Sniper and Live faster (FB-055):
the Sniper leaves gray items out of its list and waits 1 second between rounds (2.5 before), Live
waits 2 seconds (5 before), and Buy rests half a second after a purchase (1 in build 1). Zip
`auxForever-0.8.2.2-build2.zip`; `/reload` is enough (no new files). Test page build id
`0-8-2-2-build-2`. Step 3 buys one Linen Cloth.

- [ ] 1. Sniper round time. Sniper tab, click Start and let it run until the line under Start says
      "round 4" or more (the first round after logging in or a Full scan is the longest). Write
      that line in the note, for example "round 4, 9,812 items in 11.3s".
- [ ] 2. Live every 2 seconds. Search tab: search `linen cloth/exact`, then click Live. After the
      first round the button counts "Live 2s", "Live 1s", then "Updating", over and over. Click
      Live again to stop.
- [ ] 3. Half a second rest. Click the cheapest Linen Cloth row, keep 1 picked, click Buy and at
      once click it again. The bar says "Bought 1 × Linen Cloth", the button is faded only very
      briefly, and one Linen Cloth is bought (one "You won an auction" line in chat).
- [ ] 4. The Sniper still finds deals. Leave it running a few minutes. If a deal shows, click it:
      the bar offers it with Buy. Nothing to buy; write whether any deal showed.
- [ ] 5. A question. Type `/aux debug list` in chat and copy the line it prints ("Item list of the
      whole auction house: ... items in ..."). It counts gray items too, so with step 1 it tells how
      much leaving grays out saved.

### Results (Tyler, 2026-11-17, test page `0-8-2-2-build-2`)

1. Round 1: "25187 items in 153.8s" (screenshot taken during round 2; 70 deals listed). 2. Live
counts from 2s: pass. 3. The half second rest: "It still feels too long". 4. Deals show and offer
Buy: pass. 5. `/aux debug list`: "25706 items in 37.7s (52 requests)" (it takes the list's whole
time before it prints).

## 0.8.2.2 build 1 (passed, Tyler, 2026-11-17)

Buying fixes from the CurseForge comments on 0.8.2.1 (FB-049 to FB-052): the buy bar starts at 1,
Buy rests for a second after a purchase, the new "Confirm before buying" setting (trade goods and
gear), and `/aux post bid on`. Zip `auxForever-0.8.2.2-build1.zip`; `/reload` is enough (no new
files). Test page build id `0-8-2-2-build-1`. Steps 2, 4 and 5 spend a few coppers and about 1s.

- [ ] 1. Starts at 1 (FB-050). Search tab: search `linen cloth/exact` and click the cheapest row,
      nothing else. Look at the bar under the results: the QUANTITY box says 1 and the big button
      on the right says "Buy 1 for" and a price. Nothing is bought yet. Screenshot the bar.
- [ ] 2. No double buy (FB-051). Still on that row, with 1 picked, click Buy and then at once click
      the same button again, as you used to for Confirm. The bar says "Bought 1 × Linen Cloth for"
      and a price, and the button looks faded for about a second, then lights up again. In the
      note: did the second click buy another one? (At a mailbox later: how many Linen Cloth came
      from this step; 1 is right.)
- [ ] 3. The new setting (FB-049). Click the gear in aux's top bar (Settings). In the left column,
      under POSTING, there is a BUYING heading with "Confirm before buying" and a switch, off.
      Turn it on. Screenshot the Settings window (this is the layout check, as there was no
      mockup).
- [ ] 4. Confirm with a trade good. Back on `linen cloth/exact`, click the cheapest row, 1 picked,
      click Buy once. The button turns into "Confirm" and a price, a Cancel button appears to its
      left, and the line says "Nothing is bought until you confirm". Click Cancel: the bar says
      "Cancelled" and "Nothing was bought". Click Buy again, then Confirm: "Bought 1 × Linen
      Cloth".
- [ ] 5. Confirm with gear. Search `linen belt/exact` (or any cheap gear) and click its cheapest
      row. Click Buy once: the button turns into "Confirm" and the price, with Cancel next to it.
      Click Confirm: "Bought 1 × Linen Belt for" and the price. Then type `/aux buy confirm` in
      chat: it says "buy confirm off", and the switch in Settings is off again.
- [ ] 6. `/aux post bid on` (FB-052). Type `/aux post bid on` in chat: it says "post bid unit".
      Type `/aux post bid off`: it says "post bid off". Type `/aux post bid yes`: it changes
      nothing and lists the choices (on, off, unit or stack).

## 0.8.2.1 build 7 (released as 0.8.2.1 on 2026-11-16, with the crate heading renamed)

Build 6 (a price row of many sellers keeps 20 auctions and counts the rest, review S-08) was not
tested on its own; build 7 holds it and the fixes from the 2026-11-16 feedback: one click buys a
trade good (no Confirm), gear takes copper prices, the "on your mouse pointer" message, the crate
tooltip switch, and Fast row tooltips. Zip `auxForever-0.8.2.1-build7.zip`; `/reload` is enough
(no new files). Test page build id `0-8-2-1-build-7`. Steps 1 to 6 are build 6's.

- [ ] 1. Search tab: click Full (next to Fast), type `linen` and press Enter. Wait until the line
      next to the sub tabs ends in "searched just now". No popup comes up, and that line has no red
      "table full" part. Its first number is how many items were found (build 4 showed 20 of the
      36 it read). Screenshot the aux window.
- [ ] 2. In those results, find a gear line whose Seller column says many sellers, for example
      "585 sellers" next to Linen Belt (if the item is folded up, click it to see its prices). Its
      "For sale" number should be well above 20. Screenshot that line.
- [ ] 3. Buying from a row of many sellers. This spends a little gold: 17 of a cheap piece of gear,
      about 17s for Linen Belt at 1s. Search `linen belt/exact` (or another cheap item from step 2),
      click its line with the most sellers and write down its "For sale" number. Then press Buy 17
      times, each time waiting for the button to light up again. Each time the button should say
      the same price, that line should stay selected, and "For sale" should go down by one. Around
      the 16th, aux reads the item again by itself; the line may flicker, keep going. In the note:
      the "For sale" number before and after, and whether any purchase cost more than the button
      said. Screenshot at the end.
- [ ] 4. With `linen belt/exact` still in the search bar, click Live. Wait until it has counted
      down twice ("Live 5s" to 0). The line next to the sub tabs does not say "too many for Live",
      and the Linen Belt line still shows its full "For sale" number. Click Live again to stop it.
- [ ] 5. A question (from build 5). Click the search bar and slowly type `line`. When the bar has
      filled in "linen cloth/exact", press Tab once, then type a slash (/). Write what the bar reads
      now, what happened when you pressed Tab, and what you wanted Tab to do (FB-040).
- [ ] 6. A question (from build 5); no need to scan again if you remember. While the Full scan's
      bar said "reading auctions", did the game stay smooth or stutter?
- [ ] 7. Buying with one click. Search `linen cloth/exact`, click the cheapest row, and click Buy
      once with 1 picked (the "1" button). The button says "Buying...", then the bar says "Bought
      1 × Linen Cloth for" and a price. There is no Confirm button. The price it says is the one
      the Buy button showed, or lower.
- [ ] 8. Copper on gear (FB-044). Post tab: pick a cheap white or green item from your bags (not a
      trade good), type `1s 89c` as the buyout and leave the starting bid empty, then Post. It
      says "Posted". Then the Auctions tab lists it at 1s 89c. If it says "Not posted", copy the
      whole message.
- [ ] 9. Undercut on gear. Still on the Post tab, pick a piece of gear that someone else sells,
      and click the goblin (undercut) switch: the line under the price reads "1 copper below the
      lowest listing". Screenshot the Post tab.
- [ ] 10. The stat of an ending (FB-045). Search `of healing` with Fast picked. Point the mouse at
      the icon of a row, without clicking: does the tooltip show the healing line? Then click
      Full, search again and point at a row the same way. Write which showed it (Fast, Full,
      both, neither). The same with `of shadow protection` if you have time.
- [ ] 11. Crate lines switch (FB-041), only if you have a Waylaid Crate. Point at the crate in your
      bags: under the game's text, "Cheapest way to fill it" and the bundles, with no "Latest
      prices" line under it. Open Settings (the gear in aux's top bar): "Waylaid Crates" in the
      tooltip column. Turn it off and point at the crate again: aux's lines are gone. Turn it
      back on.

### Results (Tyler, 2026-11-16, test page `0-8-2-1-build-7`)

Read from his screenshots and notes; no step was marked Pass or Fail.
- 1, Full search `linen`: passes. "37 items, 36,739 for sale, searched just now", no "table full"
  (build 4 showed 20 of 36). Linen Belt: 550 for sale, 548 sellers, 1s.
- 2, a line of many sellers: passes. Tyler: "I dont know if this worked, I couldnt even unfurl linen
  belt but I could linen bag". As built: all 550 Linen Belts are at one price, so they are one line
  with nothing to open; Linen Bag has many prices and opens.
- 3, buying 17 from one line: not done. Tyler, 2026-11-16: "Just save the test for a later date :)
  and we will monitor feedback." Released without it; a cheaper way to run it (a hidden command
  that keeps 3 auctions per line, so 3 purchases reach the re-read) is in `docs/status.md`.
- 4, Live: passes. "1 price level, 550 for sale, live: updated just now", no "too many for Live".
  It said 438 sellers where the Full search said 548 for the same 550: the seller count is an
  upper bound when the game gives a count instead of names (since 0.8, not new; status file).
- 5, Tab: "it filled in the vanished part when I pressed tab"; the bar read "linen bag/exact" with
  the cursor at the end. Tab accepts as built (FB-040).
- 6, Full scan: "smooth". `SLICE_MS` stays 8.
- 7, one click buys: passes. "Bought 1 × Linen Cloth for 18c" with the button showing "Buy 1 for
  19c", and chat "You won an auction for Linen Cloth (x1)". First time seen: Forever accepts the
  confirm sent from the price event, and the server's price can be lower than the button's.
- 8, copper on gear: passes. Rough Bronze Leggings posted at 5s 69c ("Posted 1 × Rough Bronze
  Leggings"), listed at 5s 69c in the Auctions tab; other players' gear listings show copper too.
- 9, undercut on gear: passes. "1 copper below the lowest listing (5s 50c)", 5s 49c posted, the
  Auctions tab says "Lowest".
- 10, stat of an ending: the healing line shows in Fast and in Full (Mercurial Greaves of Healing,
  Simple Blouse of Healing). Whether it was missing before for these items is not known; "of
  shadow protection" was not tried.
- 11, crate lines: "Cheapest way to fill it" and the bundles, no "Latest prices" line. The switch:
  Tyler, afterwards: "yes that toggle switch works for the text". The heading was then renamed
  "Cheapest fill price" for the release (Tyler: "I dont want to test that").

## 0.8.2.1 build 6

Not tested on its own: its steps are build 7's steps 1 to 6.

## 0.8.2.1 build 5

Not tested on its own: its fix and its two questions are part of build 6. Its steps were a Full
search for `linen` without the "Table full!" popup, and the two questions now in build 6 steps 5
and 6.

## 0.8.2.1 build 4

Tested by Tyler on 2026-11-11 (test page build id `0-8-2-1-build-4`). He marked one step Pass and
skipped three; the rest are read from his screenshots.

- Step 1, Full scan: "Full scan complete: 220508 auctions recorded in 48.5s (the auction house
  took 30.3s to answer, 2.0s to send the list; reading took 16.2s)". About the same total as
  0.8.2 (215090 in 50.5s): most of it is the wait for the auction house. No word on how the game
  felt; asked in build 5.
- Step 2, Sniper: passes. Round 1 read 17627 items in 66.6s, round 2 in 54.9s; "88 to buy, 1 gone",
  rows green, not gray.
- Step 3, Full search `linen`: the search ran and ended ("20 items, 41,962 for sale, searched just
  now", gold bar, no "some items missing"), but a popup came up each time: "Table full! Further
  results from this search will still be processed but no longer displayed in the table." Tyler:
  "I had to close this error". The debug log of step 4 says 36 items were read; the table shows
  20. Old behavior (the table keeps 2,000 auctions), not from this build; fixed in part in build
  5, the rest proposed (review file, S-08).
- Step 4, `/aux debug`: "Search timing: 24.0s for 36 items, 0.67s each", "Waiting: item list 0.2s,
  server answers 6.0s, throttle 17.8s, item data 0.0s, other 0.0s", "Answers: 37 on time, 0 after
  the 1s fallback, 0 timed out (20s each), 0 dropped and resent", "The game announced 37 of 37
  answers itself, 0 of the 0 taken after the 1s fallback". The second search: 23.8s, the same
  counts. So R-05 has nothing to gain and is closed.
- Step 5, post one trade good: "Posted 1 × Linen Cloth" in green. Passes.
- Step 6, `inf` in the price box: Post faded, "Type a price to post." Passes. The receipt on the
  right still read "Starting bids, 1 item 51c" for a trade good (review file, S-09, not fixed).
- Step 7, Bids buttons: skipped.
- Step 8, typing in the search bar: Pass. Note: "Why dont we have tab completes working here? Is
  this something you can log as feedback and provide opus the correct way to do it?" Logged as
  FB-040.
- Step 9, `/aux memory`: "auxForever uses 61.0 MB of memory; price history for 28069 items (prices
  not seen for 90 days are forgotten); item list 16004 items. After a cleanup: 46.5 MB; the rest
  was garbage the game frees over time". The line is as expected. Tyler: "Not sure what was
  supposed to happen here": the step did not say that the line itself was the whole check.
- Step 10, gamepad in a fight: skipped. Step 11, leaving the Post tab: skipped. Both stay covered
  only by the automated tests.

The steps as they were:

- [ ] 1. Click Full scan at the top right of aux and wait without searching. At the end the chat
      says "Full scan complete: ... auctions recorded in ... (the auction house took ... to answer,
      ... to send the list; reading took ...)". Screenshot that line. Last time it read 215090
      auctions in 50.5s. Also say in the note whether the game felt smooth while it read.
- [ ] 2. Open the Sniper tab and click Start. Wait until the status next to the button says
      "round 2". Deals show in the table as before, and they are not all gray ("Gone").
- [ ] 3. Stop the Sniper. Search tab, click Full (next to Fast), search `linen`. Rows appear while
      it runs. When it ends, the status bar turns gold and the line next to the sub tabs ends with
      "searched just now", with no red "some items missing".
- [ ] 4. Type `/aux debug` in chat (it says "search timing log on"). Search `linen` again, wait
      for it to end, then search `linen` once more. After each search the chat prints a few
      lines; screenshot the ones that start with "Answers:" and "The game announced". Type
      `/aux debug` again to turn the log off.
- [ ] 5. Post tab: click a trade good in the bag list (cloth, ore, herbs), wait for the price,
      set the quantity to 1 and click Post. Under Duration it says "Posted 1 × " and the item's
      name, in green.
- [ ] 6. Post tab, an item selected: click the price box, type `inf` and press Enter. The Post
      button fades and the line next to it says "Type a price to post." Then type the price you
      want back, or click another item.
- [ ] 7. Open the Bids tab and click no row. The Bid and Buyout buttons at the bottom are faded and
      clicking them does nothing (no BugSack error). If you have a bid there: click its row (the
      buttons light up), then click the same row again to let go (they fade again).
- [ ] 8. Search tab: click the search bar and slowly type `line`. After the first letters the bar
      fills in an item name for you, for example "linen cloth/exact", as it did before, and typing
      does not stutter.
- [ ] 9. Type `/aux memory` in chat. The line ends with "price history for ... items (prices not
      seen for 90 days are forgotten)". Then hover an item you scanned in the last days, anywhere:
      its tooltip still has its Value line.
- [ ] 10. Only if you play with a gamepad; otherwise Skip. Turn on the taint log
      (`/console taintLog 1`), open aux in gamepad mode, and get into a fight (a duel next to the
      auctioneer will do). During the fight the pad buttons do what they do without aux; after it
      the gold frame is back in aux and the buttons work in aux again. No "blocked" message.
- [ ] 11. Post tab: click a piece of gear in the bag list (a weapon or armor you can sell), and
      right away click the Search tab at the top. Wait five seconds, then click the Post tab again.
      No BugSack error at any point, and the Post tab opens with its bag list as usual.

## 0.8.2 build 8

One fix from Tyler's build 7 test (results below): with a material selected, the deal sound played
but new rows showed only after letting go. The table waited whenever the mouse was over its rows,
and the mouse rests on the row just clicked. The selected row and the rows above it no longer move,
so the table now updates while the mouse is on them; a row below still waits. Zip
`auxForever-0.8.2-build8.zip`; `/reload` is enough. Test page build id `0-8-2-build-8`.

- [ ] 1. Open the Sniper tab and click Start. Click a material deal (cloth, ore, herbs, leather)
      and leave the mouse where it is, on that row. When the deal sound plays, the new row shows up
      just below yours within a second, and your row does not move. If no sound plays within a few
      minutes, mark Skip.

Tested by Tyler 2026-11-09 (test page `0-8-2-build-8`): passes. Coarse Stone selected in row 1,
Deathweed "just now" right below it, the status "Watching first round; checking 987 possible deals".
General note: a player Tyler knows reported his Full scan "wasnt working" (FB-039).

### 0.8.2 build 7

Tested by Tyler 2026-11-09 (test page `0-8-2-build-7`): all eight steps pass. Full scan with the
Sniper running: the button is not gray, the bar showed "waiting for the auction house, 0:13 so far",
the Sniper waited ("first round") and went on by itself after the scan; the chat line (partly
hidden behind aux) reads "215090 auctions recorded in 50.5s (the ... answer, 2.0s to send the list;
reading took ...)" (FB-027). The tooltip-word search: "That was LIGHTNING fast", 36 chests. The sort
arrow sits left of "% of usual". The Materials hover shows "(73%)" and "(56%)" in color. No Shift
hint; with Shift "4s 80c (104%) for 20". Sniper: with Crippling Poison selected the status kept
"Watching round 5, ... checking 542 possible deals"; a selected gear deal (Light Bow) shows
"Holding while this item is selected, so Buy works; click it again to go on". Tyler on step 7:
"when my row is frozen I can hear sounds like new entries should be popping up but they dont show
up until I unselect the material I was holding" (fixed in build 8). Tyler kept gear holding the
rounds (option C): "keep it, or if you can think of a more elegant solution do it".

Build 6 (not tested yet) plus the Sniper no longer stopping while a deal is selected (Tyler,
2026-11-09: "very jarring"; Gemini's review H-009, answered in H-010): trade goods and gone deals
keep the rounds going, gear still pauses them, and the selected row stays in place while new deals
come in below it. Zip `auxForever-0.8.2-build7.zip`; `/reload` is enough. Test page build id
`0-8-2-build-7`. Steps 1 to 5 are build 6's.

- [ ] 1. Open the Sniper tab and click Start. The Full scan button at the top right is not gray
      (unless your last Full scan was less than 15 minutes ago: point the mouse at it to see when).
      Click it and wait without searching. At the end the chat says "Full scan complete: ...
      auctions recorded in ... (the auction house took ... to answer, ...)". Screenshot that line.
- [ ] 2. Stop the Sniper. Search tab, Fast selected, search `usable/armor/cloth/chest/intellect`.
      Rows appear while it runs, it ends in seconds, and the chests found say Intellect in their
      tooltip (an "of the Owl" one too).
- [ ] 3. In that table, click the "% of usual" column title (it was "% Hist. Value"). The gold arrow
      sits left of the title, not on top of the "%".
- [ ] 4. Open your Professions window, pick a recipe, and point the mouse at the line under its
      reagents ("Materials ..."). Each material bought at the auction house and the "sells for" line
      end with a percent in brackets, like "(67%)", in color.
- [ ] 5. Point the mouse at a stack in your bags: the Value line has no "Shift for" any more. Hold
      Shift: it shows the whole stack's price, "for 20".
- [ ] 6. Open the Sniper tab and click Start. When a material deal shows up (cloth, ore, herbs,
      leather), click it once. Next to Stop, the status keeps saying "Watching  round 12, ..." and
      the round number goes up; it does not say "Holding". If no material deal shows up within a few
      minutes, mark Skip.
- [ ] 7. Leave that row selected and wait for another deal to show up (the sound plays). The new row
      appears just below yours, and your row stays where it was. If none shows up within a few
      minutes, mark Skip.
- [ ] 8. Click a gear deal (armor or a weapon). The status says "Holding  while this item is
      selected, so Buy works; click it again to go on". Click the same row again: the status goes
      back to "Watching".

### 0.8.2 build 6

Fixes from Tyler's build 5 test (results below) and "% of usual" everywhere (Tyler, 2026-11-09,
"especially in crafting menus"). Zip `auxForever-0.8.2-build6.zip`; `/reload` is enough. Test page
build id `0-8-2-build-6`. Not tested on its own; its five steps passed as build 7's steps 1 to 5.

### 0.8.2 build 5

Tested by Tyler 2026-11-09 (test page `0-8-2-build-5`): the Full scan button stayed gray while the
Sniper ran ("I had to stop sniper for full scan to ungrey", fixed in build 6; the scan's closing
chat line was not in the screenshots). The tooltip-word search failed ("This isnt returning items
and there is a weird visual bug on % Hist Value": gear with an ending was read one by one and the
table was redrawn only every 100 items; the sort arrow sat on the "%"; both fixed in build 6). The
tooltip reads "Value: 1s 8c (83%)  seen today" and with Shift "4s 80c (104%) for 20"; the % of usual
switch turns the percent off (screenshots). Tyler: "I dont want to put shift instructions in the
tooltip" (removed in build 6). The Sniper after a round: 21 deals, some "% of market", percents in the
Search colors, "Compared to" filled (screenshot). Tyler on the Sniper stopping while a deal is
selected: "I find it very jarring that we stop the entire search when someone highlights
something" (handoff H-009 for Gemini).

Build 4 plus one consistency change (Tyler, 2026-11-09: wherever a price is compared with the usual
price, the same percent in the Search tab's colors): the Sniper's Why column shows "30% of usual" or
"70% of market" with the percent in the % Hist. Value colors (it was always green). The "usually"
line was the only other place with its own wording; it went in build 4. Zip
`auxForever-0.8.2-build5.zip`; `/reload` is enough. Test page build id `0-8-2-build-5`. Build 4's
steps; step 5 (Sniper screenshot) also shows the Why column's colors.

### 0.8.2 build 4

Build 3 plus one tooltip change (Tyler, 2026-11-09, after deep_structure asked again about
"usually"): the usual price is a percent on the Value line, "Value: 2s (67%)  seen today", instead
of a "usually 3s" line under it; the Settings switch is "% of usual". Zip
`auxForever-0.8.2-build4.zip`; `/reload` is enough. Test page build id `0-8-2-build-4`. Build 3's
six steps (below), with two changes:
- Step 3 (Shift on a stack): the Value line reads like "Value: 2s (67%)  seen today  Shift for 20".
- Step 4 (Settings): the new row under Value is called "% of usual". Click it off, point the mouse
  at an item: the percent is gone. Click it on again.

### 0.8.2 build 3

Build 2 plus Gemini's review of the Sniper logic (H-008, eight findings, all fixed with a test each,
`docs/reviews/2026-11-09-sniper-0.8.2.md`): the Sniper's check before opening an item uses the last
Full scan's market by the Sniper's own rule (the cheapest price left out), other gear versions are
read when one is opened, a price 3 sellers ask is the market, the column next to the price is
"Compared to". Zip `auxForever-0.8.2-build3.zip`; `/reload` is enough. Test page build id
`0-8-2-build-3`. The same six steps as build 2 (below); step 5 also checks the new column.

### 0.8.2 build 2 (not tested; replaced by build 3)

Fixes and small changes from player feedback (FB-025, FB-027, FB-028, FB-033, FB-035, FB-036,
FB-037). Build 1 was never tested (the game was down); build 2 adds Swiftwren's second comment: the
Sniper's list check uses today's Full scan and other versions of the same gear name, so far fewer
items are opened per round (FB-036). Zip `auxForever-0.8.2-build2.zip`; `/reload` is enough. Test
page build id `0-8-2-build-2`. The steps are the same as build 1's.

- [ ] 1. Full scan with the Sniper running. Open the Sniper tab and click Start. Then click Full
      scan at the top right (if it is grayed out, point the mouse at it: it says when it is
      available), and wait without searching. The bar under the window says "Full scan:
      waiting for the auction house, 0:05 so far..." if the answer takes more than 5 seconds. At
      the end the chat says "Full scan complete: ... auctions recorded in ... (the auction house
      took ... to answer, ... to send the list; reading took ...)". Screenshot that chat line.
      (Before, the Sniper's next round stopped the Full scan after a few seconds.)
- [ ] 2. Stop the Sniper. On the Search tab, with Fast selected (top right of the search bar),
      search `armor/mail/chest/usable/strength`. The results come in seconds, not minutes, and the
      chests in them say Strength in their tooltip.
- [ ] 3. Hover a stack in your bags, for example 20 Linen Cloth. The Value line ends with "Shift
      for 20". Hold Shift: the line shows the whole stack's price and ends with "for 20".
- [ ] 4. Click the gear at the top right (Settings). Under Tooltip lines there is a new row,
      Usually, under Value, and nothing is cut off at the bottom of the window.
- [ ] 5. Right after the Full scan of step 1, Sniper tab, Start, and let it run about 2 minutes.
      Screenshot the Sniper with its deals table and the line above it ("checking ... possible
      deals" while a round runs). Expect far fewer possible deals than before and none like
      Swiftwren's (an item listed by many at about the same price). The column after "Price each"
      is called "Compared to" (build 3).
- [ ] 6. Only if the Sniper finds a deal while you watch: when it appears (with the sound), click it
      within 15 seconds. The Buy button appears at once, without a "Checking..." message first. Do
      not buy. (A deal found longer ago is checked again first, as before.)

### 0.8.1 build 2

One fix from Tyler's build 1 test. Tyler keeps his Professions window where he dragged it; with
aux open, build 1 pulled it to the far left, behind aux's window (the fix for FB-034 moved any
window in the right-hand place). Now aux only undoes the game's own small shift and leaves a window
the player placed alone. Zip `auxForever-0.8.1-build2.zip`; `/reload` is enough. Test page build id
`0-8-1-build-2`.

- [ ] 1. Stand next to an auctioneer. Open your Professions window (it appears at the spot you
      moved it to). Right-click the auctioneer, so aux opens. The Professions window does not move
      (in build 1 it jumped to the far left, behind aux).
- [ ] 2. Keep aux open. Close the Professions window with its X, then open it again. It ends up at
      your spot (flashing at the left first and then jumping there is fine; it did that in build 1
      too).
- [ ] 3. In the Professions window, click a recipe whose item you have never searched for in aux
      (for example one you just learned). The small line under its reagents reads like
      "Materials 2s 40c   no sell price yet".

Tested by Tyler 2026-11-08 (build 2, test page `0-8-1-build-2`): steps 1 and 2 pass (the
Professions window, at his own spot, stays there when aux opens and after reopening). Step 3 could
not be done: "I dont think I have a single item that aux didnt already fullscan." The step needed
something the tester does not have (the rule under "For agents"); the "no sell price yet" case is
covered by the automated test `fb026: a made item with no price says so`. Every 0.8.1 change has
now passed in game.

Tested by Tyler 2026-11-08 (build 1, test page `0-8-1-build-1`): steps 1 and 2 pass from the
screenshots (`hillman's cloak/exact` lists Hillman's Cloak, 415 for sale; Robes of Arcana found
the same way); step 3 fails: his Professions window, at a spot he set himself, went to the far left
behind aux when the auction house opened, and on reopening it "starts on the left then teleports
to its custom position set by me" (fixed in build 2); step 4 passes; step 5 works from the
screenshot (Woolen Bag: "Materials 12s 97c  Loss 8s 22c"); step 6 passes from the same screenshot
(the hover shows "Woolen Bag sells for 5s seen today, After the 5% auction house cut 4s 75c, Loss
8s 22c"); Tyler's note "What?" meant the step's wording was unclear ("It was very unclear what you
were asking"), not the result, so the step-writing rule in `AGENTS.md` ("Tests") was added; step 7
skipped.

### 0.8.1 build 1

0.8.0.1 build 1 (below, the cloak search and the Professions window, unchanged) plus profit or
loss on the profession window's Materials line (FB-026, deep_structure; option A of the mockup,
https://claude.ai/artifact/6VxaaXKXe3f9uJEjK7Gtoy). Zip `auxForever-0.8.1-build1.zip`; `/reload`
is enough. Test page build id `0-8-1-build-1`: seven steps, 0.8.0.1 build 1's four steps (below)
first, then these three (Tyler had not started the 0.8.0.1 page).

- [ ] 1. Open your Professions window and pick a recipe whose made item aux has seen (searched or
      full scanned), for example Woolen Bag. The line under the reagents reads "Materials ...
      Profit ..." in green, or "Loss ..." in red. Screenshot it.
- [ ] 2. Hover that line. Under the total: "<item> sells for" with how old the price is, "After
      the 5% auction house cut", and Profit or Loss with the same amount as the line.
- [ ] 3. Pick a recipe whose made item aux has never seen: the line says "no sell price yet". If
      you have a recipe that makes no item (an enchant), it shows the cost only.

### 0.8.0.1 build 1

Two bug fixes from player feedback. An exact search for a cloak found nothing (FB-024, GregoryWW:
`hillman's cloak/exact`): aux asked for Cloth armor, and Forever keeps cloaks under Miscellaneous,
Cloak (Blizzard's code). With aux open, the Professions window moved a little to the right
(FB-034, Chawitsch): the game places side windows next to its own auction house window, which aux
keeps open but shrunk and invisible; aux now puts the side window back. Zip
`auxForever-0.8.0.1-build1.zip`; `/reload` is enough. Test page build id `0-8-0-1-build-1`.

- [ ] 1. Search for a cloak that is for sale with `/exact` after its name (for example
      `hillman's cloak/exact`; search `cloak` first to find one). It lists that cloak.
- [ ] 2. The same with a necklace, ring or robe that is for sale: it is found too.
- [ ] 3. Away from the auction house, open your Professions window and note where it sits. Open
      the auction house (aux opens): the Professions window stays where it was. Close it and open
      it again while aux is open: same place. Before, it moved a little to the right.
- [ ] 4. Click Blizzard UI, then go back to aux, then close the auction house. No errors, and the
      Professions window (if open) is still usable where it is.

### 0.8 build 14

Two fixes from Tyler's build 13 test. Crates hovered in aux's results showed no "Cheapest way to
fill it" lines (Journeyman Herbs, Artisan Curiosities). Likely cause (not confirmed in game): the
game loads a crate's list, the text of its use spell, after the item, and aux read the tooltip
before that and kept "not a crate" for the session; it now waits for the list (Blizzard's code:
`C_Item.GetItemSpell`, `C_Spell.IsSpellDataCached`). Sorting by For sale put "Merc Sword of Stamina
18 (1)" below a 17: an item's row sorted by its first price only; now by all it has for sale. Zip
`auxForever-0.8-build14.zip`; `/reload` is enough. Test page build id `0-8-build-14`.

- [ ] 1. After `/reload`, open aux and search `waylaid crate`. Hover three kinds of crate in the
      results: each shows "Cheapest way to fill it" with its bundles (the first hover may not; a
      second hover must). Screenshot one.
- [ ] 2. Hover the Waylaid Crate in your bags: the same lines show.
- [ ] 3. Search `merc sword` (Full), click For sale until the arrow points down: the numbers in
      that column only go down from the top (an item with yours, like "18 (1)", sits by its 18).

Tested by Tyler 2026-11-08 (test page `0-8-build-14`, screenshots, no marks; judged from the
screenshots): all three pass. In aux's results Apprentice Ore (20 Copper Ore 25s 80c, cheapest;
20 Tin Ore 32s 20c), Earthly Expert Herbs (four bundles, 10 Khadgar's Whisker 35s cheapest) and
Artisan Textiles (20 Thick Leather 96s 60c cheapest) show "Cheapest way to fill it"; the
Apprentice Ore crate in the bags shows the same; For sale sorted down puts "Merc Sword of Stamina
20 (1)" among the 20s.

### 0.8 build 13

The release candidate for 0.8, after Gemini's last review (H-006,
`docs/reviews/2026-11-08-release-0.8.md`): seven fixes, each with a test. Gear read on the Post tab
and stopped halfway (by a Full scan) no longer unlocks Post with a price from part of the listings;
a search stopped halfway through an item's versions keeps the day's price; sorting merged rows by
For sale and Seller; a crate's bundles are read only from a crate's own list; old shared gear
prices are removed; two gamepad popup fixes; and the help no longer states as fact that the newest
listing at a price sells first (not confirmed on Forever). Zip `auxForever-0.8-build13.zip`;
`/reload` is enough. Test page build id `0-8-build-13`.

- [ ] 1. Hover two kinds of Waylaid Crate other than Textiles and Fabrics (Herbs, Ore, Parts...):
      each still shows "Cheapest way to fill it" with its bundles. Screenshot one.
- [ ] 2. Search `merc sword` (Full). Click the For sale header (twice if needed): the rows with the
      most for sale come first. Click the Seller header: the "N sellers" rows sit together, not
      among the single names.
- [ ] 3. Hover a gear item with an ending in your bags (a Merc Sword or Medicine Staff "of ..."):
      Value shows as before.
- [ ] 4. Post tab: hover the "?" next to the goblin. It says the newest listing selling first is
      "Not yet confirmed on Forever". Type `/aux undercut`: the same.
- [ ] 5. Only if your Full scan is ready: Post tab, pick a gear item with an ending and click Full
      scan right away, while it says "Reading the listings...". Post stays faded and says
      "Reading stopped. Press Refresh, or type a price." Click Refresh: it reads again.

Tested by Tyler 2026-11-08 (test page `0-8-build-13`, screenshots, no marks; judged from the
screenshots): steps 2 (the Seller sort), 3 and 4 pass; step 2's For sale sort put "18 (1)" below a
17 (fixed in build 14); step 1 fails: Journeyman Herbs and Artisan Curiosities, hovered in aux's
results, showed their list but no "Cheapest way to fill it" (build 14); step 5 skipped ("I cant
move my hand that fast"; covered by the test "H-006 2").

### 0.8 build 12

The release candidate for 0.8. On top of build 11 (the empty search bar): after Cancel on a trade
good's price, the Buy button kept the Confirm green (Tyler's screenshot, Wool Cloth). It is
repainted whenever its look changes now. Zip `auxForever-0.8-build12.zip`; `/reload` is enough.
Test page build id `0-8-build-12`.

- [ ] 1. Search a cheap trade good (`wool cloth`), click a row, Buy: the button turns to Confirm in
      green. Click Cancel: the button says Buy again in its normal color, not green.
- [ ] 2. Search tab: clear the search bar (right-click it), click somewhere else: it stays empty.

Tested by Tyler 2026-11-08 (test page `0-8-build-12`): step 1 passes; step 2 passes from the
screenshot (an empty bar, the Wool Cloth buy bar's button back to its normal look).

### 0.8 build 11

The release candidate for 0.8. One fix on top of build 10: clearing the search bar and clicking
elsewhere showed "<>" (Tyler: "This appears when you clear the search bar and click somewhere
else"); aux writes an empty search that way, and the bar now stays empty. Zip
`auxForever-0.8-build11.zip`; `/reload` is enough. Test page build id `0-8-build-11`.

- [ ] 1. Search tab: clear the search bar (right-click it), then click somewhere else. The bar
      stays empty.

### 0.8 build 10

Gemini's review of one row per price (H-004, `docs/reviews/2026-11-08-one-row-per-price.md`):
all seven findings and the build 8 note taken, each with a test. The Bids and Sniper tabs list
each auction apart again; an auction with no buyout keeps its own row; the row keeps the auction
with the lowest starting bid; the buy bar and the result count match the merged rows; each seller
is counted once ("65 sellers" in build 9). Zip `auxForever-0.8-build10.zip`; `/reload` is enough.
Test page build id `0-8-build-10`.

- [ ] 1. Search `merc sword` (Full): the seller counts look believable (not 65 sellers for 69
      swords unless that many people really sell it), and the summary above the table counts the
      rows shown. Screenshot.
- [ ] 2. Click a merged row: the bar below says as many "for sale at this price" as the row shows.
- [ ] 3. Sniper: start it for a minute; each deal is its own row.

Tested by Tyler 2026-11-08 (test page `0-8-build-10`, screenshots, no marks; judged from the
screenshots): all three pass. `merc sword` (Full): "23 items, 383 for sale", one row per ending, a
seller count per row; the 9s Merc Sword of Intellect row's buy bar said "1 for sale at this price,
The last one at this price"; the Sniper showed 13 deals and 1 gone, one row each.

### 0.8 build 9

Tested by Tyler 2026-11-08 (test page `0-8-build-9`, screenshots): one row per price works in
search results ("Merc Sword of Healing 69, 65 sellers"; the seller count was wrong, review H-004
finding 6), buying from a merged row passes, the Post tab shows 66 at 11s on one row, the Auctions
tab still shows each auction ("Tied with 66 others").


One row per price (Tyler, build 7: "Why are we separating these lines?"; build 8: "go full auto").
Search results, the Sniper and the Post tab merge gear auctions at one buyout price into one row,
whatever the seller and time left; the seller column says "4 sellers". Zip
`auxForever-0.8-build9.zip`; `/reload` is enough. Test page build id `0-8-build-9`.

- [ ] 1. Search `merc sword of healing` (Full): one row per price; the 11s row adds up all the
      sellers at 11s and says how many sellers. Screenshot.
- [ ] 2. Buy one from the cheapest row (Buy, then Confirm): it costs the price shown, and the row's
      count goes down by one (or the next seller's auctions take its place).
- [ ] 3. Post tab, the same sword: one row per price there too (yours on a row of their own).
- [ ] 4. Auctions tab, if you have auctions up: each of your auctions is still its own row.

### 0.8 build 8

Tested by Tyler 2026-11-08 (test page `0-8-build-8`): step 1 passes (gear loads in a few seconds),
step 2 skipped.


From Tyler's test of build 7: the Post tab took a long time to load a Merc Sword. It searched every
ending of the item (about 25 searches); it now searches only the versions of its own ending and
takes the other endings' lowest prices from the item list. Zip `auxForever-0.8-build8.zip`;
`/reload` is enough. Test page build id `0-8-build-8`.

- [ ] 1. Post tab, a Merc Sword: the bar at the bottom turns gold in a few seconds (it took much
      longer in build 7), and the list matches a Search tab search of that full name.
- [ ] 2. Gear whose ending nobody sells: a price is still suggested ("None of this name for sale:
      the cheapest other ending").

### 0.8 build 7

Tested by Tyler 2026-11-08 on the released game (test page `0-8-build-7`, screenshots): step 1
passes (aux loads, BugSack "You have no bugs, yay!", a Full scan recorded 161,999 auctions; the
`GetBuildInfo()` line was not captured), step 2 passes (Value kept after a login). Step 3: the Post
tab's Merc Sword of Healing list matched the search (11s: 2, 5, 39 and 10 for sale; 12s, 18s,
30s), but loading took long (fixed in build 8). Tyler asked why one price shows as several rows
(four rows at 11s): open design question, `docs/status.md`. Steps 4 and 5 not done (the game
changed since the beta, so Tyler's items differ). The search bar showed `<>` once, cause unknown.


The first build on the released game. Fixes from Gemini's review of gear versions (H-002, all six
findings, `docs/reviews/2026-10-26-gear-versions.md`) on top of build 6, which was never tested.
Zip `auxForever-0.8-build7.zip`. Put the `auxForever` folder in the release game's
`Interface\AddOns` folder (not `_classic_beta_` any more, most likely; wherever your other addons
are) and **restart the game fully**. Test page build id `0-8-build-7`.

- [ ] 1. Release check: at the character screen, AddOns: is auxForever listed and ticked, or does
      it say "Out of date"? Then in game type `/run print(GetBuildInfo())` and screenshot the
      chat line (it gives the game version and the number the addon must declare).
- [ ] 2. Release check: hover an item you have searched before and note its Value. Log out, log
      back in, hover it again: is the Value still there? (Saved prices survive a login.)
- [ ] 3. Search `merc sword` (Full), then Post tab, Merc Sword of Healing: the Post tab lists the
      same Healing swords as the search (same counts and prices). Screenshot of both.
- [ ] 4. Medicine Staff of the Whale (or any gear nobody sells): a price is filled in and the line
      under it says "None of this name for sale: the cheapest other ending".
- [ ] 5. Still on the Post tab with a Merc Sword picked: right-click a price row. The Search tab
      shows only that ending (before: nothing at all).

### 0.8 build 6

Not tested in game (development paused 2026-10-26 until the game's release).


Fixes from Tyler's test of build 5 ("the numbers dont add up"; "we need to give them a price to
post at anyway"). The Post tab now reads every version of gear before it picks a price: one name
can sit under several versions, and stopping at the first one with a listing missed the rest. And
when nobody sells that name, it suggests the cheapest other ending of the item, with the note "None
of this name for sale: the cheapest other ending" (a suggestion; any price can be typed). Zip
`auxForever-0.8-build6.zip`; `/reload` is enough. Test page build id `0-8-build-6`. Reading
gear now takes a few seconds longer (one request per version of the item).

- [ ] 1. Search `merc sword` (Full) and note how many of each ending are for sale and at what
      price. Then Post tab, Merc Sword of Healing: once the bar turns gold, the table shows the
      same Healing listings (same counts and prices) and "Same as the lowest listing". Screenshot of
      both.
- [ ] 2. Merc Sword of Agility: the same check (if none are listed now, see step 3).
- [ ] 3. Medicine Staff of the Whale (nobody sells it): a price is filled in, the cheapest other
      Medicine Staff, and the line under it says "None of this name for sale: the cheapest other
      ending". Screenshot.

### 0.8 build 5

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

Tested by Tyler 2026-10-21 (test page `0-8-build-5`, screenshots): Agility and Healing showed
listings of their own name and "Same as the lowest listing", but the counts did not match a search
a minute later (Healing 1 + 3 in the Post tab, 6 in the search): the Post tab stopped after the
first version with a listing (fixed in build 6; listings also changed in that minute, Agility was
gone from the later search). The Whale said "None for sale"; Tyler: "we need to give them a price
to post at anyway" (build 6 suggests the cheapest other ending).

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

Tested by Tyler 2026-10-21 (test page `0-8-build-4`, screenshots): step 1 passes (Medicine Staff
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
- [ ] 2. Search `linen cloth` and buy 1 with the buy bar (one click on Buy since 0.8.2.1): it is bought.
- [ ] 3. Post tab: post one item at the price aux picks: it says "Posted".
- [ ] 4. Auctions tab: that item is listed with a status.
- [ ] 5. Sniper tab: Start, wait for one round, Stop.
- [ ] 6. Open a profession window: the Materials line shows under a recipe's reagents.

Agents: keep this list at six steps or fewer. Add a step only for something that broke in a
release before, and say which.

## For agents

Add the in-game checks for each change to "Current build" above. One thing per step. If a step needs something the tester may not have (auctions
up, a second character, a rare item), say how to set it up or leave the step out (0.6.1 build 2,
step 6: two checks in one, the second needing auctions; Tyler found it confusing). The
pre-release check stays at six steps (Tyler's limit); do not move build steps into it. Older
detailed checklists: `docs/testing-history.md`.
