select(2, ...) 'aux.gui.commodity_bar'

local aux = require 'aux'
local gui = require 'aux.gui'
local money = require 'aux.util.money'

-- Forever: commodities (stackable trade goods) cannot be bought by row. Whichever row is selected,
-- the game sells the cheapest units first. So buying one is "N units of this item", done from the
-- bottom bar of the Search tab:
--   1. the quantity starts at one stack; the bar shows the cost worked out from the listed prices
--   2. Buy asks the server for the real price
--   3. nothing is bought until Confirm; a server price above the estimate is cancelled

local IDLE, QUOTING, QUOTED, BUYING = aux.enum(4)

local state = IDLE
local current
local listener_ids = {}
local t0
local message, message_color, message_until

local container, quantity_input, action_button, info_label

local function kill_listeners()
    for _, id in ipairs(listener_ids) do
        aux.kill_listener(id)
    end
    listener_ids = {}
end

local function listen(event, f)
    tinsert(listener_ids, aux.event_listener(event, f))
end

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

local function show_message(text, color, seconds)
    message, message_color = text, color or aux.color.text.enabled
    message_until = seconds and GetTime() + seconds
end

local function set_action(text, enabled, highlight)
    action_button:SetText(text)
    if enabled then
        action_button:Enable()
    else
        action_button:Disable()
    end
    action_button:SetBackdropColor((highlight and aux.color.state.enabled or aux.color.content.background)())
end

local function update()
    if not current then return end
    if message and message_until and GetTime() > message_until then
        message = nil
    end

    if state == IDLE then
        local n = quantity_input:GetNumber()
        local total, max_unit, count = estimate(n)
        if message then
            info_label:SetText(message)
            info_label:SetTextColor(message_color())
        elseif available() == 0 then
            info_label:SetText('None for sale\n(except your own)')
            info_label:SetTextColor(aux.color.label.enabled())
        elseif n < 1 then
            info_label:SetText('Enter a quantity')
            info_label:SetTextColor(aux.color.label.enabled())
        elseif count < n then
            info_label:SetText('Only ' .. count .. ' for sale')
            info_label:SetTextColor(aux.color.red())
        else
            info_label:SetText(n .. ' for ' .. money.to_string(total, true) .. '\navg ' .. money.to_string(ceil(total / n), true) .. ', max ' .. money.to_string(max_unit, true))
            info_label:SetTextColor(aux.color.text.enabled())
        end
        local can_buy = n >= 1 and count == n and total <= GetMoney()
        if n >= 1 and count == n and total > GetMoney() and not message then
            info_label:SetText('Not enough money\nfor ' .. money.to_string(total, true))
            info_label:SetTextColor(aux.color.red())
        end
        set_action('Buy', can_buy)
    elseif state == QUOTING then
        info_label:SetText('Getting price...')
        info_label:SetTextColor(aux.color.label.enabled())
        set_action('Buy', false)
    elseif state == QUOTED then
        info_label:SetText('Server price ' .. money.to_string(current.quote_total, true) .. '\nfor ' .. current.quantity .. '. Confirm?')
        info_label:SetTextColor(aux.color.green())
        set_action('Confirm', current.quote_total <= GetMoney(), true)
    elseif state == BUYING then
        info_label:SetText('Buying...')
        info_label:SetTextColor(aux.color.label.enabled())
        set_action('Confirm', false)
    end
end

local function reset(text, color)
    kill_listeners()
    if state == QUOTING or state == QUOTED then
        C_AuctionHouse.CancelCommoditiesPurchase()
    end
    state = IDLE
    if text then
        show_message(text, color, 6)
    end
    update()
end

