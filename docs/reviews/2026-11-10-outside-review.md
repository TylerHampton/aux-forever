# Outside review of auxForever at 0.8.2

Date: 2026-11-10 (Tyler's date). Reviewer: Claude, asked by Tyler to act as an outside expert at a
checkpoint in development. Read at: `main`, commit `5194560` (tag `v0.8.2`).

This file is written for the engineer who will fix things (Tyler plans to hand it to the primary
engineer in a new session) and follows the project's review rules (`AGENTS.md`, "Roles"): each finding is a claim
to check, with where it is, why it matters to a player, how sure I am, a proposed fix and a test.
Answer each finding under it (fixed with its commit, not reproduced, or not worth its cost and why).

**Answered on 2026-11-10:** Tyler then asked the reviewer to build the fixes in the same session.
They are 0.8.2.1 builds 1 and 2; the answer under each finding says what was done. After build 2
(Tyler said yes to R-10 and R-19 and asked for everything that could be done without him): 21
fixed, 4 in part (R-16, R-20, R-23, R-25), 3 not built (R-05 and R-27 wait for Tyler in the game,
R-28 is for a later version). Build 2 also holds a second pass over the files this review only
skimmed; see "Second pass" at the end.

## Verdict

The parts that spend a player's money are sound, and the project's habits (a facts file with labels,
a fake slow auction house in the tests, rules against per-frame work) are better than in most
addons. The weak spots are elsewhere:

1. **The Sniper trusts one bad answer too much.** A single round in which the auction house does not
   send the item list marks every deal as gone, and they stay gone (R-01, confirmed). Deals are also
   not judged again when the price history changes under them (R-03, confirmed).
2. **A list that only partly arrived is treated as the whole list**, without a word, in the Search
   tab, the Post tab, the Auctions tab's price check and the Sniper (R-02).
3. **The Full scan is slower than it needs to be** because its reading is tied to the frame rate,
   and it creates a large amount of temporary memory (R-07, R-08, measured in the test harness).
4. **The tests cannot catch a misspelled game function or enum**, and one test leaves the Bids tab
   broken for every test after it, which hid a real error (R-04, R-21, R-22).
5. **The docs the next agent is told to trust are one release behind** (R-26).

Nothing in the addon was changed by this review, so there is no new build to install.

## How the review was done

- Read in full: `libs/package.lua`, `compat.lua`, `aux-addon.lua`, `control.lua`, `util.lua`,
  `frame.lua`, `gui/core.lua`, `gui/buy_bar.lua`, `gui/auction_listing.lua`, `core/scan.lua`,
  `core/history.lua`, `core/cache.lua`, `core/api.lua`, `core/tooltip.lua`, `core/shortcut.lua`,
  `core/slash.lua`, `util/info.lua`, `util/filter.lua`, `util/money.lua`, `util/persistence.lua`,
  `util/sort.lua`, `util/completion.lua`, `util/scan.lua`, `tabs/post/core.lua`,
  `tabs/search/results.lua`, `tabs/search/saved.lua`, `tabs/search/recipe.lua`,
  `tabs/search/crate.lua`, `tabs/sniper/core.lua`, `tabs/auctions/core.lua`, `tabs/bids/*`,
  `gamepad.lua`.
- Skimmed only: the widget files of the tabs (`*/frame.lua`), `tabs/search/quick.lua`,
  `tabs/search/filter.lua`, `tabs/search/builder.lua`, `gui/listing.lua`, `gui/item_listing.lua`,
  `color.lua`, `core/disenchant.lua`. The test file was read for its setup and structure, not line
  by line. `docs/feedback.md` was not read in full.
- Ran the tests in both looks and the syntax check: all pass (`done, errors: 0`).
- Ran small experiments on a scratch copy of `tests/load_test.lua` (outside the repository) to
  confirm suspected defects. "Confirmed" below means one of those experiments showed it; the two
  that make ready-made failing tests are in the appendix.
- Not possible from here: running the game. Nothing below was seen in game. Statements about how
  Forever's auction house behaves carry the labels of `docs/forever-auction-house.md`. Blizzard's
  code was not read again in this pass; where a claim rests on general knowledge of the modern
  client it is labeled Outside.

Priorities: **P1** a player can hit it in normal use and gets wrong information or an error.
**P2** wrong when the server is slow or over months of use, or costs noticeable time. **P3** small,
protective, or cleanup.

## Findings: defects

### R-01 (P1) Sniper: one round without an item list marks every deal gone, for good

- Where: `tabs/sniper/core.lua:545-556` (`on_complete` calls `mark_gone(seen)` whenever
  `last_count` is set, and `last_count` is kept from earlier rounds), `core/scan.lua:838-839`.
- What happens: when the item list request gets no answer (20 seconds, `request` in
  `core/scan.lua`), `on_item_list` never runs, so `seen` is empty, and `mark_gone` then marks every
  deal as gone. On the next rounds those items are not opened again because `known[key]` still
  equals their price (`check_list`, line 473), so they stay "Gone: sold or relisted" while still
  for sale, until their price changes or a setting is touched.
- A second effect: the scan prints "the auction house did not respond to the search" in chat even
  for a quiet scan (`core/scan.lua:839` and `:865` ignore `params.quiet`), so a player watching the
  Sniper gets a line about a search they did not start.
- How sure: confirmed (appendix, experiment A).
- Why it matters: the project's own notes say the server has been slow since launch (FB-027,
  FB-037). The Sniper is the tab that runs requests all the time, so it is the most likely to meet
  an unanswered one.
