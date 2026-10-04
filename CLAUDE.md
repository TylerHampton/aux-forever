# auxForever

A port of the aux auction house addon (by shirsig) to World of Warcraft: Forever, with a redesign.
The owner, Tyler, is not a programmer: explain things in plain words, say what to click and where,
and give a ready-to-install zip after every change. Current status and open items: `docs/status.md`.

## Working on it

- The addon is the `auxForever/` folder. Players copy that folder into
  `World of Warcraft\_classic_beta_\Interface\AddOns`.
- Develop on the branch the session names (so far `claude/modest-volta-4mgmsb`, PR #1). Do not push
  to `main` or merge without being asked.
- Tests: from `auxForever/`, run `lua5.1 ../tests/load_test.lua`. It must end with
  `done, errors: 0`. Also `luac5.1 -p` every Lua file. Add a test for each bug
  fixed, and check it fails without the fix.
- Zip for Tyler: `zip -qr <scratchpad>/auxForever.zip auxForever -x '*.git*'`, then send it.
- New files (fonts, textures, Lua files) are only seen by the game after a full restart, not
  `/reload`. Say so whenever an update adds files.

## Code gotchas

- Module system (`libs/package.lua`): a file starts with `select(2, ...) 'module.name'`.
  `M.x = v` writes the module env and its exports, but **reading `M.x` gives nil**. Read `x`
  from the env, or use a local. This caused two crashes already.
- `frame.lua` and `aux-addon.lua` are module `aux` itself: use `color`, `account_data`, `bounded`
  directly there, not `aux.color` (the global `aux` is the saved variables table).
- The modern client takes edit box focus away on any mouse press (see the dropdown fix in
  `gui/core.lua`).
- Rounded styling: `gui.set_frame_style` replaces `SetBackdropColor`/`SetBackdropBorderColor` on
  the frame, so old callers recolor the rounded shape.
- Forever auction house facts are in `docs/forever-auction-house.md` (items vs commodities,
  buckets, the "player" owner string, throttles, the 15 minute full scan).
- Forever does not load fonts from addons (it rejected three TTF files while its own loaded), so
  the game font is used. Textures (`.tga`) from the addon folder do load.
- The buy bar redraws every frame: never hide and re-show a button each frame, the game drops
  clicks on it (this broke Cancel). Show or hide only when the state changes.
- Buying must never spend more than the player saw: the buy bar confirms only quotes at or below
  the shown price. Keep that guarantee.

## Writing style

No em dashes and no emojis in anything published (README, commit messages, in-game text).
