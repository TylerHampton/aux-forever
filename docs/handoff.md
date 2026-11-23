# Handoff

Notes between Gemini Neon (the primary engineer since 2026-11-19) and Claude Code (the reviewer).
Tyler carries them with one sentence, nothing else:

> **"Check the handoff."**

Active branch: `gemini/0.9.1` (0.9.0.1 hotfix released 2026-11-23; back on 0.9.1 branch)

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

### H-013 · Gemini Neon (0.9.0.1 hotfix) to Gemini Neon (0.9.1 build chat) · 2026-11-23 · pull 0.9.0.1 FB-067 fix before continuing 0.9.1
`0.9.0.1` (hotfix for `FB-067` multi-item gear posting on the Post tab) has been tested by Tyler,
merged to `main` (PR #45, `94100dd`), released (`v0.9.0.1`, CurseForge Beta file `9771064`), and
merged into `origin/gemini/0.9.1` at commit `2ab2392` (all 1,648 checks passing in New + Classic,
0 unknown globals).

**Action required before any further edits or pushes in the 0.9.1 build chat:**
1. Pull `origin/gemini/0.9.1` (`git fetch origin && git merge origin/gemini/0.9.1`, or rebase your
   local uncommitted/unpushed work onto it) so you do not ship 0.9.1 without the `0.9.0.1` fix or
   clobber `auxForever/tabs/post/core.lua`, `tests/slow_server.lua`, `tests/load_test.lua`,
   `tests/timing_test.lua`, `docs/changelog.md`, `docs/feedback.md`, `TESTING.md`, or
   `docs/status.md`.
2. **Preserve these Post tab invariants when building `FB-031` Posting Rules or other Post edits in
   `auxForever/tabs/post/core.lua`:**
   - `post_state` tracks `expected_bags = max(0, bags_before - wanted)` and `last_bags`.
     `check_post_bags()` and `AUCTION_MULTISELL_UPDATE` (`total and total > 0 and count == total`)
     finish only once `bag_count(post_state.item_key) <= post_state.expected_bags` (never
     `< bags_before`, which broke every 2+ item gear post and multi-slot commodity post).
   - `post_state.updated_at` resets on `AUCTION_MULTISELL_START`, every `AUCTION_MULTISELL_UPDATE`
     (including `count < total`), `AUCTION_HOUSE_AUCTION_CREATED`, and bag-count drops so 8+ item
     batches do not hit the 5-second silence timeout mid-batch.
   - `BAG_UPDATE_DELAYED` calls `check_post_bags()` while `post_state` is active (not done), skips
     while `post_state` is non-nil and `done` (preventing double updates before `complete_post()`),
     and calls `sync_inventory()` (`update_inventory_records(false, true)`, clamping count or
     advancing off vanished items) only when `frame and frame:IsShown()`. Keep zero container scans
     while the Post tab is closed, and keep `update_inventory_records()` without `add_new` inside
     `complete_post()` and the `'gone'` branch.
3. **Test harness update to keep in mind (`tests/slow_server.lua`):** `PostCommodity` and
   `PostItem` now return `false` (`needsConfirmation = false`, enforcing the real 5-second timeout),
   and `PostItem` with `quantity > 1` fires realistic staggered multisell events
   (`AUCTION_MULTISELL_START`, `AUCTION_HOUSE_AUCTION_CREATED`, `AUCTION_MULTISELL_UPDATE`, delayed
   `BAG_UPDATE` + `BAG_UPDATE_DELAYED`). Re-run both themes + lint (confirm >= 1,648 checks) after
   merging your local 0.9.1 work.
4. Once pulled and verified, move `H-013` to **Done** with one line on the outcome.

## Done

### H-012 · Claude to Gemini Neon · 2026-11-19 · the takeover
Done 2026-11-20 (Gemini Neon): read the brief in full, verified all tests (both themes, lint, 400
fuzz sessions), integrated and closed two open contributor PRs that were not listed in the brief
(PR #41 nokkty gamepad item compare, PR #37 Dragoy Full scan cooldown/no-answer polish), updated
CI to name test zips `auxForever-<version>-build<n>.zip`, ran build 4 testing with Tyler (passed),
recorded two new Seen AH facts (1c deposit floor live; `Scroll: CHAP BALK WELLES` freezes Forever's
AH throttle in Blizzard's window too), saved narrower Sniper for 0.9, and released 0.8.2.2 (PR #43,
tag `v0.8.2.2`, CurseForge Beta file 9718999). Everything else in the brief matched the repo.

### H-011 · Outside review to Claude (primary engineer) · 2026-11-10
Tyler had the reviewer build the fixes in the same session: 0.8.2.1 build 1 on this branch. Every
finding is answered under it in `docs/reviews/2026-11-10-outside-review.md`: after build 2, 21 fixed
with tests that fail without them, 4 fixed in part, 3 not built with the reason (R-05 and R-27 wait
for Tyler in the game, R-28 for a later version), plus a second pass (S-01 to S-04). Where things stand: `docs/status.md`.

### H-010 · Gemini to Claude · 2026-11-09
Checked the three findings: 1 built in part (trade goods and gone deals no longer hold the rounds,
the selected deal is not opened by them; gear still holds), 3 built with three changes (pin in the
table's sort, pins kept on re-read and trimming, a Sniper-only flag instead of `one_row_each`), 2
not built: a disagreement for Tyler (an extra Confirm click on most gear buys). 0.8.2 build 7;
answers under each finding in `docs/reviews/2026-11-09-sniper-hold.md`.

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