- Fix: a round only marks deals gone when its own item list arrived, and arrived completely (see
  R-02). Keep a flag set in `on_item_list`. Respect `quiet` for the two chat lines.
- Test: the appendix scenario in `tests/load_test.lua`; a slow-server variant in
  `tests/timing_test.lua` where one round's list is never answered and the next one is.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. A round marks deals gone only when its own item list arrived whole (`start_round` in `tabs/sniper/core.lua`); the two chat lines respect `quiet` (`note_list` in `core/scan.lua`). Test `timing: R-01 R-02 a Sniper round without the whole item list keeps the deals`: an unanswered round, a cut list, and a deal that really sold is still found gone.

### R-02 (P1) An item list that only partly arrived is used as if it were complete

- Where: `core/scan.lua:409-415` (`browse_results`): when a request for more results fails, the loop
  stops and whatever arrived is returned. Nothing is counted (`note_unread` is for single items)
  and nothing is said.
- Consequences, each read in the code, none seen in game:
  - Search tab: fewer items than are listed, with the status bar gold as for a finished search. This
    is the same kind of silence FB-014 was fixed for.
  - Sniper: every deal past the cut is marked gone (`mark_gone`), and stays gone as in R-01.
  - Post tab, gear: the name search reads only the versions that arrived, then `on_complete` sets
    `listings_ready` (`tabs/post/core.lua:1005`) and the automatic price is picked from part of the
    listings. Review H-006 finding 2 closed this hole for a stopped search but not for a cut list.
  - Auctions tab: `check_prices` writes `checks[key] = found[key] or {at_price = {}}` for every
    wanted key (`tabs/auctions/core.lua:153-155`), so gear whose versions were past the cut reads
    "Lowest" or "Only one listed" when it may be undercut.
- Fix: `browse_results` returns a second value, complete or not. `scan()` keeps it on the scan's
  result. Then: the search says so when it ends (one line, like `unread_text`); the Sniper skips
  `mark_gone` and leaves the missing items unjudged; the Post tab treats it as a stopped read
  (`listings_stopped`, no automatic price); the Auctions check keeps the old status for keys it
  found nothing for.
- Test: `tests/slow_server.lua` gets a way to fail the second page of a list; one test per consumer
  in `tests/timing_test.lua`.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. `browse_results` returns whether the whole list arrived, and `on_complete` is handed a result with `no_list`, `partial_list` and `unread` (`scan.saw_everything(result)` asks all three). The Search tab says it in chat and on the results line, Live mode keeps its table through such a round (it emptied it when no list came), the Post tab treats it as a stopped read, the Auctions check keeps "Not checked". The Post tab and the Auctions check also count an item that could not be read (`unread`), which had the same effect. Four tests in `tests/timing_test.lua` (`R-02 ...`); `tests/slow_server.lua` learned `page_size`, `more_silent` and `browse_silent`.

### R-03 (P1) Sniper: an item is not judged again when its price history changes

- Where: `tabs/sniper/core.lua:473` (an item is judged only when `known[key] ~= price`) and `:491`
  (`known[key] = price` when it is refused against the usual price). `known` is cleared only by
  `settings_changed` and `unignore_all`.
- What happens: the facts an item was judged with (usual price, days of complete looks) change
  without its listed price changing, in two ordinary cases:
  - A Full scan finishes: today now counts as a day of complete looks
    (`history.value_and_complete_days`), so an item refused for having 2 days now has 3.
  - Midnight passes: the usual price of every item takes in the day that ended.
  In both, items already judged keep their old verdict until their lowest price moves.
- The case a player meets: on the third day of use (the day the notice says deals against the usual
  price start), pressing Start before the Full scan judges everything with 2 days. After the Full
  scan nothing already listed becomes a deal. Touching a Sniper setting makes them all appear.
- How sure: confirmed (appendix, experiment B).
- Fix: clear `known` when a Full scan's prices come in (the `scan.on_full_scan_view` handler already
  notices a new scan by its `at`) and when `history.today()` differs from the day of the last round.
  Rounds wait during a Full scan, so nothing runs between the clear and the new prices.
- Test: experiment B as a test.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. `known` is cleared when a Full scan's prices come in and on a new day (`forget_on_new_day`). Test in `tests/load_test.lua` (`outside review: R-03 R-04 R-06`), with a real small Full scan as asked.

### R-04 (P1) Bids tab: Bid and Buyout raise an error when nothing is selected

- Where: `tabs/bids/core.lua:42` (`listing:GetSelection().record`), `:65` (`on_update` sets the
  two buttons only while there is a selection).
- What happens: select a bid, then click it again to let go (the click standard in
  `docs/clicks.md`), or the list refreshes and the row is gone. The buttons keep the state of the
  last selection. A click on Bid or Buyout, or the gamepad's Y (it presses `buyout_button` when it
  is enabled, `gamepad.lua:300-314`), then indexes nil: a BugSack error.
- How sure: read in the code. The harness cannot show it today because of R-21.
- Fix: disable both buttons when there is no selection, and return early in `place_bid`.
- Test: after R-21 is fixed: select, let go, check both buttons are disabled; call the click and
  check nothing reaches `C_AuctionHouse.PlaceBid`.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. Both buttons fade with nothing selected and `place_bid` returns early. Test in the same block; it could only be written after R-21.

