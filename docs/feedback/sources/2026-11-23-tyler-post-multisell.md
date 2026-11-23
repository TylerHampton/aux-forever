# Source: Tyler's bug report on posting 2 gear items, 2026-11-23

- Channel: chat with Gemini Neon (with an in-game screenshot).
- Received: 2026-11-23 (Tyler's date, UTC-7).
- Transcribed word for word.
- Entry from this report: FB-067 in `docs/feedback.md`.

```
log this bug I found. Aux sold both my bracers I was selling (2) but acted like it only sold one
```

Screenshot description (auxForever Post tab and the four relevant chat lines; unrelated chat lines
and character UI omitted):

- Chat lines in order:
  - `Auction created.`
  - `Auction created.`
  - `<auxForever> Posted 1 of 2 × Runed Copper Bracers`
  - `<auxForever> Not posted: the item is no longer in your bags.`
- Post tab state:
  - Left bag list still shows `[Runed Copper Bracers]` selected (no stack count badge).
  - Item header reads `Runed Copper Bracers` and `1 in your bags`.
  - Count is `1`, Duration is `2h`, Starting bid `3s 17c` (`98% of usual`), Buyout `3s 17c`
    (`98% of usual`), Match lowest active, button reads `Post 1 item`.
  - Red message under Duration reads: `Not posted: the item is no longer in your bags.`
  - Auction Buyout (per item) table row 2 shows the player's own listing in green: For sale `2`,
    Time Left `2h`, Buyout `3s 17c`, % of usual `98%`.
