select(2, ...) 'aux.tabs.search'

local aux = require 'aux'
local info = require 'aux.util.info'
local money = require 'aux.util.money'

-- auxForever (0.4): recipe search. Forever has retail's profession window, which can tell an addon
-- the materials of any recipe at the moment it is asked (C_TradeSkillUI.GetRecipeSchematic). A
-- "Search in aux" button on that window, or Alt-click on a recipe, searches the item the recipe
-- makes and every material in one search, and the line next to the sub tabs adds up the cost.
-- Nothing is read or kept before the click. (Shift-click is Blizzard's "track recipe", which aux
-- cannot stop, so it is not used.)

local AUCTION_CUT = .05

-- the recipe ID of a recipe link (the profession window's recipe links are not item links)
function M.recipe_id_from_link(link)
    if type(link) ~= 'string' or strfind(link, 'item:', 1, true) then
        return
    end
    return tonumber(strmatch(link, 'enchant:(%d+)') or strmatch(link, 'spell:(%d+)'))
end

-- {recipe_id, name, output = {item_id, count}, reagents = {{item_id, count}, ...}}, or nil
function M.recipe_parts(recipe_id)
    local schematic = C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic and C_TradeSkillUI.GetRecipeSchematic(recipe_id, false)
    if type(schematic) ~= 'table' then
        return
    end
    local parts = {recipe_id = recipe_id, name = schematic.name, reagents = {}}
    if (schematic.outputItemID or 0) > 0 then
        parts.output = {item_id = schematic.outputItemID, count = max(1, schematic.quantityMin or 1)}
    end
    for _, slot in ipairs(schematic.reagentSlotSchematics or empty) do
        local reagent = slot.reagents and slot.reagents[1]
        if reagent and reagent.itemID and slot.required ~= false and (slot.quantityRequired or 0) > 0 then
            tinsert(parts.reagents, {item_id = reagent.itemID, count = slot.quantityRequired})
        end
    end
    return parts
end

local pending_recipe

-- the search being started belongs to this recipe (read by execute)
function M.take_pending_recipe()
    local parts = pending_recipe
    pending_recipe = nil
    return parts
end

function M.search_recipe(recipe_id)
    local parts = recipe_parts(recipe_id)
    if not parts then
        aux.print('This recipe could not be read.')
        return
    end
    local ids, seen = {}, {}
    for _, part in ipairs(parts.output and {parts.output} or empty) do
        seen[part.item_id] = true
        tinsert(ids, part.item_id)
    end
    for _, part in ipairs(parts.reagents) do
        if not seen[part.item_id] then
            seen[part.item_id] = true
            tinsert(ids, part.item_id)
        end
    end
    aux.coro_thread(function()
        -- item names load on demand: wait up to 2 seconds for any the client has not seen yet
        local names, t0 = {}, GetTime()
        while true do
            local missing
            for i, item_id in ipairs(ids) do
                if not names[i] then
                    local item_info = info.item(item_id)
                    if item_info then
                        names[i] = strlower(item_info.name)
                    else
                        missing = true
                        info.request_item(item_id)
                    end
                end
            end
            if not missing or GetTime() - t0 > 2 then break end
            aux.coro_wait()
        end
        local queries = {}
        for i = 1, #ids do
            -- a slash or semicolon would break the search text; no such item names are known
            if names[i] and not strfind(names[i], '[/;]') then
                tinsert(queries, names[i] .. '/exact')
            end
        end
        if #queries == 0 then
            return
        end
        pending_recipe = parts
        aux.set_tab(1)
        set_filter(table.concat(queries, ';'))
        execute(nil, false)
        -- taken by execute; never left for an unrelated later search
        pending_recipe = nil
    end)
end

local function plain_money(amount)
    return money.to_string(amount, true, nil, nil, true)
end

-- Cost of a recipe from a search's records: materials (each the cheapest auction or the vendor
-- price, whichever is lower; cost counts only those with a price, missing lists the item IDs of
-- the others, nil when none is missing) and what the made item sells for after the cut (nil when
-- none is for sale or the recipe makes no item).
function M.recipe_costs(parts, records)
    local cheapest = {}
    for _, record in ipairs(records or empty) do
        if not record.own and (record.buyout_price or 0) > 0 then
            local unit = record.unit_buyout_price
            if not cheapest[record.item_id] or unit < cheapest[record.item_id] then
                cheapest[record.item_id] = unit
            end
        end
    end
    local cost, missing = 0, nil
    for _, part in ipairs(parts.reagents) do
        local price = cheapest[part.item_id]
        local vendor, limited = info.merchant_buy_info(part.item_id)
        if vendor and not limited and (not price or vendor < price) then
            price = vendor
        end
        if price then
            cost = cost + ceil(price) * part.count
        else
            missing = missing or {}
            tinsert(missing, part.item_id)
        end
    end
    local sell = parts.output and cheapest[parts.output.item_id]
    local net = sell and floor(ceil(sell) * parts.output.count * (1 - AUCTION_CUT)) or nil
    return cost, missing, net