### R-05 (P2) A search can take results the game already held as the answer after 1 second

- Where: `core/scan.lua:294-306` (`request`) with the `cached` checks at `:469-471` and `:490-493`.
- What happens: if no result event arrives within 1 second and the game still holds results for
  that item from an earlier search, those are used. The comment gives the reason: the game does not
  always fire the event again for results it already holds. The code cannot tell that case from
  "the server has not answered yet". When the server takes longer than a second, a second look at
  an item can return the first look's listings.
- Who is affected if so: the Post tab's Refresh and its automatic price (0.6.0.2 was built so every
  pick reads the listings fresh), today's market price written by `record_view`, the Auctions tab's
  undercut check, the re-read of a Sniper deal. Buying is not at risk: a trade good's price is
  confirmed against a server quote, and gear has a fixed buyout.
- How sure: the code path is certain. Whether it happens in play is Unknown. It is the same family
  as experiment E7 in `docs/forever-auction-house.md`.
- Measure first: `/aux debug` already prints "N after the 1s fallback" after each search. One such
  line from Tyler on a busy day, for a search of an item searched a few minutes earlier, says how
  often this path is taken.
- Possible fix, to decide after measuring: remember when each item's results were last confirmed by
  an event; take held results after 1 second only when they were confirmed within the last minute,
  otherwise wait several seconds more before using them.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Not changed: measure first, as the finding says. One more data point from the old notes: on 2026-10-04 Tyler's `/aux debug` line for 335 items read "336 answers on time, none after the 1s fallback" (`docs/status-history.md`), so before launch this path was not taken at all. A line from a busy day since launch is question 2 for Tyler in `docs/status.md`.

### R-06 (P2) `/aux clear post` clears nothing for the session and loses later settings

- Where: `core/slash.lua:157-159` replaces `aux.faction_data.post` with a new table;
  `tabs/post/core.lua:121-123` keeps its own reference `data` from login.
- What happens: the Post tab goes on reading and writing the old table. The saved file now holds
  the new, empty one, so every price and duration remembered after the command is lost at logout,
  and nothing looks cleared until then.
