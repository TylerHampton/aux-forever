select(2, ...) 'aux.tabs.post'

local aux = require 'aux'
local info = require 'aux.util.info'
local money = require 'aux.util.money'
local gui = require 'aux.gui'
local listing = require 'aux.gui.listing'
local item_listing = require 'aux.gui.item_listing'
local search_tab = require 'aux.tabs.search'

frame = CreateFrame('Frame', nil, aux.frame)
frame:SetAllPoints(aux.frame.body)
frame:SetScript('OnUpdate', on_update)
frame:Hide()

frame.content = CreateFrame('Frame', nil, frame)
frame.content:SetPoint('TOP', frame, 'TOP', 0, -8)
frame.content:SetPoint('BOTTOMLEFT', aux.frame.content, 'BOTTOMLEFT', 0, 0)
frame.content:SetPoint('BOTTOMRIGHT', aux.frame.content, 'BOTTOMRIGHT', 0, 0)

frame.inventory = gui.panel(frame.content)
frame.inventory:SetWidth(212)
frame.inventory:SetPoint('TOPLEFT', 0, 0)
frame.inventory:SetPoint('BOTTOMLEFT', 0, 0)

frame.parameters = gui.panel(frame.content)
frame.parameters:SetHeight(214)
frame.parameters:SetPoint('TOPLEFT', frame.inventory, 'TOPRIGHT', 2.5, 0)
frame.parameters:SetPoint('TOPRIGHT', 0, 0)

-- Forever: the listings fill the height under the parameters, which grew with the window
frame.bid_listing = gui.panel(frame.content)
frame.bid_listing:SetPoint('TOPLEFT', frame.parameters, 'BOTTOMLEFT', 0, -2.5)
frame.bid_listing:SetPoint('BOTTOMLEFT', frame.inventory, 'BOTTOMRIGHT', 2.5, 0)
frame.bid_listing:Hide()

frame.buyout_listing = gui.panel(frame.content)
frame.buyout_listing:SetPoint('TOPLEFT', frame.parameters, 'BOTTOMLEFT', 0, -2.5)
frame.buyout_listing:SetPoint('BOTTOMLEFT', frame.inventory, 'BOTTOMRIGHT', 2.5, 0)
frame.buyout_listing:SetPoint('BOTTOMRIGHT', 0, 0)

do
    local checkbox = gui.checkbox(frame.inventory)
    checkbox:SetPoint('TOPLEFT', 49, -15)
    checkbox:SetScript('OnClick', function()
        refresh = true
    end)
    local label = gui.label(checkbox, gui.font_size.small)
    label:SetPoint('LEFT', checkbox, 'RIGHT', 4, 1)
    label:SetText('Show hidden items')
    show_hidden_checkbox = checkbox
end

gui.horizontal_line(frame.inventory, -45)

do
	local f = CreateFrame('Frame', nil, frame.inventory)
	f:SetPoint('TOPLEFT', 0, -51)
	f:SetPoint('BOTTOMRIGHT', 0, 0)
	inventory_listing = item_listing.new(
		f,
	    function(self, button)
	        if button == 'LeftButton' then
	            update_item(self.item_record)
	        elseif button == 'RightButton' then
	            aux.set_tab(1)
	            search_tab.set_filter(strlower(info.item(self.item_record.item_id).name) .. '/exact')
	            search_tab.execute(nil, false)
	        end
	    end,
	    function(item_record)
	        return item_record == selected_item
	    end
	)
end

bid_listing = listing.new(frame.bid_listing)
bid_listing:SetSelection(function(data)
	return selected_item and (data.record == get_bid_selection() or data.record.historical_value and get_bid_selection() and get_bid_selection().historical_value)
end)
-- auxForever (0.5, docs/clicks.md): the price lists follow the click standard. Click a price to use
-- it, click the chosen one again to let go of it; right-click searches the item like every other
-- row in aux. (Right-click used to clear the price and double-click set the quantity.)
function M.search_selected_item()
	-- the name is read first: leaving the Post tab clears selected_item (0.5 build 1 error)
	local name = selected_item and selected_item.name
	if name then
		aux.set_tab(1)
		search_tab.set_filter(strlower(name) .. '/exact')
		search_tab.execute(nil, false)
	end
end

