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
- [ ] Search for something common by name, e.g. `linen cloth`. Results fill in and the status bar moves.
- [ ] Search with a filter, e.g. `armor/cloth/45/50/uncommon`.
- [ ] Exact search: right-click an item in the results. It searches that exact item.
- [ ] Select a gear row (not a trade good). The Bid and Buyout buttons light up. Buy something cheap.
- [ ] Select a trade good row (cloth, herbs, ore). Only Buyout lights up. Buy the cheapest row.
      The quantity shown should land in your mailbox and the gold should match.
- [ ] Stop a long search with the stop button, then resume it.
- [ ] Toggle real time mode (the button left of the search box) and run a search. It repeats.

## 4. Full scan
- [ ] Click "Scan" (bottom right). The status bar fills and chat says how many auctions were recorded.
- [ ] Hover "Scan" afterwards. It says when it is available again (15 minutes).
- [ ] Hover items in your bags. The tooltip shows "Value:" with a price.

## 5. Post tab
- [ ] Your auctionable bag items are listed on the left.
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
