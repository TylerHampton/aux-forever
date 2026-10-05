# Testing checklist

Do these in order. After each step, if BugSack shows an error, copy the full error text
(BugSack lets you select it) and send it over. One error at a time is fine.

## 1. Loading
- [ ] Log in. Chat shows `<auxForever> loaded. aux by shirsig, granted immortality by Tyler. /aux for help`.
- [ ] The AddOns list shows "auxForever" by shirsig. Hovering it shows the credit line.
- [ ] Type `/aux`, then `/auxforever`. Both print the list of settings in chat.
- [ ] The bottom of the window shows "aux by shirsig, granted immortality by Tyler" next to Scan.

## 2. Opening the auction house
- [ ] Talk to an auctioneer. The aux window opens and the Blizzard window does not appear.
- [ ] Click "Blizzard UI". The Blizzard window appears. Click it again and it disappears.
- [ ] Click "Close" on aux. The auction house closes. Talk to the auctioneer again; aux reopens.
- [ ] Press Escape with the auction house open. It closes.

## 3. Search tab
- [ ] Search for something by name, e.g. `bag`. Results fill in and the status bar moves.
- [ ] Prices now make sense per item: a Linen Bag row shows Stack Size 1, the price of one bag,
      and the number of bags available in "Auctions". "% Hist. Value" looks reasonable.
- [ ] Search with a filter, e.g. `armor/cloth/45/50/uncommon`.
- [ ] Exact search: right-click an item in the results. It searches that exact item.
- [ ] Shift-click an item in your bags while the Search tab is open. aux searches for it.
      Alt-click does the same. With the chat box open, Shift-click still links into chat.
- [ ] The window is wider and a buy bar sits under the results. With nothing selected it says
      "Select an auction to buy it".
- [ ] Gear or bags: select a cheap row. The bar shows the item, "6 for sale at this price" and a
      button "Buy for 2g 10s". Click it: **one** item is bought, the count drops by one, and the
      button is ready for the next one. A Bid button appears for auctions that take bids.
- [ ] Your own auction: the bar says it is yours and Buy is disabled.
- [ ] Trade goods (cloth, herbs, feathers): select any row. The bar shows quantity buttons sized to
      the stack (e.g. 1, 5, 10, 20 stack), each with its total cost, plus an Other box. The full
      stack is selected to start.
- [ ] Click each quantity button: the text and the Buy button update ("Buy 20 for 1s 40c").
- [ ] Type a number in Other: the buttons unselect and the cost updates.
- [ ] Press Buy. The button turns green: "Confirm 1s 40c", with Cancel next to it. Nothing is
      bought yet. Press Confirm: "Bought 20 × Light Feather for 1s 40c".
- [ ] Press Buy, then Cancel: "Cancelled, nothing was bought".
- [ ] Type more than is for sale: "Only N for sale" and Buy stays disabled.
- [ ] Check your mailbox: you got exactly the quantity you confirmed, for the price shown.
- [ ] Stop a long search with the stop button, then resume it.
- [ ] Toggle real time mode (the button left of the search box) and run a search. It repeats.

## 4. Full scan
- [ ] Click "Scan" (bottom right). The status bar fills and chat says how many auctions were recorded.
- [ ] Hover "Scan" afterwards. It says when it is available again (15 minutes).
- [ ] Hover items in your bags. The tooltip shows "Value:" with a price.

## 5. Post tab
- [ ] Your auctionable bag items are listed on the left.
- [ ] Shift-click an item in your bags while the Post tab is open. aux selects it.
- [ ] Pick a trade good. Only the buyout price box shows. Existing auctions load on the right.
- [ ] Post a small amount. It appears on the auction house.
- [ ] Pick a piece of gear. Starting price and buyout both show. Post it.
- [ ] Gear with the starting bid equal to the buyout (the default) posts without "Internal auction
      error" and shows up for buyout only. With a lower starting bid it can be bid on.
- [ ] The deposit amount looks right compared to the Blizzard window.

## 6. Auctions tab
- [ ] Your posted auctions are listed.
- [ ] Cancel one.

## 7. Bids tab
- [ ] After bidding on something in step 3, it shows here.

## 8. Window size
- [ ] The window opens wider than before (1100 wide by default).
- [ ] Drag the corner grip at the bottom right. The window grows and shrinks, and it stops at
      the old size as its smallest.
- [ ] While bigger, the Search results, Auctions, Bids and Post lists show more rows, and the
      columns stretch to the new width.
- [ ] Saved Searches: both lists share the width. Filter Builder: the filter text box stretches.
- [ ] Move and resize the window, `/reload`, open the auction house. Same size and place.
- [ ] Double-click the corner grip. The window goes back to the default size.

