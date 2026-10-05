# Status

Last updated at the end of the first session (2026-10-04).

## Working in game (tested by Tyler)

- Search, shift-click and alt-click from bags into Search and Post.
- Buy bar: trade goods by quantity with a confirmed server price, gear one at a time.
  Purchases matched the mail exactly.
- Resizable window that remembers its size and position.
- Rename to auxForever. Credit line, changed by Tyler on 2026-10-05 (was "aux by shirsig, granted
  immortality by Tyler"): "aux by shirsig, re-imagined by a fan".
- New look: top bar with tabs, rounded corners, amber accent, "N sellers" in the seller column.
- Undercut mode: match the cheapest price by default, goblin toggle to undercut.
- Post tab duration dropdown (fixed this session).

## Open

1. Done: Forever rejected all three bundled fonts (Barlow, a basic rebuild, PT Sans Narrow), so
   they were removed and the game font is used. Cancel on the buy bar was fixed (it was hidden
   and re-shown every frame, which drops clicks); needs checking in game.
2. Done: the status bar is dim gray when idle (Tyler agreed). Gear is now priced in whole silver
   and undercut by 1 silver; needs checking in game (post a green item in undercut mode).
3. Built in 0.2.1 (2026-10-05), tried in game by Tyler, who approved it for release: the result count on
   the "Search Results" sub tab, the summary line next to the sub tabs ("11 price levels, 6,180 for
   sale, searched 2m ago", Results sub tab only) and a magnifier in the search bar. The sub tab
   buttons are narrower (200) to make room. New texture `textures/search.tga`: full restart.
   Gemini's mockup for this (branch `gemini/search-details`, only on Tyler's PC) was not used.
   Also in 0.2.1: trade goods on the Post tab have one Quantity box (Max = everything in the bags)
   instead of Stack size and Stacks, since Forever posts a trade good as one listing of any size;
   10 x 2 used to leave 9 of 29 Blood Shards behind. Stack size stays 1 internally.
   After Tyler's test run (2026-10-05): the summary counted every auction as a "price level"
   ("403 price levels, 403 for sale"); it now counts items ("37 items, 403 for sale") and only says
   price levels for a one-item search. Filter Builder: All / Any switches fade with fewer than two
   conditions under them (Tyler toggled the top switch with one group and saw no change), and the
   builder no longer re-reads its own text when reopened, which flattened a lone group. Broad gear
   searches are slow because Forever answers one item per request; fast mode is planned for 0.3
   (`docs/roadmap.md`).
   Blizzard UI button "unreliable" (Tyler; moving aux did not reveal the window, so it was not
   just behind aux). Cause found in Blizzard's UIParentPanelManager: side windows are anchored
   with offsets divided by the window's scale, so any panel layout while aux keeps the Blizzard
   window shrunk to 1% (opening the character sheet, spellbook, a vendor) put it 100 times too
   far, off screen. On showing it, aux now scales such an anchor back
   (`fix_blizzard_frame_position` in `aux-addon.lua`), clamps it to the screen, raises it above
   aux, and lights the button while it is shown. Not confirmed in game yet.
   Settings (Tyler, 2026-10-05): no explanation text in the menu; "Default duration" replaces
   "Auction length" plus its note; a Scale row (70% to 150%, 5% steps, for 1440p screens) replaces
   the slash-only `/aux scale`, whose saved value was never applied after a reload before. The
   resize corner anchors the window by its top left before sizing: it started out anchored by its
   left edge, and sizing from the corner then could jump to full screen on one click (Tyler).
   Code review (2026-10-05): client-side work is small; slowness is mostly one server request per
   item. Two waits in `core/scan.lua` may add to it: 1s before using results the client already
   holds when no event comes, and 20s when no answer comes at all. `/aux debug` (search timing
   log, `timing_report` in scan.lua) measures this.
   Measured by Tyler (step 4 of the test scenario, 335 items): 3m 13s, 0.58s per item. Throttle
   2m 19s (72%), server answers 53s, item data 0.8s, item list 0.1s, other 0.0s. 336 answers on
   time, none after the 1s fallback, none timed out. So the waits in our code are not the problem
   and the addon's own work is negligible: the time goes to Blizzard's request rate limit
   (`IsThrottledMessageSystemReady`), which allows about one item search every 0.4s. Nothing in
   full mode can beat that; fast mode (0.3) can, since the item list itself (0.1s here) already
   holds each item's lowest price and quantity. The waits stay as they are, and the table refresh
   change is dropped (no measurable cost).
4. Not yet tested in game: Auctions tab cancel, Bids tab, full scan, posting gear with a bid,
   Filter Builder dropdowns after the dropdown fix. See `TESTING.md`.
5. Later: Tyler sends Simon (shirsig) the project to review before it goes public. The GitHub
   repository can optionally be renamed to auxForever.

## Repository

Public since 2026-10-04. PR #1 (everything up to 0.2) was merged into `main` on 2026-10-05, so
`main` is auxForever 0.2. New work starts from `main` on its own branch.

Since 2026-10-05 Gemini may work on the repository too. `AGENTS.md` is the shared guide for every
agent (`CLAUDE.md` and `GEMINI.md` load it); `docs/gemini-setup.md` is Tyler's setup guide. GitHub
Actions (`.github/workflows/test.yml`) runs the tests on every push and offers the addon as a
download. Every agent: pull first, one agent per branch, update this file when done.

## 0.3 (planning, see docs/roadmap.md)

- Decisions recorded in the roadmap: automatic fast mode, Sniper as its own top tab, default deal
  rule.
- `/aux debug list` (`measure_item_list` in core/scan.lua) times the whole auction house's item
  list. First try failed at once (a `pcall` around the waiting request, fixed in a7c9835); the
  rerun gave 7718 items in 8.5s, 16 requests.
- Mockups for fast mode and the Sniper: https://claude.ai/artifact/Q5C3ScRtCLV9ohYCcuyuRA
  (private to Tyler). Approved ("let's see the prototype").
- 0.3 first build (TOC `forever-0.3.0-dev`, branch `claude/modest-volta-4mgmsb`, sent as a zip):
  fast mode on Search (Fast / Full switch, click a row to read its auctions), Live mode with a
  visible countdown and paused state, and the Sniper tab. Decisions and known limits:
  `docs/roadmap.md`, "Built". In-game checks: `TESTING.md` section 15. Not tested in game yet.
  Unknowns to watch: whether the item list's lowest price is ever a bid (`/aux debug` prints a
  line when an opened item differs), whether item list names include suffixes, the Sniper's
  round time over a long session, and whether the server minds rounds back to back.
