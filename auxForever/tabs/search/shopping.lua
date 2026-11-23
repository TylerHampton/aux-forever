select(2, ...) 'aux.tabs.search'

local aux = require 'aux'
local info = require 'aux.util.info'
local money = require 'aux.util.money'
local inventory = require 'aux.core.inventory'
local gui = require 'aux.gui'
local listing = require 'aux.gui.listing'
local buy_bar = require 'aux.gui.buy_bar'

-- auxForever (0.9.1, FB-023, Kortan; Tyler 2026-11-22: Option A 4th Search sub-tab, direct
-- recipe reagents, opens automatically from Professions "Search in aux" / Alt-click, opt-in alt
-- inventory off by default):
-- Turns any recipe search into a Shopping List with Craft count, Have (bags + optional alts +
-- items bought this AH visit), Need, Vendor vs AH comparison, multi-tier AH cost, and 1-click
-- buying via the shared buy bar with auto-advance to the next unbought AH material.
-- No OnUpdate handler: updates only on scan updates, clicks, craft count changes, and bag events.

local SUMMARY_HEIGHT = 28
local HEADER_HEIGHT = 56
local ROW_HEIGHT = 26
local MAX_CRAFTS = 999
local GAP = '   '

local shopping_search
local shopping_filter
local craft_count = 1
local selected_item_id
local current_plan
local shopping_bought = {}

local function plain_money(amount, color)
    return money.to_string(amount, true, nil, color)
end

local function same_recipe(a, b)
    if not a or not b then
        return false
    end
    if a.recipe_id and b.recipe_id then
        return a.recipe_id == b.recipe_id
    end
    return a.name and b.name and a.name == b.name
end

-- Cost of the cheapest `need` units across sorted commodity tiers:
-- returns total, covered, available, min_unit, max_unit
function M.shopping_tier_cost(tiers, need)
    local total, covered, available, min_unit, max_unit = 0, 0, 0, nil, nil
    local remaining = max(0, need or 0)
    for _, tier in ipairs(tiers or empty) do
        local count = tier.count or 0
        local price = tier.commodity_unit_price or tier.unit_buyout_price or 0
        if count > 0 and price > 0 then
            if not min_unit then
                min_unit = price
            end
            available = available + count
            if remaining > 0 then
                local taken = min(remaining, count)
                total = total + taken * price
                covered = covered + taken
                max_unit = price
                remaining = remaining - taken
            end
        end
    end
    return total, covered, available, min_unit, max_unit
end

-- Buyable non-commodity auctions for an item in a search, cheapest unit buyout first
function M.shopping_item_auctions(search, item_id)
    local auctions = {}
    for _, record in ipairs(search and search.records or empty) do
        if not record.commodity and not record.fast and record.item_id == item_id
                and not record.own and not info.is_player(record.owner)
                and (record.buyout_price or 0) > 0 then
            tinsert(auctions, record)
        end
    end
    sort(auctions, function(a, b)
        if a.unit_buyout_price ~= b.unit_buyout_price then
            return a.unit_buyout_price < b.unit_buyout_price
        end
        return (a.buyout_price or 0) < (b.buyout_price or 0)
    end)
    return auctions
end

local function item_auctions_cost(auctions, need)
    local total, covered, available, min_unit, max_unit = 0, 0, 0, nil, nil
    local remaining = max(0, need or 0)
    for _, record in ipairs(auctions or empty) do
        local count = max(1, record.auction_count or 1) * max(1, record.count or 1)
        local unit = ceil(record.unit_buyout_price or record.buyout_price or 0)
        if unit > 0 then
            if not min_unit then
                min_unit = unit
            end
            available = available + count
            if remaining > 0 then
                local taken = min(remaining, count)
                total = total + taken * unit
                covered = covered + taken
                max_unit = unit
                remaining = remaining - taken
            end
        end
    end
    return total, covered, available, min_unit, max_unit
end

