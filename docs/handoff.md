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

### H-005 · Claude to Gemini · 2026-11-08
A last review before 0.8 is released: everything on the active branch since `main` (0.7.1.1),
`git diff origin/main..HEAD -- auxForever tests`, 0.8 builds 1 to 12. Tyler wants your remaining
time spent where I am least sure I got it right, so here they are, most important first. Review
only; change no code. Answer in `docs/reviews/2026-11-08-release-0.8.md` (format in
`docs/reviews/README.md`), most serious first, then add a note here for Claude.

1. **Gamepad support (`auxForever/gamepad.lua`, about 800 lines, build 1).** nokkty's work; I only
   merged it and fixed its tests. Nobody has tested it on the released game, and Tyler will not.
   Most important: can anything in it run, or cost frame time, when no controller is used
   (`gamepad_enabled` checks, the hint strip's `OnUpdate`, `frame:HookScript`)? Does it ever
   write into Blizzard's frames or gamepad code (the taint that froze the beta,
   `docs/gamepad.md`)? Does `aux.show_popup` behave exactly like `StaticPopup_Show` with mouse
   and keyboard?
2. **The price API promise (`auxForever/core/api.lua`, `docs/api.md`).** Since build 3, gear with a
   random ending is priced under `item:ending` (`info.price_key`). `AuxForeverAPI.GetLatestPrice`
   and `GetUsualPrice` by item ID still read `item:0`, which no longer gets new prices for such
   gear. The API's names and meanings are a promise to other addons (`AGENTS.md`). Is this a
   broken promise, and what is the smallest honest fix (by link it works)?
3. **Price keys from names (`auxForever/util/info.lua`: `price_key`, `split_ending`,
   `item_key_price_key`; build 3 and 7).** The ending is whatever the full name adds to the item's
   own name. Where can that go wrong: an item whose own name is not loaded yet (`base_names`), a
   typed name whose base also contains " of " (`split_ending` tries the last " of " first), a name
   from `GetItemKeyInfo` that differs from the link's, other locales?
4. **One row per price (`auxForever/gui/auction_listing.lua`, `UpdateRowInfo` and `price_group`;
   builds 9 and 10).** You reviewed build 9; build 10 changed it again (lowest starting bid kept,
   sellers counted once, `group_count` for the buy bar, no merge without a buyout). Check the
   build 10 version: selection after a purchase (`sync_bucket` in `tabs/search/results.lua`),
   sorting by column after merging, the expand rows of a multi-item search.
5. **The Post tab and gear (`auxForever/tabs/post/core.lua`, `refresh_entries`, `skip_key`,
   `record_auction`, `auto_pick_price`; builds 5, 6, 8, 9).** It took five rounds in game. Look for
   states where Post can be clicked at a wrong price: listings counted as read too early or too
   late (`listings_ready`, `on_abort`), the suggestion from other endings (`other_endings_lowest`,
   a browse `minPrice` that may be a starting bid), switching items quickly (experiment E7 in
   `docs/forever-auction-house.md`: a late answer taken for the next search's).
6. **Waylaid Crates (`auxForever/tabs/search/crate.lua`, build 2).** The bundles are read from
   tooltip text: any line "- <count> <name>" in any item's tooltip counts, and a non-crate item
   is cached per item ID (memory over a long session?). Alt-click on a crate in the bags now
   searches its bundles instead of the crate. `fill_cost` walks listings cheapest first.
7. **Saved prices across versions (`auxForever/core/history.lua` `record_view_of(records,
   views)`, `auxForever/core/scan.lua` `record_view` and `one_version`; build 7).** A scan adds up
   the views of one price key; one version read alone records only today's lowest. Can a scan
   that is stopped halfway, or a Full scan (`collect`), record a wrong market price?
8. **The tests themselves.** `tests/slow_server.lua` now models gear versions (build 3); several
   of my gear tests passed for the wrong reason before (build 5 caught one). Point out any test
   that could still pass while the game would fail.
9. **The release text.** `docs/changelog.md` (the 0.8 section) and
   `docs/curseforge-description.md`: is anything in 0.8 missing, wrong, or said as fact without a
   source (Waylaid Crates, gear endings and one row per price are not in the CurseForge
   description yet)?

## Done

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
