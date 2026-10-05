# auxForever: guide for AI coding agents

This file is for any AI agent working on this repository (Claude Code, Gemini CLI, Jules, others).
`CLAUDE.md` and `GEMINI.md` only point here. Read this file, then `docs/status.md` (where things
stand), before changing anything.

## The project

auxForever is a port of **aux**, the auction house addon by shirsig (Simon), to **World of
Warcraft: Forever**, plus a visual redesign and modern improvements. The credit line, used in the
addon and on every page, is: "aux by shirsig, re-imagined by a fan". Simon gave written
permission by email (quoted in `README.md`); he is not involved in this version.

- Forever runs the modern client (Interface 16001, game version 1.60.1) with the modern auction
  house API (`C_AuctionHouse`). aux was written for Classic Era's old auction house, so search,
  buying and posting were rewritten. Facts about Forever's auction house, with sources:
  `docs/forever-auction-house.md`. Read it before touching scanning, buying or posting.
- The addon is the `auxForever/` folder. Players copy it into
  `World of Warcraft\_classic_beta_\Interface\AddOns`.
- Released as a beta on CurseForge (unlisted). Page text and settings: `docs/curseforge.md`,
  paste-ready copy `docs/curseforge-description.md`. Version is in `auxForever/auxForever.toc`
  (`## Version: forever-x.y.z`).

## The owner: how to work with Tyler

Tyler owns the project and tests every change in the game. He is not a programmer.

- Explain in plain words. Say what to click and where. No unexplained jargon.
- Lead with the answer or recommendation, details after.
- After every change, give him a ready-to-install zip (see Packaging) and say whether `/reload` is
  enough or a **full game restart** is needed (any new file: Lua, texture, font).
- Ask before large or hard-to-redo work. For visual changes, show a mockup first and build only
  once he approves it (this was done for the Post tab, quick searches and the Filter Builder).
- Do not flatter. If an idea is weak, say so and why; push back on weak trade-offs. Say what you
  know, what you infer and what you are unsure of. Never invent facts; cite sources.
- No em dashes and no emojis in anything published: README, docs, commit messages, in-game text.
- Avoid filler words such as delve, leverage, robust, seamless, crucial, notably.
- He tests in game and reports with screenshots and BugSack error text. Each bug report becomes a
  fix plus a test that fails without the fix.

## Workflow

### Branches and coordination (several agents share this repo)

- Never push to `main` or merge a pull request unless Tyler asks.
- Work on a branch. Before starting, pull the latest of that branch. When done, commit, push, and
  update `docs/status.md` (what changed, what still needs testing in game). The next agent, which
  may be a different AI, relies on that file and on the git log.
- Only one agent works on a branch at a time. If two run at once, use two branches.
- Commit messages: a short summary line, then plain sentences on what and why. No em dashes.

### Tests (required before every push)

The test harness stubs the WoW API in plain Lua 5.1 and loads every file in TOC order.

```
cd auxForever
lua5.1 ../tests/load_test.lua      # must end with: done, errors: 0
for f in $(find . -name '*.lua'); do luac5.1 -p "$f"; done   # syntax check
```

- Setup on Ubuntu/Debian (also a Jules setup script): `sudo apt-get update && sudo apt-get install -y lua5.1 zip`
- GitHub Actions runs the same checks on every push and pull request (`.github/workflows/test.yml`)
  and attaches the installable addon to the run. If Lua is not installed locally, push and read the
  result there.
- Add a test for each bug fixed and each feature. Check that it fails without the change
  (break the code on purpose, run, restore).
- Harness limits: `GetChecked`, `HasFocus` and `IsMouseOver` always return false; `SetShown` does
  nothing; `Get*` methods return fresh stub frames; `SetText` does not fire `OnTextChanged`, so call
  an edit box's `change(self, true)` yourself. Reach a module's internals in a test with
  `loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)`.
- Tests cannot show layout or how the game reacts. Add the in-game checks for each change to
  `TESTING.md` (numbered sections) so Tyler can verify.

