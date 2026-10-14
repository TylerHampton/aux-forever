# AuxForeverAPI: aux's prices for other addons

Since 0.7 (FB-012, asked by MDHippie), auxForever offers its prices to other addons through one
global table, `AuxForeverAPI`. Everything else in aux is private and may change at any time; this
table will not. New functions may be added (and `version` raised); the ones below keep their names,
arguments and meaning.

Code: `auxForever/core/api.lua`. Tests: `0.7: AuxForeverAPI` in `tests/load_test.lua`.

## Using it

Add aux as an optional dependency in your TOC, so it loads before your addon when both are
installed:

```
## OptionalDeps: auxForever
```

Then check that it is there before calling it:

```lua
local aux = AuxForeverAPI
if aux and aux.IsReady() then
    local price, age = aux.GetLatestPrice(itemLink)
    if price then
        print(format('aux: %s, seen %d days ago', GetCoinTextureString(price), age))
    end
end
```

Prices are in copper, per item, for the player's realm and faction. aux learns them when the
player searches or runs a Full scan at the auction house; an item aux has never seen has no price.

## Functions

`item` is an item link, an item string (`"item:2589::::::"`) or an item ID (`2589` or `"2589"`).
A link keeps its random ending ("of the Eagle"), which aux prices apart; an ID means the plain
item. Anything else returns nil, never an error.

| Call | Returns |
| --- | --- |
| `AuxForeverAPI.version` | `1`. Raised when a function is added. |
| `AuxForeverAPI.IsReady()` | `true` once aux's saved prices have loaded (at login). Before that every price is nil. |
| `AuxForeverAPI.GetLatestPrice(item)` | `price, age`: the market price of aux's latest complete look at the item, and how many days ago that was (0 is today). The same price aux shows as "Value" in its tooltips. nil if unknown. |
| `AuxForeverAPI.GetUsualPrice(item)` | `price, age`: the usual price over up to 14 days, recent days counting more, and how many days ago aux last saw the item. aux uses it to find deals (the Sniper, the % columns). nil if unknown. |

How the two prices are worked out, and their known weak points: `docs/price-data.md`.

## Cost

The functions only run when called and read aux's price table; nothing runs every frame. Each call
for an item aux has seen unpacks its saved line once and then answers from a cache.
