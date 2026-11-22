# Status

Last updated 2026-11-22, Tyler's time (`0.9` released on `main`, 2026-11-22; next version `0.9.1`
holds the remaining Waylaid Crate Favor/Writs, Shopping List + Alt Inventory, and Posting Rules).

Keep this file short: where things stand, the next step, open questions. When a version is
released, move its notes to `docs/status-history.md` (everything before 2026-11-20 and 0.9's
build-by-build log are there).

## Start here (next session)

**Released:** **0.9** on 2026-11-22 on `main` (tag `v0.9`, GitHub pre-release, CurseForge Beta
upload). Full build-by-build log (builds 1 to 4, all tested in game by Tyler): `docs/status-history.md`
and `TESTING.md`. Release notes: `docs/changelog.md` ("0.9"). Updating from 0.8.2.2 needs a **full
game restart** for `Bindings.xml`.

**Tyler, after the 0.9 release:** paste `docs/curseforge-description.md` into the CurseForge
project page when convenient (updated for 0.9's Options > AddOns panel, Narrower Sniper, keybinds,
and settings).

**Next up: 0.9.1 (branch `gemini/0.9.1` from `main`, mockup first for each):**
1. **Waylaid Crate Merchant's Favor & reward silver (`FB-059`, `FB-042`, `FB-043`) + Craftsman's
   Writs (`FB-020`):** waiting on in-game screenshots of a Waylaid Crate turn-in reward window and a
   Craftsman's Writ tooltip from Tyler before mocking up.
2. **Crafting Shopping List + Alt Inventory tracking (`FB-023`, Kortan):** ready to design a mockup
   at the start of the next session even before crate/writ screenshots arrive.
3. **Posting rules based on usual price (`FB-031`, user_yt0k9lezehn1ukm993387):** TSM-style
   floor/normal/ceiling rules for the Post tab (mockup first).
4. **Watch `FB-065`** (marcus4555 Sniper 0 deals report) if the player replies with diagnostic info.

**Planned for 0.10 (final beta):** granular scan-age timestamps & cleaner tooltip presentation
(Tyler, 2026-11-21), Full scan speed/memory pass, and 1.0 readiness (`docs/roadmap.md`).

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
`docs/roadmap.md` (0.9.1: Waylaid Crate Favor/Writs, shopping list + alt inventory, posting rules;
0.10: granular scan ages & performance), player feedback in `docs/feedback.md`, facts about
Forever's auction house in `docs/forever-auction-house.md`, older status notes in
`docs/status-history.md`.
