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

## 0.3: fast mode and sniper

- **Fast mode** (measured need, 2026-10-05: a 335 item search took 3m 13s, 72% of it waiting on
  Blizzard's request rate limit, while the item list came back in 0.1s): search with the browse
  results only (one row per item with its lowest price and
  how many are for sale), without fetching every item's individual auctions. Much faster for broad
  searches; the details of one item load when it is selected. It has to stay lightweight.
- **Sniper** (as in TSM): go through the whole auction house and list items for sale a good margin
  below their usual price, using the price history aux already collects. Fast mode is what makes
  this practical. Open questions for when it is designed: how the margin is set, how often it
  rescans (the full scan is allowed once every 15 minutes), and how buying from it works.

Both get a mockup first, as with every visible change.
