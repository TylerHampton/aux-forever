# auxForever

aux by shirsig, re-imagined by a fan.

auxForever brings [aux](https://github.com/shirsig/aux-addon), the auction house addon by shirsig,
to World of Warcraft: Forever.

## Credit

aux was created and is maintained by [shirsig](https://github.com/shirsig) (Simon). The search
filter language, saved searches, price history, the tabs and the whole idea of how aux works
are his. This project only adapts his work to the Forever client and builds on it.

Simon gave permission for this port by email in 2026:

> "as far as I'm concerned you can feel free to use it, work on it and distribute it in any way
> you please."

He is not involved in the Forever version, so please report problems with it here rather than
to him. For aux on Classic Era, see [shirsig/aux-addon](https://github.com/shirsig/aux-addon).

## License

The original aux code has no license file; it is used here with Simon's permission above. The
MIT license in this repository covers only the changes made here, not aux itself.

## Why a port is needed

aux was written for Classic Era, which uses the old auction house (pages of 50 auctions, bought by
index). Forever runs on the modern client and uses the modern auction house (`C_AuctionHouse`):

- A search first returns one row per item, then each item is searched for its individual auctions.
- Stackable trade goods are "commodities": they are bought by quantity, always cheapest first,
  and have no bids.
- Every auction has an ID, so aux can buy the selected auction directly.
- A full scan of the whole auction house is allowed once every 15 minutes.

The tabs, the search filter language and saved searches work as in aux. The window has a new look,
and the price history was improved in 0.5 (a market price per day that one cheap auction cannot
set, and the age of each price in tooltips; see `docs/price-data.md`).

## Install

1. Download the latest `auxForever-<version>.zip` from the repository's
   [Releases](https://github.com/TylerHampton/aux-forever/releases) page (or install it with the
   CurseForge app) and unzip it.
2. Find your Forever AddOns folder. Easiest: in CurseForge, select your Forever install and use
   its "Open Folder" option. Otherwise, in the Battle.net app use the gear next to Play, then
   "Show in Explorer", open the Forever game folder (its name starts and ends with an underscore)
   and then `Interface\AddOns`.
   On a default install that is
   `C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns`.
3. Copy the `auxForever` folder into that `AddOns` folder. The folder name must stay `auxForever`.
   If an older test copy named `aux-addon` is there, delete it so the two don't load together.
4. Start the game, make sure "auxForever" is enabled in the AddOns list, and keep BugSack enabled.

## Status

Released as a beta on CurseForge (unlisted). The latest version is on the
[Releases](https://github.com/TylerHampton/aux-forever/releases) page; what changed in each version
is in `docs/changelog.md`. All tabs work in game: Search, Sniper, Post, Auctions and Bids, plus
recipe costs in the profession window.

To get good prices in tooltips and recipe costs, run a Full scan (top right of the aux window) on
each visit to the auction house.

Report problems on the [issue tracker](https://github.com/TylerHampton/aux-forever/issues), with
the error text if BugSack shows one.

## Layout

- `AGENTS.md` is the guide for AI agents working on this repository (Claude, Gemini, Jules).
- `docs/status.md` is where things stand; `TESTING.md` is the in-game checklist.

- `auxForever/` is the addon (named `aux-addon` in the early commits). The first commit in this repository is the unmodified upstream code,
  so `git diff` against it shows every change made for Forever.
- `auxForever/compat.lua` maps old Classic function names to their Forever replacements.
- `auxForever/core/scan.lua` is the rewritten scan engine.
