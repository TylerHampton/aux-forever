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
first. Rings, trinkets and one-handed weapons compare with the weaker of the two worn. Buying works
as on the Search tab (the buy bar).

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
   Also 2026-11-16 (Ben): a "Per gold" column, score points gained per gold of the price
   (`per_gold` in `tabs/upgrades/core.lua`), after Gain; the table still sorts by Gain. The
   game's stat names are Retail's until experiment E10 confirms Forever's.
5. The tab: controls, search, results table, renumbering. Built 2026-11-16 (`tabs/upgrades/`),
   with tests; not tried in game yet (`TESTING.md`, "Upgrades tab, first build"). One change from
   the mockup: a row opens that exact item on the Search tab, which shows its auctions and buys it
   with the Search tab's buy bar and its never-more-than-shown check, instead of a buy bar on the
   Upgrades tab. A buy bar on the tab itself can follow if this feels clumsy in game.
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