local function price_click(is_selected, set_selection, row_data, button)
	if button == 'RightButton' then
		search_selected_item()
	elseif is_selected(row_data) then
		set_selection()
	else
		set_selection(row_data.record)
	end
	refresh = true
end

local function price_hint(is_selected)
	return function(st, row_data)
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		gui.add_click_hint(GameTooltip, (is_selected(row_data) and 'Click again: let go of this price' or 'Click: use this price') .. gui.HINT_SEPARATOR .. 'Right-click: search', true)
		GameTooltip:Show()
	end
end

local function hide_hint()
	GameTooltip:Hide()
end

local function bid_selected(data)
	return selected_item and (data.record == get_bid_selection() or data.record.historical_value and get_bid_selection() and get_bid_selection().historical_value) and true or false
end
bid_listing:SetHandler('OnClick', function(table, row_data, column, button)
	price_click(bid_selected, set_bid_selection, row_data, button)
	if button ~= 'RightButton' then
		price_hint(bid_selected)(table, row_data)
	end
end)
bid_listing:SetHandler('OnEnter', price_hint(bid_selected))
bid_listing:SetHandler('OnLeave', hide_hint)

buyout_listing = listing.new(frame.buyout_listing)
-- auxForever: same structure as the other tables: units for sale (aux's Auctions and Stack Size
-- in one), time left, price, and its share of the usual price
buyout_listing:SetColInfo{
    {name='For sale', width=.18, align='CENTER'},
    {name='Time Left', width=.17, align='CENTER'},
    {name='Auction Buyout (per item)', width=.45, align='RIGHT'},
    {name='% Hist. Value', width=.2, align='CENTER'},
}
buyout_listing:SetSelection(function(data)
	return selected_item and (data.record == get_buyout_selection() or data.record.historical_value and get_buyout_selection() and get_buyout_selection().historical_value)
end)
local function buyout_selected(data)
	return selected_item and (data.record == get_buyout_selection() or data.record.historical_value and get_buyout_selection() and get_buyout_selection().historical_value) and true or false
end
buyout_listing:SetHandler('OnClick', function(table, row_data, column, button)
	price_click(buyout_selected, set_buyout_selection, row_data, button)
	if button ~= 'RightButton' then
		price_hint(buyout_selected)(table, row_data)
	end
end)
buyout_listing:SetHandler('OnEnter', price_hint(buyout_selected))
buyout_listing:SetHandler('OnLeave', hide_hint)

-- auxForever: the top panel of the Post tab, redesigned (post pricing mockup): the item with a
-- hide toggle; quantity and duration on the left; on the right the price with a Match lowest /
-- Undercut switch, a "% of usual" badge and a note on how the price was chosen; along the bottom
-- what will be posted, the total, the deposit, what you get after the auction house cut, and Post.
-- The widgets keep the names the posting logic in core.lua uses.
AUCTION_CUT = .05 -- the auction house keeps 5% of a sale
local LEFT_X, RIGHT_X = 12, 268
local ROW1, ROW2, ROW3 = -58, -90, -122

local function small_button(parent, text, width, size)
    local btn = gui.button(parent, size or gui.font_size.medium)
    gui.set_size(btn, width or 26, 26)
    btn:SetText(text)
    return btn
end

-- a label in front of a row's control, at the left edge of its column
local function caption(parent, anchor, text, x)
    local label = gui.label(parent, gui.font_size.small)
    label:SetPoint('LEFT', anchor, 'LEFT', x, 0)
    label:SetText(text)
    return label
end

local function style_choice(btn, selected)
    gui.style_choice(btn, selected)
end

do
    local btn = gui.button(frame)
    btn:SetPoint('LEFT', aux.status_bar, 'RIGHT', 5, 0)
    btn:SetText('Refresh')
    btn:SetScript('OnClick', refresh_button_click)
    refresh_button = btn
