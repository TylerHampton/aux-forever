# Review: Keeping the Sniper running while a deal is selected (0.8.2, H-009)

- **Date:** 2026-11-09 (Tyler's time)
- **Branch:** `claude/magical-maxwell-eyud0b`
- **Commit reviewed:** `49c85ae` (code at `82c546c`, 0.8.2 build 6)
- **Reviewer:** Gemini (Gemini 4 Argon)
- **Scope:** `H-009` in `docs/handoff.md`: why the Sniper stops when a deal is selected, which parts of that stop are still needed, how to keep rounds running safely while a deal is selected, and how to show new deals in the table without moving the selected row or the row under the mouse.

---

## Verdict

Tyler is right: highlighting a row in the Sniper table should not abort the current round or freeze the Sniper on `Holding`. None of the three reasons in the code require stopping the Sniper merely because `checked` is non-nil:
1. **Rounds only need to pause while a request for the selected deal is actively in flight** (`buy_bar.busy() or aux.bid_in_progress() or refreshing`), which lasts less than a second during a re-read or while the player is clicking `Buy` and `Confirm`.
2. **While a deal is selected (`checked`), rounds can keep running in full** (both reading the item list and opening new candidates) as long as `check_list` skips re-opening `checked.deal_key` and gear deals verify `scan.last_read_is` when the player clicks `Buy` rather than when the row is merely highlighted.
3. **The table can show new deals while a deal is selected without moving `checked` by a single pixel** by pinning the rows from row 1 down to `checked` while `checked` is selected (new deals appear immediately below `checked`, and any row above `checked` that sells out dims in place as `gone` until `checked` is let go), and by checking `frame.listing.list:IsMouseOver()` (the rows area) instead of `frame.listing:IsMouseOver()` (which also covers the buy bar).

---

## Answers to the 3 Questions in H-009

### 1. Which of the three reasons still need the full stop, given build 3's re-read rule for gear?

None of the three reasons need a full stop during the idle selection state (`checked ~= nil` with `not refreshing and not buy_bar.busy() and not aux.bid_in_progress()`):

- **Reason 1 (0.4.1 `[Seen]`: gear deals could not be bought from the Sniper after rounds searched other items):**
  - **Trade goods (commodities):** Do **not** need this stop at all. Commodity purchases use `C_AuctionHouse.StartCommoditiesPurchase(itemID, quantity)` followed by `ConfirmCommoditiesPurchase(itemID, quantity)` (`[Code]`, `[Seen]`), which worked in 0.4.1 even while rounds searched other items (`tabs/sniper/core.lua:676-677`).
  - **Gone deals (`record.deal_gone`):** Cannot be bought and only show a note in the buy bar, yet selecting one today sets `checked` and stops the Sniper (`tabs/sniper/core.lua:585, 765-766, 860-862`).
  - **Gear and other non-commodity items:** `C_AuctionHouse.PlaceBid(auctionID, buyoutAmount)` must be called synchronously inside a hardware mouse click (`aux-addon.lua:200-210` `[Code]`), and in 0.4.1 (`[Seen]`) it did nothing when other searches had run after the item's own `SendSearchQuery(itemKey)`. Under build 3, `refresh_deal` runs when the gear row is **selected** (`SetSelectedRecord`), and then enables the 1-click `Buy for Xs` button. If a round kept running *after* `refresh_deal` finished on selection, the round's next `SendBrowseQuery` (`core/scan.lua:404`, which sets `last_read = nil`) or `SendSearchQuery` (`core/scan.lua:461`) would overwrite `last_read` before the player clicked `Buy for Xs`.
  - **Why Reason 1 still does not require stopping on selection:** If a gear deal is checked when the player clicks `Buy for Xs` (when `not scan.last_read_is(item_key)` or older than `FRESH_SECONDS`), instead of when the player merely highlights the row, rounds can keep running freely while a gear row is highlighted (see **Finding 2**).

- **Reason 2 (A purchase talks to the auction house under the same request limit as the rounds' searches):**
  - **While a row is merely highlighted (`checked`):** Zero purchase requests are sent. When the deal is fresh (`<= FRESH_SECONDS`, which covers deals clicked right after the alert sound), zero re-read requests are sent either.
  - **When a re-read or purchase is actually in flight (`refreshing or buy_bar.busy() or aux.bid_in_progress()`):** `core/scan.lua` has a single module-level `state` (`core/scan.lua:23, 159-167`), so only one `scan.start` coroutine can run at a time, and purchase calls share `C_AuctionHouse`'s message throttle (`[Code]`). Pausing the round during `refreshing`, `buy_bar.busy()`, and `aux.bid_in_progress()` is still needed and lasts only for the active check or purchase.

- **Reason 3 (A round could replace the deal being bought):**
  - If a round opens `checked.deal_key` in `check_item` (`tabs/sniper/core.lua:340-343`), it removes `old` from `deals` and inserts a new `cheapest` table. Then `listing:SetDatabase(shown)` (`gui/auction_listing.lua:1083-1117`) no longer finds `prev_selected` in `self.records`, falls back to `prevSelectedIndex`, and selects a **different item's row**, switching the buy bar to another item.
  - **Why Reason 3 does not require stopping the round:** Having `check_list` skip `checked.deal_key` while `checked` is selected (without setting `known[key] = price`) prevents `checked` from ever being replaced while selected (see **Finding 1**).

---

### 2. A design that keeps rounds going while a deal is selected, with what it costs

Comparing the three options named in `H-009`:

| Design option | What runs while `checked` is selected | Request cost | Risk to purchases | Verdict |
|---|---|---|---|---|
| **A. Item list only during selection (no opening of candidates)** | `SendBrowseQuery` (16 requests, ~8.5s `[Seen]`), but `check_list` opens 0 candidates | 16 browse requests per round; 0 item searches | **Breaks gear `last_read` anyway** (`SendBrowseQuery` sets `last_read = nil` in `core/scan.lua:404`), and **finds 0 deals** while a row is selected because deals are only added and alerted after `check_item` opens them (`core.lua:15-16, 343-350`). | **Do not use.** |
| **B. Full rounds that skip `checked.deal_key`; pause only during `refreshing`, `buy_bar.busy()`, or `aux.bid_in_progress()`; gear re-reads on `Buy` -> `Confirm` when `not scan.last_read_is`** | Full browse list + `check_item` for all other candidates; new deals appear and alert normally | **0 extra requests** when highlighting a row; 1 request (~0.4s) only when buying a stale deal or a gear deal after other searches | **None.** Commodity quotes and gear `Confirm` both pause the round while buying and never spend more than shown. | **Recommended (Findings 1 and 2).** |
| **C. Full rounds while a commodity or gone deal is selected; hold only while a live gear deal is selected** | Full rounds during commodity/gone selection; stops on live gear selection | 1 request on gear selection when `not scan.last_read_is` | **None**, keeps 1-click gear buying in all cases, but clicking a gear row still stops the round and shows `Holding`. | **Fallback** if Tyler rejects a `Confirm` click on gear when `not scan.last_read_is`. |

---

### 3. The table: how to show new deals during a selection without moving the selected row or the row under the mouse

Today, two things make the table feel frozen or jumpy:
1. `frame.listing:IsMouseOver()` in `tabs/sniper/core.lua:608` checks `frame.listing`, which spans `aux.frame.content` (`tabs/sniper/frame.lua:20-21`) and includes **both** the rows (`frame.listing.list`) and the buy bar (`buy_bar.attach(frame.listing)` at `core.lua:630`). While the player's cursor is on the buy bar, `frame.listing:IsMouseOver()` is true and new deals never appear in the table.
2. When `update_deals()` does run while `checked` is selected, `Found` descending (`tabs/sniper/frame.lua:80-86`) puts newly found deals at row 1 (pushing `checked` down) and moves any older deal above `checked` that became `deal_gone` to the bottom (pulling `checked` up).

**Solution (Finding 3):**
- Check `frame.listing.list:IsMouseOver()` (the rows area only) at `tabs/sniper/core.lua:608`, so the row under the mouse never moves while the cursor is in the table, and new deals appear while the cursor is on the buy bar or elsewhere.
- When `checked` is selected, pin the current visual order of rows `1..k` (from row 1 down to `checked`) with a `deal_pin` index:
  - Rows `1..k` (ending at `checked`) stay at their exact row numbers `1..k` even if one of the rows above `checked` turns `deal_gone` (it dims in place as `gone` and sinks to the bottom only after `checked` is deselected).
  - Any new deal found while `checked` is selected sorts immediately below `checked` (starting at row `k + 1`, newest first).
  - When `checked` is bought or deselected, clear `deal_pin` so all deals return to normal `Found` order.

---

## Numbered Findings

### Finding 1: Remove `or checked` from `M.update` and `M.status`, and skip `checked.deal_key` in `check_list` while a live deal is selected
- **Where:** `auxForever/tabs/sniper/core.lua:440-461, 478-485, 585-592, 656-662`
- **What:**
  1. In `M.update()` (`core.lua:585`), change:
     `if running and (buy_bar.busy() or aux.bid_in_progress() or refreshing or checked) then`
     to:
     `if running and (buy_bar.busy() or aux.bid_in_progress() or refreshing) then`
     and remove the `elseif checked then return 'Holding', ...` branch in `M.status()` (`core.lua:660-661`).
  2. In `check_list` (`core.lua:440`), skip opening the currently selected live deal:
     `local holding_key = checked and not checked.deal_gone and checked.deal_key`
     `if not aux.account_data.sniper_ignored[key] and known[key] ~= price and key ~= holding_key then`
     Because `known[key]` is not updated when `key == holding_key`, the Sniper will check `key` on the next round after `checked` is deselected or bought.
  3. In `mark_gone(seen)` (`core.lua:478-485`), do not mark `checked` as gone while a purchase or refresh is actively running for it (`deal == checked and (buy_bar.busy() or aux.bid_in_progress() or refreshing)`). If `checked` is idle (`not buy_bar.busy()`), and `mark_gone` marks `checked` as gone because its lowest price on the browse list rose above `ceil(checked.unit_buyout_price)` or vanished, also update the buy bar (`show_deal(checked)`) so the player sees `Gone: sold or relisted` right away instead of clicking a stale `Buy` button.
- **Why it matters to a player:** Clicking a deal (or clicking a `gone` row, or selecting a row to click `Ignore item`) no longer aborts the current round or freezes the Sniper. Other candidates in the same round finish opening, and subsequent rounds keep finding deals.
- **How sure:** Certain.

**Claude's answer (2026-11-09, 0.8.2 build 7): partly built.** Checked in `tabs/sniper/core.lua`.
- Built: a selected deal that can still be bought is not opened by the rounds (`selected_live_key`),
  and not marked judged, so the first round after it is let go opens it. Skipped in two places: the
  item list pass, as proposed, and again just before each candidate is opened, since the player can
  select a deal while the round opens the ones before it (removing both fails two checks; removing
  either one alone is caught by the other). Built: when a round marks the selected deal gone and
  nothing is being bought, the buy bar says "Gone: sold or relisted" at once (`mark_gone`).
- Built only in part: the hold. `or checked` became `holding()`: a selected trade good or gone
  deal no longer holds the rounds, a selected live gear deal still does, and the status says
  "Holding" only then. This is your option C. Removing the gear hold as well needs finding 2, and
  without it the 0.4.1 failure comes back (a round's search between the gear deal's read and Buy).
- Not added: a separate guard in `mark_gone` for a deal being bought. While anything is bought or
  read again, `M.update` stops the round on the next frame and `refresh_deal` stops it before its
  own search, so a round rarely ends then; if one does, the buy bar is left alone (the
  `not buy_bar.busy()` check) and the purchase still only goes through at a server price at or below
  the one shown.
- Tests: `H-010: rounds go on while a trade good or a gone deal is selected` (load test) and
  `timing: Sniper buys a selected trade good while a round runs` (slow auction house: Buy clicked
  mid-round, the round stops before the price is asked, nothing else is sent between the price and
  the purchase, 5 bought at the price shown, rounds go on after). Each checked to fail with the old
  hold put back.

---

### Finding 2: Defer gear's `refresh_deal` re-read to the `Buy` / `Bid` click when `not scan.last_read_is(item_key)` (or `> FRESH_SECONDS`) so selecting a row never aborts an active round
- **Where:** `auxForever/tabs/sniper/core.lua:688-770, 812-849` and `auxForever/gui/buy_bar.lua:289-340, 461-479`
- **What:**
  - Today, selecting any row in the Sniper table calls `show_deal(checked)` -> `refresh_deal(record)` (`core.lua:688-700`). If `record` is a gear deal and the round opened even one other candidate after it (`not scan.last_read_is(item_key)`), or if `record` is `> 15s` old, `refresh_deal` immediately calls `scan.abort()` and `scan.start` on row selection.
  - Furthermore, once `or checked` is removed from `M.update()` (Finding 1), re-reading a gear deal on *row selection* no longer guarantees `scan.last_read_is(item_key)` is true when the player clicks `Buy for Xs` a few seconds later, because an ongoing or subsequent round will call `SendBrowseQuery` (`core/scan.lua:404`, setting `last_read = nil`) or `SendSearchQuery` on another item before the player clicks `Buy for Xs`.
  - **How to handle both commodities and gear cleanly:**
    1. **On row selection (`show_deal`):**
       - Never abort an active round on row selection. Show the buy bar immediately (`show_commodity_bar(record)` or `show_item_bar(record)`).
       - For a commodity deal older than `FRESH_SECONDS`, either refresh it when `not active` (between rounds) or when `Buy` is clicked, or let `refresh_deal` run on `Buy` before `StartCommoditiesPurchase`.
    2. **On `Buy` / `Bid` for a gear deal (`show_item_bar` / `buy_bar`):**
       - When the player clicks `Buy for Xs` (or `Bid`):
         - If `record.deal_read_at and GetTime() - record.deal_read_at <= FRESH_SECONDS and scan.last_read_is(item_key)` is **true**: call `aux.place_bid(record.auction_id, record.buyout_price, ...)` immediately inside that click handler (1 click, 0 extra requests).
         - If `not scan.last_read_is(item_key)` or `GetTime() - record.deal_read_at > FRESH_SECONDS`: start `refresh_deal(record)` (which sets `refreshing = record`, aborts the background round, and sends 1 `SendSearchQuery(item_key)` request taking ~0.4s `[Seen]`). When `on_complete` finds the auction at `<= record.unit_buyout_price`, put the item buy bar into a `QUOTED` / `Confirm Xs` state (green `Confirm` button + `Cancel` button, with `buy_bar.busy() == true` so no new round starts and `scan.last_read_is(item_key)` stays true; auto-reset if not confirmed within 15s). The player's click on `Confirm Xs` is a hardware event (`[Code]`) and calls `aux.place_bid(record.auction_id, record.buyout_price, ...)` with `scan.last_read_is(item_key)` guaranteed true.
  - **Note on existing tests:**
    - `tests/load_test.lua:1744-1755` (`sniper round`) and `tests/load_test.lua:5115-5122` (`fb028`) currently assert that `SetSelectedRecord` triggers `refresh_deal` before `bar.primary_click()`. If `refresh_deal` moves to `primary_click()`, update those two test blocks to click `bar.primary_click()` (or if `refresh_deal` still runs on selection when `not active` and re-checks on `primary_click()` if a round ran since, both old and new flows work).
- **Why it matters to a player:**
  - Highlighting a row in the table never aborts a round and never wastes a request if the player does not buy it.
  - Buying a gear deal never silently fails (`0.4.1` `[Seen]`), even if a background round ran while the player was looking at the deal.
  - Buying never spends more than the shown price.
- **How sure:** High.

**Claude's answer (2026-11-09): not built; a disagreement for Tyler.** The analysis is right: with
the gear hold gone, a gear deal's read on selection no longer lasts until Buy. What I disagree with
is the cost:
- With rounds running, nearly every gear deal is stale by the time Buy is clicked: a new round
  starts 2.5 seconds after the last one ends, and its item list clears `last_read`. So the "fresh,
  one click" case would rarely apply, and most gear buys would become Buy, wait for the answer (a
  second or more on Forever's server, `AGENTS.md`, Timing; the 0.4 second figure has no recorded
  source here), then Confirm. Today it is select, then Buy. For a sniper the gear purchase is the
  moment speed matters most.
- It adds a confirm state with a time limit to the gear buy bar, the code that keeps the "never
  spend more than shown" guarantee.
- What it removes is the hold while a gear row is selected, which the player ends with one click
  (or a purchase).
- Kept for trade goods: a deal older than 15 seconds is still read again on selection (one request;
  the round stops for it and the rounds go on after), because 4 of 5 trade good buys failed in
  0.4.1 on old counts (Seen). Moving that read to Buy would add the same wait there.
- Label: "PlaceBid must be called from a click" is aux's own code comment (`aux-addon.lua`), not
  checked against Blizzard's code in this review; the 0.4.1 cause is an inference (Seen: Buy did
  nothing; not seen: why).
