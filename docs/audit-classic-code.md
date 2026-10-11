# Audit: Classic assumptions in carried-over code (2026-10-11)

Why: FB-010 (weapon slots searched every weapon) came from a line of Simon's Classic code that
assumed only armor had slots. Nobody had touched it, the tests used an empty category list, and the
in-game checks only tried armor. Tyler asked for one pass over the code carried over from Classic
aux, looking for the same kind of mistake: code that assumes Classic's game data (category numbers
and shapes, item names and types, slot names, level range, item numbers).

How: each file of `auxForever/` was compared with Simon's current code (github.com/shirsig/aux-addon,
branch `master`) to find what is still his, then read against Blizzard's Forever code
(Gethe/wow-ui-source, branch `forever`, build 70338) and the game's English text
(Ketho/BlizzardInterfaceResources, branch `forever`). Forever is Blizzard's project "Camelot"
(`WOW_PROJECT_ID = WOW_PROJECT_CAMELOT` in `Blizzard_ProjectConstants/Camelot`), so its auction
house loads `Blizzard_AuctionHouseUI/Camelot/Blizzard_AuctionData.lua`.

Still almost entirely Simon's: `util/filter.lua` (search language, 99%), `core/disenchant.lua`
(100%), `core/cache.lua` (99%), `tabs/search/saved.lua` (98%), `util.lua`, `util/persistence.lua`,
`util/completion.lua`, `util/sort.lua` (100%, generic code with no game data). Partly his:
`util/info.lua` (77%), `gui/listing.lua`, `tabs/post/core.lua`, `gui/auction_listing.lua`,
`core/slash.lua`.

## Done in this pass

- **Tests use Forever's real categories** (`tests/forever_categories.lua`, made by
  `tests/tools/make_forever_categories.lua` from Blizzard's code). Before, the list was empty.
- **Every category, type and slot reads back** (test `0.6.1: every category reads back`): all
  137 choices of the Which items menus, written as search text, read back as the same choice and
  ask the auction house for exactly that category. Without the FB-010 fix 31 of them fail
  (all weapon slots, container types, Item Enhancement); with it none do.
- **Weapons first, Armor second** (same test): `core/scan.lua` leaves out Blizzard's exact match
  for categories 1 and 2 (gear has random endings) and finds them by position. True on Forever
  today; the test fails if a patch reorders the list, once the data is made again.

## Findings

Severity as in `docs/feedback.md` (S1 worst, S3 small). "Checked" means read in the code or in
Blizzard's code; "unknown" means it depends on something only the game can show.

| # | What | Where | Effect for a player | Evidence | Proposed |
| --- | --- | --- | --- | --- | --- |
| A1 | Slots only read under Armor | `util/filter.lua`, slot parser | Weapon, container and item enhancement slots searched everything of the type (FB-010) | Checked, test | Fixed in 0.6.1 (build 1, then named 0.6.0.3) |
| A2 | "In words" puts a weapon slot in an odd order: Weapons, One-Handed, Daggers reads "one-handed (weapons, daggers)" | `tabs/search/filter.lua`, `blizzard_words` | Confusing text in the Filter Builder's In words line (S3) | Checked in the code; written for Classic's "cloth (armor, chest)" | Fixed in 0.6.1 build 2: "Daggers (weapons, one-handed)" (Tyler, 2026-10-11: make the common-sense changes) |
| A3 | Levels stop at 60: a typed level above 60 is not a level, and the level boxes are capped at 60 | `util/filter.lua` (number parser), `tabs/search/filter.lua` (`valid_level`) | Only matters if Forever's level cap is above 60 | Tyler, 2026-10-11: the level cap on Forever is 60 | None: closed |
| A4 | aux's item list (names for autocompletion, exact searches, `/aux price`) covers item numbers 1 to 30000 | `core/cache.lua`, `MAX_ITEM_ID` | Items with higher numbers could not be autocompleted or found by name in `/aux price`, unless the game happened to download them while aux watched | Tyler, 2026-10-11: Forever will have many items Classic did not | Fixed in 0.6.1 build 2: an item seen at the auction house joins the list at once (`learn_item`; no tooltip read, no cost at login) |
| A5 | Disenchant results are Classic's table (which dust, essence and shard by item level) | `core/disenchant.lua` | Disenchant tooltip lines and disenchant filters would be wrong if Forever changed disenchanting | Unknown; likely the same as Classic | No change unless Tyler sees a wrong "Disenchants into" line |
| A6 | Whether an item can be auctioned is read from line 2 of its tooltip (binding text), away from the auction house | `util/info.lua`, `auctionable` | Decides whether tooltips show Value and whether an item joins the autocompletion list. The Post tab is not affected: with the auction house open it asks the game (`IsSellItemValid`) | Unknown: Forever's tooltip line order not checked | In-game check: a soulbound item's tooltip should have no Value line |
| A7 | Rarity choices stop at Epic (no Legendary) | `util/filter.lua` (`rarity`, suggestions), `tabs/search/filter.lua` (quality menu) | Cannot filter for Legendary only; Epic or better still includes them | Checked | None (legendaries are almost never sold) |
| A8 | "My characters" list is stamped with the computer's uptime (`GetTime`) instead of the date, so its 30-day cleanup is unreliable | `core/cache.lua`, `is_player` | A deleted or renamed alt can keep counting as yours (its auctions show as your own) | Checked in the code; Simon's code | Fixed in 0.6.1 build 2: dated with `time()`; old uptime stamps count as seen today, so no alt is lost |
| A9 | Exact searches for gear use only the category (Weapons, Armor), not the type, because a weapon's type is one level lower on Forever and slot names never match the item's equip slot | `util/filter.lua`, `blizzard_query` | None seen: the search is a little broader than it could be, then matched by name | Checked | None |

Checked and fine (no change): the item key format used for prices (`item_id:suffix_id`, also used
by the disenchant value); the item link fields (suffix in field 7, as on the modern client);
time left codes (read from the game's bands); the quality filter sent to the auction house;
`AuctionCategories` being loaded before aux uses it (`compat.lua` loads Blizzard's auction house
code at login); search texts written in code (only `<name>/exact`, no category names).

## Not covered

- The rewritten parts (scanning, buying, posting, Sniper) were not read again: they were written
  for Forever and Tyler tests them every build.
- Item type names in `tests/forever_categories.lua` (Daggers, Cloth, Potions, ...) and the type
  lists of Consumables, Trade Goods, Ammo, Recipes and Miscellaneous are written by hand in the
  script. On 2026-10-11 the game printed its real names for Tyler (0.6.1 build 2 test page) and
  several first guesses were wrong (Consumables are plural and include Draughts and Devices; Trade
  Goods has Cooking, not Meat; Recipes has no Fishing; Miscellaneous has Pet; Fishing Pole is
  singular). They were corrected and the data made again: it now matches the printout line for
  line, 137 choices. Not printed: the two types under Item Enhancements.

## Questions for Tyler

Answered on 2026-10-11: the level cap is 60 (A3 closed); Forever will have many items Classic did
not (A4 fixed); and "make all the common sense changes" (A2 and A8 fixed). None open.
