# Upgrades tab (plan)

Branch `search-upgrade-support`, started 2026-11-16. Not built yet: this file is the plan, the open
decisions and the experiments that come first. Mockup (Design canvas, two boards: the tab and the
weights in Settings): https://claude.ai/artifact/1HAmjfzsUSKAL63J9BT6sN. Its items and numbers are
examples, not game data.

## What the player gets

A tab after Sniper, **Upgrades**. The player picks a spec (their class's specs; the choice is
saved per character, since Forever does not report talent trees, E9), a slot (Head ... Ranged)
and how far above their level to look, and presses Search. aux reads what they wear in that slot, searches the auction house for gear of that slot
they can use, scores every item with the spec's stat weights and lists the ones that beat what
they wear: the score, the gain over the worn item, the stats that change, and the price, best gain
first. Rings, trinkets and one-handed weapons compare with the weaker of the two worn. A row is
bought on the tab itself, with the buy bar under the table (since 2026-11-17).

The tab informs, it does not decide (`AGENTS.md`): it shows the score and what it is made of, never
"buy this".

## Stat weights

- One weight per stat for each Classic spec (27), in a data file, each with its source. Sources are
  Outside facts made for Classic; Forever's items (Windfury on an axe) may need other numbers.
- Settings gets an "Upgrade weights" section: pick a spec, change any number, reset to defaults.
  Changes are saved per character.
- Weapons add damage per second times its weight; tanks weigh armor and defense.

## How it works

- **Search:** the item list request (one per 500 items), as the Sniper and fast mode use, with the
  slot's category and the usable filter. One row per version ("of the Bear", "of the Eagle"). No
  search per item.
- **Stats:** read once per version and kept by price key (`info.price_key`): versions of one name
  have the same stats (`docs/forever-auction-house.md`, Seen). E8: `C_Item.GetItemStats(link)` works
  on a link (Seen); `C_TooltipInfo.GetItemKey` is blocked for addons (Seen), never call it. A listed
  version has an item key, not a link: the plan is a hidden tooltip of aux's own, `SetItemKey`,
  then `GetItem()` for the link, then `GetItemStats`: this works on a row's icon in aux's results
  (Seen, 2026-11-16). Fallback if a case fails: the hidden tooltip's stat lines (English only).
- **Scoring:** sum of stat times weight, plus weapon DPS times its weight. Plain Lua in its own
  file (`core/stats.lua`), so tests check it without the game.
- **Speed:** stat reads spread over frames with `aux.coro_wait()` every few hundred items.
- **Tab numbers:** Upgrades becomes tab 3, so Post, Auctions and Bids move to 4, 5 and 6. Every
  use of a tab number changes with it: the gamepad's Y actions (`QUICK_ACTIONS`, `Y_NAMES`), tests
  that switch tabs by number, `AGENTS.md` ("Tabs by number"). A test checks each tab's number.

## Steps

1. Experiments E8 and E9 in game (`TESTING.md`, "Upgrades experiments"): done 2026-11-16.
2. Mockup approved (the link above): approved by Ben, 2026-11-16.
3. Stat reading and scoring, with tests: built 2026-11-16, `core/stats.lua` (`key_stats`,
   `link_stats`, `score`, `worn_score`, `compare`, `changes`), test `upgrades: stats, scores and
   the worn item`. Not used by any screen yet.
4. Weights: default data with sources (built, `core/weights.lua`), the Settings section (built
   2026-11-16, `tabs/upgrades/weights.lua`): a window of its own, "Settings / Upgrade weights" as in
   the mockup, opened from Settings (Upgrades, Stat weights, Edit) and from the tab's "Change
   weights" button. One box per stat for the chosen spec; the player's numbers show in gold and are
   kept per character and spec (`character_data.upgrades.weights`), only where they differ from the
   guide's; an empty box or Reset brings back the guide's; 0 leaves a stat out.
   Also 2026-11-16 (Ben): Attack Power counts for the physical specs whose list does not name it,
   from each guide's Strength and Agility conversion (`docs/stat-priorities.md`, "Attack Power
   conversions"). Also 2026-11-16 (Ben): a "Per gold" column, score points gained per gold of the price
   (`per_gold` in `tabs/upgrades/core.lua`), after Gain; the table still sorts by Gain. The
   game's stat names are Retail's until experiment E10 confirms Forever's.
