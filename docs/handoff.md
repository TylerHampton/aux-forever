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

### H-007 · Claude to Gemini · 2026-11-09 · Review the Sniper logic in 0.8.2 (tight scope)

Tyler wants you as an analyst: is the Sniper's new deal logic the best way to solve the players'
problem, and did Claude miss anything in the logic? Review only, no code changes on this branch.

**What the Sniper is for (read this first).** The Sniper is a flipping tool. While its tab is open
it reads the whole auction house's item list again and again (one request per 500 items, a round
every few seconds) and lists the auctions priced well below what the item really sells for, or
below what a vendor pays for it, with a sound. The player then decides: clicks the deal, aux shows
the buy bar, the player buys, and later resells the item at the normal price (or sells it to a
vendor) for a profit. So a deal is only a deal if the player can resell above the price paid,
after the auction house's 5% cut. Two ways it fails a player:
- **A false deal costs gold.** Swiftwren bought "deals at 4% of the usual price" and could only
  relist them at a loss: hundreds were listed at about the same price.
- **A missed or slow deal costs the chance.** Another player gets it first; a player reported over
  30 seconds from the sound to the purchase.
The player's settings are a percent (a deal is at most this share of the reference price) and a
minimum profit. Rules that hold whatever you suggest (`AGENTS.md`): aux informs, it never buys or
decides for the player; buying never spends more than the price shown (the buy bar confirms only a
server quote at or below it); every item opened is a request under the game's request limit, so
fewer requests means faster rounds (Performance section).

**The player reports** (word for word in `docs/feedback.md`): FB-036 (Swiftwren, two comments; the
second gives Invoker's Cord: 1 at 12s, usual 32s, while 78 are listed at 13s, and "1,792 possible
deals" in one round) and FB-028 (slow from sound to purchase).

**What changed** (`git diff fddd029 219db5f -- auxForever/tabs/sniper`, plus `is_full_scan` in
`auxForever/core/scan.lua`):
1. `judge`: the reference price is the lower of the usual price (`history.value`, a weighted middle
   of up to 14 past days) and today's market; the Why column says "% of market" when the market is
   lower (commit bde3033, re-judging fix in 4090883).
2. `market_now`: today's market from the item's own listings, read when a candidate is opened: the
   middle price of the cheapest quarter of the units above the cheapest price; or that cheapest
   price when 3 or more sellers ask it; other versions of the same gear name count as one unit each
   at their lowest price; nil for a lone auction (then the usual price alone, as before).
3. `check_list`, the round's check on the item list before opening anything: also uses the market
   last read for the item (kept 15 minutes), the price of today's complete look (`history.latest`
   with age 0, from a Full scan today) and the other versions' lowest prices (build 2, 219db5f).
   Trade-off written in the code: an auction alone and listed since today's Full scan is that
   scan's price, so it is no longer offered.
4. `refresh_deal`: a deal read in the last 15 seconds (`FRESH_SECONDS`) goes to the buy bar without
   reading it again (8a4aa64).
5. `update`: no new round while a Full scan runs, so the round does not stop it (19921b1).

**Questions to answer, one finding each where you disagree:**
1. Is "the lower of the usual price and today's market" the right reference for a flip, or is
   there a better practice (for example how other auction addons decide a snipe; label it Outside)?
2. `market_now`: do the cheapest quarter, the 3-seller rule and one unit per other version hide
   real deals or let false ones through? Give a concrete listing for each case you find.
3. The list check (point 3): is the trade-off acceptable, and is there a cheaper or safer way to
   cut the 1,792 opens?
4. `FRESH_SECONDS` and the 15-minute market memory: any case where they buy the wrong thing, spend
   more than shown, or keep a stale market too long?
5. Anything in these five changes that breaks a rule above or a test's intent.

**Out of scope:** the rest of 0.8.2 (Full scan wait and messages, tooltip text search, Usually
switch, Shift hint) and anything already released.

**How:** pull this branch, read `AGENTS.md` (Roles, Performance, Code gotchas) and the five
changes. The tests: `cd auxForever && lua5.1 ../tests/load_test.lua` (and `classic`); the Sniper's
are named `fb036`, `fb036b` and `fb028`. Facts about Forever's auction house carry their label
(Seen, Code, Outside, Unknown). Write `docs/reviews/2026-11-09-sniper-0.8.2.md` (date, branch,
commit 219db5f; a short verdict first, then numbered findings: what, where, why it matters to a
player, how sure). Then add H-008 for Claude here, commit and push.


## Done

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
