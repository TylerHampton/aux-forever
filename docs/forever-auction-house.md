# How the WoW Forever auction house works

Everything we know about the auction house auxForever runs on, with how we know it. First written
2026-10-04; rewritten 2026-10-11 (Tyler: "we need to confirm things like this", after a reply to a
player stated a mail delay that had never been checked).

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
- An item can also be marked as listed by another character on your account
  (`containsAccountItem`); Blizzard shows such rows as your own. **[Code]**

## 3. Durations and time left

- The sell screen offers three durations; the game's text for Forever reads "2 Hours", "8 Hours",
  "24 Hours" (`AUCTION_DURATION_ONE`..`THREE`). **[Code]** WOW4E_AH_Trader also says 2/8/24.
  AHledger's summary says 12/24/48. **[Outside]**, conflicting. The time-left bands in our search
  test topped out at 24 hours (2026-10-04) **[Seen]**, which fits 2/8/24. Settled by **E5**.
  aux reads the labels from the game, so either works.
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
  what the game says. **[Code]** Small deposits of 1c were seen (Minor Mana Potion, 0.4) **[Seen]**,
  so a flat 1 silver minimum is not true for that item.
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

## 10. Your auctions

- `QueryOwnedAuctions`, then `GetOwnedAuctions`: auction ID, item, quantity, buyout, bid, status
  (active or sold), time left. **[Code]**; aux's Auctions tab works **[Seen]**.
- `CancelAuction(auctionID)` from a click; Blizzard asks first and shows the cost. **[Code]** aux's
  cancel works **[Seen]** (0.4.1 build 5).

## Experiments (to be done in game; page: the test page, build id `ah-facts-1`)

Gold costs are fine (Tyler, 2026-10-11). Each experiment checks one thing.

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
- **E5 Durations.** Screenshot the duration choices in Blizzard's own Sell tab.
- **E6 Same price, who sells first.** Needs a second account or a friend: post one unit of a trade
  good at exactly the lowest price, where someone else already has units at that price; the other
  account buys one unit. Whose unit sold? Optional.