end
do
	item = gui.item(frame.parameters)
    item:SetPoint('TOPLEFT', 8, -6)
    item:SetScale(.9)
    item.button:SetScript('OnEnter', function(self)
        if selected_item then
            info.set_tooltip(selected_item.link, self, 'ANCHOR_RIGHT')
        end
    end)
    item.button:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)
    local function select_cursor_item()
        local type, item_id, item_link = GetCursorInfo()
        if type == 'item' then
            local _, suffix_id = info.parse_link(item_link)
            select_item(item_id .. ':' .. suffix_id)
            ClearCursor()
        end
    end
    item.button:HookScript('OnReceiveDrag', select_cursor_item)
    item.button:HookScript('OnMouseDown', select_cursor_item)
    item.button:HookScript('OnClick', select_cursor_item)
    item.name:ClearAllPoints()
    item.name:SetPoint('TOPLEFT', item.button, 'TOPRIGHT', 10, -4)
    item.name:SetPoint('RIGHT', item, 'RIGHT', -10, 0)
    item.name:SetFont(gui.font, gui.font_size.large)
    local detail = gui.label(item, gui.font_size.small)
    detail:SetPoint('BOTTOMLEFT', item.button, 'BOTTOMRIGHT', 10, 4)
    item_detail = detail
end
do
    local checkbox = gui.checkbox(frame.parameters)
    checkbox:SetPoint('TOPRIGHT', -122, -16)
    checkbox:SetScript('OnClick', function(self)
        local settings = read_settings()
        settings.hidden = self:GetChecked()
        write_settings(settings)
        refresh = true
    end)
    local label = gui.label(checkbox, gui.font_size.small)
    label:SetPoint('LEFT', checkbox, 'RIGHT', 5, 0)
    label:SetText('Hide from this list')
    hide_checkbox = checkbox
end

-- a number with -, + and Max; everything is a child of the edit box so it shows and hides with it
local function stepper(caption_text)
    local editbox = gui.editbox(frame.parameters)
    gui.set_size(editbox, 54, 26)
    editbox:SetFontSize(17)
    editbox:SetAlignment('CENTER')
    editbox:SetNumeric(true)
    editbox.reset_text = '1'
    editbox.max_value = 1
    local minus = small_button(editbox, '-')
    minus:SetPoint('RIGHT', editbox, 'LEFT', -3, 0)
    minus:SetScript('OnClick', function() editbox:SetNumber(editbox:GetNumber() - 1) end)
    local plus = small_button(editbox, '+')
    plus:SetPoint('LEFT', editbox, 'RIGHT', 3, 0)
    plus:SetScript('OnClick', function() editbox:SetNumber(editbox:GetNumber() + 1) end)
    local max_button = small_button(editbox, 'Max', 38, gui.font_size.small)
    max_button:SetPoint('LEFT', plus, 'RIGHT', 3, 0)
    max_button:SetScript('OnClick', function() editbox:SetNumber(editbox.max_value) end)
    editbox.caption = caption(editbox, minus, caption_text, LEFT_X - 86)
    return editbox
end
do
    local editbox = stepper('Stack size')
    editbox.change = function(self)
        self:SetNumber(aux.bounded(1, self.max_value, self:GetNumber()))
        quantity_update(true)
    end
    editbox:SetScript('OnTabPressed', function()
        if not IsShiftKeyDown() then
            stack_count_input:SetFocus()
        end
    end)
    stack_size_input = editbox
end
do
    local editbox = stepper('Stacks')
    editbox.change = function(self)
        self:SetNumber(aux.bounded(1, self.max_value, self:GetNumber()))
        quantity_update()
    end
    editbox:SetScript('OnTabPressed', function()
        if IsShiftKeyDown() then
            return
        elseif unit_start_price_input:IsShown() then
            unit_start_price_input:SetFocus()
        else
            unit_buyout_price_input:SetFocus()
        end
    end)
    stack_count_input = editbox
end
do
    -- three buttons in place of the old dropdown; they answer the same calls as the dropdown did
    local holder = CreateFrame('Frame', nil, frame.parameters)
    gui.set_size(holder, 138, 26)
    holder.buttons = {}
    for i = 1, 3 do
        local btn = small_button(holder, '', 44, gui.font_size.small)
        btn:SetPoint('TOPLEFT', (i - 1) * 47, 0)
        btn:SetScript('OnClick', function() holder:SetIndex(i) end)
        holder.buttons[i] = btn
    end
    caption(holder, holder, 'Duration', LEFT_X - 86)
    function holder:SetOptions()
        for i, btn in ipairs(self.buttons) do
            btn:SetText(info.duration_hours(i) .. 'h')
        end
    end
    function holder:GetIndex()
        return self.index
    end
    function holder:SetIndex(index)
        local changed = index ~= self.index
        self.index = index
        for i, btn in ipairs(self.buttons) do
            style_choice(btn, i == index)
        end
        if changed and self.selection_change then
            self.selection_change()
        end
    end
    function holder:SetFocus() end
    holder.selection_change = function()
        duration_selection_change()
    end
    holder:SetOptions()
    duration_dropdown = holder