- How sure: confirmed by experiment (the module's `data` is still the old table after the command).
- Fix: empty the table in place (`aux.wipe`), or give the Post tab a function that does it.
- Test: write a setting, run the command, check `read_settings` gives the defaults and that a
  setting written afterwards is in `aux.faction_data.post`.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed (`aux.wipe` in place). Test in `outside review: R-03 R-04 R-06`.

## Findings: speed and memory

### R-07 (P2) Full scan: reading is tied to the frame rate

- Where: `core/scan.lua:761` (one pause every 100 auctions, whatever they cost),
  `core/history.lua:467` (every 200 items when the prices are written),
  `tabs/sniper/core.lua:496` and `core/scan.lua:673` follow the same pattern.
- Measured in the test harness (game calls are stubs, so real cost per auction is higher): 200,000
  auctions of 6,000 items took 2,052 frames and 4.8 seconds of processor time in total. A reading
  frame did 100 auctions in about 2.3 ms and then sat idle; the closing frames that write prices
  averaged 5.5 ms with single frames above 20 ms.
- Tyler's own line (`docs/status.md`, 2026-11-09, Seen): 215,090 auctions in 50.5 s, of which 2.0 s
  was the list arriving. About 2,150 frames in about 48 s fits "100 auctions per frame" exactly:
  the scan's length is set by the frame count, not by the work.
- Fix: pause by time, not by count. The thread runner in `control.lua` notes when it resumes a
  thread; a helper (say `aux.coro_budget(ms)`) yields once that many milliseconds of the frame are
  used. Use it in the Full scan's two loops, `history.finish_collector`, `scan_item_list` and the
  Sniper's `check_list`. Start with about 8 ms and let Tyler judge how the game feels during a scan.
  The clock would be `debugprofilestop()` (Outside: present on the modern client; check on Forever
  with `/run print(debugprofilestop())`), with today's counts as the fallback when it is missing.
- Expected effect, an estimate from the harness numbers, not a promise: the reading part several
  times shorter at the same smoothness, and no long frames at the end. This is FB-027.
- Test: a `per-frame work` style test that a scan of N auctions needs far fewer frames when each
  auction is cheap, and that no frame runs past the budget by more than one auction's work.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. `aux.coro_due(i, every)` and `aux.coro_slice` in `control.lua`, `SLICE_MS = 8`; used by the Full scan's two loops, `history.finish_collector` and the Sniper's `check_list`. `scan_item_list` keeps its count: its pause is tied to redrawing the table every 100 items. Without `debugprofilestop` the old counts apply, so the worst case is today's speed. Harness, 200,000 auctions with R-08: 2,052 frames before, 145 with a clock, longest frame 30 ms before and 9 ms after. In game: step 1 of the build 1 checklist.

### R-08 (P2) Full scan: a full display record is built for every auction and thrown away

- Where: `util/info.lua:328-346` (`replicate_record`) through `new_record`, `set_prices` and
  `signatures` (`:139-146`).
- What happens: for each auction the scan parses the link into a table, asks the game whether the
  player can use the item, fills about 25 fields and builds two signature strings. The Full scan
  uses four things: item ID, the name (for the price key), the count and the buyout
  (`history.process_auction`, `history.collect`); `frame.lua` only counts the records.
- Measured in the harness: about 3.4 KB of temporary memory per auction (this includes the test
  stubs' own strings). Over 200,000 auctions that is several hundred MB for the game's memory
  cleanup to work through during the scan.
- Fix: a lean path for `get_all`: read the values, find the price key (keep it per link text or per
  item ID and name, so it is worked out once per item, not once per auction) and hand unit price
  and units straight to the history code. Build no record. Separately, `signatures` could be made
  on first use for every kind of scan.
- Test: the Full scan tests already check what is recorded; add a check that a Full scan creates no
  auction records (count calls into `new_record` through a test hook).

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. Without an `on_auction` callback the Full scan builds no record: `info.replicate_reader()` returns price key, buyout, count and item ID, and keeps each item's price keys for the length of one scan. `history.process_price` and `history.collect_price` take plain numbers. The top bar's button uses `on_progress(done, total)`, called once per pause; it had redrawn the status bar for every auction, a cost the harness cannot see. A caller that passes `on_auction` still gets records. Test `outside review: R-07 R-08 R-09 the Full scan` checks both ways record the same prices, per gear ending. `signatures` on first use for other scans: not done, no measured need.

### R-09 (P3) Full scan: every auction still loading is asked for again each frame

- Where: `core/scan.lua:768-780`. Each frame walks all of `pending` and calls
  `info.replicate_record` for each until 100 have loaded. With thousands not loaded yet that is
  thousands of game calls per frame for up to 30 seconds.
- Fix: look at a bounded slice per frame (or at the whole set a few times a second), or use the
  time budget of R-07.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. Unloaded listings are kept in a list and at most 200 are asked about per frame, going round (fewer when the frame's share is used up). Same test block.

### R-10 (P2) Price history is never trimmed

- Where: `core/history.lua` (one saved line per price key in `faction_data.history`),
  `core/cache.lua` (`account_data.items`, `item_ids`).
- What happens: a key seen once stays forever. Since 0.8 every gear ending is its own key, so the
  number of keys grows faster than before. The whole table is loaded at every login and `/reload`.
- How sure: read in the code. I did not measure a real saved file; `/aux memory` already prints
  the number of items, which Tyler could report from his own.
- Fix: at login, in a thread that pauses, drop keys whose newest day is older than a limit (90 days
  as a start; the usual price already ignores what is older than 14 points). Say in the changelog
  that old prices are forgotten after that long.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 2):** Fixed. Tyler said yes to 90 days (2026-11-10). `history.forget_old_prices` runs once a day at login in a thread that pauses by the clock, and removes a line whose newest price is more than `FORGET_DAYS` (90) days old. The day is read from the saved line without unpacking it (`history.last_seen_day`): the day of its newest price, not the day it was last read, since a tooltip or a Sniper round reads a line and moves its day on without having seen the item. A line it cannot read is kept. `/aux memory` says so. Test `outside review: R-10 old prices are forgotten`.

### R-11 (P3) Post tab: every look through the bags builds a hidden tooltip per slot

- Where: `util/info.lua:49-94` (`container_item` reads the slot's tooltip, asks the game whether it
  can be sold, and more), used for every slot by `bag_count`, `find_item_location`,
  `missing_item_reason` and `update_inventory_records` in `tabs/post/core.lua`. `bag_count` runs on
  every `BAG_UPDATE` while a post is under way (`:101-106`), and the game fires that once per bag.
- Fix: a light function that gives a slot's price key and count from its link alone, for counting
  and matching; keep the full read for building the bag list.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed for the count: `info.container_price_key` (link only) behind `post.bag_count`. `find_item_location` and the bag list keep the full read, which they need (can it be sold, is it locked).

### R-12 (P3) Result tables sort every row on every update

- Where: `gui/auction_listing.lua:821` (`UpdateRowInfo` sorts all records) is called by
  `SetDatabase`, which a full-mode search calls after every item (`tabs/search/results.lua:570-572`).
  A search of a few hundred items that grows to 2,000 rows sorts them a few hundred times.
- Fix: while a search runs, redraw at most a few times a second (the Sniper already does this with
  `deals_changed`), and once at the end.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. A running search draws its table at most every 0.25 seconds and once when it ends or stops. Test `timing: R-12 R-20 a search redraws now and then and alerts once`.

### R-13 (P3) Login work that can go

- `aux-addon.lua:38` sorts the whole list of item names at every login and `/reload`. Keep the list
  sorted when a name is added and skip the sort when nothing changed. `core/cache.lua:146` can add
  a name twice (`process_item` does not check, `learn_item` does).
- `core/cache.lua:232-238` makes a thread for every item the game loads, all game long, and only
  then checks whether aux already knows the item. Check first.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed, all three: `aux.sort_item_names` sorts only when one pass finds a name out of order, `process_item` no longer adds a name twice, and a known item loading starts no thread.

## Findings: smaller defects

### R-14 (P3) Sniper: after re-reading a gear deal, the amount sent can be above that auction's buyout

- Where: `tabs/sniper/core.lua:797-811` takes "another one at the shown price or lower" and copies
  only its auction ID into the deal; `:886` then sends the old record's buyout with the new ID.
- What happens: if the auction found is cheaper, aux sends more than its buyout. Outside: on older
  server code a bid at or above the buyout buys at the buyout price. On Forever: Unknown. Either way
  the player never pays more than the button shows, so the guarantee in `AGENTS.md` holds, but the
  button shows a price that is not the one paid, or the game answers with an error.
- Fix: carry the found auction's own prices into the deal (or put the found record in the deal's
  place with its `deal_*` fields), so the button shows and sends that auction's buyout.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. The deal takes over the found auction's fields (`PRICE_FIELDS`), so the button shows and sends that auction's own buyout. Test `timing: R-14 ...`. The slow test auction house had to change for it: an auction's ID was its place in the results, so a different auction in the same place passed for the same one; each auction now has an ID of its own, and a row goes on under a new ID after a purchase, as in the game (Seen, `docs/forever-auction-house.md`, section 2).

### R-15 (P3) Price boxes accept `inf`, hex and exponent numbers

- Where: `util/money.lua:125` (`tonumber(value)` for a plain number, read as gold).
- Confirmed: `inf` gives an infinite amount, `0x10` gives 16g, `1e3` gives 1,000g. An infinite
  price would be saved with the item's Post settings and handed to the game's post call.
- Fix: accept only digits with an optional decimal point, and cap the result at the game's highest
  price.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. A plain number is digits with an optional decimal point; results are capped at `MAXIMUM_BID_PRICE` when the game has it, else 9,999,999g 99s 99c.

### R-16 (P3) Search language: a counted `and`/`or` is not checked

- Where: `util/filter.lua:360` reads the count from the operator's name instead of its count field,
  so it always adds 0; `:368` loops with `ipairs` over a table keyed by names, so it adds nothing.
- Confirmed: `and2/price/1s` (two conditions promised, one given) is accepted. Code from Classic aux.
  The Filter Builder writes correct text, so only hand-typed searches meet it.
- Fix: use `component[3]`; `pairs` for the suggestions. Check the Filter Builder's tests still pass,
  since the builder and the search bar read each other's text.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed in part. `pairs` for the suggestions: after `and/` the conditions are offered again. The count check is left as it is, on purpose: reading the count correctly would reject searches that work today (a saved `and2/...` with one condition under it runs fine and would become "Malformed expression"), and nothing is gained for searches the Filter Builder writes.

### R-17 (P3) Unused table definition with a mistake in it

- `gui/auction_listing.lua:353-497` (`auctions_columns`) is no longer used by the addon (the
  Auctions tab has its own columns since 0.4; only `tests/load_test.lua:787` still names it). Its
  bid sort divides by the other row's count (`:422`). Remove it and the test's mention.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. `auctions_columns` is gone; the columns test now checks the Auctions tab's own list.

### R-18 (P3) Listeners and threads are added to tables while those tables are being walked

- Where: `control.lua:35-41` (events) and `:87-96` (threads).
- What happens: a callback that starts a scan adds a listener or a thread during the walk (for
  example the buy bar's price handler calling `on_refresh`, or a scan's `on_complete` starting the
  next scan). Lua 5.1 leaves the rest of that walk undefined: an entry can be skipped or visited
  twice. A skipped listener misses that event and its scan then waits out a timeout.
- How sure: the pattern is certain; I know of no report caused by it. It would show as a rare
  "no answer" that nobody can reproduce.
- Fix: collect new listeners and threads in a side list while a walk is under way and add them
  after it. A few lines, and nothing per frame.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. Events go out from a list in the order the listeners were made, built again only after a change; the thread runner lists the threads before running them. The new test showed this was not only theory: against the old code, 12 listeners that each make listeners during an event did not all get every event exactly once.

### R-19 (P3) Gamepad: the pad stays with aux for the whole fight when combat starts

- Where: `gamepad.lua:756-776`. `docs/gamepad.md` records it as a known limit.
- Suggestion: give the buttons back in the `PLAYER_REGEN_DISABLED` event, which fires as combat
  starts (Outside: on the modern client, protected calls are still allowed inside that event's
  handler; not checked on Forever), and take them again when combat ends if aux is still open.
  Try it with the taint log on, as `docs/gamepad.md` describes.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 2):** Fixed. Tyler said yes (2026-11-10). `gamepad.lua` hands the buttons back in `PLAYER_REGEN_DISABLED` and takes them again in `PLAYER_REGEN_ENABLED` if aux is still open; opened during a fight, aux takes them once it is over. The binding call is only made when `InCombatLockdown()` says the game is not locked yet, so if Forever locks before that event (the claim that it does not is Outside) nothing is called and the old behavior stays. Test `outside review: R-19 the gamepad in combat` plays both cases. Not seen in game: step 9 of the build 2 checklist, with the taint log on.

