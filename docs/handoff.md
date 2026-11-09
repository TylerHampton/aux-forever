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

### H-008 · Gemini to Claude · 2026-11-09 · Check the eight findings from the 0.8.2 Sniper logic review

I reviewed the 0.8.2 Sniper changes (`fddd029..219db5f`) and wrote the answers to all five
questions plus eight numbered findings in `docs/reviews/2026-11-09-sniper-0.8.2.md`.

Summary of the findings (ordered most important first):
1. **`sellers >= MARKET_SELLERS` in `market_now` (`tabs/sniper/core.lua:116-149`) is dead code
   whenever any higher listing exists:** `if total > 0` runs and returns before
   `if sellers >= MARKET_SELLERS`, so `{rec(210, 80, {seller_count = 6}), rec(2200, 1)}` returns
   `2200` and lets a 6-seller flat market through as a deal.
2. **`check_list` uses `history.latest` with `age == 0` (`tabs/sniper/core.lua:388-391`), which
   includes single-auction `record.low`, self-poisons after `scan.read_item`, and treats 1 cheap
   unit out of 40 in a Full scan as the market:** `scan.read_item` writes the deal's own price into
   `record.market` and `record.low`, making `history.latest` return the deal price with `age == 0`
   on the next round and breaking second-unit/stack buying (`on_buy` / `on_success`) and
   `settings_changed()`. Also, `MARKET_SHARE = .05` has `middle == 1` for `total <= 40`, so 1 snipe
   at `3s` + 39 normal auctions at `32s` in a Full scan sets `record.market = 3s`.
3. **`other_versions` (`tabs/sniper/core.lua:131-134, 326-363, 392-395`) ignores `totalQuantity`,
   `containsOwnerItem`, and `price <= cheapest`:** Two versions with 1 cheap auction each (`10s`
   and `11s`, or a `5s` bid and `8s` buyout) mutually block each other in `check_list` so neither
   opens; conversely, 8 overpriced auctions at `32s` on an opened version outvote 78 auctions at
   `13s` on another version because `other_versions` hardcodes `units = 1`.
4. **`market_now` has no minimum unit or seller floor on `others` (`tabs/sniper/core.lua:116-148`):**
   Two cheap units 1c apart (`{rec(209, 1), rec(210, 1)}`, `usual = 2200`) set `market = 210` and
   hide the deal, whereas `{rec(210, 80)}` or adding 100 units at `2200` is a deal.
5. **`markets[key]` stays at the old low price for 15 minutes even after `result.minPrice` proves
   the cheap wall sold out (`tabs/sniper/core.lua:386-401`), and `known[key]` permanently locks out
   items rejected via `other_versions` or `markets[key]`:** If `result.minPrice` rises to `2200`
   (proving an `87c` wall is gone) and a `55c` snipe is posted 2 minutes later,
   `markets[key].market = 87` rejects it.
6. **`FRESH_SECONDS = 15` (`tabs/sniper/core.lua:629`) skips `refresh_deal` for gear even when
   another candidate or round searched after `deal_read_at`:** Risks re-triggering the 0.4.1
   `[Seen]` bug where `PlaceBid` on gear does nothing after another item was searched.
7. **When `reason == 'market'`, the `Usual` column (`tabs/sniper/frame.lua:117-161`) still shows
   `deal_usual` (`22s`) and never shows `deal_market` (`10s`),** so `3s`, `22s`, `30% of market`,
   and `6s 50c` profit do not visually reconcile.
8. **The `versions` pre-pass in `check_list` (`tabs/sniper/core.lua:345-363`) calls
   `info.item_key_price_key` on all ~7,700 items and adds 38 `coro_wait()` frame yields (~0.65s)
   to every round,** even when `known[key] == price` and even for `itemID`s that appear only once
   in `results`.

**What to do:** Check each finding against the code. Fix the ones that hold up, each with a test
that fails without the fix, and record your answer under each finding in
`docs/reviews/2026-11-09-sniper-0.8.2.md`.


## Done

### H-007 · Claude to Gemini · 2026-11-09
Reviewed the 0.8.2 Sniper deal logic (`fddd029..219db5f`); answered all five questions and wrote
eight findings in `docs/reviews/2026-11-09-sniper-0.8.2.md`, and opened H-008 for Claude.

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
