# Roadmap and versions

Set by Tyler on 2026-10-05. Version numbers are `0.MINOR.PATCH`, written `forever-0.2.1` in the
TOC. Every release gets an entry in `docs/changelog.md`.

## 0.4.1: performance first, then common-sense UX (now)

0.4 was released on 2026-10-05. Tyler: 0.4.1 is mainly performance, partly UX/UI common-sense
changes; no new features (those are written down for 0.5). A bad bug (spends money wrongly,
errors over and over, a tab that does not work) gets its own hotfix release at once; everything
else is batched, about a week of real use.

1. Confirm in game what never was (`TESTING.md` section 17): the recipe cost line in the bottom
   bar, buying from the Sniper, posting from the reagent bag, suffix names on fast rows, the
   Auctions tab cancel flow, the Bids tab, a full scan, posting gear with a bid, Filter Builder
   dropdowns, Shift-click on a recipe.
2. Feedback from the two testers (Darkhorse, Hotpocket), on recipe search and the Auctions tab.
3. Performance:
   - Done: Simon's login walk over item numbers 1 to 30000 (`fetch_item_data`) skips numbers the
     game says are no item and pauses every 500 numbers; `/aux memory` says how far it is.
   - Done: `core/crafting.lua` removed (Classic profession frames only; on by default, did nothing
     on Forever) with its `/aux crafting cost` setting.
   - Done: the per-frame audit. Every `OnUpdate` and thread was read. Fixed: Saved Searches checked
     the Alt key every frame, the Bids tab set its buttons every frame, quick menu rows set the
     pin's alpha every frame. The buy bar was already at ten times a second in 0.4 and only while
     a row is selected; left as is.
   - To do: `/aux memory` at Sniper round 10 and round 40 (after a cleanup should match).
4. Housekeeping, done: tests run once per change on GitHub (a pull request from this repository
   reuses the branch's run; the duplicate was cancelled while queued at the 0.4 merge and GitHub
   mailed it as a failure).
5. UX/UI common sense. Tyler picked (2026-10-05): prices without zero parts ("7s", not "7s 00c")
   and sold Sniper deals at the bottom; both done. Not picked for now: a dash instead of "?" in
   the Sniper's Usual column, and "?" in the Search tab's Seller column.

## 0.3.x: fixes after 0.3 (done)

0.3 was released on 2026-10-05. 0.3.x is bug fixes, speed and other small things that come up,
no new features (Tyler, 2026-10-05). To confirm in game: buying from the Sniper, posting from the
reagent bag, suffix names on fast mode rows (`TESTING.md` section 15).

## 0.4: selling tools (released 2026-10-05)

Tyler chose selling tools (other candidates, not chosen for now: price history from Sniper rounds,
a price history chart, crafting profit). Searching and buying are strong since 0.3; the Auctions
tab is still a list with Cancel.

Decisions (Tyler, 2026-10-05):
- Auctions tab shows, for each of your auctions, the lowest price of other sellers and a status:
  lowest, tied, undercut by how much, sold.
- Undercut (someone else lower) is red and goes through "Cancel undercut". Tied (someone else at
  your price; on Forever the newest listing at a price sells first) is amber, shown but not
  cancelled.
- Cancelled items come back by mail on Forever (Tyler), so reposting is: cancel at the auction
  house, collect the mail, post again (the Post tab already starts at the lowest price).
- Every cancel and every post needs its own click (Blizzard marks CancelAuction, PostItem and
  PostCommodity as restricted), so Cancel undercut steps through one auction per click.
- Posting several items: after posting an item, the Post tab selects the next item in the list
  (no separate queue mode).

Facts to check while building: the cost of cancelling on Forever (`GetCancelCost`, likely the
deposit), and how fast the per-item checks are for a typical number of auctions (about 0.5s per
item, measured for searches).

Recipe search (added by Tyler 2026-10-05 after two guild testers asked for it; retail and
Auctionator users expect it): Shift-click or Alt-click a recipe in the profession window while aux is
open, and the Search tab searches the item it makes and every material, as one search with one exact
query per item ("linen bag/exact;bolt of linen cloth/exact;..."). Facts from Blizzard's Forever code:
- Forever uses the modern profession window (Blizzard_Professions), not Classic's TradeSkillFrame.
  aux's `core/crafting.lua` hooks only the Classic frames, so its material cost label and its
  right-click search on materials never run on Forever.
