# Status

Last updated 2026-11-22, Tyler's time (`0.9` build 3 built on branch `gemini/0.9`, ready for
in-game testing; `/reload` is enough from Build 2; 0.8.2.2 released on `main`).

Keep this file short: where things stand, the next step, open questions. When a version is
released, move its notes to `docs/status-history.md` (everything before 2026-11-20 is there).

## Start here (next session)

**Active branch:** `gemini/0.9` (version `forever-0.9`, build 3 ready to test in game; zip
`auxForever-0.9-build3.zip`, `/reload` is enough if upgrading from Build 2; full game restart only
if upgrading from 0.8.2.2 or Build 1 because of `Bindings.xml`).

**What is in 0.9 build 3 (2026-11-22, Phase 2 complete + Build 2 polish):**
- `FB-057` (LLanwrst, jebbush): Blizzard **Options > AddOns > auxForever** canvas settings panel
  (`Settings.RegisterCanvasLayoutCategory` + `Settings.RegisterAddOnCategory`), `/aux settings`
  (aliases `/aux config`, `/aux options`) with combat-lockdown guard, live two-way sync with the AH
  Settings gear popup and `/aux` commands, keybinds note, and **Clear post prices** / **Clear item
  cache** maintenance buttons with confirmation popups.
- Minimalist item tooltips (Option B, Tyler): removed `for N` from Vendor and Value lines, compact
  age labels (`today`, `3d`, dimmed `9d` via `history.short_age_text`), keeping full `age_text` for
  `/aux price`. (Tyler logged a 0.10 goal in `docs/roadmap.md` for more granular scan-age intervals
  and presentation.)
- Aligned Professions crafting hover tooltip (Tyler): moved `today`/`Nd`/`vendor` and `(%)` in
  front of costs so all prices line up down the right edge; trimmed subtitle/cut/output wording
  (`T5`).
- `FB-062` default flipped to **on** (`right_click_post = true`, Tyler: welcomes players coming
  from Blizzard's default AH).
- Approved UI wordiness trims `T1` to `T6` (Post `Deposit` / `AH cut (5%)`, Buy bar idle and
  `N at this price`, crafting hover `T5`, Sniper empty message `T6`).
- Added +12px bottom breathing room to the AH Settings gear popup (`416` normal / `444` waiting for
  Theme reload).

**0.9 build 2 results (Tyler, 2026-11-21):**
- Steps 1 to 5 all passed in game (including `Bindings.xml` under Options > Keybindings > auxForever
  after full restart, and `S-09` Post no-price receipt fix).
- E9 printed `E9 send: 4567 true` and `E9: 4567 0 true nil nil` (`HasSearchResults == true`, server
  answered for item 4567 with 0 listed; suffixed variants still Unknown). E10 printed `E10 send:
  false` (throttle busy right after E9; still Unknown, save standalone probe for Phase 3).

**Waiting on Tyler (in `TESTING.md` + side-pane test artifact):**
1. Test 0.9 build 3 in game (`/reload` is enough from Build 2): Option B tooltips, aligned crafting
   hover, Blizzard Options > AddOns > auxForever + `/aux settings` + live sync + Clear buttons,
   `right_click_post` default, and `T1` to `T6` trims.
2. Next up: Phase 3 (`FB-055` Narrower Sniper mockup + clean standalone E10 probe), then Phase 4
   (`FB-059`/`FB-042` Waylaid Crate Favor + `FB-020` Craftsman's Writs, needing crate turn-in and
   writ screenshots), Phase 5 (`FB-023` shopping list + alt inventory), and Phase 6 (`FB-031`
   posting rules).

**Released:** 0.8.2.2 on 2026-11-20 (PR #43 squash-merged to `main`, Release workflow run
44779865723: tag `v0.8.2.2`, GitHub pre-release, CurseForge Beta file `9718999`). What it holds:
`docs/changelog.md`, "0.8.2.2". Build-by-build history: `docs/status-history.md` (top) and
`TESTING.md`.

**Tyler, after the 0.8.2.2 release:** paste `docs/curseforge-description.md` into the CurseForge
page if not done yet.

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
