# Status

Last updated 2026-11-23, Tyler's time (`0.9.0.1` hotfix for `FB-067` released on `main`,
2026-11-23; `gemini/0.9.1` active with `0.9.0.1` merged in; 0.9.1 build 1 merged into the Upgrades branch `search-upgrade-support`).

Keep this file short: where things stand, the next step, open questions. When a version is
released, move its notes to `docs/status-history.md` (everything before 2026-11-20 and 0.9's
build-by-build log are there).

## Start here (next session)

**Released:** **0.9.0.1** on 2026-11-23 on `main` (PR #45 squash-merged at `94100dd`, Release
workflow run `45156197742`: tag `v0.9.0.1`, GitHub pre-release, CurseForge Beta file `9771064`).
Hotfix for `FB-067` multi-item gear posting on the Post tab; tested in game by Tyler on 2026-11-23
(`TESTING.md`). Release notes: `docs/changelog.md` ("0.9.0.1"). Updating from 0.9 only needs
**`/reload`** (no new files; updating from 0.8.2.2 or earlier needs a full game restart for 0.9's
`Bindings.xml`).

**Earlier release:** **0.9** on 2026-11-22 on `main` (PR #44 squash-merged at `4c4d3a9`, tag
`v0.9`, GitHub pre-release, CurseForge Beta file `9747981`).

**Active branch:** `gemini/0.9.1` (`main` merged in with `0.9.0.1`; `auxForever.toc` at
`forever-0.9.1`).

**Built, awaiting Tyler's in-game test (0.9.1 build 1, 2026-11-22, updated with 0.9.0.1 fix):**
- **Crafting Shopping List + opt-in Alt Inventory (`FB-023`, Kortan):** Approved Option A mockup
  (`docs/mockups/shopping-list-alt-inventory-2026-11-22.html`) built and verified with tests in
  both looks, 0 unknown globals, and 400 fuzz sessions. Requires a **full game restart**
  (`core/inventory.lua`, `tabs/search/shopping.lua` are new files). In-game steps are under
  "Current build: 0.9.1 build 1" in `TESTING.md`.

**Tyler, after the 0.9 release:** paste `docs/curseforge-description.md` into the CurseForge
project page when convenient (updated for 0.9's Options > AddOns panel, Narrower Sniper, keybinds,
and settings).

**Next up for 0.9.1 build 2 (waiting on Tyler's picks):**
1. **Waylaid Crate Merchant's Favor & reward silver (`FB-059`, `FB-042`, `FB-043`) + Craftsman's
   Writs (`FB-020`):** web research (`[Outside]`, Forever guides) completed on 2026-11-22; awaiting
   Tyler's in-game confirmation (especially Artisan crate Favor/silver) before mocking up.
2. **Watch `FB-065`** (marcus4555 Sniper 0 deals report) if the player replies with diagnostic info.

**Planned for 0.9.2 (Tyler, 2026-11-23):**
- **Posting rules based on usual price (`FB-031`, user_yt0k9lezehn1ukm993387):** held back from
  0.9.1 so we can design a sleeker UX for floor/normal/ceiling posting rules before building
  (mockup first).

**Planned for 0.10 (final beta):** granular scan-age timestamps & cleaner tooltip presentation
(Tyler, 2026-11-21), Full scan speed/memory pass, Sniper speed pass (Point Blank Sniper research),
and 1.0 readiness (`docs/roadmap.md`).

**Takeover complete (2026-11-20):** Gemini Neon is the primary engineer and Claude Code the
reviewer (`AGENTS.md`, "Roles"). H-012 in `docs/handoff.md` is closed. Claude-only tools are
retired: mockups are in `docs/mockups/`, the old test page's saved answers in
`docs/test-results/test-page-results.md`.

**Being built: the Upgrades tab** (branch `search-upgrade-support`, not released). `main` up to
0.8.2.1 merged into it on 2026-11-18, 0.8.2.2 build 4 (branch `claude/confident-bohr-vctz8g`) on
2026-11-20, and 0.9.1 build 1 (branch `gemini/0.9.1`, with 0.9 and 0.9.0.1) on 2026-11-23 (see the
last note). Notes, newest last:

**2026-11-16, Claude, Upgrades tab plan** (branch `search-upgrade-support`, from `main` after
0.8.2): a new tab after Sniper that finds gear upgrades by spec stat weights. Plan, open decisions
and mockup link in `docs/upgrades.md`; nothing built. Experiments done (E12: `GetItemStats` on a link
works, also a results row's icon link; `C_TooltipInfo.GetItemKey` is blocked for addons. E13: no
talent trees, the player picks the spec). Mockup approved (Ben). Built: `core/stats.lua` (stats,
scores, worn item), with tests, not used by a screen yet; new file, so a full game restart. Stat
priorities of all 27 specs from Icy Veins' Forever pages (`docs/stat-priorities.md`), turned into
ranked weights (option A, Ben) in `core/weights.lua`, tested. E14 seen (stat names; Spell Power
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
`tests/load_test.lua`, checked to fail without it. Two Unknowns (E15 in
`docs/forever-auction-house.md`), checked by steps 28 and 29. Next: steps 1 to 29.
Result (Ben, E15): the scan saved 11,354 names, Chest, Back and Wrist read only 21 themselves,
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

**2026-11-20, Claude, 0.8.2.2 merged in.** Tyler's branch `claude/confident-bohr-vctz8g` (0.8.2.2
build 4: Confirm before buying, the rest after buying, the faster Sniper and Live, gamepad item
compare from PR #41, the Full scan polish from PR #37, and the Gemini Neon takeover docs) merged
into this branch. Conflicts: Settings now has POSTING, BUYING, then UPGRADES in the left column, and
the window is 386 high (was 358) so "Saved item stats" fits while a reload is waiting; the gamepad
Y line names both Confirm and the Upgrades tab; changelog, `TESTING.md` and this file keep both
sides. Tyler's new code uses only tab numbers 1 and 2, which did not move. Tests: both looks 0
errors, 1566 checks (1497 here, 1440 on his branch before). Lint not run locally (no `luac5.1`);
CI runs it. Step 14 now checks the new Settings column. Next: steps 1 to 31 in game.

**2026-11-23, Claude, 0.9.1 merged in.** Tyler's active branch `gemini/0.9.1` (0.9 and 0.9.0.1 as
released, plus 0.9.1 build 1: Shopping List and opt-in Alt Inventory) merged into this branch.
Conflicts settled:
- Settings: 0.9 builds the gear popup and the new Escape > Options > AddOns > auxForever panel from
  one builder, and its left column is full (Posting, Buying, General). UPGRADES moved to the right
  column under the tooltip lines, one row now: "Stat weights" with Clear and Edit, the hint counts
  the saved endings ("120 endings saved"). Both views have it; Edit is faded while aux's window is
  closed (the weights editor lives inside it). The gear popup is 502 high (446 or 474 in 0.9, still
  inside the smallest window); the Options panel's bottom row moved down 24.
- Experiments: 0.9 used E9 to E11 for its own. The Upgrades tab's E9 (talents), E10 (stat names)
  and E11 (Full scan endings) are now E13, E14 and E15 in every file; E12 stays.
- Tab numbers: 0.9's code finds Post by name, so nothing moved there; two new upstream tests used
  Post 3 and were set to 4.
- A test of this branch restored its globals with `pairs`, which skips one that was nil, so its
  "blocked" `C_TooltipInfo` stayed and broke 0.9.1's crate code in a later test. Fixed (restored by
  name).
