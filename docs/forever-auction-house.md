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

6. Checked again on 2026-11-10 against build 70888 of source 1 (and build 70532 of source 2, the
   lists of global functions, frames and text): every `C_` function, event and `Enum` member
   auxForever uses is in Blizzard's generated documentation for Forever, with the values the tests
   now use (`tests/forever_api.lua`); so is the timing function `debugprofilestop`. **[Code]**

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
  error text was captured. Every gear listing Blizzard's window showed was whole silver. aux kept
  gear in whole silver until 0.8.2.1 build 6; since build 7 it posts the copper price typed (below,
  FB-044).
- Two players report that Blizzard's window now posts copper prices on items that are not trade
  goods: sarrathsilentstrider posted "a level 3 white axe on the AH for 1s 89c" through "the default
  Blizz AH ... w/o issue" ("we can sell items by the copper now"), and user_mezgz2zh1g3sbu1v names
  Small Red Pouch (CurseForge comments, 2026-11-13 to 2026-11-16, FB-044) **[Outside]**. This
  contradicts Tyler's 10s 50c test of 2026-10-19 above; sarrathsilentstrider's "now" suggests a
  change on Blizzard's side since. Seen by Tyler on 2026-11-16 (0.8.2.1 build 7, step 8): aux
  posted Rough Bronze Leggings at 5s 69c and the Auctions tab listed it at 5s 69c; other players'
  gear listings at 5s 67c, 5s 71c **[Seen]**. Gear takes copper prices on Forever now.
