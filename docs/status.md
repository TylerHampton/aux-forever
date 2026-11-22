# Status

Last updated 2026-11-21, Tyler's time (`0.9` build 1 built on branch `gemini/0.9`, ready for
in-game testing; 0.8.2.2 released on `main`).

Keep this file short: where things stand, the next step, open questions. When a version is
released, move its notes to `docs/status-history.md` (everything before 2026-11-20 is there).

## Start here (next session)

**Active branch:** `gemini/0.9` (version `forever-0.9`, build 1 ready to test in game; zip
`auxForever-0.9-build1.zip`, `/reload` is enough).

**What is in 0.9 build 1 (2026-11-21, foundation and high-impact fixes before new UI features):**
- `FB-056` (user_kc0ds7pqedmptpep): dungeon/tooltip Lua error hardening in `core/tooltip.lua` and
  `util/info.lua`, plus 7 missing Forever tooltip stack-count getters (mail, guild bank, trade,
  quest) and `daily` nil/color fixes.
- `wait_throttle` timeout (`THROTTLE_TIMEOUT = 10s`) in `core/scan.lua` and `tabs/search/results.lua`
  `sync_bucket` (also stops cleanly on `AUCTION_HOUSE_CLOSED`).
- High-impact code audit fixes: Sniper per-round version read cache (fixes K^2 duplicate AH
  requests on multi-version gear) and preserved green "Bought ..." message on auto-deselect;
  Search `UpdateRowInfo` grouping fix (stops bid-only + buyout mixing from splitting one gear
  ending into 2 rows); synchronous API event fixes in `aux.place_bid`, `post_auction`, and
  `cancel_auction`; multi-item Post `AUCTION_MULTISELL_UPDATE` race fix and cache-miss guard;
  stopped gear buyouts from polluting `bid_auction_ids`; timeout guards on `refresh_commodity`,
  fast `open_item`, and Sniper `refresh_deal`; scan priority coordinator (`PRIORITY_BACKGROUND`,
  `PRIORITY_WATCH`, `PRIORITY_USER`); Buy bar chip/anchor/empty-Enter/instant-refresh fixes;
  Waylaid Crate Equip/proc gear caching fix.
- `docs/roadmap.md` updated with the agreed 0.9 / 0.10 / 1.0 split (exit beta after 0.10).
- `docs/forever-auction-house.md` updated with `[Code]` notes and experiments `E9`
  (`SendSellSearchQuery`) and `E10` (`SearchForItemKeys`).

**Waiting on Tyler (in `TESTING.md`):**
1. Test 0.9 build 1 in game (steps 1-3) and run the two 0-gold `/run` probes (steps 4-5: E9
   `SendSellSearchQuery` and E10 `SearchForItemKeys`).
2. Next build (0.9 build 2): Phase 1 QoL switches (`FB-058` full-stack tooltip default, `FB-061`
   hide Professions line, `FB-062` right-click bag to Post, `FB-032` Auto Full Scan, `FB-063`
   `Bindings.xml` keybinds [full game restart], remove `seen ` + UI wordiness audit), plus wire
   in `SendSellSearchQuery` / `SearchForItemKeys` once E9/E10 are confirmed.

**Released:** 0.8.2.2 on 2026-11-20 (PR #43 squash-merged to `main`, Release workflow run
44779865723: tag `v0.8.2.2`, GitHub pre-release, CurseForge Beta file `9718999`). What it holds:
`docs/changelog.md`, "0.8.2.2". Build-by-build history: `docs/status-history.md` (top) and
`TESTING.md`.

**Tyler, after the 0.8.2.2 release:** paste `docs/curseforge-description.md` into the CurseForge
page if not done yet.

**Remaining 0.9 scope (after build 2; mockups first, details in `docs/plan-0.9.md`):**
- Phase 2: `FB-057` Settings panel in Options > AddOns + `/aux settings`.
- Phase 3: `FB-055` Narrower Sniper (using `SearchForItemKeys` if E10 confirms).
- Phase 4: `FB-059` / `FB-042` Waylaid Crate Merchant's Favor + `FB-020` Craftsman's Writs (needs
  crate turn-in and writ tooltip screenshots from Tyler).
- Phase 5: `FB-023` Crafting shopping list + alt inventory tracking.
- Phase 6: `FB-031` Posting rules based on usual price.

**Takeover complete (2026-11-20):** Gemini Neon is the primary engineer and Claude Code the
reviewer (`AGENTS.md`, "Roles"). H-012 in `docs/handoff.md` is closed. Claude-only tools are
retired: mockups are in `docs/mockups/`, the old test page's saved answers in
`docs/test-results/test-page-results.md`.

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
- FB-042, FB-043, FB-059: crate cost with Merchant's Favor and reward silver, and a list of every
  crate and writ; 0.9 with writs. Crates pay Favor and silver, writs reputation (Outside, guides).
- Not built from the outside review: R-27 (needs a sale in game), R-28 (structure), R-23, R-25, and
  one part each of R-16 and R-20 (review file).

**Open questions for Tyler:**
1. FB-054 (jebbush, "cannot sort by bag slots"): does he know which screen they meant? Likely the
   Post tab's bag list, sorted by name. FB-053: whether Forever's gamepad mode lets an addon use
   the triggers (an experiment before building). FB-052: a reply for joker2206 is in its entry.
2. FB-046: does he use Bagnon? FB-042 / FB-059: a screenshot of a Waylaid Crate's turn-in reward.
3. R-27: one sale and a screenshot of its "Auction successful" mail (experiment E1) settles the 5%
   cut aux shows as fact; one auction left to expire (E4) settles "kept if the auction expires".
4. Replies to the players of the 2026-11-08 and 2026-11-16 feedback batches are not written; does
   he want them?

**Roles (Tyler, 2026-11-19):** Gemini Neon is the primary engineer; Claude Code gives second
opinions in `docs/reviews/` (`AGENTS.md`, "Roles"; until 2026-11-19 it was the other way, with
Gemini 4 Argon reviewing). Agents talk through `docs/handoff.md`; Tyler only says "Check the
handoff". Nothing currently open in `docs/handoff.md`.

**How Tyler tests:** from `TESTING.md` ("Current build"): he runs the steps and answers in the chat
with Pass or Fail, notes and screenshots; the engineer writes them under the build as "Results".
He often sends screenshots without saying Pass or Fail (judge from the picture). He screenshots
with Win+Shift+S, which holds Shift (tooltip prices then show the whole stack, "for 3"). Zips are
`auxForever-<version>-build<n>.zip`; always say whether `/reload` is enough. (Until 2026-11-19 Claude
used a claude.ai test page; its answers are in `docs/test-results/test-page-results.md`.)

**Where the rest is:** everything Claude knew at the takeover in `docs/takeover-2026-11.md`, plans in `docs/roadmap.md` (0.9: shopping lists, an automatic Full scan
option, posting rules), player feedback in `docs/feedback.md`, facts about Forever's auction house
in `docs/forever-auction-house.md`, older status notes in `docs/status-history.md`.
