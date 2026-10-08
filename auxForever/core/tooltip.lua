select(2, ...) 'aux.core.tooltip'

local aux = require 'aux'
local info = require 'aux.util.info'
local money =  require 'aux.util.money'
local disenchant = require 'aux.core.disenchant'
local history = require 'aux.core.history'
local gui = require 'aux.gui'

local UNKNOWN = GRAY_FONT_COLOR_CODE .. '?' .. FONT_COLOR_CODE_CLOSE


-- Forever: item tooltips are built through TooltipDataProcessor, so one post-call replaces the
-- per-method GameTooltip hooks of Classic aux. The quantity (used when Shift is held) is read from
-- the call that filled the tooltip, where the item's stack size is known.
local quantity_getters = {
    GetBagItem = function(bag, slot)
        local item = C_Container.GetContainerItemInfo(bag, slot)
        return item and item.stackCount
    end,
    GetInventoryItem = function(unit, slot)
        return GetInventoryItemCount(unit, slot)
    end,
    GetLootItem = function(slot)
        return select(3, GetLootSlotInfo(slot))
    end,
    GetMerchantItem = function(slot)
        return select(4, GetMerchantItemInfo(slot))
    end,
    GetBuybackItem = function(slot)
        return select(4, GetBuybackItemInfo(slot))
    end,
}

local function tooltip_quantity(tooltip)
    local processing_info = tooltip.processingInfo
    local getter = processing_info and quantity_getters[processing_info.getterName]
    if getter and processing_info.getterArgs then
        local ok, quantity = pcall(getter, unpack(processing_info.getterArgs, 1, processing_info.getterArgs.n or #processing_info.getterArgs))
        if ok and type(quantity) == 'number' and quantity > 0 then
            return quantity
        end
    end
    return 1
end

function aux.event.AUX_LOADED()
    settings = aux.character_data.tooltip
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then
            return
        end
        if tooltip.IsForbidden and tooltip:IsForbidden() then
            return
        end
        local _, link = tooltip:GetItem()
        link = link or data and data.hyperlink
        if type(link) ~= 'string' or (issecretvalue and issecretvalue(link)) or not strfind(link, 'item:') then
            return
        end
        extend_tooltip(tooltip, link, tooltip_quantity(tooltip))
    end)
end

-- auxForever: whether an item can be auctioned is read from a hidden tooltip of the item, which
-- the game has to build. aux did that on every hover of every item, anywhere in the game; the
-- answer never changes for an item, so it is kept (one entry per item hovered).
local auctionable_cache = {}

function M.is_auctionable(item_id, item_info)
    local known = auctionable_cache[item_id]
    if known == nil then
        known = info.auctionable(info.tooltip('link', item_info.link), item_info.quality) and true or false
        auctionable_cache[item_id] = known
    end
    return known
end

-- auxForever (0.5): how fresh the usual price is, after Value: "  seen 3 days ago", gray, darker when
-- the newest price is a week old or more
function M.age_suffix(age)
    local text = history.age_text(age)
    if not text then
        return ''
    end
    local color = age >= history.OLD_DAYS and aux.color.label.disabled or aux.color.label.enabled
    return '  ' .. color('seen ' .. text)
end

function extend_tooltip(tooltip, link, quantity)
    local item_id, suffix_id = info.parse_link(link)
    quantity = IsShiftKeyDown() and quantity or 1
    local item_info = info.item(item_id)
    -- auxForever: the disenchant table is only worked out when one of its lines is shown
    if item_info and (settings.disenchant_distribution or settings.disenchant_value) then
        local distribution = disenchant.distribution(item_info.slot, item_info.quality, item_info.level)
        if #distribution > 0 then
            if settings.disenchant_distribution then
                tooltip:AddLine('Disenchants into:', aux.color.tooltip.disenchant.distribution())
                sort(distribution, function(a,b) return a.probability > b.probability end)
                for _, event in ipairs(distribution) do
                    tooltip:AddLine(format('  %s%% %s (%s-%s)', event.probability * 100, info.display_name(event.item_id, true) or 'item:' .. event.item_id, event.min_quantity, event.max_quantity), aux.color.tooltip.disenchant.distribution())
                end
            end
            if settings.disenchant_value then
                local disenchant_value = disenchant.value(item_info.slot, item_info.quality, item_info.level)
                if settings.money_icons then
                    tooltip:AddLine('Disenchant: ' .. (disenchant_value and GetCoinTextureString(disenchant_value) or UNKNOWN), aux.color.tooltip.disenchant.value())
                else
                    tooltip:AddLine('Disenchant: ' .. (disenchant_value and money.to_string2(disenchant_value) or UNKNOWN), aux.color.tooltip.disenchant.value())
                end
            end
        end
    end
    if settings.merchant_buy then
        local price, limited = info.merchant_buy_info(item_id)
        if price then
            if settings.money_icons then
                tooltip:AddLine('Vendor Buy ' .. (limited and '(limited): ' or ': ') .. GetCoinTextureString(price * quantity), aux.color.tooltip.merchant())
            else
                tooltip:AddLine('Vendor Buy ' .. (limited and '(limited): ' or ': ') .. money.to_string2(price * quantity), aux.color.tooltip.merchant())
            end
        end
    end
    if settings.merchant_sell then
        local price = item_info and item_info.sell_price
        if price ~= 0 then
            if settings.money_icons then
                tooltip:AddLine('Vendor: ' .. (price and GetCoinTextureString(price * quantity) or UNKNOWN), aux.color.tooltip.merchant())
            else
                tooltip:AddLine('Vendor: ' .. (price and money.to_string2(price * quantity) or UNKNOWN), aux.color.tooltip.merchant())
            end
        end
    end
    local auctionable = not item_info or is_auctionable(item_id, item_info)
    local item_key = (item_id or 0) .. ':' .. (suffix_id or 0)
    local value, age = history.value_and_age(item_key)
    if auctionable then
        if settings.value then
            if settings.money_icons then
                tooltip:AddLine('Value: ' .. (value and GetCoinTextureString(value * quantity) .. age_suffix(age) or UNKNOWN), aux.color.tooltip.value())
            else
                tooltip:AddLine('Value: ' .. (value and money.to_string2(value * quantity) .. age_suffix(age) or UNKNOWN), aux.color.tooltip.value())
            end
        end
        if settings.daily  then
            local market_value = history.market_value(item_key)
            if settings.money_icons then
                tooltip:AddLine('Today: ' .. (market_value and GetCoinTextureString(market_value * quantity) .. ' (' .. gui.percentage_historical(aux.round(market_value / value * 100)) .. ')' or UNKNOWN))
            else
                tooltip:AddLine('Today: ' .. (market_value and money.to_string2(market_value * quantity) .. ' (' .. gui.percentage_historical(aux.round(market_value / value * 100)) .. ')' or UNKNOWN), aux.color.tooltip.value())
            end
        end
    end

--    if tooltip == GameTooltip and game_tooltip_money > 0 then
--        SetTooltipMoney(tooltip, game_tooltip_money)
--    end
    tooltip:Show()
end

-- auxForever: /aux memory detail
function M.memory_counts()
    local n = 0
    for _ in pairs(auctionable_cache) do n = n + 1 end
    return n
end
