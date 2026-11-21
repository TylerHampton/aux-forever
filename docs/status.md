# Status

Last updated 2026-11-20, Tyler's time (0.8.2.2 released; CurseForge feedback FB-056 to FB-063 logged, waiting on Tyler's direction).

Keep this file short: where things stand, the next step, open questions. When a version is
released, move its notes to `docs/status-history.md` (everything before 2026-11-20 is there).

## Start here (next session)

**Released:** 0.8.2.2 on 2026-11-20 (PR #43 squash-merged to `main`, Release workflow run
44779865723: tag `v0.8.2.2`, GitHub pre-release, CurseForge Beta file `9718999`). What it holds:
`docs/changelog.md`, "0.8.2.2". Build-by-build history: `docs/status-history.md` (top) and
`TESTING.md`.

**Tyler, after the release:** paste `docs/curseforge-description.md` into the CurseForge page (it
now says one click buys, the buy bar starts at 1, and mentions the Confirm before buying setting).

**New feedback logged (2026-11-20, waiting on Tyler's decisions):** `FB-056` to `FB-063` in
`docs/feedback.md` (source: `docs/feedback/sources/2026-11-20-curseforge-comments.md`):
- **FB-056 (S1 bug):** dungeon "many Lua errors" warning, possibly on conjured water
  (`user_kc0ds7pqedmptpep`); candidate for a 0.8.2.3 patch hardening `core/tooltip.lua` and
  `util/info.lua`.
- **Small settings/UX requests (candidates for 0.8.2.3 or 0.9):** FB-058 (whole-stack tooltip
  prices by default toggle, `jebbush`), FB-061 (toggle to hide the Professions window Materials and
  profit line, `LLanwrst`), FB-062 (option for right-click bag item to always open Post,
  `rokstar8872` and `deep_structure`).
- **Larger feature requests (candidates for 0.9 or later):** FB-057 (Settings in Options > AddOns
  and `/aux settings`, `LLanwrst` and `jebbush`, mockup first), FB-059 (Waylaid Crate Merchant's
  Favor reward, `sarrathsilentstrider`, Tyler replied 0.9, pairs with FB-042), FB-060 (best items
  to farm like GoldScout, `XtreamCoder`, scope decision needed), FB-063 (keybinds for buying,
  confirming and declining via `Bindings.xml`, `khorrs`).

**Nothing is being built yet.** Next minor version is **0.9** (`docs/roadmap.md`): shopping lists
and Craftsman's Writs, what other characters hold, narrower Sniper (FB-055, Tyler confirmed
2026-11-20: "Save narrow sniper for .9", mockup first), an automatic Full scan option, posting
rules. Small fix candidate before or with 0.9: add a timeout to `wait_throttle` in `core/scan.lua`
and `tabs/search/results.lua` so if Forever's auction throttle ever locks up
(`IsThrottledMessageSystemReady` stuck `false`, Seen 2026-11-20), aux times out with a clear
message instead of sitting on `Reading the listings...`.

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
0. Decisions on the 2026-11-20 feedback batch (FB-056 to FB-063): which go into a 0.8.2.3 patch vs
   0.9 vs wont-fix/later.
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
