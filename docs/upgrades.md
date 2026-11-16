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
  then `GetItem()` for the link, if that link carries the ending's stats (still to check).
  Fallback: read the stat lines of that hidden tooltip (English client only).
- **Scoring:** sum of stat times weight, plus weapon DPS times its weight. Plain Lua in its own
  file (`core/stats.lua`), so tests check it without the game.
- **Speed:** stat reads spread over frames with `aux.coro_wait()` every few hundred items.
- **Tab numbers:** Upgrades becomes tab 3, so Post, Auctions and Bids move to 4, 5 and 6. Every
  use of a tab number changes with it: the gamepad's Y actions (`QUICK_ACTIONS`, `Y_NAMES`), tests
  that switch tabs by number, `AGENTS.md` ("Tabs by number"). A test checks each tab's number.

## Steps

1. Experiments E8 and E9 in game (`TESTING.md`, "Upgrades experiments"): done 2026-11-16, one
   check left (E8, the link of a row's icon).
2. Mockup approved (the link above).
3. Stat reading and scoring, with tests.
4. Weights: default data with sources, the Settings section.
5. The tab: controls, search, results table, renumbering.
6. Gamepad (Y runs Search), docs, `TESTING.md` steps, changelog.

New feature, so it belongs in the next minor version (0.9); Tyler decides which release it joins.

## Open decisions

1. Weapons: compare like with like first (a two-hander with a two-hander), or also a two-hander
   with main hand plus off hand?
2. Where the default weights come from.
3. One slot per search, or also all slots at once (about 15 requests in a row)?
4. GearQuest (an addon some players have) already scores gear. Reading its scores when it is
   installed would need a way it offers to other addons; not checked.
