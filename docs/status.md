# Status

Last updated 2026-10-20, Tyler's time (0.8 build 3: gear versions; build 2: Waylaid Crates; build 1: gamepad support from nokkty; 0.7.1.1 released).

**2026-10-20, privacy pass (docs only, no addon change):** Tyler asked that the public repository
say no more about him than the work needs. Removed: his city and time zone name (dates now use
UTC offsets, rule in `AGENTS.md`), mentions of when in his day he worked, and the designer's real
name, handle and job (he is now only "webster"). New privacy rule in `AGENTS.md`, "The owner".
Git history still has the old text; rewriting it was judged not worth it.

**2026-10-20, branch cleanup (docs only):** two branches held work that never reached `main`.
`claude/zealous-bardeen-i9v5mp` (Tyler posted the corrected FB-021 reply on 2026-10-19) and
`claude/exciting-brown-a9k99n` (Tyler changed his mind and wanted it merged): the 2026-10-11
rewrite of `docs/forever-auction-house.md` with a label on every fact (Seen, Code, Outside,
Unknown) and the rule in `AGENTS.md` that only Seen facts go to players as fact. The facts seen in
game since 2026-10-11 (deposit floor of 1 silver, `SupportsCopperValues()` true, the gear copper
post, gear versions, no `itemLink` for owned trade goods) were added to it under their labels;
E5 (durations) is settled as 2/8/24. The `AGENTS.md` gotcha about the newest listing selling first
now says it has no source (E6). Every other branch was merged or replaced by later work.
Tyler: GitHub Settings, General, Pull Requests, "Automatically delete head branches", so merged
branches stop piling up.

**Dates:** Tyler's (rule in `AGENTS.md`, "The owner"). On 2026-10-09 the dates agents
had written from the UTC clock were moved to his date, checked against the time of the commit
that wrote each line (the 0.6 and 0.6.0.1 releases were on 2026-10-09 his time, not
10-10). A few lines edited later could not be checked that way and may still be a day ahead. Dates
of outside events (Blizzard patches, players' messages) were left as their source gave them.

## Start here (next session)

**Where things stand (2026-10-20):** **0.8 build 3 (gear versions)** is on branch
`claude/fervent-planck-ry58jx`, waiting for Tyler's test (`TESTING.md`, zip
`auxForever-0.8-build3.zip`). With it every 0.8 item is built: gamepad support (build 1, nokkty),
Waylaid Crates (build 2, tested, pass), gear versions (build 3). Next: Tyler tests build 3, then
says whether 0.8 is ready to release (pull request, merge, Release workflow). Build 1 was gamepad
support alone; its mouse and keyboard steps are folded into build 2. It is nokkty's work (GitHub issue #27, fork
branch `gamepad-navigation`, built with Claude and tested in game by them on 0.7, 2026-10-13),
merged with their commits and authorship kept, onto `main` at 0.7.1.1. Tyler, on the issue: "ill
check it out and merge tonight". Nothing is released; 0.7.1.1 is still the latest release.
Next: Tyler tests build 1, then says whether 0.8 ships with gamepad alone or waits for the other
0.8 items (`docs/roadmap.md`). Open for Tyler: FB-022 (below).

- **0.8 planning (2026-10-20):** 0.8 is only gamepad support, Waylaid crates and gear versions
  (Tyler). The crafting shopping list (FB-023, Kortan) and counting other characters' items move
  to 0.9 together. Still open for 0.9: compare crafted materials with crafting them, and which
  price the list shows; then a mockup. Gear versions: Tyler asked what it meant; the way to settle it is a screenshot of
  two same-name gear tooltips (do the stats differ?). Waylaid crates: "cheapest way to fill one"
  (Tyler); a crate lists several bundles, any one fills it (guides, FB-020). Waiting on a crate's
  tooltip in game. Writs go to 0.9 with the shopping list (Tyler, 2026-10-20).
- **0.8 build 2: Waylaid Crates built and tested in game (2026-10-20)**: steps 1, 3 to 6 pass from
  Tyler's screenshots (`TESTING.md`); was waiting for Tyler's test (`TESTING.md`, zip
  `auxForever-0.8-build2.zip`, full game restart). Tyler chose options A and C of the mockup. A: a
  crate's tooltip lists every bundle with its cost, cheapest in gold, bags counted
  (`add_crate_lines`, called from `core/tooltip.lua`). C: Alt-click a crate in the bags searches
  every bundle's item through the recipe search path (`search_parts`); the bottom bar prices each
  bundle from live listings, cheapest first as many as needed, own auctions skipped
  (`crate_live_costs`, `crate_summary`); Recent searches keep it as a crate. Tests: load_test
  (tooltip, live costs, Alt-click end to end with the fake auction house) and timing_test (a
  second crate clicked mid-search), each checked to fail with the code broken. Found on the way:
  E7 in `docs/forever-auction-house.md` (whether Forever answers a replaced search; if it does, a
  search started while another loads its item list can read the old list).
- **Earlier the same day:** the crate logic was built first, without display: `auxForever/tabs/search/crate.lua` (new file, so a
  full game restart once it ships): reads a crate's bundles from its tooltip text (each row
  "- <count> <name>", one or several per line), keeps them per crate, prices each bundle like a
  recipe's materials (vendor when cheaper, else the latest price; `recipe_usual_cost`), less what
  is in the bags, and finds the cheapest. Tests: "0.8: Waylaid Crates" in `tests/load_test.lua`,
  checked to fail when the bags or the tie rule are broken. Waiting on Tyler: the mockup
  https://claude.ai/artifact/946XmJEswoKZAoNjme1mAq, option A (every bundle in the tooltip), B (one
  line) and the extra C (Alt-click a crate searches its bundles, live prices, like recipe search).
- **Seen 2026-10-20 (Tyler's screenshots):** a Waylaid Crate's tooltip lists its bundles (FB-020).
  Three Medicine Staffs with different endings (of the Bandit, of Arcane Protection, of the Wolf;
  different stats) showed the same aux prices in their tooltips (Value 1g 50s, usually 25s, Today
  1g 10s, 440%): aux's tooltip prices lump every ending of an item together. Cause confirmed by the
  raw link Tyler printed (`item:4575::::::::24:1487::1:1:12726:1:28:5254::::`): the suffix field is
  empty, so every ending reads as `item_id:0`, while searches record `itemKey.itemSuffix`
  (`docs/forever-auction-house.md`, section 4). The fix is the next 0.8 item, gear versions.
- **Gamepad testing:** Tyler will not test the controller steps (2026-10-20: "That can be for the
  small amount of users that want to test it"). The mouse and keyboard check moved into build 2
  (step 6).
- **Other characters' items (0.9, Claude's thoughts 2026-10-20):** two ways. (a) aux
  records each character's bags (always), bank (when opened) and mail (when opened) in its
  account-wide saved data, as Syndicator does; counts only, saved on a timer and on logout, never
  per bag event. Works only for characters logged in at least once with aux, on the same account
  folder, and is as fresh as each one's last login. (b) Read Syndicator's data when it is
  installed: no new tracking code, but depends on another addon being installed and working on
  Forever (not checked). Claude's suggestion: build the list so "what you have" is one place,
  and add (a) with it, and (b) only if players already use Syndicator on Forever.
- **0.8 build 3: gear versions (2026-10-20).** Tyler's screenshots: two Medicine Staffs of Arcane
  Protection have the same stats, so gear is grouped by full name. New `info.price_key` (ending
  from the name: "4575:of the wolf"; else "id:0"), set on every record and bag item; price history,
  filters, the % column, tooltips, the API, `/aux price` and the Sniper use it. Post tab: bag items
  are grouped by price key and compared with listings of the same name. Auctions tab: gear with an
  ending is checked with a name search of the item, against every listing of its name. Old gear
  prices under "id:0" are no longer read for gear. Tests: "0.8: gear versions" (load_test) and
  "gear is posted against its own ending" (timing_test, the slow server now models versions), each
  checked to fail with the change undone.
- **Gear versions plan (2026-10-20, answered, built in build 3):** how aux keys gear prices today: a search
  that reads each auction keys it by the link's suffix field, empty on Forever, so every ending
  lands on `item_id:0` (`info.item_search_record`); fast searches key by the auction house's
  version (`itemKey.itemSuffix`, `info.browse_record`); tooltips read the link, so they show the
  lumped `:0` price. Blizzard's code (`Gethe/wow-ui-source`, forever,
  `AuctionHouseDocumentation.lua`): `GetItemKeyFromItem(itemLocation)` gives a bag item's version;
  every item search row carries both `itemLink` and `itemKey`; nothing turns a link alone into a
  version. Plan: key gear by the auction house's version everywhere; tooltips learn link to
  version from the search rows aux reads (and ask the game for bag items). Open: whether two gear
  items with the same name but different versions have different stats (Outside: in original
  Classic they could), which decides whether the Post and Auctions tabs compare with the exact
  version or every version of the name.
- **What it does:** auxForever can be used with a controller in Forever's gamepad mode: D-pad, A,
  B, X, Y, LB/RB, a hint strip with the controller's icons, aux's popups inside aux. Mouse and
  keyboard are unchanged. How and why: `docs/gamepad.md`. New file `auxForever/gamepad.lua`; five
  buttons exported for Y (`buy_bar.primary_button`, the Sniper's `run_button` and `deals_list`,
  `post_button`, the Auctions tab's `cancel_button`, the Bids tab's `buyout_button`); aux's popups
  go through `aux.show_popup`/`aux.hide_popup` (every popup on `main` already did after the merge).
  Version raised to 0.8 (a new feature, by the numbering rule).
- **Fixed while bringing it in** (2026-10-20): nokkty's merge of `main` into their branch
  (2026-10-15) had cut the closing `end)` off their Sniper gamepad test, so `tests/load_test.lua`
  no longer ran at all on their branch. Restored. Every gamepad test also left aux holding the pad
  buttons when it finished; once 0.7.1.1's timing tests closed the auction house after them, that
  gave 2 errors. The tests now close aux while still in gamepad mode. New timing test (rule from
  FB-021): Y on the Post tab posts nothing while the listings load, and two quick presses post
  once; checked to fail when Y ignores a faded Post.
- **Found while building it** (rule added to `AGENTS.md`, Code gotchas): aux must never write into
  Blizzard's gamepad code (`GamepadMode`, `SmartNavigation`, its window manager or binding
  groups). The first try registered aux with Blizzard's window manager; closing aux by pad then
  got `SetPreferredGamepadInteractTarget()` blocked, each "blocked" popup was blocked again (259
  times) and the game froze (`Logs/taint.log`). aux now has a navigator of its own with override
  bindings on a frame it owns. Also: `C_Texture.GetAtlasInfo` fails on Forever (Vector2DMixin).
- **Tested in game** (2026-10-13, the contributor, New theme): every step of
  `TESTING.md` "0.7 build 1" passes; taint log with nothing blocked; no BugSack error. Not tested:
  the Classic theme, a PlayStation controller, the post confirmation popup by pad (covered by the
  automated tests), Y on Bids.
- **Test harness:** stub frames made with `CreateFrame` now know their parent, children, type and
  frame strata, `HookScript` adds to a script instead of replacing it, and `GetCenter`,
  `GetEffectiveAlpha` and `GetStringHeight` return numbers, all as in the game.
- `docs/curseforge-description.md` already has a line about controllers: paste it on CurseForge
  only once 0.8 is released.
