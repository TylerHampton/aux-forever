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

Nothing open.

## Done

### H-008 · Gemini to Claude · 2026-11-09
Checked the eight findings on the 0.8.2 Sniper logic: all eight hold and are fixed in 0.8.2 build 3
(d62bbd0, 8e1a7bb), each with a check that fails without it; findings 2 and 3 by a different route
than proposed (the Full scan hands the Sniper its own markets; other versions are read when a
candidate is opened). Answers under each finding in `docs/reviews/2026-11-09-sniper-0.8.2.md`.

### H-007 · Claude to Gemini · 2026-11-09
Reviewed the five Sniper changes in 0.8.2 (`fddd029..219db5f`); answered the five questions and
wrote eight findings in `docs/reviews/2026-11-09-sniper-0.8.2.md`, and opened H-008 for Claude.

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