- The recipe list passes a click to `HandleModifiedItemClick(C_TradeSkillUI.GetRecipeLink(id))`,
  which aux already hooks for items; recipe links are not item links, so they are ignored today.
- `C_TradeSkillUI.GetRecipeSchematic(recipeID, false)` gives `outputItemID` and
  `reagentSlotSchematics` (each with its `reagents` item IDs and `quantityRequired`).
To check in game: the recipe link format (likely `enchant:` plus the recipe ID), whether Shift-click
also tracks the recipe (Blizzard does that when the click is not taken), and whether links from
other players' recipes in chat work too.

Recommended design (Claude, 2026-10-05, waiting for Tyler; mockup board "Recipe" in the 0.4
canvas): no Recipes tab and no copy of the player's recipes. A "Search in aux" button on the
profession window's recipe panel, shown only while aux is open at the auction house, plus
Shift-click or Alt-click on a recipe in the list. Either one reads that one recipe
(`GetRecipeSchematic`) at the moment of the click and runs one Search tab search for the item and
its materials; a line above the results adds up materials, sale price after the cut, and profit.
Nothing runs or is stored until the click. In Blizzard's Forever code the only built-in link from
the profession window to the auction house is a gamepad-only "search the auction house" for a
single reagent; the "search every ingredient" Hotpocket knows from retail is, as far as we know,
from Auctionator (not confirmed).

Found in Blizzard's Forever code (2026-10-05): Shift-click on a recipe is also "track recipe"
(`RECIPEWATCHTOGGLE`, default Shift) whenever the click is not taken by chat, and aux's hook cannot
take it, so Shift-click would search and track at once. Use Alt-click and the button instead.
The selected recipe is `ProfessionsFrame.CraftingPage.SchematicForm:GetRecipeInfo()`.
Waiting for Tyler's in-game check of the recipe link and `GetRecipeSchematic` (two /run lines).

Performance work planned with 0.4 (Tyler: performance matters most; change Simon's code where it
makes sense):
- Item tooltips anywhere in the game build a hidden tooltip on every hover to decide whether the
  item can be auctioned (`info.auctionable(info.tooltip(...))` in `core/tooltip.lua`): cache it per
  item.
- The Post tab re-reads its price boxes and asks the game for the deposit every frame while open
  (`validate_parameters`, `deposit_amount`): only when something changed.
- The buy bar sets its texts every frame while a row is selected: only on change.
- Price history unpacks and repacks an item's saved text for every auction a scan sees
  (`history.process_auction`): keep records unpacked in memory and save once.
Not worth changing: the idle thread loop in `control.lua` (an empty table per frame), the event
dispatch (about 30 listeners per event), the module system's lookups (rewriting all of aux to
locals would be churn with no measurable gain at these call rates).