Both positions go to Tyler: option C (built: gear holds while selected, buying stays select + Buy)
or option B (this finding: nothing holds, gear buys usually need Buy then Confirm).

---

### Finding 3: Pin rows `1..k` up to `checked` (`deal_pin`) while a deal is selected, check `frame.listing.list:IsMouseOver()`, and do not reselect by row index in `SetDatabase` when `one_row_each` is true
- **Where:** `auxForever/tabs/sniper/core.lua:608, 858-867`, `auxForever/tabs/sniper/frame.lua:23-27, 80-86`, and `auxForever/gui/auction_listing.lua:1104-1117`
- **What:**
  1. **Hover check on the rows frame, not the outer content panel (`tabs/sniper/core.lua:608`):**
     Change `not frame.listing:IsMouseOver()` to `not frame.listing.list:IsMouseOver()`. `frame.listing` includes the buy bar at the bottom (`tabs/sniper/frame.lua:20-27`, `core.lua:630`), so hovering over the buy bar currently blocks table updates. Checking `frame.listing.list:IsMouseOver()` blocks row updates only while the cursor is over the table rows.
  2. **Pin rows `1..k` up to `checked` while `checked` is selected (`tabs/sniper/core.lua:858-867`, `tabs/sniper/frame.lua:80-86`):**
     - When `checked` is selected in `update_selection()`, assign `deal_pin = 1, 2, ..., k` to the records currently shown in `listing.rowInfo` from row 1 through `checked` (and `nil` on all other records). When `checked` is cleared (`checked = nil`), clear `deal_pin` on all deals and set `deals_changed = true`.
     - In `Found`'s comparator (`tabs/sniper/frame.lua:80-86`), check `deal_pin` first:
       ```lua
       cmp = function(a, b, desc)
           if a.deal_pin or b.deal_pin then
               if a.deal_pin and b.deal_pin then
                   return sort_util.compare(a.deal_pin, b.deal_pin, false)
               end
               return a.deal_pin and sort_util.LT or sort_util.GT
           end
           if not a.deal_gone ~= not b.deal_gone then
               return a.deal_gone and sort_util.GT or sort_util.LT
           end
           return sort_util.compare(a.deal_found, b.deal_found, desc)
       end,
       ```
     - With this rule:
       - Selecting row `k` never moves row `k` or any row `1..k-1` above it.
       - If a row in `1..k-1` turns `deal_gone` while `checked` is selected, it dims in place as `gone` without jumping to the bottom, so `checked` does not shift up.
       - Any new deal found while `checked` is selected has `deal_pin == nil` and `deal_gone == nil`, so it appears immediately at row `k + 1` right below `checked`.
  3. **No fallback to `prevSelectedIndex` / `rows[1]` in `SetDatabase` when `one_row_each` is true (`gui/auction_listing.lua:1104-1117`):**
     In `SetDatabase`, lines 1104-1117 (`if not self.selected and prevSelectedIndex then ...`) reselect whatever record sits at `prevSelectedIndex` (or `rows[1]`) when `prev_selected` is removed. In the Search tab, rows are auctions of the searched item; in the Sniper tab (`self.one_row_each == true`), every row is a different deal, so falling back to `prevSelectedIndex` when a deal is removed (e.g. `Ignore item`) automatically selects another deal and triggers `show_deal` on it. Guarding lines 1104-1117 with `if not self.one_row_each and not self.selected and prevSelectedIndex then` prevents an unselected or ignored deal from jumping the selection onto the next row.
