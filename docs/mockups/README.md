# Mockups

Every mockup Claude made for Tyler, copied from claude.ai on 2026-11-19 so they no longer depend on
Claude's tools (Tyler chose to copy them into this public repository). The rule they come from:
for a visual change, show a mockup first and build only once Tyler approves it (`AGENTS.md`).

## How to read them

- **Plain pages** (`*.html` at this level) open in any browser.
- **Design canvases** (the folders) were made with a claude.ai design tool. Each `*.dc.html` file
  is one board; `canvas.json` gives the boards' titles and order. They need that tool's runtime
  (`support.js`, not included) to run their clickable parts, so in a browser the static parts show
  and template fields such as `{{summary}}` show as raw text. Read the HTML and the script at the
  bottom of each file: the data and rules of the mockup are there in plain JavaScript.
- Images that pointed at claude.ai (`/_blob/...`, the goblin undercut icon) do not load; the real
  icon is `auxForever/textures/` in the addon.
- Prices in them are examples unless a mockup says otherwise. The older ones (0.2 to 0.5) are in
  the 0.5 look (slate, amber, rounded), before webster's New theme of 0.6; the credit line there
  ("granted immortality by Tyler") was later changed to "aux by shirsig, re-imagined by a fan".
- One seller name taken from a real auction (quick searches) was replaced with "?".

## The mockups, oldest first, and what was decided

| Mockup | What it showed | Decision |
| --- | --- | --- |
| `redesign-2026-10-04/` | The Search tab buying a trade good, and every state of the buy bar (quantity buttons sized to the stack, server price, Confirm, price went up) | Built in 0.2; the Confirm step was removed in 0.8.2.1 (FB-048) and came back as an option in 0.8.2.2 (FB-049) |
| `quick-searches-2026-10-04/` | The quick search menu (pinned and recent searches with cheapest price and age) and its row states | Built (0.2) |
| `post-pricing-2026-10-04/` | Post tab pricing: Match lowest or Undercut, % of usual, trade goods and gear | Built (0.2); gear in whole silver then, copper since 0.8.2.1 (FB-044) |
| `filter-builder-2026-10-05/` | The Filter Builder: "which items" on the left, conditions with All/Any, not, groups, "In words"; the add-condition catalog; a Settings popup | Built (0.3); the bid variants became separate menu entries instead of a switch |
| `fast-mode-sniper-0.3-2026-10-05/` | Fast mode (one row per item, open to read its auctions) and the Sniper tab (deal rule, rounds, buy bar) | Built (0.3). Its "7,718 items in 8.5s each round" was the October measurement; on 2026-11-17 the house was 25,706 items (FB-055) |
| `auctions-recipes-0.4-2026-10-05/` | The Auctions tab with undercut check and Cancel undercut (approved); recipe search from the profession window (recommended); a Recipes sub tab (not recommended) | Auctions tab and recipe search from the profession window built (0.4) |
| `mockups-0.5-2026-10-08.html` | Three items for 0.5: the quantity box that looks like a place to type (FB-001), what a recipe's materials cost anywhere (FB-007), one meaning per click in every tab (`docs/clicks.md`) | FB-001 option B ("Everything looks good"), the Materials line and the click standard built (0.5) |
| `settings-2026-10-09.html` | Every `/aux` command and where it goes in a two-column Settings window (FB-008) | Approved; Settings built that way in 0.6 build 3 |
| `post-panel-2026-10-10/` | The Post tab's top panel: today, option A (three columns: setup, price, receipt), A with trade goods, B, C | Option A chosen and built (0.6) |
| `waylaid-crate-2026-10-21/` | Waylaid Crate tooltip: A every bundle with the cheapest in gold, B one line; C Alt-click a crate to search its bundles | A and C chosen and built (0.8) |
| `craft-profit-line-2026-11-09.html` | Profit on the Materials line under a recipe's reagents (FB-026): A cost and profit, B cost, selling price and profit, C two lines; the hover; five cases | Built in 0.8.1 (the craft profit line) |

Where each decision is recorded in more detail: `docs/status-history.md`, `docs/changelog.md`, and
the feedback entries named above in `docs/feedback.md`.