## 9. New look
- [ ] A bar across the top shows "auxForever", the Search / Post / Auctions / Bids tabs, Full scan,
      Blizzard UI and an × that closes the window. The old tabs under the window are gone.
- [ ] Panels and buttons have rounded corners, and nothing looks cut off or square-cornered.
- [ ] Text uses the new font everywhere (narrow, clean). Nothing overflows its button.
- [ ] Search is an amber button. Selected rows are tinted amber.
- [ ] With nothing selected, the buy bar shows a short explanation instead of an empty box.
- [ ] Trade goods with several sellers at one price say "N sellers" instead of "?".
- [ ] All four tabs, Saved Searches and Filter Builder look right, also at a large window size.

## 10. Post tab (redesigned)
- [ ] Pick a trade good: the item name and "N in your bags · stack of N" show at the top, with
      "Hide from this list" at the top right.
- [ ] Left: Stack size and Stacks with - / + / Max, and Duration as 2h / 8h / 24h buttons. The
      chosen duration is amber and the deposit changes with it.
- [ ] As soon as the listings load, the price is the cheapest listing (that row is highlighted)
      and the line under it says so, even if you used another price for this item before.
- [ ] Right: "Match lowest" is selected. The badge says e.g. "100% of usual".
- [ ] Click "Undercut" (goblin): the price drops 1 copper (trade goods) or 1 silver (gear), and the
      line under it says so. Click "Match lowest" to go back. Undercut is off again every time you
      open the auction house.
- [ ] Hover the "?": it explains matching vs undercutting.
- [ ] Bottom row: "Posting N items" and Total on the left; on the right, next to the amber
      "Post N items" button, the deposit in red ("-25c") and "You get" in green (total minus 5%).
      The Post button fades when posting is not possible.
- [ ] The bar at the bottom left turns gold once the item's listings have loaded, and goes back
      to gray when you switch tabs.
- [ ] Pick a piece of gear: Count instead of Stack size, and two prices, Starting bid and Buyout.
- [ ] Post something small. It appears on the auction house. Refresh is at the bottom left.
- [ ] Filter Builder dropdowns (class, subclass, slot, quality) can be changed.

## 10b. Columns and money details
- [ ] Search, Auctions and Bids tables: Lvl is a narrow first column, then Item. "For sale"
      (Search) or "Quantity" (Auctions, Bids) replaces Auctions and Stack Size and shows units.
- [ ] A search with only trade goods (Light Feather) has no Auction Bid column; a search with gear
      has it.
- [ ] Post tab lists: For sale, Time Left, price, % Hist. Value.
- [ ] Post several items: under "You get" a small line shows the amount per item.
- [ ] Post at a price below what a vendor pays: "You get" turns red and the line says "a vendor
      pays ...".
- [ ] Hover the deposit: a tooltip explains it comes back when the item sells.

## 11. Quick searches
- [ ] Next to `<` on the Search tab is a clock button with a small arrow. Click it: a menu opens
      with Pinned and Recent, and the button turns amber.
- [ ] Each recent row shows the item icon and name, and after a search finishes, "Cheapest ...,
      Xm ago". Searches that cover several items show a funnel icon.
- [ ] Click a row: the menu closes and that search runs.
- [ ] Hover a recent row: a pin appears on the right. Click it: the row moves to Pinned, and it
      also shows on the Saved Searches tab. Click the lit pin to unpin it.
- [ ] Scroll the mouse wheel over the menu to reach older searches.
- [ ] The `<` and `>` arrows are always there. When you cannot go back or forward, that arrow is
      faded and does nothing; the other buttons never shift.
- [ ] Clicking anywhere outside the menu closes it. Switching tabs or closing the window too.

## 12. Background opacity
- [ ] A gear button sits left of Full scan. Click it: a small Settings box opens.
- [ ] Background - / +: steps of 5%. The window and panels let the game show through; text,
      buttons, price boxes and the buy bar stay solid. It stops at 50% and at 100%.
- [ ] The setting is kept after `/reload`. `/aux opacity 85` sets it from chat.
- [ ] Clicking anywhere else closes the Settings box.

## 13. Version 0.2: auction length, favorites, Filter Builder

A guided run through all of this with early Horde items: `docs/test-scenario-0.2.md`.

Needs a full game restart (a new file was added), not just `/reload`.

Settings
- [ ] The gear's Settings box now has "Auction length" with 2h / 8h / 24h. Pick 24h, then select an
      item in the Post tab you have never posted: it starts at 24h. An item you posted before keeps
      the length you used last time.

