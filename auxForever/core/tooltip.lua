select(2, ...) 'aux.core.tooltip'

local aux = require 'aux'
local info = require 'aux.util.info'
local money =  require 'aux.util.money'
local disenchant = require 'aux.core.disenchant'
local history = require 'aux.core.history'
local gui = require 'aux.gui'

local UNKNOWN = GRAY_FONT_COLOR_CODE .. '?' .. FONT_COLOR_CODE_CLOSE

-- Forever: GameTooltip:GetItem() and SetItemKey often drop the random-suffix bonus IDs that
-- C_AuctionHouse item links carry, so the built-in tooltip shows the base item with no +stats.
-- Full auction links still work with GetItemStats; we note those links from AH hover code,
-- remember them by item key after an item search, and re-add missing +stat lines.

local last_link = {}
local last_hover = {}
local retry_tip, retry_link, retry_frames = nil, nil, 0
local inject_announced
local cached_suffix_lines = {}

local function item_string(link)
    return type(link) == 'string' and (strmatch(link, 'item:[%-:%d]+') or link)
end

-- Must be declared before note_hover / cache_suffix_stats (Lua locals are nil above their line).
local function nonempty_stat_lines(lines)
    return lines and #lines > 0 and lines or nil
end

local function prefetch_link(link)
    local item_id = tonumber(strmatch(link or '', 'item:(%-?%d+)'))
    if item_id and C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(item_id)
    end
end

function M.note_link(tooltip, link)
    if tooltip and type(link) == 'string' and strfind(link, 'item:', 1, true)
        and not (issecretvalue and issecretvalue(link)) then
        last_link[tooltip] = link
        last_hover.link = link
        prefetch_link(link)
    end
end

function M.note_hover(record, link)
    last_hover.record = record
    if type(link) == 'string' then
        last_hover.link = link
    elseif record and type(record.link) == 'string' then
        last_hover.link = record.link
    end
    -- Prefetch only; never compute stats here (errors on hover blanked the buy bar).
    if last_hover.link then
        pcall(prefetch_link, last_hover.link)
    end
end

-- Always fill a fresh table. A shared GetItemStats return value keeps leftover keys from the
-- previous item, which made "full link vs base" deltas all zero.
local function copy_stats(link)
    link = item_string(link)
    if not link then
        return
    end
    local t = {}
    local ok, result = pcall(function()
        if GetItemStats then
            return GetItemStats(link, t)
        end
        if C_Item and C_Item.GetItemStats then
            return C_Item.GetItemStats(link, t)
        end
    end)
    if not ok then
        return
    end
    local src = result
    if type(src) ~= 'table' or not next(src) then
        src = t
    end
    if type(src) ~= 'table' then
        return
    end
    local copy = {}
    for k, v in pairs(src) do
        if type(v) == 'number' then
            copy[k] = v
        end
    end
    return next(copy) and copy or nil
end

local function stat_label(key)
    if type(key) ~= 'string' then
        return
    end
    local label = _G[key]
    if type(label) == 'string' and label ~= '' then
        return label
    end
    local short = strmatch(key, '^ITEM_MOD_(.+)_SHORT$') or strmatch(key, '^ITEM_MOD_(.+)$')
    if short then
        return gsub(strlower(short), '_', ' ')
    end
end

local function tooltip_has_label(tooltip, label)
    local name = tooltip:GetName()
    for i = 1, tooltip:NumLines() do
        local fs = _G[name .. 'TextLeft' .. i]
        local text = fs and fs:GetText()
        if type(text) == 'string' and strfind(text, label, 1, true) then
            return true
        end
    end
    return false
end

-- Equip-stat lines missing from the tooltip. Prefer bonus-vs-base deltas; if that yields nothing
-- (shared-table quirks, base equal), fall back to every ITEM_MOD_* on the link not already shown.
function M.suffix_stat_lines(link)
    link = item_string(link)
    if not link then
        return
    end
    local item_id = tonumber(strmatch(link, 'item:(%-?%d+)'))
    if not item_id then
        return
    end
    local with = copy_stats(link)
    if not with then
        return
    end
    local base = copy_stats('item:' .. item_id) or {}
    local lines, seen = {}, {}
    local function add(label, amount)
        if amount and amount > 0 and label and not seen[label] then
            seen[label] = true
            tinsert(lines, { label = label, amount = amount })
        end
    end
    for k, v in pairs(with) do
        if k ~= 'RESISTANCE0_NAME' then
            local label = stat_label(k)
            local delta = v - (base[k] or 0)
            if delta > 0 then
                add(label, delta)
            end
        end
    end
    if #lines == 0 then
        for k, v in pairs(with) do
            if type(k) == 'string' and strfind(k, 'ITEM_MOD_', 1, true) then
                add(stat_label(k), v)
            end
        end
    end
    return nonempty_stat_lines(lines)
