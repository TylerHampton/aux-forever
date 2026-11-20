# Takeover brief: Claude Code to Gemini Neon (2026-11-19)

Tyler, 2026-11-19: "Prep this project for a full takeover by Gemini Neon. Leave no stone unturned,
literally every tidbit of information you have learned and created should be passed on to Gemini."
He then chose (the same day): Claude becomes the reviewer; 0.8.2.2 gets a quarter-second rest and
Gemini Neon releases it; everything Claude-only is copied into the repository; Gemini Neon works in
Antigravity and Tyler tests from the `TESTING.md` checklist with results in the chat.

This file is Claude's whole handover. Most of the project's knowledge already lives in the repository
(Claude wrote it there as it went); this file says where, adds what was only in Claude's sessions,
and lists everything open. Read it once in full, then `AGENTS.md` again with it in mind.

## 1. Your first session, in order

1. Pull the active branch `claude/confident-bohr-vctz8g` (it holds 0.8.2.2; `main` holds 0.8.2.1).
2. Install Lua if needed (`sudo apt-get update && sudo apt-get install -y lua5.1 zip`) and run every
   check in `AGENTS.md`, "Tests". Expected on 2026-11-19: `checks: 1421`, `done, errors: 0` in both
   themes, syntax check silent, `lint: 0 unknown names`.
3. Read, in this order: `AGENTS.md`, `docs/status.md` ("Start here"), this file, `TESTING.md`
   ("Current build" and the 0.8.2.2 builds under it), `docs/changelog.md` ("0.8.2.2"), the entries
   FB-048 to FB-055 at the end of `docs/feedback.md`, and `docs/forever-auction-house.md`.
4. Give Tyler `auxForever-0.8.2.2-build3.zip` (build it: section 6) and its one step (`TESTING.md`,
   "Current build"). Record his answer under the build.
5. If he is happy with the rest after buying, ask whether 0.8.2.2 is ready to release. Release only
   when he says so (section 5).
6. Answer note H-012 in `docs/handoff.md`, then end your reply to Tyler with the handoff line.

## 2. The project in a few lines, and where everything is

auxForever ports shirsig's aux addon to World of Warcraft: Forever (modern client, Interface 16001,
`C_AuctionHouse`), with a redesign. Tyler owns it and tests every change in game; he is not a
programmer. Released as an unlisted CurseForge beta (project 1727417) and as GitHub releases.

