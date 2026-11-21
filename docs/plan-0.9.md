# auxForever 0.9 Build Handoff

Created: 2026-11-21 (Tyler's time)
For: Gemini Neon (primary engineer) in a new session with Tyler
Base state: `0.8.2.2` released (`main` at `178bd19`, tag `v0.8.2.2`, CurseForge Beta file `9718999`). Latest docs on branch `claude/confident-bohr-vctz8g` (`c78d432`).

## 1. First steps in the new session

1. Read `AGENTS.md`, `GEMINI.md`, `docs/status.md`, `docs/forever-auction-house.md`, and this file.
2. Fetch all branches and start a clean 0.9 branch off `origin/claude/confident-bohr-vctz8g` (which includes the post-0.8.2.2 doc updates and FB-056 to FB-063):
   ```
   git fetch origin '+refs/heads/*:refs/remotes/origin/*'
   git checkout -b gemini/0.9 origin/claude/confident-bohr-vctz8g
   ```
3. When starting build 1:
   - Update `Active branch:` at the top of `docs/handoff.md` to `gemini/0.9`.
   - Bump `## Version: forever-0.9` in `auxForever/auxForever.toc` and add a `## 0.9 (unreleased)` heading in `docs/changelog.md`.
4. Confirm tests pass before changing code (install `lua5.1` and `zip` if missing: `sudo apt-get update && sudo apt-get install -y lua5.1 zip`):
   ```
   cd auxForever
   lua5.1 ../tests/load_test.lua
   lua5.1 ../tests/load_test.lua classic
   for f in $(find . -name '*.lua'); do luac5.1 -p "$f"; done
   cd .. && lua5.1 tests/lint_globals.lua
   ```
5. Ask Tyler which phase to start with (recommended: Phase 1 first since it needs no mockups and immediately fixes the S1 dungeon bug and popular QoL switches, while preparing mockups for Phase 2+).

## 2. Full 0.9 scope (phased build plan)

Build 0.9 in small, testable builds rather than one huge diff. Every visual change gets a mockup approved by Tyler first (`AGENTS.md`). Every bug fix gets a test that fails without the fix. Credit every player handle listed below in `docs/changelog.md`.

### Phase 1: Hardening, small fixes, toggles, and keybinds (no mockups needed)

All items here fit into existing UI or Blizzard's built-in Keybindings menu:

1. **FB-056 (S1 bug, reported by `user_kc0ds7pqedmptpep`): Dungeon / tooltip Lua error hardening**
   - Player got Blizzard's "many Lua errors" popup during a dungeon when someone created conjured water; turning off aux stopped it. No BugSack text was given.
   - Code audit findings to fix (`auxForever/core/tooltip.lua`, `auxForever/util/info.lua`), all verified against `Gethe/wow-ui-source` branch `forever` (**Code**, not yet seen in game):
     - Read tooltip `data` with `issecretvalue` checks before falling back to `pcall(tooltip.GetItem, tooltip)` (`Blizzard_SharedXMLGame/Tooltip/TooltipUtil.lua`'s `GetDisplayedItem` calls `C_Item.GetItemLinkByGUID` / `GetItemInfo` without secret checks).
     - Remove the redundant `tooltip:Show()` at `core/tooltip.lua:183` (`Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua:300` already calls `self:Show()` right after post-calls; calling it from addon code risks tainting `GameTooltip` during combat/dungeons).
     - Guard `tooltip_quantity` (`core/tooltip.lua:41`) against secret numbers (`not (issecretvalue and issecretvalue(quantity))`).
     - Guard `settings.daily` (`core/tooltip.lua:165,167`) when `value` is `nil` or `<= 0` (currently divides by nil).
     - In `util/info.lua`: nil-check `_G['AuxTooltipText' .. side .. i]` and skip `issecretvalue(text)` in `M.tooltip` (`line 511`); nil-check `ITEM_CONJURED` and `ITEM_MIN_LEVEL` in `M.auctionable` (`line 488`, note `tooltip_find(ITEM_MIN_LEVEL, tooltip)` ONLY runs on conjured items like magic water) and guard string types in `tooltip_match`/`tooltip_find`.
   - Tests: secret tooltip data/link/quantity, conjured item with nil globals, missing `AuxTooltipTextLeftN`, `daily` on with nil `value`, and assert `tooltip:Show()` is not called inside `AddTooltipPostCall`.

2. **`wait_throttle` timeout (`core/scan.lua`, `tabs/search/results.lua`)**
   - **Seen** 2026-11-20: Forever's AH throttle can freeze (`IsThrottledMessageSystemReady` stuck `false`, even in Blizzard's window). Add a timeout so aux prints a clear message instead of hanging forever on `Reading the listings...`.
   - Test in `tests/timing_test.lua` with `slow_server.lua`.

3. **FB-058 (suggested by `jebbush`; direction set by Tyler, 2026-11-21): Full stack by default in tooltips, hold Shift for 1 item**
   - Vendor, Vendor Buy, Value and Today always show the **full stack** amount by default when hovering a stack of more than 1 item, and **holding Shift shows 1 item** (flipping the old default).
   - Keep `FB-058`'s switch in Settings > Tooltip lines + `/aux tooltip stack`, starting **on by default** (so players who want 1-item default can still switch it back).
   - In `core/tooltip.lua:93`, use the stack count by default and `1` when Shift is held (reversed if the toggle is turned off). Keep the `for N` label on stacks (and confirm with Tyler whether holding Shift on a stack should say `each` or stay plain).

4. **FB-061 (suggested by `LLanwrst`): Toggle to hide the Professions window Materials / profit line**
   - Setting (default `true`) + matching chat command (e.g. `/aux crafting cost`), checked in `tabs/search/recipe.lua` (`update_line`). Hides immediately when turned off and refreshes live when turned back on (no `/reload` needed). Keep the "Search in aux" button separate since it only appears at the AH.

5. **FB-062 (suggested by `rokstar8872` and `deep_structure`): Option for right-clicking a bag item to always open Post**
   - Account setting under Settings > Posting ("Right-click bag item to sell", default `false`) + matching chat command.
   - In `core/shortcut.lua` (`on_post_item`), when enabled, switch to the Post tab (find by name `'Post'`, not hardcoded index) and call `tab.USE_ITEM(...)`. Keep Shift-click and Alt-click tab-aware (`docs/clicks.md`; update `docs/clicks.md` too).

6. **FB-032 (suggested by `Chawitsch`): Auto Full scan when the auction house opens**
   - Account setting (default `false`) + matching chat command (e.g. `/aux auto scan`).
   - In `aux-addon.lua` (`AUCTION_HOUSE_SHOW`), if enabled and the 15-minute cooldown is over and no Full scan is running, call `start_full_scan()`. Do not trigger when cooldown is active (no chat spam on every AH open).

7. **FB-063 (suggested by `khorrs`): Keybinds for buying, confirming and declining**
   - Add `auxForever/Bindings.xml` (**new file -> requires a full game restart on first install**; note this clearly to Tyler in the build message).
   - Register bindings under WoW's **Options > Keybindings > AddOns > auxForever** acting on whichever buy bar (Search or Sniper) is active while `aux.frame:IsShown()`:
     - **Buy** (fires only in Buy state so mashing it cannot accidentally Confirm when Confirm before buying is on)
     - **Confirm** (fires only in Confirm state)
     - **Cancel / Decline** (cancels a pending quote or confirmation)
     - Optional: **Buy or Confirm** (one-key/scroll-wheel flow for players who want one key to do both)
   - Verify `Bindings.xml` loads cleanly on Forever in game, respects edit-box focus, works with hardware-event restrictions (`StartCommoditiesPurchase`, `PlaceBid`), and does not collide with `gamepad.lua`.

8. **Remove `seen` and tighten wordy UI copy (Tyler, 2026-11-21)**
   - Remove the word `seen ` from tooltip age labels in `core/tooltip.lua:88` and `tabs/search/recipe.lua:319,351` (so `Value: 41 (100%)  for 20  1 day ago` instead of `... seen 1 day ago`).
   - Audit other UI text across auxForever (tooltips, Professions cost tooltip, buy bar messages, status bar, Post tab receipt/hints, Sniper notices, Settings rows/hints, hover click hints) for needless wordiness. Show Tyler a short before/after table of proposed cuts for approval before changing other screens.

9. **Optional small fix (check with Tyler):** `S-09` (Post tab receipt shows a starting bid for a trade good when no price is typed).

### Phase 2: Settings outside the auction house (mockup first)

- **FB-057 (suggested by `LLanwrst` and `jebbush`)**
  - Register an `auxForever` panel in Blizzard's **Options > AddOns** using `Settings.RegisterCanvasLayoutCategory`, `Settings.RegisterAddOnCategory`, and `Settings.OpenToCategory` (confirmed in `Gethe/wow-ui-source`, branch `forever`, `Blizzard_Settings_Shared/Blizzard_Settings.lua` **[Code]**, not yet tested in game).
  - Add `/aux settings` (and aliases `/aux config`, `/aux options`) to open it anywhere in the world, and mention it at the top of `/aux` help.
  - Keep the AH gear popup and the Options > AddOns panel backed by the same saved state and synced via `refresh_settings()`.
  - Building this right after Phase 1 gives clean room for the growing list of switches (the AH gear popup is already 358px tall with 9 tooltip rows).
  - **Mockup first** before building.

### Phase 3: Narrower Sniper (mockup first)

- **FB-055 (reported by `khorrs` and Tyler; Tyler 2026-11-20: "Save narrow sniper for .9")**
  - **Seen** 2026-11-17: the whole Forever AH is 25,706 items (52 browse requests, ~37.7 s floor per round).
  - Let the player narrow what the Sniper watches (e.g., Everything, Trade Goods only, a category, or a Favorite search) so a round finishes in a few seconds.
  - Update `tabs/sniper/core.lua` and `tabs/sniper/frame.lua`; run extended fuzz testing (`AUX_FUZZ_SEEDS=400 AUX_FUZZ_STEPS=250`) after changes.
  - **Mockup first** before building.

### Phase 4: Waylaid Crate Merchant's Favor and Craftsman's Writs (mockup first)

- **FB-059 (`sarrathsilentstrider`) + FB-042 (`user_tdsvrjvpe8rufw54`) + FB-020 writs (`Harro22`)**
  - **Blocked on in-game info from Tyler first:**
    1. A screenshot of a Waylaid Crate's turn-in reward window (and a `/run` probe if needed to check whether Forever exposes Favor/silver via API or if a lookup table per crate item ID is required; **Outside** guides say crates pay Merchant's Favor + silver, writs pay reputation + small coin pouch).
    2. A screenshot of a Craftsman's Writ tooltip so we see how Forever formats the requested crafted item.
  - Crate tooltip (`tabs/search/crate.lua`): show Merchant's Favor reward, optionally full cost (crate + fill, less silver reward) and cost per Favor (`FB-042`, `FB-059`).
  - Craftsman's Writs (`FB-020`): compare buying the finished item vs crafting it (ties into Phase 5's shopping list).
  - **Mockup first** before building.