-- Pure shopping calculation for a recipe: merges duplicate reagent IDs, applies Have/Need,
-- compares unlimited vendor vs AH multi-tier cost, and computes both "still to buy" and full
-- batch craft cost / profit.
function M.shopping_plan(parts, search, count, include_alts, bought_map)
    count = max(1, min(MAX_CRAFTS, floor(tonumber(count) or 1)))
    include_alts = include_alts and inventory.is_enabled() and true or false
    bought_map = bought_map or empty

    local merged, order = {}, {}
    for _, part in ipairs(parts and parts.reagents or empty) do
        local id = part.item_id
        if id then
            if merged[id] then
                merged[id].per_craft = merged[id].per_craft + (part.count or 1)
            else
                merged[id] = {item_id = id, per_craft = part.count or 1}
                tinsert(order, id)
            end
        end
    end

    local plan = {
        recipe = parts,
        craft_count = count,
        include_alts = include_alts,
        rows = {},
        ah_cost = 0,
        vendor_cost = 0,
        still_to_buy = 0,
        ah_remaining = 0,
        vendor_remaining = 0,
        missing_count = 0,
        short_count = 0,
        done_count = 0,
        full_cost = 0,
        full_missing = 0,
        sell_net = nil,
    }

    local scanning = search and search.active and true or false

    for _, item_id in ipairs(order) do
        local spec = merged[item_id]
        local item_info = info.item(item_id)
        local required = spec.per_craft * count
        local self_bags, extra_have, entries, account_bank = inventory.shopping_counts(item_id, include_alts)
        local bought_now = max(0, bought_map[item_id] or 0)
        local have = self_bags + extra_have + bought_now
        local need = max(0, required - have)

        local tiers = search and commodity_tiers_of(search, item_id) or {}
        local auctions = #tiers == 0 and shopping_item_auctions(search, item_id) or {}
        local is_commodity = #tiers > 0

        local ah_total, ah_covered, ah_available, ah_min_unit, ah_max_unit
        if is_commodity then
            ah_total, ah_covered, ah_available, ah_min_unit, ah_max_unit = shopping_tier_cost(tiers, need)
        else
            ah_total, ah_covered, ah_available, ah_min_unit, ah_max_unit = item_auctions_cost(auctions, need)
        end

        local vendor_unit, vendor_limited = info.merchant_buy_info(item_id)
        local vendor_reliable = vendor_unit and not vendor_limited and true or false
        local vendor_total = vendor_reliable and (ceil(vendor_unit) * need) or nil

        -- Full batch craft cost (all `required` units, independent of owned stock)
        local full_ah_total, full_ah_cov, full_ah_avail, full_ah_min
        if is_commodity then
            full_ah_total, full_ah_cov, full_ah_avail, full_ah_min = shopping_tier_cost(tiers, required)
        else
            full_ah_total, full_ah_cov, full_ah_avail, full_ah_min = item_auctions_cost(auctions, required)
        end
        local full_ah_est = full_ah_avail > 0 and (full_ah_cov >= required and full_ah_total or (full_ah_min and ceil(full_ah_min) * required)) or nil
        local full_vendor = vendor_reliable and (ceil(vendor_unit) * required) or nil
        if full_vendor and (not full_ah_est or full_vendor <= full_ah_est) then
            plan.full_cost = plan.full_cost + full_vendor
        elseif full_ah_est then
            plan.full_cost = plan.full_cost + full_ah_est
        else
            plan.full_missing = plan.full_missing + 1
        end

        local best_source, unit_price, buy_total, short, vendor_saves = 'missing', nil, 0, false, nil
        if need == 0 then
            best_source = 'done'
            plan.done_count = plan.done_count + 1
        else
            local ah_avg = ah_covered > 0 and (ah_total / ah_covered) or nil
            local vendor_wins = false
            if vendor_reliable then
                if ah_available == 0 then
                    vendor_wins = true
                elseif ah_covered >= need then
                    vendor_wins = vendor_total <= ah_total
                elseif ah_avg then
                    vendor_wins = ceil(vendor_unit) <= ah_avg
                end
            end

            if vendor_wins then
                best_source = 'vendor'
                unit_price = ceil(vendor_unit)
                buy_total = vendor_total
                if ah_covered >= need and ah_total > vendor_total then
                    vendor_saves = ah_total - vendor_total
                elseif ah_min_unit and ceil(ah_min_unit) > unit_price then
                    vendor_saves = (ceil(ah_min_unit) - unit_price) * need
                end
                plan.vendor_cost = plan.vendor_cost + buy_total
                plan.vendor_remaining = plan.vendor_remaining + 1
            elseif ah_available > 0 then
                best_source = 'ah'
                unit_price = ah_covered > 0 and ceil(ah_total / ah_covered) or (ah_min_unit and ceil(ah_min_unit))
                buy_total = ah_total
                short = ah_covered < need
                plan.ah_cost = plan.ah_cost + buy_total
                plan.ah_remaining = plan.ah_remaining + 1
                if short then
                    plan.short_count = plan.short_count + 1
                end
            elseif scanning then
                best_source = 'scanning'
            else
                best_source = 'missing'
                plan.missing_count = plan.missing_count + 1
            end
        end

        local row = {
            item_id = item_id,
            name = item_info and item_info.name or ('item ' .. item_id),
            texture = item_info and item_info.texture,
            quality = item_info and item_info.quality or 1,
            max_stack = item_info and item_info.max_stack or 1,
            per_craft = spec.per_craft,
            required = required,
            self_bags = self_bags,
            extra_have = extra_have,
            bought_now = bought_now,
            have = have,
            need = need,
            entries = entries,
            account_bank = account_bank,
            is_commodity = is_commodity,
            tiers = tiers,
            auctions = auctions,
            ah_available = ah_available,
            ah_covered = ah_covered,
            ah_total = ah_total,
            ah_min_unit = ah_min_unit,
            ah_max_unit = ah_max_unit,
            vendor_unit = vendor_unit,
            vendor_limited = vendor_limited,
            vendor_reliable = vendor_reliable,
            vendor_saves = vendor_saves,
            best_source = best_source,
            unit_price = unit_price,
            buy_total = buy_total,
            short = short,
        }
        tinsert(plan.rows, row)
    end

    plan.still_to_buy = plan.ah_cost + plan.vendor_cost

    if parts and parts.output then
        local out_id = parts.output.item_id
        local cheapest
        for _, record in ipairs(search and search.records or empty) do
            if record.item_id == out_id and not record.own and (record.buyout_price or 0) > 0 then
                if not cheapest or record.unit_buyout_price < cheapest then
                    cheapest = record.unit_buyout_price
                end
            end
        end
        if cheapest then
            plan.sell_unit = ceil(cheapest)
            plan.sell_net = floor(plan.sell_unit * (parts.output.count or 1) * count * (1 - aux.AUCTION_CUT))
        end
    end

    return plan
end

