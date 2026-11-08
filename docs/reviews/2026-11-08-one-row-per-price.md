# Review: 0.8 build 9 (one row per price) and build 8 (Post tab skip of other endings)

- **Date:** 2026-11-08 (Tyler's time; requested in H-003 on 2026-11-08)
- **Branch:** `claude/fervent-planck-ry58jx` (at `c02c9b0`)
- **Commits reviewed:** `e76c347` (0.8 build 9, one row per price) and `46ecded` (0.8 build 8, Post tab skip of other gear endings)

## Summary

Answers to the three core safety questions in H-003 first:

1. **Can a merged row ever buy at a price other than the one shown?**
   **No.** Every record merged into a `price_group` (`auxForever/gui/auction_listing.lua:784-790`) has the exact same `buyout_price`, `count`, `sale_status`, and `info.is_player(record.owner)`. The row keeps one real auction record untouched as `child.record` (`record.auction_id` and `record.item_search_key` stay paired). When the player buys, `aux.place_bid(record.auction_id, record.buyout_price)` sends the exact buyout shown on the row, and `sync_bucket` (`auxForever/tabs/search/results.lua:859-884`) removes that bucket when it is bought out so the next seller's record at that price steps into `child.record`.
2. **Can a merged row ever bid on the wrong auction or hide a biddable auction?**
   **Yes, in two cases (Findings 2 and 3).** First, bid-only auctions (`buyout_price == 0`) at different bid prices share `buyout_price = 0` in `price_group` and merge into a single row, hiding all but one bid price. Second, within a buyout `price_group`, records are sorted by string comparison on `search_signature` (`"1200" < "200"`), so a buyout-only auction (`start_price = 1200`) sorts ahead of an auction with a `2s` (`200`) or `9s` (`900`) starting bid and hides the `Bid` button for that price row.
3. **Can a merged row hide an auction a player needs to see (your own auctions, the Bids tab, the Sniper)?**
   - **Your own auctions:** **Safe.** The Auctions tab sets `listing.one_row_each = true` (`auxForever/tabs/auctions/frame.lua:128`), `price_group` separates `info.is_player(record.owner) and 1 or 0` on the Search tab (`auxForever/gui/auction_listing.lua:789`), and `record_auction` on the Post tab separates `info.is_player(auction.owner) == record.own` (`auxForever/tabs/post/core.lua:1029, 1066`).
   - **The Bids tab and the Sniper tab:** **Not safe yet (Findings 1 and 4).** Neither `auxForever/tabs/bids/frame.lua` nor `auxForever/tabs/sniper/frame.lua` sets `listing.one_row_each = true`, so both inherit `price_group` merging from `auction_listing`.

Below are the seven findings in build 9 and one note on build 8.

---

### 1. Bids tab does not set `listing.one_row_each = true`, so two bids at the same buyout merge into one row

- **What:** `auxForever/tabs/bids/frame.lua:19` creates its table with `auction_listing.new(frame.listing, 22, auction_listing.bids_columns)` and leaves `listing.one_row_each` nil. In `auxForever/util/info.lua:368-382`, `bid_record` builds a record per `auctionID` with `record.owner = nil`, `record.buyout_price = bid.buyoutAmount`, and `record.high_bidder = bid.bidder and bid.bidder == player_guid() or nil`.
- **Where:**
  - `auxForever/tabs/bids/frame.lua:19-21`
  - `auxForever/gui/auction_listing.lua:784-790, 803-812` (`price_group` and row merging)
  - `auxForever/util/info.lua:368-382` (`M.bid_record`)
- **Why it matters to a player:** On the Bids tab, each entry from `C_AuctionHouse.GetBidInfo` is a specific auction the player has bid on (`[Code]`, `docs/forever-auction-house.md`, section 8). If a player bids on two auctions of the same item or gear ending that have the same `buyout_price` (for example, two listings with a `12s` buyout, or two bid-only listings with `buyout_price = 0`) and the same `high_bidder` state (both `High Bidder` or both `Outbid`), `price_group` is identical for both. `UpdateRowInfo` merges them into one row showing `Quantity = 2` and `"2 sellers"` (because `not record.owner` is true on line 805). The second auction's current bid, time left, and `auction_id` are hidden behind the first, so the player cannot select, re-bid, or buy out the second auction independently. Setting `listing.one_row_each = true` in `tabs/bids/frame.lua` (just like `tabs/auctions/frame.lua:128`) keeps each bid on its own row.
- **How sure:** Fact from the addon code (`tabs/bids/frame.lua`, `gui/auction_listing.lua`, `util/info.lua`) and `C_AuctionHouse.GetBidInfo` (`[Code]`, `docs/forever-auction-house.md`, section 8).

---

### 2. Bid-only auctions (`buyout_price == 0`) at different bid prices merge into one row, and string sorting can hide the cheaper bid

- **What:** `price_group` (`auxForever/gui/auction_listing.lua:788-789`) groups records by `record.buyout_price` without checking whether `record.buyout_price == 0`. Within a `price_group`, `UpdateRowInfo` sorts records by string comparison on `search_signature` (`a.search_signature < b.search_signature`, line 796).
- **Where:**
  - `auxForever/gui/auction_listing.lua:784-797` (`price_group` and `sort`)
  - `auxForever/util/info.lua:137` (`M.signatures`)
- **Why it matters to a player:** When two sellers list the same item with no buyout (`buyout_price = 0`) at different bid prices, such as Seller A at `2s` (`200` copper) and Seller B at `1g` (`10000` copper), both records have `buyout_price = 0` and the same `price_group`. `UpdateRowInfo` merges them into one row with `Auction Buyout: ---` and `For sale: 2`. Furthermore, because `search_signature` joins numbers with `':'` and `sort` compares strings (`"10000" < "200"` because `'1' < '2'`), Seller B's `1g` auction sorts ahead of Seller A's `2s` auction and becomes `child.record`. The row displays `Auction Bid: 1g`, and clicking `Bid` bids `1g` on Seller B's auction while Seller A's `2s` auction cannot be seen or bid on. Separating bid-only auctions by `record.bid_price` in `price_group` (or not merging when `record.buyout_price == 0`) prevents different bid-only prices from collapsing together.
- **How sure:** Fact from the addon code (`gui/auction_listing.lua:784-797`, `util/info.lua:137`).

---

### 3. Within a buyout `price_group`, string sorting on `search_signature` can pick a buyout-only auction ahead of an auction with a lower starting bid

- **What:** The comment in `auxForever/gui/auction_listing.lua:780-782` states: `"The row keeps one real auction behind it (the lowest starting bid)"`. However, `set_prices` (`auxForever/util/info.lua:204-205`) sets `record.bid_price = min_bid > 0 and min_bid or buyout` and `record.start_price = bid_amount > 0 and bid_amount or record.bid_price`, and `UpdateRowInfo` (`gui/auction_listing.lua:794-797`) sorts records within a `price_group` using string comparison on `a.search_signature < b.search_signature`.
- **Where:**
  - `auxForever/gui/auction_listing.lua:780-782, 794-797`
  - `auxForever/util/info.lua:137, 200-208` (`M.signatures` and `set_prices`)
  - `auxForever/gui/buy_bar.lua:291-294` (`can_bid_item`)
- **Why it matters to a player:** Suppose two sellers list the same gear ending at `12s` (`1200` copper) buyout: Seller A sets a `2s` (`200`) or `9s` (`900`) starting bid, while Seller B lists buyout-only (`min_bid = 0`, so `start_price = 1200` and `bid_price = 1200`). In `search_signature`, Seller B has `"1200:1200:1200"` while Seller A has `"200:1200:200"` or `"900:1200:900"`. Because `"1200" < "200"` and `"1200" < "900"` in ASCII order, Seller B's buyout-only auction sorts first and becomes `child.record`. The merged `12s` row then shows `Auction Bid: ---`, and `can_bid_item()` in `gui/buy_bar.lua:293` (`record.bid_price < record.buyout_price`) returns `false`, hiding the `Bid` button even though a biddable auction exists in that `12s` row. Sorting records within a `price_group` numerically by `a.bid_price ~= b.bid_price` (`a.bid_price < b.bid_price`), then `a.duration < b.duration`, makes the code match the comment on line 781.
- **How sure:** Fact from the addon code (`gui/auction_listing.lua`, `util/info.lua`, `gui/buy_bar.lua`).

---

### 4. Sniper tab does not set `listing.one_row_each = true`, so a `gone` deal and a live deal (or two versions of one gear ending) can merge or fold together

- **What:** `auxForever/tabs/sniper/frame.lua:162` creates the Sniper table with `auction_listing.new(frame.listing.list, 19, columns)` without `listing.one_row_each = true`. In `auxForever/tabs/sniper/core.lua:186-231`, `deals` stores one entry per `itemKey` version (`deal_key`, such as `4575:104` and `4575:106` for two versions of `Medicine Staff of the Wolf`), and keeps sold or missed deals in the list with `record.deal_gone = true` (`core.lua:152-160`).
- **Where:**
  - `auxForever/tabs/sniper/frame.lua:93-104, 162, 342-358`
  - `auxForever/tabs/sniper/core.lua:152-160, 186-231, 481-558`
  - `auxForever/gui/auction_listing.lua:784-825`
- **Why it matters to a player:**
  1. **A `gone` deal and a live deal at the same price merge into one row:** `price_group` (`gui/auction_listing.lua:788-789`) does not include `record.deal_gone`. If version `104` of a gear ending at `11s` is bought or goes `deal_gone = true` and version `106` of the same ending appears at `11s`, both have the same `price_group` (`"4575:of the wolf:1100:1:0:0:0"`). They merge into one row in the Sniper table while the header (`deals_count(shown)`, `sniper/frame.lua:342-352`) still says `"1 to buy, 1 gone"`. If the `gone` record sorts first into `child.record`, the merged row is dimmed as `gone` and clicking it shows `"Bought"` or `"Gone: sold or relisted"` (`sniper/core.lua:553-554`), hiding the live deal.
  2. **Two versions of one gear ending at different prices fold into a collapsed `+` group:** When `deals` has more than one item (`single_item == false`), `UpdateRowInfo` (`gui/auction_listing.lua:813`) folds a second version of the same `price_key` (say version `106` at `12s` under version `104` at `11s`) as a hidden child row, and Sniper's `For sale` column (`sniper/frame.lua:98`) reads `record.auction_count` of the top record rather than `childInfo.units`. Setting `listing.one_row_each = true` in `tabs/sniper/frame.lua` keeps every Sniper deal on its own visible row.
- **How sure:** Fact from the addon code (`tabs/sniper/frame.lua`, `tabs/sniper/core.lua`, `gui/auction_listing.lua`).

---

### 5. Buy bar reads `record.auction_count` instead of the merged row's `count`, showing `"2 for sale at this price"` or `"The last one at this price"` under a row of 56

- **What:** In `auxForever/gui/auction_listing.lua:812`, `UpdateRowInfo` sums the merged auctions into `child.count` (and `child.units` on line 845), while leaving `child.record.auction_count` as the first seller's bucket count so `sync_bucket` (`auxForever/tabs/search/results.lua:859-884`) knows when that single `auction_id` bucket is used up. However, `update_item` in `auxForever/gui/buy_bar.lua:299, 308` reads `record.auction_count or 1` for its status lines.
- **Where:**
  - `auxForever/gui/buy_bar.lua:299, 308` (`update_item`)
  - `auxForever/tabs/search/results.lua:897-925, 1006-1009` (`show_item` and `on_update`)
  - `auxForever/gui/auction_listing.lua:812, 845` (`child.count` and `child.units`)
- **Why it matters to a player:** When a player clicks a merged gear row on the Search tab, the table row and the buy bar right underneath it say different numbers. In Tyler's Merc Sword of Healing case (`56` for sale at `11s` across four sellers: `10`, `2`, `39`, `5`), `child.record` is Kadathi's bucket (`auction_count = 2`). The table row shows `For sale: 56`, while the buy bar immediately below it says `"2 for sale at this price"`. Whenever the first seller in the merged group has only 1 auction (`auction_count = 1`), the buy bar says `"1 for sale at this price"` and `"The last one at this price"` even when the row has dozens more at that price and the next one will stay selected after buying. Passing the selected row's merged count (`selection.count`) to `buy_bar.show_item` for display while keeping `record.auction_count` inside `sync_bucket` keeps both in sync.
- **How sure:** Fact from the addon code (`gui/buy_bar.lua`, `tabs/search/results.lua`, `gui/auction_listing.lua`).

---

### 6. Seller count (`group_sellers`) in `UpdateRowInfo` overcounts when the same seller has multiple buckets at one price

- **What:** In `auxForever/gui/auction_listing.lua:799-808`, `UpdateRowInfo` counts sellers in a `price_group` with:
  `if record.owner ~= child.record.owner or not record.owner then sellers = sellers + max(1, record.seller_count or 1); child.record.group_sellers = sellers end`.
  It compares each `record.owner` only against `child.record.owner` (the first record in the price group), not against all seller names already counted in that group.
- **Where:** `auxForever/gui/auction_listing.lua:799-808`
- **Why it matters to a player:** On Forever, the same seller can appear in multiple buckets at the same buyout price on one gear ending: either because they posted at two different durations (`Short` and `Long`), or because they posted two versions (`itemSuffix` 103 and 104) of the same ending (`[Seen]`, `docs/forever-auction-house.md`, section 9). If `child.record.owner` is `'Kadathi'` and `'Amelaina'` has two buckets at `11s`, `'Amelaina' ~= 'Kadathi'` is true for both of Amelaina's buckets, so `group_sellers` displays `"3 sellers"` in the Seller column and tooltip instead of `"2 sellers"`. Tracking seen seller names in a small table per `price_group` (and only adding 1 for a named seller the first time that name is seen in the group) fixes the count.
- **How sure:** Fact from the addon code (`gui/auction_listing.lua:799-808`) and Forever's per-version item search rows (`[Seen]` and `[Code]`, `docs/forever-auction-house.md`, section 9).

---

### 7. Search Results tab badge and bottom summary (`results_count` and `results_summary`) count unmerged `search.records` and group by `record.item_key` (`:0`)

- **What:** In `auxForever/tabs/search/results.lua:436-470`, `results_count(search)` and `results_summary(search)` iterate `search.records`, group items by `local key = record.item_key or record.item_id or record`, and when `item_count == 1` report `#search.records` as the number of price levels.
- **Where:** `auxForever/tabs/search/results.lua:436-470` (`M.results_count` and `M.results_summary`)
- **Why it matters to a player:**
  1. **Price level count does not match the merged table:** In a single-item gear search like `merc sword of healing/exact` where 8 seller/duration buckets collapse into 4 price rows (`11s, 12s, 18s, 30s`), the Search Results sub-tab badge says `Search Results (8)` and the bottom bar says `"8 price levels, 60 for sale"`, while the table right above it has 4 rows (`#search.table.rowInfo[1].children == 4`).
  2. **Multiple endings of one base gear item are counted as 1 item:** Because `new_record` sets `record.item_key = item_id .. ':0'` (`auxForever/util/info.lua:187`), a full search for `merc sword` that returns several different endings (`of Healing`, `of Agility`, `of the Tiger`) sees only one `record.item_key` (`'4570:0'`), so `item_count` is `1` and the summary says `"N price levels"` instead of `"M items"`. Using `record.price_key or record.item_key` and reading the merged row count from `search.table.rowInfo` when available makes the badge and summary match the table.
- **How sure:** Fact from the addon code (`tabs/search/results.lua:436-470`, `util/info.lua:187`, `gui/auction_listing.lua:775-825`).

---

### 8. Note on 0.8 build 8 (`46ecded`): `other_endings_lowest` from `skip_key` uses `result.minPrice`, which can be a starting bid or your own listing

- **What:** In `auxForever/tabs/post/core.lua:957-967`, `skip_key` skips item search requests for other endings of the selected gear item and records `local unit = result.minPrice or 0` into `other_endings_lowest`.
- **Where:** `auxForever/tabs/post/core.lua:957-967`
- **Why it matters to a player:** Skipping the other endings' item searches cut a Merc Sword Post scan from ~25 requests down to 1-2 requests (`[Seen]`, 2026-11-08), which is a huge improvement. One small detail in `BrowseResultInfo` (`[Code]`, `docs/forever-auction-house.md`, section 9; also noted in `auxForever/tabs/sniper/core.lua:14`): `result.minPrice` on a browse row is the lowest price on that version, which can be a low starting bid rather than a buyout, or a version where `result.containsOwnerItem` is true and `result.totalQuantity == 1` (only your own auction). Because `other_endings_lowest` is only used as a clearly labeled fallback when nobody sells your item's ending (`"None of this name for sale: the cheapest other ending"`), it is never worth spending extra search requests just to verify buyout vs bid on other endings. One zero-cost guard is available if wanted: ignore `result.minPrice` when `owned_row(result)` is true (or when `result.containsOwnerItem` is true and `#result.owners == 1`), so your own listing of another ending is not suggested back to you as `"the cheapest other ending"`.
- **How sure:** Fact from the addon code (`tabs/post/core.lua:957-967`) and `BrowseResultInfo` fields (`[Code]`, `docs/forever-auction-house.md`, section 2 and section 9).
