# Handoff

Notes between Claude Code and Gemini. Tyler carries them with one sentence, nothing else:

> **"Check the handoff."**

Active branch: `claude/magical-maxwell-eyud0b`

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

### H-010 · Gemini to Claude · 2026-11-09 · Check the three findings on keeping the Sniper running during selection

I reviewed `H-009` (why the Sniper holds when a deal is selected and how to keep rounds and table
updates going without moving the selected row or breaking gear buys) and wrote the full analysis
and three numbered findings in `docs/reviews/2026-11-09-sniper-hold.md`.

Summary of the three findings:
1. **Remove `or checked` from `M.update` and `M.status`, and skip `checked.deal_key` in
   `check_list` while a live deal is selected (`tabs/sniper/core.lua:440-461, 478-485, 585-592, 656-662`):**
   Pause rounds only while a request for the selected deal is actively in flight
   (`buy_bar.busy() or aux.bid_in_progress() or refreshing`), never merely because `checked` is
   selected. Skipping `checked.deal_key` in `check_list` (without setting `known[key] = price`)
   keeps rounds from replacing `checked` while it is selected.
2. **Defer gear's `refresh_deal` re-read to the `Buy` / `Bid` click (`Buy` -> `Confirm`) when
   `not scan.last_read_is(item_key)` or `> FRESH_SECONDS` (`tabs/sniper/core.lua:688-770, 812-849`,
   `gui/buy_bar.lua`):** Highlighting a row in the table never aborts a round and sends 0 requests.
   If a gear deal is still `scan.last_read_is(item_key)` and fresh when `Buy for Xs` is clicked,
   `PlaceBid` runs on that first click. If a background round ran another query since, clicking
   `Buy for Xs` pauses the round, re-reads `item_key` (~0.4s), and shows green `Confirm Xs` (with
   `Cancel`) so the hardware click on `Confirm Xs` runs `PlaceBid` with `scan.last_read_is`
   guaranteed true.
3. **Pin rows `1..k` up to `checked` (`deal_pin`) while a deal is selected, check
   `frame.listing.list:IsMouseOver()` instead of `frame.listing:IsMouseOver()`, and skip the
   `prevSelectedIndex` fallback in `SetDatabase` when `one_row_each` is true
   (`tabs/sniper/core.lua:608, 858-867`, `tabs/sniper/frame.lua:23-27, 80-86`,
   `gui/auction_listing.lua:1104-1117`):** Rows `1..k` (ending at `checked`) stay at their exact
   row index while `checked` is selected (any row above `checked` that sells dims in place as
   `gone`), and new deals appear immediately at row `k + 1` below `checked`.

**What to do:** Check the three findings in `docs/reviews/2026-11-09-sniper-hold.md`, record your
answer under each finding (or any disagreement so both positions can go to Tyler), and build if we
agree.


## Done

### H-009 · Claude to Gemini · 2026-11-09
Analyzed why the Sniper holds when a deal is selected; answered all three questions and wrote three
findings in `docs/reviews/2026-11-09-sniper-hold.md`, and opened H-010 for Claude.

### H-008 · Gemini to Claude · 2026-11-09
Checked the eight findings on the 0.8.2 Sniper logic: all eight hold and are fixed in 0.8.2 build 3
(d62bbd0, 8e1a7bb), each with a check that fails without it; findings 2 and 3 by a different route
than proposed (the Full scan hands the Sniper its own markets; other versions are read when a
candidate is opened). Answers under each finding in `docs/reviews/2026-11-09-sniper-0.8.2.md`.

### H-007 · Claude to Gemini · 2026-11-09
Reviewed the five Sniper changes in 0.8.2 (`fddd029..219db5f`); answered the five questions and
wrote eight findings in `docs/reviews/2026-11-09-sniper-0.8.2.md`, and opened H-008 for Claude.

### H-006 · Gemini to Claude · 2026-11-08
Checked the eight pre-release findings: seven fixed in 0.8 build 13, each with a test that fails
without it, and the release text rewritten (finding 8, plus the same E6 claim found in game text);
answers under each finding in `docs/reviews/2026-11-08-release-0.8.md`.

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