Tests under LuaJIT: both looks 0 errors, 1773 checks. Lint and the `luac5.1` syntax check are not
installed here (LuaJIT's syntax check passed); CI runs them. Next: steps 1 to 31 in game, step 14
now in the right column of Settings.
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
- FB-042, FB-043, FB-059: crate cost with Merchant's Favor and reward silver, and a list of every
  crate and writ; 0.9.1 with writs. Crates pay Favor and silver, writs reputation (Outside, guides).
- Not built from the outside review: R-27 (needs a sale in game), R-28 (structure), R-23, R-25, and
  one part each of R-16 and R-20 (review file).

**Open questions for Tyler:**
1. FB-054 (jebbush, "cannot sort by bag slots"): does he know which screen they meant? Likely the
   Post tab's bag list, sorted by name. FB-053: whether Forever's gamepad mode lets an addon use
   the triggers (an experiment before building). FB-052: a reply for joker2206 is in its entry.
2. FB-046: does he use Bagnon? FB-042 / FB-059: a screenshot of a Waylaid Crate's turn-in reward and
   a Craftsman's Writ tooltip.
3. R-27: one sale and a screenshot of its "Auction successful" mail (experiment E1) settles the 5%
   cut aux shows as fact; one auction left to expire (E4) settles "kept if the auction expires".
4. Replies to the players of the 2026-11-08 and 2026-11-16 feedback batches are not written; does
   he want them?

**Roles (Tyler, 2026-11-19):** Gemini Neon is the primary engineer; Claude Code gives second
opinions in `docs/reviews/` (`AGENTS.md`, "Roles"; until 2026-11-19 it was the other way, with
Gemini 4 Argon reviewing). Agents talk through `docs/handoff.md`; Tyler only says "Check the
handoff". Nothing currently open in `docs/handoff.md`.

**How Tyler tests:** from `TESTING.md` ("Current build") plus an interactive side-pane HTML test
checklist artifact: he runs the steps and answers in the chat with Pass or Fail, notes and
screenshots; the engineer writes them under the build as "Results". He often sends screenshots
without saying Pass or Fail (judge from the picture). He screenshots with Win+Shift+S, which holds
Shift (since 0.9, tooltips show the full stack by default and Shift shows 1 item). Zips are
`auxForever-<version>-build<n>.zip`; always say whether `/reload` is enough. (Until 2026-11-19 Claude
used a claude.ai test page; its answers are in `docs/test-results/test-page-results.md`.)

**Where the rest is:** everything Claude knew at the takeover in `docs/takeover-2026-11.md`, plans in
`docs/roadmap.md` (0.9.1: shopping list + opt-in alt inventory, Waylaid Crate Favor/Writs; 0.9.2:
sleeker posting rules; 0.10: granular scan ages, Sniper speed pass & performance), Point Blank
Sniper research in `docs/sniper-research-pointblanksniper.md`, player feedback in `docs/feedback.md`,
facts about Forever's auction house in `docs/forever-auction-house.md`, older status notes in
`docs/status-history.md`.
