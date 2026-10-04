select(2, ...) 'aux.gui.commodity_dialog'

local aux = require 'aux'
local gui = require 'aux.gui'
local money = require 'aux.util.money'

-- Forever: buying a commodity takes the cheapest units on the auction house, so a purchase is a
-- quantity rather than a row. This dialog keeps that safe:
--   1. the player picks a quantity, capped at what is listed at the selected row's price or less
--   2. Buy asks the server for a price quote
--   3. the quote is shown and nothing is bought until the player presses Confirm
-- A quote above quantity x the row's unit price is cancelled automatically.

local IDLE, QUOTING, QUOTED, BUYING = aux.enum(4)

local state = IDLE
local current
local listener_ids = {}
local t0

local frame, title, quantity_input, max_label, cost_label, status_label, primary_button, cancel_button

local function kill_listeners()
    for _, id in ipairs(listener_ids) do
        aux.kill_listener(id)
    end
    listener_ids = {}
end

local function listen(event, f)
    tinsert(listener_ids, aux.event_listener(event, f))
end

local function quantity()
    return quantity_input:GetNumber()
end

local function ceiling(n)
    return n * current.unit_price
end

local function set_status(text, color)
    status_label:SetText(text or '')
    status_label:SetTextColor((color or aux.color.text.enabled)())
end

local function update()
    if not current then return end
    local n = quantity()
    local valid = n >= 1 and n <= current.max_quantity
    if state == IDLE then
        quantity_input:EnableMouse(true)
        primary_button:SetText('Buy')
        if valid then
            local expected = current.expected_total(n)
            cost_label:SetText('Cost: ' .. money.to_string(expected, true) .. '  (' .. money.to_string(current.unit_price, true) .. ' each or less)')
            if expected > GetMoney() then
                primary_button:Disable()
                set_status('Not enough money.', aux.color.red)
            else
                primary_button:Enable()
            end
        else
            cost_label:SetText('Enter a quantity from 1 to ' .. current.max_quantity .. '.')
            primary_button:Disable()
        end
    elseif state == QUOTING then
        quantity_input:EnableMouse(false)
        primary_button:Disable()
    elseif state == QUOTED then
        quantity_input:EnableMouse(false)
        primary_button:SetText('Confirm')
        if current.quote_total > GetMoney() then
            primary_button:Disable()
        else
            primary_button:Enable()
        end
    elseif state == BUYING then
        quantity_input:EnableMouse(false)
        primary_button:Disable()
    end
end

local function reset(status, color)
    kill_listeners()
    if state == QUOTING or state == QUOTED then
        C_AuctionHouse.CancelCommoditiesPurchase()
    end
    state = IDLE
    set_status(status, color)
    update()
end

function M.close()
    if frame:IsShown() then
        reset()
        frame:Hide()
    end
end

function M.in_progress()
    return frame:IsShown()
end

local function request_quote()
    local n = quantity()
    if n < 1 or n > current.max_quantity then return end
    current.quantity = n
    state = QUOTING
    t0 = GetTime()
    set_status('Getting price...', aux.color.label.enabled)

    listen('COMMODITY_PRICE_UPDATED', function(unit_price, total)
        if state ~= QUOTING and state ~= QUOTED then return end
        if total > ceiling(current.quantity) then
            reset('The price went up to ' .. money.to_string(total, true) .. '. Nothing was bought.', aux.color.red)
            return
        end
        current.quote_total = total
        state = QUOTED
        cost_label:SetText('Price: ' .. money.to_string(total, true) .. '  (' .. money.to_string(ceil(total / current.quantity), true) .. ' each)')
        set_status('Press Confirm to buy ' .. current.quantity .. '.', aux.color.green)
        update()
    end)
    listen('COMMODITY_PRICE_UNAVAILABLE', function()
        reset('That price is no longer available. Nothing was bought.', aux.color.red)
    end)
    listen('COMMODITY_PURCHASE_FAILED', function()
        reset('The purchase failed. Nothing was bought.', aux.color.red)
    end)
    listen('AUCTION_HOUSE_SHOW_ERROR', function()
        if state ~= IDLE then
            reset('The auction house refused the purchase.', aux.color.red)
        end
    end)
    listen('COMMODITY_PURCHASE_SUCCEEDED', function()
        if state ~= BUYING then return end
        local bought, on_success = current.quantity, current.on_success
        kill_listeners()
        state = IDLE
        frame:Hide()
        do (on_success or pass)(bought) end
    end)

    C_AuctionHouse.StartCommoditiesPurchase(current.item_id, n)
    update()