Order: Auctions tab (mockup approved by Tyler 2026-10-05:
https://claude.ai/artifact/A6L3eNDURLpJUMBd1aVucY), the Post tab jump, recipe search.

## 0.2.x: everything that is there works (done)

The goal of the 0.2 line is that every feature in the addon works without issues: no new
features, only bug fixes and speed. A 0.2.x goes to CurseForge once the filters work well in
Tyler's test runs (`docs/test-scenario-0.2.md`).

Open for 0.2.x:

- Blizzard UI button unreliable (fix in 0.2.1, needs confirming in game).
- Anything found in the test scenario.
- Speed of broad searches where it can be improved without new features (Forever answers one
  item per request, so a search over hundreds of items takes minutes; the big speedup is 0.3).
- Still not tried in game: Auctions tab cancel, Bids tab, full scan, posting gear with a bid.

## 0.3: fast mode and sniper (planning, 2026-10-05)

### What the game gives us (Blizzard's API documentation)

- **Item list** (`GetBrowseResults`, 0.1s for 335 items; the whole auction house, 7718 items, in
  8.5s and 16 requests): per item
  only the item, how many are for sale (`totalQuantity`), the lowest price (`minPrice`) and
  whether some are yours. No bids, sellers, time left or individual auctions.
- **One item's auctions** (`SendSearchQuery` per item): everything, but Blizzard's request limit
  allows about one every 0.4s. This is what full mode does for every item.
- **Full scan** (`ReplicateItems`, once per 15 minutes): every auction with price and seller,
  but no auction IDs, so nothing can be bought from it directly.

### Fast mode

- A search that only reads the item list: one row per item with Lvl, Item, For sale, Lowest
  price (each) and % of usual. Seconds instead of minutes for broad searches.
- Selecting a row loads that item's auctions (one request, about half a second) into the buy bar,
  which buys exactly as today and keeps its price guarantee.
- Conditions that need more than the list (bid, seller, time left, tooltip text) cannot be
  checked on the list. Proposal: they are checked when an item is opened, and the Filter Builder
  marks them; or a search that uses them runs in full mode. To be decided.
- Lightweight: no new saved data; the list is what the game already sends.

### Sniper

- Goes through the whole auction house's item list again and again and lists items whose lowest
  price is a good margin under their usual price, newest finds on top, with a sound when one
  appears. Selecting one loads its auctions into the buy bar as above.
- A deal: lowest price at most X% of usual and at least Y profit. Items with too little price
  history are skipped, so a thin "usual price" does not fake deals.
- How often it can go round depends on how long the whole list takes on Forever: to be measured
  first (a debug command that times an item list of everything, without opening items).
- The full scan stays separate: it feeds price history, which is what makes deals trustworthy.

### Decisions (Tyler, 2026-10-05)

- Fast mode is automatic: searches over many items use the item list; a search for one exact
  item stays full. A small Fast / Full switch can force full.
- The Sniper gets its own top tab (Search, Sniper, Post, Auctions, Bids).
- Default deal rule, chosen by Claude for a full release rather than the beta economy (Tyler left
  the call to Claude; TSM players' sniper setups combine "below vendor price" with "a share of the
  market price, never below vendor price"; the exact TSM defaults could not be checked):
  - always a deal: lowest price below what a vendor pays (a sure profit, no history needed);
  - otherwise a deal when the lowest price is at most 60% of the usual price, the profit after the
    auction house cut is at least 5s, and the usual price rests on at least 3 days of history;
  - the usual price used here is never below the vendor price.
  Players can change the percentage and the minimum profit. A percentage scales from level 20 to
  60 on its own; the 5s floor only hides trivial finds.

### Built (2026-10-05, first build for testing)

- Fast mode as planned. Rows from the item list are not price history (the list's lowest price may
  be a bid); opened items are. Conditions the list cannot check (seller, time left, bid, tooltip
  text) make a search full, and the summary line says so (Tyler's choice).
- Live mode kept as Simon's real time mode, made visible (Tyler: "make it work how it sounds"):
  a round, then a 5 second countdown on the Live button, "Paused" only when paused, held while on
  another tab.
- Sniper: only while its tab is open (Tyler's choice). An item that looks like a deal on the list
  is opened once to check its real auctions, so a bid shown as the lowest price never makes a
  false deal. The minimum profit also applies to below-vendor deals, so 1 copper finds are hidden.
  Known limit: profit is per item, so cheap trade goods (Wool Cloth 2s, usual 6s) rarely pass 5s
  even when buying 80 would be worth it. To revisit after testing.
- Fast mode and the Sniper were delivered together in one zip (Tyler's choice).

### Order

1. Measure the whole-auction-house item list (time, number of items, number of requests).
   Done (Tyler, 2026-10-05, `/aux debug list`): 7718 items in 8.5s, 16 requests (the game sends
   the list in pages of about 500). Reading every item's auctions instead would take about 75
   minutes at 0.58s per item. One sniper round is therefore about 8.5s. Not yet known: whether
   it changes at busy times, and whether the server objects to rounds back to back for a long time.
2. Mockups for fast mode and the sniper, then build fast mode (the sniper is built on it).
3. Sniper.

Every visible change gets a mockup first.
