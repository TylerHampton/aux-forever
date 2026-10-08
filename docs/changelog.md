# Changelog

What changed in each version, newest first. The text under each version is ready to paste into the
CurseForge file's changelog box.

A change that comes from a player's feedback credits them by in-game name at the end of its line:
"(suggested by Darkhorse)" or "(reported by Darkhorse)". Who to credit is in `docs/feedback.md`.

## 0.5 (in progress)

- Price data: aux now records a market price, the average of the cheapest fifth of what is listed,
  from every complete look at an item (Full scan, normal searches, the Sniper's checks). One cheap
  auction no longer sets the price. Tooltips show the price from your latest scan as Value, with
  when aux saw it ("seen today", "seen 3 days ago", darker when a week old or more), so a quick
  scan before posting is what you see afterwards anywhere in the world. When that is far from the
  usual price of the last two weeks, a gray "usually ..." line shows it. The usual price, with
  recent days counting more, is what the Sniper and the % columns compare against. Your 0.4.1
  price history is converted, not wiped. Going back to 0.4.1 after this version starts the price
  history over.
- Post tab: a post that does not happen always says why, under Duration and in chat: the item left
  your bags, is locked, needs a repair, was refused (with the game's own reason), or the auction
  house did not answer. A post that went through says "Posted". When the Post button is faded,
  the same place says why (no price, the starting bid above the buyout, not enough money for the
  deposit). (reported by Darkhorse)
- The Saved Searches lists and the Post tab's price lists lay out their columns again when shown
  and when resized, and their last column always ends at the window's edge. After a resize and a
  scale change, the Recent Searches header could stick out of the window. (reported by Garsterson)
- Clicks work the same way everywhere (docs/clicks.md). Right-click an item in your bags to bring it
  into aux: the Post tab selects it, the Search tab searches it. (suggested by Darkhorse) Shift- and
  Alt-click from the bags now also work from the Sniper, Auctions and Bids tabs (they switch to
  Search). Click a selected row again to let go of it, in every table. In the Post tab's price
  lists, right-click searches the item like every other row, and click a chosen price again to let
  go of it. Hovering any row shows a gray line with what its clicks do.
- Buy bar: the box for typing how many to buy is labeled QUANTITY and always shows the number you
  are buying; the quantity buttons fill it in, and typing any number changes it. It used to be a
  gray "Other" that looked like a button. (suggested by Darkhorse)
- Profession window: a line under the reagents says what one craft's materials cost at the prices
  of your latest scans (or the vendor price when a vendor sells it for less), anywhere in the world. A gray "+"
  means some materials have no price yet; hover the line for each material's price and where it
  comes from. (suggested by Garsterson)
- Tooltips: with Shift held (prices for the whole stack), Value, Today and the vendor prices say
  "for 3" so they are not read as the price of one.
- `/aux price <item>` prints what aux has recorded for an item: the usual price and how many days
  it rests on, today's lowest and market price, and each past day.

## 0.4.1 (2026-10-06)

Performance, memory and fixes from a week of testing.

- Memory: a full scan no longer keeps the listings of every item on the auction house for the Post
  tab (about 30 MB for the rest of the session); it keeps those of the items in your bags. Sniper
  rounds keep nothing from round to round.
- Performance: aux's item list at login no longer asks the server about item numbers the game says
  do not exist, and walks the list in steps instead of one long frame. Saved Searches, the Bids tab
  and the quick search menu no longer do work every frame. The Classic-only crafting cost code and
  its `/aux crafting cost` setting are removed; recipe search does this job.
- Sniper: gear deals can be bought. A selected deal is checked again first ("Checking the
  auction...", or what is left of a trade good), the buy bar offers only the units that are a deal,
  and the rounds hold while a deal is selected (click it again to go on) or a purchase is under
  way. Deals that sold sort to the bottom, and the table no longer changes while the mouse is over
  it.
- Live: a new search of any kind ends Live mode, and Live rounds wait while you buy (a round during
  a trade good's price quote ended it with "Internal auction error").
- Tables keep the same row selected when rows are added above it.
- Prices leave out parts that are zero ("7s" instead of "7s 00c"); in a table where any price has
  copper, every price keeps all its parts so the column lines up. The Auction Bid column shows "---"
  for auctions with no starting bid.
- The resize corner: aux sizes the window itself while you drag. A single click on it could make
  the whole window jump.
- An empty search bar no longer lists the whole auction house.
- `/aux memory` also reports the size after a cleanup and the item list; `/aux memory detail` lists
  what aux keeps.

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