-- UI widgets inside frame.shopping
local header, icon_tex, title_label, subtitle_label
local craft_label, minus_button, craft_input, plus_button
local alt_switch, alt_label, alt_hint_label, refresh_button
local list_frame, shopping_listing, summary_bar, totals_left, totals_right
local empty_panel, empty_title, empty_body, last_recipe_button
local clear_button

local col_info = {
    {name = 'Material', width = .30, align = 'LEFT', headAlign = 'LEFT'},
    {name = 'For 1', width = .08, align = 'RIGHT', headAlign = 'RIGHT'},
    {name = 'Have', width = .12, align = 'RIGHT', headAlign = 'RIGHT'},
    {name = 'Need', width = .08, align = 'RIGHT', headAlign = 'RIGHT'},
    {name = 'Best source', width = .14, align = 'CENTER', headAlign = 'CENTER'},
    {name = 'Unit price', width = .13, align = 'RIGHT', headAlign = 'RIGHT'},
    {name = 'Total to buy', width = .15, align = 'RIGHT', headAlign = 'RIGHT'},
}

local function find_row(item_id)
    if not current_plan or not item_id then
        return nil
    end
    for _, row in ipairs(current_plan.rows) do
        if row.item_id == item_id then
            return row
        end
    end
    return nil
end

local function pick_next_ah_row(plan, after_item_id)
    if not plan then
        return nil
    end
    local seen_after = not after_item_id
    local first_ah
    for _, row in ipairs(plan.rows) do
        if row.need > 0 and row.best_source == 'ah' then
            if not first_ah then
                first_ah = row
            end
            if seen_after and row.item_id ~= after_item_id then
                return row
            end
        end
        if row.item_id == after_item_id then
            seen_after = true
        end
    end
    return first_ah
end

local function format_places(entry)
    local parts = {}
    if entry.bags > 0 then tinsert(parts, entry.bags .. ' bags') end
    if entry.bank > 0 then tinsert(parts, entry.bank .. ' bank') end
    if entry.mail > 0 then tinsert(parts, entry.mail .. ' mail') end
    return table.concat(parts, ', ')
end

local function after_purchase(item_id)
    if not shopping_search or not shopping_search.recipe then
        return
    end
    local include_alts = aux.account_data and aux.account_data.shopping_count_alts and true or false
    current_plan = shopping_plan(shopping_search.recipe, shopping_search, craft_count, include_alts, shopping_bought)
    local bought_row = find_row(item_id)
    if bought_row and bought_row.need == 0 then
        local next_row = pick_next_ah_row(current_plan, item_id)
        if next_row then
            selected_item_id = next_row.item_id
        end
    end
    refresh_shopping_list(true, true)
end

local function load_row_into_buy_bar(row, keep_message)
    if not (frame.shopping and frame.shopping:IsShown()) then
        return
    end
    if not row or not shopping_search then
        if keep_message then
            buy_bar.clear_keeping_message()
        else
            buy_bar.show_note('Shopping List', 'Open your Professions window and click "Search in aux", or Alt-click a recipe.')
        end
        return
    end

    if row.best_source == 'scanning' then
        buy_bar.show_note(row.name, 'Reading auction house listings...')
        return
    end

    -- Inform, never refuse: even if a vendor is cheaper or the player already has enough, if AH
    -- listings exist we load them into the buy bar with a clear note while keeping Buy clickable.
    local note
    if row.best_source == 'vendor' and row.ah_available > 0 then
        local line2 = row.vendor_saves and ('You save ' .. plain_money(row.vendor_saves) .. ' at a vendor, or buy on AH here')
            or 'Cheaper from a vendor, or buy on AH here'
        note = {'Cheaper at a vendor (' .. plain_money(ceil(row.vendor_unit)) .. ' each)', line2, aux.color.yellow}
    elseif row.need == 0 and row.ah_available > 0 then
        note = {'Already have enough for ' .. craft_count .. (craft_count == 1 and ' craft' or ' crafts'), 'You can still buy more here if you want', aux.color.green}
    elseif row.short then
        note = {'Only ' .. row.ah_available .. ' listed (need ' .. row.need .. ')', 'Pre-filled to all ' .. row.ah_available .. ' available', aux.color.yellow}
    end

    if row.is_commodity and row.ah_available > 0 then
        local item_id = row.item_id
        buy_bar.show_commodity{
            item_id = item_id,
            name = row.name,
            texture = row.texture,
            quality = row.quality,
            max_stack = row.max_stack,
            start_quantity = row.need > 0 and row.need or 1,
            note = note,
            keep_message = keep_message,
            tiers = function() return commodity_tiers_of(shopping_search, item_id) end,
            on_success = function(n)
                consume_commodity_of(shopping_search, item_id, n)
                shopping_bought[item_id] = (shopping_bought[item_id] or 0) + n
                after_purchase(item_id)
            end,
            on_refresh = function()
                refresh_commodity_of(shopping_search, item_id)
            end,
        }
    elseif #row.auctions > 0 then
        local item_id = row.item_id
        local record = row.auctions[1]
        buy_bar.show_item{
            record = record,
            name = row.name,
            texture = row.texture or record.texture,
            quality = row.quality or record.quality,
            own = info.is_player(record.owner) or record.own,
            note = note,
            keep_message = keep_message,
            busy = function()
                return record.syncing or aux.bid_in_progress() or not shopping_search.table:ContainsRecord(record)
            end,
            on_buy = function(on_bought)
                aux.place_bid(record.auction_id, record.buyout_price, function()
                    do (on_bought or pass)() end
                    shopping_bought[item_id] = (shopping_bought[item_id] or 0) + max(1, record.count or 1)
                    sync_bucket_of(shopping_search, record)
                    after_purchase(item_id)
                end, purchase_failure_of(shopping_search, record))
            end,
            on_bid = function()
                aux.place_bid(record.auction_id, record.bid_price, function()
                    if record.auction_count and record.auction_count > 1 then
                        sync_bucket_of(shopping_search, record)
                    elseif record.bid_price < record.buyout_price then
                        info.bid_update(record)
                        shopping_search.table:SetDatabase()
                    else
                        remove_record_of(shopping_search, record)
                    end
                end, purchase_failure_of(shopping_search, record))
            end,
        }
    elseif keep_message then
        buy_bar.clear_keeping_message()
    elseif row.best_source == 'vendor' then
        buy_bar.show_note(row.name, 'Buy ' .. row.need .. ' from a vendor for ' .. plain_money(row.buy_total) .. ' (' .. plain_money(row.unit_price) .. ' each)', aux.color.green)
    elseif row.need == 0 then
        buy_bar.show_note(row.name, 'You already have enough for ' .. craft_count .. (craft_count == 1 and ' craft' or ' crafts'), aux.color.green)
    else
        buy_bar.show_note(row.name, 'Not listed on the auction house right now', aux.color.red)
    end