end
do
    local line = frame.parameters:CreateTexture(nil, 'ARTWORK')
    line:SetColorTexture(aux.color.panel.border())
    line:SetWidth(1)
    line:SetPoint('TOPLEFT', RIGHT_X - 14, ROW1 + 4)
    line:SetPoint('BOTTOMLEFT', frame.parameters, 'TOPLEFT', RIGHT_X - 14, ROW3 - 34)
end

do
    local label = gui.label(frame.parameters, gui.font_size.small)
    label:SetPoint('TOPLEFT', RIGHT_X, ROW1 - 8)
    label:SetText('PRICE PER ITEM')
    label:SetTextColor(aux.color.header.text())
    price_caption = label
end
do
    -- the pricing mode: Match lowest (default) or Undercut with the goblin
    local switch = CreateFrame('Frame', nil, frame.parameters, 'BackdropTemplate')
    -- auxForever (0.6, the UI Kit): a sunken track with one lit option
    gui.set_frame_style(switch, function() return 9 / 255, 9 / 255, 9 / 255, 1 end, aux.color.input.border)
    gui.set_size(switch, 204, 30)
    switch:SetPoint('TOPRIGHT', -40, ROW1 + 2)
    local match = small_button(switch, 'Match lowest', 98)
    match:SetPoint('LEFT', 2, 0)
    local undercut = small_button(switch, 'Undercut', 100)
    undercut:SetPoint('LEFT', match, 'RIGHT', 2, 0)
    undercut:GetFontString():ClearAllPoints()
    undercut:GetFontString():SetPoint('LEFT', 30, 0)
    undercut:GetFontString():SetPoint('RIGHT', -6, 0)
    local goblin = undercut:CreateTexture(nil, 'ARTWORK')
    goblin:SetTexture([[Interface\AddOns\auxForever\textures\goblin.tga]])
    goblin:SetSize(18, 18)
    goblin:SetPoint('LEFT', 8, 0)
    match:SetScript('OnClick', function() set_undercut_mode(false) end)
    undercut:SetScript('OnClick', function() set_undercut_mode(true) end)
    function switch:SetChecked(on)
        for btn, selected in pairs{[match] = not on, [undercut] = on} do
            gui.style_choice(btn, selected)
            if not selected then
                btn:SetBackdropColor(0, 0, 0, 0)
                btn:SetBackdropBorderColor(0, 0, 0, 0)
            end
        end
        goblin:SetAlpha(on and 1 or .55)
    end
    switch.match_button, switch.undercut_button = match, undercut
    mode_switch = switch

    local help = small_button(frame.parameters, '?', 24, gui.font_size.medium)
    help:SetPoint('LEFT', switch, 'RIGHT', 8, 0)
    help:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:AddLine('Match lowest or undercut?')
        GameTooltip:AddLine('On Forever the newest listing at a price sells first, so matching the lowest price sells just as fast as going below it, and keeps prices from sliding.', 1, 1, 1, true)
        GameTooltip:AddLine('Undercut goes one step below: 1 copper for trade goods, 1 silver for gear. It starts off each time the auction house opens.', 1, 1, 1, true)
        GameTooltip:AddLine('/aux undercut for more', .6, .6, .6)
        GameTooltip:Show()
    end)
    help:SetScript('OnLeave', function() GameTooltip:Hide() end)
end

-- "100% of usual": the price compared with the item's usual (historical) price
local function badge(parent)
    local f = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    gui.set_frame_style(f, function() return 9 / 255, 9 / 255, 9 / 255, 1 end, aux.color.input.border)
    gui.set_size(f, 112, 24)
    local text = gui.label(f, gui.font_size.small)
    text:SetPoint('CENTER')
    function f:SetText(value)
        if value == '---' then
            text:SetText(aux.color.label.disabled('no usual price yet'))
        else
            text:SetText(value .. aux.color.label.enabled(' of usual'))
        end
    end
    return f
end