end

-- Precomputed +stat lines by item string, filled when search results arrive (not on hover).
function M.cache_suffix_stats(link)
    link = item_string(link)
    if not link then
        return
    end
    local lines = nonempty_stat_lines(M.suffix_stat_lines(link))
    if lines then
        cached_suffix_lines[link] = lines
    end
    return lines
end

local suffix_retry = CreateFrame('Frame')
suffix_retry:Hide()
suffix_retry:SetScript('OnUpdate', function(self)
    if retry_tip and retry_tip:IsShown() then
        local ok, added = pcall(M.add_suffix_stats, retry_tip, retry_link)
        if ok and added then
            retry_tip:Show()
            retry_frames = 0
        end
    end
    retry_frames = retry_frames - 1
    if retry_frames <= 0 then
        self:Hide()
    end
end)

-- Returns true when at least one line was added. Does not Show(): callers must Show, because a
-- mid-extend Show() on Forever can drop later AddLines (disenchant / value).
function M.add_suffix_stats(tooltip, link)
    link = item_string(link or last_link[tooltip])
    if not tooltip or not link or (tooltip.IsForbidden and tooltip:IsForbidden()) then
        return false
    end
    if tooltip:NumLines() < 1 then
        return false
    end
    -- Empty tables from an early (failed) cache must not block a later GetItemStats retry.
    local lines = nonempty_stat_lines(cached_suffix_lines[link])
        or nonempty_stat_lines(last_hover.record and last_hover.record.suffix_stats)
        or M.suffix_stat_lines(link)
    if lines then
        cached_suffix_lines[link] = lines
        if last_hover.record then
            last_hover.record.suffix_stats = lines
        end
    else
        return false
    end
    local added = false
    for _, entry in ipairs(lines) do
        if not tooltip_has_label(tooltip, entry.label) then
            tooltip:AddLine(format('+%d %s', entry.amount, entry.label), 0, 1, 0)
            added = true
        end
    end
    if added and not inject_announced then
        inject_announced = true
        aux.print('Suffix stats: added +stat lines to the tooltip (this message once).')
    end
    return added
end

-- Hover path: only a remembered auction link (never synthetic GetItemStats trials).
function M.link_for_item_key(item_key)
    if type(item_key) ~= 'table' or not item_key.itemID then
        return
    end
    local suffix = item_key.itemSuffix or 0
    if suffix == 0 then
        return
    end
    return info.suffix_link_for(item_key.itemID, suffix)
end

function M.schedule_suffix_stats(tooltip, link)
    if not tooltip then
        return
    end
    if link then
        M.note_link(tooltip, link)
    end
    retry_tip = tooltip
    retry_link = link or last_link[tooltip]
    retry_frames = 8
    suffix_retry:Show()
end

