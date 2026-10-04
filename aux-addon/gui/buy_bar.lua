select(2, ...) 'aux.gui.buy_bar'

local aux = require 'aux'
local gui = require 'aux.gui'
local money = require 'aux.util.money'

-- The buy bar sits under the Search results and buys whatever is selected.
--
-- Commodities (stackable trade goods) cannot be bought by row on Forever: whichever row is
-- selected, the game sells the cheapest units first. So for them the bar offers quantities sized
-- to the item's stack (e.g. 1, 5, 10, 20), each showing what it costs, plus an Other box:
--   1. Buy asks the server for the real price
--   2. nothing is bought until Confirm; the button shows the exact price
--   3. a server price above the shown cost is cancelled and the item's listings are re-read
--
-- Items (gear, bags, ...) are bought one at a time at the price shown on the button, as in
-- Classic aux; a Bid button appears when the auction takes bids.

M.HEIGHT = 58

local ACCENT = {.89, .64, .23}
local ACCENT_TEXT = {.10, .08, .03}
local CONFIRM = {.25, .68, .42}
local CONFIRM_TEXT = {.02, .08, .05}
local NEUTRAL = {.12, .13, .15}

local NONE, COMMODITY, ITEM = aux.enum(3)
local IDLE, QUOTING, QUOTED, BUYING = aux.enum(4)

local mode = NONE
local state = IDLE
local current
local listener_ids = {}
local t0
local message, message_color, message_until

local bar, icon, name_label, sub_label, chips, other_input, line1, line2, cancel_button, bid_button, primary_button

-- helpers

local function kill_listeners()
    for _, id in ipairs(listener_ids) do
        aux.kill_listener(id)
    end
    listener_ids = {}
end

local function listen(event, f)
    tinsert(listener_ids, aux.event_listener(event, f))
end

local function show_message(text, color, seconds)
    message, message_color = text, color or aux.color.text.enabled
    message_until = GetTime() + (seconds or 6)
end

local function style_button(button, colors, text_colors, enabled)
    if enabled then
        button:Enable()
        button:SetBackdropColor(colors[1], colors[2], colors[3], 1)
        button:GetFontString():SetTextColor(text_colors[1], text_colors[2], text_colors[3], 1)
    else
        button:Disable()
        button:SetBackdropColor(NEUTRAL[1], NEUTRAL[2], NEUTRAL[3], 1)
        button:GetFontString():SetTextColor(aux.color.text.disabled())
    end
end

local function fit_width(button, min_width)
    button:SetWidth(max(min_width or 80, button:GetFontString():GetStringWidth() + 28))
end

local function set_lines(text1, text2, color2)
    line1:SetText(text1 or '')
    line2:SetText(text2 or '')
    line2:SetTextColor((color2 or aux.color.label.enabled)())
end