- **Open questions for Tyler:** a look at the hint strip (no mockup was made; the layout was
  nokkty's choice after trying icons beside the tabs and buttons), a short pass in Classic, and
  whether to thank nokkty on the issue once it is merged.

**Before that:** **0.7.1.1 is released** (2026-10-19, PR #32, `main`
cdc2208): FB-021 (typed prices below the lowest listing can be posted), gear with only a buyout,
and the fixes found with the slow test auction house (below). Tag `v0.7.1.1`, GitHub pre-release
https://github.com/TylerHampton/aux-forever/releases/tag/v0.7.1.1, CurseForge Beta file id 9253171
(Release run 39214275264). `/reload` is enough for players. Tested in game by Tyler on build 2
(`TESTING.md`). Next: 0.8 as planned (`docs/roadmap.md`); nothing is being built. Tyler posted the
corrected reply to sarrathsilentstrider (2026-10-19). Open for Tyler: FB-022 (should the Post tab
say why it matches the lowest price?).

- **What it is:** FB-021 (sarrathsilentstrider: Rough Stone listed at 7c, 5c typed, Post would
  not post it; 6c worked). Cause: trade goods have no starting bid (its box is hidden), but aux
  kept one at the automatic price, and a typed buyout below it faded Post with "The starting bid
  is above the buyout." Fixed: that check is for gear only.
- **The slow auction house (new in the tests):** Tyler worried about problems he cannot see in
  code he cannot read. The tests answered every request at once, so bugs that depend on timing
  (a player clicking while the auction house is still answering) passed. `tests/slow_server.lua`
  is a fake auction house with a bag and listings that answers a second later and records what
  aux actually posted and bought; `tests/timing_test.lua` plays each tab against it (Post,
  buy bar, Search and buy, Sniper, closing the auction house mid-action). It found, all fixed with
  a test each, checked to fail without the fix:
  - a price typed while the listings loaded was replaced by the automatic one;
  - Post could be clicked before the listings arrived and posted at last visit's price;
  - an unrelated bag change ended a post early ("Not posted", Post clickable again: double post);
  - a post never answered while on another tab left Post on "Posting..." until a reload;
  - a slow trade good purchase said "Nothing was bought" though it could still go through, and a
    slow gear purchase said nothing (both now say it may still go through, check the mail);
  - buying from a row of identical gear auctions stopped any search started right after;
  - the Sniper lost possible deals it had not opened when the player clicked a deal.
- Checked and left as is: a search stopped by another tab (Post, Auctions, Sniper) shows Resume,
  as in the original aux; cancels already handle a slow answer (0.7.1); quick item switching on
  the Post tab is fine. Tyler's CurseForge reply for FB-021 (posted before the cause was known)
  says typing before the listings load was the bug; it was a real bug but not Sarrath's.
- Gear and copper: Blizzard's Sell tab has a copper box for gear, but Tyler's 10s 50c post there
  does not seem to have gone through (screenshots, no error text). aux keeps gear in whole silver
  until a refused post is seen with its error text (`docs/forever-auction-house.md`, section 4).
- Open for Tyler: FB-022 (should the Post tab say why it matches the lowest price, or is that
  teaching the auction house?). The corrected reply to Sarrath was posted by Tyler on 2026-10-19.

**Before that:** **0.7.1 is released** (2026-10-17, PR #30, `main` e63ec0a): every own
auction on its own row, cancels confirmed by the auction house, no silent search misses (FB-014 to
FB-016, daland). Tag `v0.7.1`, GitHub pre-release
https://github.com/TylerHampton/aux-forever/releases/tag/v0.7.1, CurseForge Beta file id 9233568
(Release run 39075770178). `/reload` is enough for players. Next: 0.8 is planned
(`docs/roadmap.md`: Waylaid crates, gear versions); nothing is being built. Replies for
sarrathsilentstrider (FB-017, FB-018) are in `docs/feedback.md` if Tyler wants to post them.
Branch `claude/exciting-brown-a9k99n`: Tyler deletes it on GitHub (Branches page). (Changed
2026-10-20: merged instead, see the top.)

- **Build 3 in game** (Tyler, 2026-10-17, `builds/0-7-1-build-3/results`, screenshots): Settings
  without the start mode row; Undercut stays on across posts until the auction house closes; the
  Auctions tab said "Tied with 4 others" for Ritual Belt of Arcane Protection at 6s, which matches
  the exact version's 5 listings. The `/run` lines showed why build 2 said "Only one listed": one
  gear name has several versions (suffix numbers 14320 to 14323 for the same "of Arcane
  Protection"), and aux compares with the exact version while Blizzard's Sell window lumps them.
  Not a bug in the check; a design question for 0.8 (`docs/roadmap.md`, Gear versions).

- **0.7.1 build 3** (2026-10-17): from Tyler's test of build 2 (results and 17 screenshots on the
  test page, `builds/0-7-1-build-2/results`):
  - Deposit rounding taken out: `SupportsCopperValues()` prints true on Forever, so it never
    applied. aux's deposit matched Blizzard's and the money taken (FB-017 not reproduced; facts in
    `docs/forever-auction-house.md`, section 4).
  - "Post tab starts on" taken out (FB-018 wont-fix): Tyler wants Match lowest at every visit, and
    Undercut, once clicked, to stay until the auction house closes. That is how it works; a test
    now guards it.
  - Open: the Auctions tab's price check said "Only one listed" / Lowest other "none" for Ritual
    Bands of Spirit while aux's Post tab had listed others of the same version (9s, 1g 55s) a
    minute earlier. Suspected: the item key of your own auction (`GetOwnedAuctionInfo`) differs
    from the listed one (item level or suffix), so the check reads only your own. Not confirmed;
    build 3 steps 3 to 5 print both keys. Likely tied to the gear versions item (`docs/roadmap.md`,
    0.8).
  - Tyler's answers to the older questions: Sniper single listings: C (leave as is); no New theme
    tweaks; drop the FB-008 name and the CurseForge replies; the Sniper profit question was unclear
    to him and is dropped; branch `claude/exciting-brown-a9k99n`: delete (Claude's session was not
    allowed to delete a branch; Tyler deletes it on GitHub, Branches page; its last commit is
    1469ffa if ever wanted).
  - FB-020 Waylaid crates: planned for 0.8 (`docs/roadmap.md`).

- **0.7.1 build 2** (2026-10-17): adds to build 1 (below)
  - FB-017: the Post tab's deposit is rounded up to whole silver when
    `C_AuctionHouse.SupportsCopperValues()` is false, as Blizzard's sell window does
    (`deposit_amount` in `tabs/post/core.lua`). Step 6 prints what Forever returns; if it is
    true, this changes nothing and the cause is elsewhere.
  - FB-018: Settings, Posting, "Post tab starts on" (Match lowest / Undercut,
    `account_data.post_start_undercut`, default Match lowest). Built on Tyler's "all these
    changes are going to just be .7.1" as a yes; he had not answered the question directly.
  - Tests for both, each checked to fail without its change. Version `forever-0.7.1`. Zip
    `auxForever-0.7.1-build2.zip`, `/reload` is enough.
  - Still open for Tyler: FB-020 (Waylaid crates and writs: does Forever have them, worth
    building?); the rest of sarrathsilentstrider's cut-off comment.

- **Feedback logged 2026-10-17** (`docs/feedback.md`): FB-017 deposit and FB-018 setting are in
  build 2 above; FB-019 praise; FB-020 Waylaid crates and writs waits on Tyler.

- **0.7.1 build 1** (built as 0.7.0.1 build 1, 2026-10-16), from daland's comments (Tyler sent the three screenshots
  without a message; recorded in `docs/feedback.md`, source
  `docs/feedback/sources/2026-10-16-daland-curseforge.md`):
  - FB-015: the Auctions tab folded identical auctions (Forever makes one auction per posted
    item) into one row that said Qty 1, and hid other prices of an item under its row.
    Reproduced in the harness: 5 auctions showed as 2 rows. Now one row per auction
    (`listing.one_row_each` in `gui/auction_listing.lua`; own auctions get their auction ID in
    the signature, `owned_record` in `util/info.lua`).
  - FB-016: Cancel said "Cancelled, comes by mail" the moment it was clicked. Now "Cancelling..."
    until `AUCTION_CANCELED` for that auction (or the auction leaving the list); after 10 seconds
    with no answer the row shows its status again and a chat line says so
    (`tabs/auctions/core.lua`). Inference: daland's report was likely FB-015's folded row (one
    of several identical auctions cancelled while the row said cancelled).
  - FB-014: cause not found in the code. Confirmed: a search skipped an item silently when the
    game had not loaded it within 3 seconds. Now it waits up to 5 seconds more, reading the rows
    again, and the search ends with "N items could not be read in time... Search again" when
    any were left (`search` and `scan_item_list` in `core/scan.lua`). Not ruled out: an
    `/exact` search pins the level range to the item's own level (`blizzard_query` in
    `util/filter.lua`); unverified, left alone. Steps 4 and 5 of the test check search.
  - Tests: `auctions tab: every auction on its own row, cancels the auction house confirms`,
    `search: items the game loads late are waited for, unread items are reported`, and the
    cancel check in `auctions tab: undercut check`; each fails without its fix. The fake
    auction house now stubs `AuxTooltip.NumLines` (the login item walk could reach its items).
    Version `forever-0.7.0.1`. Zip `auxForever-0.7.0.1-build1.zip`, `/reload` is enough.
  - Blizzard: builds 70374, 70425 (2026-10-15) and 70450 (2026-10-16) are out on Gethe's
    `forever` branch. 70425 changed the auction house UI: Forever now shows each item key's
    required level (`AuctionHouse_ShouldUseRequiredLevel`, `GetItemKeyRequiredLevel`) instead of
    item level, and added `GetItemKeySampleLink` for tooltips. Nothing in aux depends on the
    changed Blizzard code.

- **Build 4 in game** (Tyler, 2026-10-13, `builds/0-7-build-4/results`, screenshots; only step 4
  marked, the rest judged from the screenshots): columns and item levels right, Req colors right
  in New and Classic, Req sort works both ways, fast resize to the smallest window passes, and
  `/run print(AuxForeverAPI.GetLatestPrice(2589))` printed `20 0` (Linen Cloth 20c, seen today).
  Tyler asked in the notes whether the API is active: yes, that output is the API answering.

- **0.7 build 4** (2026-10-13): Tyler: "actually swap req/ilvl. Req first always". Columns are now
  Req, iLvl, Item, For sale (Sniper: Found, Req, iLvl, Item). Zip `auxForever-0.7-build4.zip`,
  test page build id `0-7-build-4`. No answers were saved for builds 1 to 3.

- **0.7 build 3** (2026-10-13): Tyler, testing build 2 (screenshot): after a fast drag to the
  smallest window, the search table kept a wider layout and Bid, Buyout and % ran past the
  window's right edge. Not caused by the new columns: `ResizeColumns` in `gui/auction_listing.lua`
  measured the content area during the table's own size event, which could still report the size
  of a step before; a fast drag ends in one big step, so the last layout was far off. The lists
  had the same bug, fixed in 0.5 (FB-006, `gui/listing.lua`). Now the content area's own size
  event lays the table out with the width it reports, later refreshes reuse that width (measured
  again on show), the last column is anchored to the right edge, and a layout that did not change
  does no widget work. Test `0.7: result tables follow a fast resize` (fails without the fix). Zip
  `auxForever-0.7-build3.zip`; test page build id `0-7-build-3` (step 4 now asks for fast drags).

- **0.7 build 2** (2026-10-13): Tyler, looking at build 1 before testing: "I want it to be ilvl /
  req / Item name / for sale... Need clarity, quick visual clarity on how many are for sale." The
  iLvl column sat between the item and For sale, two columns of plain numbers side by side. Now
  iLvl, Req, Item, For sale in Search, Bids (Quantity), Auctions (Qty) and the Sniper (after
  Found). Auctions tab sort moved to `SetSort(3, 8)`. Test: the column after Item is the units
  column in every table. Zip `auxForever-0.7-build2.zip`; test page build id `0-7-build-2`.