-- /aux suffix: dump the last hovered AH link and whether GetItemStats sees bonus stats
function M.suffix_report()
    local link = last_hover.link or last_link[GameTooltip]
    local lines_out = {}
    if not link then
        tinsert(lines_out, 'No AH item hovered yet. Hover an auction icon, then run /aux suffix.')
        return lines_out
    end
    tinsert(lines_out, 'link=' .. gsub(link, '|', '||'))
    local stats = copy_stats(link)
    if not stats then
        tinsert(lines_out, 'GetItemStats: nil (link not usable)')
    else
        local parts = {}
        for k, v in pairs(stats) do
            tinsert(parts, format('%s=%s', tostring(stat_label(k) or k), tostring(v)))
        end
        sort(parts)
        tinsert(lines_out, 'GetItemStats: ' .. (#parts > 0 and table.concat(parts, ', ') or '(empty)'))
    end
    local bonus = M.suffix_stat_lines(link)
    if not bonus or #bonus == 0 then
        tinsert(lines_out, 'bonus lines: none (no ITEM_MOD delta vs base)')
    else
        local parts = {}
        for _, e in ipairs(bonus) do
            tinsert(parts, format('+%d %s', e.amount, e.label))
        end
        tinsert(lines_out, 'bonus lines: ' .. table.concat(parts, ', '))
    end
    if GameTooltip:IsShown() then
        local added = M.add_suffix_stats(GameTooltip, link)
        tinsert(lines_out, added and 're-injected into the open tooltip' or 'open tooltip unchanged (already shown or nothing to add)')
    end
    return lines_out
end

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
        link = last_link[tooltip] or link or data and data.hyperlink
        if type(link) ~= 'string' or (issecretvalue and issecretvalue(link)) or not strfind(link, 'item:') then
            return
        end
        extend_tooltip(tooltip, link, tooltip_quantity(tooltip))
        pcall(M.schedule_suffix_stats, tooltip, link)
    end)
    aux.event_listener('GET_ITEM_INFO_RECEIVED', function(item_id, success)
        if not success then
            return
        end
        local link = retry_link or last_hover.link
        local link_id = link and tonumber(strmatch(link, 'item:(%-?%d+)'))
        if link_id and link_id == item_id then
            M.cache_suffix_stats(link)
            if retry_tip and retry_tip:IsShown() then
                if pcall(M.add_suffix_stats, retry_tip, link) then
                    retry_tip:Show()
                end
            end
        end
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
    -- auxForever (0.5): with Shift held the prices are for the whole stack; say so ("for 3"). In build
    -- 1 a stack's Value read as a far too high price per item (Windows' screenshot keys hold Shift).
    local per = quantity > 1 and ('  ' .. aux.color.label.enabled('for ' .. quantity)) or ''
    local item_info = info.item(item_id)
    -- auxForever: the disenchant table is only worked out when one of its lines is shown.
    -- Skip white/gray (and shirts): they cannot be disenchanted.
    if item_info and (settings.disenchant_distribution or settings.disenchant_value)
        and (item_info.quality or 0) >= 2 then
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
                tooltip:AddLine('Vendor Buy ' .. (limited and '(limited): ' or ': ') .. GetCoinTextureString(price * quantity) .. per, aux.color.tooltip.merchant())
            else
                tooltip:AddLine('Vendor Buy ' .. (limited and '(limited): ' or ': ') .. money.to_string2(price * quantity) .. per, aux.color.tooltip.merchant())
            end
        end
    end
    if settings.merchant_sell then
        local price = item_info and item_info.sell_price
        if price ~= 0 then
            if settings.money_icons then
                tooltip:AddLine('Vendor: ' .. (price and GetCoinTextureString(price * quantity) .. per or UNKNOWN), aux.color.tooltip.merchant())
            else
                tooltip:AddLine('Vendor: ' .. (price and money.to_string2(price * quantity) .. per or UNKNOWN), aux.color.tooltip.merchant())
            end
        end
    end
    local auctionable = not item_info or is_auctionable(item_id, item_info)
    local item_key = (item_id or 0) .. ':' .. (suffix_id or 0)
    -- auxForever (0.5, build 3): Value is the latest look at the item (what players just saw at the
    -- auction house); the multi-day usual price shows under it only when the two differ a lot
    local latest, age = history.latest(item_key)
    local value = history.value(item_key)
    if auctionable then
        if settings.value then
            local function coins(amount)
                return settings.money_icons and GetCoinTextureString(amount) or money.to_string2(amount)
            end
            tooltip:AddLine('Value: ' .. (latest and coins(latest * quantity) .. per .. age_suffix(age) or UNKNOWN), aux.color.tooltip.value())
            if history.usually_differs(latest, value) then
                tooltip:AddLine('  ' .. aux.color.label.enabled('usually ') .. coins(value * quantity), aux.color.label.enabled())
            end
        end
        if settings.daily  then
            local market_value = history.market_value(item_key)
            if settings.money_icons then
                tooltip:AddLine('Today: ' .. (market_value and GetCoinTextureString(market_value * quantity) .. per .. ' (' .. gui.percentage_historical(aux.round(market_value / value * 100)) .. ')' or UNKNOWN))
            else
                tooltip:AddLine('Today: ' .. (market_value and money.to_string2(market_value * quantity) .. per .. ' (' .. gui.percentage_historical(aux.round(market_value / value * 100)) .. ')' or UNKNOWN), aux.color.tooltip.value())
            end
        end
    end

--    if tooltip == GameTooltip and game_tooltip_money > 0 then
--        SetTooltipMoney(tooltip, game_tooltip_money)
--    end
    -- Forever: suffix +stats after Value/DE so a failed GetItemStats cannot skip those lines,
    -- and without an extra Show() that would drop them on this client.
    pcall(M.add_suffix_stats, tooltip, link)
    tooltip:Show()
end

-- auxForever: /aux memory detail
function M.memory_counts()
    local n = 0
    for _ in pairs(auctionable_cache) do n = n + 1 end
    return n
end
