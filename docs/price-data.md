# Price data: where aux keeps prices and how it uses them

Written 2026-10-08 for Tyler and for any agent touching prices. Facts come from the code (file and
function named); anything else is marked as an inference or an opinion.

## In one paragraph

aux keeps one short line of text per item: the lowest price it saw for that item today, plus the
lowest price of each of up to 11 earlier days on which it saw the item. The "usual price" (called
"Value" in tooltips) is worked out from those daily lows. Everything aux has ever scanned feeds
this, not only the Full scan. It is saved in the game's own saved-variables file, so it is there
after a logout and away from the auction house.

## Where it is stored

- WoW lets an addon keep data in one way only: saved variables, which the game writes to a file
  when you log out or `/reload`. aux's are declared in `auxForever/auxForever.toc`
  (`## SavedVariables: aux`). On disk this is
  `World of Warcraft\_classic_beta_\WTF\Account\<account>\SavedVariables\auxForever.lua`
  (the game names the file after the addon folder).
- Inside it, price history sits under `aux.faction["<realm>|<faction>"].history`
  (`faction_data`, set up in `auxForever/aux-addon.lua`). So each realm and faction has its own
  history; characters of the same faction on the same realm share it.
- One entry per item, keyed `"<item id>:<suffix id>"` (gear "of the Owl" and "of the Bear" are
  separate items). The entry is packed text (`history_schema` in `auxForever/core/history.lua`):
  when today ends, today's lowest, and the list of past daily lows with their dates. Packing keeps
  the file and memory small.
- While playing, aux also keeps in memory (not saved): today's lowest per item seen today
  (`today_min`) and the usual prices worked out so far (`value_cache`). `/aux memory detail` counts
  them.

## How a price gets in

- Every auction any scan sees goes through `history.process_auction` (`auxForever/core/history.lua`,
  called from `auxForever/core/scan.lua`): Search (fast and full mode), Live, the Sniper's checks
  of single items (`scan.read_item`), and the Full scan.
- It records only a new low: if this auction's price per unit is below today's lowest for the
  item, it becomes today's lowest. Nothing else about the auction is kept (not how many were for
  sale, not the second cheapest).
- At local midnight (`get_next_push`), the next time the item is read, today's lowest moves into
  the list of daily lows. The list keeps the 11 most recent days that had a price (`push_record`).
  Days without a scan of the item add nothing; old days stay until 11 newer ones push them out.

## How the usual price is worked out

`history.value` in `auxForever/core/history.lua`:
- With no past days yet: today's lowest.
- Otherwise: a weighted median of the past daily lows (the middle value, with each day's weight
  `0.99 ^ days old`). Today's lowest is not part of it until the day ends.
- `history.market_value` is today's lowest ("Today" in tooltips).

## Where it is used

- Item tooltips: "Value" (usual) and "Today" (`auxForever/core/tooltip.lua`).
- Search results: the percentage of the usual price (`gui/auction_listing.lua`).
- Post tab: the "% of usual" badge, and the starting price when an item has no listings
  (`tabs/post/core.lua`).
- Sniper: the deal rule compares prices with the usual price, shown only with 3 or more days of
  history (`tabs/sniper/core.lua`).
- Search filters such as `pct` and `profit` (`util/filter.lua`), disenchant values
  (`core/disenchant.lua`).
- Planned: recipe cost in the profession window (`docs/feedback.md`, FB-007).

## Is it the best way? (Claude's assessment, 2026-10-08)

Where it is stored is right: saved variables are the only place an addon can keep data, and one
packed line per item is small. Measured in 0.4: about 2,200 items with a usual price after normal
play, a small part of aux's memory (`docs/status.md`).

What it records is the weak part. These are inferences from the code, not measured in game:

1. **One cheap auction sets the day.** Only the single lowest unit price is kept. One trade good
   listed far too low (a mistake, or one unit) becomes that day's value. The weighted median over
   several days softens this, but a usual price built from only a few days of scans does not.
2. **It does not know how much is for sale at that price.** For buying 20 of a material, the
   cheapest unit understates the cost. This matters for the planned recipe cost (FB-007) and for
   the Sniper.
3. **Old prices count almost as much as new ones.** The weight `0.99 ^ days` is nearly flat: a
   price from 30 days ago counts about three quarters as much as yesterday's. With 11 days kept,
   someone who scans once a week has a usual price spread over about two and a half months.
4. **Nothing says how fresh a price is** when it is shown (except the Sniper's 3-day minimum).
5. **Per faction.** History is kept per realm and faction, as in Classic. Whether Forever's
   auction house is shared between factions is not recorded in `docs/forever-auction-house.md`; if
   it is, each faction collects the same prices separately. Unverified.

For comparison, from memory and not checked: TSM's "market value" averages the cheaper part of
the listings over about two weeks instead of taking the single lowest auction. Check TSM's own
documentation before relying on this.

What a better version could look like (opinion, for 0.5 planning; Tyler decides):
- During a Full scan, which sees every auction, record per item a price that resists outliers, for
  example the average price of the cheapest part of what is listed (a share of the units, not one
  auction), plus how many units were listed.
- Keep the date of the last price, and show old prices dimmed or with their age.
- Weight recent days more (for example halve a day's weight every week or two).
- Every user of `history.value` (list above) would change at once, and existing history would need
  converting or a fresh start. That makes it a minor-version change with tests, not a patch.
- A first step that changes nothing for players: a `/aux debug` line that prints, for a few items
  after a Full scan, today's lowest next to the average of the cheapest part of the listings, to
  see how far apart they are on Forever.
