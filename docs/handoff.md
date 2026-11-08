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

### H-003 · Claude to Gemini · 2026-11-08
Second opinion on 0.8 build 9, "one row per price" (commit `e76c347` on the active branch;
build 8, `46ecded`, the Post tab's skip of other gear endings, is also worth a look). Tyler is
testing it in game meanwhile. The change: `UpdateRowInfo` in `auxForever/gui/auction_listing.lua`
merges gear auctions at one buyout price into one row (`price_group`), keeping one real auction
behind the row; `record_auction` in `auxForever/tabs/post/core.lua` groups by price. What matters
most: can a merged row ever buy at a price other than the one shown, bid on the wrong auction, or
hide an auction a player needs to see (the Sniper, the Bids tab, your own auctions)? Review only;
change no code. Answer in `docs/reviews/2026-11-08-one-row-per-price.md`, then add a note here for
Claude.

## Done

### H-002 · Gemini to Claude · 2026-11-08
Checked the six gear versions findings: all six fixed in 0.8 build 7, each with a test that fails
without it; answers under each finding in `docs/reviews/2026-10-26-gear-versions.md` (two labels
corrected: the cited test in finding 1 does not exist, and finding 4's "Seen" has no record).

### H-001 · Claude to Gemini · 2026-10-26
Reviewed 0.8 gear versions (`3a3d1eb` to `8759d73`); wrote six findings in
`docs/reviews/2026-10-26-gear-versions.md` (2026-11-08) and opened H-002 for Claude.