Favorites
- [ ] Saved Searches, empty search bar, click Favorite: nothing is added and chat says why.
- [ ] Favorite the same search twice: it is added once ("already a favorite").

Filter Builder (Search tab, Filter Builder)
- [ ] Left: "WHICH ITEMS" with Name, Exact, Level from and to, I can use, Category, Type, Slot,
      Rarity. Changing any of them changes the search bar text at once.
- [ ] Right: "ONLY SHOW AUCTIONS WHERE". Click "+ Condition": a menu of every filter in plain
      words opens. Pick "Price per item, at most", type `5g`: the search bar shows `price/5g`.
- [ ] A bad value (e.g. `abc` for a price) gets a red border and stays out of the search bar.
- [ ] Time left and Rarity open a small list of choices instead of a text box.
- [ ] "not" on a row turns red and adds `not/` in the search bar.
- [ ] Match All / Any at the top right switches the search between all and any of the conditions.
- [ ] "+ Group" adds a box with its own All / Any and "not"; "+ Condition" inside it adds to the
      group. A group inside a group works too.
- [ ] The × on a row or a group removes it.
- [ ] "In words" at the bottom reads the whole search back, e.g. "... where price per item is at
      most 5g AND NOT (seller is bob OR time left is 30m)."
- [ ] Type a search in the search bar, then open Filter Builder: the form shows it. Typing in the
      search bar while the builder is open updates the form too.
- [ ] Paste Simon's example `or/and2/profit/5g/percent/60/and3/bid-profit/5g/bid-percent/60/left/30m`
      into the search bar and open Filter Builder: two groups under Match Any.
- [ ] Category, Type and Slot: pick Armor, then Cloth. The search bar shows `armor/cloth`, and a
      search finds cloth armor. (Category names come from the game; check they match.)
- [ ] Clear all empties the form and the search bar. Save to favorites saves the search.
- [ ] Press Search at the top: the results match what "In words" says.

## 14. Version 0.2.1: Search tab details

Needs a full game restart (a new texture was added), not just `/reload`.

- [ ] The search bar has a small magnifier at its left, and typed text starts after it.
- [ ] The three sub tab buttons are a little narrower. After a search, the first one reads
      "Search Results  37" with the number in gold: how many different items were found (for a
      search of one item: how many prices).
- [ ] To the right of the sub tabs: "37 items, 403 for sale, searched just now", or for one item
      "11 price levels, 6,180 for sale". While a search runs it says "still searching"; a minute
      later "searched 1m ago".
- [ ] The line only shows on Search Results, not on Saved Searches or Filter Builder.
- [ ] Shrink the window to its smallest: the line does not overlap the Filter Builder button
      (it may cut off at the end).

Settings and window
- [ ] Gear menu: Background, Scale and Default duration, with no explanation text under them.
- [ ] Scale - and + change the whole window in 5% steps, from 70% to 150%. The window's top left
      corner stays put. After `/reload` the scale, size and position are kept.
- [ ] Single-click the resize corner (bottom right) several times, also right after logging in:
      the window never jumps. Dragging it resizes, double-click goes back to the default size.

Search timing log (for measuring slow searches)
- [ ] Type `/aux debug`: chat says the search timing log is on. Run a broad search (e.g. step 4 of
      the test scenario). When it ends, chat shows where the time went: server answers, the 1s
      fallback, time-outs, the slowest items. Screenshot that and send it. Run the same search a
      second time and screenshot that too. `/aux debug` again turns it off.

Item list measurement (for planning 0.3)
- [ ] At the auction house, type `/aux debug list`. After a while chat says how many items the
      whole auction house has, how long the list took and how many requests it needed. Screenshot
      it. Try it at a busy time and a quiet time if you can.

Blizzard UI button
- [ ] Click Blizzard UI several times, also right after clicking around in aux: the Blizzard
      window opens in front every time, and the button is lit while it is open. Click it again to
      hide it.
- [ ] With the auction house open and the Blizzard window hidden, open and close the character
      sheet (C) and the spellbook (P). Then click Blizzard UI: it still appears on screen (this
      used to send it off screen). If it ever fails, note what you opened just before.

Post tab: trade goods
- [ ] Pick a trade good you have more than one stack of (e.g. 29 Blood Shards). There is one
      "Quantity" box instead of Stack size and Stacks, and it starts at everything you have (29).
- [ ] -, + and typing change it by one; Max goes back to everything. "Posting 29 items" and the Post
      button follow it.
- [ ] Post: one listing of that many shows up on the auction house.
- [ ] Gear still shows "Count" as before.

## Things to note even without errors
- Anything that looks different from how aux worked on Classic.
- Anything slow (searches will be slower than Classic for broad searches, that is expected).