local function price_input(get_price, set_price, on_user_input)
    local editbox = gui.editbox(frame.parameters)
    editbox:SetAlignment('RIGHT')
    editbox:SetFontSize(19)
    editbox:SetTextInsets(8, 10, 3, 3)
    editbox.formatter = function()
        return money.to_string(get_price(), true)
    end
    editbox.change = function(self, is_user_input)
        refresh = true
        if is_user_input then
            on_user_input()
            set_price(money.from_string(self:GetText()) or 0)
        end
    end
    editbox.enter = function(self)
        self:ClearFocus()
    end
    editbox.focus_loss = function(self)
        self:SetText(money.to_string(get_price(), true, nil, nil, true))
    end
    editbox.caption = gui.label(editbox, gui.font_size.small)
    editbox.caption:SetPoint('RIGHT', editbox, 'LEFT', -10, 0)
    editbox.badge = badge(editbox)
    editbox.badge:SetPoint('LEFT', editbox, 'RIGHT', 10, 0)
    return editbox
end
do
    local editbox = price_input(get_unit_start_price, set_unit_start_price, function()
        set_bid_selection()
        set_buyout_selection()
    end)
    editbox.caption:SetText('Starting bid')
    editbox:SetScript('OnTabPressed', function()
	    if IsShiftKeyDown() then
		    stack_count_input:SetFocus()
	    else
		    unit_buyout_price_input:SetFocus()
	    end
    end)
    local change = editbox.change
    editbox.change = function(self, is_user_input)
        change(self, is_user_input)
        unit_buyout_price_input.reset_text = self:GetText()
    end
    start_price_percentage = editbox.badge
    unit_start_price_input = editbox
end
do
    local editbox = price_input(get_unit_buyout_price, set_unit_buyout_price, function()
        set_buyout_selection()
    end)
    editbox.caption:SetText('Buyout')
    editbox:SetScript('OnTabPressed', function()
        if IsShiftKeyDown() then
            if unit_start_price_input:IsShown() then
                unit_start_price_input:SetFocus()
            else
                stack_count_input:SetFocus()
            end
        end
    end)
    local change = editbox.change
    editbox.change = function(self, is_user_input)
        change(self, is_user_input)
        unit_start_price_input.reset_text = self:GetText()
    end
    buyout_price_percentage = editbox.badge
    unit_buyout_price_input = editbox
end
do
    local label = gui.label(frame.parameters, gui.font_size.small)
    label:SetJustifyH('LEFT')
    price_note = label
end
do
    -- auxForever (0.5, FB-003): what happened to the last post, or why Post is faded; left column,
    -- under Duration, above the line
    local label = gui.label(frame.parameters, gui.font_size.small)
    label:SetJustifyH('LEFT')
    label:SetJustifyV('TOP')
    -- two lines when needed (a gui.label is one line by default, which cut the text off, build 2)
    label:SetWordWrap(true)
    label:SetPoint('TOPLEFT', frame.parameters, 'TOPLEFT', 14, ROW3 - 2)
    label:SetPoint('BOTTOMRIGHT', frame.parameters, 'TOPLEFT', RIGHT_X - 16, -162)
    post_message = label
end

do
    local line = frame.parameters:CreateTexture(nil, 'ARTWORK')
    line:SetColorTexture(aux.color.panel.border())
    line:SetHeight(1)
    line:SetPoint('TOPLEFT', 10, -166)
    line:SetPoint('TOPRIGHT', -10, -166)
