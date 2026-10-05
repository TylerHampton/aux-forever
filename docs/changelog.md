# Changelog

What changed in each version, newest first. The text under each version is ready to paste into the
CurseForge file's changelog box.

## 0.2.1 (2026-10-05)

- Post tab: trade goods have one Quantity box instead of Stack size and Stacks. Forever posts a
  trade good as one listing of any size, so Max now posts everything you have.
- Search tab: the Search Results tab shows how many items were found, a line next to the tabs
  says what they hold ("37 items, 403 for sale, searched 2m ago"), and the search bar has a
  magnifier.
- Filter Builder: a Match All / Any switch is faded while it has fewer than two conditions under
  it, and the builder keeps your groups when you leave it and come back.
- Blizzard UI button: the Blizzard window could end up off screen after opening another game
  window (character sheet, spellbook, a vendor), so the button seemed to do nothing. It now
  always opens on screen and in front of aux, and the button is lit while it is shown.
- Needs a full game restart after updating (a new icon was added).

## 0.2 (2026-10-05)

- New Filter Builder: conditions in plain words, Match All or Any, "not" on any condition, groups
  inside groups, and an "In words" line that reads the search back. It stays in sync with the
  search bar.
- Settings: default auction length (2h, 8h or 24h) for items you have not posted before.
- Favorites: an empty search is no longer saved, and the same search is not saved twice.
- Needs a full game restart after updating (a new file was added).

## 0.1.1 (2026-10-05)

- Fixed: posting gear failed with "Internal auction error" when the starting bid equalled the
  buyout. Such items are now posted for buyout only.

## 0.1 (2026-10-04)

- First test release of auxForever, aux by shirsig rebuilt for WoW Forever: search, buying (trade
  goods by quantity with a confirmed price, gear one at a time), posting at the lowest price with
  an optional undercut mode, quick searches and price history.