end

local function confirm()
    if state ~= QUOTED then return end
    state = BUYING
    t0 = GetTime()
    set_status('Buying...', aux.color.label.enabled)
    C_AuctionHouse.ConfirmCommoditiesPurchase(current.item_id, current.quantity)
    update()
end

local function primary_click()
    if state == IDLE then
        request_quote()
    elseif state == QUOTED then
        confirm()
    end
end

-- params: item_id, name, unit_price (the selected row's), max_quantity, quantity (default),
-- expected_total(n) (cost of the cheapest n listed), on_success(n)
function M.open(params)
    if state ~= IDLE then return end
    current = params
    title:SetText(params.name)
    max_label:SetText('of ' .. params.max_quantity)
    quantity_input:SetNumber(params.quantity)
    set_status()
    frame:Show()
    quantity_input:SetFocus()
    quantity_input:HighlightText()
    update()
end

function aux.event.CLOSE()
    close()
end

do
    frame = CreateFrame('Frame', nil, aux.frame, 'BackdropTemplate')
    gui.set_window_style(frame)
    gui.set_size(frame, 340, 150)
    frame:SetPoint('CENTER', aux.frame, 'CENTER')
    frame:SetFrameStrata('DIALOG')
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:Hide()
    frame:SetScript('OnHide', function()
        reset()
    end)
    frame:SetScript('OnUpdate', function()
        -- a quote only lasts a short time; a lost server answer must not leave the dialog stuck
        if state == QUOTED and C_AuctionHouse.GetQuoteDurationRemaining() == 0 then
            reset('The price quote expired. Nothing was bought.', aux.color.red)
        elseif (state == QUOTING or state == BUYING) and GetTime() - t0 > 10 then
            reset('No answer from the auction house.', aux.color.red)
        end
    end)

    title = gui.label(frame, gui.font_size.large)
    title:SetPoint('TOPLEFT', 10, -10)
    title:SetPoint('TOPRIGHT', -10, -10)
    title:SetJustifyH('LEFT')

    local quantity_label = gui.label(frame, gui.font_size.medium)
    quantity_label:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -14)
    quantity_label:SetText('Quantity')

    quantity_input = gui.editbox(frame)
    quantity_input:SetPoint('LEFT', quantity_label, 'RIGHT', 8, 0)
    quantity_input:SetWidth(70)
    quantity_input:SetNumeric(true)
    quantity_input:SetAlignment('CENTER')
    quantity_input.change = function(self)
        if state == IDLE then
            set_status()
            update()
        elseif current and current.quantity and self:GetNumber() ~= current.quantity then
            -- the quantity is fixed once a price was asked for
            self:SetNumber(current.quantity)
        end
    end
    -- the quantity box keeps the keyboard focus, so Enter buys and then confirms
    quantity_input.enter = primary_click
    quantity_input.escape = close

    max_label = gui.label(frame, gui.font_size.medium)
    max_label:SetPoint('LEFT', quantity_input, 'RIGHT', 8, 0)

    cost_label = gui.label(frame, gui.font_size.medium)
    cost_label:SetPoint('TOPLEFT', quantity_label, 'BOTTOMLEFT', 0, -14)
    cost_label:SetPoint('RIGHT', -10, 0)
    cost_label:SetJustifyH('LEFT')

    status_label = gui.label(frame, gui.font_size.small)
    status_label:SetPoint('TOPLEFT', cost_label, 'BOTTOMLEFT', 0, -8)
    status_label:SetPoint('RIGHT', -10, 0)
    status_label:SetJustifyH('LEFT')

    cancel_button = gui.button(frame)
    cancel_button:SetPoint('BOTTOMRIGHT', -8, 8)
    gui.set_size(cancel_button, 70, 24)
    cancel_button:SetText('Cancel')
    cancel_button:SetScript('OnClick', close)

    primary_button = gui.button(frame)
    primary_button:SetPoint('RIGHT', cancel_button, 'LEFT', -6, 0)
    gui.set_size(primary_button, 70, 24)
    primary_button:SetText('Buy')
    primary_button:SetScript('OnClick', primary_click)
end
