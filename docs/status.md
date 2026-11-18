# Status

Last updated 2026-11-18, Tyler's time (0.8.2.1 released; main merged into the Upgrades branch).

Keep this file short: where things stand, the next step, open questions. When a version is
released, move its notes to `docs/status-history.md` (everything before 2026-11-10 is there).

## Start here (next session)

**Being built: the Upgrades tab** (branch `search-upgrade-support`, not released). `main` up to
0.8.2.1 merged into it on 2026-11-18 (see the last note). Notes, newest last:

**2026-11-16, Claude, Upgrades tab plan** (branch `search-upgrade-support`, from `main` after
0.8.2): a new tab after Sniper that finds gear upgrades by spec stat weights. Plan, open decisions
and mockup link in `docs/upgrades.md`; nothing built. Experiments done (E12: `GetItemStats` on a link
works, also a results row's icon link; `C_TooltipInfo.GetItemKey` is blocked for addons. E9: no
talent trees, the player picks the spec). Mockup approved (Ben). Built: `core/stats.lua` (stats,
scores, worn item), with tests, not used by a screen yet; new file, so a full game restart. Stat
priorities of all 27 specs from Icy Veins' Forever pages (`docs/stat-priorities.md`), turned into
ranked weights (option A, Ben) in `core/weights.lua`, tested. E10 seen (stat names; Spell Power
under one name on a real item). The tab is built (`tabs/upgrades/`, tab 3; Post, Auctions and Bids
are now 4, 5 and 6), with tests, not tried in game: `TESTING.md`, "Upgrades tab, first build". A
row opens the item on the Search tab to buy it. Also built 2026-11-16: the weights editor (`tabs/upgrades/weights.lua`, own window, from Settings
and the tab) and a Per gold column. Next: Ben's in-game test (`TESTING.md`, steps 1 to 14).

**2026-11-17, Claude, buying on the Upgrades tab** (Ben: buy from the tab, mouse and gamepad, Y
buys a highlighted item). Built on `search-upgrade-support`: the buy bar sits under the Upgrades
table; a click reads that row's auctions and offers the cheapest at its real price; right-click
opens it on the Search tab; gamepad Y on a row reads its price, the next Y buys (the game buys only
inside a press). Tests in `tests/timing_test.lua` (slow auction house), checked to fail without
the change. No new file. Not tried in game: `TESTING.md`, steps 16 to 21. Next: Ben's in-game
test of steps 1 to 21.

**2026-11-17, Claude, endings on the Upgrades tab.** Ben's screenshot: every "of the ..." version
scored the same, because the link aux's tooltip gives for an item key has no ending. Now one
auction of each ending name is read after the item list and its link's stats are used (cached for
the session). Test in `tests/timing_test.lua`, checked to fail without the fix. No new file. Not
tried in game: `TESTING.md`, steps 22 and 23 (step 22 also confirms that a real auction's link
gives the ending's stats). Next: Ben's in-game test of steps 1 to 23.
Later the same day: the ending stats are saved for the account (`account_data.ending_stats`), read
again after a game patch (build number) or 30 days, with a Clear button in Settings, Upgrades,
"Saved item stats". Tested with breaks for each rule. Steps 24 to 26. Next: steps 1 to 26.
Later still (Ben): a lower edge for the ending reads. The search still covers level 1 up, but
endings are read only for items whose required level is at least 75% of the player's
(`ENDING_SHARE_BELOW = .25`, `ending_floor` in `tabs/upgrades/core.lua`; at 60 that is 45 up).
Lower items are scored on their plain stats (or a saved ending) and counted in the status line.
Test in `tests/timing_test.lua`, checked to fail without it. Step 27. Next: steps 1 to 27.
Later still (Ben: "save all levels and classes"): a Full scan saves every ending's stats from its
listings' links (no extra request; after the scan, 50 a frame; `on_full_scan_record` and
`on_full_scan_end` in `core/scan.lua`, used in `tabs/upgrades/core.lua`). Test in
`tests/load_test.lua`, checked to fail without it. Two Unknowns (E11 in
`docs/forever-auction-house.md`), checked by steps 28 and 29. Next: steps 1 to 29.
Result (Ben, E11): the scan saved 11,354 names, Chest, Back and Wrist read only 21 themselves,
item levels match; the 21 got no stats from the game at that moment. Now retried every second,
5 times (`FULL_SCAN_RETRIES`), test in `tests/load_test.lua`. Step 30. Next: steps 1 to 30.
Also (Ben): a Full scan tip on the Upgrades status line when none ran in the last 24 hours,
tested. Step 31. Next: steps 1 to 31.
Note: under LuaJIT (this Mac has no lua5.1) "sniper memory: no growth" failed once and passed on
three reruns; GitHub Actions runs real Lua 5.1.
2026-11-18 (Ben): `main` (0.8.2.1) merged in. Conflicts settled: the Full scan keeps 0.8.2.1's
fast read (no auction record per listing, R-08) and hands the Upgrades tab only the listings of
gear with a random ending (`hand_on_listing` in `core/scan.lua`; the reader now also returns the
link). The Upgrades item-stats experiment is now E12 (0.8.2.1 has its own E8, copper on gear).
0.8.2.1's new tests used Post 3, Auctions 4: renumbered, and the random player (`fuzz_test.lua`)
now visits all six tabs. A test of this branch left `GetInventoryItemLink` unset after it (a local
named `saved` hid the saved functions); fixed. Lint: `GetInventoryItemLink` added to
`known_globals.lua`; the global `GetItemStats`/`GetItemInfoInstant` fallbacks removed (Forever has
only the `C_Item` ones). Both looks 0 errors under LuaJIT. Next: steps 1 to 31 in game, plus a
Full scan to check the endings are still saved after the merge (step 28).