### R-20 (P3) Short list

- `tabs/search/saved.lua:15-18, :142`: removing a favorite uses the row number from when the
  question opened; reordering favorites meanwhile removes another one. Pass the entry, not the index.
- `tabs/search/results.lua:578-580`: in a normal search the alert popup is shown again for every
  matching auction (the code's own TODO). Show it once per search, as Live mode does.
- `core/cache.lua:239-241`: an item whose data failed to load is saved as "does not exist" for
  good (the code's own TODO doubts this). Whether Forever reports a temporary failure this way is
  Unknown. Safer: remember it for the session only.
- `tabs/sniper/core.lua:593-601`: Ignore item stores the auction house's version key, so ignoring
  one version of "Staff of the Wolf" leaves its other versions (same name, same stats, Seen once)
  showing. Store the price key.
- `gui/buy_bar.lua:240-285`: a trade good's price request that the game drops for being sent too
  fast ends as "No answer from the auction house" after 10 seconds. Listening for
  `AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED` there would say so at once and could send it again.
- `AUCTION_CUT` is written in three files (`tabs/post/frame.lua:159`, `tabs/sniper/core.lua:20`,
  `tabs/search/recipe.lua:16`) and "5%" once more as text (`tabs/search/recipe.lua:352`). One
  constant in one place. See also R-27.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed, except one. Favorites are removed by entry; the alert popup shows once per search; Ignore item stores the price key (old entries still count, and the name check costs nothing for items that are no candidates); a dropped price request says "The auction house was busy" at once (while the price is asked only: during the purchase itself another message could have been the one dropped); the cut is `aux.AUCTION_CUT`, used by Post, Sniper and the recipe lines. Not changed: an item that failed to load stays saved as "does not exist". If Forever lacks `C_Item.DoesItemExistByID` (Unknown), remembering failures for the session only would ask the game about every unknown item number again at each login, which 0.4.1 removed.

## Findings: tests and tooling

### R-21 (P1 for the tests) One test removes the Bids table's `GetSelection` for every later test

- Where: `tests/load_test.lua:2666-2671`. The test replaces `bids.listing.GetSelection` and then
  "restores" it with `rawset(..., nil)`. A table's methods are plain fields copied in by
  `auction_listing.new`, so this deletes the real one; from then on the harness answers with an
  empty stub frame. `real_get` is saved two lines above and never used.
- Effect: no later test can exercise selection on the Bids tab, which is how R-04 went unseen.
- Fix: restore `real_get`. Better: one helper for swapping a field that puts back exactly what was
  there (the raw value, or nothing), and use it everywhere a test replaces something. A quick search
  for `rawset(` followed later by `, nil)` will find the other places to check.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed for every such place at once: in `tests/load_test.lua` and `tests/timing_test.lua`, `rawset` remembers what a field held before its first swap and a later `nil` puts that back. 54 places restore this way; besides the Bids table's `GetSelection` they had removed buttons' `SetBackdropColor`, a dropdown's `GetIndex` and listings' `SetData` for later tests. All 1,101 checks of the time still passed afterwards.

### R-22 (P2) The stubs accept any game function and any enum value

- Where: `tests/load_test.lua:80-83`: an unknown `C_*` function returns a function that returns 0,
  every `Enum` value is 1, and unknown globals ending in `Button`, `Text` and so on are frames.
- Effect: a misspelled function or enum member passes every test, and all enum values compare equal
  (`ItemNotFound == ItemNotAvailable`, `Sold == Commodity`). The first in-game test finds it, at
  Tyler's cost. The audit of 2026-10-11 found the same weakness in the category list and fixed it
  with real data; this is the same step for functions and enums.
- Fix: make lists of the real names from Blizzard's generated documentation for Forever (the files
  `docs/forever-auction-house.md` names under Sources), the way
  `tests/tools/make_forever_categories.lua` makes the categories. The harness then fails on a call
  to a name that is not in the list, and gives each enum member its real, distinct value. Tests that
  need a function to answer still set it themselves.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 2):** Fixed. Blizzard's code turned out to be reachable from this session after all (anonymous read of the public repository). `tests/tools/make_forever_api.lua` writes `tests/forever_api.lua` from the generated documentation (branch `forever`, build 70888): the functions of every `C_` namespace the addon names, every event, and the members and values of every `Enum` the addon names. In the harness a `C_` function, an event or an enum member Forever does not have is an error, also when a test fakes one, and enums hold the game's values. Every function, event and enum the addon uses is in the list; the 1,188 checks of the time passed unchanged. Not checked by it: functions Blizzard's interface code writes in Lua (`ItemLocation`, `TooltipDataProcessor`, frames), which that documentation does not hold; the ones the addon uses were looked up by hand on 2026-11-10 (`tests/known_globals.lua` names the sources).

