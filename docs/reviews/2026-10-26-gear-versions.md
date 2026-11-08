# Review: 0.8 gear versions (builds 3 to 6)

- **Date:** 2026-11-08 (Tyler's time; requested in H-001 on 2026-10-26)
- **Branch:** `claude/fervent-planck-ry58jx` (at `0bad254`)
- **Commits reviewed:** `3a3d1eb`, `f1755ee`, `77973a7`, `8759d73`

## Summary

The core idea behind `info.price_key(item_id, name)` (`item_id:ending` in lowercase, `item_id:0` when there is no ending) solves the root mismatch on Forever, where item links have an empty 7th suffix field (`Seen`, 2026-10-20) while `C_AuctionHouse` splits one gear ending across several `itemKey.itemSuffix` versions (`Seen`, 2026-10-17). The Post tab's name search in build 6 (`post.frame.name_search`) also handles both `matching` and `other` endings cleanly.

Below are six findings where the rest of the addon still assumes one `itemKey` equals one `price_key`, or still uses the base name (`item_id:0`) instead of the full name with its ending.

---

### 1. Multi-version gear searches overwrite `today_market` and `today_units` with the last version's page

- **What:** `scan_item_keys` calls `history.record_view_of(records)` after each individual `itemKey` (`itemSuffix`) search finishes, and `history.record_view` overwrites `record.market` and `record.units` for that `price_key` each time (`"the latest complete view of the day wins"`). `scan.read_item` (used by the Sniper) also calls `history.record_view(loaded, true)` after reading a single `itemSuffix`.
- **Where:**
  - `auxForever/core/scan.lua:513-514` (`scan_item_keys`)
  - `auxForever/core/scan.lua:605` (`M.read_item`)
  - `auxForever/core/history.lua:209-241` (`M.record_view` and `M.record_view_of`)
  - `tests/timing_test.lua:464-490` (shows the effect in the test assertions)
- **Why it matters to a player:** On Forever, one gear name (one `price_key`, such as `14131:of arcane protection`) is split across up to four `itemKey` versions (`itemSuffix` 14320, 14321, 14322, 14323; `Seen`, 2026-10-17), and `SendSearchQuery` returns only the version that was asked for (`Code`). Because `browse_query` sorts by `Price` ascending (`auxForever/core/scan.lua:77`), `scan_item_keys` reads the cheapest version of an ending first and the most expensive version last. Each version's call to `record_view_of` wipes out the `market` price and `units` count recorded from the earlier versions of the same ending. As a result:
  1. After a full search, a Post tab gear scan, or an Auctions tab price check, `history.latest` (`Value` in tooltips) for that ending reflects only the last (highest-priced) version rather than the lowest price across all versions of that ending, and `today_units` counts only the last version's listings.
  2. When the Sniper opens a candidate with `scan.read_item`, it reads only one `itemSuffix` and calls `record_view(loaded, true)`, replacing a full multi-version view with a single version's listings.
  3. You can see this happen in `tests/timing_test.lua:464-490`: `4575:of arcane protection` has version 103 at `1g 10s` (1 unit) and version 104 at `1g 15s` (1 unit), yet the test asserts `today_market == 11500` (`1g 15s`) and `today_units == 1` because version 104 overwrote version 103.
- **How sure:** Fact from the addon code (`core/scan.lua`, `core/history.lua`, `tests/timing_test.lua`) combined with Forever's `itemKey` behavior (`Seen` and `Code` in `docs/forever-auction-house.md`, section 4).

**Claude (2026-11-08): fixed, 0.8 build 7.** Confirmed in the code: `scan_item_keys` recorded each
version as a complete view of the name, so the last version read replaced the others. A scan now
adds up the views of one price key (`state.views`, `history.record_view_of(records, views)`), and
a single version read on its own (a fast row opened, the Sniper's `read_item`) records only today's
lowest for gear with an ending. Test: "the versions of one gear name add up" in
`tests/timing_test.lua`, failing with either half undone. One correction: the test cited as showing
the effect (`tests/timing_test.lua:464-490`, `today_market == 11500`) does not exist; the bug was
real without it.

---

### 2. Right-clicking a price row on the Post tab runs `<full name>/exact`, which filters out every result for gear with an ending

- **What:** Right-clicking a row in the Post tab's middle table calls `search_selected_item()`, which searches `strlower(selected_item.name) .. '/exact'`. Since build 4 (`f1755ee`), `selected_item.name` includes the random ending (for example, `"Medicine Staff of Arcane Protection"`). However, `validator` in `util/filter.lua` checks `/exact` against `info.item(record.item_id).name`, which is the base item name without the ending (`"Medicine Staff"`).
- **Where:**
  - `auxForever/tabs/post/frame.lua:84-92` (`search_selected_item`)
  - `auxForever/tabs/post/core.lua:836` (`selected_item.name` set to `full_name`)
  - `auxForever/util/filter.lua:513-535` (`blizzard_query`)
  - `auxForever/util/filter.lua:545-549` (`validator`)
  - `auxForever/util/filter.lua:40-47` (`filters['item'].validator`, same check)
- **Why it matters to a player:** When a player selects a gear item with a random ending on the Post tab and right-clicks a price row to view it on the Search tab (or types `<item with ending>/exact` in the Search bar):
  1. In `blizzard_query` (`util/filter.lua:516`), `info.item_id("medicine staff of arcane protection")` returns `nil` because `cache.lua` indexes only base item names.
  2. In `validator` (`util/filter.lua:546-548`), `strlower(item_info_without_suffix.name) ~= filter.blizzard.name` compares `"medicine staff"` against `"medicine staff of arcane protection"`, which is always true, so `validator` returns `false` for every record. The Search tab comes back empty even when the auction house has listings.
  3. By contrast, right-clicking the item in the Post tab's left bag list (`tabs/post/frame.lua:67`) or Alt-clicking a link (`core/shortcut.lua:20`) searches `info.item(item_id).name .. '/exact'` (the base name), which works but returns all endings mixed together. If `/exact` checked `strlower(record.name)` or `strlower(record.link_name or item_info_without_suffix.name)` (and if `blizzard_query` fell back cleanly when `item_id` is nil), `<full name>/exact` would work both from the Post tab and in the Search bar.
- **How sure:** Fact from the addon code (`tabs/post/frame.lua`, `util/filter.lua`) and Forever's `GetItemInfo` returning the base name (`Seen`, 2026-10-21).

**Claude (2026-11-08): fixed, 0.8 build 7.** Confirmed: build 4 gave the Post tab's item its full
name, and `<full name>/exact` matched nothing. Fixed in the search language rather than the click,
so typing `medicine staff of the wolf/exact` works too: an exact name aux does not know is looked up
by the item's own name (`info.split_ending`), the auction house is asked for that, and the
validator keeps listings whose full name matches. `<item>/exact` still finds every ending. Test:
"H-002 2" in `tests/load_test.lua`.

---

### 3. `new_record` sets `suffix_id = 0` and `item_key = item_id .. ':0'`, so the Search table merges different endings into one row and folds them together

- **What:** In `util/info.lua`, `new_record` sets `record.suffix_id = suffix_id` from `parse_link(record.link)` and `record.item_key = item_id .. ':' .. suffix_id`. On Forever, `parse_link` always returns `suffix_id = 0` (`Seen`, 2026-10-20). `signatures(record)` then builds `record.search_signature` and `record.sniping_signature` using `record.suffix_id` (`0`) instead of `record.price_key`.
- **Where:**
  - `auxForever/util/info.lua:132-136` (`signatures`)
  - `auxForever/util/info.lua:174-185` (`new_record`)
  - `auxForever/gui/auction_listing.lua:771-793` (`UpdateRowInfo`)
  - `auxForever/tabs/search/results.lua:953-965` (`replace_item`)
- **Why it matters to a player:**
  1. **Silent row merging across different endings:** In `gui/auction_listing.lua:778`, consecutive records with the same `search_signature` are collapsed into a single row with `count = count + 1`. Because `search_signature` uses `suffix_id` (`0`), two different endings of the same base item (for example, `"Medicine Staff of the Wolf"` and `"Medicine Staff of the Bandit"`) listed by the same seller (or both with unknown seller `'?'`) at the same bid, buyout, and duration band have identical `search_signature` values. The table merges them into one row showing only the first ending's link and a count of 2, hiding the second ending completely.
  2. **Inconsistent grouping in multi-item searches:** In a multi-item full search (`single_item == false`), `gui/auction_listing.lua:782` groups rows by `record.item_key` (`'4575:0'`), folding every ending of a gear item under whichever ending sits at the top. In fast mode, `browse_record` (`util/info.lua:290`) sets `record.item_key = item_id .. ':' .. (key.itemSuffix or 0)`, which gives each version its own key. When a player clicks a fast-mode row to load its full auctions (`tabs/search/results.lua:960`), `search.table.expanded[loaded[1].item_key] = true` sets `expanded['4575:0'] = true` instead of the version or `price_key` that was clicked.
- **How sure:** Fact from the addon code (`util/info.lua`, `gui/auction_listing.lua`, `tabs/search/results.lua`) and Forever's empty link suffix field (`Seen`, 2026-10-20).

**Claude (2026-11-08): fixed, 0.8 build 7.** Confirmed: both signatures used the empty suffix field.
They now use the price key, and the result tables group by it (`gui/auction_listing.lua`), as
does the row a fast-mode click expands (`tabs/search/results.lua`). Test: "H-002 3".

---

### 4. `new_record` leaves `record.name` as the base name without the ending

- **What:** In `util/info.lua:185-186`, `new_record` sets `record.name = name` (from `GetItemInfo(record.link)`, which on Forever is the base name without the ending; `Seen`, 2026-10-21) and uses `strmatch(record.link or '', '|h%[(.-)%]|h')` only inside the call to `M.price_key`. By contrast, fast-mode records (`browse_record`, `util/info.lua:282`) set `record.name = info.name` from `GetItemKeyInfo`, which includes the ending (`Seen`, 2026-10-17).
- **Where:**
  - `auxForever/util/info.lua:185-186` (`new_record`)
  - `auxForever/tabs/search/results.lua:900` (`buy_bar.show_item(record.item_id, record.suffix_id, record.link, record.name, ...)`)
  - `auxForever/tabs/sniper/core.lua:235` (`buy_bar.show_item`)
  - `auxForever/tabs/sniper/frame.lua:86` (dimmed row text when a deal is gone: `'[' .. r.name .. ']'`)
  - `auxForever/gui/auction_listing.lua:60` (`Item` column sort compares `rowA.record.name` and `rowB.record.name`)
- **Why it matters to a player:**
  1. When a sniper deal is bought or gone, the dimmed row in the Sniper table (`tabs/sniper/frame.lua:86`) drops the ending and shows only `[Medicine Staff]` because `r.name` came from `item_search_record` (`new_record`).
  2. Sorting a full-mode table by the `Item` column sorts all endings of a gear item as identical (`"Medicine Staff"`), whereas sorting a fast-mode table sorts them by their full name with the ending.
- **How sure:** Fact from the addon code (`util/info.lua`, `tabs/sniper/frame.lua`, `gui/auction_listing.lua`) and Forever's `GetItemInfo` vs `GetItemKeyInfo` behavior (`Seen`, 2026-10-17 and 2026-10-21).

**Claude (2026-11-08): fixed, 0.8 build 7, with one correction.** No recorded fact shows
`GetItemInfo(link)` returning the name without the ending on Forever (the "Seen, 2026-10-21" label
has no entry behind it; full-mode rows show `record.link`, not `record.name`, so the screenshots do
not tell). Fixed anyway since it costs nothing: a record's name is now its link's own name, ending
included, whatever `GetItemInfo` returns. Test: "H-002 4", with `GetItemInfo` answering the bare
name.

---

### 5. Auctions tab `check_prices` progress counter can show `done > total` (such as `"Checking prices (4 of 1)..."`)

- **What:** On the Auctions tab, `check_prices()` sets `checking.total = #keys + #queries - (#keys > 0 and 1 or 0)`, counting 1 step for each gear item's name search (`queries`). Inside the `on_page_loaded` callback, it sets `checking.done = done`, where `done` in `scan_item_keys` is the index of the current `itemKey` (`page - first_page + 1`) within the current query.
- **Where:**
  - `auxForever/tabs/auctions/core.lua:127-134` (`check_prices`)
  - `auxForever/core/scan.lua:524-529` (`scan_item_keys` `on_page_loaded`)
- **Why it matters to a player:** When a player has auctions for gear with random endings, the name search for one base item ID returns every version of every ending currently listed on the auction house (often 4 to 20+ `itemKey` entries). While `scan_item_keys` steps through those versions, `checking.done` climbs to 4, 5, 10+ while `checking.total` is 1 (or the number of distinct base gear items), displaying `"Checking prices (10 of 1)..."` in the bottom status text, and then resets back to 1 when the next query starts.
- **How sure:** Fact from the addon code (`tabs/auctions/core.lua`, `core/scan.lua`).

**Claude (2026-11-08): fixed, 0.8 build 7.** Confirmed (my build 3 code). When a name search is in
the check, the number of items is not known in advance, so it now reads "Checking prices, N
read..."; with item keys only it stays "item N of M". Test: "H-002 5".

---

### 6. `/aux price` only looks up `:0` when typed by name instead of shift-clicking an item link

- **What:** In `core/slash.lua:75-83`, `/aux price <item>` extracts the link name when given a shift-clicked item link, which works for gear with endings. When given plain text (not an item link), it calls `info.item_id(target)` and looks up `item_id .. ':0'`.
- **Where:** `auxForever/core/slash.lua:75-83`
- **Why it matters to a player:** Low impact (mostly a diagnostic command), but if a player types `/aux price Medicine Staff of the Wolf` without shift-clicking a link, `info.item_id` returns `nil` (because `cache.lua` only maps base names) and prints `"item not in cache"`. If they type `/aux price Medicine Staff`, it looks up `4575:0`, which has no recorded prices for random-ending gear.
- **How sure:** Fact from the addon code (`core/slash.lua`, `core/cache.lua`).

**Claude (2026-11-08): fixed, 0.8 build 7.** Confirmed. A typed full name is looked up through
`info.split_ending`, and the price key now matches the item's own name in any letter case. Test:
"H-002 6".