**Released:** 0.8.2.1 on 2026-11-16 (pull request to `main`, Release workflow: tag `v0.8.2.1`,
GitHub release, CurseForge Beta file). What it holds: `docs/changelog.md`, "0.8.2.1". How it was
built and tested, build by build: `docs/status-history.md` (top) and `TESTING.md`.

**Tyler, after the release:** paste `docs/curseforge-description.md` into the CurseForge page (it
now says a trade good is bought with one click).

**Nothing else is being built.** The next version is not chosen; candidates below and in
`docs/roadmap.md` (0.9: shopping lists and writs, an automatic Full scan option, posting rules).

**Saved for later (Tyler, 2026-11-16: "Just save the test for a later date :) and we will monitor
feedback"):** the in-game check of buying through a row of many sellers (S-08; build 7 step 3,
17 purchases of Linen Belt was too costly). A cheaper way when it is run: a hidden test command
that sets `FOLD_KEEP` to 3 and `REFILL_AT` to 2, so 3 purchases at 1s reach the re-read. If it
fails the worst case is the display (a row gone early, a count off by one until the next search),
not money: each purchase pays the real auction's own price.

**Watch in player feedback:** one-click buying (FB-048) and copper on gear (FB-044), both seen
working by Tyler; the locked-item message with bag addons (FB-046, not seen in game); "of Shadow
Protection" tooltips (FB-045, not tried).

**Open items (not built):**
- "N sellers" is an upper bound: when one auction house row holds several sellers the game gives a
  count, not names, so a seller in two rows counts twice (548 in Full, 438 in Live for the same
  550 Linen Belts in build 7's test). Since 0.8. A fix needs every seller's name, which the game
  may not give (not checked).
- S-09: the Post tab's receipt shows a starting bid for a trade good when no price is typed.
- FB-042, FB-043: crate cost with Merchant's Favor and reward silver, and a list of every crate and
  writ; 0.9 with writs. Crates pay Favor and silver, writs reputation (Outside, guides).
- Not built from the outside review: R-27 (needs a sale in game), R-28 (structure), R-23, R-25, and
  one part each of R-16 and R-20 (review file).

**Open questions for Tyler:**
1. FB-046: does he use Bagnon? FB-042: a screenshot of a Waylaid Crate's turn-in reward.
2. R-27: one sale and a screenshot of its "Auction successful" mail (experiment E1) settles the 5%
   cut aux shows as fact; one auction left to expire (E4) settles "kept if the auction expires".
3. Replies to the players of the 2026-11-08 and 2026-11-16 feedback batches are not written; does
   he want them?

**Roles (Tyler, 2026-10-26):** Claude Code is the primary engineer; Gemini (Gemini 4 Argon) gives
second opinions in `docs/reviews/` (`AGENTS.md`, "Roles"). Agents talk through `docs/handoff.md`;
Tyler only says "Check the handoff". Nothing is open there.

**How Tyler tests:** one test page, https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ. For a new
build, republish its `index.html` with a new `BUILD` id and the steps in `AREAS` (the same steps as
`TESTING.md`, "Current build"). Tyler marks Pass, Fail or Skip with notes and screenshots; read
them with ArtifactData, collection `builds/<build id>/results`, and download each screenshot with
Artifact read, `path` = the asset id, one at a time. He often uploads screenshots without marking a
status: read the screenshots. He screenshots with Win+Shift+S, which holds Shift (tooltip prices
then show the whole stack, "for 3"). Zips are `auxForever-<version>-build<n>.zip`, sent with the
file tool; always say whether `/reload` is enough.

**Where the rest is:** plans in `docs/roadmap.md` (0.9: shopping lists, an automatic Full scan
option, posting rules), player feedback in `docs/feedback.md`, facts about Forever's auction house
in `docs/forever-auction-house.md`, older status notes in `docs/status-history.md`.
