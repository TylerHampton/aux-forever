# Status

Last updated 2026-11-11, Tyler's time.

Keep this file short: where things stand, the next step, open questions. When a version is
released, move its notes to `docs/status-history.md` (everything before 2026-11-10 is there).

## Start here (next session)

**Released:** 0.8.2 (tag `v0.8.2` on `main`, GitHub release, CurseForge Beta file), 2026-11-09.

**Being built:** 0.8.2.1 build 4 on branch `claude/festive-faraday-w1xbvz` (`main` plus this work).
Not tested in game yet (builds 1 to 3 were never tested either; build 4 holds everything). No pull
request yet.

**What 0.8.2.1 is.** On 2026-11-10 Tyler asked Claude for a full review of the code as an outside
expert, then to build the fixes ("I want you to write all the changes as well"), then said yes to
the two open questions and left Claude to "fix everything you can". The review is
`docs/reviews/2026-11-10-outside-review.md`: 28 findings (R-01 to R-28), each answered under it,
plus a second pass over the files it had only skimmed (S-01 to S-04) and three fixes found by a
random player in the tests (S-05 to S-07, build 4, 2026-11-11). 21 fixed, 4 in part, 3 not
built. Every fix has a test that fails without it (each was broken on purpose once to see its test
fail). What changed, by area:
- Sniper: a round without the whole item list no longer marks deals gone (R-01, R-02); items are
  judged again after a Full scan and on a new day (R-03); a re-read gear deal takes the price of the
  auction found (R-14); Ignore item works by name (R-20).
- A partly arrived item list is noticed and handled in Search, Live, Post and the Auctions check
  (R-02; `core/scan.lua` hands `on_complete` a result with `no_list`, `partial_list`, `unread`).
- Full scan speed (FB-027): pauses by the clock (`aux.coro_due`, `SLICE_MS = 8` in `control.lua`),
  no auction record per listing (`info.replicate_reader`), unloaded listings a share at a time
  (R-07 to R-09). In the test harness 200,000 auctions went from 2,052 frames to 145. The clock is
  the game's `debugprofilestop`, which is in Blizzard's documentation for Forever (Code, build
  70888); without it aux falls back to the old counts.
- Prices not seen for 90 days are forgotten, once a day at login (R-10, Tyler: yes).
- Gamepad: the buttons go back to the game when a fight starts and come back after it (R-19,
  Tyler: yes). Not seen in game; it only acts when the game says it is not locked yet.
- Bids buttons (R-04), `/aux clear post` (R-06), price boxes (R-15), events and threads (R-18),
  lighter bag count (R-11), fewer table redraws (R-12), login work (R-13), the short list of R-20,
  search bar typing (S-01), right-click searches on unknown items (S-02).
- Build 4, found by the random player: leaving the Post tab while gear listings are read raised
  an error (S-05); the buy bar's click could act on a newer selection or price than its label
  (S-06, the bar now remembers what it drew: `shown` in `gui/buy_bar.lua`); a click on Post past
  the fade (S-07, `post_auction` asks `disabled_reason()` itself).
- The random player: `tests/fuzz_test.lua`, run at the end of `load_test.lua` (6 short sessions by
  default; `AUX_FUZZ_SEEDS=400 AUX_FUZZ_STEPS=250` for a long run, clean on 2026-11-11). Stub
  buttons now know whether they are enabled, and `Click()` respects it (`AGENTS.md`, Tests).
- Tests: swapped fields are restored (R-21); game functions, events and enums are checked against
  Forever's real list, `tests/forever_api.lua` (R-22); `tests/lint_globals.lua` finds misspelled
  names (R-24); the run prints its check count (1,303); the slow auction house can cut or withhold
  an item list and gives each auction its own ID. Blizzard's code is reachable from a cloud
  session: clone `Gethe/wow-ui-source`, branch `forever`, with `--filter=blob:none --no-checkout`.

**Not built, and why** (answers in the review file): R-05 (measure first), R-27 (needs a sale in
game), R-28 (structure, for a later version), the test file split (R-23), naming the release action
by commit (R-25), and one part each of R-16 and R-20 (each would change something that works today).

**Next step:** Tyler tests build 4 (eleven steps, step 10 only with a gamepad: `TESTING.md`, test
page build id `0-8-2-1-build-4`, zip `auxForever-0.8.2.1-build4.zip`, `/reload` is enough). Read the
test page results first. Step 1 gives the Full scan's time in game: put that number into the
0.8.2.1 changelog entry (it only says "faster" now) and, if the game stuttered, lower `SLICE_MS`.
When it passes and Tyler says so: changelog date, pull request to `main`, merge, Release workflow.
The CurseForge description does not change.

**Open questions for Tyler:**
1. R-05: step 4 of the build 4 checklist asks for the `/aux debug` lines of a search run twice.
   The new line "The game announced N of M answers itself, J of the K taken after the 1s
   fallback" says whether aux can wait for the game's own "results arrived" event (Code:
   `AUCTION_HOUSE_NEW_RESULTS_RECEIVED`) instead of taking held results after 1 second. If J equals
   K (and K is above 0), build that next. A line from a busy day is worth more than a quiet one.
2. R-27: one sale and a screenshot of its "Auction successful" mail (experiment E1 in
   `docs/forever-auction-house.md`) settles the 5% cut that aux shows as fact. One auction left to
   expire (E4) settles the deposit tooltip's "kept if the auction expires".
3. From before the review: replies to the players of the 2026-11-08 feedback batch are not written;
   does he want them? FB-039 (a player's Full scan "wasnt working") has no details yet.

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
