select(2, ...) 'aux.tabs.search'

local info = require 'aux.util.info'

-- auxForever (0.8, FB-020, Harro22): Waylaid Crates. A crate's tooltip lists the bundles that fill
-- it, any one of them (seen 2026-10-20):
--   Use: Fill the crate with any bundle from the following list:
--   - 20 Wool Cloth
--   - 40 Silk Cloth
--   - 20 Medium Leather
-- aux reads that list from the tooltip text, so no crate is written down by hand, and prices each
-- bundle from what aux already knows (the recipe cost rules: vendor when cheaper, else the latest
-- price), less what is already in the bags. The cheapest bundle is the cheapest way to fill it.

-- crate item ID -> its bundles; a crate's list never changes, so each is read once
local bundles_of = {}

local function plain(text)
    return (text:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''))
end

-- the bundles in a tooltip's lines (strings; a line may hold several rows), or nil when the item
-- is not a crate: {{name, count}, ...}, in the tooltip's order
function M.crate_bundles_from_text(texts)
    local bundles = {}
    for _, text in ipairs(texts) do
        if type(text) == 'string' then
            for row in string.gmatch(plain(text), '[^\n]+') do
                local count, name = strmatch(row, '^%s*%-%s*(%d+)%s+(.-)%s*$')
                if count and name ~= '' then
                    tinsert(bundles, {name = name, count = tonumber(count)})
                end
            end
        end
    end
    return #bundles > 0 and bundles or nil
end

-- the bundles of a crate, read from its tooltip lines the first time and kept
function M.crate_bundles(item_id, texts)
    if bundles_of[item_id] == nil and texts then
        bundles_of[item_id] = crate_bundles_from_text(texts) or false
    end
    return bundles_of[item_id] or nil
end

-- a material's item ID from its name: aux's item list (filled by scans), else the game's cache
local function material_id(name)
    local id = info.item_id(name)
    if not id and C_Item and C_Item.GetItemInfoInstant then
        local instant = C_Item.GetItemInfoInstant(name)
        id = type(instant) == 'number' and instant or nil
    end
    return id
end

local function bag_count(item_id)
    local count = C_Item and C_Item.GetItemCount and C_Item.GetItemCount(item_id)
    if type(count) ~= 'number' and GetItemCount then count = GetItemCount(item_id) end
    return type(count) == 'number' and count or 0
end

-- each bundle priced: {name, count, item_id, have, need, cost, source, age}, cost nil when aux
-- has no price (or does not know the item); and the index of the cheapest priced bundle
function M.crate_costs(bundles)
    local rows, cheapest = {}, nil
    for i, bundle in ipairs(bundles) do
        local row = {name = bundle.name, count = bundle.count, item_id = material_id(bundle.name)}
        row.have = row.item_id and bag_count(row.item_id) or 0
        row.need = max(0, bundle.count - row.have)
        if row.item_id then
            if row.need == 0 then
                row.cost, row.source = 0, 'bags'
            else
                local total, missing, priced = recipe_usual_cost({reagents = {{item_id = row.item_id, count = row.need}}})
                if missing == 0 then
                    row.cost, row.source, row.age = total, priced[1].source, priced[1].age
                end
            end
        end
        if row.cost and (not cheapest or row.cost < rows[cheapest].cost) then
            cheapest = i
        end
        tinsert(rows, row)
    end
    return rows, cheapest
end