### Releases

Only when Tyler says a version is ready: merge its pull request into `main`, then run the Release
workflow (`.github/workflows/release.yml`) on `main`: Actions tab, Release, "Run workflow" (or, for
an agent, trigger the workflow through the GitHub API; Claude's session cannot push tags). It reads
the version from the TOC, runs the tests, builds `auxForever-<version>.zip`, creates the tag
`v<version>` and publishes a GitHub Release (pre-release while in beta) with the version's notes
from `docs/changelog.md`. Pushing a matching `v<version>` tag does the same. CurseForge is uploaded
by hand by Tyler (see `docs/curseforge.md`).

### Packaging

The zip must contain the `auxForever` folder at its top level:
`zip -qr auxForever.zip auxForever -x '*.git*'` (Windows PowerShell:
`Compress-Archive -Path auxForever -DestinationPath auxForever.zip -Force`). Each GitHub Actions run
also offers it as a download ("auxForever" under Artifacts).

## Code map

Load order is the TOC (`auxForever/auxForever.toc`).

- `libs/package.lua`: the module system (see gotchas). `compat.lua`: old Classic function names
  mapped to modern ones.
- `aux-addon.lua`: events, saved variables (`account_data` defaults), tab switching.
- `frame.lua`: the main window: top bar (logo, tabs, settings gear with opacity and auction
  length, Full scan, Blizzard UI, close), resize grip, credit label.
- `color.lua`: the palette. `gui/core.lua`: widgets (button, label, editbox, dropdown, checkbox,
  status bar, rounded styling, `style_choice`, `set_primary`, background opacity).
- `core/scan.lua`: the scan engine, rewritten for `C_AuctionHouse` (browse query, then one search
  per item key; full scan with `ReplicateItems`). Fast mode (`params.fast`) stops at the browse
  list: one row per item (`info.browse_record`, `record.fast`); `params.on_item_list` hands the raw
  list to the Sniper. `util/scan.lua`, `util/info.lua`: helpers and
  item/auction records. `core/history.lua`: price history ("usual price").
- `util/filter.lua`: aux's search language: parsing, the post filters and their validators.
- `gui/auction_listing.lua`: the result tables (columns Lvl, Item, For sale, ...).
  `gui/buy_bar.lua`: buying under the search results.
- `tabs/search/`: `core.lua` (sub tabs), `results.lua` (searches, history arrows), `saved.lua`
  (favorites and recent), `quick.lua` (quick search menu), `filter.lua` (Filter Builder logic:
  condition tree, search text, "In words"), `frame.lua` (Search tab widgets),
  `builder.lua` (Filter Builder rows and menus), `recipe.lua` (recipe search: the button on the
  profession window, Alt-click on a recipe, the cost line).
- `tabs/sniper/`: the Sniper tab (0.3): `core.lua` (rounds over the whole item list, the deal
  rule `judge`, checking a candidate's real auctions, buying), `frame.lua` (controls and table).
- `tabs/post/`: posting (auto price, undercut mode, deposit, "You get"). `tabs/auctions/`,
  `tabs/bids/`: the other tabs. `core/slash.lua`: `/aux` commands.
- `textures/*.tga`: icons and rounded corners (addon textures load; addon fonts do not).

## Performance (Tyler: "add-on performance and compute cost is very important")

aux runs inside the game; every frame it spends time in costs the player frame rate.
- Nothing may run every frame while it has nothing to do. `OnUpdate` handlers return at once when
  idle, throttle to a few times a second (`GetTime()` checks), and only touch widgets (`SetText`,
  `SetBackdropColor`) when a value changed.
- No endless `aux.coro_thread` loops: a thread that `coro_wait`s forever is resumed every frame,
  all game long, even with the auction house closed. Use events, or a timestamp check inside a
  tab's own `on_update` (which only runs while the tab is shown).
- No work that grows with the square of anything per frame or per event.
- Long loops (thousands of items: the Sniper, fast lists, full scans) yield with `aux.coro_wait()`
  every few hundred items so the game does not stutter.
- Prefer one request over many: the item list (one request per 500 items) over one search per
  item, and read single items only when needed.
- Tests guard the rules above (`per-frame work` in `tests/load_test.lua`); add one when you add an
  `OnUpdate` or a timer.

## Code gotchas (each one has caused a real bug)

- **Module system:** a file starts with `select(2, ...) 'module.name'`. `M.x = v` writes both the
  module environment and its exports, but **reading `M.x` gives nil**. Read `x` from the
  environment, or use a local.
- `frame.lua` and `aux-addon.lua` are module `aux` itself: use `color`, `account_data`, `bounded`
  directly there, not `aux.color` (the global `aux` is the saved variables table).
- Lua 5.1 only (WoW): no `goto`, no `//`, no integer types. Use WoW globals such as `tinsert`,
  `strlower`, `format`.
- Never wrap code that waits (`aux.coro_wait`, any scan request) in `pcall`: Lua 5.1 cannot yield
  inside a `pcall`, so it fails at once. The test harness only notices if the stubbed answer
  arrives on a later tick, as in the game.
- Colors from `color.lua` are callable: `aux.color.accent.background('text')` returns colored
  text; `aux.color.accent.background()` returns r, g, b, a.
- `gui.editbox` calls `editbox.change(self, is_user_input)` on every text change, `enter`, `escape`,
  `char`, `focus_gain`, `focus_loss`. Right click clears it.
- The modern client takes edit box focus away on any mouse press. Dropdown options therefore act
  on `OnMouseDown`, and the menu stays open while hovered (`gui/core.lua`).
- Never hide and re-show a button every frame: the game drops clicks on it (this broke Cancel on
  the buy bar). Show or hide only when the state changes.
- Rounded styling: `gui.set_frame_style` replaces `SetBackdropColor`/`SetBackdropBorderColor` on
  the frame, so later calls recolor the rounded shape.
- Forever rejects fonts shipped in addons; the game font is used. `.tga` textures load.
- Buying must never spend more than the player saw: the buy bar confirms only server quotes at or
  below the shown price. Keep that guarantee.
- Posting: an item auction's buyout must be above its starting bid, or the server answers
  "Internal auction error"; an equal bid is dropped (`item_post_prices` in `tabs/post/core.lua`).
  Gear is priced in whole silver; commodities may use copper. The auction house cut is the
  constant `AUCTION_CUT = .05`. Deposits come from the game (`CalculateItemDeposit`).
- On Forever the newest listing at a price sells first, so the Post tab matches the lowest price by
  default; undercut mode (goblin switch) goes one step below. Undercut mode always starts off.
- Filter Builder: write `and`/`or` with a count (`and2`); a bare `and` takes everything after it.
  The builder and the search bar stay in sync both ways; `loading` and `syncing` flags in
  `tabs/search/filter.lua` stop them from feeding back into each other.

## Design language

Dark slate panels, warm off-white text, one amber accent (`227, 164, 59`) for the selected and
primary things, rounded corners, the game font. Money coming in is green (`positive`), going out red
(`negative`). Tokens are in `color.lua`. Keep new screens in this style. Mockups so far were made
as interactive HTML pages; an HTML file Tyler can open in a browser works the same way.

## Where to find more

- `docs/status.md`: current state, decisions, open items. Keep it up to date.
- `docs/changelog.md`: what changed in each version; add an entry when the version number changes.
- `docs/roadmap.md`: what each version is for. A patch version (0.3.x) is bug fixes, speed and
  small things only, no new features; new features go into the next minor version (0.4).
- `docs/forever-auction-house.md`: how Forever's auction house works, with sources.
- `TESTING.md`: in-game checklist, one numbered section per feature.
- `README.md`: credit, license, install. License: MIT for the changes made here; Simon's original
  code has no license and is used with his permission. CurseForge uses "All Rights Reserved".
- `git log`: every change with its reason. The first commit is the unmodified upstream aux, so
  `git diff <first commit>` shows everything changed for Forever.
