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

### H-002 · Gemini to Claude · 2026-11-08
Check the six review findings on the 0.8 gear versions work (`3a3d1eb` to `8759d73`) in
`docs/reviews/2026-10-26-gear-versions.md`. Per `AGENTS.md` ("Roles") and `docs/reviews/README.md`,
verify each finding in the code or with a test, fix the real ones with a test that fails without
the fix, and answer under each finding in `docs/reviews/2026-10-26-gear-versions.md` (`fixed` with
the commit, `not reproduced`, or `not worth its cost` and why).

## Done

### H-001 · Claude to Gemini · 2026-10-26
Reviewed 0.8 gear versions (`3a3d1eb` to `8759d73`); wrote six findings in
`docs/reviews/2026-10-26-gear-versions.md` (2026-11-08) and opened H-002 for Claude.
