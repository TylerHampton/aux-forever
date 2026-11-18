select(2, ...) 'aux.core.stats'

-- auxForever (Upgrades tab, docs/upgrades.md): gear stats, and scores by stat weights.
--
-- Stats come from the game's GetItemStats on an item link (E12 in docs/forever-auction-house.md,
-- Seen 2026-11-16). An auction house row has an item key, not a link: aux's hidden tooltip shows the
-- key (SetItemKey, which shows the version's ending) and gives its link (GetItem); that link's stats
-- were seen in game too. Never C_TooltipInfo.GetItemKey: the game blocks it for addons (E12, Seen).
--
-- Stats keep the game's names (ITEM_MOD_STRENGTH_SHORT, ITEM_MOD_DAMAGE_PER_SECOND_SHORT, ...), and
-- weights use the same names, so a stat the weights do not name counts 0 and no list of stat names
-- has to be guessed here. Nothing runs unless called.

-- equip location -> the inventory slots an item of it can replace
M.SLOTS = {
    INVTYPE_HEAD = {1}, INVTYPE_NECK = {2}, INVTYPE_SHOULDER = {3}, INVTYPE_CLOAK = {15},
    INVTYPE_CHEST = {5}, INVTYPE_ROBE = {5}, INVTYPE_WRIST = {9}, INVTYPE_HAND = {10},
    INVTYPE_WAIST = {6}, INVTYPE_LEGS = {7}, INVTYPE_FEET = {8},
    INVTYPE_FINGER = {11, 12}, INVTYPE_TRINKET = {13, 14},
    INVTYPE_WEAPON = {16, 17}, INVTYPE_WEAPONMAINHAND = {16}, INVTYPE_2HWEAPON = {16},
    INVTYPE_WEAPONOFFHAND = {17}, INVTYPE_SHIELD = {17}, INVTYPE_HOLDABLE = {17},
    INVTYPE_RANGED = {18}, INVTYPE_RANGEDRIGHT = {18}, INVTYPE_THROWN = {18}, INVTYPE_RELIC = {18},
}
local MAIN_HAND, OFF_HAND = 16, 17
-- what may sit in the off hand for a one-handed weapon to replace it: another weapon, not a
-- shield or a held item
local OFF_HAND_WEAPONS = {INVTYPE_WEAPON = true, INVTYPE_WEAPONOFFHAND = true}

local function get_stats(link)
    -- Forever has C_Item.GetItemStats only, no global GetItemStats (BlizzardInterfaceResources, forever)
    local get = C_Item and C_Item.GetItemStats
    local stats = link and get and get(link)
    return type(stats) == 'table' and stats or nil
end

-- the stats of an item link, not kept (for one-off reads of many links, such as a Full scan's)
function M.read_link_stats(link) return get_stats(link) end

-- the stats of an item link; nil while the game has not loaded the item
local link_cache = {}
function M.link_stats(link)
    if not link then return end
    local stats = link_cache[link] or get_stats(link)
    link_cache[link] = stats
    return stats
end

-- the stats of an auction house item key (one version of an item, its ending included), read once
-- per version; nil while the game has not loaded it (ask again later, it is not remembered)
local key_cache = {}
function M.key_stats(key)
    if not key or not AuxTooltip.SetItemKey then return end
    local id = key.itemID .. ':' .. (key.itemLevel or 0) .. ':' .. (key.itemSuffix or 0)
    if key_cache[id] then return key_cache[id] end
    AuxTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
    AuxTooltip:ClearLines()
    AuxTooltip:SetItemKey(key.itemID, key.itemLevel or 0, key.itemSuffix or 0, 0)
    local _, link = AuxTooltip:GetItem()
    AuxTooltip:Hide()
    local stats = get_stats(link)
    key_cache[id] = stats
    return stats
end

-- an item's score: each stat times its weight
function M.score(stats, weights)
    local total = 0
    for name, value in pairs(stats or {}) do
        local weight = weights[name]
        if weight and type(value) == 'number' then
            total = total + value * weight
        end
    end
    return total
end

local function equip_location(link)
    return link and select(9, GetItemInfo(link)) or nil
end

local function worn_in(slot, weights)
    local link = GetInventoryItemLink('player', slot)
    if not link then return 0, nil, true end
    local stats = link_stats(link)
    return score(stats, weights), link, stats ~= nil
end

-- What an item of this equip location would replace, by score: the weaker of two rings or
-- trinkets; a one-handed weapon's main hand, or the weaker hand when the off hand holds a weapon
-- too; for a two-hander both hands together. An empty slot scores 0. Returns the score, the link it
-- is compared with (nil for an empty slot or two hands), and false while a worn item has not
-- loaded (the score is then not to be trusted yet).
function M.worn_score(location, weights)
    local slots = SLOTS[location]
    if not slots then return end
    if location == 'INVTYPE_2HWEAPON' then
        local main, main_link, main_ready = worn_in(MAIN_HAND, weights)
        local off, off_link, off_ready = worn_in(OFF_HAND, weights)
        -- two items worn: no single one to name
        return main + off, not off_link and main_link or nil, main_ready and off_ready
    end
    local best_score, best_link, all_ready
    all_ready = true
    for _, slot in ipairs(slots) do
        local link = GetInventoryItemLink('player', slot)
        local counts = slot ~= OFF_HAND or location ~= 'INVTYPE_WEAPON' or OFF_HAND_WEAPONS[equip_location(link) or '']
        if counts then
            local value, worn_link, ready = worn_in(slot, weights)
            all_ready = all_ready and ready
            if not best_score or value < best_score then
                best_score, best_link = value, worn_link
            end
        end
    end
    return best_score or 0, best_link, all_ready
end

-- How an item compares with what it would replace: its score, the worn score, the gain, and the
-- gain in percent of the worn score (nil when nothing is worn there)
function M.compare(stats, location, weights)
    local own = score(stats, weights)
    local worn, link, ready = worn_score(location, weights)
    if not worn then return end
    local gain = own - worn
    return {
        score = own,
        worn = worn,
        worn_link = link,
        ready = ready,
        gain = gain,
        percent = worn > 0 and gain / worn * 100 or nil,
    }
end

-- The stats that differ between an item and the worn one, biggest weighted change first, for the
-- Changes column: {name = 'ITEM_MOD_STRENGTH_SHORT', diff = 4}, ...
function M.changes(stats, worn_stats, weights)
    local seen, list = {}, {}
    local function add(name)
        if seen[name] then return end
        seen[name] = true
        local diff = ((stats or {})[name] or 0) - ((worn_stats or {})[name] or 0)
        if diff ~= 0 then
            tinsert(list, {name = name, diff = diff, weighted = diff * (weights[name] or 0)})
        end
    end
    for name in pairs(stats or {}) do add(name) end
    for name in pairs(worn_stats or {}) do add(name) end
    sort(list, function(a, b)
        if abs(a.weighted) ~= abs(b.weighted) then return abs(a.weighted) > abs(b.weighted) end
        return a.name < b.name
    end)
    return list
end