- Blizzard's Sell window treats gear and trade goods alike: it shows the copper box whenever
  `SupportsCopperValues()` is true and does not round a typed gear price to silver (only its
  default price is silver-aligned) (`Blizzard_AuctionHouseSellFrame.lua`,
  `Blizzard_AuctionHouseSharedTemplates.lua`, branch `forever`, build 70938) **[Code]**. Its
  auction house code has not changed since build 70425 (2026-10-16), so any change since Tyler's
  2026-10-19 test would be on the server. No Blizzard note found that mentions copper prices on
  gear (searched 2026-11-16).
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
- The 1 silver floor dropped to 1 copper: announced for the weekly maintenance of 2026-11-17
  (North America) and 2026-11-18 (Europe) **[Outside]**
  ([Massively OP](https://massivelyop.com/2026/11/11/wow-forever-reduces-auction-house-listing-costs-and-adds-more-gold-to-high-level-quests/),
  [Icy Veins](https://www.icy-veins.com/wow-forever/news/the-auction-house-is-still-unusable-at-low-levels-deposit-cost-change-delayed/)).
  Confirmed in game (Tyler, 2026-11-20) **[Seen]**: 10 Rough Sharpening Stones (2 hours) showed 1c
  deposit in Blizzard's window and took 1c; Scroll: CHAP BALK WELLES showed 1c at 2 hours (in both
  aux and Blizzard's window) and 3c at 8 hours. aux shows the game's own number, so nothing in aux
  depends on the floor.
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
  (`quantity - numOwnerItems`). **[Code]** aux's buy bar (Buy, then Confirm) works **[Seen]**
  (until 0.8.2.1 build 6; since build 7 one click, below).
- Blizzard's own buy window accepts a server price up to 5% above the price it showed, and shows
  the increase (`MAXIMUM_PREVIEW_PRICE_DIFFERENTIAL = 1.05` in
  `Blizzard_AuctionHouseBuyDialog.lua`, build 70888). **[Code]** aux is stricter: it confirms only a
  server price at or below what it showed.
- A purchase on a quote that went stale ended with "Internal auction error" (0.4.1 tests, Sniper
  trade goods 4 of 5 times on deals found minutes earlier). **[Seen]**
- Whether the confirm step may run without a click: `StartCommoditiesPurchase` and `PlaceBid` are
  marked `HasRestrictions` in Blizzard's generated documentation and `ConfirmCommoditiesPurchase`
  is not (`AuctionHouseDocumentation.lua`, branch `forever`, build 70938) **[Code]**; the wiki says
  the start needs a hardware event (a click or key) and lists no restriction on the confirm
  ([warcraft.wiki.gg](https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.StartCommoditiesPurchase))
  **[Outside]**. Since 0.8.2.1 build 7 aux confirms by itself when the price arrives at or below
  the one shown, so Buy is one click (Tyler, 2026-11-16). Seen 2026-11-16 (build 7, step 7):
  one click on "Buy 1 for 19c" bought 1 Linen Cloth for 18c **[Seen]**.
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
- The game has an event made for addons that says results have arrived:
  `AUCTION_HOUSE_NEW_RESULTS_RECEIVED`, with the item key of a search, or nothing for an item list
  ("This signal is not used in the base UI but is included for AddOn ease-of-use", Blizzard's
  documentation, build 70888). Blizzard's own trade goods list also treats
  `COMMODITY_SEARCH_RESULTS_RECEIVED` as "results loaded", next to the updated event. **[Code]**
  On Forever the event came for every answer of two Full searches for `linen` (37 of 37 each,
  2026-11-11, `/aux debug`). **[Seen]** Whether it also comes when the results did not change
  since the last request: **[Unknown]**. aux waits for the updated events and, after 1 second without one, takes results
  the game already holds (`request` in `core/scan.lua`), which cannot tell an unchanged answer
  from no answer yet. Since 0.8.2.1 `/aux debug` counts the event ("The game announced N of M
  answers itself, J of the K taken after the 1s fallback"). In Tyler's test no answer needed the
  fallback (K was 0), so nothing was changed (outside review, R-05, closed).
- Where a Full search's time goes: `linen`, 36 items, 24.0 s in all: 17.8 s waiting for the game's
  request limit, 6.0 s for the server's answers, 0.2 s for the item list (2026-11-11). **[Seen]**
- Measured again after launch (Tyler, 2026-11-17, `/aux debug list`): 25,706 items in 37.7 seconds
  over 52 requests, about 0.73 s per request. **[Seen]** The same evening a Sniper round asked
  without gray items got 25,187 items, so grays were 519 (about 2%) **[Seen]**; that round took
  153.8 s in all, most of it opening possible deals. Narrowing Sniper to **Trade Goods** (Tyler,
  2026-11-22, 0.9 build 4) returned **491 items in 0.1 s to 0.2 s** (1 request per round)
  **[Seen]**.
- Whether `C_AuctionHouse.GetItemKeySampleLink(key)` returns a non-nil sample link during browse on
  Forever remains **[Unknown]**: the Build 4 Step 5 chat screenshot was downscaled too far to read
  `true` vs `false` reliably (though Step 4 confirmed Fast search `armor/miscellaneous/finger/spell`
  now finds `"of the Channeler"` and `"of the Prophet"` rings with `Equip:` spell stats **[Seen]**,
  via either sample links or the `needs_suffix_tooltip` fallback).
- Measured: the whole house's item list, 7,718 items in 8.5 seconds over 16 requests
  (2026-10-04); item searches about one every 0.4 seconds because of the game's request limit
  (`IsThrottledMessageSystemReady`), 335 items in 3m 13s (0.4). **[Seen]**
- A stuck request can freeze `C_AuctionHouse.IsThrottledMessageSystemReady()` at `false` until a
  full game restart (Tyler, 2026-11-20) **[Seen]**: trying to post or open listings for
  Scroll: CHAP BALK WELLES froze both aux (`Reading the listings...`) and Blizzard's own Post
  Auctions window (`Searching...`, Create Auction grayed out), with `IsThrottledMessageSystemReady()`
  returning `false`; a full game restart cleared it and normal items (Rough Sharpening Stone)
  posted cleanly.
- Full scan (`ReplicateItems`) works: whole house in one go, one row per auction, buyout for the
  whole stack. **[Seen]** (0.5, prices per unit matched the lowest listing).
- Full scan time since launch: one player saw more than 5 minutes before the list arrived
  (user_ayzkr6rhvrlna3ya, FB-027, 2026-11-06). **[Outside]** (a player's report, not seen by us).
  aux gave up after 2 minutes until 0.8.2, which waits up to 10 and prints how long the answer and
  the list took at the end of each Full scan. Tyler's line of 2026-11-11 (0.8.2.1 build 4):
  220,508 auctions in 48.5 s, of which the auction house took 30.3 s to answer, 2.0 s to send the
  list, and aux 16.2 s to read it. **[Seen]** Most of a Full scan is the wait for the server.
- Full scan allowed once every 15 minutes per account. **[Outside]** (retail's rule, used by
  Auctionator and Arbitrage). aux waits 15 minutes itself, so the real limit on Forever has never
  been tried. **[Unknown]**; low priority. A contributor report (Dragoy, PR #37, 2026-11-07) saw a
  second `ReplicateItems` call a few minutes after another addon's get no answer within 2 minutes,
  suggesting other addons' Full scans share the server's limit **[Outside]** (exact length still
  **[Unknown]**).
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
  under `itemKey.itemSuffix` instead, so the same item can have its prices under two keys. Fixed in
  0.8 build 3: prices are kept per name (`info.price_key`).
- **Versions of one name have the same stats.** Two Medicine Staffs of Arcane Protection listed at
  the same time (1g 15s and 1g 50s) both showed +4 Stamina and +4 Arcane Resistance (Tyler,
  2026-10-20) **[Seen]**, one case. So aux groups gear by its full name, as Blizzard's Sell window
  does, not by the auction house's version number.

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
  and aux needs a fix. Also in the Post tab (found 2026-10-20 with the slow test auction house):
  after a post, aux picks the next item and reads it; picking another item before that answer came
  back read the late, empty answer as the new item's and said "None for sale". Same test in game:
  post an item, and right away pick a different one in the bag list.
- **E8 Copper prices on gear (FB-044).** Settled 2026-11-16: gear takes copper prices (section 2).
- **E9 `SendSellSearchQuery` for gear (2026-11-21, [Code] / partial [Seen]).** Blizzard's Sell
  window zeroes `itemLevel` and `itemSuffix` on a gear item key and calls
  `C_AuctionHouse.SendSellSearchQuery` (`Blizzard_AuctionHouseUtil.lua`,
  `Blizzard_AuctionHouseItemSellFrame.lua`, passing `separateOwnerItems = false`), returning all
  versions of that item ID in 1 request (read via `GetNumItemSearchResults` /
  `GetItemSearchResultInfo`). On 2026-11-21 (0.9 build 2), running idle on item 4567 printed
  `E9 send: 4567 true` and `E9: 4567 0 true nil nil` (`HasSearchResults == true`, server answered
  with 0 results for item 4567). Whether it returns suffixed variants when listed remains
  **[Unknown]** until tested on a gear item ID that currently has suffixed auctions listed.
- **E10 `SearchForItemKeys` batch browse (2026-11-21, [Code]).** `C_AuctionHouse.SearchForItemKeys(itemKeys, sorts)`
  is documented on Forever (`AuctionHouseDocumentation.lua`). Both the 2026-11-21 (build 2) and
  2026-11-22 (build 4) probes printed `E10 send: false` and `E10: 0 false nil nil nil` (the build 4
  screenshot was initially misread as `true` due to chat image downscaling; corrected 2026-11-22
  after Tyler caught it). Because the throttle was not ready when Line 1 ran, `SearchForItemKeys`
  remains **[Unknown]** until tested with `IsThrottledMessageSystemReady() == true`. If it works,
  it enables Point Blank Sniper-style 100-key single-request Watch List sniping
  (`docs/sniper-research-pointblanksniper.md`).
- **E11 Browse price sort order & mid-browse `SendSearchQuery` (2026-11-23, [Unknown]; from
  `docs/sniper-research-pointblanksniper.md`).**
  - **E11a (Price-Cap Early-Stop):** Confirm that `SendBrowseQuery` sorted by
    `Enum.AuctionHouseSortOrder.Price` ascending actually delivers browse pages in ascending
    `minPrice` order on Forever (so the Sniper can stop calling `RequestMoreBrowseResults()` once a
    page's last `minPrice` passes a player-chosen max price cap).
  - **E11b (Streaming browse + live check):** Confirm whether calling `SendSearchQuery` for one item
    while `HasFullBrowseResults() == false` leaves the browse cursor intact for subsequent
    `RequestMoreBrowseResults()` calls or resets it.
- **Note on Blizzard's invisible `AuctionHouseFrame:OnShow` ([Code], 2026-11-21):** when a player
  has Blizzard AH favorites, opening the AH triggers `C_AuctionHouse.SearchForFavorites(sorts)`
  (`Blizzard_AuctionHouseFrame.lua:398-400`), using a throttle slot and firing
  `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` right at `AUCTION_HOUSE_SHOW`. Keep in mind for Auto Full
  Scan (FB-032) and initial searches.
- Experiments E12 to E15 below are the Upgrades tab's (branch `search-upgrade-support`). E13 to E15
  were E9 to E11 on that branch until 0.9 used those numbers for other experiments; renamed when 0.9.1
  was merged into it (2026-11-23).
- **E12 Item stats (Upgrades tab, `docs/upgrades.md`).** Results 2026-11-16 (Ben):
  - A hovered item's link with `C_Item.GetItemStats` (or `GetItemStats`) prints its stats **[Seen]**.
  - `C_TooltipInfo.GetItemKey` is blocked: run from chat, the game showed "*** ForceTaint_Strong ***
    has been blocked from an action only available to the Blizzard UI" **[Seen]**. Addon code is
    tainted the same way, so aux must not call it (it would show the same popup, with aux's name).
  - The link of a row's icon in aux's results (a tooltip set with `SetItemKey`, then
    `GameTooltip:GetItem()`) gives stats with `GetItemStats` too (Ben, 2026-11-16) **[Seen]**.
  - But that link has no ending: on the Upgrades tab every version of Birchwood Maul (of Defense,
    of Fire Protection, of the Owl, of Healing, ...) and of Spiked Club scored exactly the same,
    "+2.8 DPS, -1 Strength" against the worn weapon (Ben, 2026-11-17, screenshot) **[Seen]**. So a
    key's stats from `SetItemKey` are the plain item's. Whether the tooltip itself shows the
    ending's stat lines **[Unknown]**. A real auction's link (an item search result's `itemLink`)
    carries the ending (see "A gear link's ending" above, **[Seen]**); that its `GetItemStats`
    includes the ending's stats is **[Inference]** from E14's Brutal War Axe of the Sorcerer, to be
    confirmed by `TESTING.md` step 22.
- **E13 Talents.** Result 2026-11-16 (Ben): the command printed "Shaman SHAMAN 7" and no talent tree
  lines, so `GetNumTalentTabs` gave 0 or is missing on Forever **[Seen]**. Whether another function
  (`GetSpecialization`) answers **[Unknown]**; the Upgrades tab can do without it (the player picks
  the spec once, saved per character).
- **E14 Stat names.** Result 2026-11-16 (Ben), first part: the stat names the game knows, the
  global strings `ITEM_MOD_*_SHORT`, printed in game **[Seen]**. Forever's client has the modern
  list, Retail's stats included (Versatility, Mastery, Leech), and more than one name for several
  stats: Hit, Hit (Melee), Hit (Spell), Hit (Ranged); Critical Strike with the same three; Spell
  Power and Spell Damage; "Mana Regeneration per 5 sec" and "Mana Per 5 Sec." (`POWER_REGEN0`);
  Expertise, Haste, Spell Piercing (`SPELL_PENETRATION`), Spell Healing, Defense, Dodge, Parry,
  Block, Bonus Armor, the weapon skills ("Daggers Skill") and school damage ("Fire Damage").
  `core/weights.lua` lists every name of a stat. Second part, 2026-11-16 (Ben): Brutal War Axe of
  the Sorcerer gave `ITEM_MOD_INTELLECT_SHORT` 8, `ITEM_MOD_SPELL_POWER_SHORT` 22,
  `ITEM_MOD_DAMAGE_PER_SECOND_SHORT` 15.14 and `ITEM_MOD_STAMINA_SHORT` 6 **[Seen]**: spell power
  under one name only (not also `SPELL_DAMAGE_DONE`), weapon DPS as a decimal, and a random
  ending's stats (the Sorcerer's) included. Still open **[Unknown]**: the names an item with Hit,
  Crit or MP5 uses, so such a stat is not counted twice.
- **E15 A Full scan's links and endings (Upgrades tab).** Since 2026-11-17 a Full scan saves the
  stats of each ending from its listings' links (`GetReplicateItemLink`), filed by the item level
  `GetItemInfo` gives for the link; the Upgrades tab looks them up by the item level of the auction
  house item key. Two things not yet seen **[Unknown]**: that a Full scan link carries the
  ending's stats (seen only for an item search result's link), and that the two item levels are the
  same number. `TESTING.md` step 28 checks both at once: after Clear and a Full scan, an Upgrades
  search that has no "Reading the stats of each ending" step means both hold.
  Result 2026-11-17 (Ben, saved variables read after a `/reload`) **[Seen]**: the Full scan
  saved 11,354 ending names in about 4 seconds after it finished, so its links do carry the
  ending's stats. Chest, Back and Wrist searches after it read only 21 names themselves (Chest had
  read 100+ before). For each of the 21, the scan had saved other endings of the same item at the
  same item level, so the two item levels match. The 21 names had a market price for that day,
  which only a complete look such as the Full scan writes, so the scan saw those listings, but no
  stats were saved for them. **[Inference]**: `GetItemStats` gave nothing for those links at that
  moment (the game had not loaded them yet), and aux does not try again. Since the same day aux
  tries those names again every second, 5 times (`TESTING.md` step 30).