5. The tab: controls, search, results table, renumbering. Built 2026-11-16 (`tabs/upgrades/`),
   with tests; not tried in game yet (`TESTING.md`, "Upgrades tab, first build"). One change from
   the mockup: a row opens that exact item on the Search tab, which shows its auctions and buys it
   with the Search tab's buy bar and its never-more-than-shown check, instead of a buy bar on the
   Upgrades tab. A buy bar on the tab itself can follow if this feels clumsy in game.
   2026-11-17 (Ben, screenshot): every "of the ..." version scored as the plain item, since the
   link `SetItemKey` gives has no ending (E8 in `docs/forever-auction-house.md`). Fixed: after the
   item list, one auction of each ending name of the slot is read (one request per name, one scan;
   `read_endings` in `tabs/upgrades/core.lua`) and its link's stats score every version of that
   name (Ben: the lowest values of a grouping are acceptable; one case Seen of two versions of one
   name with the same stats). Saved for the account (`account_data.ending_stats`, Ben: "so they
   don't have to be looked up"), and read again after a game patch (another build number from
   `GetBuildInfo`), 30 days after each was read (a server-side fix that keeps the build), or when
   the player presses Clear in Settings, Upgrades, "Saved item stats". Saved by item, item level
   and name, so each item level has its own. Left open (Ben, 2026-11-17, "leave it for now"):
   versions of one name at one item level (Ritual Belt of Arcane Protection, 14320 to 14323) share
   the first one read; if they differ in strength **[Unknown]**, keying by the version number reads
   each one exactly, at one request per version the first time. An ending that could not be read is scored
   without it and the status line counts it. Cost: a Two-Hand search at level 15 found about 20
   ending names, so about 20 more requests the first time.
   2026-11-17 (Ben): buy on the tab itself, with mouse and gamepad. Built: the Search tab's buy
   bar sits under the table while the tab is open (as on the Sniper). A click selects a row; its
   version's auctions are read (one request, `read_row` in `tabs/upgrades/core.lua`) and the
   cheapest with a buyout is offered at its real price on the button; the row takes that price and
   count. After a purchase it is read again, so the next one is offered or the row leaves the table
   when none is left. Right-click opens it on the Search tab, as in every table. Gamepad: Y on a
   focused row selects it (reads its price), the next Y buys; Y elsewhere on the tab is Search. A
   read that ends cannot buy by itself: aux's buy call (`aux.place_bid`) runs only from a click or
   pad press (Code, aux's own comment there; not checked in Blizzard's code). Tests:
   `tests/timing_test.lua`, "buying from the Upgrades tab" and "Y on a row buys it".
   Open: whether the auction house's "usable" filter also hides items above the player's level
   (then "Up to my level + 2" finds nothing extra; `TESTING.md` step 7).
6. Gamepad (Y runs Search), docs, `TESTING.md` steps, changelog.

New feature, so it belongs in the next minor version (0.9); Tyler decides which release it joins.

## What an item is compared with (`worn_score`)

- Rings and trinkets: the weaker of the two worn.
- A two-hander: both hands together (main hand plus off hand).
- A one-handed weapon: the main hand, or the weaker hand when the off hand holds a weapon too
  (never a shield or a held item).
- A main hand or one-hander while a two-hander is worn: the two-hander alone. Leaving the off hand
  empty is not counted; refine later if it misleads.
- An empty slot scores 0, so anything with a weighted stat is an upgrade there.

## Open decisions

1. Weapons: the comparisons above are the starting point; open whether they need refining.
2. Where the default weights come from: decided 2026-11-16 (Ben), Icy Veins' WoW Forever stat
   pages, one per spec, collected in `docs/stat-priorities.md`. They give an order, not numbers
   per point. Decided 2026-11-16 (Ben), option A: ranked weights. In a list of n stats the first
   is worth n per point, the next n - 1, down to 1; a stat not listed is 0. Known weakness: a 1%
   stat (Hit, Crit) counts like one point of Strength, so % stats are undervalued; players can
   change any weight in Settings. Built: `core/weights.lua`, test `upgrades: stat priorities and
   ranked weights`. Caps are not counted yet.
3. One slot per search, or also all slots at once (about 15 requests in a row)?
4. GearQuest (an addon some players have) already scores gear. Reading its scores when it is
   installed would need a way it offers to other addons; not checked.