end

local function update_subtab_badge()
    if not shopping_list_button then
        return
    end
    local n = current_plan and current_plan.ah_remaining or 0
    shopping_list_button:SetText(n > 0 and ('Shopping List  ' .. aux.color.accent.background(tostring(n))) or 'Shopping List')
end

local function last_saved_recipe()
    for _, list in ipairs{recent_searches or empty, favorite_searches or empty} do
        for _, entry in ipairs(list) do
            if entry.recipe and not entry.recipe.crate then
                return entry
            end
        end
    end
    return nil
end

local function color_item_name(row)
    local q = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[row.quality or 1]
    local icon_str = row.texture and ('|T' .. row.texture .. ':16:16:0:0:64:64:4:60:4:60|t  ') or ''
    if q and q.hex then
        return icon_str .. q.hex .. row.name .. FONT_COLOR_CODE_CLOSE
    end
    return icon_str .. row.name
end

local function format_have_cell(row)
    if row.have == 0 then
        return aux.color.label.disabled('0')
    end
    local tags = {}
    if row.extra_have > 0 then
        tinsert(tags, '+' .. row.extra_have .. ' saved')
    end
    if row.bought_now > 0 then
        tinsert(tags, '+' .. row.bought_now .. ' bought')
    end
    if #tags > 0 then
        return row.have .. ' ' .. aux.color.label.enabled('(' .. table.concat(tags, ', ') .. ')')
    end
    return tostring(row.have)
end

local function format_source_cell(row)
    if row.best_source == 'done' then
        return aux.color.green('Ready')
    elseif row.best_source == 'scanning' then
        return aux.color.label.enabled('Scanning...')
    elseif row.best_source == 'vendor' then
        return aux.color.green('Vendor')
    elseif row.best_source == 'ah' then
        if row.short then
            return aux.color.yellow('AH (only ' .. row.ah_available .. ')')
        end
        return aux.color.accent.background('AH')
    end
    return aux.color.red('Not listed')
end

local function render_header(plan)
    local parts = plan.recipe
    local out_info = parts.output and info.item(parts.output.item_id)
    local first_info = parts.reagents and parts.reagents[1] and info.item(parts.reagents[1].item_id)
    icon_tex:SetTexture((out_info and out_info.texture) or (first_info and first_info.texture) or [[Interface\Icons\INV_Misc_QuestionMark]])

    local title = parts.name or 'Recipe'
    if parts.output and (parts.output.count or 1) > 1 then
        title = title .. '  ' .. aux.color.label.enabled('(makes ' .. parts.output.count .. ' per craft)')
    end
    title_label:SetText(title)

    local sub = 'Full ' .. plan.craft_count .. (plan.craft_count == 1 and ' craft: ' or ' crafts: ')
    if #plan.rows > 0 and plan.full_missing == #plan.rows then
        sub = sub .. aux.color.label.disabled(shopping_search and shopping_search.active and 'scanning...' or 'no prices yet')
    else
        sub = sub .. plain_money(plan.full_cost) .. (plan.full_missing > 0 and aux.color.label.disabled('+') or '')
        if parts.output then
            if plan.sell_net then
                sub = sub .. GAP .. 'Sells ' .. plain_money(plan.sell_net) .. ' after cut' .. GAP
                if plan.sell_net >= plan.full_cost then
                    sub = sub .. aux.color.green(plan.full_missing > 0 and 'Profit at most ' or 'Profit ') .. plain_money(plan.sell_net - plan.full_cost, aux.color.green)
                else
                    sub = sub .. aux.color.red(plan.full_missing > 0 and 'Loss at least ' or 'Loss ') .. plain_money(plan.full_cost - plan.sell_net, aux.color.red)
                end
            else
                sub = sub .. GAP .. aux.color.label.disabled('none listed to sell')
            end
        end
    end
    subtitle_label:SetText(sub)

    local count_text = tostring(craft_count)
    if craft_input:GetText() ~= count_text then
        craft_input:SetText(count_text)
        craft_input.overlay:SetText(craft_input.formatter(count_text))
    end
    if craft_count <= 1 then minus_button:Disable() else minus_button:Enable() end
    if craft_count >= MAX_CRAFTS then plus_button:Disable() else plus_button:Enable() end

    local include_alts = aux.account_data and aux.account_data.shopping_count_alts and true or false
    alt_switch:SetChecked(include_alts)
    if include_alts then
        local n = inventory.character_count()
        alt_hint_label:SetText('(' .. n .. (n == 1 and ' char)' or ' chars)'))
    else
        alt_hint_label:SetText('(off)')
    end