### Phase 5: Crafting shopping list + what other characters hold (mockup first)

- **FB-023 (suggested by `Kortan`; Tyler 2026-10-20)**
  - Pick a recipe (from the Professions window), type how many to craft, see what is still needed (bags, bank once opened, and other characters' bags/bank/mail), show whether AH or vendor is cheaper for each material, and buy down the list (one click per purchase; hardware-event rule).
  - Alt inventory store: each character on the realm/faction records its bags, bank (on `BANKFRAME_OPENED` / updates) and mail (on `MAIL_SHOW`) when logged in with aux; count them in the shopping list and optionally in tooltips.
  - Open design choices to confirm with Tyler during mockup: (a) where it lives (likely a Shopping sub-tab in Search), (b) whether to compare buying crafted sub-materials vs crafting them, (c) which price the list uses before scanning (latest vs live).
  - **Mockup first** before building.

### Phase 6: Posting rules based on usual price (mockup first)

- **FB-031 (suggested by `user_yt0k9lezehn1ukm993387`)**
  - TSM-style posting rules using the usual price (`history.value`): e.g., post at X% of usual if below lowest, match/undercut lowest otherwise, and flag or skip items whose lowest price is below a Y% floor.
  - Respect the core rule (`AGENTS.md`): aux informs and follows the player's own configured rule; never refuse something Blizzard's window allows without the player opting into a rule.
  - Re-confirm with Tyler during mockup whether fixed undercut ("always undercut by N") is included or stays out after `FB-018`.
  - **Mockup first** before building.

## 3. Explicitly out of 0.9 / open candidates

- **Out of auxForever (`FB-060`, `XtreamCoder`):** GoldScout-style best-items-to-farm guide is `wont-fix` in auxForever. Saved under **Future ideas** in `docs/roadmap.md` as a potential separate companion addon later with `auxForever` as an optional dependency (`AuxForeverAPI`).
- **Open candidates not yet decided by Tyler (ask only if relevant):**
  - `FB-053` (`user_q6cn8g517mpcvp2f`): controller button to search/refresh (needs an in-game experiment first to see if Forever's gamepad mode lets addons bind LT/RT).
  - `FB-054` (`jebbush`): "Bag searching could use an update, cannot sort by bag slots" (unclear which screen; likely Post tab's bag list).
  - `FB-030` (`user_yt0k9lezehn1ukm993387`): show how many days a usual price rests on / keep more than 14 days.
  - `FB-043` (`user_tdsvrjvpe8rufw54`): full window listing every crate and writ by favor/rep per gold.

## 4. Reminders for working with Tyler

- Plain words, lead with the answer/recommendation, no unexplained jargon, no em dashes, no emojis, no filler words.
- Only **Seen** facts go to players or design decisions as plain fact; label **Code**, **Outside**, **Unknown**.
- Dates are Tyler's (`TZ='<-07>7<-06>,M3.2.0,M11.1.0' date`).
- After every build: run all 4 test commands (plus fuzz tests after buying/posting/scan/gamepad edits), build `auxForever-0.9-build<n>.zip`, write crystal-clear one-thing-per-step instructions under `Current build` in `TESTING.md`, and state whether `/reload` is enough or a **full game restart** is needed (`Bindings.xml` and any new Lua/texture file need a full game restart).
- Claude Code is the reviewer: for large phases (or before releasing 0.9), leave a handoff note in `docs/handoff.md` and tell Tyler `Next: tell Claude "Check the handoff."` when a second opinion is useful.
- Never push to `main`, merge a PR, or run the Release workflow until Tyler asks.
