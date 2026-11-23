# Status

Last updated 2026-11-23, Tyler's time (`0.9.0.1` hotfix for `FB-067` released on `main`,
2026-11-23; `gemini/0.9.1` active with `0.9.0.1` merged in).

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
1. **Posting rules based on usual price (`FB-031`, user_yt0k9lezehn1ukm993387):** interactive
   mockup shown in session; awaiting Tyler's approval on default percentages, layout, and fallback
   behavior.
2. **Waylaid Crate Merchant's Favor & reward silver (`FB-059`, `FB-042`, `FB-043`) + Craftsman's
   Writs (`FB-020`):** web research (`[Outside]`, Forever guides) completed on 2026-11-22; awaiting
   Tyler's in-game confirmation (especially Artisan crate Favor/silver) before mocking up.
3. **Watch `FB-065`** (marcus4555 Sniper 0 deals report) if the player replies with diagnostic info.

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
