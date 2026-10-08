# Status

Last updated 2026-10-08 (0.5 build session).

## 0.5: where it stands (2026-10-08, build session on `claude/youthful-curie-ghbvlt`)

Branch `claude/youthful-curie-ghbvlt` from `main` (dd040f9), TOC `forever-0.5`. Test build 2 is out
(see Build 1 results below). Test build 1 was
(zip sent to Tyler; test page https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ, results in
ArtifactData collection `builds/0-5-dev1/results`). No new files, so `/reload` is enough. All six
handoff items are built, each with tests that fail without the change; none is tried in game yet.

1. Price data (e1c852a): market price per day from complete views, usual price weighted to recent
   days (half-life 7 days, 14 days kept), "seen N days ago" in tooltips, history version 3 with
   lazy conversion of version 2. Details: `docs/price-data.md`, start of "Plan for 0.5".
2. FB-003 (7a187c7): every way a post ends says what happened (Post tab, left column under
   Duration, and chat on failure); a faded Post button says why. PostItem's return value is read
   as "needs confirmation" (as aux's code always did), not as a failure: unverified against the
   API docs, inferred from the code.
3. FB-006 (31ac02c): `gui/listing.lua` lays out again on show and on content size change; the last
   column is anchored to the right edge.
4. Click standard and FB-002 (140996a): Tyler approved the standard on 2026-10-08. Blizzard's
   Forever bag code sends a right-click to `AuctionHouseFrame:SetPostItem`; aux follows it.
   Details and what was not changed: `docs/clicks.md`, "Built in 0.5".
5. FB-001 (6f77958): option B of the mockup (Tyler: "Everything looks good").
6. FB-007 (5a935e1): the cost line under the reagent list; its position comes from Blizzard's
   source, not seen in game yet.

Build 1 results (Tyler, 2026-10-08, test page collection `builds/0-5-dev1/results`): 14 pass, 5
fail, 3 skipped, 1 unmarked (Full scan memory: 17.8 MB, 9.9 MB after a cleanup, 3,457 items of
history; fine). Failures and what was done (build 2, `builds/0-5-dev2/results`):
- Right-click a Post price row: BugSack "attempt to index global 'selected_item'" (tabs/post/
  frame.lua:87). Leaving the Post tab clears selected_item before its name was read. Fixed; the
  build 1 test missed it because it used tab 4 (Auctions) for Post (Post is tab 3).
- Click hints: one wrapped gray paragraph, hard to read (Saved Searches). Now one line per click,
  click left, action right (`gui.add_click_hint`). aux.split only handles one-character separators.
- Quantity box: Tyler: the cursor mark "looks like its a bug". Removed.
- Price tooltips "not even close" (Tel'Abim Banana: Value 2s 61c, listings 38c to 1s). Analysis:
  the search table at the same moment showed 44% of usual at 38c, so the usual price was 87c; the
  tooltip's 2s 61c is exactly 3 x 87c, the price of his stack of 3 (Shift multiplies by the stack;
  Windows' screenshot keys Win+Shift+S hold Shift). So two things: the stack total was not labeled
  (fixed: "for 3"), and the usual price on day one of 0.5 rests only on the daily lows recorded by
  0.4.1 (Simon's method), because today's market price only counts after midnight, as in Simon's
  aux. Proposed to Tyler: count today's market price in the usual price as the newest day. Not
  built; waiting for his answer. `/aux price <item>` added to see what was recorded.
- Post locked test step: Tyler did not understand it; reworded (optional).
- Not a failure but found in a screenshot: the recipe cost tooltip's Total was red (colors passed
  as a color's four values). Fixed.

Build 2 results (Tyler, 2026-10-08, `builds/0-5-dev2/results`): Post right-click, hints, quantity
box pass; stack label works ("Value: 2s 61c for 3" with Shift, 87c without). `/aux price` on the
banana confirmed the analysis: usual 87c from 2 past days, both 0.4.1 daily lows (87c two days
ago, 11c three days ago); today lowest 38c, market 39c (cheapest fifth of 82 listed). Light Feather:
usual 4c (0.4.1 lows), lowest today 7c with 1,861 listed. Fixed after build 2 (5338888, not yet in a
zip): the cost tooltip's prices were gold (the game's default right color), the Post locked message
was cut off.

Price question (Tyler, 2026-10-08): players do a full scan, post and leave within minutes, and need
to trust the tooltip away from the auction house; heavy averaging that lags the market loses that.
Claude's proposal sent the same day (waiting for Tyler): tooltips and the recipe cost show the
latest market price (the most recent complete look, with its age), and the multi-day usual price
stays for finding deals (Sniper, the search % column, percentage filters), shown in the tooltip only
when it differs a lot from the latest. Not built.

Tyler approved the proposal ("Yes build it, the text examples are enough"). Built in build 3:
`history.latest`, tooltips and the recipe cost use it, "usually ..." at a 30% gap; details in
`docs/price-data.md`. Test page collection `builds/0-5-dev3/results`.

Build 3 results (Tyler, 2026-10-08, `builds/0-5-dev3/results`): banana tooltip 38c each (pass);
Full scan alone recorded Rough Dynamite at 30c, its lowest listing, so Full scan prices look right;
Linen Cloth 32c with 296 listed at 23c ("The full scan NOR the search fixed the tooltip??"): the
average of the cheapest 20% is too deep for big markets. Also: hovering the faded Post button did
nothing; the Full scan looks stuck for 7 to 8 seconds before its bar moves (Tyler: help impatient
players see a scan is running); a right-clicked bag item stayed locked (Blizzard's hidden Sell tab
calls C_Item.LockItem on it, source: Blizzard_AuctionHouseSharedTemplates.lua, forever branch), so
it could not be picked up and aux posted from another stack. All four fixed in build 4
(`builds/0-5-dev4/results`): market price = middle of the cheapest 5% of units, the right-clicked
item is cleared from Blizzard's Sell tab (ClearPostItem), a Post button tooltip, status bar text
during a Full scan.

Build 4 results (Tyler, 2026-10-08, `builds/0-5-dev4/results`): Full scan status text passes;
Linen Cloth Value 33c with 712 listed at 33c and 2 at 3c (the outliers were ignored: right); the
faded Post button's tooltip shows the reason. The right-click unlock step has only a screenshot of
"Not posted: the item is on your mouse pointer..." on Ritual Bands, no note: either the item was
still on the pointer when Post was clicked (expected message) or it was still locked after the
right-click (the bug). Asked Tyler which.

Open:
- Tyler's answer on the right-click unlock step.
- Then: the release quick run (`TESTING.md`, Before every release), and whether the Sniper and
  Auctions tab notes (`docs/roadmap.md`, 0.5) go into 0.5 or wait.
- Asked Tyler: whether to do the Sniper and Auctions tab notes in `docs/roadmap.md` (0.5) tonight
  (he asked what they were; explained 2026-10-08, waiting); whether today's market price should
  count in the usual price. FB-002's suspected bug: he does not remember. Damaged gear (FB-003):
  skipped in build 1.
- Mockup page for this build's visual items: https://claude.ai/artifact/SX8EwZHbgqS94ZBGhUtJCg

## 0.5: start here (handoff written 2026-10-08 by the feedback-logging session; done, see above)

Tyler is opening a new chat on 2026-10-08 to build 0.5 the same night. Everything it needs is in
the repository; this list is the order of work. Read `AGENTS.md` first, then this, then the files
named.

- **Branch:** a new branch from the latest `main`. The feedback log and these notes were merged
  into `main` from `claude/exciting-tesla-3jksts` (if that pull request is still open, merge it or
  read from that branch). TOC version `forever-0.5`. Changelog heading `## 0.5 (date)` when
  released.
- **No 0.4.2** (Tyler): every small fix found since 0.4.1 goes into 0.5.
- **Scope, in this order** (each with a test that fails without it; AGENTS.md, Tests):
  1. **Better price data:** `docs/price-data.md`, "Plan for 0.5" (what changes, what stays, cost,
     risks, tests). Foundation for 6. No layout change except the age next to Value in tooltips.
  2. **FB-003, silent failed post:** every way `post_auction` (`tabs/post/core.lua`) can stop
     without a word gets a message saying why. Details in `docs/feedback.md`, FB-003. Ask Tyler for
     the damaged-gear check listed there if it helps; do not wait for it.
  3. **FB-006, Recent Searches header sticks out** after resizing and a scale change
     (`gui/listing.lua` fixed column widths). Screenshot and steps in the entry.
  4. **Clicks made consistent, including FB-002** (right-click a bag item loads it into the Post
     tab). Tyler asked on 2026-10-08 for clicks to be predictable across every tab. The full click
     map, the findings and the proposed standard are in `docs/clicks.md`; show Tyler its standard
     table (and the hover hint mockup) for an OK before changing clicks. Check Blizzard's Forever
     bag click code first (FB-002 explains why: aux keeps Blizzard's window invisible but open, and
     the click may go there). Ask Tyler what bug he suspected there (FB-002, Ask Tyler).
  5. **FB-001, the buy bar's quantity box** should look like a place to type. Visual: mockup first.
  6. **FB-007, crafting cost in the profession window**, anywhere in the world, at usual prices;
     design decided in the entry (one line, "+" when a material has no price, tooltip with
     details). Visual: mockup first.
  7. Only if Tyler wants them tonight (ask): the 0.5 notes in `docs/roadmap.md` (Sniper hold and
     buy feedback, Auctions tab starting bid).
- **Not in 0.5 tonight:** the redesign with Tyler's designer friend (direction: TSM and the
  original aux, AGENTS.md Design language); the designs are not in the repository yet.
- **Mockups:** show the FB-001 and FB-007 mockups and the click standard (`docs/clicks.md`) together early, so Tyler can approve them while
  steps 1 to 4 are built.
- **Credit** (Tyler's rule, `docs/feedback.md` Credit): changelog lines for FB-001, FB-002, FB-003
  end "(suggested by Darkhorse)" or "(reported by Darkhorse)"; FB-006 "(reported by
  Garsterson)", FB-007 "(suggested by Garsterson)". Not FB-004 (rejected) or FB-005 (praise).
- **When an entry is done:** set its status in `docs/feedback.md` (index and entry), add its
  in-game check to `TESTING.md` and the build's test page, give Tyler the zip and say whether
  `/reload` is enough or a full restart is needed (new files need a restart).

## Start here (where things stand right now)

- Released: 0.4.1 (2026-10-06) is the latest; `main` is at its merge (#8, ea73c6a).
- **Player feedback log (started 2026-10-08):** `docs/feedback.md`. Tyler passes on what players
  say; one Claude session records it there (no fixes in that session) and a separate session or
  agent fixes from it. Check its index for entries with status `new` or `confirmed` before
  planning 0.4.x or 0.5. First batch (2026-10-08): FB-001 to FB-005 from Darkhorse (buy quantity
  box, right-click from bags to Post, a silent failed post, the UI overall, praise for the Post
  tab's bag list). FB-004's direction (closer to Blizzard's auction house) was rejected by Tyler:
  the redesign follows TSM and the original aux. Players are not asked follow-up questions; open
  questions for Tyler are under "Ask Tyler" in each entry.
  Second batch (2026-10-08): FB-006 and FB-007 from Garsterson (Tyler's brother): the Recent
  Searches header sticks out of the window after resizing and a scale change; crafting cost in the
  profession window anywhere in the world (Tyler: cost only, no profit).
  Decisions the same day: no 0.4.2, so FB-006 and the other small fixes go into 0.5; FB-007 is a
  line in the recipe's detail panel at usual prices, with a "+" when a material has no price
  (design in the entry). Tyler asked how aux stores prices: `docs/price-data.md` (new) explains it
  and lists its weak points; Tyler then decided to improve it in 0.5 (plan in that file).
- Versioning decision (2026-10-05): fixes to an unreleased version go into that version, so the
  build 2 and 3 fixes are part of 0.4, not 0.4.1. 0.4.1 is for fixes after 0.4 is released.
- **0.4.1 release (2026-10-06):** build 6 passed except one case, fixed before release: a Live
  round during a trade good's price quote ended the purchase with "Internal auction error"; Live
  rounds now wait while the buy bar is buying (`update_live`). That fix was not tried in game
  before the release; Tyler checks it on the release zip before uploading to CurseForge. Next:
  0.5 planning (docs/roadmap.md, 0.5 notes: Sniper rework, fast-market buy feedback).
- Before the release, **0.4.1** was on branch `claude/modest-volta-4mgmsb` (restarted from `main` after the 0.4
  merge), TOC `forever-0.4.1`, test build 3 out. Plan in `docs/roadmap.md` (0.4.1): performance first, then
  common-sense UX (list to agree with Tyler, mockups for visual changes). Done so far: login item
  walk (`fetch_item_data`) skips non-items and pauses every 500 numbers, `core/crafting.lua`
  removed, the per-frame audit (Saved Searches, Bids tab, quick menu rows fixed), tests run once
  per change on GitHub. In-game checks: `TESTING.md` (Current build) and the test page
  https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ, where Tyler marks each step; read the results
  with ArtifactData, collection `builds/0-4-1-dev<N>/results` (one document per step id; notes
  and screenshot asset ids, which `Artifact` read with `path` = the id downloads).
- Build 5 results (Tyler, 2026-10-06): Sniper gear buys work ("way better"), hold and pick pass,
  empty search, quick run search/buy, Live, Post, Auctions (cancel and undercut too) pass; memory
  11.9 MB after a cleanup at the end. Failed: a saved or recipe search while Live was on (refused
  as a multi-query, Live kept updating the old search; fixed in build 6: any new search ends
  Live). Trade good Sniper buys hit "Internal auction error" 4 of 5 times on deals found minutes
  earlier; build 6 reads a trade good deal again when selected, like gear. Tyler's Sniper design
  notes are in docs/roadmap.md (0.5).
- Build 4 results (Tyler, 2026-10-05; the game server was being restarted and players reported
  the AH broken meanwhile): memory settled (after a cleanup 17.3 MB at Sniper round 14, 17.5 MB at
  round 46, 18.5 MB after a full scan with the bag-only fix; the rise from 8.1 MB at login is
  one-time: an empty search's 2,083 rows, Sniper notes on 7,763 items, 2,177 cached usual
  prices). Sniper gear buys did nothing while trade goods bought fine and Search gear buys work:
  likely the purchase needs the auction in the latest search of its item, and rounds search other
  items. Build 5: a selected gear deal is read again (one request) before Buy, rounds hold while a
  deal is selected (click again to let go), the purchase stays on the click (PlaceBid from code
  may need a click; unverified). The selection moved because auction_listing reselected by row
  position after each refresh (Simon's code); it now keeps the same record. The Sniper table
  freezes while the mouse is over it. Empty searches do nothing. Tyler skipped the quick run;
  it is still needed before release.
- Build 2 results (Tyler, 2026-10-05): a full scan left 42.3 MB after a cleanup (Post tab kept
  every item's listings; fixed in build 3, only bag items now). Sniper "after a cleanup" grew
  12.9 MB (round 29) to 19.1 MB (round 41) with only the Sniper running and a deal selected; the
  harness does not repeat it (flat over 80 rounds with deals, selection and moving prices), so
  build 3 adds `/aux memory detail` (entry counts per store) and asks for round 10 and 40 with
  nothing selected. Sniper buy bar offered non-deal units of a trade good (fixed: deal tiers
  filtered by the rule) and the buy did not go through (unknown; rounds now pause while the buy
  bar is busy; the Confirm click may have been missed). Prices: Tyler wants copper kept in
  tables for alignment (done: full parts when any price in the table has copper). Auction Bid
  showed the buyout on buyout-only auctions (now "---"). Resize corner jumps on a single click
  (Tyler made sure: single clicks, and once it starts each click jumps again; scale 100%): not
  reproduced; my double-click guess was wrong. Build 4 drops the game's StartSizing for aux's own
  sizing during the drag (`frame.lua`, grip OnUpdate only while dragging), so a click without
  movement changes nothing; anchor_top_left no longer re-anchors when already in place. Posting bid = buyout posts buyout only, as
  designed; the test step had asked for a lower bid.
- 0.4 release (2026-10-05): Tyler approved it after build 5, with one last change: the recipe
  cost line moved from the line next to the sub tabs (crowded, cut off) to the bottom bar right of
  Clear, in shorter words (`recipe_label` in `tabs/search/frame.lua`, set in
  `update_results_summary`). That last change was not tried in game before the release; Tyler
  checks the release zip before uploading to CurseForge. Released through a pull request into
  `main` and the Release workflow (`v0.4`). Open after 0.4: `/aux memory` at round 10 and round 40
  of the Sniper (should match after a cleanup); Simon's background item cache thread
  (`fetch_item_data` in `core/cache.lua`, walks item IDs 1 to 30000 at login) is a performance
  item to review for 0.4.1.
- Before the release, **0.4** was on branch `claude/modest-volta-4mgmsb` (TOC `forever-0.4`), pushed. Tyler
  tested the first 0.4 build: recipe search works. His findings, fixed in the second build:
  saved recipe searches showed raw search text (now "Recipe  Name  (N materials)", the recipe is
  kept on the saved entry); the Sniper played its sound once per deal (about 40 times in a 1c
  first round) and showed nothing until the round ended (now one sound per 10s, deals and
  "checking N possible deals" during the round); `/aux debug` printed timing every Sniper round
  (scans with `quiet = true` print nothing); memory read 8.6 MB at first and 26.0 MB after Sniper
  rounds. Memory: rounds no longer unpack history or build tables per item (`history.value_and_days`,
  `GetItemInfo` directly). What remains per round is the game's own item list (about 7,700 entries,
  each a table with an item key table), which becomes garbage; an estimate, not measured, is a few
  MB per round. `/aux memory` now also reports the size after a full cleanup to tell the two apart.
  Build 2 result (Tyler, 2026-10-05): `/aux memory` read 58.2 MB, 10.6 MB after a cleanup, and
  later 18.9 MB, 10.7 MB after a cleanup, over 13+ Sniper rounds. So aux keeps about 10.6 MB and it
  does not grow; the rest is garbage from the rounds that the game frees. The pause between
  Sniper rounds went from 1s to 2.5s (Tyler's choice, a compromise) for less garbage and fewer
  requests. Also in build 2, every Sniper deal vanished around round 6 and came
  back later: build 2 read the vendor price only from GetItemInfo, which returns nothing while the
  game reloads an item, and a deal without facts was hidden. Fixed in build 3: deals keep the facts
  they were found with, and the vendor price falls back to aux's saved item list. Likely cause, not
  proven in game.
  Build 4 result (Tyler): login 8.1 MB (8.1 after a cleanup); after 23 Sniper rounds 49.0 MB, 16.4
  after a cleanup. Measured in the harness with 7,700 fake items: the Sniper keeps about 1.1 MB
  once (its notes on each item: `known`, `seen_items`), then nothing more through round 60 (test
  "sniper: rounds keep no memory"). Other things that grow once and stop: aux's saved item list
  (`account_data.items`, Simon's cache, filled from every item the game loads, so the Sniper fills
  it fast), the history cache, search results kept for the history arrows. Not yet proven which
  part makes up the rest of the 8 MB; to tell: `/aux memory` at round 10 and round 40, the "after a
  cleanup" number should be the same. Tyler noticed a new Sniper find right after running
  `/aux memory`: aux has no weak tables, so a cleanup cannot change what it knows; finds came every
  few minutes in that session, so it is likely chance; watch for it repeating.
  Design note from Tyler (not a demand): the line next to the sub tabs is getting crowded (the
  recipe line gets cut off: "searched ju..."), while the bar at the bottom (next to Clear) and the
  search bar have room. Consider moving the recipe line or the summary down there; mockup first.
  Also fixed in build 5: the recipe line names a material without a price instead of "?".
  Next steps:
  1. Tyler tests the fifth build (`docs/testing-history.md` section 16, Recipe search, Sniper fixes,
     Performance) and sends both `/aux memory` lines at login and after 20+ Sniper rounds. If the
     "after a cleanup" number keeps climbing, something is kept that should not be: look for it.
  2. Fix whatever his test turns up (each bug: fix plus a test that fails without it).
  3. When he says 0.4 is ready: changelog heading `## 0.4 (date)`, status, curseforge text
     (features: Auctions tab undercut check, recipe search, Post next item), then a pull request
     into `main`, wait for CI, merge, run the Release workflow, check the release zip, send it, and
     give Tyler the CurseForge upload steps and changelog text (as done for 0.3 and 0.3.1).
- 0.4 contents: Auctions tab (undercut / tied / lowest / sold, Cancel undercut one per click, check
  on tab open, reused for 2 minutes unless an auction is unchecked), Post tab selects the next item
  after posting everything of one, recipe search (`tabs/search/recipe.lua`: "Search in aux" button
  on the profession window while aux is open, Alt-click a recipe; Shift-click is Blizzard's track
  recipe, so not used), performance fixes (tooltip scan once per item, Post tab validation and buy
  bar throttled, history unpacked only for new daily lows).
- Mockups (private to Tyler): 0.3 https://claude.ai/artifact/Q5C3ScRtCLV9ohYCcuyuRA, 0.4
  https://claude.ai/artifact/A6L3eNDURLpJUMBd1aVucY (Auctions tab approved; "Recipe" board is the
  built design; "Recipes" sub tab board was rejected).
- Tyler's standing priorities: performance and compute cost first (AGENTS.md, Performance); patch
  versions (0.x.y) are fixes, speed and small things only; mockup before any visual change; he
  trusts Claude's engineering judgment but wants honesty, not agreement.
- Testers: two guild AH power users (Darkhorse, Hotpocket) asked for recipe search; their RAM
  concern is why `/aux memory` exists.
- Release mechanics that bit before: the session's git proxy refuses tag pushes, so releases go
  through the Release workflow (`run_workflow` on `main`); after a merge, restart the branch from
  `main` before new work; WoW chat lines are limited to 255 characters (keep /run test lines short).

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
- 0.3 first build (TOC `forever-0.3.0-dev`, later `forever-0.3`, branch `claude/modest-volta-4mgmsb`, sent as a zip):
  fast mode on Search (Fast / Full switch, click a row to read its auctions), Live mode with a
  visible countdown and paused state, and the Sniper tab. Decisions and known limits:
  `docs/roadmap.md`, "Built". In-game checks: `docs/testing-history.md` section 15. Not tested in game yet.
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
- Sniper test by Tyler (2026-10-05): round 39, 7256 items in 8.4s each round, matching the
  `/aux debug list` measurement. Two below-vendor deals were found and went gone (sold or relisted;
  not checked). Changes after it: deals that fail the current rule are hidden even when gone (a 1c
  find from a loose setting stayed after going back to 5s), the count reads "N to buy, N gone"
  instead of "0 found" over gone rows, and Usual is blank unless the item has 3 days of history
  (it showed the vendor price before, which looked like the usual price). Buying from the Sniper
  is not confirmed in game yet.

## 0.4 (in progress)

- Built: Auctions tab (undercut check, Cancel undercut), Post tab next item, recipe search (button
  on the profession window and Alt-click), performance fixes (tooltip scan once per item, Post tab
  and buy bar throttled, history unpacked only for new daily lows). TOC `forever-0.4`.
- Facts from Tyler's in-game check (2026-10-05): the recipe for Simple Kilt is 12046 and its link
  shows the materials. The second check failed only because the /run line was over WoW's
  255-character chat limit; Blizzard's own profession window uses `GetRecipeSchematic` to show
  materials, so the call works on Forever.
- `core/crafting.lua` hooked Classic's profession frames, which Forever does not have. Removed in
  0.4.1 with its `/aux crafting cost` setting.
- Not tested in game yet: everything in `docs/testing-history.md` section 16.

## 0.3.1 (released 2026-10-05)

- Performance pass after Tyler stressed compute cost (2026-10-05). Found and fixed: `control.lua`
  compared every event listener with every other one on every frame, all game long (from Classic
  aux); the Auctions and Bids tabs ran endless per-frame threads to rebuild their lists every
  second; the Full scan button restyled itself every frame; the Live button and Sniper status
  rebuilt their text every frame. Rules for all agents: AGENTS.md, Performance. Tests: `per-frame
  work`. The buy bar was throttled to ten times a second in 0.4 (and does nothing with no row
  selected).
- `/aux memory` (memory use and number of items in price history), for questions about RAM.
- 0.4 Auctions tab mockup approved by Tyler (https://claude.ai/artifact/A6L3eNDURLpJUMBd1aVucY).
  Recipe search added to 0.4 (`docs/roadmap.md`). Not built yet.

## Releases

- 0.2.1 released 2026-10-05: GitHub Release `v0.2.1` (pre-release, with the zip, published by
  the Release workflow from `main` at 064ace9), CurseForge upload by Tyler. Includes everything
  from 0.2, which was not released on its own. Its release text says "listed under 0.2 below",
  which only makes sense in the changelog file; the changelog wording is fixed for later
  releases.
- 0.3 approved for release by Tyler on 2026-10-05 after testing fast mode, Live and the Sniper
  (round times 8.4s). Released through a pull request into `main` and the Release workflow
  (GitHub Release `v0.3`, pre-release). CurseForge upload by Tyler. Not confirmed in game at
  release: buying from the Sniper, posting from the reagent bag, whether fast mode rows show
  suffixes ("of the Owl"); these stay in `docs/testing-history.md` section 15.
- 0.3.1 approved by Tyler on 2026-10-05 ("stable and ready to release"): performance fixes and
  `/aux memory`. GitHub Release `v0.3.1` by the Release workflow; CurseForge upload by Tyler.
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
