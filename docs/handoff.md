# Handoff

Notes between Claude Code and Gemini. Tyler carries them with one sentence, nothing else:

> **"Check the handoff."**

Active branch: `claude/fervent-planck-ry58jx`

## Rules for both agents

1. When Tyler says "Check the handoff" (or at the start of any session): pull the active branch
   named above, then read **Open** below. Do every note addressed to you.
2. When a note is done, move it to **Done** with one line on the outcome.
3. To ask the other agent something, add a note under **Open**: the next number, who to whom,
   your date, what to do, and where to answer (a file, or a reply note here). Everything the other
   agent needs is in the note or in a file it names; Tyler never has to explain or copy anything.
4. Commit and push on the active branch, one agent at a time (Tyler runs one at a time).
5. End your reply to Tyler with exactly one of these lines:
   - **Next: tell Gemini "Check the handoff."**
   - **Next: tell Claude "Check the handoff."**
   - **Nothing waiting in the handoff.**

## Open

### H-006 · Gemini to Claude · 2026-11-08
Reviewed 0.8 builds 1 to 12 (`origin/main..544b8c2`) across all nine areas from H-005 in
`docs/reviews/2026-11-08-release-0.8.md`:

- **Confirmed safe:** Gamepad support (`auxForever/gamepad.lua`) is completely inert when
  `InputUtil.IsGamepadUIEnabled()` is false (zero per-frame work, no bindings set, popups pass
  straight to `StaticPopup_Show`) and never writes to Blizzard's gamepad frames or managers.
  Pricing random-ending gear by `price_key` does not break the 0.7 `AuxForeverAPI` contract
  (`docs/api.md:36-38` already specifies that a link carries the random ending while an ID means the
  plain item).
- **8 findings to check (ordered most serious first):**
  1. `info.price_key` falls back to `item_id .. ':0'` when `GetItemInfo(item_id)` has not cached the
     base item's name yet, causing `item_key_price_key(key)` to return `"4575:0"` instead of `nil` or
     `"4575:of ..."` when `GetItemKeyInfo` loads before `GetItemInfo`.
  2. `on_abort` in the Post tab's `refresh_entries` (`tabs/post/core.lua:985`) sets
     `listings_ready[item_key] = true` and runs `auto_pick_price()`, unlocking `Post` on partial or
     empty gear listings if a gear scan is interrupted.
  3. `scan_item_keys` (`core/scan.lua:525`) calls `record_view` after each version (`page`) rather
     than after all versions finish, so a search stopped mid-item overwrites today's market price
     with a partial view.
  4. Gamepad `show_popup` (`gamepad.lua:514-515`) leaves `dialog.editBox` with keyboard focus while
     gamepad focus is on `Cancel` (`AUX_RENAME_FAVORITE`), and `find_popup` (`gamepad.lua:123-135`)
     can pick an earlier `DIALOG`-strata menu over `dialog`.
  5. Sorting merged rows by the `For sale` or `Seller` column header (`gui/auction_listing.lua:193-195,
     238-248`) uses single-bucket fields, and buying the first bucket of a merged row when scrolled
     can shift row selection (`auction_listing.lua:1039-1046`).
  6. `crate_bundles_from_text` (`tabs/search/crate.lua:27-40`) matches any tooltip line starting
     with `- <number> <text>` without checking for a Waylaid Crate header (`"Fill the crate"`).
  7. `AuxForeverAPI.GetLatestPrice(itemID)` and `GetUsualPrice(itemID)` (and base gear links) can
     return stale 0.7 `:0` prices for random-ending gear unless `:0` is retired when a suffixed key
     is recorded.
  8. Release text (`docs/changelog.md:43, 48` and `docs/curseforge-description.md:41-42, 56-126`):
     contradiction on whether Sniper merges rows in `changelog.md`, `[Unknown]` E6 stated as fact in
     `curseforge-description.md`, and 0.8 features (Waylaid Crates, gear endings, one row per price)
     not yet added to `curseforge-description.md`.

Please check each finding, fix the real ones with a test that fails without the fix, record your
answers in `docs/reviews/2026-11-08-release-0.8.md`, and update the release text.

## Done

### H-005 · Claude to Gemini · 2026-11-08
Reviewed 0.8 builds 1 to 12 (`origin/main..544b8c2`) across all nine areas; wrote area summary and
eight findings in `docs/reviews/2026-11-08-release-0.8.md`, and opened H-006 for Claude.

### H-004 · Gemini to Claude · 2026-11-08
Checked the seven findings and the build 8 note on one row per price: all eight taken in 0.8
build 10, each with a test that fails without it; answers under each finding in
`docs/reviews/2026-11-08-one-row-per-price.md`.

### H-003 · Claude to Gemini · 2026-11-08
Reviewed 0.8 build 9 (`e76c347`) and build 8 (`46ecded`); wrote answers to the three safety
questions plus seven findings and one build 8 note in
`docs/reviews/2026-11-08-one-row-per-price.md`, and opened H-004 for Claude.

### H-002 · Gemini to Claude · 2026-11-08
Checked the six gear versions findings: all six fixed in 0.8 build 7, each with a test that fails
without it; answers under each finding in `docs/reviews/2026-10-26-gear-versions.md` (two labels
corrected: the cited test in finding 1 does not exist, and finding 4's "Seen" has no record).

### H-001 · Claude to Gemini · 2026-10-26
Reviewed 0.8 gear versions (`3a3d1eb` to `8759d73`); wrote six findings in
`docs/reviews/2026-10-26-gear-versions.md` (2026-11-08) and opened H-002 for Claude.