| Where | What |
| --- | --- |
| `AGENTS.md` | The rules: working with Tyler, roles, workflow, tests, releases, code map, performance, code gotchas, design language. Everything there was learned from a real mistake or a decision of Tyler's. |
| `docs/status.md` | Where things stand now; the next step; open questions. Keep it short and current. |
| `docs/status-history.md` | The status file of every released version, newest first (the full story of how each was built). |
| `docs/handoff.md` | Notes between the agents. |
| `docs/feedback.md` | Every piece of player feedback (FB-001 to FB-055), rules at the top, players listed. Sources word for word in `docs/feedback/sources/`. |
| `docs/forever-auction-house.md` | Facts about Forever's auction house, each labeled Seen, Code, Outside or Unknown, plus experiments for Tyler (E1 to E6). |
| `docs/changelog.md` | Every version's changes; also the CurseForge file changelog. |
| `docs/roadmap.md` | What each version is for; 0.9 is planned. |
| `TESTING.md` | The current build's in-game steps and results; older builds below it; the 5-minute pre-release check. `docs/testing-history.md` holds the oldest checklists. |
| `docs/reviews/` | Six reviews so far (Gemini reviewing Claude, plus an outside review), each finding answered in the file. |
| `docs/clicks.md`, `docs/gamepad.md`, `docs/price-data.md`, `docs/api.md`, `docs/audit-classic-code.md` | Deep notes on clicks, gamepad support, price history, the public API, the Classic code audit. |
| `docs/curseforge.md`, `docs/curseforge-description.md` | CurseForge page settings and the paste-ready description (Tyler pastes it by hand). |
| `docs/mockups/` | Every mockup Claude made, with what was decided (copied from claude.ai on 2026-11-19). |
| `docs/test-results/test-page-results.md` | Every answer Tyler saved on Claude's test page, build by build (exported 2026-11-19). |
| `docs/gemini-setup.md` | Tyler's 2026-10-04 guide to Jules and Gemini CLI (older; Antigravity is what you use now). |
| `tests/` | The Lua 5.1 harness: `load_test.lua` (runs everything), `timing_test.lua` with `slow_server.lua` (a fake auction house that answers late), `fuzz_test.lua` (a random player), `lint_globals.lua`, `forever_api.lua` and `forever_categories.lua` (made from Blizzard's code by `tests/tools/`), `tools/sniper_bench.lua` (new, section 7). |
| `.github/workflows/` | `test.yml` (every push: tests, and the installable zip as an artifact), `release.yml` (tag, GitHub release, CurseForge upload), `curseforge-check.yml`. |

## 3. Where things stand (2026-11-19)

- **Released:** 0.8.2.1 (2026-11-16; tag `v0.8.2.1` on `main`, GitHub release, CurseForge Beta).
- **Built, not released: 0.8.2.2** on `claude/confident-bohr-vctz8g`. Version `forever-0.8.2.2` in
  the TOC; changelog "0.8.2.2 (not released yet)". It holds, from CurseForge comments on 0.8.2.1:
  - FB-050 (Tremulent): the buy bar starts at 1 on the Search tab (it started at a full stack; with
    one-click buying that bought far more than meant). The Sniper still starts at all the units of a
    deal (`whole_deal`), Claude's call, told to Tyler, not yet answered.
  - FB-051 (Tremulent, "double buys"): after any purchase Buy rests `HOLD_SECONDS` and says what was
    bought. 1 s in build 1, 0.5 s in build 2 ("It still feels too long", Tyler), 0.25 s in build 3.
    Tyler first asked "Did you code in a manual wait time? If so I dont like that"; Claude explained
    that a short rest is the only way to tell a habitual second click from a wanted purchase, and he
    then chose half a second, then found it too long. Build 3 is the check.
  - FB-049 (Tremulent): "Confirm before buying", Settings (Buying) and `/aux buy confirm`, off by
    default, for trade goods (the 0.8.2 two-step flow) and gear (Confirm and the price, then a
    second click). Not the Bids tab's Buyout.
  - FB-052 (joker2206): `/aux post bid on` works; an unknown word lists the choices.
  - FB-055 (khorrs; Tyler: "sniper is quite slow"): the Sniper's item list leaves gray items out,
    1 s between Sniper rounds (2.5), Live waits 2 s (5).
- **Tested in game:** build 1 passed all six steps; build 2 passed Live and deals (2026-11-17).
  Build 3 (the quarter second) is not tested yet: your first step with Tyler.
- **Waiting on CurseForge:** Tyler should paste `docs/curseforge-description.md` into the page after
  0.8.2.1 and again after 0.8.2.2 (it now mentions the Confirm setting and starting at 1).

## 4. Everything open

### Decisions only Tyler can make

1. **A narrower Sniper (the real fix for FB-055).** The house was 25,706 items on 2026-11-17: the
   item list alone takes about 38 s (52 requests at about 0.73 s each), so a whole-house round can
   never be quick. Letting the player narrow what the Sniper watches (trade goods only, one
   category, a saved search) would make rounds of a few seconds. It is a new feature: by the version
   rules it belongs in 0.9 unless Tyler says otherwise, and it needs a mockup first. Tyler has not
   answered whether it goes in 0.8.2.2 or 0.9.
2. **The Sniper's start quantity** (FB-050): all the units of a deal, or 1 as on the Search tab.
3. **The rest after buying** (FB-051): build 3's step settles it.
4. **The 70 gear deals at 18 to 30% of usual** on Tyler's Sniper (screenshot of 2026-11-17, all gear
   "of the X"): real (gear prices falling since launch) or noise (out-of-date usual prices for gear
   endings)? Asked, not answered. If noise, each costs a request every time it is checked, and the
   deal rule for gear may need today's market from other versions (it has it only when several
   versions are listed; see `market_now` and H-008 in `tabs/sniper/core.lua`).
5. **FB-054** (jebbush, "Bag searching could use an update, cannot sort by bag slots"): which screen?
   Likely the Post tab's bag list, sorted by name (`tabs/post/core.lua`). Players are never asked.