-- Quantities offered for a stack size: 1, up to two round numbers below the stack, and the stack
function M.quantities(stack)
    if not stack or stack <= 1 then
        return {}
    end
    local below = {}
    for _, n in ipairs{5, 10, 20, 50, 100, 200, 500} do
        if n < stack then
            tinsert(below, n)
        end
    end
    local quantities = {1}
    for i = max(1, #below - 1), #below do
        tinsert(quantities, below[i])
    end
    tinsert(quantities, stack)
    return quantities
end

-- commodities

-- Cost of the cheapest n units listed: total, highest unit price paid, units actually available
local function estimate(n)
    local total, max_unit, remaining = 0, 0, n
    for _, tier in ipairs(current.tier_list) do
        if remaining <= 0 then break end
        local taken = min(remaining, tier.count)
        total = total + taken * tier.commodity_unit_price
        max_unit = tier.commodity_unit_price
        remaining = remaining - taken
    end
    return total, max_unit, n - remaining
end

local function available()
    local count = 0
    for _, tier in ipairs(current.tier_list) do
        count = count + tier.count
    end
    return count
end

local function quantity()
    return current.quantity or 0
end

local function set_quantity(n)
    if state ~= IDLE then return end
    current.quantity = n
    message = nil
end

local function update_commodity()
    local n = quantity()
    local total, max_unit, count = estimate(n)
    local stock = available()

    sub_label:SetText(stock .. ' for sale' .. ((current.max_stack or 1) > 1 and ' · stack of ' .. current.max_stack or ''))

    for i, chip in ipairs(chips) do
        local amount = current.quantities[i]
        if amount then
            chip:Show()
            local chip_total, _, chip_count = estimate(amount)
            chip.amount:SetText(amount == current.max_stack and amount .. ' stack' or amount)
            chip:SetWidth(amount == current.max_stack and 76 or 54)
            local selected = amount == n
            if chip_count < amount then
                chip.cost:SetText('-')
                chip:Disable()
            else
                chip.cost:SetText(money.to_string(chip_total, true))
                chip:Enable()
            end
            if selected then
                chip:SetBackdropColor(.23, .18, .08, 1)
                chip:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
            else
                chip:SetBackdropColor(.12, .13, .15, 1)
                chip:SetBackdropBorderColor(.23, .25, .27, 1)
            end
        else
            chip:Hide()
        end
    end
    local custom = not aux.key(current.quantities, n)
    other_input:SetBackdropBorderColor((custom and ACCENT or {.23, .25, .27})[1], (custom and ACCENT or {.23, .25, .27})[2], (custom and ACCENT or {.23, .25, .27})[3], 1)

    cancel_button:Hide()
    bid_button:Hide()
    if state == IDLE then
        if message and GetTime() < message_until then
            set_lines(message[1], message[2], message_color)
        elseif stock == 0 then
            set_lines('None for sale', 'Only your own auctions are listed')
        elseif n < 1 then
            set_lines('Choose how many to buy')
        elseif count < n then
            set_lines('Only ' .. count .. ' for sale', 'Choose a smaller quantity', aux.color.red)
        else
            set_lines(n .. ' × ' .. current.name .. ' for ' .. money.to_string(total, true), 'Cheapest first · avg ' .. money.to_string(ceil(total / n), true) .. ' · highest ' .. money.to_string(max_unit, true) .. ' each')
        end
        local can_buy = n >= 1 and count == n
        if can_buy and total > GetMoney() then
            can_buy = false
            set_lines(n .. ' × ' .. current.name .. ' for ' .. money.to_string(total, true), 'Not enough money', aux.color.red)
        end
        primary_button:SetText(can_buy and ('Buy ' .. n .. ' for ' .. money.to_string(total, true)) or 'Buy')
        style_button(primary_button, ACCENT, ACCENT_TEXT, can_buy)
    elseif state == QUOTING then
        set_lines('Asking the auction house for the price...', 'Nothing is bought yet')
        primary_button:SetText('Getting price...')
        style_button(primary_button, ACCENT, ACCENT_TEXT, false)
    elseif state == QUOTED then
        set_lines('Server price: ' .. money.to_string(current.quote_total, true) .. ' for ' .. current.quote_quantity, 'Nothing is bought until you confirm', aux.color.green)
        primary_button:SetText('Confirm ' .. money.to_string(current.quote_total, true))
        style_button(primary_button, CONFIRM, CONFIRM_TEXT, current.quote_total <= GetMoney())
        cancel_button:Show()
    elseif state == BUYING then
        set_lines('Buying...', 'Waiting for the auction house')
        primary_button:SetText('Buying...')
        style_button(primary_button, CONFIRM, CONFIRM_TEXT, false)
    end
    fit_width(primary_button, 130)
end

local function reset(text, color)
    kill_listeners()
    if mode == COMMODITY and (state == QUOTING or state == QUOTED) then
        C_AuctionHouse.CancelCommoditiesPurchase()
    end
    state = IDLE
    if text then
        show_message(text, color)
    end
end

local function request_quote()
    local n = quantity()
    local total, _, count = estimate(n)
    if n < 1 or count < n or total > GetMoney() then return end
    current.quote_quantity, current.estimate = n, total
    state = QUOTING
    t0 = GetTime()
    message = nil

    listen('COMMODITY_PRICE_UPDATED', function(_, quote_total)
        if state ~= QUOTING and state ~= QUOTED then return end
        if quote_total > current.estimate then
            reset({'The price went up to ' .. money.to_string(quote_total, true), 'Nothing was bought. Listings refreshed.'}, aux.color.red)
            do (current.on_refresh or pass)() end
            return
        end
        current.quote_total = quote_total
        state = QUOTED
    end)
    listen('COMMODITY_PRICE_UNAVAILABLE', function()
        reset({'That price is no longer available', 'Nothing was bought. Listings refreshed.'}, aux.color.red)
        do (current.on_refresh or pass)() end
    end)
    listen('COMMODITY_PURCHASE_FAILED', function()
        reset({'The purchase failed', 'Nothing was bought'}, aux.color.red)
    end)
    listen('AUCTION_HOUSE_SHOW_ERROR', function()
        if state ~= IDLE then
            reset({'The auction house refused the purchase', 'Nothing was bought'}, aux.color.red)
        end
    end)
    listen('COMMODITY_PURCHASE_SUCCEEDED', function()
        if state ~= BUYING then return end
        local bought, paid, on_success = current.quote_quantity, current.quote_total, current.on_success
        kill_listeners()
        state = IDLE
        show_message({'Bought ' .. bought .. ' × ' .. current.name .. ' for ' .. money.to_string(paid, true), 'On the way to your mailbox'}, aux.color.green)
        do (on_success or pass)(bought) end
        -- the purchase can change the selection, which may already have moved the bar on
        if mode == COMMODITY and current then
            current.tier_list = current.tiers()
        end
    end)

    C_AuctionHouse.StartCommoditiesPurchase(current.item_id, n)
end

-- items

local function can_buy_item()
    local record = current.record
    return not current.busy() and not current.own and not record.own and record.buyout_price > 0 and record.buyout_price <= GetMoney()
end

local function can_bid_item()
    local record = current.record
    return not current.own and not record.own and not record.high_bidder and (record.buyout_price == 0 or record.bid_price < record.buyout_price)
end

local function update_item()
    local record = current.record
    local busy = current.busy()
    sub_label:SetText((record.auction_count or 1) .. ' for sale at this price')
    for _, chip in ipairs(chips) do chip:Hide() end
    cancel_button:Hide()

    if message and GetTime() < message_until then
        set_lines(message[1], message[2], message_color)
    elseif record.own or current.own then
        set_lines('This is your own auction', 'It cannot be bought or bid on')
    elseif record.buyout_price > 0 then
        set_lines('1 × ' .. current.name .. ' for ' .. money.to_string(record.buyout_price, true), (record.auction_count or 1) > 1 and 'The next one at this price is selected after buying' or 'The last one at this price')
    else
        set_lines('No buyout price', 'This auction can only be bid on')
    end

    local can_buy = can_buy_item()
    primary_button:SetText(record.buyout_price > 0 and ('Buy for ' .. money.to_string(record.buyout_price, true)) or 'Buy')
    style_button(primary_button, ACCENT, ACCENT_TEXT, can_buy)
    fit_width(primary_button, 130)

    if can_bid_item() then
        bid_button:Show()
        bid_button:SetText('Bid ' .. money.to_string(record.bid_price, true))
        fit_width(bid_button, 90)
        if busy or record.bid_price > GetMoney() then
            bid_button:Disable()
        else
            bid_button:Enable()
        end
    elseif record.high_bidder then
        bid_button:Show()
        bid_button:SetText('You are the high bidder')
        fit_width(bid_button, 90)
        bid_button:Disable()
    else
        bid_button:Hide()
    end
end

-- shared

local lines_left, lines_x, lines_right

local function place_lines()
    line1:ClearAllPoints()
    line1:SetPoint('TOPLEFT', lines_left, 'TOPRIGHT', lines_x, -4)
    line1:SetPoint('RIGHT', lines_right, 'LEFT', -10, 0)
    line2:ClearAllPoints()
    line2:SetPoint('BOTTOMLEFT', lines_left, 'BOTTOMRIGHT', lines_x, 4)
    line2:SetPoint('RIGHT', lines_right, 'LEFT', -10, 0)
end

local function anchor_lines(left, x)
    lines_left, lines_x = left, x
    place_lines()
end

-- the text uses the room up to the leftmost visible button
local function fit_lines()
    local right = bid_button:IsShown() and bid_button or cancel_button:IsShown() and cancel_button or primary_button
    if right ~= lines_right then
        lines_right = right
        place_lines()
    end
end

local function update()
    if mode == NONE then return end
    if mode == COMMODITY then
        update_commodity()
    else
        update_item()
    end
    fit_lines()
end

local function show_common(params)
    icon:SetTexture(params.texture)
    local color = ITEM_QUALITY_COLORS[params.quality or 1] or ITEM_QUALITY_COLORS[1]
    name_label:SetText(params.name or '')
    name_label:SetTextColor(color.r, color.g, color.b)
    for _, widget in ipairs{icon, name_label, sub_label, line1, line2, primary_button} do
        widget:Show()
    end
end

-- params: item_id, name, texture, quality, max_stack, tiers() (the tiers the player can buy,
-- cheapest first), on_success(n), on_refresh()
function M.show_commodity(params)
    if mode == COMMODITY and current and current.item_id == params.item_id then
        -- same item (e.g. the table refreshed after a purchase): keep the quantity and any message
        current.tiers, current.on_success, current.on_refresh = params.tiers, params.on_success, params.on_refresh
        current.tier_list = params.tiers()
        return
    end
    reset()
    message = nil
    mode = COMMODITY
    current = params
    current.tier_list = params.tiers()
    current.quantities = quantities(params.max_stack)
    local start = max(1, min(params.max_stack or 1, available()))
    current.quantity = start
    other_input:Show()
    other_input:SetText(aux.key(current.quantities, start) and '' or tostring(start))
    other_input.overlay:SetText(other_input.formatter(other_input:GetText()))
    anchor_lines(other_input, 14)
    show_common(params)
end

-- params: record, name, texture, quality, own, busy(), on_buy(), on_bid()
function M.show_item(params)
    if mode == COMMODITY then
        reset()
    end
    if not (mode == ITEM and current and current.record == params.record) then
        message = nil
    end
    mode = ITEM
    current = params
    other_input:Hide()
    anchor_lines(icon:GetParent(), 170)
    show_common(params)
end

function M.show_message(text1, text2, color)
    show_message({text1, text2}, color)
end

function M.clear()
    reset()
    mode = NONE
    current = nil
    for _, chip in ipairs(chips) do chip:Hide() end
    for _, widget in ipairs{icon, name_label, sub_label, other_input, cancel_button, bid_button, primary_button, line2} do
        widget:Hide()
    end
    line1:Show()
    line1:SetText('Select an auction to buy it')
end

function M.busy()
    return state ~= IDLE
end

function M.primary_click()
    if mode == COMMODITY then
        if state == IDLE then
            request_quote()
        elseif state == QUOTED and current.quote_total <= GetMoney() then
            state = BUYING
            t0 = GetTime()
            C_AuctionHouse.ConfirmCommoditiesPurchase(current.item_id, current.quote_quantity)
        end
    elseif mode == ITEM and can_buy_item() then
        current.on_buy()
    end
    update()
end

function M.bid_click()
    if mode == ITEM and can_bid_item() and not current.busy() and current.record.bid_price <= GetMoney() then
        current.on_bid()
    end
    update()
end

function M.primary_label()
    return primary_button:GetText()
end

function aux.event.CLOSE()
    clear()
end

-- Built by the Search tab along the bottom of its results
function M.create(parent)
    bar = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    gui.set_frame_style(bar, aux.color.panel.background, aux.color.panel.border)
    bar:SetBackdropColor(.105, .10, .09, 1)
    bar:SetBackdropBorderColor(.23, .20, .15, 1)
    bar:SetPoint('BOTTOMLEFT', 0, 0)
    bar:SetPoint('BOTTOMRIGHT', 0, 0)
    bar:SetHeight(HEIGHT)
    bar:SetScript('OnHide', function()
        reset()
    end)
    bar:SetScript('OnUpdate', function()
        -- a quote only lasts a short time; a lost server answer must not leave the bar stuck
        if mode == COMMODITY and state == QUOTED and C_AuctionHouse.GetQuoteDurationRemaining() == 0 then
            reset({'The price quote expired', 'Nothing was bought'}, aux.color.red)
        elseif mode == COMMODITY and (state == QUOTING or state == BUYING) and GetTime() - t0 > 10 then
            reset({'No answer from the auction house', 'Nothing was bought'}, aux.color.red)
        end
        update()
    end)

    local icon_frame = CreateFrame('Frame', nil, bar, 'BackdropTemplate')
    gui.set_content_style(icon_frame)
    gui.set_size(icon_frame, 38, 38)
    icon_frame:SetPoint('LEFT', 10, 0)
    icon = icon_frame:CreateTexture(nil, 'ARTWORK')
    icon:SetPoint('TOPLEFT', 2, -2)
    icon:SetPoint('BOTTOMRIGHT', -2, 2)
    icon:SetTexCoord(.08, .92, .08, .92)

    name_label = gui.label(bar, gui.font_size.medium)
    name_label:SetPoint('TOPLEFT', icon_frame, 'TOPRIGHT', 8, -2)
    name_label:SetWidth(150)
    name_label:SetJustifyH('LEFT')

    sub_label = gui.label(bar, gui.font_size.small)
    sub_label:SetPoint('BOTTOMLEFT', icon_frame, 'BOTTOMRIGHT', 8, 2)
    sub_label:SetWidth(150)
    sub_label:SetJustifyH('LEFT')

    chips = {}
    for i = 1, 4 do
        local chip = CreateFrame('Button', nil, bar, 'BackdropTemplate')
        gui.set_content_style(chip)
        gui.set_size(chip, 54, 42)
        if i == 1 then
            chip:SetPoint('LEFT', icon_frame, 'RIGHT', 170, 0)
        else
            chip:SetPoint('LEFT', chips[i - 1], 'RIGHT', 6, 0)
        end
        chip.amount = gui.label(chip, gui.font_size.medium)
        chip.amount:SetPoint('TOP', 0, -5)
        chip.amount:SetTextColor(aux.color.text.enabled())
        chip.cost = gui.label(chip, gui.font_size.small)
        chip.cost:SetPoint('BOTTOM', 0, 5)
        local highlight = chip:CreateTexture(nil, 'HIGHLIGHT')
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, .08)
        chip:SetScript('OnClick', function()
            if current and current.quantities and current.quantities[i] then
                set_quantity(current.quantities[i])
                other_input:SetText('')
                other_input:ClearFocus()
                update()
            end
        end)
        chip:Hide()
        chips[i] = chip
    end

    other_input = gui.editbox(bar)
    other_input:SetPoint('LEFT', chips[4], 'RIGHT', 6, 0)
    other_input:SetWidth(56)
    other_input:SetHeight(42)
    other_input:SetNumeric(true)
    other_input:SetAlignment('CENTER')
    other_input:SetFontSize(gui.font_size.medium)
    other_input.formatter = function(text)
        return text == '' and aux.color.label.enabled'Other' or text
    end
    other_input.change = function(self)
        if state == IDLE and self:GetText() ~= '' then
            set_quantity(self:GetNumber())
            update()
        end
    end
    -- Enter asks for the price, then Enter again confirms
    other_input.enter = function() primary_click() end
    other_input.escape = function()
        if state ~= IDLE then
            reset({'Cancelled', 'Nothing was bought'}, aux.color.label.enabled)
        end
    end
    other_input:Hide()

    primary_button = gui.button(bar, gui.font_size.medium)
    primary_button:SetPoint('RIGHT', -10, 0)
    gui.set_size(primary_button, 130, 42)
    primary_button:SetScript('OnClick', function() primary_click() end)

    cancel_button = gui.button(bar, gui.font_size.medium)
    cancel_button:SetPoint('RIGHT', primary_button, 'LEFT', -6, 0)
    gui.set_size(cancel_button, 80, 42)
    cancel_button:SetText('Cancel')
    cancel_button:SetScript('OnClick', function()
        reset({'Cancelled', 'Nothing was bought'}, aux.color.label.enabled)
        update()
    end)
    cancel_button:Hide()

    bid_button = gui.button(bar, gui.font_size.medium)
    bid_button:SetPoint('RIGHT', primary_button, 'LEFT', -6, 0)
    gui.set_size(bid_button, 90, 42)
    bid_button:SetScript('OnClick', function() bid_click() end)
    bid_button:Hide()

    line1 = gui.label(bar, gui.font_size.medium)
    line1:SetJustifyH('LEFT')
    line1:SetTextColor(aux.color.text.enabled())

    line2 = gui.label(bar, gui.font_size.small)
    line2:SetJustifyH('LEFT')
    lines_right = primary_button
    anchor_lines(icon_frame, 170)

    clear()
end
