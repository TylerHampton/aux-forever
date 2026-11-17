# Source: user_mezgz2zh1g3sbu1v and sarrathsilentstrider in CurseForge comments, 2026-11-16

- Channel: comments on the auxForever CurseForge project page: one comment and one reply to it.
- Received: 2026-11-16 (Tyler's date), as one screenshot from Tyler. The screenshot is not kept;
  this transcript replaces it.
- Times as CurseForge showed them when Tyler took the screenshot. The comment was expanded ("Read
  less" link); the whole text is below. The comment's code lines were indented with dots, kept as
  shown.
- Transcribed word for word, typos kept.
- Recorded under FB-044 in `docs/feedback.md`.

```
user_mezgz2zh1g3sbu1v (13 hours ago):
In auxForever's pricing code, the rule is:
- Commodities (such as ores and herbs): Can be priced in copper.
- Non-commodities (such as bags and equipment): Prices are rounded to whole silver.

However not all Non-commodities are restricted by Blizzard to be sold as whole silver rounded. An example is Small Red Pouch which the auxForever restricts to only whole silver price, but Blizzard actually allows it to be sold in copper too.

Instead of auxForevers blanket restriction on non-commodities, a better way to handle such this would be to disable the a whole-silver restriction IF the addon finds other current listings of the item at non-whole silver prices.

Since auxForever is already searching for other listings of the item and finding the item when we move the item to the post window that scan is already being done anyway.

For example (lua code):

local function is_copper_pricing_observed(listings)
....for _, listing in ipairs(listings) do
........if listing.unit_price % 100 ~= 0 then
............return true
........end
....end
....return false
end

The modulo operation % 100 checks whether a price has a nonzero copper remainder.
- 200 % 100 = 0 → 2s 00c
- 249 % 100 = 49 → 2s 49c
- 265 % 100 = 65 → 2s 65c
If any current listing has a copper remainder, auxForever could switch to 1-copper pricing increments for that item.

I'd actually go one step further: when auxForever detects copper priced listings it could display a short message beneath the price field: "Copper pricing enabled - detected in current listings."

This implementation would be relatively small.

    sarrathsilentstrider (11 hours ago), reply:
    @user_mezgz2zh1g3sbu1v Thanks for this.  I hope it gets implemented somehow, as I prefer not having to swap to the Blizz UI to sell things
```
