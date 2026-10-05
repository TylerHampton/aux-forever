# Filter Builder test run (0.2 and 0.2.1)

One pass through everything new since 0.1.1, with items a level 15 to 25 Horde character sees in
the Barrens and nearby. About 20 minutes. Write down anything that looks wrong, plus the step
number, and send a screenshot.

Before you start: update to 0.2.1 and fully restart the game. At an auctioneer (Orgrimmar or
Crossroads), click Full scan once if you have not in a while; the "% of usual" steps need price
history. A full scan is allowed once every 15 minutes.

Names in quotes are what you type. "Search bar shows" is the text in the search bar at the top;
click outside it to see it in color.

## A. Which items (left side)

1. Search tab, Filter Builder. Click Clear all. The search bar is empty and "In words" says
   "All items."
2. Name: "linen". Search bar shows `linen`. Press Search at the top: Linen Cloth, Linen Bandage,
   Linen Bag and so on. The Search Results tab shows a count, and the line next to the tabs says
   how many price levels and items for sale.
3. Back to Filter Builder. Name: "linen cloth", tick Exact. Search bar shows
   `linen cloth/exact`, and the other left-side fields disappear. Search: only Linen Cloth.
4. Clear all. Category: Armor. Type: Cloth. Level 15 to 25. Tick "I can use". Rarity: Uncommon.
   Search bar shows `15/25/usable/armor/cloth/uncommon`. In words: "Uncommon or better cloth
   (armor), level 15 to 25, that you can use." Search: green cloth gear in that level range.
   If the category or type names look different from the game's own auction house, note it.

## B. Conditions (right side)

5. Clear all. Category: Trade Goods (or what the game calls it), Type: Herb. Click
   "+ Condition", pick "Price per item, at most", type "20s". Search bar shows
   `trade goods/herb/price/20s`. Search: Peacebloom, Silverleaf, Earthroot, Mageroyal, Briarthorn,
   Bruiseweed and so on, none above 20s each.
6. Change the price to "abc". The box turns red and `price/...` disappears from the search bar.
   Change it back to "20s".
7. "+ Condition", "% of usual price, at most", type "80". Search bar ends `price/20s/percent/80`.
   In words reads both, joined by AND. Search: only herbs at or under 80% of their usual price
   (may be none; that is fine).
8. Click "not" on the % row (it turns red). Search bar now has `not/percent/80`. In words says
   "NOT buyout is at most 80%...". Click it again to turn it off.
9. Match: Any (top right). Search bar starts the post part with `or2/`. Switch back to All.
10. Click the × on the % row. It is gone, and so is `percent/80` in the search bar.

## C. Groups (Simon's nesting)

11. Clear all. Category: Trade Goods, Type: Cloth. Match: Any.
12. "+ Group". Inside the new box (it says Group: match All), "+ Condition", "Price per item, at
    most", "1s". Then "+ Condition" inside the same box, "Item is", "linen cloth".
13. Below the box, "+ Group" again. Inside it: "Price per item, at most", "3s", and "Item is",
    "wool cloth".
14. Search bar shows
    `trade goods/cloth/or2/and2/price/1s/item/linen cloth/and2/price/3s/item/wool cloth`.
    In words: "(price at most 1s AND item is Linen Cloth) OR (price at most 3s AND item is Wool
    Cloth)". Search: Linen Cloth up to 1s and Wool Cloth up to 3s, nothing else.
15. Inside the first box, "+ Group": a box inside the box (Match Any). Add "Time left is" and pick
    any choice. The search bar grows a `left/...` part inside the first group. Remove that inner
    box with its ×.
16. Click "not" on the second box. The search bar shows `not/and2/price/3s/item/wool cloth`.
    Turn it off again.

## D. Search bar and builder stay in sync

17. With the builder open, click into the search bar and type
    `trade goods/leather/price/50s`. The form follows as you type: Trade Goods, Leather, and one
    price row. Search: Light Leather, Medium Leather, Light Hide under 50s.
18. Paste Simon's example into the search bar:
    `or/and2/profit/5g/percent/60/and3/bid-profit/5g/bid-percent/60/left/30m`
    The builder shows Match Any with two groups, and In words explains it.
19. Type just `price` into the search bar. In words turns red and says the text cannot be shown;
    the rows stay as they were. Clear all.

## E. Recipes you can learn

20. Clear all. Category: Recipes. "+ Condition", "Usable, not learned yet". Search: only recipes
    your professions can learn now. This one reads item tooltips, which may behave differently on
    Forever; note if it shows recipes you already know or cannot use.

## F. Favorites and settings

21. Build any search (step 5 is fine), click "Save to favorites": chat says "Saved to favorites",
    and it shows on Saved Searches and in the clock menu. Click it again: "already a favorite".
22. Clear all, then "Save to favorites": chat says the search bar is empty, nothing is saved.
    Same with the Favorite button on Saved Searches.
23. Gear menu: Auction length 24h. Post tab: pick an item you have never posted (Light Leather,
    a Wool Bandage): it starts at 24h. An item you posted before keeps its old length.

## G. 0.2.1 checks

24. Post tab, a trade good you have plenty of (Linen Cloth, Copper Ore): one Quantity box, starting
    at everything you have. Max goes back to all of it.
25. Search tab: a magnifier in the search bar; the line next to the tabs only shows on Search
    Results and says "still searching" during a search.