- Tyler's first 0.3 test (2026-10-05), neither reproduced since:
  1. Live stuck on "Updating" with an empty table and the status bar full. Cause not confirmed;
     the likely one is an error inside the scan's thread, which used to leave the scan marked as
     running forever. `aux.coro_thread` now takes an error handler: the scan ends as if stopped
     (Live shows Paused, chat asks for the BugSack text) and the error still reaches BugSack.
     Live also restarts by itself if it says Updating with no round running.
  2. Blizzard's own tabs (Buy, Sell, Auctions) stretched off the screen. Likely cause: Blizzard
     sizes its tabs to their text when shown, and that ran while aux kept the window at 1% scale.
     The tabs are now measured again with Blizzard's code whenever the window is shown at full size.
  3. Items in the reagent bag (Forever's bag 5) were missing from the Post tab: aux read bags 0 to 4
     only. `info.inventory` now goes up to `NUM_TOTAL_EQUIPPED_BAG_SLOTS` (5).

## Releases

- 0.2.1 released 2026-10-05: GitHub Release `v0.2.1` (pre-release, with the zip, published by
  the Release workflow from `main` at 064ace9), CurseForge upload by Tyler. Includes everything
  from 0.2, which was not released on its own. Its release text says "listed under 0.2 below",
  which only makes sense in the changelog file; the changelog wording is fixed for later
  releases.
- From 0.2.1 on, the Release workflow publishes the GitHub Release: Actions, Release, "Run
  workflow" on `main` (or a pushed `v<version>` tag). See AGENTS.md, Releases.

## 0.2 (built 2026-10-05, released as part of 0.2.1)

1. Settings popup: default auction length (2h/8h/24h, labels from the game). It is the existing
   `post_duration` setting: new items start at it, items posted before keep their last length.
2. Filter Builder facelift. Mockup: https://claude.ai/artifact/2UoFbSgPsFSgRUdPdNKZQV
   - Left "Which items" (the Blizzard part), right "Only show auctions where": a list of conditions
     in plain words, Match All / Any, a "not" switch per row, and groups that nest (Tyler wants
     Simon's full and/or/not nesting kept; groups map one to one onto it).
   - Live sync with the search bar replaces Import/Export; "Save to favorites" added.
   - "In words" line reads the search back in plain English.
   - Built as `tabs/search/filter.lua` (tree, search text, words) and `tabs/search/builder.lua`
     (rows, menus). Groups are always written with a count (`and2`), since a bare `and` takes
     everything after it. Unfinished conditions are left out of the search bar.
   - The bid variants are separate menu entries rather than the Buyout / Bid switch the mockup
     mentioned. Category names still need checking against Forever's AuctionCategories in game.
     (The `<>` in the search bar is aux's label for an empty search; not a bug by itself.)
3. Done in 0.2: Favorite with an empty search bar used to save an empty search (`<>`), once per
   click. Now it saves nothing on an empty search bar and never adds a search that is already a
   favorite (`add_favorite` and `save_favorite` in `tabs/search/saved.lua`, with tests).

## Fixed in 0.1.1

- Posting gear failed with "Internal auction error" when the starting bid equalled the buyout
  (the default). The game needs the buyout above the bid; an equal or higher bid is now left out and
  the item is posted for buyout only. Found by Tyler's brother with a Blazing Wand.

## Recent decisions

- Undercut mode starts off every time the auction house opens (Tyler: never remembered).
- Quick searches, the gold finished-search bar and the fading history arrows tested fine in game.

## Post tab: auto price (built)

When an item is loaded, once its listings are in, the price starts at the lowest listing (matched,
or one step below in undercut mode), else the usual price. A clicked row or typed price still wins.
Tyler: "99% of posts are matching the lowest price"; aux used to show the last price used.

## Post tab facelift (built, tested in game)

https://claude.ai/artifact/9gx3SMqfU46WMGbZ11iwKv : Match lowest / Undercut switch with the goblin,
a "?" for the undercut hint, bigger price box with a "% of usual" badge, a summary row (items,
total, deposit, "you get" after the 5% cut, Post button), steppers with Max, duration as 2h/8h/24h
buttons, "Hide from this list" next to the item name.

Auction house cut: 5% (Tyler's research; retail value). Keep it one constant. Deposits come from the
game's own CalculateItemDeposit / CalculateCommodityDeposit, not a formula, so a server-side
deposit change shows up by itself. Tyler's notes also claimed a flat 1 silver deposit minimum, but
his own Post tab showed a 1c deposit for Minor Mana Potion, so that claim is not trusted.

## Background opacity (built)

Gear in the top bar, 50% to 100% (Tyler lowered the floor from 70%), only backgrounds fade (gui.register_background). Light mode was
considered and turned down: game item colors are made for dark backgrounds and it doubles UI work.

## Quick searches (built, tested in game)

Clock button next to "<" on the Search tab (tabs/search/quick.lua): pinned searches (aux's
favorites) and recent searches, with icon, cheapest price seen and time. Mockup:
https://claude.ai/artifact/6eBC1KgzAvRCNfgmQDGxmB

## Ideas Tyler mentioned for later

- Expand undercut mode beyond one step (start simple, iterate).
- Remove the "/aux undercut" explanation once Forever players know the mechanic.

## CurseForge page (in progress, version 0.1, unlisted)

Draft description and project settings: `docs/curseforge.md`, modeled on shirsig's aux page.
Logo: Tyler's Recraft design ("aux" with a looped x), cleaned up (transparent corners, stray specks
removed) and recolored to the addon gold #E3A43B: `docs/images/logo.svg` and `logo.png`. Header
image `docs/images/banner.png` (that aux plus FOREVER in Cinzel). Recraft's free plan keeps
ownership of what it makes and allows no commercial use, so the logo must come from a paid plan.
License field on CurseForge: All Rights Reserved, like Simon's page, since MIT there would wrongly
suggest his code is MIT. The repository stays MIT (Tyler, 2026-10-04); it covers only the changes
made here.