6. **FB-053** (a controller button to search): 0.9. Before building, an experiment in game: can an
   addon bind the triggers (LT, RT) in Forever's gamepad mode, and what do they do there now?
   Tyler does not test with a controller (0.8 build 1: "I'll leave that up to users who actually use
   controller mode"); nokkty tested 0.8's gamepad support.
7. **Replies to players.** A ready reply for joker2206 is in FB-052. Replies to the 2026-11-08 and
   2026-11-16 batches were never written; Tyler has not said whether he wants them.
8. Older questions (also in `docs/status.md`): FB-046 (does Tyler use Bagnon?), FB-042 (a screenshot
   of a Waylaid Crate's turn-in reward), R-27 / experiments E1 and E4 (one sale's "Auction
   successful" mail settles the 5% cut; one auction left to expire settles the deposit).

### Built but not seen in game (watch feedback)

One-click buying (FB-048) and copper on gear (FB-044) were seen working. Not seen: the locked-item
message with bag addons (FB-046), "of Shadow Protection" tooltips (FB-045), buying through a row of
many sellers past the re-read (S-08; Tyler, 2026-11-16: "save the test for a later date"; a cheaper
check is in `docs/status.md`).

### Not built (known)

"N sellers" is an upper bound (a seller in two rows counts twice); S-09 (the Post receipt shows a
starting bid for a trade good with no price typed); FB-042 and FB-043 (crate cost with Merchant's
Favor and reward silver; a list of crates and writs; 0.9 with writs); from the outside review R-23,
R-25, R-27, R-28 and parts of R-16 and R-20 (answers in `docs/reviews/2026-11-10-outside-review.md`).

### 0.9 (planned, `docs/roadmap.md`)

Shopping lists and writs, an automatic Full scan option, posting rules; FB-053 and the narrower
Sniper are candidates.

## 5. How each piece of the workflow is done

### A build

1. Work on the active branch; one agent at a time.
2. Every bug fix and feature gets a test that fails without it (break the code, run, restore).
   Anything that talks to the auction house gets a timing test against the slow fake. After a change
   to buying, posting, scans or the gamepad, run the random player long:
   `AUX_FUZZ_SEEDS=400 AUX_FUZZ_STEPS=250 lua5.1 ../tests/load_test.lua` (about two minutes).
3. Version numbers (Tyler, 2026-10-09): a fix raises the fourth number (0.8.2.1 -> 0.8.2.2); a bigger
   update within a version the third; new features the next minor version (0.9). Raise it in
   `auxForever/auxForever.toc` (`## Version: forever-x.y.z.w`) once per version, with a changelog
   entry "x.y.z (not released yet)". Builds within a version are numbered 1, 2, 3 in `TESTING.md`
   and in the zip name, not in the TOC.
4. Changelog style: every change with what changed and why it matters to a player, grouped by area,
   crediting the player by name ("(reported by X)", "(suggested by X)"); never "minor fixes".
5. `TESTING.md`: a "Current build" heading with what changed, the zip name, `/reload` or full
   restart, then numbered steps written so Tyler can follow them without guessing (exact action and
   place, the words the screen shows, a real example). Keep them few. Move the previous current build
   down under its own heading.
6. Commit messages: a short summary, then plain sentences on what and why; no em dashes. Push.
7. Update `docs/status.md` ("Start here") and the feedback entries' status.

### Player feedback

Tyler pastes CurseForge comments (often as screenshots). Log every point before fixing: one entry per
distinct point (Tremulent's one comment became FB-049, FB-050 and FB-051), the words exactly as
written, a source file in `docs/feedback/sources/` with the whole thread, the player under
"Players". Never treat it as the player's mistake. Never ask players follow-up questions.
Screenshots are described in words, not saved, unless the picture itself matters.

### Testing with Tyler

He runs the steps and answers in the chat. Habits worth knowing: he often sends screenshots without
saying Pass or Fail (judge from the picture); he takes screenshots with Win+Shift+S, which holds
Shift, so tooltip prices then show the whole stack ("for 3"); he cannot do steps that need fast
hands ("I cant move my hand that fast", 0.8 build 13; 0.7.1.1); he dislikes unclear questions ("I
dont really understand what you are asking"). Steps that spend gold say how much. A step that needs
something he may not have says how to get it or is left out.

### A release (only when Tyler says the version is ready)

As done for 0.8.1, 0.8.2 and 0.8.2.1:
1. Date the version's changelog heading (his date).
2. Open a pull request from the active branch to `main` and let the Tests check pass; merge it
   (squash, as before) only because Tyler asked.
3. Run the Release workflow on `main` (GitHub, Actions, Release, "Run workflow", or through the API).
   It reads the TOC version, runs the tests, builds `auxForever-<version>.zip`, creates tag
   `v<version>`, publishes a GitHub pre-release with the changelog notes, and uploads to CurseForge
   (project 1727417, Beta, secret `CF_API_KEY`); its log shows the CurseForge file id.
4. Afterwards: merge `main` back into the branch; mark the version's feedback entries "released
   <date>"; move the status file's notes into `docs/status-history.md`; update `docs/roadmap.md`;
   remind Tyler to paste `docs/curseforge-description.md` into the CurseForge page.
5. Minor releases (0.9) also get the 5-minute pre-release check in `TESTING.md`.

### Talking with Claude (the reviewer now)

Leave a numbered note under "Open" in `docs/handoff.md` saying what to review (branch, commits, the
question) and where to answer; Claude writes `docs/reviews/<date>-<topic>.md`. Answer each finding in
that file after checking it. End every reply to Tyler with the handoff line.

## 6. Making Tyler's zip

From the repository root: `zip -qr auxForever-0.8.2.2-build3.zip auxForever -x '*.git*'`. The
folder at the top of the zip must be `auxForever`. `.gitignore` keeps zips out of commits. If you
cannot hand Tyler a file, every push builds the same zip on GitHub Actions: the push's "Tests" run,
"auxForever" under Artifacts. Always tell him `/reload` is enough or a full game restart is needed
(a new file of any kind needs a restart).

## 7. What Claude learned recently that is not written elsewhere (or only in passing)

- **Forever's auction house size (Seen, 2026-11-17):** 25,706 items in the whole-house list, 37.7 s,
  52 requests (October: 7,718 in 8.5 s, 16 requests). Grays were 519 (2%). Recorded in
  `docs/forever-auction-house.md`.
- **Where a Sniper round's time goes (harness, 2026-11-17):** aux's own work is 20 to 50 ms of CPU
  for 8,000 items; the rest is waiting on requests. `tests/tools/sniper_bench.lua` measures it:
  `AUX_BENCH=1 lua5.1 ../tests/load_test.lua` from `auxForever/` (add `BENCH_N=25000` for Forever's
  size). It replaces the timing tests and the random player for that run.
- **Live** is the fast path for watching one item (2 s pause, about two requests a round). Players
  who used Classic aux's real-time mode to snipe undercuts (khorrs) expect that speed. Classic aux
  watched the last result page; Forever has no pages (Outside, from memory of Classic aux).
- **A one-frame race in the Sniper (harmless, noticed 2026-11-19):** a click on a deal in the same
  frame as a round opens that item puts a new record in the deal's place; the selection follows it,
  so the player sees nothing wrong. `selected_live_key()` relies on `checked`, which
  `update_selection()` sets on the next frame.
- **Gear deals with 1 s rounds:** a gear deal clicked more than a moment after its round is read
  again first (one request), because the next round has searched other items and the game takes a
  gear purchase from the item's latest search (H-008 finding 6). Correct, slightly slower.
- **The buy bar's states** (`gui/buy_bar.lua`): IDLE, QUOTING, QUOTED (only with Confirm before
  buying), BUYING; `item_confirm` for gear waiting on Confirm; `hold_until` and `message_item` for the
  rest after a purchase; `shown` holds what the button last drew (a click that does not match it
  only redraws). Callers' `on_buy(on_bought)` call `on_bought` on success so the bar can rest.
- **Test harness lessons from 0.8.2.2:**
  - A test that buys twice must tick past `HOLD_SECONDS` (`for _ = 1, 11 do tick() end` was used).
  - The Sniper table redraws at most twice a second: select a deal only once the table lists it.
    Tests that keep a deal record from an earlier round can hold a stale one; look it up again in
    `sniper.deals`.
  - `load_test.lua`'s own stubs save some names as green (quality 2), for example "Linen Belt"
    (item 4571) and "Bolt of Woolen Cloth"; an exact search asks for the quality saved for its name.
    The slow fake therefore applies rarity filters only to items that state a `quality`.
  - The slow fake's commodity quotes run out after 20 s (`server.quote_seconds`); the real duration
    is Unknown.
  - `checks: N` can move by one or two between runs when the random player's path changes (it adds
    a check per post and per cancel). A bigger drop means a block stopped.
- **Claude's own tooling, now gone for you:** claude.ai test pages (results exported), claude.ai
  mockups (copied to `docs/mockups/`), GitHub through an MCP server (Claude's cloud session could not
  push tags, so releases ran through the Release workflow, which you can use the same way).
- **Branches on GitHub:** `claude/confident-bohr-vctz8g` (active, 0.8.2.2). `claude/fervent-planck-ry58jx`
  and `claude/magical-maxwell-eyud0b` hold only a few docs commits written after the 0.8 and 0.8.2
  squash merges ("released" notes in status, roadmap and feedback); later status files supersede
  them. `design` is
  merged. Old `claude/festive-faraday-w1xbvz` (0.8.2.1) was the handoff's active branch until
  2026-11-19. Delete old branches only if Tyler asks.

## 8. Tyler's preferences that matter most day to day

All are in `AGENTS.md`; these are the ones that came up most:
- Lead with the answer; plain words; say what to click and where; ask before large or visual work
  (mockup first; this time he said "no mockup" for the Confirm setting).
- No flattery; push back on weak ideas with the reason; say what is known, inferred, unsure.
- Facts about Forever's auction house only with their label; only Seen facts go to players.
- The addon informs, never refuses what Blizzard's window allows. The rest after buying was judged
  not to break this (it delays a click by a quarter second, it refuses nothing), but Tyler dislikes
  "manual wait times": keep it as short as works.
- Performance matters ("add-on performance and compute cost is very important").
- Privacy: nothing about Tyler's life in this public repository, not even schedule or friends
  (two notes in the test results export were redacted for that).
- Dates in his time zone (UTC-7 in winter): `TZ='<-07>7<-06>,M3.2.0,M11.1.0' date`.
- When he says he is stopping for the day, wrap up without being asked (`AGENTS.md`).
