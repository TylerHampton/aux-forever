# Roadmap and versions

Set by Tyler on 2026-10-05. Version numbers are `0.MINOR.PATCH`, written `forever-0.2.1` in the
TOC. Every release gets an entry in `docs/changelog.md`.

## 0.2.x: everything that is there works (now)

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

- **Item list** (`GetBrowseResults`, one request, 0.1s for 335 items in Tyler's test): per item
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

### Order

1. Measure the whole-auction-house item list (time, number of items, number of requests).
2. Mockups for fast mode and the sniper, then build fast mode (the sniper is built on it).
3. Sniper.

Every visible change gets a mockup first.