end

local function render_summary(plan)
    if plan.still_to_buy == 0 and plan.missing_count == 0 and not (shopping_search and shopping_search.active) then
        totals_left:SetText(aux.color.green('Everything ready for ' .. plan.craft_count .. (plan.craft_count == 1 and ' craft' or ' crafts')))
    else
        local breakdown = {}
        if plan.ah_cost > 0 then tinsert(breakdown, 'AH ' .. plain_money(plan.ah_cost)) end
        if plan.vendor_cost > 0 then tinsert(breakdown, 'Vendor ' .. plain_money(plan.vendor_cost)) end
        local text = 'Still to buy: ' .. plain_money(plan.still_to_buy)
        if #breakdown > 0 then
            text = text .. '  ' .. aux.color.label.enabled('(' .. table.concat(breakdown, ', ') .. ')')
        end
        if plan.missing_count > 0 then
            text = text .. '  ' .. aux.color.red('+ ' .. plan.missing_count .. ' not listed')
        end
        totals_left:SetText(text)
    end

    if shopping_search and shopping_search.active then
        totals_right:SetText(aux.color.label.enabled('Reading live AH prices...'))
    elseif plan.ah_remaining > 0 then
        totals_right:SetText(aux.color.accent.background(plan.ah_remaining .. (plan.ah_remaining == 1 and ' AH material left' or ' AH materials left')))
    elseif plan.missing_count > 0 then
        totals_right:SetText(aux.color.red(plan.missing_count .. (plan.missing_count == 1 and ' material not listed' or ' materials not listed')))
    elseif plan.vendor_remaining > 0 then
        totals_right:SetText(aux.color.green('All AH materials ready (' .. plan.vendor_remaining .. ' from vendor)'))
    else
        totals_right:SetText(aux.color.green('All materials ready'))
    end
end

function M.refresh_shopping_list(force_bar, keep_message)
    if not shopping_search or not shopping_search.recipe then
        current_plan = nil
        header:Hide()
        list_frame:Hide()
        summary_bar:Hide()
        empty_panel:Show()
        local last = last_saved_recipe()
        if last then
            last_recipe_button:SetText('Load last recipe: ' .. (last.recipe.name or '?'))
            last_recipe_button:SetWidth(max(180, last_recipe_button:GetFontString():GetStringWidth() + 28))
            last_recipe_button:Show()
        else
            last_recipe_button:Hide()
        end
        update_subtab_badge()
        if force_bar and frame.shopping and frame.shopping:IsShown() then
            load_row_into_buy_bar(nil, keep_message)
        end
        update_done()
        update_results_summary(true)
        return
    end

    empty_panel:Hide()
    header:Show()
    list_frame:Show()
    summary_bar:Show()

    local include_alts = aux.account_data and aux.account_data.shopping_count_alts and true or false
    current_plan = shopping_plan(shopping_search.recipe, shopping_search, craft_count, include_alts, shopping_bought)

    col_info[2].name = 'For ' .. craft_count
    shopping_listing:SetColInfo(col_info)

    local rows = {}
    for _, row in ipairs(current_plan.rows) do
        local need_text = row.need == 0 and aux.color.green('Done') or tostring(row.need)
        local unit_text = row.unit_price and plain_money(row.unit_price) or aux.color.label.disabled('-')
        local total_text
        if row.need == 0 or row.best_source == 'scanning' or row.best_source == 'missing' then
            total_text = aux.color.label.disabled('-')
        elseif row.short then
            total_text = plain_money(row.buy_total) .. aux.color.yellow('+')
        else
            total_text = plain_money(row.buy_total)
        end
        tinsert(rows, {
            row = row,
            cols = {
                {value = color_item_name(row)},
                {value = tostring(row.required)},
                {value = format_have_cell(row)},
                {value = need_text},
                {value = format_source_cell(row)},
                {value = unit_text},
                {value = total_text},
            },
        })
    end

    -- Keep selection valid; auto-pick first unbought AH material once listings are available
    local chosen = find_row(selected_item_id)
    if not chosen then
        chosen = pick_next_ah_row(current_plan) or current_plan.rows[1]
        selected_item_id = chosen and chosen.item_id or nil
    end

    render_header(current_plan)
    render_summary(current_plan)
    shopping_listing:SetData(rows)
    update_subtab_badge()

    if frame.shopping and frame.shopping:IsShown() and (force_bar or not buy_bar.busy()) then
        load_row_into_buy_bar(chosen, keep_message)
    end
    update_done()
    update_results_summary(true)
end

function M.load_shopping_search(search)
    if not search or not search.recipe or search.recipe.crate then
        return
    end
    local prev_recipe = shopping_search and shopping_search.recipe
    if not same_recipe(prev_recipe, search.recipe) then
        craft_count = 1
        aux.wipe(shopping_bought)
        selected_item_id = nil
    end
    shopping_search = search
    shopping_filter = search.filter_string
    refresh_shopping_list(true)
end

