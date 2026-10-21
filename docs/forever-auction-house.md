# How the WoW Forever auction house works

Everything we know about the auction house auxForever runs on, with how we know it. First written
2026-10-04; rewritten 2026-10-11 (Tyler: "we need to confirm things like this", after a reply to a
player stated a mail delay that had never been checked). The rewrite reached `main` on 2026-10-20,
with the facts seen in game between 2026-10-11 and then added under their labels.

## The rule

Every fact below carries one label:

- **[Seen]**: seen in game on Forever by Tyler or a tester, with the date.
- **[Code]**: read in Blizzard's own interface code for Forever (build 70338, see Sources). This is
  how the game client is built to work. It does not prove what the server does (amounts, delays,
  limits come from the server).
- **[Outside]**: another addon, a guide site or a forum says so. Not checked by us.
- **[Unknown]**: nobody has checked; the experiment that would settle it is named (E1, E2, ...).

Nothing goes to a player, into a reply, or into a design decision as fact unless it is **[Seen]**.
A **[Code]** or **[Outside]** fact may be used with its label said out loud ("Blizzard's code shows
X; not yet seen in game"). When an experiment settles a fact, change its label here and record the
date and who saw it.

## Sources

1. Blizzard's interface code for Forever: branch `forever` of
   [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), client 1.60.1 build 70338
   (2026-10-10). Forever is Blizzard's project "Camelot" (`Blizzard_ProjectConstants/Camelot`) and
   loads the modern ("Mainline") auction house and mail code plus its own category list
   (`Blizzard_AuctionHouseUI/Camelot/Blizzard_AuctionData.lua`). Read: the generated API
   documentation (`AuctionHouseDocumentation.lua`, `AuctionHouseEnumsDocumentation.lua`,
   `MailInfoDocumentation.lua`), `Blizzard_AuctionHouseUI/Shared/*`, `Blizzard_MailFrame/MailFrame.lua`.
2. The game's English text for the same build: branch `forever` of
   [Ketho/BlizzardInterfaceResources](https://github.com/Ketho/BlizzardInterfaceResources)
   (`Resources/GlobalStrings/enUS.lua`, `LuaEnum.lua`, `Events.lua`).
3. Two Forever addons: [Arbitrage](https://github.com/derek-etherton/Arbitrage) (README says
   verified in game, last commit 2026-09-24) and
   [WOW4E_AH_Trader](https://github.com/1nd1v1d/WOW4E_AH_Trader) (last commit 2026-10-10; parts of its
   documentation still describe Classic 1.12 formulas).
4. Web search summaries (2026-10-11) of: AHledger ("The WoW Forever auction house: how it works"),
   warcraftforever.games ("The auction house in WoW: Forever"), Wowhead news "WoW: Forever AH
   Currently Bugged - Too Much Deposit Being Taken" (about 2026-09-29), Blizzard forum threads "Is AH
   cross faction?", "No mail after Auction sales", "AH, mail delay, chat delay and latency Issues
   10/4/2026". **The pages themselves could not be opened** from the research environment (blocked);
   only the search engine's summaries were read, so treat these as weak.
5. Our own observations: Tyler's in-game tests, recorded in `docs/status.md`,
   `docs/testing-history.md` and the test pages.

## 1. Which auction houses there are

- Each faction has its own auction house; the neutral auctioneers (Gadgetzan, Booty Bay,
  Everlook) are shared by both factions. **[Outside]** (AHledger summary; a forum thread got
  contradictory answers). Settled by **E2**.
- There are no realms in the usual sense: one house per ruleset and faction in each region (six in
  the US, six in Europe). **[Outside]** (AHledger summary). WOW4E_AH_Trader keeps its data per region
  and per "connected realms reported by the client". Not checked.
- aux keeps price history per realm name and faction (`docs/price-data.md`). If the faction houses
  are separate, that is right; prices from a neutral house are mixed into the faction's history
  today. **[Unknown]**, depends on E2.

## 2. Two kinds of goods

Every item is either an **item** (gear, bags, recipes) or a **commodity** (stackable goods).
`C_AuctionHouse.GetItemKeyInfo(itemKey).isCommodity` says which. **[Code]**; aux uses it in every
search and buy, which work in game **[Seen]**.

| | Items | Commodities |
|---|---|---|
| Search results | `GetItemSearchResultInfo(itemKey, i)` | `GetCommoditySearchResultInfo(itemID, i)` |
| One result row is | a bucket of identical auctions | a price tier |
| Price | `buyoutAmount`, `minBid`, `bidAmount`, per item | `unitPrice`, per unit |
| `quantity` | number of identical auctions in the bucket | units at that price |
| Buy | `PlaceBid(auctionID, buyoutAmount)` buys **one** | `StartCommoditiesPurchase`, then `ConfirmCommoditiesPurchase` |
| Bids | yes | no |

- Item rows are buckets priced per item: Linen Bag rows read quantity 941 at 3s (2026-10-04),
  which only makes sense per item, and buying a row buys one. **[Seen]**
- Which goods are commodities is decided by the game per item; aux asks at run time. **[Code]**
- Gear and other items are only ever listed in whole silver; trade goods show copper (88c, 89c).
  **[Seen]** (Tyler, 0.4). Blizzard's code rounds prices up to whole silver when
  `SupportsCopperValues()` is false (`AuctionHouseUtil.SanitizeAuctionHousePrice`). **[Code]**
  But `SupportsCopperValues()` prints **true** on Forever (Tyler, 2026-10-17, FB-017) **[Seen]**,
  so that rounding does not explain the whole silver.
- Blizzard's Sell tab shows gold, silver and copper boxes for gear (Merc Sword of Healing). Tyler
  typed 10s 50c there and clicked Create Auction; afterwards his auction list showed only the Merc
  Sword aux had posted at 11s, and two Merc Swords were still in his bags (2026-10-19, 0.7.1.1
  build 2, step 8, screenshots) **[Seen]**. Inference: the 10s 50c post did not go through; no
  error text was captured. Every gear listing Blizzard's window showed was whole silver. Until a
  refused post is seen with its error text, aux keeps gear in whole silver; a typed copper amount
  shows rounded down in the box after Enter.
- An item can also be marked as listed by another character on your account
  (`containsAccountItem`); Blizzard shows such rows as your own. **[Code]**

## 3. Durations and time left

- The sell screen offers three durations; the game's text for Forever reads "2 Hours", "8 Hours",
  "24 Hours" (`AUCTION_DURATION_ONE`..`THREE`). **[Code]** WOW4E_AH_Trader also says 2/8/24.
  AHledger's summary says 12/24/48. **[Outside]**, conflicting. The time-left bands in our search
  test topped out at 24 hours (2026-10-04) **[Seen]**, which fits 2/8/24. Tyler then used 2, 8
  and 24 hours in Blizzard's Sell window for one Ritual Bands of Spirit (2026-10-17, FB-017)
  **[Seen]**, which settles **E5**: 2/8/24. aux reads the labels from the game either way.
- Time left on other players' listings comes as a band (Short, Medium, Long, Very Long) whose
  limits the game reports (`GetTimeLeftBandInfo`); your own auctions and commodity tiers may carry
  exact seconds (`timeLeftSeconds`). **[Code]**
- Posting shows a warning when the house will "undergo major updates during the scheduled weekly
  maintenance": an auction still up then is returned early and loses its deposit
  (`CONFIRM_AUCTION_POSTING_TEXT`, `AUCTION_HOUSE_POST_WARNING`). **[Code]** Whether and when
  Forever shows it: **[Unknown]**.

## 4. Costs

- **Cut on a sale:** 5% on a faction house, 15% on a neutral house. **[Outside]** (AHledger and
  warcraftforever summaries; Tyler's earlier research said 5%). aux uses `AUCTION_CUT = .05`
  everywhere. Never checked against a real invoice. Settled by **E1** (faction) and **E2**
  (neutral).
- **Deposit:** the game computes it (`CalculateItemDeposit`, `CalculateCommodityDeposit`); aux shows
  what the game says. **[Code]** The deposit has a floor of 1 silver: 20 Linen Cloth (8 hours) and
  one Ritual Bands of Spirit (2 and 8 hours) each showed 1s in aux and in Blizzard's window, and
  posting took exactly 1s from the money each time; the same Ritual Bands at 24 hours showed
  1s 20c in Blizzard's window (Tyler, 2026-10-17, FB-017) **[Seen]**. aux matched the game in
  every case. Inference: below some amount the game charges 1s; the Classic formula alone would
  give a few copper for these. The 1c deposit once shown for Minor Mana Potion (0.4) was only
  aux's display, not what the game took.
- A bug took too much deposit (about 1 silver on many auctions) around 2026-09-29. **[Outside]**
  (Wowhead, Seramate summaries). Fixed or not: **[Unknown]**.
- **Deposit back on a sale:** the seller's invoice adds the deposit to the sale price and subtracts
  the cut (`bid + deposit - consignment` in `MailFrame.lua`). **[Code]** Settled by **E1**.
- **Cancelling:** you lose the deposit, and the game may charge more (`GetCancelCost`; the dialog
  reads "Canceling this auction will cost you your deposit and:"). **[Code]** How much on Forever:
  **[Unknown]**, **E3**. An auction cannot be cancelled while someone's purchase quote is pending
  (`ERR_AUCTION_ITEM_HAS_QUOTE`). **[Code]**
- **Expiry:** the deposit is lost when an auction expires. **[Outside]** (warcraftforever and
  AHledger summaries), also Classic's rule. **E4**.

## 5. Selling

- Items: `PostItem(location, duration, quantity, bid, buyout)`, prices per item; a quantity above 1
  makes that many separate auctions ("multisell"). Commodities: `PostCommodity(location, duration,
  quantity, unitPrice)`. **[Code]**; posting both works in aux **[Seen]**.
- A buyout must be above the starting bid; an equal bid gave "Internal auction error" (green wand,
  2026-10-04). **[Seen]** aux leaves the bid out then.
- Posting can need a confirmation (`AUCTION_HOUSE_POST_WARNING`/`ERROR`, then `ConfirmPostItem` or
  `ConfirmPostCommodity` from a click). **[Code]**
- What cannot be sold, from the game's error list: soulbound and quest items, conjured items, items
  with a limited duration, damaged items (repair first), items with used charges, lootable or
  wrapped items, non-empty or equipped bags. **[Code]** (`AuctionHouseError`, `ERR_AUCTION_*`).
  `IsSellItemValid` checks an item; aux's Post tab uses it with the auction house open. **[Code]**
- **Which listing sells first at the same price.** aux's Post tab matches the lowest price by
  default because "on Forever the newest listing at a price sells first" (commit 755e16e,
  2026-10-04). **No source was recorded for that claim.** Retail players describe the same
  (last in, first out) **[Outside]**; one guide says otherwise. On Forever: **[Unknown]**, **E6**.
  This matters: if it is false, matching the price is the wrong default.
- Blizzard fills in a suggested price only when `ShouldAutoPopulatePrice()` is true; the fallback is
  1.5 times the vendor price. **[Code]**

## 6. Buying

- Commodities: `StartCommoditiesPurchase(itemID, quantity)` asks for a quote
  (`COMMODITY_PRICE_UPDATED` or `COMMODITY_PRICE_UNAVAILABLE`); `ConfirmCommoditiesPurchase`
  completes it (`COMMODITY_PURCHASE_SUCCEEDED` or `_FAILED`). The quote expires
  (`GetQuoteDurationRemaining`). Units are taken cheapest first and your own units are skipped
  (`quantity - numOwnerItems`). **[Code]** aux's buy bar (Buy, then Confirm) works **[Seen]**.
- A purchase on a quote that went stale ended with "Internal auction error" (0.4.1 tests, Sniper
  trade goods 4 of 5 times on deals found minutes earlier). **[Seen]**
- Whether the confirm step may run without a click: **[Unknown]**. aux always asks for the click,
  so this does not matter today.
- After buying, the item arrives by mail; the game reports a delivery delay for purchased and for
  cancelled items (`AUCTION_HOUSE_ITEM_DELIVERY_DELAY_UPDATE`). **[Code]** The delays:
  **[Unknown]**.

## 7. After a sale

What the game is built to do **[Code]**:

1. A chat line: "A buyer has been found for your auction of X." (`ERR_AUCTION_SOLD_S`).
2. The auction stays in your auction list marked Sold, grayed, with "Delivered in: <time>" and the
   buyer's name in its tooltip (`AuctionStatus.Sold`, `AUCTION_HOUSE_TIME_LEFT_FORMAT_SOLD`). aux's
   Auctions tab shows such an auction as "Sold, money in the mail" (not recorded as seen).
3. A mail "Sale Pending: X" (`seller_temp_invoice`): item, buyer, "Amount Pending", "Estimated
   delivery time <clock time>".
4. Later a mail "Auction successful: X" (`seller` invoice) with the gold: sale price, deposit back,
   auction house cut, amount received.

What we do not know: how long step 3 to 4 takes on Forever. About an hour **[Outside]** (AHledger
summary). A forum thread "No mail after Auction sales" exists; its content was not read. **[Unknown]**,
**E1**. Do not tell players a delay until E1 is done.

Other mails **[Code]**: "Auction expired: X" (item back), "Auction canceled: X", "Outbid on X",
"Auction won: X". A won commodity also prints "You won an auction for X (xN)".

## 8. Bids

- Only items can have bids; commodities cannot. **[Code]** Every Auction Bid column in Tyler's 0.6
  screenshots read "---". **[Seen]**
- `QueryBids(sorts, auctionIDs)` needs the list of auction IDs you bid on; Blizzard keeps that list
  itself. **[Code]** aux's Bids tab: not fully tested in game.

## 9. Searching, scanning and limits

- Browse first (`SendBrowseQuery`): one row per item, with its lowest price and total quantity.
  Then one search per item (`SendSearchQuery`), at most 100 per minute (Blizzard's documentation).
  **[Code]**
- Measured: the whole house's item list, 7,718 items in 8.5 seconds over 16 requests
  (2026-10-04); item searches about one every 0.4 seconds because of the game's request limit
  (`IsThrottledMessageSystemReady`), 335 items in 3m 13s (0.4). **[Seen]**
- Full scan (`ReplicateItems`) works: whole house in one go, one row per auction, buyout for the
  whole stack. **[Seen]** (0.5, prices per unit matched the lowest listing).
- Full scan allowed once every 15 minutes per account. **[Outside]** (retail's rule, used by
  Auctionator and Arbitrage). aux waits 15 minutes itself, so the real limit on Forever has never
  been tried. **[Unknown]**; low priority.
- The categories (Weapons, One-Handed, Daggers, ...) as the game printed them on 2026-10-11 **[Seen]**:
  `tests/forever_categories.lua`.
- How many auctions one character may have up: **[Unknown]**; no experiment planned.
- **Gear versions.** Gear item keys carry an item level and a large suffix number, and one item
  name can have several. Ritual Belt of Arcane Protection (item 14131, item level 19) was listed
  under suffixes 14320 (5 listed), 14321, 14322 and 14323 (all "of Arcane Protection" in aux's
  results, all 6s), and Ritual Belt of the Sorcerer and of Magic under 14325 and 14314 (Tyler,
  2026-10-17, 0.7.1 build 3) **[Seen]**. Inference: the suffix number stands for the ending
  together with its stat values, so two belts with the same name can be different versions. A
  search by item key (`SendSearchQuery`) returns only that exact version; Blizzard's Sell window
  clears item level and suffix for gear and asks with `SendSellSearchQuery`, so it lists every
  version together (`AuctionHouseUtil.ConvertItemSellItemKey`). **[Code]**
- **A gear link's ending is not in the suffix field.** Medicine Staff of the Wolf, hovered in aux's
  results, printed `item:4575::::::::24:1487::1:1:12726:1:28:5254::::` (Tyler, 2026-10-20) **[Seen]**:
  the suffix field (the 8th number, after the four gem fields) is empty and 24 sits where the link
  level goes. Inference: the ending is carried further on, most likely the 12726. aux reads the
  ending from the suffix field (`info.parse_link`), so every ending of an item looks the same to it:
  the Bandit, Arcane Protection and Wolf staffs showed one price (2026-10-20). Searches record
  under `itemKey.itemSuffix` instead, so the same item can have its prices under two keys. To fix
  with gear versions (0.8).

## 10. Your auctions

- `QueryOwnedAuctions`, then `GetOwnedAuctions`: auction ID, item, quantity, buyout, bid, status
  (active or sold), time left. **[Code]**; aux's Auctions tab works **[Seen]**.
- `CancelAuction(auctionID)` from a click; Blizzard asks first and shows the cost. **[Code]** aux's
  cancel works **[Seen]** (0.4.1 build 5).
- `GetOwnedAuctionInfo` gives no `itemLink` for trade goods (Peacebloom, Scroll of Stamina printed
  nil); gear has one (2026-10-17, 0.7.1 build 3) **[Seen]**. aux reads them by item ID.

## Experiments (not scheduled)

Tyler, 2026-10-11: no dedicated test sessions; "we will learn it over time". These are what would
settle each Unknown. When one comes up in normal play (a sale, a cancel, a trip to Booty Bay) or a
screenshot happens to show it, record it here as Seen with the date. Gold costs are fine. The test
page once carried them as build id `ah-facts-1`.

- **E1 Sale timeline.** Post something cheap that sells fast on your faction house. Note the time
  of the "A buyer has been found" line; screenshot Blizzard's Auctions tab (Blizzard UI button) for
  "Delivered in"; open the mailbox for the "Sale Pending" mail; note when the "Auction successful"
  mail arrives and screenshot it. Settles: the delay, the 5% cut, the deposit coming back.
- **E2 Neutral house.** At a neutral auctioneer (Booty Bay, Gadgetzan or Everlook): search an item
  you also see at your faction's house and compare; sell something cheap there and screenshot the
  "Auction successful" mail. Settles: shared or separate listings, the 15% cut.
- **E3 Cancel.** Post something cheap, note the deposit, cancel it from Blizzard's Auctions tab and
  screenshot the dialog; note your gold before and after and when the item comes back by mail.
- **E4 Expiry.** Post something cheap at a high price for the shortest duration; after it expires,
  check the mail and whether the deposit came back.
- **E5 Durations.** Settled 2026-10-17: 2, 8 and 24 hours (section 3).
- **E6 Same price, who sells first.** Needs a second account or a friend: post one unit of a trade
  good at exactly the lowest price, where someone else already has units at that price; the other
  account buys one unit. Whose unit sold? Optional.
- **E7 A replaced search.** Does Forever still answer a search after a newer one replaced it? aux
  takes the next item list that arrives as the answer to its latest question, so a late answer to
  an older search would be read as the new one's (found 2026-10-20 with the slow test auction house,
  which assumes it does; the real game may drop it) **[Unknown]**. To try: search something with
  many items (for example `cloth`), and the moment it starts, search `copper ore/exact`. If the
  results show cloth items or nothing where Copper Ore is listed, the game answers replaced searches
  and aux needs a fix.