- **Why it matters to a player:** While a player has a deal selected and is moving to the buy bar, the selected row stays at its exact position on screen, new deals still appear right below it, and ignoring or finishing a deal never jumps the highlight onto a random other item.
- **How sure:** Certain.

**Claude's answer (2026-11-09, 0.8.2 build 7): built, with three changes.**
- Hover: built as proposed (`frame.listing.list:IsMouseOver()`).
- Pinning: built in the table's own sort (`row_pin` in `sort_helper`, `gui/auction_listing.lua`),
  not in Found's comparator. The player can sort by any column; Found's comparator is then only a
  tie-breaker and the pin would not hold (the test sorts by Price each). Two more ways the selected
  row moved up, found while building: a pinned row above it read again by a round is a new record
  (it now takes the old one's pin, `check_item`), and trimming to 100 deals dropped the oldest even
  when pinned (`trim_deals` now skips the selected and pinned rows).
- The `SetDatabase` fallback: not by `one_row_each`. The Auctions and Bids tabs are `one_row_each`
  too, and they read their lists as new records every time, so this fallback by row position is
  what keeps their selection across a refresh. The Sniper sets its own flag,
  `keep_selection_only`.
- Test: `H-010: the selected row keeps its place while deals come and go` (a new deal goes in
  below the selected row, a sold row above dims in place, a row above read again keeps its place,
  sorting by another column keeps them, letting go sorts as usual, Ignore selects nothing else,
  trimming keeps pinned rows), plus the hover checks in the gear test. Each part checked to fail
  without its change.
