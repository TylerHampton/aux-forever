# Status

Last updated 2026-11-20, Tyler's time (0.8.2.2 build 4 passed; ready to release when Tyler says).

Keep this file short: where things stand, the next step, open questions. When a version is
released, move its notes to `docs/status-history.md` (everything before 2026-11-10 is there).

## Start here (next session)

**Takeover (Tyler, 2026-11-19):** Gemini Neon is now the primary engineer and Claude Code the
reviewer (`AGENTS.md`, "Roles"). H-012 in `docs/handoff.md` stays open until 0.8.2.2 is released.
Claude-only tools are retired: mockups are in `docs/mockups/`, the test page's saved answers in
`docs/test-results/test-page-results.md`.

**Released:** 0.8.2.1 on 2026-11-16 (pull request to `main`, Release workflow: tag `v0.8.2.1`,
GitHub release, CurseForge Beta file). What it holds: `docs/changelog.md`, "0.8.2.1". How it was
built and tested, build by build: `docs/status-history.md` (top) and `TESTING.md`.

**Tyler, after the release:** paste `docs/curseforge-description.md` into the CurseForge page (it
now says a trade good is bought with one click, starts at 1, and mentions Confirm before buying).

**Ready to release: 0.8.2.2** (branch `claude/confident-bohr-vctz8g`). Every non-gamepad step across
builds 1, 2 and 4 passed in game:
- Build 1 (passed 2026-11-17): FB-050 (Search buy bar starts at 1; Sniper still starts at a deal's
  units), FB-051 (rest after buying, tuned to 0.25 s in build 3), FB-049 (Settings > Buying >
  "Confirm before buying" and `/aux buy confirm`, off by default, trade goods and gear), FB-052
  (`/aux post bid on`).
- Build 2 (passed 2026-11-17): FB-055 (Sniper skips grays, 1 s between rounds, Live every 2 s).
  The house was 25,706 items (37.7 s, 52 requests for the list alone; grays only 2%), so a
  whole-house Sniper round cannot go under about 38 s.
- Build 4 (passed 2026-11-20): quarter-second rest after buying passed; mouse tooltip sanity check
  passed; PR #41 (nokkty, gamepad item compare; skipped by Tyler, tested by nokkty and automated
  tests) and PR #37 (Dragoy, Full scan cooldown and no-answer message polish) integrated and closed;
  CI test artifacts now named `auxForever-<version>-build<n>.zip`.

Waiting on Tyler: say the word to release 0.8.2.2 (PR to `main` + Release workflow), and decide
whether a narrower Sniper (FB-055, mockup first) goes into 0.9.

Next version after that: not chosen; candidates below and in `docs/roadmap.md` (0.9: shopping
lists and writs, an automatic Full scan option, posting rules; FB-053, a controller button to
search, belongs there).

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
0. FB-054 (jebbush, "cannot sort by bag slots"): does he know which screen they meant? Likely the
   Post tab's bag list, sorted by name. FB-053: whether Forever's gamepad mode lets an addon use
   the triggers (an experiment before building). FB-052: a reply for joker2206 is in its entry.
1. FB-046: does he use Bagnon? FB-042: a screenshot of a Waylaid Crate's turn-in reward.
2. R-27: one sale and a screenshot of its "Auction successful" mail (experiment E1) settles the 5%
   cut aux shows as fact; one auction left to expire (E4) settles "kept if the auction expires".
3. Replies to the players of the 2026-11-08 and 2026-11-16 feedback batches are not written; does
   he want them?

**Roles (Tyler, 2026-11-19):** Gemini Neon is the primary engineer; Claude Code gives second
opinions in `docs/reviews/` (`AGENTS.md`, "Roles"; until 2026-11-19 it was the other way, with
Gemini 4 Argon reviewing). Agents talk through `docs/handoff.md`; Tyler only says "Check the
handoff". Open there: H-012, the takeover, for Gemini Neon.

**How Tyler tests:** from `TESTING.md` ("Current build"): he runs the steps and answers in the chat
with Pass or Fail, notes and screenshots; the engineer writes them under the build as "Results".
He often sends screenshots without saying Pass or Fail (judge from the picture). He screenshots
with Win+Shift+S, which holds Shift (tooltip prices then show the whole stack, "for 3"). Zips are
`auxForever-<version>-build<n>.zip`; always say whether `/reload` is enough. (Until 2026-11-19 Claude
used a claude.ai test page; its answers are in `docs/test-results/test-page-results.md`.)

**Where the rest is:** everything Claude knew at the takeover in `docs/takeover-2026-11.md`, plans in `docs/roadmap.md` (0.9: shopping lists, an automatic Full scan
option, posting rules), player feedback in `docs/feedback.md`, facts about Forever's auction house
in `docs/forever-auction-house.md`, older status notes in `docs/status-history.md`.
