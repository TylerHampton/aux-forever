# Status

Last updated 2026-10-10: 0.6.0.1 (recipe button fix) tested by Tyler and released.

## Start here (next session, after the 0.6 release)

- **Released: 0.6** on 2026-10-10. `main` has it (PR #15, 49cc8cf; upload fix PR #16, 8952465);
  tag `v0.6`; GitHub pre-release https://github.com/TylerHampton/aux-forever/releases/tag/v0.6;
  CurseForge Beta file id 9114535, uploaded by the Release workflow (run 38019960716), the first
  automatic upload. CurseForge may hold a new file for review before players see it; check the
  project's Files page if Tyler asks. The page description (`docs/curseforge-description.md`, updated
  for 0.6) is still pasted by hand by Tyler.
- First automatic upload failed (run 38019762742): `curl -F` cut the metadata JSON at a ";" in
  the changelog. Fixed with `--form-string` in `.github/scripts/curseforge.sh`.
- Next version: not chosen. 0.6.x is fixes and small things; features go into 0.7
  (`docs/roadmap.md` rules). Tyler planned about one release a week.
- Still open from 0.6: the thin-market rule for items with a single listing (A everything, B
  stackable goods only, C wait and see, recommended); why `/aux price Trapper's Shirt` found no
  history while the Sniper had a usual of 90s (ask for the command with a Shift-clicked link);
  the CurseForge player's in-game name for FB-008 (changelog credit); Tyler's tweaks to the New
  theme; Sniper "profit at least" 1g suggested instead of his 5c (his "below vendor" deals profit
  6c to 2s).
- **0.6.0.1 build 1** (Tyler: a fix right after a release is 0.6.0.1, not 0.6.1) (2026-10-10, branch `claude/upbeat-davinci-jqwq9d`, not tried in game):
  Tyler found "Search in aux" covering Blizzard's Track Recipe checkbox. Cause, from Forever's UI
  source (Gethe/wow-ui-source, branch `forever`, `Blizzard_Professions/Camelot/
  Blizzard_ProfessionsCrafting.lua`, diff of builds 70245 and 70291): Blizzard's 2026-10-08 patch
  moved the checkbox from BOTTOMLEFT (17, 11) to BOTTOMRIGHT. Fix: `recipe_button_spot` /
  `place_button` in `tabs/search/recipe.lua` put the button left of the checkbox when the checkbox
  is anchored on the right (read from its `GetPoint`), placed again on each `Init`.
  Tested in game 2026-10-10 (`builds/0-6-1-build-1/results`: the button sits left of Track
  Recipe, the search works) and released as 0.6.0.1.
- Changelogs list every change with detail (AGENTS.md, Tyler 2026-10-10).
- Test page: https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (last used: `0-6-release`, the
  5-minute check, passed). Zips are named `auxForever-<version>-build<n>.zip`.

## Post tab top panel redesign (2026-10-10, branch `claude/upbeat-davinci-jqwq9d`)

0.6 builds 1 to 6 were merged into this branch from `claude/eager-dijkstra-drmz2k`. Next build is
build 7. Build 6 was never tested in game; Tyler wants one test page for everything (build 6's
Sniper steps plus the Post panel).

Tyler, 2026-10-10: the Post tab's top panel (item, Count, Duration, prices, Match lowest / Undercut,
the money line, Post) "feels outdated"; change how it is presented only, no functions added or
removed. His points: the price fields take far too much width for a price of at most
"9999g 99s 99c"; the vendor line under "You get" is unreadable. Scope: only that panel, not the bag
list or the auctions table. The ? button stays (move it if needed). Pay homage to TSM3 and the
original aux: aux's README says its look was "based on the retail addOn TSM" and its post price
input "inspired by the retail addOn TSM" (github.com/shirsig/aux-addon-vanilla).

Mockup: https://claude.ai/artifact/FQAKTqLUF4NQrSiAXV8ERK (today's panel and options A, B, C).
Tyler picked A (2026-10-10) with two tweaks: keep the goblin on Undercut, and a red warning
triangle when a vendor pays more ("they should not be able to miss it"). He also sent a goblin
picture found online as the model for a new goblin; it looks like a stock icon (Icons8 style) that
needs a license or a credit link, so it was not copied or traced. `textures/goblin.tga` is a new,
original drawing in the same flat style (big ears, two greens, yellow eyes, a grin with teeth),
drawn with Python/PIL at 16x and scaled to 64x64.

