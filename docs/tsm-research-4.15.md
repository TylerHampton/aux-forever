# TSM 4.15 & Desktop App Research (`TradeSkillMaster`)

Researched 2026-11-24 (Tyler's time) from the public [TradeSkillMaster](https://github.com/orgs/TradeSkillMaster/repositories)
GitHub organization (all 12 repositories checked, 9 active repositories cloned and read), TSM's
4.15 WoW: Forever release notes (`tradeskillmaster.com`, Nov 2026), TSM's AuctionDB market value
and Public Pricing Data documentation, Blizzard's Forever API documentation
(`Gethe/wow-ui-source`, branch `forever`), and the open-source MIT companion client
[Wuild/TSM-App](https://github.com/Wuild/TSM-App) for the `AppData.lua` file protocol.

Every claim below about WoW: Forever or TSM carries its source label: **`[Seen]`** (observed in
game on Forever), **`[Code]`** (verified in Blizzard's Forever UI source or TSM's GitHub source),
**`[Outside]`** (TSM blog/docs, third-party tools, or community API probes), or **`[Unknown]`**
(needs an in-game experiment).

---

## 1. Executive verdict: is auxForever faithfully "TSM-lite"?

**Mostly yes (roughly 75% there), and already ahead of TSM on zero-setup speed and Forever-native
tools, with three clear gaps keeping TSM veterans from switching completely.**

| TSM 4.15 Pillar | What TSM 4.15 Does | What auxForever Has (`gemini/0.9.1`) | Verdict |
|---|---|---|---|
| **Searching & Filtering** | Browse filter strings, Favorites/Recents, `%` of market colors | aux filter language, visual Filter Builder, Quick Searches, Favorites/Recents, Fast + Full + Live, `%` of usual colors | **Ahead of TSM for lite use** (visual builder + Fast browse) |
| **Sniping** | Buyout Sniper & Bid Sniper with custom price strings | Dedicated Sniper tab, Narrower Sniper Watch bar (All / Trade Goods / Consumables / Recipes / Categories / Favorites), Quality picker, crash-wall protection (`market_now`), 1-click buy + keybinds | **Strong** (better crash protection; misses Bid Sniper & PBS-style price-cap fast rounds) |
| **Posting & Rules** | Groups + Auctioning Operations (Min/Normal/Max rules), **4.15 Visual Post Scan** with inline Min/Normal/Max markers inside the live listing table + batch Post Scan | Single-item Post tab, Match lowest / Undercut switch, remembered price, receipt + vendor warning, auto-advance. **No Min/Normal/Max rules yet (`FB-031`, 0.9.2), no inline rule markers, no batch Bag Post Scan** | **Gap #1 (biggest missing TSM-lite piece)** |
| **Cancel Scan / My Auctions** | Cancel undercut, cancel below min, cancel to repost higher, persistent filters, bid-protection toggle | Auto undercut check on Auctions tab, Lowest / Tied / Undercut / Sold, 1-click Cancel undercut queue. **No "cancel to repost higher" indicator or persistent filters/bid guard** | **Close** (small polish needed) |
| **Price History & Market Value** | `DBMarket` (14d weighted avg, bottom 15-30% trimmed at 1.5 sigma, ~2d half-life), `DBHistorical` (60d), `DBNumAuctions` (4.15), `DBRegionSaleRate`, `DBRegionSoldPerDay` | Local `history.latest` (median of bottom 5% units), `history.value` (14d weighted median, 7d half-life), `Today` low, Full scan (`ReplicateItems`). **No passive hourly feed, no supply count in tooltips, no demand/sale-rate metric, day-only ages (0.10)** | **Strong standalone; missing passive hourly feed & demand signals** |
| **Crafting & Shopping** | Full Crafting UI, restock queue, Gathering task list | Professions Materials + Profit line, Alt-click / "Search in aux" -> **0.9.1 Shopping List** (Craft count, Have/Need, Vendor vs AH, multi-tier cost, 1-click buy + auto-advance) | **Textbook TSM-lite** (80% of value, 5% of setup) |
| **Alt Inventory Tracking** | Cross-char bags, bank, AH, mail, guild bank in tooltips & gathering | **0.9.1 opt-in Alt Inventory** (`core/inventory.lua`: bags, bank, mail, Account Bank). **Does not count alts' active AH listings yet** | **Very close** (~20 lines to add alt AH count) |
| **Accounting / Ledger** | Sales, purchases, cancels, expires, `AvgBuy`, `SmartAvgBuy`, `Expires Since Last Sale`, 4.15 Activity Feed & gold graph | **Not built yet** (`FB-069` logged 2026-11-23) | **Gap #2** (top reason goldmakers keep TSM installed) |
| **Tooltips** | Heavily configurable multi-source tooltip lines | Minimalist tooltips (Value, `%` of usual, Today, Vendor, DE, Waylaid Crate, 0.9.1 Owned) | **Faithful to lite** (cleaner than TSM; needs granular age + optional AvgBuy/supply) |
| **Desktop App & External Data** | Cross-platform desktop app syncing Blizzard Game Data API prices into `TradeSkillMaster_AppHelper/AppData.lua` + SavedVariables backups | **None yet** (manual in-game Full scans only) | **Gap #3** (post-1.0 companion app goal) |
| **Mailbox / Bank / Vendor / Destroying / Group Scripting** | Full UI replacements + recursive group trees + custom string language (`first(max(...))`) | **Not built** | **Intentionally omitted** (core reason aux stays simple and fast) |

---

## 2. What is actually inside `github.com/orgs/TradeSkillMaster`

**Important boundary:** the main `TradeSkillMaster` 4.15 addon Lua source and the official TSM
Desktop App are **not** in the GitHub organization; they are closed-source ("All Rights
Reserved") and distributed on CurseForge and `tradeskillmaster.com`.

What **is** public in `github.com/orgs/TradeSkillMaster` is all of TSM 4.15's underlying library
stack (7 MIT-licensed Lua/Python repositories), its complete localization table (All Rights
Reserved), and its Rust WoW Lua language server (GPL-3.0). All 9 active repositories were cloned
and inspected on 2026-11-24:

### 2.1 `LibTSMClass` (MIT, 897 lines Lua, updated 2026-11-19) `[Code]`
- Full OOP class system: single inheritance, `ABSTRACT`, `__private`, `__protected`, `__static`,
  class extensions (`__extend`), cached bound closures (`__closure`), weak-keyed instance tracking,
  and BFS cycle-safe object dumping (`GetDebugInfo`).
- **Hot-path trick:** leaf classes (no superclass) `rawset` all static methods directly onto each
  instance table at construction (`LibTSMClass.lua:444-449`) and `rawset` instance fields directly
  (`line 179`), avoiding `__index` overhead on single-level objects. Subclasses store fields in a
  separate `instInfo.fields` table.
- **Verdict for auxForever:** Do **not** adopt. auxForever's flat module/closure style is simpler
  and avoids metatable wrapper overhead.

### 2.2 `LibTSMCore` (MIT, 555 lines Lua, updated 2026-11-19) `[Code]`
- Component/module dependency loader (`NewComponent`, `AddDependency`, `From`, `Init` vs
  `InitInternal`, `OnModuleLoad`, `OnModuleUnload`, `OnModuleUnloadLate`).
- Tracks per-module load/unload time and supports time-budgeted unloading (`UnloadAll(maxTime)`).
- **Forever detection (`Source/Core.lua:33-34, 207-209`):** explicitly checks
  `WOW_PROJECT_ID == WOW_PROJECT_CAMELOT` and maps it to `GAME_VERSION = "FOREVER"`
  (`IsForever()`).
- **Verdict for auxForever:** Do **not** embed; auxForever already has its own lightweight module
  loader (`libs/package.lua`) and targets Forever only.

### 2.3 `LibTSMUtil` (MIT, 5,988 lines Lua across 38 files, updated 2026-11-19) `[Code]`
TSM's zero-GC performance and utility layer. Key modules read:
- **`BaseType/TempTable.lua` (228 lines):** Weak-keyed pool of recycled short-lived tables
  (`Acquire`, `Release`, `UnpackAndRelease`, `ConcatAndRelease`, up to 100 live). Released tables
  are given `RELEASED_TEMP_TABLE_MT` so any use-after-release errors immediately instead of
  silently corrupting another caller. Optional call-stack leak tracking in test builds.
- **`BaseType/ObjectPool.lua` (131 lines):** Recycled class instance pool with per-callsite leak
  stats (`GetDebugInfo`).
- **`BaseType/NamedTupleList.lua` (171 lines):** Stores rows of 1 to 6 fields inside **one flat 1D
  Lua array** (`data[(rowIndex - 1) * numFields + fieldOffset]`). Zero per-row table allocations.
- **`BaseType/SmartMap.lua` (262 lines):** Lazy memoized `key -> value` cache with read-only
  `SmartMapReader` tables (`rawset` cache on first read), reactive `ValueChanged(key)` invalidation,
  and batched reader callbacks (`SetCallbacksPaused`).
- **`FSM/` (`FSM.lua`, `Type/Object.lua`, `Type/State.lua`):** Explicit Finite State Machine with
  compile-time-validated transition graphs (`Init` checks every `toState` exists), entry/exit hooks,
  and action logging.
- **`Util/ExecutionTime.lua` (98 lines):** `WithMeasurement(label)` wraps code blocks and logs a
  warning whenever elapsed time exceeds `20 ms` (dev) or `50 ms` (release).
- **`UI/Money.lua` & `Format/MoneyFormatter.lua`:** Separate formatters for AH, UI, UI-short,
  Exact, and Tooltip. **Forever detail (`UI/Money.lua:26, 29, 42`):** only `IsRetail()` strips or
  rounds copper over 1g; `IsForever()` keeps copper everywhere (`COPPER_HANDLING.KEEP`), matching
  auxForever's `FB-044` behavior.
- **`UI/Color.lua`, `UI/ColorRamp.lua`, `UI/OKLCH.lua`, `UI/HSLuv.lua`:** Perceptual color-space
  math generating consistent lightness ramps from a single hue + chroma (powers TSM 4.15's 3-color
  theme wheel).
- **`BaseType/Encoder.lua`, `Format/CSV.lua`, `Format/JSON.lua`, `Util/BinarySearch.lua`,
  `Util/Hash.lua`, `Util/CallbackRegistry.lua`, `BaseType/ContextManager.lua`, `BaseType/Future.lua`,
  `Lua/Table.lua`, `Lua/Memory.lua`:** Serialization, sorting/diffing, and async future primitives.
- **Verdict for auxForever:** Do **not** embed the library (5,988 lines + `LibTSMClass`/`LibTSMCore`
  dependencies), **do** borrow three tiny patterns directly in plain Lua:
  1. Pooled scratch tables / flat stride arrays for hot loops (`core/history.lua`, Full scan,
     `gui/auction_listing.lua` in `0.10`).
  2. A 25-line `ExecutionTime` profiler behind `/aux debug` (`debugprofilestop() > 20 ms` warning).
  3. Explicit FSM state tables for any multi-step async workflow (as done for `post_state` in `0.9`).

### 2.4 `LibTSMDatabase` (MIT, 4,771 lines Lua, updated 2026-11-19) `[Code]`
An in-memory relational database engine written in Lua 5.1:
- **Zero-table-per-row storage (`Source/Internal/Table.lua:89, 193-197`):** All rows live inside
  one flat array `self._data` indexed by `uuid -> dataOffset`, with field offsets precomputed from
  the schema.
- **Indexes:** Unique hash maps (`_uniques`), sorted binary-search index lists (`_indexLists`),
  **trigram substring index** (`_trigramIndexLists`) for instant search-as-you-type across
  thousands of rows, and virtual `SmartMap` columns.
- **Batching:** `BulkInsertStart` / `BulkUpdateRows` rebuilds an index once when >=32 rows change
  (`BULK_UPDATE_INDEX_REBUILD_MIN_ROWS = 32`) instead of per row; `WithQueryUpdatesPaused` batches
  query notifications.
- **Queries (`Source/Internal/Query.lua`):** Pooled `DatabaseQuery` objects supporting `INNER` /
  `LEFT` / `AGGREGATE_SUM` joins, `VirtualField`, `Distinct`, multi-column sorting, and reactive
  `ReactiveStream` emission when query results change.
- **Verdict for auxForever:** Overkill to embed for auxForever's size, but explains how TSM keeps
  large tables and instant bag/group search fast without GC spikes.

### 2.5 `LibTSMReactive` (MIT, 3,153 lines Lua, updated 2026-11-19) `[Code]`
TSM 4.15's declarative UI state engine (how TSM drives live window resizing and event-driven UI
with zero per-frame `OnUpdate` polling):
- **`ReactiveState` / `ReactiveStream` / `PublisherSchema`:** UI widgets subscribe to typed state
  keys through chained operators (`Map`, `IgnoreIfEquals`, `CallMethod`, etc.).
- **Compiled pipelines (`Source/Internal/PublisherCodeGen.lua`):** Rather than chaining closures at
  runtime, TSM compiles each reactive pipeline string into a straight-line Lua function via
  `loadstring` inside a strict sandboxed `FUNC_ENV` (lines 109-133) and caches compiled functions
  by hash. Firing a state update allocates zero tables and zero closures.
- **`UIManager` & `UIBindings` (`Source/UIManager.lua`, `Source/UIBindings.lua`):** Central action
  dispatcher (`ProcessAction`), `ManageFuture` / `CancelFuture` for cancelling stale async work,
  and action logging.
- **Verdict for auxForever:** Too heavy to embed, but validates auxForever's own `0.10` direction
  (dirty flags + event-driven updates instead of `OnUpdate` polling).

### 2.6 `LibBonusId` (MIT, 430 lines Lua + data, updated 2026-11-21) & `BonusIdTool` (MIT, 2,634 lines Python, updated 2026-11-08) `[Code]`
- Parses Blizzard DB2 files from `wago.tools` (`ItemBonus`, `ItemSparse`, `CurvePoint`,
  `ContentTuning`, `ItemXBonusTree`, etc.) to compute retail item levels and filter effective bonus
  IDs offline.
- **Direct WoW: Forever findings (`LibBonusId.lua:13`, `BonusIdTool/lib/generate_addon_data.py:62-63, 118-143`):**
  - `PRODUCT = WOW_PROJECT_ID == WOW_PROJECT_CAMELOT and "wowf" or "wow"`.
  - WoW: Forever builds have **no item-level scaling tables** (`--product wowf` calls
    `_generate_filter_data()`). `DataForever.lua` only contains `tooltip_bonuses` (bonus IDs that
    visibly change stats, quality, name suffix, sockets, required level, etc.) and
    `item_tree_bonuses` (bonus 3524). All item-level calculation calls return `nil` on Forever.
  - **`DataForever.lua` loading trick:** TSM ships the Forever table as a single Base64 + Deflate +
    CBOR blob and decodes it in native C++ at load time (`~20 ms` per README):
    `C_EncodingUtil.DeserializeCBOR(C_EncodingUtil.DecompressString(C_EncodingUtil.DecodeBase64(DATA)))`.
  - Verified `[Code]` on 2026-11-24 in Blizzard's Forever API documentation
    (`Gethe/wow-ui-source`, branch `forever`, `EncodingUtilDocumentation.lua`): Forever includes
    `C_EncodingUtil.CompressString`, `DecompressString`, `EncodeBase64`, `DecodeBase64`,
    `SerializeCBOR`, `DeserializeCBOR`, `SerializeJSON`, and `DeserializeJSON`. Not yet tested in
    game (added as Experiment **E13** in `docs/forever-auction-house.md`).
- **Verdict for auxForever:**
  - **In-game addon:** Do **not** embed `LibBonusId`. On Forever, auxForever's `info.price_key`
    (`"4575:of the wolf"`) already groups random-suffix gear cleanly without a DBC bonus table
    (confirmed `[Seen]` 2026-10-20 that identical suffix names share stats on Forever).
  - **Future Desktop App backend:** `BonusIdTool`'s DBC extraction technique (`wago.tools` `wowf`
    `ItemBonus` + `ItemNameDescription` -> suffix text) **will be directly useful** on the server
    side to map Blizzard Game Data API `item.bonus_lists` IDs back to auxForever's
    `"itemID:of the ..."` price keys!

### 2.7 `TSM-Localization` (All Rights Reserved, 1,440 strings in `enUS.txt`, updated 2026-11-20) `[Code]`
- Complete catalog of every user-facing string in TSM 4.15 (do **not** copy strings; read only to
  understand TSM 4.15's exact feature set).
- Confirms TSM 4.15's Forever and new features:
  - `enUS.txt:1229`: `"TSM now supports WoW: Forever, including AuctionDB price data from the TSM Desktop App."`
  - `enUS.txt:881`: `"Post scans now show the current auctions for each item alongside your min, normal and max prices. Drag or double-click an auction to undercut it instead."`
  - `enUS.txt:1243`: `"The Dashboard now has an Activity feed showing your recent sales, purchases, expirations and cancellations."`
  - `enUS.txt:194-208`: New `DBNumAuctions` and `DBAlt*` (alternate realm) price sources.
  - `enUS.txt:66-67, 835`: Automatic Accounting trimming when SavedVariables grow too large, and
    only loading the last 6 months of Accounting purchases/sales per realm.
  - `enUS.txt:291`: `"Can't load TSM tooltip while in combat"` (combat safety guard).
  - `enUS.txt:605, 1231`: Buyout confirmation alert only above a configurable price threshold.

### 2.8 `wowlua-ls` (GPL-3.0, ~38,000 lines Rust, updated 2026-11-22) & `wowlua-ls-zed` `[Code]`
- Sapu's purpose-built WoW Lua Language Server with a CI CLI (`wowlua_ls check path/to/addon`).
- Built-in features directly relevant to auxForever (`crates/wowlua_core/src/flavor.rs`, `CLAUDE.md`):
  - **9,000+ built-in WoW API stubs including native `forever` (`camelot`) flavor support** (auto-detected from `## Interface: 16001` or `.wowluarc.json`).
  - **1,000+ typed WoW events**, `.toc` validation, `wrong-flavor-api` detection.
  - **Static secret-value analysis** (`secret_context.rs` / `secret_narrowing.rs`) that flags
    unsafe comparisons, arithmetic, indexing, and table keys on Blizzard secret values before they
    cause `FB-056`-style runtime errors in dungeons.
- **Verdict for auxForever:** Strong candidate as a **development / CI tool only** (GPL-3.0 never
  touches shipped addon code). Needs a short spike to verify how cleanly it parses auxForever's
  `select(2, ...) 'aux.module'` dynamic environment before deciding whether to run it in GitHub
  Actions alongside `tests/load_test.lua` and `tests/lint_globals.lua`.

### 2.9 `luacheck` & `do-actions-runner`
- Forks used for TSM's own linting and DigitalOcean CI runners. Not relevant to auxForever.

---

## 3. What TSM 4.15 does really well that we can build a "lite" version of

Ranked by impact for auxForever's TSM-lite identity vs complexity cost. Every visible change still
gets a mockup for Tyler before building (`AGENTS.md`).

### Priority 1: TSM 4.15-Style Visual Posting Rules + Bag Post Scan (`FB-031`, target `0.9.2`)
- **What TSM 4.15 nailed (`[Outside]` announcement + `enUS.txt:881`):** Even veteran TSM users
  struggled to tell *why* an Auctioning Operation picked a price. TSM 4.15 solved it by putting
  three inline markers (`Min`, `Normal`, `Max`) directly inside the live auction list for the item
  being posted, plus a one-line status reason and click/drag to undercut a different row.
- **How to build the auxForever-lite version (zero Groups, zero scripting syntax):**
  - Keep a single clean **Posting Rules** configuration (optional lightweight presets like
    *Default*, *Trade Goods*, *Gear*, or per-item override, no nested Group trees):
    - **Floor (Min):** `%` of usual price (never below `vendor / 0.95` when vendor-safe is checked),
      with action when AH lowest is below Floor: *Post at Floor*, *Post at Normal*, or *Flag & skip*.
    - **Normal (No competition):** `%` of usual price (e.g. `120%`).
    - **Ceiling (Max):** `%` of usual price (e.g. `200%`), with action when AH lowest is above
      Ceiling: *Post at Ceiling*, *Post at Normal*, or *Match/undercut anyway*.
  - **Visual price ladder in the Post tab:** Render subtle inline rule lines (`Min`, `Normal`,
    `Max`) right inside the Post tab's existing listings table so the player sees at one glance
    where their rule sits against live competitors. Clicking any competitor row overrides the rule
    for that post (aux informs, never locks the player out).
  - **Optional Bag Post Scan ("Post All" queue):** Scan visible bag items -> show a compact ready /
    below-floor summary with total expected gold -> click Post (or press keybind) repeatedly to
    post down the queue.

### Priority 2: Lite Accounting Ledger + `Smart Avg Buy` (`FB-069`, target `0.9.2` or `0.10`)
- **What TSM Accounting nailed (`[Outside]` + `enUS.txt:36-41, 312, 504, 1160, 1243`):**
  - Passive recording of **Purchases**, **Sales**, **Cancels**, and **Expirations** (no manual
    data entry).
  - **`Smart Avg Buy`:** averages only the *most recent N purchased units* matching what you
    currently own (so buying Linen Cloth at 15c a month ago does not skew today's 40c flip cost).
  - **`Expires Since Last Sale`:** surfaces dead inventory that keeps burning deposits.
  - **TSM 4.15 Activity Feed:** a clean chronological feed of recent sales, purchases, cancels, and
    expirations plus 7d / 30d / All-Time totals (Spent, Earned, Net Profit).
  - **Auto-trimming (`enUS.txt:66-67, 835`):** cap or roll off old transaction records (e.g., 180
    days) so SavedVariables never blow up.
- **Prerequisites before building:**
  1. Fix `FB-065` (`Region|Ruleset|Faction` SavedVariables key) so ledger records are never split or
     orphaned across Forever subrealms.
  2. Settle Experiment **E1** (Forever's `"Auction successful"` mail invoice format and
     `GetInboxInvoiceInfo` return values) and **E4** (expired mail format).

### Priority 3: Auctions Tab Upgrades + Alt AH Inventory (`0.9.1` follow-up / `0.9.2`)
- **"Cancel to Repost Higher" status (`enUS.txt:295, 308, 830`):** When you are the cheapest
  seller by a large margin (competition was bought out above you), flag the row (e.g. `"Underpriced
  (next: 35c)"`) so you can cancel and relist higher. `tabs/auctions/core.lua` already fetches the
  item's full listings during `check_prices`, so this needs zero extra AH requests.
- **Auctions with bids guard + persistent filter/sort:** Protect auctions that already have a bid
  from accidental cancel-undercut clicks, and remember tab filters/toggles across AH visits (new
  in TSM 4.15).
- **Add active AH listings to `core/inventory.lua` (`0.9.1` follow-up):** Record each character's
  active auctions on `OWNED_AUCTIONS_UPDATED` (~20 lines) so tooltips and the Shopping List show
  `bags, bank, AH, mail` just like TSM (`enUS.txt:28-31`).

### Priority 4: Price Data, Supply Signals & Threshold Buy Guard (`0.9.2` / `0.10`)
- **TSM `DBMarket` vs auxForever `core/history.lua` (`[Outside]` TSM Support + `[Code]`):**
  - *Single scan:* auxForever uses the **median of the cheapest 5% of units** (`MARKET_SHARE = .05`,
    tuned on Forever after Tyler tested 20% in `docs/price-data.md:134-137`). TSM takes the bottom
    15% to 30% (stopping at any >=20% price jump after 15%), removes outliers >1.5 std dev from the
    mean, and averages the rest. Keep auxForever's bottom-5% median for `latest` ("what it really
    costs to buy right now").
  - *Multi-day decay:* auxForever uses a **7-day half-life** over 14 days (excluding today until
    midnight). TSM uses a **~2-day half-life** over 14 days (including today's scans averaged) plus
    a separate 60-day `DBHistorical`. In Forever's young economy, testing a faster half-life (3 to
    4 days) could reduce stale-usual Sniper false positives (`FB-036`).
  - **Expose supply (`units` listed) in tooltips (TSM 4.15 `DBNumAuctions` lite):** `core/history.lua`
    already stores `record.units` on every complete view! Showing it as an optional tooltip line
    (or next to Value, e.g. `420 listed`) gives players an instant liquidity clue with almost no
    extra code.
- **Smart Buyout Confirmation Threshold (`enUS.txt:285, 605, 1231`):** Instead of only all-on or
  all-off "Confirm before buying" (`0.8.2.2`), add an optional threshold (e.g., *"Confirm when
  total spend is over X gold"* or *"over 150% of usual"*). Keeps 1-click sniping instant for cheap
  items while catching fat-finger 500g bait listings.

### Priority 5: Quick TSM 4.15 QoL Polish
- **Post from Search (`enUS.txt:880`):** Right-click or button on a Search result row for an item
  you own -> jump straight to the Post tab pre-selected and pre-priced to match/undercut that row.
- **Optional Sound Picker (`enUS.txt:187, 192, 544`):** Choose built-in `SOUNDKIT` alerts (Raid
  Warning, Cash Register / Money Frame Open, Ready Check, Alarm Clock, None) for Sniper deals and
  Auction Sold (`ERR_AUCTION_SOLD_S`).
- **Auto-focus Search input** and **Prevent ESC from closing AH** toggles (`enUS.txt:223, 896`).
- **Granular scan age in tooltips** (`"42m ago"`, `"3h ago"`; already on the `0.10` roadmap).

---

## 4. What NOT to copy from TSM (protecting auxForever's identity)

1. **No recursive Group trees or custom price-expression language** (`first(max(120% dbmarket, ...))`).
   TSM's hours-long setup wall is the main reason players look for auxForever. Keep posting rules
   as plain controls (checkboxes, `% of usual`, gold boxes, clear live markers).
2. **No full UI replacements for Mailbox, Bank/Warehousing, Vendor, or Destroying.** That expands
   maintenance surface massively and collides with bag/mail addons (Bagnon, Postal, Leatrix Plus).
   Passive reading of mailbox invoices/alt mail inside Blizzard's own UI is fine; replacing those
   frames is not.
3. **No embedding the 15,400-line `LibTSM*` framework stack.** auxForever is 22,664 lines total
   with zero external dependencies. Borrow specific micro-patterns (flat arrays, pooled temp
   tables, `ExecutionTime` debug helper), not the framework.
4. **No mandatory desktop app or paywalled features.** Everything in auxForever must continue to
   work 100% standalone from in-game scans; a future desktop app is strictly an optional upgrade.

---

## 5. Blueprint for a future auxForever Desktop App (post-1.0)

### 5.1 How WoW allows a desktop app to feed an addon (100% ToS-safe) `[Outside]`
WoW addons cannot open sockets or read arbitrary files. Every legal companion app (TSM Desktop App,
Forever Profiteer, wowfah Sync, Oribos Exchange) uses the same file bridge:
- **App -> Addon (Hourly Prices In):** A tiny companion addon folder (`auxForever_AppData` next to
  `auxForever`, identical in role to `TradeSkillMaster_AppHelper`) containing a single generated
  `AppData.lua`. The desktop app writes to a temporary file and atomically renames it over
  `AppData.lua` (see `Wuild/TSM-App`'s `AppDataFileWriter.cs`). On login or `/reload`, WoW loads
  the file in ~20 ms (especially if packed with Base64 + Deflate + CBOR via `C_EncodingUtil`,
  pending **E13**).
- **Addon -> App (Backups & Analytics Out):** The desktop app watches
  `World of Warcraft\_forever_\WTF\Account\<ACC>\SavedVariables\auxForever.lua` on logout/`/reload`
  to save automatic rolling local backups (and optionally display ledger charts / price history
  outside the game).

### 5.2 Where Forever's hourly auction data comes from `[Outside]`
Two real-world options were investigated:

1. **Recommended: Blizzard's Official WoW: Forever Game Data API -> Tiny Static CDN Pipeline**
   - Community probes on launch day (Nov 5, 2026) and active Forever sites (`wowfah.com`,
     `foreverprofiteer.com`, `timesaver.gg`) confirm Blizzard publishes hourly WoW: Forever AH
     snapshots via OAuth client credentials (`[Outside]`):
     - Base URLs: `https://{us,eu}.api.blizzard.com`, namespace `?namespace=dynamic-forever-{region}`
     - Routes: `/data/wow/ruleset/index` (Rulesets: `1` PvP, `2` Normal, `3` Roleplay, `15` RP-PvP),
       `/data/wow/ruleset/{rulesetId}/auctions/index`,
       `/data/wow/ruleset/{rulesetId}/auctions/{houseId}` (gear/items, `buyout` in copper +
       `item.bonus_lists`), and `.../commodities` (trade goods, `unit_price` in copper).
     - Note: Forever uses `/ruleset/{id}` instead of `/connected-realm/{id}`, and the house-ID to
       ruleset/faction mapping requires verification per region before merging (launch-day probe
       observed overlapping house IDs across ruleset indexes).
   - **Why a tiny server/worker sits in the middle:** Blizzard OAuth client secrets must never be
     shipped inside a downloadable desktop app. A cheap scheduled worker (e.g., Cloudflare Worker +
     R2 or a small VPS cron) polls Blizzard once per hour per region/ruleset/house, computes:
     - Current market price (auxForever's bottom-5% median) & min buyout
     - 14-day weighted usual price + 60-day historical average
     - Active supply count (units & listings)
     - Estimated daily sales / turnover velocity (diffing consecutive hourly snapshots)
     - **Gear random-suffix keys:** Blizzard's API sends `item.bonus_lists` instead of item names;
       extracting Forever's `ItemBonus` + `ItemNameDescription` DB2 tables (the exact `BonusIdTool`
       method!) lets the server emit auxForever's exact `"4575:of the wolf"` price keys.
   - Publishes one tiny pre-compressed static blob per market (`US-Normal-Alliance`, etc.) on a
     static CDN. Desktop clients poll with `If-Modified-Since` / `ETag` -> near-zero server cost
     even at large scale.

2. **Alternative (Not Recommended as Primary): TSM Public Pricing Data CSVs**
   - TSM publishes free static CSV files at `https://public-data.tradeskillmaster.com/{gameType}/{regionSlug}/realm/{realmSlug}/items.csv`
     (with `gameType = forever` listed in their docs, updated ~every 3 hours, plus daily
     `region/items.csv` with `saleRate` and `soldPerDay`).
   - Terms of Use (`tradeskillmaster.com/public-data`) explicitly allow free use in third-party
     addons/tools with attribution (`"Pricing data from TradeSkillMaster"` + link), **but** forbid
     republishing in bulk as your own feed, carry no availability/format guarantee, update every
     ~3 hours (vs Blizzard's 1 hour), and only key by base `itemId` (no Forever random-suffix gear
     separation).

### 5.3 Concrete MVP & Prep Work
- **Prep inside auxForever now (costs nothing extra, aligns with current roadmap):**
  1. Fix `FB-065` with canonical `Region|Ruleset|Faction` market keys (e.g. `US|Normal|Alliance`,
     `US|PvP|Horde`, `US|Normal|Neutral`), matching the exact keys a desktop app will write.
  2. Keep `core/history.lua` cleanly separated so an optional `auxForever_AppData` loader can later
     supply external baseline metrics (usual, 60d historical, supply, est. sales/day, timestamp)
     while live in-game scans still override `latest` / `Today` immediately.
  3. Confirm Experiment **E13** (`C_EncodingUtil` on Forever).
- **When to build the Desktop App:** **After auxForever `1.0` ships.** Shipping `FB-065`, `0.9.1`
  (Shopping List + Alt Inventory), `0.9.2` (Visual Posting Rules + Lite Ledger), `0.10`
  (Performance, granular scan ages, Neutral AH, Sniper speed), and `1.0` first keeps focus on the
  core addon; then the desktop app launches cleanly as **Companion v1** (Win/Mac/Linux tray app:
  auto-detect `_forever_`, hourly price sync into `auxForever_AppData/AppData.lua`, SavedVariables
  auto-backup, optional addon updater from GitHub Releases).

---

## 6. Experiment added to `docs/forever-auction-house.md` (0 Gold)

- **E13 (`C_EncodingUtil` live check on Forever):** Confirm Blizzard's documented C++
  `C_EncodingUtil` (`EncodeBase64`/`DecodeBase64`, `CompressString`/`DecompressString`,
  `SerializeCBOR`/`DeserializeCBOR`, `SerializeJSON`/`DeserializeJSON`) works at runtime on Forever
  without restriction, as used by `LibBonusId/DataForever.lua`.
