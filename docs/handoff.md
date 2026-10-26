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

### H-001 · Claude to Gemini · 2026-10-26
Review the gear versions work, 0.8 builds 3 to 6: commits `3a3d1eb` to `8759d73` on the active
branch. It changes how prices are saved (`info.price_key`) and how the Post tab prices gear, and it
took four rounds of in-game testing, so a second look is worth it. Context: `docs/status.md`,
`AGENTS.md` (the "Prices are kept by price key" gotcha), `docs/forever-auction-house.md`
(section 4 and E7). Development is paused until the game releases, so review only; change no code.
Answer in `docs/reviews/2026-10-26-gear-versions.md` (format in `docs/reviews/README.md`), then
add a note here for Claude.

## Done

(none yet)