end

-- "Simple Kilt: materials 6s 10c, sells for 42s 75c after the cut, profit 36s 65c". A material
-- with no auction and no known vendor price is named (aux learns vendor prices when you open a
-- vendor that sells it): "materials 8s 63c + Gray Dye (no price)", and the profit becomes a bound
-- ("profit at most", "loss at least").
function M.recipe_summary(search)
    local parts = search.recipe
    local cost, missing, net = recipe_costs(parts, search.records)
    local text = (parts.name or 'Recipe') .. ': materials ' .. plain_money(cost)
    if missing then
        local names = {}
        for _, item_id in ipairs(missing) do
            local item_info = info.item(item_id)
            tinsert(names, item_info and item_info.name or 'a material')
        end
        text = text .. ' + ' .. table.concat(names, ', ') .. ' (no price)'
    end
    if parts.output then
        if not net then
            text = text .. ', none for sale'
        else
            text = text .. ', sells for ' .. plain_money(net) .. ' after the cut'
            if net >= cost then
                text = text .. aux.color.green((missing and ', profit at most ' or ', profit ') .. plain_money(net - cost))
            else
                text = text .. aux.color.red((missing and ', loss at least ' or ', loss ') .. plain_money(cost - net))
            end
        end
    end
    return text
end

-- Saved and Recent searches keep the recipe of a recipe search, so running one again (from either
-- list, the quick menu, the history arrows or typed) shows the cost line again.
function M.saved_recipe(filter_string)
    for _, list in ipairs{recent_searches or empty, favorite_searches or empty} do
        for _, entry in ipairs(list) do
            if entry.recipe and entry.filter_string == filter_string then
                return entry.recipe
            end
        end
    end
end

-- a recipe search in the lists: "Recipe  Colorful Kilt  (3 materials)" instead of its search text
function M.recipe_entry_name(entry)
    local n = #(entry.recipe.reagents or empty)
    return aux.color.accent.background('Recipe') .. '  ' .. (entry.filter_name or entry.recipe.name or '?')
        .. '  ' .. aux.color.label.enabled('(' .. n .. (n == 1 and ' material)' or ' materials)'))
end

-- the button on the profession window, shown while aux is open at the auction house
do
    local button

    local function create_button()
        local form = ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
        if button or type(form) ~= 'table' or not form.GetRecipeInfo then
            return
        end
        button = CreateFrame('Button', nil, form, 'UIPanelButtonTemplate')
        button:SetSize(120, 22)
        button:SetPoint('BOTTOMRIGHT', form, 'BOTTOMRIGHT', -16, 12)
        button:SetText('Search in aux')
        button:SetScript('OnClick', function()
            local recipe = form:GetRecipeInfo()
            if recipe and recipe.recipeID then
                search_recipe(recipe.recipeID)
            end
        end)
        if aux.frame:IsShown() then button:Show() else button:Hide() end
        M.recipe_button = button
    end

    function aux.event.AUX_LOADED()
        aux.event_listener('ADDON_LOADED', function(name)
            if name == 'Blizzard_Professions' then
                create_button()
            end
        end)
        create_button()
        aux.event_listener('AUCTION_HOUSE_SHOW', function()
            create_button()
            if button then button:Show() end
        end)
        aux.event_listener('AUCTION_HOUSE_CLOSED', function()
            if button then button:Hide() end
        end)
    end
end