function M.on_shopping_search_update(search, done)
    if not shopping_search or search ~= shopping_search then
        return
    end
    if done then
        -- After a search completes, auto-select the first unbought AH material if the current
        -- selection is not an actionable AH row (e.g., it was scanning before)
        local include_alts = aux.account_data and aux.account_data.shopping_count_alts and true or false
        local plan = shopping_plan(shopping_search.recipe, shopping_search, craft_count, include_alts, shopping_bought)
        local chosen = selected_item_id and nil
        if selected_item_id then
            for _, row in ipairs(plan.rows) do
                if row.item_id == selected_item_id then
                    chosen = row
                    break
                end
            end
        end
        if not chosen or (chosen.best_source ~= 'ah' and plan.ah_remaining > 0) then
            local next_ah = pick_next_ah_row(plan)
            if next_ah then
                selected_item_id = next_ah.item_id
            end
        end
    end
    refresh_shopping_list(done)
end

function M.set_shopping_craft_count(n)
    n = max(1, min(MAX_CRAFTS, floor(tonumber(n) or 1)))
    if n == craft_count then
        return craft_count
    end
    craft_count = n
    refresh_shopping_list(true)
    return craft_count
end

function M.clear_shopping_list()
    shopping_search = nil
    shopping_filter = nil
    current_plan = nil
    selected_item_id = nil
    craft_count = 1
    aux.wipe(shopping_bought)
    refresh_shopping_list(true)
end

function M.shopping_search_complete()
    return shopping_search and shopping_search.complete and true or false
end

function M.shopping_status_text()
    if not shopping_search or not shopping_search.recipe then
        return ''
    end
    if shopping_search.active then
        return 'Reading live AH prices...'
    end
    if shopping_search.complete and shopping_search.completed_at then
        return 'Live AH prices read ' .. time_ago(shopping_search.completed_at)
    end
    return ''
end

function M.shopping_state()
    return shopping_search, craft_count, selected_item_id, current_plan, shopping_bought
end