- **0.7 build 1** (2026-10-13), from two CurseForge comments, both asked for at once by Tyler:
  - FB-013 (HoaxBox): an **iLvl** column (after the item's name in build 1; first since build 2) (gear only; Forever's tooltips do
    not show item level, Tyler's screenshot) and the level column renamed **Req**, colored by
    distance from the player's level: red 5+ above, orange 3 to 4, yellow 1 to 2, green usable,
    gray far below (Classic's gray level, `gray_level`). Tyler's idea, with gray instead of his
    blue (blue is rare items' color) and two columns instead of one combined (his choice after
    the reply). In Search, Sniper, Auctions and Bids. No mockup: Tyler "I trust that you can
    make it work". Item width .35 to .32 so the other columns keep their size.
  - FB-012 (MDHippie): `AuxForeverAPI` (`core/api.lua`, new file): `GetLatestPrice`,
    `GetUsualPrice`, `IsReady`, `version = 1`. For addon authors: `docs/api.md`, linked from the
    README and the CurseForge description (Tyler pastes the description by hand).
  - Tests `0.7: Req and iLvl columns` and `0.7: AuxForeverAPI` (checked to fail with the code
    broken). Version `forever-0.7`. Zip `auxForever-0.7-build1.zip`, **full game restart**. Test
    page build id `0-7-build-1`, 6 steps as in `TESTING.md`.
  - Not checked by any test: whether the columns fit at the smallest window (step 4), and whether
    Forever's item keys carry `itemLevel` (the item's own level is used when not).

- Branch `claude/exciting-brown-a9k99n` (docs only: auction house facts, experiments not scheduled) is
not merged; ask Tyler whether to merge it. (Merged 2026-10-20.)

- **Released 0.6.1.1** on 2026-10-12 (PR #25, `main` 154a584), "The Gaddor Update" (Tyler's
  name, used in the changelog only): a click on an item's icon in the Post tab's bag list selects
  it (FB-011). Tag `v0.6.1.1`, GitHub pre-release
  https://github.com/TylerHampton/aux-forever/releases/tag/v0.6.1.1, CurseForge Beta file id
  9153068 (Release run 38336234368). `/reload` is enough for players. The name is in the
  changelog heading and as the first line of the section's text, since the Release workflow
  leaves the heading out of the GitHub and CurseForge notes.
- **0.6.1.1 build 1** (2026-10-12): FB-011 (Gaddor on CurseForge): in the Post tab's list of bag
  items, a click on an item's icon did nothing; only the name worked. The icon is its own button
  (for its tooltip) and swallowed the click. Its mouse-up now calls the row's click handler
  (`gui/item_listing.lua`), so left-click selects and right-click searches from the icon too.
  Test in `lists follow the window size` (item list: a click on the icon selects the item), fails
  without the fix. Tyler wrote "6.1.1"; named 0.6.1.1 by the numbering rule (a bug fix raises the
  fourth number). Zip `auxForever-0.6.1.1-build1.zip`, `/reload` is enough. Test page build id
  `0-6-1-1-build-1` (3 steps, the same as `TESTING.md`). The page held the auction house
  experiments (`ah-facts-1`, no answers saved); branch `claude/exciting-brown-a9k99n` (docs only,
  not merged) says Tyler does not want them scheduled, so the page now shows this build.
- **Build 1 in game** (Tyler, 2026-10-12, `builds/0-6-1-1-build-1/results`, screenshots): icon
  click selects, name click selects, right-click on the icon searches. All pass.

- **Released 0.6.1** on 2026-10-11 (PR #23, `main` 7fa5223): weapon slots in Search (FB-010), In
  words names the slot first, items seen at the auction house join aux's item list, your characters
  dated by the date. Tag `v0.6.1`, GitHub pre-release
  https://github.com/TylerHampton/aux-forever/releases/tag/v0.6.1, CurseForge Beta file id
  9140444 (Release run 38184921559). `/reload` is enough for players. Tyler named the version
  0.6.1 on 2026-10-11 ("these changes justify .6.1"); build 1 was the same work under the name
  0.6.0.3, and the name 0.6.1 was once used for what became 0.6.0.1 (test page id
  `0-6-1-build-1`), so its builds counted on from 2. Build history below.

- **0.6.1 build 1** (2026-10-11, named 0.6.0.3 then): weapon slots in Search (FB-010, GregoryWW on
  CurseForge: "Slot selection for weapons (daggers f.e.) doesnt work, it cause full search
  instead."). Forever's auction house has three levels under Weapons (Weapons, One-Handed,
  Daggers; Blizzard's `Camelot/Blizzard_AuctionData.lua`, branch `forever`, build 70338), and also
  under Containers, Consumables (Item Enhancement) and Armor (Relic, Miscellaneous). The `slot`
  parser in `util/filter.lua` only accepted a third level under Armor (Classic), so "daggers"
  became a tooltip text filter and the search read every one-handed weapon. Now the slot is read
  under any category. Test `0.6.1: slots under any category` (fails without the fix).
- **Classic code audit** (2026-10-11, Tyler asked after FB-010): `docs/audit-classic-code.md`.
  The tests now use Forever's real category tree (`tests/forever_categories.lua`, made from
  Blizzard's code by `tests/tools/make_forever_categories.lua`), and a test sends all 137 menu
  choices through the search text and back. Tyler's answers: level cap 60 (A3 closed), Forever
  will have many items Classic did not (A4), "make all the common sense changes you want".
- **0.6.1 build 2** (2026-10-11): the audit's fixes. A2: Filter Builder In words names the slot
  first ("Daggers (weapons, one-handed)"). A4: an item seen at the auction house joins aux's item
  list at once (`learn_item` in `core/cache.lua`, called from `new_record` and `browse_record` in
  `util/info.lua`; no tooltip read, a table lookup for known items), so Forever's new items
  autocomplete and `/aux price` finds them. A8: your characters are dated with `time()` instead of
  `GetTime()` (uptime), old stamps count as seen today. Tests: `0.6.1: weapon slots in the Which
  items menus`, `0.6.1: your characters`, `0.6.1: items seen at the auction house join the item
  list`, each checked to fail without its change. The harness's `C_Item.GetItemQualityColor` now
  returns a color code as the game does. Zip `auxForever-0.6.1-build2.zip`, `/reload` is enough.
  Test page build id `0-6-1-build-2` (6 steps plus 2 optional ones that print the game's category
  names, the same as `TESTING.md`).
- **Build 2 in game** (Tyler, 2026-10-11, `builds/0-6-1-build-2/results`, screenshots only): weapon
  slots, staves, cloth chests, bows typed in the search bar and In words all pass. Autocompletion
  works ("linen" to "linen bag/exact"; an item the login walk already knew, so the new-item path is
  covered by the automated test only). Own auctions not checked (none up). Step 6 was confusing
  (two checks in one): rule added to `TESTING.md`, For agents. The two optional `/run` commands
  printed the game's category names; several hand-written names were wrong and are corrected
  (`docs/audit-classic-code.md`, Not covered); the test data now matches the game, 137 choices.

- **Released 0.6.0.2** on 2026-10-10 (PR #21, `main` 1bf97bd): the Post tab reads fresh listings
  on every pick (no more Full scan listings), one row per price for items sold by quantity, and
  one request instead of two for items that are not gear. Tag `v0.6.0.2`, GitHub pre-release
  https://github.com/TylerHampton/aux-forever/releases/tag/v0.6.0.2, CurseForge Beta file id
  9124502 (Release run 38101325007). `/reload` was enough for players. Build history below.
- **Next:** not chosen. The strongest candidate is **gear versions on the Post tab**
  (`docs/roadmap.md`): gear is priced against whichever version of the item comes first, not the
  player's own (Merc Sword: 11s for Eagle, 60s for Strength). Investigate first, mockup before
  building. Also watch for the Wool Cloth post that did not seem to reload (build 1, once).
- **Rules added in this session** (now on `main`, `AGENTS.md`): dates in Tyler's time;
  wrap up a session without being asked when he says he is done for the day.

- **0.6.0.2 build 1** (2026-10-09): the Post tab always searches the picked item. Tyler's
  screenshots: Scroll of Stamina showed the last Full scan's listings (27 at 13s, one row per
  listing, some rows without a time left) and the real ones only after Refresh (42 at 13s). Cause:
  `update_item` skipped the search when listings were already known (`listings_known`, from the
  full scan since 0.4.1, or from an earlier pick, as in the original aux), and full-scan listings
  are grouped by price, quantity, time left and owner while a commodity search gives one row per
  price. Tyler's decision after Claude's recommendation: always search, the full scan no longer
  feeds the Post tab (`record_scanned_auction`, `listings_known` and the bag-item filter removed;
  `refresh_entries` keeps only the picked item's listings). Test: `post: picking an item reads its
  listings fresh`.
- **Build 1 in game** (Tyler, 2026-10-09, `builds/0-6-0-2-build-1/results`): full scan then pick
  (Scroll of Stamina, one row per price: 40 at 13s) pass; picking again pass; price step not
  marked, but both screenshots show the price at the lowest listing ("Same as the lowest
  listing"). After posting: Light Feather reloaded and showed his new auction in green, but the
  first post of that test (1 Wool Cloth) did not seem to reload; Tyler is unsure whether he
  waited long enough, and every post after it reloaded. Not reproduced, cause unknown; watch for it.
  Still open: Light Feather showed three rows at 8c (26 and 480 at 24h, his own 2 at 2h). The
  commodity search itself returned two rows at that price, and `record_auction` merges only rows
  with the same quantity, time left and owner. Proposed to Tyler: for commodities, one row per
  price (his own separate). Tyler said yes: built as **build 2** (`record_auction`: commodities
  merge by price and owner, units added up, longest time left; test `post: one row per price for
  commodities`). Test page build id `0-6-0-2-build-2`.
- **Build 2 in game** (Tyler, 2026-10-09, `builds/0-6-0-2-build-2/results`): no steps marked,
  three screenshots, all as expected. Light Feather: one row of 581 at 8c and his own 2 as a green
  row. Tel'Abim Banana: after "Posted 1", the table read again and his 1 shows green at 26c. Merc
  Sword (gear): loads as before, one row per kind of auction (5 at 12h and 1 at 24h, both 10s),
  no error.
- **Build 3** (2026-10-10, Tyler asked before the release whether the Post tab is as fast as it
  can be): `refresh_entries` searched the item's name (browse request) before reading its listings
  (search request). It now takes the item key from the bag item (`C_AuctionHouse.GetItemKeyFromItem`,
  as Blizzard's Sell tab does on Forever: `Blizzard_AuctionHouseItemSellFrame.lua`, build 70338)
  and reads it with one request; the name search is the fallback when the item is not in the bags.
  Test: `post: an item in the bags is read with one request`. Not measured: `/aux debug` prints
  where a search's time went.
- **Build 3 in game** (Tyler, 2026-10-10, `builds/0-6-0-2-build-3/results`): speed pass, posting
  pass, measuring skipped. Fail: Merc Sword (gear; the auction house lists "of the Owl", "of the
  Eagle" and other versions) showed no listings, only the usual-price row. Its item key from the
  bag holds the random suffix and the search by that key found nothing; Blizzard's Sell tab asks
  for gear with `SendSellSearchQuery` (by item ID) instead (`Blizzard_AuctionHouseFrame.lua`,
  `QueryItem`, `byItemID` = `isEquipment`). Also seen: the Post tab lists all versions of a gear
  item as one item ("Merc Sword") and prices it against all of them (11s to 60s); that was so
  before this version too, left for later.
- **Build 4** (2026-10-10): the one request only for items that are not gear
  (`GetItemKeyInfo(key).isEquipment` false); gear keeps the name search as in build 2. Test
  extended (gear keeps the name search; fails without the check). Test page build id
  `0-6-0-2-build-4`.
- **Build 4 in game** (Tyler, 2026-10-10, `builds/0-6-0-2-build-4/results`): trade goods pass;
  posting (Light Feather, his new auction green) as expected. Merc Sword marked fail with "Shouldn't
  this be showing all of the types of Merc swords in the post search?": the Post tab showed one row
  (2 at 11s, 12h) while the Search tab showed 55 auctions across Eagle, Intellect, Agility, Nature
  Protection, Wolf and Strength (11s to 60s). Build 4 behaves like build 2 and 0.6.0.1 here; the
  cause is older: the name search lists one item key per version, and `refresh_entries` stops after
  the first key with listings (`on_page_scanned`, unless `/aux post full scan` is on), so gear is
  priced against whichever version comes first, not the player's own. Not a regression of 0.6.0.2.
  Proposed to Tyler: release 0.6.0.2 as it is, then fix gear versions on their own (see
  `docs/roadmap.md`, "Gear versions on the Post tab"). Tyler agreed and said release.
  Left alone: a re-pick may wait 1 second when the client does not announce results it already
  holds (`request`, the `cached` fallback); unconfirmed in game.

- **Released 0.6.0.1** on 2026-10-09 (PR #18, `main` b17b9bc): "Search in aux" no longer covers
  Blizzard's Track Recipe checkbox (details below). Tag `v0.6.0.1`, GitHub pre-release
  https://github.com/TylerHampton/aux-forever/releases/tag/v0.6.0.1, CurseForge Beta file id
  9114589 (Release run 38020724242). `/reload` was enough for players.
- **Released 0.6** on 2026-10-09 (PR #15, 49cc8cf): webster's new look plus the Classic theme,
  the two-column Settings menu, the Post panel redesign (option A), the Sniper's 3-day rule and
  price history line. Tag `v0.6`, CurseForge Beta file id 9114535. Needed a full game restart
  (new texture `warning.tga`). Full list: `docs/changelog.md`, 0.6.
- **CurseForge uploads are automatic and proven** (Release workflow, secret `CF_API_KEY`). The
  first try failed: `curl -F` cut the metadata JSON at a ";" in the changelog; fixed with
  `--form-string` in `.github/scripts/curseforge.sh` (PR #16). The project page description is
  still pasted by hand by Tyler: `docs/curseforge-description.md` was updated for 0.6; ask Tyler
  whether he has pasted it.
- **How a release goes** (worked twice on 2026-10-09): Tyler tests the build on the test page,
  says it is ready; the changelog section gets its date; a PR from the session branch to `main`;
  after its tests pass, merge (Tyler asked for it); trigger `release.yml` on `main` through the
  GitHub API; read the "Upload to CurseForge" step's log for `{"id": ...}` and "Uploaded."; then
  update this file in a small PR. Run the 5-minute check (`TESTING.md`) before a minor release.
- **Version numbers** (Tyler, 2026-10-09): a bug fix raises the fourth number (0.6 -> 0.6.0.1
  -> 0.6.0.2); a bigger update within the same version raises the third (0.6.1); new features are
  the next minor version (0.7).
- **Changelogs** list every change with a little detail, grouped by area (Tyler: never "minor bug
  fixes"); rule in AGENTS.md.
- **Next version:** not chosen. Candidates are in `docs/roadmap.md`, "After 0.6". Tyler planned
  about one release a week; two went out on 2026-10-09.
- **Open questions for Tyler:** none from before 2026-10-17 (all answered that day, see Start
  here). Current ones are in Start here.
- **How Tyler tests:** one test page, https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ
  (`index.html` with a `BUILD` id and `AREAS` steps; he marks Pass/Fail with notes and
  screenshots; read with ArtifactData, collection `builds/<build id>/results`, and download each
  screenshot with Artifact read, `path` = the asset id). Last used: `0-7-1-build-3` (passed 2026-10-17). He
  often uploads screenshots without marking a status: read the screenshots. Zips:
  `auxForever-<version>-build<n>.zip`, sent with the file tool; say whether `/reload` is enough.
- **Mockups:** the Post panel mockup (options A, B, C, A chosen) is
  https://claude.ai/artifact/FQAKTqLUF4NQrSiAXV8ERK (a Design canvas).
- **Blizzard patches move things:** the 2026-10-08 patch (build 70291) reversed the bag order and
  moved Track Recipe; a newer build 70334 (2026-10-09) exists in Gethe/wow-ui-source, branch
  `forever`. When something in Blizzard's frames looks different, diff the builds there first.

### 0.6.0.1: Search in aux and Track Recipe

Tyler found "Search in aux" covering Blizzard's Track Recipe checkbox. Cause, from Forever's UI
source (Gethe/wow-ui-source, branch `forever`, `Blizzard_Professions/Camelot/
Blizzard_ProfessionsCrafting.lua`, diff of builds 70245 and 70291): Blizzard's 2026-10-08 patch
moved the checkbox from BOTTOMLEFT (17, 11) to BOTTOMRIGHT. Fix: `recipe_button_spot` /
`place_button` in `tabs/search/recipe.lua` put the button left of the checkbox when the checkbox
is anchored on the right (read from its `GetPoint`), placed again on each `Init`. Tested in game
2026-10-09 (`builds/0-6-1-build-1/results`) and released.

## 0.6 build log, builds 7 to 10 and the release (2026-10-09, branch `claude/upbeat-davinci-jqwq9d`)

0.6 builds 1 to 6 were merged into this branch from `claude/eager-dijkstra-drmz2k`. Next build is
build 7. Build 6 was never tested in game; Tyler wants one test page for everything (build 6's
Sniper steps plus the Post panel).

Tyler, 2026-10-09: the Post tab's top panel (item, Count, Duration, prices, Match lowest / Undercut,
the money line, Post) "feels outdated"; change how it is presented only, no functions added or
removed. His points: the price fields take far too much width for a price of at most
"9999g 99s 99c"; the vendor line under "You get" is unreadable. Scope: only that panel, not the bag
list or the auctions table. The ? button stays (move it if needed). Pay homage to TSM3 and the
original aux: aux's README says its look was "based on the retail addOn TSM" and its post price
input "inspired by the retail addOn TSM" (github.com/shirsig/aux-addon-vanilla).

Mockup: https://claude.ai/artifact/FQAKTqLUF4NQrSiAXV8ERK (today's panel and options A, B, C).
Tyler picked A (2026-10-09) with two tweaks: keep the goblin on Undercut, and a red warning
triangle when a vendor pays more ("they should not be able to miss it"). He also sent a goblin
picture found online as the model for a new goblin; it looks like a stock icon (Icons8 style) that
needs a license or a credit link, so it was not copied or traced. `textures/goblin.tga` is a new,
original drawing in the same flat style (big ears, two greens, yellow eyes, a grin with teeth),
drawn with Python/PIL at 16x and scaled to 64x64.

Build 7 (same day): option A built (`tabs/post/frame.lua`, `update_item_configuration` and
`price_note_text` in `tabs/post/core.lua`). New file `textures/warning.tga` (white triangle, black
mark, tinted with the palette red), so a **full game restart** is needed. New receipt widgets:
`cut_label`/`cut_summary`, `net_label`, `deposit_label`, `receipt_line`, `vendor_warning` (shown
or hidden only when it changes), `usual_caption`. `posting_summary` is now "Total, N items" and
`total_summary`, `net_summary`, `deposit` hold only the amounts. Two new lines on screen, approved
with the mockup: the auction house cut, and "Bid equals buyout, so it posts as buyout only" for
gear (what `item_post_prices` already did). The "On Forever the newest listing..." sentence left
the note; it stays in the ? tooltip. Layout sized for the smallest window (panel about 777 wide):
the % column ends at the middle divider there. Not tried in game; test page build id
`0-6-build-7` (11 steps: 8 Post, build 6's 3 Sniper), results in `builds/0-6-build-7/results`.

Build 7 in game (Tyler, 2026-10-09, `builds/0-6-build-7/results`): goblin and bid note pass;
gear, trade goods, vendor warning (both themes), posting and both tooltips look right in the
screenshots. Found: PER ITEM overlapped the top of the first price field; at a narrow window OF
USUAL was cut off by the divider; Linen Cloth's deposit read "-0c". Build 8 fixes all three
(`price_layout` in `tabs/post/frame.lua` and a test that fails on build 7's numbers). Sniper: no
gray items (pass). Every deal was "below vendor" with Usual "?", and Tyler wrote "I guess my data
is just gone idk". Not lost: the Post tab shows "% of usual" for the same items, so the history is
there. Inferred cause: build 6 counts only PAST days with a complete look (`cached` in
`core/history.lua`, today is not counted), and complete looks exist only since 0.5 (2026-10-08),
so no item can reach `MIN_DAYS` = 3 before 2026-10-11 at the earliest. Asked Tyler whether today's
Full scan should count. The empty-list step was written wrongly on the page (Stop then Clear shows
"Press Start..."; the gray-items message shows only while running); rewritten for build 8.

Build 9 (same day, Tyler: "build it"): asked whether the Sniper should require a Full scan before
it runs. Decided: a warning, not a lock (a lock would hide below vendor deals that need no
history, the game allows a Full scan once every 15 minutes per account, and it would not shorten
the 3 days). Built: today's complete look counts toward `MIN_DAYS` (`cached` in
`core/history.lua`); `sniper.history_notice` (pure, tested) gives the line next to "Deals": orange
"Your last Full scan was N days ago..." when `account_data.replicate_time` is more than 2 days old,
else "...after 3 days of Full scans; you have N so far" while `history_days` (the most days any
item had while the round judged it, no extra work) is below 3 after the first round, else
nothing. A Full scan button beside it clicks `aux.full_scan_button` (exported from `frame.lua`).
Redrawn only when the text changes (in `update_controls`, five times a second while the tab is
shown). Note: `replicate_time` is set when a Full scan starts, even if the server never answers.

Build 9 in game (Tyler, `builds/0-6-build-9/results`): headings clear of the fields, OF USUAL
whole at the smallest window, deposit 0c, the Sniper shows usual prices again (4s, 10s; today's
scan made 3 days) and no notice (fresh data). Tyler's notes, built in build 10: "Just put Of Usual
below the percentage" (the heading is gone; each % has "of usual" under it, `badge` in
`tabs/post/frame.lua`), and under the Sniper's running-with-no-deals message add "Sniper works best
with fresh Full scan data." Test page build id `0-6-build-10`.

Build 10 in game: "of usual" under the percentage and the Sniper's third line look right
(screenshots, `builds/0-6-build-10/results`). Tyler asked to release 0.6 to CurseForge
(2026-10-09). Done: changelog dated, CurseForge description updated (Tyler pastes it by hand),
PR https://github.com/TylerHampton/aux-forever/pull/15 opened. Pre-release check passed
(Tyler, 2026-10-09, test page `0-6-release`: open, buy, post, Auctions "Tied with 130 others",
a Sniper round, the Materials line). The changelog was rewritten in full on Tyler's request (rule
now in AGENTS.md). PR 15 merged (49cc8cf); the Release workflow published the GitHub release
v0.6 (https://github.com/TylerHampton/aux-forever/releases/tag/v0.6), but the first automatic
CurseForge upload failed: 400 "Invalid JSON" in `metadata`. Cause: `curl -F` treats ";" in the
changelog text as a field option and cut the JSON; reproduced locally. Fixed with `--form-string`
in `.github/scripts/curseforge.sh` (PR after #15), then the Release workflow was run again.

## 0.6 build log, builds 2 to 6 (2026-10-09, branch `claude/eager-dijkstra-drmz2k`)

Tyler, 2026-10-08: webster (a collaborator who designs UIs) made build 1 on the branch
`design`; he is done with it. Tyler wants three ways to see the auction house by 1.0:
Blizzard's (the Blizzard UI button), the 0.5 look (Classic) and webster's (New). New is the
default, also for players updating from 0.5. Tyler plans about one release a week; 0.6 is not to be released yet.

Built (tests pass in both looks; checks for Tyler in `TESTING.md`, Current build):
- Look switch: Settings, Look: New or Classic, saved in `account_data.theme` (account-wide). It
  takes effect at the next login or reload; a Reload now button appears when the choice differs
  from what is on screen. Classic is the 0.5 palette and rounded corners on webster's layout (same
  sizes and positions), flat buttons (no sheen), no top and bottom bands.
- How it works (`gui/core.lua`, "the look"): widgets are built while the files load, before the
  saved settings exist. Shapes wait until `gui.settle_theme` (called at the end of `AUX_LOADED` in
  `aux-addon.lua`) and are then built square or rounded. Every color set at load goes through
  `gui.themed`; for Classic that list is painted again, then dropped. In New nothing is painted
  twice. Color objects keep their numbers in a table that `aux.set_palette` rewrites, so colors read
  later follow the look. AGENTS.md, Design language, has the rules.
- Zebra rows (Tyler): every second row of the result tables (`auction_listing`) and the other tables
  (`listing`) has a faint light shade (`color.stripe`, white 4% in New, 3.5% in Classic as in
  0.5), under hover and selection. The Post tab's bag list has none (it had none in 0.5 either).
- New look, blacks toned back (Tyler: "it's hard to tell where the text boxes are", the Filter
  Builder; "I do like the blackness of it"): window 22 to 26, panels 12 to 19, bands 11 to 16,
  sunken fields 10 to 12 with a gray edge (64) instead of black. A test keeps the edge at least 30
  levels lighter than the panel.
- Settings, TOOLTIP LINES (this character): the seven `/aux tooltip` lines as checkboxes (FB-008,
  a CurseForge player). Not added, waiting on Tyler: action shortcuts, ignore owner, post full scan,
  post bid, clear item cache, clear post. Left out on purpose: debug, memory, price.
- Hard-coded colors moved into the palettes: scroll bar thumb, input focus edge, status bar, the
  Post tab's switch track, the buy bar's chosen quantity (now the `selected` look, redrawn only when
  the choice changes).
- Tests: `lua5.1 ../tests/load_test.lua classic` runs every test in Classic; the workflows (Tests,
  Release) run both. The harness now keeps the colors set on stub frames (`__text_color`,
  `__texture_color`, `__vertex_color`).

Build 3 (same day): the Settings menu as in the mockup Tyler approved
(https://claude.ai/artifact/21FjqFGt2vzbVo9BDG5d6j): 600 wide, two columns. Left: WINDOW
(Background, Scale, Look, and the reload row when the look changes) and POSTING (Default duration,
Bid prices Off / Item / Stack, which moves up when no reload waits). Right: TOOLTIP LINES with an
on/off switch each (`gui.switch`: square in New, rounded in Classic; color `switch_knob`). Bid
prices (`/aux post bid`) now applies at once from the menu and the chat command
(`post.apply_bid_layout`); it used to need a reload. Ignore owner, action shortcuts (Tyler: risky,
buys gear in one click) and debug stay chat only.

Build 4: "Bid prices on the Post tab" and its gray line ran under the Off / Item / Stack buttons
(Tyler's screenshot); the row is now just "Bid prices", explained in its tooltip. Tyler also saw
his bags (Blizzard's Combined Backpack) with the items in reverse order and no cleanup button. Not
from auxForever as far as the code shows: it only reads bag contents and hooks clicks
(`core/shortcut.lua`, unchanged in 0.6), and never touches bag settings or bag buttons. Cause found
the same day: Blizzard's patch of 2026-10-08 (build 70291) changed the bags, not auxForever. In
Forever's UI source (`Gethe/wow-ui-source`, branch `forever`, diff of builds 70245 and 70291,
`Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua`) the mouse and keyboard sort
`SortItemsBottomRight` (highest slot first, so the first slot showed at the top left) was replaced
by one ascending sort for everyone, while the first item is still anchored at the bottom right. So
the first slot now shows at the bottom right: the order Tyler saw as inverted. The same patch added
gamepad bag features, which likely caused it (inference). The Clean Up button
(`BagItemAutoSortButton`) is unchanged in the code and still placed at the top right next to the
search box; Tyler does not see it, which the code does not explain (open). Not auxForever's to fix:
changing Blizzard's bag frames from an addon risks breaking them further.

Build 4 in game (Tyler, 2026-10-08, test page `0-6-build-4`): open, table, buy bar, other tabs,
Classic all fine (Classic: pass; other tabs: pass; no notes on open and table, their screenshots
look right: gray edges on the Filter Builder boxes, zebra rows). Findings:
- The Buy button showed "4s 60c" without coin colors (it used the plain form). Tyler: g, s and c
  must have their coin colors everywhere, as a global rule. Fixed in build 5: buy bar buttons,
  recipe line, Sniper prices and profit; rule in AGENTS.md (Design language). Classic's primary
  and confirm looks are no longer solid filled (dark amber or green with an outline) so the coin
  colors stay readable on them.
- "It should be called theme, not look." The Settings row and its texts say Theme (build 5).
- Bid prices: Tyler found it confusing and asked whether "per stack" makes sense. It does not on
  Forever (bids only on gear, one item per auction, few sellers set one). Removed from Settings
  (build 5); `/aux post bid` stays and applies at once. FB-008.
- Sniper (open, not changed): first time it listed deals by "% of usual". Every deal in Tyler's
  screenshot is priced 1s 00c, with usuals like 90s (Trapper's Shirt) and 79s (Fading Echo). Likely
  real 1-silver listings (items on Forever are listed in whole silver, so 1s is the floor) against a
  usual price raised by high asking prices (`docs/price-data.md`, weak points: it records listings,
  not sales). His profit setting was 5c, which lets almost any 1s listing through. To check: Tyler
  runs `/aux price` on two of the deals and searches them; read the chat output before changing the
  Sniper.

Build 5: coin colors everywhere, Theme, Bid prices out of Settings (above).

Build 5 in game (Tyler, test page `0-6-build-5`): buy button, settings, Sniper colors pass; recipe
line and Classic buttons unmarked, screenshots look right (colored g/s/c; Classic Search and Buy
dark amber with an outline).

Sniper check (Tyler, 2026-10-09, `/aux price` and searches): Fading Echo (gray) is 13 listed at 1s
by 2 sellers; its usual of 79s rests on two 0.4 days that kept only the lowest asking price (no
listed count), while yesterday's complete look saw 1s. Trapper's Shirt: one listing at 1s, and
`/aux price Trapper's Shirt` said "No price history for this item yet" although the Sniper showed a
usual of 90s; unexplained (open: maybe the name lookup finds another item id; ask for the command
with a Shift-clicked link). Tyler: "gray items definitely cannot be in the sniper", "Sniper is to
make money", and junk with a single listing should stay out ("who's going to buy it?").

Build 6 (Sniper):
- Gray (poor quality) items are never deals, below vendor price included
  (`sniper.item_facts` gives them no prices).
- The 3 days of history a deal needs (`MIN_DAYS`) count only days with a complete look, i.e.
  points with a listed count (`history.value_and_complete_days`), not 0.4 lines or days that only
  saw single auctions. The usual price itself is unchanged (still from all days).
- Not done, asked Tyler: a rule against thin markets (an item with one listing). Gear is often one
  listing too, so a "too few listed" rule would also hide real gear deals; needs his call.
- Tyler's profit setting was 5c, which lets 30c deals through; suggested 1g.

Test page: build id `0-6-build-6` (3 steps, the same as `TESTING.md`), results in ArtifactData
collection `builds/0-6-build-6/results`.

Open questions for Tyler:
- The CurseForge player's in-game name (changelog credit, FB-008) and which of the not-obvious
  commands above belong in Settings.
- His tweaks to webster's look (he will send screenshots).

## 0.6 build 1: the new look (2026-10-08, branch `design`, by webster)

Tyler asked to "take the ui kit and screens and make the addon look like that". The design is the
Paper file "auxForever Screens", pages "UI Kit" (every color, size and control) and "New" (the seven
screens). A "New v2" page with a Barlow design was tried in an earlier session; it is no longer in
the file, so it is not what was built. TOC `forever-0.6`.

Build 1 (not tried in game yet): a restyle only, no change to searching, buying or posting.
- `color.lua`: the kit's values (gold 229,190,91; black edges; text #EBEBEB; status colors for the
  percentages and money). Key names unchanged, so every caller keeps working.
- `gui/core.lua`: square shapes (the rounded corner textures are no longer used), `add_sheen` (a
  black gradient over a raised control's fill plus a light top line; falls back to a flat shade if
  the client's `SetGradient` differs), button looks (`apply_look`; Enable and Disable redraw), tabs
  as raised buttons 1px apart, gold outline on a focused input, the status bar as a sunken track,
  `row_selection` and `row_hover` for tables.
- Tables: raised header plates, sorted column white with a gold chevron (`chevron.tga` rotated), no
  stripes (the kit says "no stripes"), selected row gold 13% with a 2px gold bar, hover white 6%.
- Window: darker bands top and bottom that fade with the Background setting; status bar 265x22 in
  the bottom band; logo "aux" white, "Forever" gold.
- Buy bar: no box of its own, quantity chips 64px (80 for the stack), Buy 160px with the primary
  look, Confirm green. The kit's 80px chips and 190px Buy do not fit the 1000px minimum window
  next to the Quantity box, so they are a little narrower.
- Not matched: the font (Forever loads no addon fonts; sizes stay as they were, the game font
  needs them), the layouts of each screen (the kit screens mostly follow the existing layouts;
  differences such as the Fast/Full sunken track are approximated with two buttons).
- Edges are 1-unit lines; at some Scale settings they may render uneven. If so, set their size with
  `PixelUtil` in `create_shape` (`gui/core.lua`).
- The test page (artifact LUCZVgJV27irizAyKHTjhJ) could not be read from this session ("not
  found"); build 1's steps are only in `TESTING.md`.
- Tests and syntax check pass under Lua 5.1.5 (built from lua.org source on Tyler's collaborator's
  Mac; Homebrew has no lua@5.1).
- Open question for Tyler: zebra rows. He asked for a zebra version of an earlier design; the kit
  says no stripes, so build 1 has none. Easy to add back. (Answered 2026-10-08: add them back in
  dark gray; done in build 2.)

## Earlier start notes (after the 0.5 release; history, superseded by Start here above)

- **Released: 0.5** on 2026-10-07. `main` is at its merge (PR #11, e27b711); tag `v0.5`; GitHub
  pre-release https://github.com/TylerHampton/aux-forever/releases/tag/v0.5. Tyler uploaded 0.5 to
  CurseForge by hand.
- **CurseForge uploads are automatic from the next release on:** the Release workflow uploads the
  zip as a Beta file with the changelog (project 1727417, secret `CF_API_KEY` set by Tyler on
  2026-10-07). The CurseForge check workflow confirmed the token works and that CurseForge lists
  game version 1.60.1 under "WoW Forever" (id 17053). Not yet used for a real upload; watch the
  first one. The page description is still pasted by hand when it changes.
- **Which version next:** Tyler has not chosen. Rules (`docs/roadmap.md`): 0.5.x is bug fixes,
  speed and small things only; new features go into 0.6. If players report bugs in 0.5, they go
  into 0.5.1 (or a hotfix if bad: money spent wrongly, repeated errors, a broken tab, lost data).
- **Candidates, none decided** (details in `docs/roadmap.md`, "After 0.5"):
  1. Sniper rework (0.6): the hold on a selected deal, clear feedback on each buy in a fast market.
  2. Auctions tab: show the starting bid of your own auctions, if the game gives it (unverified).
  3. The redesign with Tyler's designer friend (0.6 or later; TSM and the original aux direction,
     AGENTS.md Design language). Designs are not in the repository yet.
  4. Small loose ends from 0.5 (0.5.1 material), listed under "Open after 0.5" below.
- **Player feedback:** `docs/feedback.md`. FB-001, FB-002, FB-003, FB-006, FB-007 are done in 0.5;
  FB-004 rejected (direction); FB-005 praise; FB-009 (Classic stacks, Maggew) wont-fix. New entries start
  at FB-010 and are recorded by a separate feedback session, not by the session that builds.
- **Audience (Tyler, 2026-10-09):** auxForever is for intermediate players who know Forever's modern
  auction house. Requests for things that auction house does not have are answered, not built
  (AGENTS.md, the exception after "a player's problem is the addon's problem").
- **How Tyler tests** (worked well all through 0.5): each build gets a zip (sent with the file tool)
  and steps on the test page https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (republish
  `index.html` with a new `BUILD` id and steps; Tyler marks Pass/Fail with notes and screenshots;
  read them with ArtifactData, collection `builds/<build id>/results`, and download screenshots with
  Artifact read, `path` = the asset id, one at a time). Keep `TESTING.md` "Current build" in step
  with the page. The pre-release check is six steps, about 5 minutes (Tyler's limit).
- **Things that confused testing before** (check these first when a screenshot looks wrong):
  Tyler screenshots with Win+Shift+S, which holds Shift (tooltip prices then show the whole stack,
  "for 3") and hides the item on the mouse pointer.

## Open after 0.5 (loose ends; still open unless noted in Start here)

- Damaged gear and posting (FB-003): never tried in game. The Post tab says "must be repaired"
  if aux finds damaged gear it cannot post; whether Forever lists damaged gear at all is unknown.
- Converted 0.4.1 history: until about two weeks of 0.5 days are recorded, "usually ..." lines
  and the Sniper's percentages still lean on 0.4.1's daily lows, some of them single cheap
  auctions (Linen Cloth "usually 8c" while it sold at 23c to 33c). Expected to wash out; check
  again after a couple of weeks of play.
- The "usually" threshold (30%, `USUALLY_SHARE`) and the market price share (5%,
  `MARKET_SHARE`) in `core/history.lua` are first settings, checked on a few items only.
- The tooltip "Today" line (setting `/aux tooltip daily`, off for Tyler) still shows today's
  lowest and its percentage of the usual price; untouched in 0.5.
- `docs/curseforge.md` and `-description.md` were updated for 0.5; check the Usage section again
  whenever clicks change.

## 0.5 build log (2026-10-07, branch `claude/youthful-curie-ghbvlt`, released as PR #11)

Branch `claude/youthful-curie-ghbvlt` from `main` (dd040f9), TOC `forever-0.5`. Test build 2 is out
(see Build 1 results below). Test build 1 was
(zip sent to Tyler; test page https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ, results in
ArtifactData collection `builds/0-5-dev1/results`). No new files, so `/reload` is enough. All six
handoff items are built, each with tests that fail without the change; none is tried in game yet.

1. Price data (e1c852a): market price per day from complete views, usual price weighted to recent
   days (half-life 7 days, 14 days kept), "seen N days ago" in tooltips, history version 3 with
   lazy conversion of version 2. Details: `docs/price-data.md`, start of "Plan for 0.5".
2. FB-003 (7a187c7): every way a post ends says what happened (Post tab, left column under
   Duration, and chat on failure); a faded Post button says why. PostItem's return value is read
   as "needs confirmation" (as aux's code always did), not as a failure: unverified against the
   API docs, inferred from the code.
3. FB-006 (31ac02c): `gui/listing.lua` lays out again on show and on content size change; the last
   column is anchored to the right edge.
4. Click standard and FB-002 (140996a): Tyler approved the standard on 2026-10-07. Blizzard's
   Forever bag code sends a right-click to `AuctionHouseFrame:SetPostItem`; aux follows it.
   Details and what was not changed: `docs/clicks.md`, "Built in 0.5".
5. FB-001 (6f77958): option B of the mockup (Tyler: "Everything looks good").
6. FB-007 (5a935e1): the cost line under the reagent list; its position comes from Blizzard's
   source, not seen in game yet.

Build 1 results (Tyler, 2026-10-07, test page collection `builds/0-5-dev1/results`): 14 pass, 5
fail, 3 skipped, 1 unmarked (Full scan memory: 17.8 MB, 9.9 MB after a cleanup, 3,457 items of
history; fine). Failures and what was done (build 2, `builds/0-5-dev2/results`):
- Right-click a Post price row: BugSack "attempt to index global 'selected_item'" (tabs/post/
  frame.lua:87). Leaving the Post tab clears selected_item before its name was read. Fixed; the
  build 1 test missed it because it used tab 4 (Auctions) for Post (Post is tab 3).
- Click hints: one wrapped gray paragraph, hard to read (Saved Searches). Now one line per click,
  click left, action right (`gui.add_click_hint`). aux.split only handles one-character separators.
- Quantity box: Tyler: the cursor mark "looks like its a bug". Removed.
- Price tooltips "not even close" (Tel'Abim Banana: Value 2s 61c, listings 38c to 1s). Analysis:
  the search table at the same moment showed 44% of usual at 38c, so the usual price was 87c; the
  tooltip's 2s 61c is exactly 3 x 87c, the price of his stack of 3 (Shift multiplies by the stack;
  Windows' screenshot keys Win+Shift+S hold Shift). So two things: the stack total was not labeled
  (fixed: "for 3"), and the usual price on day one of 0.5 rests only on the daily lows recorded by
  0.4.1 (Simon's method), because today's market price only counts after midnight, as in Simon's
  aux. Proposed to Tyler: count today's market price in the usual price as the newest day. Not
  built; waiting for his answer. `/aux price <item>` added to see what was recorded.
- Post locked test step: Tyler did not understand it; reworded (optional).
- Not a failure but found in a screenshot: the recipe cost tooltip's Total was red (colors passed
  as a color's four values). Fixed.

Build 2 results (Tyler, 2026-10-07, `builds/0-5-dev2/results`): Post right-click, hints, quantity
box pass; stack label works ("Value: 2s 61c for 3" with Shift, 87c without). `/aux price` on the
banana confirmed the analysis: usual 87c from 2 past days, both 0.4.1 daily lows (87c two days
ago, 11c three days ago); today lowest 38c, market 39c (cheapest fifth of 82 listed). Light Feather:
usual 4c (0.4.1 lows), lowest today 7c with 1,861 listed. Fixed after build 2 (5338888, not yet in a
zip): the cost tooltip's prices were gold (the game's default right color), the Post locked message
was cut off.

Price question (Tyler, 2026-10-07): players do a full scan, post and leave within minutes, and need
to trust the tooltip away from the auction house; heavy averaging that lags the market loses that.
Claude's proposal sent the same day (waiting for Tyler): tooltips and the recipe cost show the
latest market price (the most recent complete look, with its age), and the multi-day usual price
stays for finding deals (Sniper, the search % column, percentage filters), shown in the tooltip only
when it differs a lot from the latest. Not built.

Tyler approved the proposal ("Yes build it, the text examples are enough"). Built in build 3:
`history.latest`, tooltips and the recipe cost use it, "usually ..." at a 30% gap; details in
`docs/price-data.md`. Test page collection `builds/0-5-dev3/results`.

Build 3 results (Tyler, 2026-10-07, `builds/0-5-dev3/results`): banana tooltip 38c each (pass);
Full scan alone recorded Rough Dynamite at 30c, its lowest listing, so Full scan prices look right;
Linen Cloth 32c with 296 listed at 23c ("The full scan NOR the search fixed the tooltip??"): the
average of the cheapest 20% is too deep for big markets. Also: hovering the faded Post button did
nothing; the Full scan looks stuck for 7 to 8 seconds before its bar moves (Tyler: help impatient
players see a scan is running); a right-clicked bag item stayed locked (Blizzard's hidden Sell tab
calls C_Item.LockItem on it, source: Blizzard_AuctionHouseSharedTemplates.lua, forever branch), so
it could not be picked up and aux posted from another stack. All four fixed in build 4
(`builds/0-5-dev4/results`): market price = middle of the cheapest 5% of units, the right-clicked
item is cleared from Blizzard's Sell tab (ClearPostItem), a Post button tooltip, status bar text
during a Full scan.

Build 4 results (Tyler, 2026-10-07, `builds/0-5-dev4/results`): Full scan status text passes;
Linen Cloth Value 33c with 712 listed at 33c and 2 at 3c (the outliers were ignored: right); the
faded Post button's tooltip shows the reason. The right-click unlock step has only a screenshot of
"Not posted: the item is on your mouse pointer..." on Ritual Bands, no note: either the item was
still on the pointer when Post was clicked (expected message) or it was still locked after the
right-click (the bug). Tyler: he was holding the item (Win+Shift+S hid the pointer in the
screenshot); the fix works.

The 15-minute pre-release quick run was too long for Tyler; replaced by a 5-minute, six-step check
(`TESTING.md`, Before every release; test page collection `builds/0-5-release/results`).

Release check on build 4 (Tyler, 2026-10-07, `builds/0-5-release/results`): all six steps pass
(open, buy one linen cloth, post, Auctions tab, a Sniper round, the Materials line on Herb Baked
Egg).

Release (Tyler, 2026-10-07: "Yes"): he also asked to stress Full scans. Added: a second login line
saying when the last Full scan was (`full_scan_reminder` in `aux-addon.lua`), a "Get the most out
of it: run a Full scan" section and a corrected "Prices" section on the CurseForge page
(`docs/curseforge.md`, `docs/curseforge-description.md`). Changelog dated, with Darkhorse and
Garsterson credited on each change from their feedback and named at the top. Then the pull request
into `main`, merged, and the Release workflow (`v0.5`).
- The Sniper and Auctions tab notes (`docs/roadmap.md`, 0.5): Claude recommended leaving them for
  after 0.5; Tyler has not decided.
- Asked Tyler: whether to do the Sniper and Auctions tab notes in `docs/roadmap.md` (0.5) tonight
  (he asked what they were; explained 2026-10-07, waiting); whether today's market price should
  count in the usual price. FB-002's suspected bug: he does not remember. Damaged gear (FB-003):
  skipped in build 1.
- Mockup page for this build's visual items: https://claude.ai/artifact/SX8EwZHbgqS94ZBGhUtJCg

## 0.5: start here (handoff written 2026-10-07 by the feedback-logging session; done, see above)

Tyler is opening a new chat on 2026-10-07 to build 0.5 the same night. Everything it needs is in
the repository; this list is the order of work. Read `AGENTS.md` first, then this, then the files
named.

- **Branch:** a new branch from the latest `main`. The feedback log and these notes were merged
  into `main` from `claude/exciting-tesla-3jksts` (if that pull request is still open, merge it or
  read from that branch). TOC version `forever-0.5`. Changelog heading `## 0.5 (date)` when
  released.
- **No 0.4.2** (Tyler): every small fix found since 0.4.1 goes into 0.5.
- **Scope, in this order** (each with a test that fails without it; AGENTS.md, Tests):
  1. **Better price data:** `docs/price-data.md`, "Plan for 0.5" (what changes, what stays, cost,
     risks, tests). Foundation for 6. No layout change except the age next to Value in tooltips.
  2. **FB-003, silent failed post:** every way `post_auction` (`tabs/post/core.lua`) can stop
     without a word gets a message saying why. Details in `docs/feedback.md`, FB-003. Ask Tyler for
     the damaged-gear check listed there if it helps; do not wait for it.
  3. **FB-006, Recent Searches header sticks out** after resizing and a scale change
     (`gui/listing.lua` fixed column widths). Screenshot and steps in the entry.
  4. **Clicks made consistent, including FB-002** (right-click a bag item loads it into the Post
     tab). Tyler asked on 2026-10-07 for clicks to be predictable across every tab. The full click
     map, the findings and the proposed standard are in `docs/clicks.md`; show Tyler its standard
     table (and the hover hint mockup) for an OK before changing clicks. Check Blizzard's Forever
     bag click code first (FB-002 explains why: aux keeps Blizzard's window invisible but open, and
     the click may go there). Ask Tyler what bug he suspected there (FB-002, Ask Tyler).
  5. **FB-001, the buy bar's quantity box** should look like a place to type. Visual: mockup first.
  6. **FB-007, crafting cost in the profession window**, anywhere in the world, at usual prices;
     design decided in the entry (one line, "+" when a material has no price, tooltip with
     details). Visual: mockup first.
  7. Only if Tyler wants them tonight (ask): the 0.5 notes in `docs/roadmap.md` (Sniper hold and
     buy feedback, Auctions tab starting bid).
- **Not in 0.5 tonight:** the redesign with Tyler's designer friend (direction: TSM and the
  original aux, AGENTS.md Design language); the designs are not in the repository yet.
- **Mockups:** show the FB-001 and FB-007 mockups and the click standard (`docs/clicks.md`) together early, so Tyler can approve them while
  steps 1 to 4 are built.
- **Credit** (Tyler's rule, `docs/feedback.md` Credit): changelog lines for FB-001, FB-002, FB-003
  end "(suggested by Darkhorse)" or "(reported by Darkhorse)"; FB-006 "(reported by
  Garsterson)", FB-007 "(suggested by Garsterson)". Not FB-004 (rejected) or FB-005 (praise).
- **When an entry is done:** set its status in `docs/feedback.md` (index and entry), add its
  in-game check to `TESTING.md` and the build's test page, give Tyler the zip and say whether
  `/reload` is enough or a full restart is needed (new files need a restart).

## Earlier notes (0.4.1 and before)

- Released: 0.4.1 (2026-10-05) is the latest; `main` is at its merge (#8, ea73c6a).
- **Player feedback log (started 2026-10-07):** `docs/feedback.md`. Tyler passes on what players
  say; one Claude session records it there (no fixes in that session) and a separate session or
  agent fixes from it. Check its index for entries with status `new` or `confirmed` before
  planning 0.4.x or 0.5. First batch (2026-10-07): FB-001 to FB-005 from Darkhorse (buy quantity
  box, right-click from bags to Post, a silent failed post, the UI overall, praise for the Post
  tab's bag list). FB-004's direction (closer to Blizzard's auction house) was rejected by Tyler:
  the redesign follows TSM and the original aux. Players are not asked follow-up questions; open
  questions for Tyler are under "Ask Tyler" in each entry.
  Second batch (2026-10-07): FB-006 and FB-007 from Garsterson (Tyler's brother): the Recent
  Searches header sticks out of the window after resizing and a scale change; crafting cost in the
  profession window anywhere in the world (Tyler: cost only, no profit).
  Decisions the same day: no 0.4.2, so FB-006 and the other small fixes go into 0.5; FB-007 is a
  line in the recipe's detail panel at usual prices, with a "+" when a material has no price
  (design in the entry). Tyler asked how aux stores prices: `docs/price-data.md` (new) explains it
  and lists its weak points; Tyler then decided to improve it in 0.5 (plan in that file).
- Versioning decision (2026-10-05): fixes to an unreleased version go into that version, so the
  build 2 and 3 fixes are part of 0.4, not 0.4.1. 0.4.1 is for fixes after 0.4 is released.
- **0.4.1 release (2026-10-05):** build 6 passed except one case, fixed before release: a Live
  round during a trade good's price quote ended the purchase with "Internal auction error"; Live
  rounds now wait while the buy bar is buying (`update_live`). That fix was not tried in game
  before the release; Tyler checks it on the release zip before uploading to CurseForge. Next:
  0.5 planning (docs/roadmap.md, 0.5 notes: Sniper rework, fast-market buy feedback).
- Before the release, **0.4.1** was on branch `claude/modest-volta-4mgmsb` (restarted from `main` after the 0.4
  merge), TOC `forever-0.4.1`, test build 3 out. Plan in `docs/roadmap.md` (0.4.1): performance first, then
  common-sense UX (list to agree with Tyler, mockups for visual changes). Done so far: login item
  walk (`fetch_item_data`) skips non-items and pauses every 500 numbers, `core/crafting.lua`
  removed, the per-frame audit (Saved Searches, Bids tab, quick menu rows fixed), tests run once
  per change on GitHub. In-game checks: `TESTING.md` (Current build) and the test page
  https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ, where Tyler marks each step; read the results
  with ArtifactData, collection `builds/0-4-1-dev<N>/results` (one document per step id; notes
  and screenshot asset ids, which `Artifact` read with `path` = the id downloads).
- Build 5 results (Tyler, 2026-10-05): Sniper gear buys work ("way better"), hold and pick pass,
  empty search, quick run search/buy, Live, Post, Auctions (cancel and undercut too) pass; memory
  11.9 MB after a cleanup at the end. Failed: a saved or recipe search while Live was on (refused
  as a multi-query, Live kept updating the old search; fixed in build 6: any new search ends
  Live). Trade good Sniper buys hit "Internal auction error" 4 of 5 times on deals found minutes
  earlier; build 6 reads a trade good deal again when selected, like gear. Tyler's Sniper design
  notes are in docs/roadmap.md (0.5).
- Build 4 results (Tyler, 2026-10-05; the game server was being restarted and players reported
  the AH broken meanwhile): memory settled (after a cleanup 17.3 MB at Sniper round 14, 17.5 MB at
  round 46, 18.5 MB after a full scan with the bag-only fix; the rise from 8.1 MB at login is
  one-time: an empty search's 2,083 rows, Sniper notes on 7,763 items, 2,177 cached usual
  prices). Sniper gear buys did nothing while trade goods bought fine and Search gear buys work:
  likely the purchase needs the auction in the latest search of its item, and rounds search other
  items. Build 5: a selected gear deal is read again (one request) before Buy, rounds hold while a
  deal is selected (click again to let go), the purchase stays on the click (PlaceBid from code
  may need a click; unverified). The selection moved because auction_listing reselected by row
  position after each refresh (Simon's code); it now keeps the same record. The Sniper table
  freezes while the mouse is over it. Empty searches do nothing. Tyler skipped the quick run;
  it is still needed before release.
- Build 2 results (Tyler, 2026-10-05): a full scan left 42.3 MB after a cleanup (Post tab kept
  every item's listings; fixed in build 3, only bag items now). Sniper "after a cleanup" grew
  12.9 MB (round 29) to 19.1 MB (round 41) with only the Sniper running and a deal selected; the
  harness does not repeat it (flat over 80 rounds with deals, selection and moving prices), so
  build 3 adds `/aux memory detail` (entry counts per store) and asks for round 10 and 40 with
  nothing selected. Sniper buy bar offered non-deal units of a trade good (fixed: deal tiers
  filtered by the rule) and the buy did not go through (unknown; rounds now pause while the buy
  bar is busy; the Confirm click may have been missed). Prices: Tyler wants copper kept in
  tables for alignment (done: full parts when any price in the table has copper). Auction Bid
  showed the buyout on buyout-only auctions (now "---"). Resize corner jumps on a single click
  (Tyler made sure: single clicks, and once it starts each click jumps again; scale 100%): not
  reproduced; my double-click guess was wrong. Build 4 drops the game's StartSizing for aux's own
  sizing during the drag (`frame.lua`, grip OnUpdate only while dragging), so a click without
  movement changes nothing; anchor_top_left no longer re-anchors when already in place. Posting bid = buyout posts buyout only, as
  designed; the test step had asked for a lower bid.
- 0.4 release (2026-10-05): Tyler approved it after build 5, with one last change: the recipe
  cost line moved from the line next to the sub tabs (crowded, cut off) to the bottom bar right of
  Clear, in shorter words (`recipe_label` in `tabs/search/frame.lua`, set in
  `update_results_summary`). That last change was not tried in game before the release; Tyler
  checks the release zip before uploading to CurseForge. Released through a pull request into
  `main` and the Release workflow (`v0.4`). Open after 0.4: `/aux memory` at round 10 and round 40
  of the Sniper (should match after a cleanup); Simon's background item cache thread
  (`fetch_item_data` in `core/cache.lua`, walks item IDs 1 to 30000 at login) is a performance
  item to review for 0.4.1.
- Before the release, **0.4** was on branch `claude/modest-volta-4mgmsb` (TOC `forever-0.4`), pushed. Tyler
  tested the first 0.4 build: recipe search works. His findings, fixed in the second build:
  saved recipe searches showed raw search text (now "Recipe  Name  (N materials)", the recipe is
  kept on the saved entry); the Sniper played its sound once per deal (about 40 times in a 1c
  first round) and showed nothing until the round ended (now one sound per 10s, deals and
  "checking N possible deals" during the round); `/aux debug` printed timing every Sniper round
  (scans with `quiet = true` print nothing); memory read 8.6 MB at first and 26.0 MB after Sniper
  rounds. Memory: rounds no longer unpack history or build tables per item (`history.value_and_days`,
  `GetItemInfo` directly). What remains per round is the game's own item list (about 7,700 entries,
  each a table with an item key table), which becomes garbage; an estimate, not measured, is a few
  MB per round. `/aux memory` now also reports the size after a full cleanup to tell the two apart.
  Build 2 result (Tyler, 2026-10-05): `/aux memory` read 58.2 MB, 10.6 MB after a cleanup, and
  later 18.9 MB, 10.7 MB after a cleanup, over 13+ Sniper rounds. So aux keeps about 10.6 MB and it
  does not grow; the rest is garbage from the rounds that the game frees. The pause between
  Sniper rounds went from 1s to 2.5s (Tyler's choice, a compromise) for less garbage and fewer
  requests. Also in build 2, every Sniper deal vanished around round 6 and came
  back later: build 2 read the vendor price only from GetItemInfo, which returns nothing while the
  game reloads an item, and a deal without facts was hidden. Fixed in build 3: deals keep the facts
  they were found with, and the vendor price falls back to aux's saved item list. Likely cause, not
  proven in game.
  Build 4 result (Tyler): login 8.1 MB (8.1 after a cleanup); after 23 Sniper rounds 49.0 MB, 16.4
  after a cleanup. Measured in the harness with 7,700 fake items: the Sniper keeps about 1.1 MB
  once (its notes on each item: `known`, `seen_items`), then nothing more through round 60 (test
  "sniper: rounds keep no memory"). Other things that grow once and stop: aux's saved item list
  (`account_data.items`, Simon's cache, filled from every item the game loads, so the Sniper fills
  it fast), the history cache, search results kept for the history arrows. Not yet proven which
  part makes up the rest of the 8 MB; to tell: `/aux memory` at round 10 and round 40, the "after a
  cleanup" number should be the same. Tyler noticed a new Sniper find right after running
  `/aux memory`: aux has no weak tables, so a cleanup cannot change what it knows; finds came every
  few minutes in that session, so it is likely chance; watch for it repeating.
  Design note from Tyler (not a demand): the line next to the sub tabs is getting crowded (the
  recipe line gets cut off: "searched ju..."), while the bar at the bottom (next to Clear) and the
  search bar have room. Consider moving the recipe line or the summary down there; mockup first.
  Also fixed in build 5: the recipe line names a material without a price instead of "?".
  Next steps:
  1. Tyler tests the fifth build (`docs/testing-history.md` section 16, Recipe search, Sniper fixes,
     Performance) and sends both `/aux memory` lines at login and after 20+ Sniper rounds. If the
     "after a cleanup" number keeps climbing, something is kept that should not be: look for it.
  2. Fix whatever his test turns up (each bug: fix plus a test that fails without it).
  3. When he says 0.4 is ready: changelog heading `## 0.4 (date)`, status, curseforge text
     (features: Auctions tab undercut check, recipe search, Post next item), then a pull request
     into `main`, wait for CI, merge, run the Release workflow, check the release zip, send it, and
     give Tyler the CurseForge upload steps and changelog text (as done for 0.3 and 0.3.1).
- 0.4 contents: Auctions tab (undercut / tied / lowest / sold, Cancel undercut one per click, check
  on tab open, reused for 2 minutes unless an auction is unchecked), Post tab selects the next item
  after posting everything of one, recipe search (`tabs/search/recipe.lua`: "Search in aux" button
  on the profession window while aux is open, Alt-click a recipe; Shift-click is Blizzard's track
  recipe, so not used), performance fixes (tooltip scan once per item, Post tab validation and buy
  bar throttled, history unpacked only for new daily lows).
- Mockups (private to Tyler): 0.3 https://claude.ai/artifact/Q5C3ScRtCLV9ohYCcuyuRA, 0.4
  https://claude.ai/artifact/A6L3eNDURLpJUMBd1aVucY (Auctions tab approved; "Recipe" board is the
  built design; "Recipes" sub tab board was rejected).
- Tyler's standing priorities: performance and compute cost first (AGENTS.md, Performance); patch
  versions (0.x.y) are fixes, speed and small things only; mockup before any visual change; he
  trusts Claude's engineering judgment but wants honesty, not agreement.
- Testers: two guild AH power users (Darkhorse, Hotpocket) asked for recipe search; their RAM
  concern is why `/aux memory` exists.
- Release mechanics that bit before: the session's git proxy refuses tag pushes, so releases go
  through the Release workflow (`run_workflow` on `main`); after a merge, restart the branch from
  `main` before new work; WoW chat lines are limited to 255 characters (keep /run test lines short).

## Working in game (tested by Tyler)

- Search, shift-click and alt-click from bags into Search and Post.
- Buy bar: trade goods by quantity with a confirmed server price, gear one at a time.
  Purchases matched the mail exactly.
- Resizable window that remembers its size and position.
- Rename to auxForever. Credit line, changed by Tyler on 2026-10-05 (was "aux by shirsig, granted
  immortality by Tyler"): "aux by shirsig, re-imagined by a fan".
- New look: top bar with tabs, rounded corners, amber accent, "N sellers" in the seller column.
- Undercut mode: match the cheapest price by default, goblin toggle to undercut.
- Post tab duration dropdown (fixed this session).

## Open

1. Done: Forever rejected all three bundled fonts (Barlow, a basic rebuild, PT Sans Narrow), so
   they were removed and the game font is used. Cancel on the buy bar was fixed (it was hidden
   and re-shown every frame, which drops clicks); needs checking in game.
2. Done: the status bar is dim gray when idle (Tyler agreed). Gear is now priced in whole silver
   and undercut by 1 silver; needs checking in game (post a green item in undercut mode).
3. Built in 0.2.1 (2026-10-04), tried in game by Tyler, who approved it for release: the result count on
   the "Search Results" sub tab, the summary line next to the sub tabs ("11 price levels, 6,180 for
   sale, searched 2m ago", Results sub tab only) and a magnifier in the search bar. The sub tab
   buttons are narrower (200) to make room. New texture `textures/search.tga`: full restart.
   Gemini's mockup for this (branch `gemini/search-details`, only on Tyler's PC) was not used.
   Also in 0.2.1: trade goods on the Post tab have one Quantity box (Max = everything in the bags)
   instead of Stack size and Stacks, since Forever posts a trade good as one listing of any size;
   10 x 2 used to leave 9 of 29 Blood Shards behind. Stack size stays 1 internally.
   After Tyler's test run (2026-10-04): the summary counted every auction as a "price level"
   ("403 price levels, 403 for sale"); it now counts items ("37 items, 403 for sale") and only says
   price levels for a one-item search. Filter Builder: All / Any switches fade with fewer than two
   conditions under them (Tyler toggled the top switch with one group and saw no change), and the
   builder no longer re-reads its own text when reopened, which flattened a lone group. Broad gear
   searches are slow because Forever answers one item per request; fast mode is planned for 0.3
   (`docs/roadmap.md`).
   Blizzard UI button "unreliable" (Tyler; moving aux did not reveal the window, so it was not
   just behind aux). Cause found in Blizzard's UIParentPanelManager: side windows are anchored
   with offsets divided by the window's scale, so any panel layout while aux keeps the Blizzard
   window shrunk to 1% (opening the character sheet, spellbook, a vendor) put it 100 times too
   far, off screen. On showing it, aux now scales such an anchor back
   (`fix_blizzard_frame_position` in `aux-addon.lua`), clamps it to the screen, raises it above
   aux, and lights the button while it is shown. Not confirmed in game yet.
   Settings (Tyler, 2026-10-04): no explanation text in the menu; "Default duration" replaces
   "Auction length" plus its note; a Scale row (70% to 150%, 5% steps, for 1440p screens) replaces
   the slash-only `/aux scale`, whose saved value was never applied after a reload before. The
   resize corner anchors the window by its top left before sizing: it started out anchored by its
   left edge, and sizing from the corner then could jump to full screen on one click (Tyler).
   Code review (2026-10-04): client-side work is small; slowness is mostly one server request per
   item. Two waits in `core/scan.lua` may add to it: 1s before using results the client already
   holds when no event comes, and 20s when no answer comes at all. `/aux debug` (search timing
   log, `timing_report` in scan.lua) measures this.
   Measured by Tyler (step 4 of the test scenario, 335 items): 3m 13s, 0.58s per item. Throttle
   2m 19s (72%), server answers 53s, item data 0.8s, item list 0.1s, other 0.0s. 336 answers on
   time, none after the 1s fallback, none timed out. So the waits in our code are not the problem
   and the addon's own work is negligible: the time goes to Blizzard's request rate limit
   (`IsThrottledMessageSystemReady`), which allows about one item search every 0.4s. Nothing in
   full mode can beat that; fast mode (0.3) can, since the item list itself (0.1s here) already
   holds each item's lowest price and quantity. The waits stay as they are, and the table refresh
   change is dropped (no measurable cost).
4. Not yet tested in game: Auctions tab cancel, Bids tab, full scan, posting gear with a bid,
   Filter Builder dropdowns after the dropdown fix. See `TESTING.md`.
5. Later: Tyler sends Simon (shirsig) the project to review before it goes public. The GitHub
   repository can optionally be renamed to auxForever.

## Repository

Public since 2026-10-04. PR #1 (everything up to 0.2) was merged into `main` on 2026-10-04, so
`main` is auxForever 0.2. New work starts from `main` on its own branch.

Since 2026-10-04 Gemini may work on the repository too. `AGENTS.md` is the shared guide for every
agent (`CLAUDE.md` and `GEMINI.md` load it); `docs/gemini-setup.md` is Tyler's setup guide. GitHub
Actions (`.github/workflows/test.yml`) runs the tests on every push and offers the addon as a
download. Every agent: pull first, one agent per branch, update this file when done.

## 0.3 (planning, see docs/roadmap.md)

- Decisions recorded in the roadmap: automatic fast mode, Sniper as its own top tab, default deal
  rule.
- `/aux debug list` (`measure_item_list` in core/scan.lua) times the whole auction house's item
  list. First try failed at once (a `pcall` around the waiting request, fixed in a7c9835); the
  rerun gave 7718 items in 8.5s, 16 requests.
- Mockups for fast mode and the Sniper: https://claude.ai/artifact/Q5C3ScRtCLV9ohYCcuyuRA
  (private to Tyler). Approved ("let's see the prototype").
- 0.3 first build (TOC `forever-0.3.0-dev`, later `forever-0.3`, branch `claude/modest-volta-4mgmsb`, sent as a zip):
  fast mode on Search (Fast / Full switch, click a row to read its auctions), Live mode with a
  visible countdown and paused state, and the Sniper tab. Decisions and known limits:
  `docs/roadmap.md`, "Built". In-game checks: `docs/testing-history.md` section 15. Not tested in game yet.
  Unknowns to watch: whether the item list's lowest price is ever a bid (`/aux debug` prints a
  line when an opened item differs), whether item list names include suffixes, the Sniper's
  round time over a long session, and whether the server minds rounds back to back.
- Tyler's first 0.3 test (2026-10-05), neither reproduced since:
  1. Live stuck on "Updating" with an empty table and the status bar full. Cause not confirmed;
     the likely one is an error inside the scan's thread, which used to leave the scan marked as
     running forever. `aux.coro_thread` now takes an error handler: the scan ends as if stopped
     (Live shows Paused, chat asks for the BugSack text) and the error still reaches BugSack.
     Live also restarts by itself if it says Updating with no round running.
  2. Blizzard's own tabs (Buy, Sell, Auctions) stretched off the screen. Likely cause: Blizzard
     sizes its tabs to their text when shown, and that ran while aux kept the window at 1% scale.
     The tabs are now measured again with Blizzard's code whenever the window is shown at full size.
  3. Items in the reagent bag (Forever's bag 5) were missing from the Post tab: aux read bags 0 to 4
     only. `info.inventory` now goes up to `NUM_TOTAL_EQUIPPED_BAG_SLOTS` (5).
- Sniper test by Tyler (2026-10-05): round 39, 7256 items in 8.4s each round, matching the
  `/aux debug list` measurement. Two below-vendor deals were found and went gone (sold or relisted;
  not checked). Changes after it: deals that fail the current rule are hidden even when gone (a 1c
  find from a loose setting stayed after going back to 5s), the count reads "N to buy, N gone"
  instead of "0 found" over gone rows, and Usual is blank unless the item has 3 days of history
  (it showed the vendor price before, which looked like the usual price). Buying from the Sniper
  is not confirmed in game yet.

## 0.4 (in progress)

- Built: Auctions tab (undercut check, Cancel undercut), Post tab next item, recipe search (button
  on the profession window and Alt-click), performance fixes (tooltip scan once per item, Post tab
  and buy bar throttled, history unpacked only for new daily lows). TOC `forever-0.4`.
- Facts from Tyler's in-game check (2026-10-05): the recipe for Simple Kilt is 12046 and its link
  shows the materials. The second check failed only because the /run line was over WoW's
  255-character chat limit; Blizzard's own profession window uses `GetRecipeSchematic` to show
  materials, so the call works on Forever.
- `core/crafting.lua` hooked Classic's profession frames, which Forever does not have. Removed in
  0.4.1 with its `/aux crafting cost` setting.
- Not tested in game yet: everything in `docs/testing-history.md` section 16.

## 0.3.1 (released 2026-10-05)

- Performance pass after Tyler stressed compute cost (2026-10-05). Found and fixed: `control.lua`
  compared every event listener with every other one on every frame, all game long (from Classic
  aux); the Auctions and Bids tabs ran endless per-frame threads to rebuild their lists every
  second; the Full scan button restyled itself every frame; the Live button and Sniper status
  rebuilt their text every frame. Rules for all agents: AGENTS.md, Performance. Tests: `per-frame
  work`. The buy bar was throttled to ten times a second in 0.4 (and does nothing with no row
  selected).
- `/aux memory` (memory use and number of items in price history), for questions about RAM.
- 0.4 Auctions tab mockup approved by Tyler (https://claude.ai/artifact/A6L3eNDURLpJUMBd1aVucY).
  Recipe search added to 0.4 (`docs/roadmap.md`). Not built yet.

## Releases

- 0.2.1 released 2026-10-04: GitHub Release `v0.2.1` (pre-release, with the zip, published by
  the Release workflow from `main` at 064ace9), CurseForge upload by Tyler. Includes everything
  from 0.2, which was not released on its own. Its release text says "listed under 0.2 below",
  which only makes sense in the changelog file; the changelog wording is fixed for later
  releases.
- 0.3 approved for release by Tyler on 2026-10-05 after testing fast mode, Live and the Sniper
  (round times 8.4s). Released through a pull request into `main` and the Release workflow
  (GitHub Release `v0.3`, pre-release). CurseForge upload by Tyler. Not confirmed in game at
  release: buying from the Sniper, posting from the reagent bag, whether fast mode rows show
  suffixes ("of the Owl"); these stay in `docs/testing-history.md` section 15.
- 0.3.1 approved by Tyler on 2026-10-05 ("stable and ready to release"): performance fixes and
  `/aux memory`. GitHub Release `v0.3.1` by the Release workflow; CurseForge upload by Tyler.
- From 0.2.1 on, the Release workflow publishes the GitHub Release: Actions, Release, "Run
  workflow" on `main` (or a pushed `v<version>` tag). See AGENTS.md, Releases.

## 0.2 (built 2026-10-04, released as part of 0.2.1)

1. Settings popup: default auction length (2h/8h/24h, labels from the game). It is the existing
   `post_duration` setting: new items start at it, items posted before keep their last length.
2. Filter Builder facelift. Mockup: https://claude.ai/artifact/2UoFbSgPsFSgRUdPdNKZQV
   - Left "Which items" (the Blizzard part), right "Only show auctions where": a list of conditions
     in plain words, Match All / Any, a "not" switch per row, and groups that nest (Tyler wants
     Simon's full and/or/not nesting kept; groups map one to one onto it).
   - Live sync with the search bar replaces Import/Export; "Save to favorites" added.
   - "In words" line reads the search back in plain English.
   - Built as `tabs/search/filter.lua` (tree, search text, words) and `tabs/search/builder.lua`
     (rows, menus). Groups are always written with a count (`and2`), since a bare `and` takes
     everything after it. Unfinished conditions are left out of the search bar.
   - The bid variants are separate menu entries rather than the Buyout / Bid switch the mockup
     mentioned. Category names still need checking against Forever's AuctionCategories in game.
     (The `<>` in the search bar is aux's label for an empty search; not a bug by itself.)
3. Done in 0.2: Favorite with an empty search bar used to save an empty search (`<>`), once per
   click. Now it saves nothing on an empty search bar and never adds a search that is already a
   favorite (`add_favorite` and `save_favorite` in `tabs/search/saved.lua`, with tests).

## Fixed in 0.1.1

- Posting gear failed with "Internal auction error" when the starting bid equalled the buyout
  (the default). The game needs the buyout above the bid; an equal or higher bid is now left out and
  the item is posted for buyout only. Found by Tyler's brother with a Blazing Wand.

## Recent decisions

- Undercut mode starts off every time the auction house opens (Tyler: never remembered).
- Quick searches, the gold finished-search bar and the fading history arrows tested fine in game.

## Post tab: auto price (built)

When an item is loaded, once its listings are in, the price starts at the lowest listing (matched,
or one step below in undercut mode), else the usual price. A clicked row or typed price still wins.
Tyler: "99% of posts are matching the lowest price"; aux used to show the last price used.

## Post tab facelift (built, tested in game)

https://claude.ai/artifact/9gx3SMqfU46WMGbZ11iwKv : Match lowest / Undercut switch with the goblin,
a "?" for the undercut hint, bigger price box with a "% of usual" badge, a summary row (items,
total, deposit, "you get" after the 5% cut, Post button), steppers with Max, duration as 2h/8h/24h
buttons, "Hide from this list" next to the item name.

Auction house cut: 5% (Tyler's research; retail value). Keep it one constant. Deposits come from the
game's own CalculateItemDeposit / CalculateCommodityDeposit, not a formula, so a server-side
deposit change shows up by itself. Tyler's notes also claimed a flat 1 silver deposit minimum, but
his own Post tab showed a 1c deposit for Minor Mana Potion, so that claim is not trusted.

## Background opacity (built)

Gear in the top bar, 50% to 100% (Tyler lowered the floor from 70%), only backgrounds fade (gui.register_background). Light mode was
considered and turned down: game item colors are made for dark backgrounds and it doubles UI work.

## Quick searches (built, tested in game)

Clock button next to "<" on the Search tab (tabs/search/quick.lua): pinned searches (aux's
favorites) and recent searches, with icon, cheapest price seen and time. Mockup:
https://claude.ai/artifact/6eBC1KgzAvRCNfgmQDGxmB

## Ideas Tyler mentioned for later

- Expand undercut mode beyond one step (start simple, iterate).
- Remove the "/aux undercut" explanation once Forever players know the mechanic.

## CurseForge page (in progress, version 0.1, unlisted)

Draft description and project settings: `docs/curseforge.md`, modeled on shirsig's aux page.
Logo: Tyler's Recraft design ("aux" with a looped x), cleaned up (transparent corners, stray specks
removed) and recolored to the addon gold #E3A43B: `docs/images/logo.svg` and `logo.png`. Header
image `docs/images/banner.png` (that aux plus FOREVER in Cinzel). Recraft's free plan keeps
ownership of what it makes and allows no commercial use, so the logo must come from a paid plan.
License field on CurseForge: All Rights Reserved, like Simon's page, since MIT there would wrongly
suggest his code is MIT. The repository stays MIT (Tyler, 2026-10-04); it covers only the changes
made here.