end
do
    local btn = gui.button(frame.parameters, gui.font_size.large)
    btn:SetPoint('TOPRIGHT', -10, -175)
    gui.set_size(btn, 140, 30)
    btn:SetText('Post')
    gui.set_primary(btn)
    btn:SetScript('OnClick', post_auction)
    -- auxForever (0.5): hovering a faded Post button says why (Tyler, build 3: "hovering the greyed
    -- out button does nothing"); the same reason is shown in the left column
    btn:SetMotionScriptsWhileDisabled(true)
    btn:SetScript('OnEnter', function(self)
        local reason = disabled_reason()
        if reason and not self:IsEnabled() then
            GameTooltip:SetOwner(self, 'ANCHOR_TOP')
            GameTooltip:AddLine(reason, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    btn:SetScript('OnLeave', function() GameTooltip:Hide() end)
    post_button = btn
end
do
    local function summary_label()
        local label = gui.label(frame.parameters, gui.font_size.medium)
        label:SetTextColor(aux.color.label.enabled())
        return label
    end
    -- what is posted on the left; the money right next to the Post button: the deposit going out
    -- (red) and what the sale brings in after the auction house cut (green, larger)
    posting_summary = summary_label()
    posting_summary:SetPoint('LEFT', frame.parameters, 'TOPLEFT', 14, -190)
    total_summary = summary_label()
    total_summary:SetPoint('LEFT', posting_summary, 'RIGHT', 24, 0)
    net_summary = summary_label()
    net_summary:SetFont(gui.font, gui.font_size.large)
    net_summary:SetPoint('BOTTOMRIGHT', post_button, 'LEFT', -16, -2)
    -- under "You get": the amount per item, and a warning when a vendor pays more
    net_detail = gui.label(frame.parameters, gui.font_size.small)
    net_detail:SetPoint('TOPRIGHT', post_button, 'LEFT', -16, -1)
    deposit = summary_label()
    deposit:SetPoint('RIGHT', net_summary, 'LEFT', -22, 0)
    -- the deposit explained on mouse over (a label cannot take the mouse, so a frame over it)
    local hover = CreateFrame('Frame', nil, frame.parameters)
    hover:SetAllPoints(deposit)
    hover:EnableMouse(true)
    hover:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_TOP')
        GameTooltip:AddLine('Deposit')
        GameTooltip:AddLine('Paid when you post. You get it back when the item sells; it is kept if the auction expires or you cancel it.', 1, 1, 1, true)
        GameTooltip:Show()
    end)
    hover:SetScript('OnLeave', function() GameTooltip:Hide() end)
end

-- trade goods: stack size, stacks and one price; gear: a count, a starting bid and a buyout
function M.layout_parameters(commodity)
    local function at(region, y, x, right)
        region:ClearAllPoints()
        region:SetPoint('TOPLEFT', frame.parameters, 'TOPLEFT', x, y)
        if right then
            region:SetPoint('TOPRIGHT', frame.parameters, 'TOPRIGHT', right, y)
        end
    end
    if commodity then
        at(stack_count_input, ROW1, 115)
        at(duration_dropdown, ROW2, 86)
        stack_count_input.caption:SetText('Quantity')
        at(unit_buyout_price_input, ROW2 + 2, RIGHT_X, -134)
        unit_buyout_price_input:SetHeight(34)
        unit_buyout_price_input:SetFontSize(20)
        unit_buyout_price_input.caption:Hide()
        at(price_note, ROW2 - 40, RIGHT_X, -12)
    else
        at(stack_count_input, ROW1, 115)
        at(duration_dropdown, ROW2, 86)
        stack_count_input.caption:SetText('Count')
        at(unit_start_price_input, ROW2 + 1, RIGHT_X + 82, -134)
        unit_start_price_input:SetHeight(28)
        at(unit_buyout_price_input, ROW3 + 1, RIGHT_X + 82, -134)
        unit_buyout_price_input:SetHeight(28)
        unit_buyout_price_input:SetFontSize(19)
        unit_buyout_price_input.caption:Show()
        at(price_note, ROW3 - 34, RIGHT_X, -12)
    end
end
layout_parameters(true)

function aux.event.AUX_LOADED()
	mode_switch:SetChecked(aux.account_data.post_undercut)
	if aux.account_data.post_bid then
        frame.bid_listing:Show()
        bid_listing:SetColInfo{
            {name='For sale', width=.2, align='CENTER'},
            {name='Time\nLeft', width=.15, align='CENTER'},
            {name='Auction Bid\n' .. (aux.account_data.post_bid == 'unit' and '(per item)' or '(per stack)'), width=.43, align='RIGHT'},
            {name='% Hist.\nValue', width=.22, align='CENTER'},
        }
        -- side by side, each half of the space under the parameters
        frame.bid_listing:SetPoint('TOPRIGHT', frame.parameters, 'BOTTOM', -1.25, -2.5)
        frame.buyout_listing:ClearAllPoints()
        frame.buyout_listing:SetPoint('TOPLEFT', frame.parameters, 'BOTTOM', 1.25, -2.5)
        frame.buyout_listing:SetPoint('BOTTOMRIGHT', 0, 0)
        buyout_listing:SetColInfo{
            {name='For sale', width=.2, align='CENTER'},
            {name='Time\nLeft', width=.15, align='CENTER'},
            {name='Auction Buyout\n(per item)', width=.43, align='RIGHT'},
            {name='% Hist.\nValue', width=.22, align='CENTER'},
        }
	end
end