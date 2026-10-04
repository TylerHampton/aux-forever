# Testing checklist

Do these in order. After each step, if BugSack shows an error, copy the full error text
(BugSack lets you select it) and send it over. One error at a time is fine.

## 1. Loading
- [ ] Log in. Chat shows `<aux> loaded - /aux`.
- [ ] Type `/aux`. A list of settings prints in chat.

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
- [ ] The deposit amount looks right compared to the Blizzard window.

## 6. Auctions tab
- [ ] Your posted auctions are listed.
- [ ] Cancel one.

## 7. Bids tab
- [ ] After bidding on something in step 3, it shows here.

## Things to note even without errors
- Anything that looks different from how aux worked on Classic.
- Anything slow (searches will be slower than Classic for broad searches, that is expected).
