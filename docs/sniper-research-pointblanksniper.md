# Sniper Research: Point Blank Sniper (`TheMouseNest/PointBlankSniper`)

Researched 2026-11-23 (Tyler's time) from [TheMouseNest/PointBlankSniper](https://github.com/TheMouseNest/PointBlankSniper)
(last pushed 2026-10-14; retail WoW companion addon built on Auctionator and `C_AuctionHouse`).
Every technique below from Point Blank Sniper is labeled **`[Outside]`** unless checked against
Blizzard's Forever API (`[Code]`) or observed in game on Forever (`[Seen]`).

## Summary: top ideas worth adopting for auxForever

1. **Price-Cap Early-Stop Mode (whole-AH sniping in ~1 to 5s instead of ~38s):** High impact, low
   complexity, zero new APIs. Needs **E11a** to confirm Forever's browse results arrive sorted by
   ascending `minPrice`.
2. **Streaming Page-by-Page Browse Processing:** High impact on whole-AH and multi-page category
   rounds (surface Page 1 cheap items in ~0.5s instead of waiting ~38s for all 52 pages). Needs
   **E11b** to confirm whether `SendSearchQuery` mid-browse disrupts `RequestMoreBrowseResults()`.
3. **`SearchForItemKeys` Batch Sniping (up to 100 items per request):** High impact for multi-item
   Search Favorites / Watch Lists in Narrower Sniper (collapses 20+ separate queries into 1 single
   request). Blocked on settling **E10** (`IsThrottledMessageSystemReady() == true` probe).
4. **Optional "Stop and select first deal" mode:** Pairs with auxForever's 0.9 Buy keybind
   (`FB-063`) for 1-keypress sniping without moving the mouse. Must be opt-in (off by default).
5. **Sort gear `SendSearchQuery` by `Buyout` (4) instead of `Price` (0):** Puts cheapest buyouts on
   Page 1 ahead of low-bid spam. `Enum.AuctionHouseSortOrder.Buyout == 4` exists on Forever
   (`[Code]`, `tests/forever_api.lua:1069`).
6. **`New` highlight for fresh deals + separate Flash/Sound toggles:** Quick, low-risk UX polish.

---

## Detailed Findings

### 1. Price-Cap Early-Stop Mode ("Threshold" / Penny-Snipe Mode) `[Outside]`

- **How Point Blank Sniper does it (`Source/Scan/NameCache.lua:20-35, 102, 175-185`,
  `Source/Tab/Main.lua:192-197`):**
  - Sends a blank whole-AH `SendBrowseQuery` sorted by `Enum.AuctionHouseSortOrder.Price` ascending
    (followed by `Name` ascending).
  - After each 500-item page arrives, checks the tail entry's `minPrice` against a cap
    (`value > 100` copper in PBS, i.e., 1 silver).
  - As soon as the page passes the price cap, PBS stops calling `RequestMoreBrowseResults()` and
    immediately ends the round and starts the next one.
- **Why it fits auxForever:**
  - Whole-AH browse on Forever takes ~37.7s across 52 pages (`[Seen]`, 2026-11-17).
  - `auxForever/core/scan.lua:112-115` already sends the exact same `SORTS` (`Price` ascending,
    `Name` ascending).
  - Most fat-finger typos (for example a 50g item posted for 50c or 50s) and below-vendor flips sit
    in the cheapest few pages. A configurable **Max price** cap on the Sniper (such as `All prices`,
    `Under 1s`, `Under 10s`, `Under 1g`, `Under 5g`, or typed cap) would scan the cheap end of the
    entire auction house in ~2 to 8 requests (1 to 5 seconds) instead of 52 requests.
  - Note: when a price cap stops early, `mark_gone` must only mark deals at or below the cap as
    gone (or skip marking unseen higher-priced deals gone), just like Narrower Sniper's
    `deal_scope` guard.
- **Check before building:** **E11a** in `docs/forever-auction-house.md` (confirm Forever's browse
  pages actually arrive in ascending `minPrice` order).

### 2. Streaming Page-by-Page Browse Processing `[Outside]`

- **How Point Blank Sniper does it (`Source/Scan/NameCache.lua:206-215`, `Source/Tab/Main.lua:228-243`):**
  - Handles `AUCTION_HOUSE_BROWSE_RESULTS_ADDED` page by page as each 500-item batch arrives,
    firing `SnipeSearchNewResults` right away rather than waiting for `HasFullBrowseResults()`.
  - If a deal appears on Page 1, the user sees and hears it within ~0.5 to 1 second while later
    pages are still arriving (or stops the round right there if `CARRY_ON_AFTER_RESULT` is off).
- **How auxForever currently works (`auxForever/core/scan.lua:501-518`):**
  - `browse_results()` loops `while not C_AuctionHouse.HasFullBrowseResults()` until all 52 pages
    arrive, then hands the complete list to `on_item_list` all at once. On an `All` round, a
    Page 1 deal waits ~37 seconds before aux even inspects it.
- **Design caution for Forever:**
  - PBS does not call `SendSearchQuery` during browse (it alerts straight off `minPrice` and only
    opens the item when clicked or after stopping). auxForever pre-verifies deals with
    `scan.read_item` (`SendSearchQuery`) to filter out bid-only auctions, your own listings, and
    flat-market walls (`market_now`).
  - Calling `SendSearchQuery` while `HasFullBrowseResults() == false` might reset the browse cursor
    on Forever (**E11b**, `[Unknown]`).
  - If **E11b** shows `SendSearchQuery` breaks an in-progress browse, streaming still works cleanly
    with a "Stop on first candidate" toggle (stop browse on Page 1 hit, verify buyout immediately,
    resume if false alarm) or by letting `on_browse_page` surface Page 1 hits while deferring
    reads until a small cap or round end. If **E11b** shows `SendSearchQuery` does NOT break
    browse, auxForever can check Page 1 candidates live while continuing the round.

### 3. `C_AuctionHouse.SearchForItemKeys` Batch Sniping (100 Keys / Request) `[Outside]`

- **How Point Blank Sniper does it (`Source/Scan/KeyCache.lua`, `Source/ItemKeyCache/*.lua`,
  `Source/Scan/GetItemKeys.lua`):**
  - Maintains a persistent name-to-`itemKey` cache (`POINT_BLANK_SNIPER_ITEM_CACHE`) populated by
    hooking `GetItemKeyInfo`.
  - Resolves a Shopping List's item names via binary search into exact `itemKey` structs and sends
    `C_AuctionHouse.SearchForItemKeys(itemKeys, {})` in batches of `KEYS_PER_SEARCH = 100` keys per
    single server request.
  - Also offers a `NoGear` mode (`Source/Utilities/Main.lua:69-72`) using `C_Item.GetItemInfoInstant`
    (zero server calls; exists on Forever `[Code]`, `tests/forever_api.lua:88`) to skip `Weapon` and
    `Armor` keys so random-suffix gear does not bloat the key list.
- **Why it fits auxForever:**
  - Narrower Sniper (0.9) lets players watch a multi-item **Search Favorite** (for example
    `linen cloth/exact;copper ore/exact;black lotus/exact;...`), which currently sends 1
    `SendBrowseQuery` per term. A 25-item watch list takes 25 requests (~12 to 18s).
  - If `C_AuctionHouse.SearchForItemKeys` works on Forever, a 25-to-100-item exact watch list
    collapses to **1 single request (~0.5s per round)**!
  - Note: PBS compresses its saved cache using `C_EncodingUtil.SerializeCBOR`, which is not in
    `tests/forever_api.lua` (`[Unknown]` on Forever) and unnecessary for auxForever because aux
    already has `core/cache.lua` and `util/persistence.lua` in plain Lua 5.1.
- **Check before building:** **E10** in `docs/forever-auction-house.md` (`[Unknown]`; must be run
  while `IsThrottledMessageSystemReady() == true`). Do not build anything on `SearchForItemKeys`
  until E10 confirms Forever returns results for it.

### 4. Opt-in "Stop and Select on First Deal" Mode `[Outside]`

- **How Point Blank Sniper does it (`Source/Tab/Main.lua:228-262`,
  `Source/Config/Main.lua:4` `CARRY_ON_AFTER_RESULT`):**
  - When `CARRY_ON_AFTER_RESULT` is unchecked, the first deal found immediately stops the scan and
    opens the Buy panel for that item, ready to click Buy.
- **Why it fits auxForever:**
  - In 0.9 (`FB-063`), auxForever added dedicated Buy / Confirm / Cancel keybinds.
  - Pairing an opt-in **"Pause & select on deal"** switch (off by default, preserving Tyler's 0.8.2
    `H-009` rule against silently pausing on highlight) with `FB-063` keybinds would let a sniper
    hear the alert and press one hotkey to buy without touching the mouse.

### 5. Gear Item Search Sort Order (`Buyout` vs `Price`) `[Outside]` + `[Code]`

- **How Point Blank Sniper does it (`Source/Buy/Main.lua:207-212`):**
  - Commodities: `sortOrder = 0` (`Enum.AuctionHouseSortOrder.Price`, `reverseSort = false`).
  - Gear/Items: `sortOrder = 4` (`Enum.AuctionHouseSortOrder.Buyout`, `reverseSort = false`).
- **How auxForever currently works (`auxForever/core/scan.lua:117-119, 596`):**
  - Sends `SEARCH_SORTS = {{sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false}}`
    for both commodities and gear, and fetches all pages (`while not HasFullItemSearchResults`).
  - `Enum.AuctionHouseSortOrder.Buyout` (`4`) exists on Forever (`[Code]`,
    `tests/forever_api.lua:1069`). Sorting gear item searches by `Buyout` ascending puts real
    cheapest buyouts first ahead of bid-only spam, and makes a future Page-1-only fast verification
    option possible for high-volume items.

### 6. Visual "New" Deal Highlight and Separate Alert Toggles `[Outside]`

- **How Point Blank Sniper does it (`Source/Tab/DataProvider.lua:57-76`, `Source/Tab/Alert.lua`):**
  - Keys each round's results by `itemKey .. " " .. minPrice`, comparing `thisRound` against
    `lastRound` so brand-new deals are highlighted (optional `HIGHLIGHT_NEW_RESULTS` toggle +
    `Is New` column).
  - Separates Sound (`USE_BLEEP`) and Taskbar Flash (`USE_FLASH`) into two checkboxes and ships a
    short custom sound (`Tones/Bleep.mp3`).
- **How auxForever compares:**
  - auxForever already computes `same` (`sniper/core.lua:386`) and stores `deal_found` timestamps,
    and calls both `PlaySound(SOUNDKIT.RAID_WARNING)` (when `sniper_sound` is on) and
    `FlashClientIcon()`. Adding a subtle "New" row tint (or badge) for deals found in the latest
    round and an optional separate Flash toggle is trivial and costs zero extra work. (Custom
    `.mp3` playback on Forever is `[Unknown]`; Blizzard `SOUNDKIT` sounds are `[Seen]`.)

### 7. Minor note: Vendor Blacklist `[Outside]`

- `Source/Constants.lua:12-15` blacklists item IDs `38` (Recruit's Shirt) and `45` (Squire's Shirt)
  because vendor versions caused false snipes on retail. Low priority on Forever (auxForever's
  Sniper already ignores items via right-click Ignore, and low-value starter shirts fail
  `min_profit`).

---

## What NOT to Copy from Point Blank Sniper (auxForever is Already Stronger)

1. **Per-frame `OnUpdate` polling (`Source/Tab/Main.lua:206-210`):** PBS calls `UpdateConfigs()`,
   `UpdateKeysSearchDialog()`, and `UpdateStartButton()` every single frame while the tab is open.
   Violates auxForever's performance rules (`AGENTS.md`). Keep auxForever's event-driven updates.
2. **No live-market wall protection:** PBS compares `minPrice` only against static prices (TSM,
   Oribos Exchange, or fixed max price per term) with no check for a crashing market. auxForever's
   `market_now` / `rest_market` / 3-seller wall (`FB-036`) and Full scan `scan_markets` are much
   safer against false deals.
3. **Alerting before verifying buyouts:** PBS alerts straight from browse `minPrice` and only runs
   `SendSearchQuery` when clicked, resulting in "Bid Only" or "Sold" clicks. auxForever's
   `check_item` pre-verifies real buyouts, skips your own auctions, and caches reads for
   `FRESH_SECONDS = 15` so clicking a fresh deal skips the extra round trip.
4. **Heavy per-batch allocations and external dependencies:** PBS copies the whole results table
   every batch (`CopyTable`), fires `C_Timer.After(0.2)` per batch, and requires Auctionator plus
   TSM/OE. auxForever is standalone, reuses tables (`aux.wipe`), and slices loops with
   `aux.coro_slice`.

---

## Experiments to Run Before Building (0 Gold)

1. **E10 (`SearchForItemKeys`, already in `docs/forever-auction-house.md`):** Re-run while idle
   (`IsThrottledMessageSystemReady() == true`) to see if Forever returns results for batched
   item-key queries.
2. **E11a (Browse Price sort order, added to `docs/forever-auction-house.md`):** Send a blank
   `SendBrowseQuery` sorted by `Price` ascending and print the first, middle, and last `minPrice`
   of Page 1 (and Page 2) to confirm Price-Cap Early-Stop is safe on Forever.
3. **E11b (Mid-browse `SendSearchQuery`, added to `docs/forever-auction-house.md`):** Call
   `SendSearchQuery` for one item while `HasFullBrowseResults() == false`, then call
   `RequestMoreBrowseResults()` to see whether the browse cursor survives or resets.
