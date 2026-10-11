# Clicks: what every click does in auxForever

Written 2026-10-07 after Tyler asked whether clicks are predictable across the addon (prompted by
Darkhorse's right-click request, `docs/feedback.md` FB-002). Part 1 is a map of the code as of
0.4.1 (facts, with files). Part 2 compares it with Blizzard and the original aux. Part 3 is the
standard proposed for 0.5 (Claude's proposal; Tyler approves it before it is built, like a
mockup).

## 1. Click map (0.4.1, from the code)

### Items outside aux (bags, chat links, profession window), while aux is open

| Click | What happens | Where |
| --- | --- | --- |
| Shift-click (no chat box open) | Search tab: searches the item. Post tab: selects it. Other tabs: nothing. | `core/shortcut.lua` |
| Alt-click | Same as Shift-click. (Original aux used Alt only; Shift was added for Forever.) | `core/shortcut.lua` |
| Shift-click with a chat box open | Links the item in chat (Blizzard). | Blizzard |
| Right-click a bag item | Not handled by aux. Darkhorse: "nothing happened" (FB-002). | none |
| Drag an item onto the search bar, or onto the Post tab's item button | Searches it / selects it. Clicking those with an item on the cursor does the same. | `tabs/search/frame.lua`, `tabs/post/frame.lua` |
| Alt-click a recipe in the profession window | Recipe search (item and materials). | `core/shortcut.lua`, `tabs/search/recipe.lua` |
| "Search in aux" button on the profession window | Recipe search. | `tabs/search/recipe.lua` |

### Result tables (Search results, Sniper, Auctions, Bids; `gui/auction_listing.lua`)

| Click | Search | Sniper | Auctions | Bids |
| --- | --- | --- | --- | --- |
| Left-click a row | Select (buy bar shows it) | Select and hold the rounds; click again to let go | Select | Select |
| Right-click a row | Search for that item | Search for that item | Search for that item | Search for that item |
| Shift-click a row | Link in chat (Blizzard) | same | same | same |
| Ctrl-click a row | Preview the item (Blizzard) | same | same | same |
| Double-click a row | Expand or collapse a grouped row | same | same | same |
| Alt-click the selected row, only with `/aux action shortcuts` on (off by default) | Left: buy. Right: bid. | nothing | Cancel (either button) | Left: buyout. Right: bid. |
| Click a column header | Sort | Sort | Sort | Sort |
| Right-click some column headers | Switch the column (for example per unit / per stack) | same | same | same |

### Post tab (`tabs/post/frame.lua`)

| Click | What happens |
| --- | --- |
| Left-click an item in the bag list | Select it for posting |
| Right-click an item in the bag list | Search for it on the Search tab |
| Left-click a price in the bid or buyout list | Use that price |
| Right-click a price in those lists | Clear the chosen price (only if it is the chosen one) |
| Double-click a price in those lists | Set the stack size to that listing's |

### Saved Searches (`tabs/search/saved.lua`)

| Click | Recent searches | Favorites |
| --- | --- | --- |
| Left-click | Run it | Run it |
| Shift + left-click | Put it in the search bar without running | same |
| Shift + right-click | Add it to the search bar's text | same |
| Right-click | Add to favorites | Remove (asks first) |
| Ctrl + right-click | nothing | Rename |
| Alt + left-click | nothing | Turn its alert on or off |
| Alt + drag | nothing | Reorder |

### Everything else

| Click | What happens | Where |
| --- | --- | --- |
| Right-click any text box | Clears it (original aux) | `gui/core.lua` |
| Right-click the Search button | Runs the current search again, ignoring what is typed | `tabs/search/frame.lua` |
| Quick searches menu (clock button) | Left-click only: run; pin button pins | `tabs/search/quick.lua` |
| Dropdown options | Act on mouse down (the modern client drops focus on click) | `gui/core.lua` |
| Drag the window | Moves it | `frame.lua` |
| Resize corner: drag / double-click | Resize / back to the default size | `frame.lua` |

Shown to players: only in `docs/curseforge-description.md` (Usage). Nothing in the addon itself
tells a player that any of these exist.

## 2. Compared with Blizzard, the original aux and TSM

- **Blizzard (modern client):** Shift-click an item links it in chat, Ctrl-click previews it.
  Right-click on a bag item with the auction house open sends it to the Sell tab (what Darkhorse
  expected; on Forever not checked in Blizzard's code yet, see FB-002). auxForever keeps Shift and
  Ctrl on rows the same way.
- **Original aux (Classic, upstream commit b33f6c4):** Alt-click a bag item to use it in the
  current tab; right-click a row to search its item; Shift/Ctrl on rows go to Blizzard; Alt-click
  shortcuts optional; right-click clears text boxes; the Saved Searches clicks above. auxForever
  kept all of these and added Shift-click from bags.
- **TSM:** not compared. TSM's documentation found on 2026-10-07 does not describe its clicks on
  auction rows or bag items (searched support.tradeskillmaster.com and blog.tradeskillmaster.com;
  the only documented ones seen were unrelated, such as right-click deleting a ledger entry).
  Unverified either way; check in game with TSM installed if TSM parity matters.

## 3. Findings and the standard proposed for 0.5

### What is already consistent

- Right-click a row in any result table searches for that item, in all four tabs and in the Post
  tab's bag list. Shift and Ctrl on rows always do Blizzard's link and preview. Double-click always
  expands. This is the core of aux and stays.

### What is not (findings)

1. **Right-click on a bag item does nothing** (FB-002), while it is the first thing Blizzard and
   Auctionator players try.
2. **Using a bag item works in two tabs only.** Shift- or Alt-click from the bags in the Sniper,
   Auctions or Bids tab does nothing at all, with no message.
3. **Right-click has a different meaning in the Post tab's price lists** (clear the price) than in
   every other list (search the item).
4. **Saved Searches has seven hidden combinations** (Shift, Ctrl, Alt with left and right), one of
   them destructive (right-click removes a favorite, with a confirmation). None are shown.
5. **Alt means four things**: use a bag item, recipe search, the opt-in buy/bid/cancel shortcuts,
   and favorites' alert and reordering. They do not collide (different places), so this is a
   naming problem more than a behavior problem.
6. **The Sniper's left-click holds the rounds** until clicked again, unlike any other table
   (already in the 0.5 notes as the Sniper rework).
7. **None of it is visible.** Under Tyler's rule (the problem is the addon, not the player), a
   click nobody can discover is a finding in itself.
8. Unverified: Shift-click on an aux row with no chat box open goes to Blizzard, which may put it in
   Blizzard's hidden search box, so nothing visible happens. Check in game.

### Proposed standard (one meaning per click, everywhere)

| Click | Meaning everywhere |
| --- | --- |
| Left-click | Select, or the thing's main action (run a search, use a price). Clicking a selected row again lets go of it, in every table (replaces the Sniper's special case and the Post tab's right-click to clear). |
| Right-click on a row inside aux | Search for that item. Including the Post tab's price lists. |
| Right-click, Shift-click or Alt-click an item in the bags (outside aux) | Bring it into aux: Search tab searches it, Post tab selects it for posting, and any other tab switches to the Search tab and searches it. (Shift-click with a chat box open stays Blizzard's chat link.) |
| Shift-click / Ctrl-click a row | Blizzard: link in chat / preview. Unchanged. |
| Double-click a row | Expand or collapse. The Post tab's double-click (set the stack size) goes, since Forever posts a trade good as one quantity. Check what it does in 0.4.1 first. |
| Right-click a text box | Clear it. Unchanged. |
| Alt | aux's own shortcuts: bag item use, recipe search, the opt-in buy/bid/cancel, favorites' alert and order. Unchanged. |
| Saved Searches | Keep the clicks (they are Simon's, and some players know them), but show them: a one-line hint when hovering a row. |

Showing clicks (for the "none of it is visible" finding): when hovering a row in any aux table, add
one gray line at the bottom of the item tooltip with that row's clicks, for example "Right-click:
search  Double-click: expand". One line, only on aux's own rows, so it stays low profile. A visual
change: mockup first.

Not proposed: changing Shift and Ctrl on rows, the Alt shortcuts, or the text box right-click.
They match Blizzard or the original aux, which is the direction Tyler set (AGENTS.md, Design
language).

### Built in 0.5 (2026-10-07)

Tyler approved the standard and the hover hint mockup on 2026-10-07 ("Everything looks good"). Built:
- Right-click a bag item (FB-002): checked in Blizzard's UI source for Forever (branch `forever` of
  Gethe/wow-ui-source, `Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua`,
  `ContainerFrameItemButton_OnClick`): with `AuctionHouseFrame` shown, a right-click on a bag item
  that can be sold calls `AuctionHouseFrame:SetPostItem`, which puts it into Blizzard's own Sell tab
  (and starts a search for it). aux keeps that window shown but invisible, so the item went there:
  Darkhorse's "nothing happened". aux now follows that call (`hooksecurefunc`, a right-click only,
  not while Blizzard's window is shown) and uses the item in aux (`core/shortcut.lua`). Items the
  game says cannot be sold still go to Blizzard's default right-click (use or equip).
- Shift-, Alt- and right-click from the bags in a tab without its own use (Sniper, Auctions, Bids)
  switch to Search and search the item.
- Clicking the selected row again lets go of it in every result table (`gui/auction_listing.lua`)
  and in the Post tab's price lists. Alt-click on the selected row stays the opt-in shortcut.
- Post tab price lists: right-click searches the item; double-click no longer sets the quantity.
- Hover hint: every aux row shows a gray line with its clicks (`gui.add_click_hint`): result rows
  and their item tooltips (Alt shortcuts listed only when turned on), the Post tab's bag list and
  price lists, Saved Searches.
- Not changed: Shift and Ctrl on rows, the Alt shortcuts, right-click on text boxes, the Sniper's
  hold (part of the Sniper rework, `docs/roadmap.md`).

### For the session building 0.5

- Show Tyler the standard table above (and the hover hint mockup) for an OK before changing clicks.
- `core/shortcut.lua` is where bag clicks go; right-click on a bag item is not a modified click,
  so it needs Blizzard's bag click code checked first (FB-002).
- Update the Usage section of `docs/curseforge-description.md` and `docs/curseforge.md` to match.
- Tests: each click rule above that changes gets a test (the harness can call the handlers; see
  AGENTS.md, Tests). In-game checks go into `TESTING.md`.