### R-23 (P3) One test file of 5,700 lines with shared state

- All tests run in one file, in order, on one loaded addon; each depends on what the ones before it
  left behind (R-21 is the example). Suggestions, in order of value:
  - Print how many checks ran ("done, 1094 checks, errors: 0") and keep the number in CI's output,
    so a block that silently stops running is noticed.
  - Split by area (scan, history, post, sniper, gamepad, looks) into files that a small runner
    loads; a fresh addon per file is cheap (the whole run takes about a second).
  - The swap helper from R-21.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** In part: the run prints `checks: N` before its last line (1,188 now). The split into files is not done; with R-21 fixed the shared state is less dangerous, and the split is a large mechanical change better done on its own.

### R-24 (P3) Nothing checks for misspelled names inside the addon

- In this module system a misspelled variable reads as nil and a misspelled assignment makes a new
  variable, both silently (`libs/package.lua`). The tests could run with a strict switch: after the
  files have loaded, a write to a name the module never had, or a read that finds nothing in the
  module and nothing in the game's globals, is recorded and fails the run unless the name is on a
  short allow list (optional game functions such as `GetUIPanel`).

**Answer (Claude, 2026-11-10, 0.8.2.1 build 2):** Fixed, by another route than proposed. A switch at run time would have drowned in names that are nil on purpose (`next_refresh or 0`). `tests/lint_globals.lua` reads each file's compiled code (`luac -l`) and lists every name that is read but that neither the file's module nor the game defines; `tests/known_globals.lua` holds the game globals the addon reads, each looked up for Forever. The current code has none unknown (one unused leftover, `editBoxWidth`, was removed). CI runs it. Shown to work by misspelling a name on purpose.