-- Build the Shopping List sub-tab layout inside frame.shopping (created in frame.lua)
do
    local root = frame.shopping

    header = CreateFrame('Frame', nil, root)
    header:SetPoint('TOPLEFT', 0, 0)
    header:SetPoint('TOPRIGHT', 0, 0)
    header:SetHeight(HEADER_HEIGHT)
    local h_edge = header:CreateTexture(nil, 'BORDER')
    gui.texture_color(h_edge, aux.color.window.border)
    h_edge:SetPoint('BOTTOMLEFT')
    h_edge:SetPoint('BOTTOMRIGHT')
    h_edge:SetHeight(1)

    local icon_frame = CreateFrame('Frame', nil, header, 'BackdropTemplate')
    gui.set_well_style(icon_frame)
    gui.set_size(icon_frame, 36, 36)
    icon_frame:SetPoint('LEFT', 10, 0)
    icon_tex = icon_frame:CreateTexture(nil, 'ARTWORK')
    icon_tex:SetPoint('TOPLEFT', 2, -2)
    icon_tex:SetPoint('BOTTOMRIGHT', -2, 2)
    icon_tex:SetTexCoord(.08, .92, .08, .92)

    -- Right-side controls anchored right to left so nothing crowds or overlaps at 1000px width
    refresh_button = gui.button(header, gui.font_size.small)
    gui.set_size(refresh_button, 104, 24)
    refresh_button:SetPoint('RIGHT', -10, 0)
    refresh_button:SetText('Refresh prices')
    refresh_button:SetScript('OnClick', function()
        if shopping_search and shopping_search.recipe then
            if shopping_filter and shopping_filter ~= '' then
                set_filter(shopping_filter)
                execute(nil, false)
            elseif shopping_search.recipe.recipe_id then
                search_recipe(shopping_search.recipe.recipe_id)
            end
        end
    end)

    alt_hint_label = gui.label(header, gui.font_size.small)
    alt_hint_label:SetPoint('RIGHT', refresh_button, 'LEFT', -10, 0)
    gui.text_color(alt_hint_label, aux.color.label.disabled)
    alt_hint_label:SetText('(off)')

    alt_label = gui.label(header, gui.font_size.small)
    alt_label:SetPoint('RIGHT', alt_hint_label, 'LEFT', -4, 0)
    gui.text_color(alt_label, aux.color.text.enabled)
    alt_label:SetText('Count alts')

    alt_switch = gui.switch(header)
    alt_switch:SetPoint('RIGHT', alt_label, 'LEFT', -6, 0)
    alt_switch.on_click = function()
        local on = not (aux.account_data and aux.account_data.shopping_count_alts)
        aux.set_shopping_count_alts(on)
    end
    alt_switch:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_BOTTOM')
        GameTooltip:AddLine('Count alts', 1, 1, 1)
        GameTooltip:AddLine('Subtract materials held in your bank (once opened), mail (once opened), and other characters on this realm and faction.', 1, 1, 1, true)
        GameTooltip:AddLine('Off by default. Turning this on records inventory snapshots when you log in, open your bank, or open mail.', aux.color.label.enabled())
        GameTooltip:Show()
    end)
    alt_switch:SetScript('OnLeave', function() GameTooltip:Hide() end)

    local div = header:CreateTexture(nil, 'BORDER')
    gui.texture_color(div, aux.color.input.border)
    div:SetSize(1, 22)
    div:SetPoint('RIGHT', alt_switch, 'LEFT', -10, 0)

    plus_button = gui.button(header, gui.font_size.medium)
    gui.set_size(plus_button, 24, 24)
    plus_button:SetPoint('RIGHT', div, 'LEFT', -10, 0)
    plus_button:SetText('+')
    plus_button:SetScript('OnClick', function()
        set_shopping_craft_count(craft_count + 1)
    end)

    craft_input = gui.editbox(header)
    gui.set_size(craft_input, 44, 24)
    craft_input:SetPoint('RIGHT', plus_button, 'LEFT', -2, 0)
    craft_input:SetNumeric(true)
    craft_input:SetMaxLetters(3)
    craft_input:SetAlignment('CENTER')
    craft_input.reset_text = '1'
    craft_input.formatter = function(text)
        return text == '' and tostring(craft_count) or text
    end
    craft_input.change = function(self, is_user_input)
        if not is_user_input then
            return
        end
        local n = tonumber(self:GetText())
        if n and n >= 1 then
            set_shopping_craft_count(n)
        end
    end
    craft_input.enter = function(self)
        self:ClearFocus()
    end
    craft_input.focus_loss = function(self)
        local n = tonumber(self:GetText())
        if not n or n < 1 then
            self:SetText(tostring(craft_count))
            self.overlay:SetText(self.formatter(self:GetText()))
        else
            set_shopping_craft_count(n)
        end
    end
    craft_input:SetText('1')
    craft_input.overlay:SetText('1')

    minus_button = gui.button(header, gui.font_size.medium)
    gui.set_size(minus_button, 24, 24)
    minus_button:SetPoint('RIGHT', craft_input, 'LEFT', -2, 0)
    minus_button:SetText('-')
    minus_button:SetScript('OnClick', function()
        set_shopping_craft_count(craft_count - 1)
    end)

    craft_label = gui.label(header, gui.font_size.small)
    craft_label:SetPoint('RIGHT', minus_button, 'LEFT', -6, 0)
    gui.text_color(craft_label, aux.color.label.enabled)
    craft_label:SetText('Craft')

    title_label = gui.label(header, gui.font_size.medium)
    title_label:SetPoint('TOPLEFT', icon_frame, 'TOPRIGHT', 8, -1)
    title_label:SetPoint('RIGHT', craft_label, 'LEFT', -12, 0)
    title_label:SetJustifyH('LEFT')
    gui.text_color(title_label, aux.color.text.enabled)

    subtitle_label = gui.label(header, gui.font_size.small)
    subtitle_label:SetPoint('BOTTOMLEFT', icon_frame, 'BOTTOMRIGHT', 8, 1)
    subtitle_label:SetPoint('RIGHT', craft_label, 'LEFT', -12, 0)
    subtitle_label:SetJustifyH('LEFT')
    gui.text_color(subtitle_label, aux.color.label.enabled)

    -- Table panel between header and summary bar
    list_frame = CreateFrame('Frame', nil, root)
    list_frame:SetPoint('TOPLEFT', header, 'BOTTOMLEFT', 0, 0)
    list_frame:SetPoint('BOTTOMRIGHT', root, 'BOTTOMRIGHT', 0, buy_bar.HEIGHT + SUMMARY_HEIGHT)

    shopping_listing = listing.new(list_frame, ROW_HEIGHT)
    shopping_listing:SetColInfo(col_info)
    shopping_listing:SetSelection(function(data)
        return data.row and data.row.item_id == selected_item_id
    end)
    shopping_listing:SetHandler('OnClick', function(_, row_data, _, button)
        local row = row_data and row_data.row
        if not row then
            return
        end
        if button == 'RightButton' then
            search_item(row.item_id)
            return
        end
        selected_item_id = row.item_id
        shopping_listing:Update()
        load_row_into_buy_bar(row)
    end)
    shopping_listing:SetHandler('OnEnter', function(_, row_data, row_frame)
        local row = row_data and row_data.row
        if not row then
            return
        end
        GameTooltip:SetOwner(row_frame, 'ANCHOR_RIGHT')
        local item_info = info.item(row.item_id)
        local link = (item_info and item_info.link) or ('item:' .. row.item_id)
        GameTooltip:SetHyperlink(link)
        local r, g, b = aux.color.label.enabled()
        local hr, hg, hb = aux.color.tooltip.value()
        GameTooltip:AddLine(' ')
        GameTooltip:AddLine('Shopping List', hr, hg, hb)
        local req_right = craft_count > 1 and (row.required .. ' (' .. row.per_craft .. ' × ' .. craft_count .. ')') or tostring(row.required)
        GameTooltip:AddDoubleLine('Required', req_right, r, g, b, 1, 1, 1)
        GameTooltip:AddDoubleLine('In your bags', tostring(row.self_bags), r, g, b, 1, 1, 1)
        if row.bought_now > 0 then
            local gr, gg, gb = aux.color.green()
            GameTooltip:AddDoubleLine('Bought this visit', tostring(row.bought_now), gr, gg, gb, gr, gg, gb)
        end
        local tooltip_has_inv = aux.character_data and aux.character_data.tooltip and aux.character_data.tooltip.inventory
        if current_plan and current_plan.include_alts then
            if not tooltip_has_inv then
                for _, entry in ipairs(row.entries or empty) do
                    if not entry.is_self or entry.bank > 0 or entry.mail > 0 then
                        local label = '  ' .. entry.name .. (entry.is_self and ' (You)' or '')
                        GameTooltip:AddDoubleLine(label, format_places(entry), r, g, b, 1, 1, 1)
                    end
                end
                if (row.account_bank or 0) > 0 then
                    local ar, ag, ab = aux.color.blue()
                    GameTooltip:AddDoubleLine('  Account Bank', tostring(row.account_bank), ar, ag, ab, 1, 1, 1)
                end
            end
        else
            GameTooltip:AddLine('Turn on "Count alts" to include bank, mail, and other characters.', r, g, b, true)
        end
        if row.vendor_reliable then
            GameTooltip:AddDoubleLine('Vendor price', plain_money(ceil(row.vendor_unit)) .. ' each', r, g, b, 1, 1, 1)
            if row.vendor_saves and row.vendor_saves > 0 then
                local gr, gg, gb = aux.color.green()
                GameTooltip:AddDoubleLine('Vendor saves', plain_money(row.vendor_saves), gr, gg, gb, gr, gg, gb)
            end
        end
        if row.ah_available > 0 and row.ah_min_unit then
            local ah_text = row.ah_available .. ' listed, from ' .. plain_money(ceil(row.ah_min_unit))
            if row.ah_max_unit and ceil(row.ah_max_unit) > ceil(row.ah_min_unit) then
                ah_text = ah_text .. ' up to ' .. plain_money(ceil(row.ah_max_unit))
            end
            GameTooltip:AddDoubleLine('Auction house', ah_text, r, g, b, 1, 1, 1)
        end
        gui.add_click_hint(GameTooltip, 'Click: load in buy bar' .. gui.HINT_SEPARATOR .. 'Right-click: search listings')
        GameTooltip:Show()
    end)
    shopping_listing:SetHandler('OnLeave', function()
        GameTooltip:Hide()
    end)

    -- Summary strip directly above the shared buy bar
    summary_bar = CreateFrame('Frame', nil, root)
    summary_bar:SetPoint('BOTTOMLEFT', 0, buy_bar.HEIGHT)
    summary_bar:SetPoint('BOTTOMRIGHT', 0, buy_bar.HEIGHT)
    summary_bar:SetHeight(SUMMARY_HEIGHT)
    local s_edge = summary_bar:CreateTexture(nil, 'BORDER')
    gui.texture_color(s_edge, aux.color.window.border)
    s_edge:SetPoint('TOPLEFT')
    s_edge:SetPoint('TOPRIGHT')
    s_edge:SetHeight(1)

    totals_left = gui.label(summary_bar, gui.font_size.small)
    totals_left:SetPoint('LEFT', 12, 0)
    totals_left:SetJustifyH('LEFT')
    gui.text_color(totals_left, aux.color.text.enabled)

    totals_right = gui.label(summary_bar, gui.font_size.small)
    totals_right:SetPoint('RIGHT', -12, 0)
    totals_right:SetJustifyH('RIGHT')
    gui.text_color(totals_right, aux.color.label.enabled)

    -- Empty state when no recipe is loaded
    empty_panel = CreateFrame('Frame', nil, root)
    empty_panel:SetPoint('TOPLEFT', 0, 0)
    empty_panel:SetPoint('BOTTOMRIGHT', 0, buy_bar.HEIGHT)

    empty_title = gui.label(empty_panel, gui.font_size.large)
    empty_title:SetPoint('CENTER', 0, 26)
    gui.text_color(empty_title, aux.color.text.enabled)
    empty_title:SetText('No recipe loaded')

    empty_body = gui.label(empty_panel, gui.font_size.small)
    empty_body:SetPoint('TOP', empty_title, 'BOTTOM', 0, -8)
    gui.text_color(empty_body, aux.color.label.enabled)
    empty_body:SetText('Open your Professions window and click "Search in aux", or Alt-click any recipe.')

    last_recipe_button = gui.button(empty_panel, gui.font_size.small)
    last_recipe_button:SetHeight(26)
    last_recipe_button:SetPoint('TOP', empty_body, 'BOTTOM', 0, -14)
    last_recipe_button:SetScript('OnClick', function()
        local last = last_saved_recipe()
        if last then
            set_filter(last.filter_string)
            execute(nil, false)
        end
    end)
    last_recipe_button:Hide()

    -- Clear button in the bottom status band (same place as Search Results)
    clear_button = gui.button(root)
    clear_button:SetPoint('LEFT', aux.status_bar, 'RIGHT', 5, 0)
    clear_button:SetText('Clear')
    clear_button:SetScript('OnClick', function()
        clear_shopping_list()
    end)

    M.shopping_listing = shopping_listing
    M.shopping_craft_input = craft_input
    M.shopping_minus_button = minus_button
    M.shopping_plus_button = plus_button
    M.shopping_alt_switch = alt_switch
    M.shopping_refresh_button = refresh_button
    M.shopping_clear_button = clear_button
    M.shopping_title_label = title_label
    M.shopping_subtitle_label = subtitle_label
    M.shopping_totals_left = totals_left
    M.shopping_totals_right = totals_right
    M.shopping_empty_panel = empty_panel
    M.shopping_last_button = last_recipe_button
end

-- Live refresh when bags/bank/mail change while Shopping List is shown (no OnUpdate)
inventory.on_change(function()
    if frame.shopping and frame.shopping:IsShown() then
        refresh_shopping_list()
    end
end)

-- Reset per-visit bought counts when the auction house closes (items are now in the mailbox)
function aux.event.CLOSE()
    aux.wipe(shopping_bought)
end

function aux.event.AUX_LOADED()
    refresh_shopping_list()
end
