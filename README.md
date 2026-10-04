# aux-forever

A port of [aux](https://github.com/shirsig/aux-addon) by shirsig to World of Warcraft: Forever.

aux is the work of shirsig. This repository adapts it to the Forever client and is kept private
until shirsig has been asked about publishing it. The upstream code has no license file, so the
MIT license in this repository only covers changes made here, not aux itself.

## Why a port is needed

aux was written for Classic Era, which uses the old auction house (pages of 50 auctions, bought by
index). Forever runs on the modern client and uses the modern auction house (`C_AuctionHouse`):

- A search first returns one row per item, then each item is searched for its individual auctions.
- Stackable trade goods are "commodities": they are bought by quantity, always cheapest first,
  and have no bids.
- Every auction has an ID, so aux can buy the selected auction directly.
- A full scan of the whole auction house is allowed once every 15 minutes.

The look, the tabs, the search filter language, saved searches and price history are unchanged.

## Install

1. Download this repository (Code, then Download ZIP) and unzip it.
2. Find your Forever AddOns folder. Easiest: in CurseForge, select your Forever install and use
   its "Open Folder" option. Otherwise, in the Battle.net app use the gear next to Play, then
   "Show in Explorer", open the Forever game folder (its name starts and ends with an underscore)
   and then `Interface\AddOns`.
   On a default install that is
   `C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns`.
3. Copy the `aux-addon` folder into that `AddOns` folder. The folder name must stay `aux-addon`.
4. Start the game, make sure "aux" is enabled in the AddOns list, and keep BugSack enabled.

## Status

In testing. Searching works in game. See `TESTING.md` for what to check and
`docs/forever-auction-house.md` for how Forever's auction house works.

Known gaps:

- Crafting cost in the profession window is not shown (Forever uses a different profession UI).
- Trade goods ("commodities") cannot be bought by row on Forever: the game always sells the
  cheapest units first. Selecting one shows a quantity box in the bottom bar (starting at one
  stack) with the cost worked out from the listings. Buy asks the server for the real price and
  nothing is bought until Confirm. A server price above the shown cost is cancelled.

## Layout

- `aux-addon/` is the addon. The first commit in this repository is the unmodified upstream code,
  so `git diff` against it shows every change made for Forever.
- `aux-addon/compat.lua` maps old Classic function names to their Forever replacements.
- `aux-addon/core/scan.lua` is the rewritten scan engine.