### R-25 (P3) Release workflow

- `.github/workflows/release.yml` can be started by hand from any branch and would publish that
  branch as a release. Add a check that a manual run is on `main`.
- `softprops/action-gh-release@v2` runs with write access and is named by a moving tag. Name it by
  commit.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** In part: a manual run must be on `main`. Naming the release action by commit is not done: the commit cannot be looked up from this session, and a wrong one would break releases. `test.yml` also checks that the TOC's version has a changelog section.

## Findings: docs and process

### R-26 (P2) The files the next agent starts from are one release behind

- `docs/status.md:3` says 0.8.2 build 8 is "ready to release when Tyler says" and 0.8.1 is the
  latest release; the tag `v0.8.2` is on `main`. Its "Start here" said H-010 was open while
  `docs/handoff.md` had nothing open, and the handoff's active branch was the merged
  `claude/magical-maxwell-eyud0b`. (This review corrected those three lines when it added its own
  note.) Also: `CLAUDE.md` says "Releases up to 0.6.0.2 (PR #21, 2026-10-10) are merged into
  main".
- `docs/status.md` is 1,564 lines with two newest-first lists (above and below "Start here"). The
  file every session must read first should fit on a screen: where things stand, the next step,
  open questions. Move the history to an archive file, as `TESTING.md` did with
  `docs/testing-history.md`.
- A small CI check would keep it honest: the TOC version, the newest changelog heading and the
  "latest release" line of the status file must agree.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Fixed. `docs/status.md` is now one screen (where things stand, the next step, questions for Tyler, how he tests); everything that stood there moved unchanged to `docs/status-history.md`. `CLAUDE.md` points to the status file for the released version instead of naming one. The CI check covers the TOC and the changelog; the status file's line is not checked by a machine.

### R-27 (P2) The 5% cut is shown to players as fact while the facts file labels it Outside