local function request_quote()
    local n = quantity_input:GetNumber()
    local total, _, count = estimate(n)
    if n < 1 or count < n or total > GetMoney() then return end
    current.quantity, current.estimate = n, total
    state = QUOTING
    t0 = GetTime()
    message = nil

    listen('COMMODITY_PRICE_UPDATED', function(_, quote_total)
        if state ~= QUOTING and state ~= QUOTED then return end
        if quote_total > current.estimate then
            reset('Price is now ' .. money.to_string(quote_total, true) .. '\nNothing bought', aux.color.red)
            return
        end
        current.quote_total = quote_total
        state = QUOTED
        update()
    end)
    listen('COMMODITY_PRICE_UNAVAILABLE', function()
        reset('Price unavailable\nNothing bought', aux.color.red)
    end)
    listen('COMMODITY_PURCHASE_FAILED', function()
        reset('Purchase failed\nNothing bought', aux.color.red)
    end)
    listen('AUCTION_HOUSE_SHOW_ERROR', function()
        if state ~= IDLE then
            reset('Auction house refused\nNothing bought', aux.color.red)
        end
    end)
    listen('COMMODITY_PURCHASE_SUCCEEDED', function()
        if state ~= BUYING then return end
        local bought, paid, on_success = current.quantity, current.quote_total, current.on_success
        kill_listeners()
        state = IDLE
        show_message('Bought ' .. bought .. '\nfor ' .. money.to_string(paid, true), aux.color.green, 6)
        do (on_success or pass)(bought) end
        -- the purchase can change the selection, which may already have hidden the bar
        if current then
            current.tier_list = current.tiers()
            update()
        end
    end)

    C_AuctionHouse.StartCommoditiesPurchase(current.item_id, n)
    update()
end

local function confirm()
    if state ~= QUOTED then return end
    state = BUYING
    t0 = GetTime()
    C_AuctionHouse.ConfirmCommoditiesPurchase(current.item_id, current.quantity)
    update()
end

local function action()
    if state == IDLE then
        request_quote()
    elseif state == QUOTED then
        confirm()
    end
end

-- params: item_id, max_stack, tiers() (the tiers the player can buy, cheapest first), on_success(n)
function M.show(params)
    if current and current.item_id == params.item_id and container:IsShown() then
        -- same item (e.g. the table refreshed after a purchase): keep the quantity and any message
        current.tiers, current.on_success, current.max_stack = params.tiers, params.on_success, params.max_stack
        current.tier_list = params.tiers()
        update()
        return
    end
    reset()
    message = nil
    current = params
    current.tier_list = params.tiers()
    container:Show()
    quantity_input:SetNumber(max(1, min(params.max_stack or 1, available())))
    update()
end

function M.hide()
    if container:IsShown() then
        reset()
        container:Hide()
    end
    current = nil
end

function M.shown()
    return container:IsShown()
end

function M.busy()
    return state ~= IDLE
end

function aux.event.CLOSE()
    hide()
end

-- Built by the Search tab next to the status bar, where the Bid/Buyout/Clear buttons normally are
function M.create(parent, anchor)
    container = CreateFrame('Frame', nil, parent)
    container:SetPoint('TOPLEFT', anchor, 'TOPRIGHT', 5, 0)
    container:SetPoint('BOTTOMLEFT', anchor, 'BOTTOMRIGHT', 5, 0)
    container:SetWidth(300)
    container:Hide()
    container:SetScript('OnHide', function()
        reset()
    end)
    container:SetScript('OnUpdate', function()
        -- a quote only lasts a short time; a lost server answer must not leave the bar stuck
        if state == QUOTED and C_AuctionHouse.GetQuoteDurationRemaining() == 0 then
            reset('Price quote expired\nNothing bought', aux.color.red)
        elseif (state == QUOTING or state == BUYING) and GetTime() - t0 > 10 then
            reset('No answer from the\nauction house', aux.color.red)
        else
            update()
        end
    end)

    quantity_input = gui.editbox(container)
    quantity_input:SetPoint('LEFT', 0, 0)
    quantity_input:SetWidth(50)
    quantity_input:SetNumeric(true)
    quantity_input:SetAlignment('CENTER')
    quantity_input:SetFontSize(gui.font_size.medium)
    quantity_input.change = function(self)
        if state == IDLE then
            message = nil
            update()
        elseif current and current.quantity and self:GetNumber() ~= current.quantity then
            -- the quantity is fixed once a price was asked for
            self:SetNumber(current.quantity)
        end
    end
    -- Enter asks for the price, then Enter again confirms
    quantity_input.enter = action
    quantity_input.escape = function()
        if state ~= IDLE then
            reset('Cancelled\nNothing bought', aux.color.label.enabled)
        end
    end

    action_button = gui.button(container)
    action_button:SetPoint('LEFT', quantity_input, 'RIGHT', 5, 0)
    gui.set_size(action_button, 75, 24)
    action_button:SetText('Buy')
    action_button:SetScript('OnClick', action)

    info_label = gui.label(container, gui.font_size.small)
    info_label:SetPoint('LEFT', action_button, 'RIGHT', 6, 0)
    info_label:SetWidth(165)
    info_label:SetJustifyH('LEFT')
end
