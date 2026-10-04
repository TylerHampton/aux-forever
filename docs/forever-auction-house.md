# How the WoW Forever auction house works

Research notes for porting aux. Written 2026-10-04.

Confidence labels:
- **Confirmed**: read directly in Blizzard's own Forever UI code, or seen in game.
- **Likely**: supported by Blizzard's code plus another addon, not yet seen in game by us.
- **Unverified**: reported by one source, or conflicting sources.

## Sources

1. Blizzard's interface code for the Forever client, `forever` branch of
   [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source) (client 1.60.1, build 70205,
   updated 2026-10-03). Mainly `Blizzard_AuctionHouseUI` and the generated API documentation.
2. [Arbitrage](https://github.com/derek-etherton/Arbitrage), a Forever-only auction addon whose
   README says it works end to end and was verified in game (last commit 2026-09-24).
3. [WOW4E_AH_Trader](https://github.com/1nd1v1d/WOW4E_AH_Trader), a Forever auction addon in
   active development (last commit 2026-10-04). Its own notes say its in-game checks are not done.
4. [wow-artisan](https://github.com/edloidas/wow-artisan) README, a Forever crafting tool.
5. Our own test: an aux search for "bag" on 2026-10-04.

Auctionator's source and the Forever guide sites (ahledger.com, warcraftforever.games) could not
be read from the research environment.

## 1. Two kinds of goods

Every item is either an **item** or a **commodity**. `C_AuctionHouse.GetItemKeyInfo(itemKey).isCommodity`
says which. (Confirmed)

| | Items (gear, bags, recipes, ...) | Commodities (stackable trade goods, ...) |
|---|---|---|
| Search results | `GetItemSearchResultInfo(itemKey, i)` | `GetCommoditySearchResultInfo(itemID, i)` |
| One result row is | a bucket of identical auctions | a price tier |
| Price field | `buyoutAmount`, `minBid`, `bidAmount`: **per item** | `unitPrice`: per unit |
| `quantity` | how many identical auctions are in the bucket | how many units at that price |
| Buy | `PlaceBid(auctionID, buyoutAmount)` buys **one** | `StartCommoditiesPurchase(itemID, n)` then `ConfirmCommoditiesPurchase(itemID, n)` |
| Bids | yes | no |

Which stackable goods are commodities on Forever is not documented anywhere we could read.
aux must ask the game per item at run time, which it already does. (Confirmed that the check
exists; which items are which: Unverified)

## 2. Item rows are buckets, priced per item

**Likely.** Evidence:

- Blizzard's item list counts "total quantity of items, instead of lines of results"
  (`GetItemSearchResultsQuantity`), so one line can hold many items.
- Each row has `owners` (a list of sellers) and `totalNumberOfOwners`. Blizzard shows
  "N sellers" when there is more than one. The player's own entry is the string `"player"`.
- After a purchase, `ITEM_SEARCH_RESULTS_UPDATED(itemKey, auctionID)` hands Blizzard's list a
  new auction ID for the row, so the row moves on to the next auction in the bucket.
- Blizzard's sell screen copies a result's `buyoutAmount` straight into its price box, which is
  labelled "per item".
- Blizzard's buy button calls `PlaceBid(row.auctionID, row.buyoutAmount)`. Arbitrage does the
  same and treats it as buying one item.
- Our test showed Linen Bag rows with quantity 941 and price 3s. 941 bags for 3s in total is
  impossible; 3s each fits.

WOW4E_AH_Trader divides `buyoutAmount` by `quantity`, the opposite reading. Its own notes say
that has not been checked in game, and it contradicts all the points above.

## 3. Buying commodities

**Confirmed** from Blizzard's code:

1. `StartCommoditiesPurchase(itemID, quantity)` asks the server for a quote. It must be called
   from a click.
2. The server answers with `COMMODITY_PRICE_UPDATED(unitPrice, totalPrice)` or
   `COMMODITY_PRICE_UNAVAILABLE`.
3. `ConfirmCommoditiesPurchase(itemID, quantity)` completes it, then `COMMODITY_PURCHASE_SUCCEEDED`
   or `COMMODITY_PURCHASE_FAILED`.
4. A quote expires (`GetQuoteDurationRemaining`). `CancelCommoditiesPurchase` drops it.

The purchase always takes the cheapest units first and skips the player's own units. Blizzard
works out what is available in a tier as `quantity - numOwnerItems`. When you click a tier in
Blizzard's window, it buys everything at that price or cheaper.

Can step 3 be called automatically when the quote arrives? The API documentation does not mark
it as needing a click, and Arbitrage confirms automatically. WOW4E_AH_Trader says Forever needs a
visible confirmation, but gives no evidence. **Unverified**; needs an in-game test.

## 4. Selling

**Confirmed** from Blizzard's code:

- Items: `PostItem(location, duration, quantity, bid, buyout)`. Prices are per item. Posting a
  quantity above 1 creates that many separate auctions ("multisell", with
  `AUCTION_MULTISELL_START/UPDATE/FAILURE`). Bid is optional and off by default.
- Commodities: `PostCommodity(location, duration, quantity, unitPrice)`.
- Either can return "needs confirmation". The server then sends `AUCTION_HOUSE_POST_WARNING`
  or `AUCTION_HOUSE_POST_ERROR`, and `ConfirmPostItem`/`ConfirmPostCommodity` completes it from a click.
- `GetAvailablePostCount(location)` gives the most you can post. `IsSellItemValid` says whether
  an item can be sold at all.
- Deposits come from `CalculateItemDeposit` / `CalculateCommodityDeposit`.
- Unless `SupportsCopperValues()` is true, prices must be whole silver.
- **Observed in game (Tyler):** on Forever, gear and other non-commodity items are only ever
  listed at whole silver amounts, while trade goods show copper prices (88c, 89c). auxForever
  therefore prices items in whole silver and undercuts them by 1 silver; trade goods use copper
  when `SupportsCopperValues()` allows it. Not confirmed from Blizzard's code.

Durations: three options, durations 1-3 in the API. Auctionator's Forever build, WOW4E_AH_Trader
and wow-artisan say 2, 8 and 24 hours; one guide site says 12, 24 and 48. The time-left bands in
our test topped out at 24 hours, which fits 2/8/24. aux reads the labels from the game, so
either works. (Likely 2/8/24)

## 5. Searching and throttling

- Browse first (`SendBrowseQuery`): one row per item key, with `minPrice` and `totalQuantity`.
  Arbitrage warns `minPrice` can be a bid, not a buyout. (Confirmed)
- Then one search per item key (`SendSearchQuery`). The documentation says these are limited to
  100 per minute. Only one item search runs at a time. (Confirmed)
- Results arrive in pages: `HasFull...Results` / `RequestMore...Results`. (Confirmed)
- Before sending, wait for `IsThrottledMessageSystemReady()`. A request can be dropped
  (`AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED`) and then needs to be sent again. (Confirmed)
- Arbitrage reports that the game does not always fire the "results updated" event again for
  results it already has cached, and checks the cached results as a fallback. (Likely)
- Full scan: `ReplicateItems()`, once every 15 minutes per account. Its data uses the old Classic
  layout: one row per auction, with the buyout for the whole stack. Arbitrage reads it that way.
  Whether it works fully on Forever is **Unverified**: one search summary mentioned a full scan
  coming back empty after a long wait on the beta, and we could not trace that claim to a source.

## 6. Your own auctions and bids

- `QueryOwnedAuctions` then `GetOwnedAuctionInfo(i)`: auction ID, quantity, `buyoutAmount`,
  `bidAmount`, status (active or sold), time left. Blizzard shows "x N" next to the item when
  quantity is above 1. Prices are most likely per unit like everywhere else. (Likely)
- `CancelAuction(auctionID)` from a click. It can cost money (`GetCancelCost`). (Confirmed)
- `QueryBids(sorts, auctionIDs)` then `GetBidInfo(i)`. Blizzard keeps its own list of auction IDs
  you bid on and passes it in. (Confirmed)

## 7. What this means for aux

1. **Item rows**: show one aux auction per item, priced per item, with the bucket size in the
   "Auctions" column. That matches how Classic aux showed many single auctions, and clicking
   Buyout buys one, just like Classic. After each purchase, update the row's auction ID and count.
2. **Commodity rows**: available quantity is `quantity - numOwnerItems`.
3. **Search engine**: fall back to cached results when no event arrives, and send dropped
   requests again.
4. **Price history**: comes out right once item prices are per item.
5. **Own auctions**: treat prices as per unit.
6. **To test in game**: confirming a commodity purchase automatically; full scan on Forever;
   which trade goods are commodities.
