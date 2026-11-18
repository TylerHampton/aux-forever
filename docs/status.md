# Status

Last updated 2026-11-17, Tyler's time (0.8.2.2 build 2 waiting for Tyler's test).

Keep this file short: where things stand, the next step, open questions. When a version is
released, move its notes to `docs/status-history.md` (everything before 2026-11-10 is there).

## Start here (next session)

**Released:** 0.8.2.1 on 2026-11-16 (pull request to `main`, Release workflow: tag `v0.8.2.1`,
GitHub release, CurseForge Beta file). What it holds: `docs/changelog.md`, "0.8.2.1". How it was
built and tested, build by build: `docs/status-history.md` (top) and `TESTING.md`.

**Tyler, after the release:** paste `docs/curseforge-description.md` into the CurseForge page (it
now says a trade good is bought with one click).

**Being built: 0.8.2.2** (branch `claude/confident-bohr-vctz8g`), buying fixes from the
CurseForge comments on 0.8.2.1 (Tyler, 2026-11-17: "Cover gear too, default off, no mockup, build
it"). Build 1 passed every step in game (2026-11-17). Build 2 waits for Tyler's test (`TESTING.md`,
"Current build", test page build id `0-8-2-2-build-2`, zip `auxForever-0.8.2.2-build2.zip`,
`/reload` is enough): FB-055 (khorrs; Tyler: "sniper is quite slow"; he chose all three changes):
the Sniper's item list leaves grays out, 1 s between Sniper rounds (2.5), Live every 2 s (5), and
the FB-051 rest is half a second (1). A harness measurement showed aux's own work per round is
20 to 50 ms for 8,000 items: round time is the auction house. Build 1 held:
- FB-050: the buy bar starts at 1 on the Search tab (it started at a full stack). The Sniper
  still starts at a deal's units (`whole_deal`), Claude's call: tell Tyler, he may want 1 there.
- FB-051: after any purchase Buy rests (half a second since build 2) and says what was bought (likely cause of the
  double buys: the Buy then Confirm habit; inference, not seen in game).
- FB-049: Settings, Buying, "Confirm before buying", and `/aux buy confirm`; off by default; trade
  goods (the 0.8.2 Confirm flow, with Cancel and the quote running out) and gear (Confirm and the
  price, then a second click). Not the Bids tab's Buyout. The random player runs half its
  sessions with it on; the fake auction house's quotes now run out after 20 seconds.
- FB-052: `/aux post bid on` works; an unknown word lists the choices.
Build 2 tested (2026-11-17): Live and deals pass; the house is now 25,706 items (37.7 s, 52
requests for the list alone; grays only 2%), so a whole-house Sniper round cannot go under about
38 s. Waiting on Tyler: the rest after buying (he finds half a second too long; Claude recommends a
quarter second), and whether a narrower Sniper (a category, trade goods, a saved search; mockup
first) goes into 0.8.2.2 or 0.9.
After that: the pull request and release, when Tyler asks.

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
