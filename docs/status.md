# Status

Last updated at the end of the first session (2026-10-04).

## Working in game (tested by Tyler)

- Search, shift-click and alt-click from bags into Search and Post.
- Buy bar: trade goods by quantity with a confirmed server price, gear one at a time.
  Purchases matched the mail exactly.
- Resizable window that remembers its size and position.
- Rename to auxForever, credit line "aux by shirsig, granted immortality by Tyler".
- New look: top bar with tabs, rounded corners, amber accent, "N sellers" in the seller column.
- Undercut mode: match the cheapest price by default, goblin toggle to undercut.
- Post tab duration dropdown (fixed this session).

## Open

1. **Font.** Forever rejected `BarlowSemiCondensed-Medium.ttf` (`SetFont` returned false; the game
   font loaded fine). The latest zip tries three candidates in order: Barlow, a basic rebuild of
   Barlow (`BarlowBasic-*`, no hinting or layout tables), and PT Sans Narrow. At login, chat
   prints which one was used, with a result per candidate. Ask Tyler for that line. If all fail,
   Forever may block addon fonts entirely; then drop the bundled fonts.
2. The status bar at the bottom left is solid amber when idle and looks loud. Suggested a dim gray
   when idle; Tyler has not answered.
3. Parts of the mockup not built yet: "Results N" count, the summary line next to the sub tabs
   ("11 price levels, 6,180 for sale, searched 4s ago"), a search icon in the search box.
   Column names were kept as in aux on purpose.
4. Not yet tested in game: Auctions tab cancel, Bids tab, full scan, posting gear with a bid,
   Filter Builder dropdowns after the dropdown fix. See `TESTING.md`.
5. Later: Tyler sends Simon (shirsig) the project to review before it goes public. The GitHub
   repository can optionally be renamed to auxForever.

## Ideas Tyler mentioned for later

- Expand undercut mode beyond one step (start simple, iterate).
- Remove the "/aux undercut" explanation once Forever players know the mechanic.