- `docs/forever-auction-house.md`, section 4: 5% on a faction house and 15% on a neutral one are
  Outside, "never checked against a real invoice" (experiments E1 and E2). The Post tab ("Auction
  house cut 5%", "You get"), the recipe profit line and its hover ("After the 5% auction house
  cut") and the Sniper's profit all state it without a label. By the project's own rule that needs
  either the label or the check.
- E1 is one sale and one screenshot of the "Auction successful" mail. I recommend doing it before
  0.9 adds posting rules that build on these numbers. If the neutral houses do take 15%, the Post
  tab's "You get" is wrong there; whether aux can tell which house is open is Unknown.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Not built: it needs a sale in game (question 3 in `docs/status.md`). The number now lives in one place (`aux.AUCTION_CUT` in `aux-addon.lua`) with its label in the comment, so one edit follows the answer.

### R-28 (P3) Two structural notes for later versions

- **One scan at a time, and the last one to start wins.** `scan.start` stops whatever is running
  (`core/scan.lua:159-167`). Each new feature has added a guard for one pairing: the Sniper and the
  Auctions check wait for a Full scan, Live waits for the buy bar, the re-read after buying waits up
  to 30 seconds for any scan and then sends its own request around the scan engine
  (`tabs/search/results.lua:820-827`). A small queue with an order (a purchase first, then what the
  player asked for, then background reads) would replace the guards and make "who stopped my
  search" impossible. Not urgent; worth planning before 0.9 adds more background work.
- **State kept as loose flags.** A post in progress is spread over `posting`, `pending_post`,
  `post_outcome`, `post_error_text`, `last_post_update`, `posting_item` and five event handlers
  (`tabs/post/core.lua:70-119, :434-527`); a live search over `live_next`, `live_held`,
  `live_restarting`, `live_stopping`, `continuation`, `active`. Several past bugs in the changelog
  were one flag out of step. One table per post and per live search, with named states, would make
  the next change in these areas safer. Do it when one of them next needs a real change, with the
  slow-server tests as the safety net.

**Answer (Claude, 2026-11-10, 0.8.2.1 build 1):** Not built: both are for a later version, as the finding says. R-02's result table on `on_complete` is a small step toward callers knowing how a scan went.

## Checked and found sound

- **Buying trade goods** (`gui/buy_bar.lua`): nothing is confirmed above the cost shown; a price
  update during a quote is checked again; changing the item, the tab or closing cancels the quote;
  a confirmed purchase that gets no answer says it may still go through.
- **Buying gear from the Search tab** (`tabs/search/results.lua`): the amount sent is the row's own
  buyout with its own auction ID, and after a purchase the next auction of the row is matched on
  link, buyout and bid before it can be bought.
- **Posting** (`tabs/post/core.lua`): Post stays faded until the listings are in unless the player
  typed a price; the result is taken from what left the bags, not from an event alone.
- **Work per frame**: every `OnUpdate` in the addon returns at once when idle or is limited to a
  few times a second; the one login thread ends; no thread waits forever.
- **Blizzard's code is left alone**: hooks are `hooksecurefunc` and `HookScript`, the gamepad code
  reads but never writes Blizzard's tables, tooltips skip values the game hides from addons.
- **The public API** (`core/api.lua`) is small, returns nil before the history loads and matches
  `docs/api.md`.

## Suggested order for the engineer

1. A patch (0.8.2.1 by the project's numbering): R-01, R-02, R-03, R-04, R-06, with R-21 first so
   the Bids test can be written. All have tests that fail today.
2. With that or right after: the Full scan speed work R-07 and R-08 (FB-027), then ask Tyler for one
   Full scan line before and after.
3. Ask Tyler for two things that need the game: one `/aux debug` line on a busy day (R-05) and the
   sale mail of experiment E1 (R-27).
4. Before 0.9: R-22 (strict stubs), R-10 (trimming), R-26 (docs), then the small ones as they are
   touched.

## Second pass (2026-11-10, with the fixes): the files this review only skimmed

Read in full for build 2: `tabs/post/frame.lua`, `tabs/sniper/frame.lua`, `tabs/search/frame.lua`,
`tabs/search/core.lua`, `tabs/search/quick.lua`, `tabs/search/filter.lua`, `gui/item_listing.lua`,
the rest of `tabs/auctions/frame.lua`. Still only skimmed: `tabs/search/builder.lua`,
`gui/listing.lua`, `color.lua`, `core/disenchant.lua`. Found and fixed in build 2, each with a test:

- **S-01 Typing in the search bar was slow.** For the first word of a search,
  `completion.complete_filter` got a list of every item name with "/exact" added, built anew at
  every key press, and compared each in upper case: about 28 ms per key with 25,000 names in the
  harness. It now looks through the names itself: about 3 ms. Same completions as before
  (`second pass: search bar completion`).
- **S-02 A right-click search raised an error for an item the game had dropped the data of**
  (`info.item(...).name` in five tabs), and so did the conditions `item`, `vendor-profit` and
  `bid-vendor-profit`. All right-click searches now go through `search.search_item`, which does
  nothing for such an item (`second pass: items the game does not know`).
- **S-03 A Sniper deal re-priced by R-14 kept its old profit and percent.** They are worked out
  again from the new price.
- **S-04 "The money is in your mailbox."** for a sold auction stated what
  `docs/forever-auction-house.md` calls Unknown (how long the money takes, experiment E1). It now
  reads "Sold. The money comes by mail."

Seen and left alone:

- The deposit tooltip on the Post tab says the deposit "is kept if the auction expires". On Forever
  that is Outside (experiment E4). The cancel half of the sentence is Code. Left for Tyler: a label
  in a tooltip reads oddly, and E4 is one expired auction away from settling it.
- A right-click on a result row searches the item's own name, so for gear every ending; the Post
  tab's right-click on a price searches the full name with its ending. Both are deliberate as far
  as the comments say, but they differ.
- The count boxes on the Post tab snap an emptied box back to 1 at once, so "Choose how many to
  post." can never show. Harmless.
- Blizzard's own buy window accepts a server price up to 5% above the one it showed (Code, now in
  the facts file). aux stays stricter.

## Appendix: two experiments that are ready-made failing tests

Both ran at the end of a scratch copy of `tests/load_test.lua`, with
`local function M(name) return loadstring("select(2, ...) '" .. name .. "'; return _M")('auxForever', addon) end`.

**A (R-01).** Output today: the deal is marked gone, and chat gets "the auction house did not
respond to the search".

```lua
local sniper, scan = M 'aux.tabs.sniper', M 'aux.core.scan'
local deal = {deal_key = '977:0', unit_buyout_price = 500, buyout_price = 500, count = 1,
  name = 'Still Listed Herb', item_id = 977, search_signature = 'x', sniping_signature = 'x'}
for i = #sniper.deals, 1, -1 do tremove(sniper.deals, i) end
tinsert(sniper.deals, deal)
sniper.last_count = 7000                                    -- an earlier round read the list
rawset(C_AuctionHouse, 'SendBrowseQuery', function() end)   -- this round gets no answer
sniper.start_round()
for _ = 1, 230 do tick() end                                -- 23 seconds: past the 20 second wait
check('a round without an item list leaves the deals alone', not deal.deal_gone)
```

**B (R-03).** Output today: not opened in round 1 (right), 3 complete days after the Full scan, not
opened in round 2 (wrong), opened once `sniper.settings_changed()` is called.

```lua
local sniper, h, scan, a = M 'aux.tabs.sniper', M 'aux.core.history', M 'aux.core.scan', M 'aux'
local d = h.today()
-- GetItemInfo answers for item 955: an uncommon trade good with a vendor price of 1c
a.account_data.sniper_percent, a.account_data.sniper_profit = 60, 1
h.write_record('955:0', {day = d, points = {{value = 3200, day = d - 1, units = 10},
                                             {value = 3200, day = d - 2, units = 10}}})
local opened = {}
sniper.check_item = function(_, key) opened[key] = true end
local r = {itemKey = {itemID = 955, itemSuffix = 0, itemLevel = 20}, totalQuantity = 5, minPrice = 500}
local k = scan.item_key_string(r.itemKey)
sniper.settings_changed()
sniper.check_list({r}, {})                 -- 2 days of history: rightly not opened
-- today's Full scan: a complete look, so 3 days now count
h.write_record('955:0', {day = d, market = 3200, units = 10, low = 500, points = h.data_points('955:0')})
sniper.check_list({r}, {})
check('an item is judged again once a Full scan adds a day of history', opened[k])
```

In the real fix the second `check_list` follows a Full scan through `scan.on_full_scan_view`, so the
test should run a small Full scan as the H-008 tests do, not write the record by hand.
