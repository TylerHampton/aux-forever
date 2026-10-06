# Changelog

What changed in each version, newest first. The text under each version is ready to paste into the
CurseForge file's changelog box.

## 0.4.1 (in progress)

- Performance: aux's item list at login no longer asks the server about item numbers the game
  says do not exist, and walks the list in steps instead of one long frame. Saved Searches, the
  Bids tab and the quick search menu no longer do work every frame.
- Removed the Classic-only crafting cost code and its `/aux crafting cost` setting; it never ran on
  Forever (recipe search does this job since 0.4).
- `/aux memory` also says how many items aux's item list knows, and whether it is still checking.
- Prices leave out parts that are zero ("7s" instead of "7s 00c") in text. In a table, when any price
  has copper, every price keeps all its parts ("1s 00c") so the column lines up.
- Memory: a full scan no longer keeps the listings of every item on the auction house for the Post
  tab (about 30 MB for the rest of the session); it keeps those of the items in your bags.
- Sniper: the buy bar offers only the units that are a deal (it offered more expensive units of a
  trade good too), and rounds wait while a purchase is under way.
- Sniper: gear deals can be bought. A selected deal is checked again first ("Checking the
  auction...", or what is left of a trade good), and the rounds hold while a deal is selected
  (click it again to go on). The table no longer changes while the mouse is over it.
- A new search of any kind ends Live mode. A saved or recipe search started while Live was on was
  refused, and Live kept updating the old search under the new search text.
- Tables keep the same row selected when rows are added above it (it moved to another row).
- An empty search bar no longer lists the whole auction house (2,000 rows and a "Table full" popup).
- The Auction Bid column shows "---" for auctions with no starting bid instead of their buyout.
- The resize corner: aux sizes the window itself while you drag. A single click on the corner could
  make the whole window jump diagonally, again with each click.
- `/aux memory detail` lists what aux keeps (Sniper, history, searches, Post, tooltips, events).
- Sniper: deals that sold sort below the ones still to buy.

## 0.4 (2026-10-05)

- Auctions tab: each of your auctions is compared with the other sellers: undercut (and by how
  much), tied, lowest or sold. "Cancel undercut" cancels the undercut ones, one click each, and
  shows what each cancel costs; cancelled items come back by mail. Prices are read when the tab
  opens (or with Check prices), half a second per item, never in the background.
- Recipe search: with aux open at the auction house, the profession window gets a "Search in aux"
  button, and Alt-click on a recipe does the same. aux searches the item the recipe makes and all
  its materials at once. The bar under the results adds up the materials (cheapest auction or
  vendor price), what the item sells for after the cut, and the profit or loss; a material with
  no price is named, and the result becomes "loss at least" or "profit at most". Recipe searches
  show in Saved and Recent as "Recipe  Name  (N materials)" and keep their cost line. Nothing is
  read before you click.
- Post tab: after posting everything of an item, the next item in the list is selected.
- Sniper: deals show while a round runs, with "checking N possible deals (k done)"; one sound for
  a burst of deals (at most one every 10 seconds); deals no longer vanish for a while when the game
  reloads item data; 2.5 seconds between rounds instead of 1; the empty table's text is no longer
  cut off.
- Performance and memory: item tooltips no longer build a hidden tooltip on every hover; the Post
  tab and the buy bar no longer redo their work every frame; scans no longer unpack each item's
  price history for every auction they see; Sniper rounds build no tables per item and keep
  nothing from round to round (about 1 MB of notes on the items, once).
- `/aux memory` also shows what is left after a cleanup, to tell real use from garbage the game
  has not freed yet. `/aux debug` prints timing for searches only, not for every Sniper round or
  Auctions check.

## 0.3.1 (2026-10-05)

- Performance: aux no longer does work every frame while idle. A check inherited from Classic aux
  compared every event listener with every other one on every frame, all game long, even away
  from the auction house; the Auctions and Bids tabs each ran a timer every frame to rebuild their
  lists every second; the Full scan button repainted itself every frame. Now the event cleanup
  runs only after a change, the Auctions and Bids lists follow the game's events (and refresh
  every 10 seconds while open), and the Full scan button and Live and Sniper status lines update a
  few times a second.
- `/aux memory` says how much memory aux uses and how many items its price history holds.

## 0.3 (2026-10-05)

- Fast searches: a search over many items lists each item once with its lowest price and how many
  are for sale, read from the auction house's item list in seconds instead of minutes. Click an
  item to see its auctions and buy. A Fast / Full switch sits next to Search. Searches for one
  exact item, or using seller, time left, bid or tooltip text, read every auction as before, and
  the line next to the tabs says why.
- Live mode shows what it is doing: "Updating" during a round, then a countdown to the next one
  ("Live 4s"), and "Paused" only when you pause it. It repeats the search every 5 seconds, holds
  while you are on another tab and carries on when you come back.
- New Sniper tab: watches the whole auction house round after round (about 8 seconds a round) and
  lists deals: below vendor price, or at most 60% of the usual price, with at least 5s profit
  either way (both adjustable). The usual price needs 3 days of price history. Each deal is
  checked against the item's real auctions before it is shown, and buying works as on the Search
  tab. A sound and a flashing game icon for new deals; ignore items you do not want.
- Post tab: items in the reagent bag are listed too.
- The Blizzard window's own tabs (Buy, Sell, Auctions) no longer stretch off the screen.
- A search that hits an error now stops cleanly and says so in chat, instead of looking busy
  forever.
- New credit line: "aux by shirsig, re-imagined by a fan".
- Needs a full game restart after updating (new files).

## 0.2.1 (2026-10-05)

First release since 0.1.1, so it also brings everything from 0.2: the new Filter Builder
(conditions in plain words, Match All or Any, "not", groups inside groups, an "In words" line,
kept in sync with the search bar), the default duration setting and the favorites fix.

- Post tab: trade goods have one Quantity box instead of Stack size and Stacks. Forever posts a
  trade good as one listing of any size, so Max now posts everything you have.
- Search tab: the Search Results tab shows how many items were found, a line next to the tabs
  says what they hold ("37 items, 403 for sale, searched 2m ago"), and the search bar has a
  magnifier.
- Filter Builder: a Match All / Any switch is faded while it has fewer than two conditions under
  it, and the builder keeps your groups when you leave it and come back.
- Settings: a Scale setting (70% to 150%), handy on large monitors, and the scale is now kept
  after a reload. The settings menu has no explanation text; the auction length setting is now
  called Default duration, like the Duration buttons on the Post tab.
- `/aux debug` turns on a search timing log: after each search, chat shows where the time went.
- The resize corner no longer makes the window jump to full screen on a single click.
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