Build 7 (same day): option A built (`tabs/post/frame.lua`, `update_item_configuration` and
`price_note_text` in `tabs/post/core.lua`). New file `textures/warning.tga` (white triangle, black
mark, tinted with the palette red), so a **full game restart** is needed. New receipt widgets:
`cut_label`/`cut_summary`, `net_label`, `deposit_label`, `receipt_line`, `vendor_warning` (shown
or hidden only when it changes), `usual_caption`. `posting_summary` is now "Total, N items" and
`total_summary`, `net_summary`, `deposit` hold only the amounts. Two new lines on screen, approved
with the mockup: the auction house cut, and "Bid equals buyout, so it posts as buyout only" for
gear (what `item_post_prices` already did). The "On Forever the newest listing..." sentence left
the note; it stays in the ? tooltip. Layout sized for the smallest window (panel about 777 wide):
the % column ends at the middle divider there. Not tried in game; test page build id
`0-6-build-7` (11 steps: 8 Post, build 6's 3 Sniper), results in `builds/0-6-build-7/results`.

Build 7 in game (Tyler, 2026-10-10, `builds/0-6-build-7/results`): goblin and bid note pass;
gear, trade goods, vendor warning (both themes), posting and both tooltips look right in the
screenshots. Found: PER ITEM overlapped the top of the first price field; at a narrow window OF
USUAL was cut off by the divider; Linen Cloth's deposit read "-0c". Build 8 fixes all three
(`price_layout` in `tabs/post/frame.lua` and a test that fails on build 7's numbers). Sniper: no
gray items (pass). Every deal was "below vendor" with Usual "?", and Tyler wrote "I guess my data
is just gone idk". Not lost: the Post tab shows "% of usual" for the same items, so the history is
there. Inferred cause: build 6 counts only PAST days with a complete look (`cached` in
`core/history.lua`, today is not counted), and complete looks exist only since 0.5 (2026-10-08),
so no item can reach `MIN_DAYS` = 3 before 2026-10-11 at the earliest. Asked Tyler whether today's
Full scan should count. The empty-list step was written wrongly on the page (Stop then Clear shows
"Press Start..."; the gray-items message shows only while running); rewritten for build 8.

Build 9 (same day, Tyler: "build it"): asked whether the Sniper should require a Full scan before
it runs. Decided: a warning, not a lock (a lock would hide below vendor deals that need no
history, the game allows a Full scan once every 15 minutes per account, and it would not shorten
the 3 days). Built: today's complete look counts toward `MIN_DAYS` (`cached` in
`core/history.lua`); `sniper.history_notice` (pure, tested) gives the line next to "Deals": orange
"Your last Full scan was N days ago..." when `account_data.replicate_time` is more than 2 days old,
else "...after 3 days of Full scans; you have N so far" while `history_days` (the most days any
item had while the round judged it, no extra work) is below 3 after the first round, else
nothing. A Full scan button beside it clicks `aux.full_scan_button` (exported from `frame.lua`).
Redrawn only when the text changes (in `update_controls`, five times a second while the tab is
shown). Note: `replicate_time` is set when a Full scan starts, even if the server never answers.

Build 9 in game (Tyler, `builds/0-6-build-9/results`): headings clear of the fields, OF USUAL
whole at the smallest window, deposit 0c, the Sniper shows usual prices again (4s, 10s; today's
scan made 3 days) and no notice (fresh data). Tyler's notes, built in build 10: "Just put Of Usual
below the percentage" (the heading is gone; each % has "of usual" under it, `badge` in
`tabs/post/frame.lua`), and under the Sniper's running-with-no-deals message add "Sniper works best
with fresh Full scan data." Test page build id `0-6-build-10`.

Build 10 in game: "of usual" under the percentage and the Sniper's third line look right
(screenshots, `builds/0-6-build-10/results`). Tyler asked to release 0.6 to CurseForge
(2026-10-10). Done: changelog dated, CurseForge description updated (Tyler pastes it by hand),
PR https://github.com/TylerHampton/aux-forever/pull/15 opened. Pre-release check passed
(Tyler, 2026-10-10, test page `0-6-release`: open, buy, post, Auctions "Tied with 130 others",
a Sniper round, the Materials line). The changelog was rewritten in full on Tyler's request (rule
now in AGENTS.md). PR 15 merged (49cc8cf); the Release workflow published the GitHub release
v0.6 (https://github.com/TylerHampton/aux-forever/releases/tag/v0.6), but the first automatic
CurseForge upload failed: 400 "Invalid JSON" in `metadata`. Cause: `curl -F` treats ";" in the
changelog text as a field option and cut the JSON; reproduced locally. Fixed with `--form-string`
in `.github/scripts/curseforge.sh` (PR after #15), then the Release workflow was run again.

## 0.6 build 2 (2026-10-09, branch `claude/eager-dijkstra-drmz2k`)

Tyler, 2026-10-09: Webster (Christian Webster, GitHub `webguh`, a collaborator who does UI design for
work) made build 1 on the branch `design`; he is done with it. Tyler wants three ways to see the
auction house by 1.0: Blizzard's (the Blizzard UI button), the 0.5 look (Classic) and Webster's
(New). New is the default, also for players updating from 0.5. Tyler plans about one release a
week; 0.6 is not to be released yet.

Built (tests pass in both looks; checks for Tyler in `TESTING.md`, Current build):
- Look switch: Settings, Look: New or Classic, saved in `account_data.theme` (account-wide). It
  takes effect at the next login or reload; a Reload now button appears when the choice differs
  from what is on screen. Classic is the 0.5 palette and rounded corners on Webster's layout (same
  sizes and positions), flat buttons (no sheen), no top and bottom bands.
- How it works (`gui/core.lua`, "the look"): widgets are built while the files load, before the
  saved settings exist. Shapes wait until `gui.settle_theme` (called at the end of `AUX_LOADED` in
  `aux-addon.lua`) and are then built square or rounded. Every color set at load goes through
  `gui.themed`; for Classic that list is painted again, then dropped. In New nothing is painted
  twice. Color objects keep their numbers in a table that `aux.set_palette` rewrites, so colors read
  later follow the look. AGENTS.md, Design language, has the rules.
- Zebra rows (Tyler): every second row of the result tables (`auction_listing`) and the other tables
  (`listing`) has a faint light shade (`color.stripe`, white 4% in New, 3.5% in Classic as in
  0.5), under hover and selection. The Post tab's bag list has none (it had none in 0.5 either).
- New look, blacks toned back (Tyler: "it's hard to tell where the text boxes are", the Filter
  Builder; "I do like the blackness of it"): window 22 to 26, panels 12 to 19, bands 11 to 16,
  sunken fields 10 to 12 with a gray edge (64) instead of black. A test keeps the edge at least 30
  levels lighter than the panel.
- Settings, TOOLTIP LINES (this character): the seven `/aux tooltip` lines as checkboxes (FB-008,
  a CurseForge player). Not added, waiting on Tyler: action shortcuts, ignore owner, post full scan,
  post bid, clear item cache, clear post. Left out on purpose: debug, memory, price.
- Hard-coded colors moved into the palettes: scroll bar thumb, input focus edge, status bar, the
  Post tab's switch track, the buy bar's chosen quantity (now the `selected` look, redrawn only when
  the choice changes).
- Tests: `lua5.1 ../tests/load_test.lua classic` runs every test in Classic; the workflows (Tests,
  Release) run both. The harness now keeps the colors set on stub frames (`__text_color`,
  `__texture_color`, `__vertex_color`).

Build 3 (same day): the Settings menu as in the mockup Tyler approved
(https://claude.ai/artifact/21FjqFGt2vzbVo9BDG5d6j): 600 wide, two columns. Left: WINDOW
(Background, Scale, Look, and the reload row when the look changes) and POSTING (Default duration,
Bid prices Off / Item / Stack, which moves up when no reload waits). Right: TOOLTIP LINES with an
on/off switch each (`gui.switch`: square in New, rounded in Classic; color `switch_knob`). Bid
prices (`/aux post bid`) now applies at once from the menu and the chat command
(`post.apply_bid_layout`); it used to need a reload. Ignore owner, action shortcuts (Tyler: risky,
buys gear in one click) and debug stay chat only.

Build 4: "Bid prices on the Post tab" and its gray line ran under the Off / Item / Stack buttons
(Tyler's screenshot); the row is now just "Bid prices", explained in its tooltip. Tyler also saw
his bags (Blizzard's Combined Backpack) with the items in reverse order and no cleanup button. Not
from auxForever as far as the code shows: it only reads bag contents and hooks clicks
(`core/shortcut.lua`, unchanged in 0.6), and never touches bag settings or bag buttons. Cause found
the same day: Blizzard's patch of 2026-10-08 (build 70291) changed the bags, not auxForever. In
Forever's UI source (`Gethe/wow-ui-source`, branch `forever`, diff of builds 70245 and 70291,
`Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua`) the mouse and keyboard sort
`SortItemsBottomRight` (highest slot first, so the first slot showed at the top left) was replaced
by one ascending sort for everyone, while the first item is still anchored at the bottom right. So
the first slot now shows at the bottom right: the order Tyler saw as inverted. The same patch added
gamepad bag features, which likely caused it (inference). The Clean Up button
(`BagItemAutoSortButton`) is unchanged in the code and still placed at the top right next to the
search box; Tyler does not see it, which the code does not explain (open). Not auxForever's to fix:
changing Blizzard's bag frames from an addon risks breaking them further.

Build 4 in game (Tyler, 2026-10-09, test page `0-6-build-4`): open, table, buy bar, other tabs,
Classic all fine (Classic: pass; other tabs: pass; no notes on open and table, their screenshots
look right: gray edges on the Filter Builder boxes, zebra rows). Findings:
- The Buy button showed "4s 60c" without coin colors (it used the plain form). Tyler: g, s and c
  must have their coin colors everywhere, as a global rule. Fixed in build 5: buy bar buttons,
  recipe line, Sniper prices and profit; rule in AGENTS.md (Design language). Classic's primary
  and confirm looks are no longer solid filled (dark amber or green with an outline) so the coin
  colors stay readable on them.
- "It should be called theme, not look." The Settings row and its texts say Theme (build 5).
- Bid prices: Tyler found it confusing and asked whether "per stack" makes sense. It does not on
  Forever (bids only on gear, one item per auction, few sellers set one). Removed from Settings
  (build 5); `/aux post bid` stays and applies at once. FB-008.
- Sniper (open, not changed): first time it listed deals by "% of usual". Every deal in Tyler's
  screenshot is priced 1s 00c, with usuals like 90s (Trapper's Shirt) and 79s (Fading Echo). Likely
  real 1-silver listings (items on Forever are listed in whole silver, so 1s is the floor) against a
  usual price raised by high asking prices (`docs/price-data.md`, weak points: it records listings,
  not sales). His profit setting was 5c, which lets almost any 1s listing through. To check: Tyler
  runs `/aux price` on two of the deals and searches them; read the chat output before changing the
  Sniper.

Build 5: coin colors everywhere, Theme, Bid prices out of Settings (above).

Build 5 in game (Tyler, test page `0-6-build-5`): buy button, settings, Sniper colors pass; recipe
line and Classic buttons unmarked, screenshots look right (colored g/s/c; Classic Search and Buy
dark amber with an outline).

Sniper check (Tyler, 2026-10-09, `/aux price` and searches): Fading Echo (gray) is 13 listed at 1s
by 2 sellers; its usual of 79s rests on two 0.4 days that kept only the lowest asking price (no
listed count), while yesterday's complete look saw 1s. Trapper's Shirt: one listing at 1s, and
`/aux price Trapper's Shirt` said "No price history for this item yet" although the Sniper showed a
usual of 90s; unexplained (open: maybe the name lookup finds another item id; ask for the command
with a Shift-clicked link). Tyler: "gray items definitely cannot be in the sniper", "Sniper is to
make money", and junk with a single listing should stay out ("who's going to buy it?").

Build 6 (Sniper):
- Gray (poor quality) items are never deals, below vendor price included
  (`sniper.item_facts` gives them no prices).
- The 3 days of history a deal needs (`MIN_DAYS`) count only days with a complete look, i.e.
  points with a listed count (`history.value_and_complete_days`), not 0.4 lines or days that only
  saw single auctions. The usual price itself is unchanged (still from all days).
- Not done, asked Tyler: a rule against thin markets (an item with one listing). Gear is often one
  listing too, so a "too few listed" rule would also hide real gear deals; needs his call.
- Tyler's profit setting was 5c, which lets 30c deals through; suggested 1g.

Test page: build id `0-6-build-6` (3 steps, the same as `TESTING.md`), results in ArtifactData
collection `builds/0-6-build-6/results`.

Open questions for Tyler:
- The CurseForge player's in-game name (changelog credit, FB-008) and which of the not-obvious
  commands above belong in Settings.
- His tweaks to Webster's look (he will send screenshots).

## 0.6 build 1: the new look (2026-10-08, branch `design`, by Webster)

Tyler asked to "take the ui kit and screens and make the addon look like that". The design is the
Paper file "auxForever Screens", pages "UI Kit" (every color, size and control) and "New" (the seven
screens). A "New v2" page with a Barlow design was tried in an earlier session; it is no longer in
the file, so it is not what was built. TOC `forever-0.6`.

Build 1 (not tried in game yet): a restyle only, no change to searching, buying or posting.
- `color.lua`: the kit's values (gold 229,190,91; black edges; text #EBEBEB; status colors for the
  percentages and money). Key names unchanged, so every caller keeps working.
- `gui/core.lua`: square shapes (the rounded corner textures are no longer used), `add_sheen` (a
  black gradient over a raised control's fill plus a light top line; falls back to a flat shade if
  the client's `SetGradient` differs), button looks (`apply_look`; Enable and Disable redraw), tabs
  as raised buttons 1px apart, gold outline on a focused input, the status bar as a sunken track,
  `row_selection` and `row_hover` for tables.
- Tables: raised header plates, sorted column white with a gold chevron (`chevron.tga` rotated), no
  stripes (the kit says "no stripes"), selected row gold 13% with a 2px gold bar, hover white 6%.
- Window: darker bands top and bottom that fade with the Background setting; status bar 265x22 in
  the bottom band; logo "aux" white, "Forever" gold.
- Buy bar: no box of its own, quantity chips 64px (80 for the stack), Buy 160px with the primary
  look, Confirm green. The kit's 80px chips and 190px Buy do not fit the 1000px minimum window
  next to the Quantity box, so they are a little narrower.
- Not matched: the font (Forever loads no addon fonts; sizes stay as they were, the game font
  needs them), the layouts of each screen (the kit screens mostly follow the existing layouts;
  differences such as the Fast/Full sunken track are approximated with two buttons).
- Edges are 1-unit lines; at some Scale settings they may render uneven. If so, set their size with
  `PixelUtil` in `create_shape` (`gui/core.lua`).
- The test page (artifact LUCZVgJV27irizAyKHTjhJ) could not be read from this session ("not
  found"); build 1's steps are only in `TESTING.md`.
- Tests and syntax check pass under Lua 5.1.5 (built from lua.org source on Tyler's collaborator's
  Mac; Homebrew has no lua@5.1).
- Open question for Tyler: zebra rows. He asked for a zebra version of an earlier design; the kit
  says no stripes, so build 1 has none. Easy to add back. (Answered 2026-10-09: add them back in
  dark gray; done in build 2.)

## Start here (for the next session: 0.5.1 or 0.6)

- **Released: 0.5** on 2026-10-08. `main` is at its merge (PR #11, e27b711); tag `v0.5`; GitHub
  pre-release https://github.com/TylerHampton/aux-forever/releases/tag/v0.5. Tyler uploaded 0.5 to
  CurseForge by hand.
- **CurseForge uploads are automatic from the next release on:** the Release workflow uploads the
  zip as a Beta file with the changelog (project 1727417, secret `CF_API_KEY` set by Tyler on
  2026-10-08). The CurseForge check workflow confirmed the token works and that CurseForge lists
  game version 1.60.1 under "WoW Forever" (id 17053). Not yet used for a real upload; watch the
  first one. The page description is still pasted by hand when it changes.
- **Which version next:** Tyler has not chosen. Rules (`docs/roadmap.md`): 0.5.x is bug fixes,
  speed and small things only; new features go into 0.6. If players report bugs in 0.5, they go
  into 0.5.1 (or a hotfix if bad: money spent wrongly, repeated errors, a broken tab, lost data).
- **Candidates, none decided** (details in `docs/roadmap.md`, "After 0.5"):
  1. Sniper rework (0.6): the hold on a selected deal, clear feedback on each buy in a fast market.
  2. Auctions tab: show the starting bid of your own auctions, if the game gives it (unverified).
  3. The redesign with Tyler's designer friend (0.6 or later; TSM and the original aux direction,
     AGENTS.md Design language). Designs are not in the repository yet.
  4. Small loose ends from 0.5 (0.5.1 material), listed under "Open after 0.5" below.
- **Player feedback:** `docs/feedback.md`. FB-001, FB-002, FB-003, FB-006, FB-007 are done in 0.5;
  FB-004 rejected (direction); FB-005 praise; FB-009 (Classic stacks, Maggew) wont-fix. New entries start
  at FB-010 and are recorded by a separate feedback session, not by the session that builds.
- **Audience (Tyler, 2026-10-10):** auxForever is for intermediate players who know Forever's modern
  auction house. Requests for things that auction house does not have are answered, not built
  (AGENTS.md, the exception after "a player's problem is the addon's problem").
- **How Tyler tests** (worked well all through 0.5): each build gets a zip (sent with the file tool)
  and steps on the test page https://claude.ai/artifact/LUCZVgJV27irizAyKHTjhJ (republish
  `index.html` with a new `BUILD` id and steps; Tyler marks Pass/Fail with notes and screenshots;
  read them with ArtifactData, collection `builds/<build id>/results`, and download screenshots with
  Artifact read, `path` = the asset id, one at a time). Keep `TESTING.md` "Current build" in step
  with the page. The pre-release check is six steps, about 5 minutes (Tyler's limit).
- **Things that confused testing before** (check these first when a screenshot looks wrong):
  Tyler screenshots with Win+Shift+S, which holds Shift (tooltip prices then show the whole stack,
  "for 3") and hides the item on the mouse pointer.

## Open after 0.5 (loose ends, none urgent)

- Damaged gear and posting (FB-003): never tried in game. The Post tab says "must be repaired"
  if aux finds damaged gear it cannot post; whether Forever lists damaged gear at all is unknown.
- Converted 0.4.1 history: until about two weeks of 0.5 days are recorded, "usually ..." lines
  and the Sniper's percentages still lean on 0.4.1's daily lows, some of them single cheap
  auctions (Linen Cloth "usually 8c" while it sold at 23c to 33c). Expected to wash out; check
  again after a couple of weeks of play.
- The "usually" threshold (30%, `USUALLY_SHARE`) and the market price share (5%,
  `MARKET_SHARE`) in `core/history.lua` are first settings, checked on a few items only.
- The tooltip "Today" line (setting `/aux tooltip daily`, off for Tyler) still shows today's
  lowest and its percentage of the usual price; untouched in 0.5.
- `docs/curseforge.md` and `-description.md` were updated for 0.5; check the Usage section again
  whenever clicks change.

## 0.5 build log (2026-10-08, branch `claude/youthful-curie-ghbvlt`, released as PR #11)

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
right-click (the bug). Tyler: he was holding the item (Win+Shift+S hid the pointer in the
screenshot); the fix works.

The 15-minute pre-release quick run was too long for Tyler; replaced by a 5-minute, six-step check
(`TESTING.md`, Before every release; test page collection `builds/0-5-release/results`).

Release check on build 4 (Tyler, 2026-10-08, `builds/0-5-release/results`): all six steps pass
(open, buy one linen cloth, post, Auctions tab, a Sniper round, the Materials line on Herb Baked
Egg).

Release (Tyler, 2026-10-08: "Yes"): he also asked to stress Full scans. Added: a second login line
saying when the last Full scan was (`full_scan_reminder` in `aux-addon.lua`), a "Get the most out
of it: run a Full scan" section and a corrected "Prices" section on the CurseForge page
(`docs/curseforge.md`, `docs/curseforge-description.md`). Changelog dated, with Darkhorse and
Garsterson credited on each change from their feedback and named at the top. Then the pull request
into `main`, merged, and the Release workflow (`v0.5`).
- The Sniper and Auctions tab notes (`docs/roadmap.md`, 0.5): Claude recommended leaving them for
  after 0.5; Tyler has not decided.
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

## Earlier notes (0.4.1 and before)

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
