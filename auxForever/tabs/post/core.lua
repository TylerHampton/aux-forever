select(2, ...) 'aux.tabs.post'

local aux = require 'aux'
local info = require 'aux.util.info'
local sort_util = require 'aux.util.sort'
local persistence = require 'aux.util.persistence'
local money = require 'aux.util.money'
local scan_util = require 'aux.util.scan'
local scan = require 'aux.core.scan'
local history = require 'aux.core.history'
local item_listing = require 'aux.gui.item_listing'
local al = require 'aux.gui.auction_listing'
local gui = require 'aux.gui'

local tab = aux.tab 'Post'

-- auxForever: the item whose price is picked once its listings are in (auto_pick_price), and
-- which items' listings are complete enough to pick from
local auto_price_key
local listings_ready = {}

local settings_schema = {'tuple', '#', {duration='number'}, {start_price='number'}, {buyout_price='number'}, {hidden='boolean'}}

local inventory_records, bid_records, buyout_records = {}, {}, {}

-- Forever: duration options 1-3 of the auction house (see info.duration_hours for their lengths)
M.DURATION_2, M.DURATION_8, M.DURATION_24 = 1, 2, 3

refresh = true

posting = nil

last_post_update = nil

selected_item = nil

function get_default_settings()
	return { duration = aux.account_data.post_duration, start_price = 0, buyout_price = 0, hidden = false }
end

function aux.event.AUCTION_HOUSE_LOADED()
    for slot in info.inventory() do
        AuxTooltip:SetBagItem(unpack(slot))
    end
end

StaticPopupDialogs.AUX_POST_CONFIRM = {
    text = '%s',
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function()
        confirm_post()
    end,
    OnCancel = function()
        if pending_post then
            post_outcome = 'cancelled'
        end
        pending_post = nil
        posting = nil
    end,
    showAlert = 1,
    timeout = 0,
    hideOnEscape = 1,
}

function aux.event.AUX_LOADED()
    -- Forever: the server can ask to confirm a post (e.g. a price far from the market); aux shows its own dialog
    aux.event_listener('AUCTION_HOUSE_POST_WARNING', function()
        if pending_post then
            StaticPopup_Show('AUX_POST_CONFIRM', CONFIRM_AUCTION_POSTING_TEXT)
        end
    end)
    aux.event_listener('AUCTION_HOUSE_POST_ERROR', function()
        if pending_post then
            StaticPopup_Show('AUX_POST_CONFIRM', AUCTION_POSTING_ERROR_TEXT)
        end
    end)
    -- auxForever (0.5, FB-003): the game's own error text while a post is under way (it shows it in
    -- red at the top of the screen, easy to miss) is repeated in the Post tab if the post fails
    aux.event_listener('UI_ERROR_MESSAGE', function(_, text)
        if posting and type(text) == 'string' then
            post_error_text = text
        end
    end)
    aux.event_listener('AUCTION_HOUSE_SHOW_ERROR', function()
        if posting then
            post_outcome = 'refused'
            StaticPopup_Hide('AUX_POST_CONFIRM')
            pending_post = nil
            posting = nil
            last_post_update = nil
        end
    end)
    aux.event_listener('BAG_UPDATE', function()
        if posting == 'single' then
            posting = nil
            last_post_update = nil
        end
    end)
    aux.event_listener('AUCTION_MULTISELL_FAILURE', function()
        if posting == 'multi' then
            posting = nil
            last_post_update = nil
        end
    end)
    aux.event_listener('AUCTION_MULTISELL_UPDATE', function(count, total)
        if posting == 'multi' and count == total then
            posting = 'single'
            last_post_update = GetTime()
        end
    end)
end

function aux.event.PLAYER_LOGIN()
	data = aux.faction_data.post
end

function read_settings(item_key)
	item_key = item_key or selected_item.key
	return data[item_key] and persistence.read(settings_schema, data[item_key]) or get_default_settings()
end
function write_settings(settings, item_key)
	item_key = item_key or selected_item.key
	data[item_key] = persistence.write(settings_schema, settings)
end

do
	local bid_selections, buyout_selections = {}, {}
	function get_bid_selection()
		return bid_selections[selected_item.key]
	end
	function set_bid_selection(record)
		bid_selections[selected_item.key] = record
	end
	function get_buyout_selection()
		return buyout_selections[selected_item.key]
	end
	function set_buyout_selection(record)
		buyout_selections[selected_item.key] = record
	end
end

function refresh_button_click()
	scan.abort()
	refresh_entries()
	refresh = true
end

function tab.OPEN()
    frame:Show()
    update_inventory_records(true)
    refresh = true
    update_post_done()
end

function tab.CLOSE()
    selected_item = nil
    ClearCursor()
    frame:Hide()
    aux.status_bar:set_done(false)
end

-- auxForever: the status bar turns gold once the listings of the item being posted are in, like a
-- finished search on the Search tab, and goes back to normal for another item or another tab.
-- Only while the Post tab is shown, so it never changes the Search tab's bar.
function M.update_post_done()
    if frame:IsShown() then
        aux.status_bar:set_done(selected_item and listings_ready[selected_item.key] and true or false)
    end
end

function tab.USE_ITEM(item_id, suffix_id)
	select_item(item_id .. ':' .. suffix_id)
end

function get_unit_start_price()
	return selected_item and read_settings().start_price or 0
end

function set_unit_start_price(amount)
	local settings = read_settings()
	settings.start_price = amount > 0 and round_price(amount) or 0
	write_settings(settings)
end

function get_unit_buyout_price()
	return selected_item and read_settings().buyout_price or 0
end

function set_unit_buyout_price(amount)
	local settings = read_settings()
	settings.buyout_price = amount > 0 and round_price(amount) or 0
	write_settings(settings)
end

-- the items in the list on the left, in the order shown
function visible_inventory()
	local records = aux.values(aux.filter(aux.copy(inventory_records), function(record)
		local settings = read_settings(record.key)
		return record.count > 0 and (not settings.hidden or show_hidden_checkbox:GetChecked())
	end))
	sort(records, function(a, b) return a.name < b.name end)
	return records
end

function update_inventory_listing()
	item_listing.populate(inventory_listing, visible_inventory())
end

-- auxForever (0.4): after everything of an item was posted, the next item in the list is selected,
-- so posting several items is one click each
function M.next_item_after(name, key, records)
	local best
	for _, record in ipairs(records or visible_inventory()) do
		if record.key ~= key and record.count > 0 and record.name > name and (not best or record.name < best.name) then
			best = record
		end
	end
	return best
end

function update_auction_listing(listing, records, reference)
	local rows = {}
	if selected_item then
		local historical_value = history.value(selected_item.key)
		local stack_size = stack_size_input:GetNumber()
		-- every price in the list keeps all its parts when any of them has copper (money.set_full_parts)
		local amounts = {historical_value and ceil(historical_value) or 0}
		for _, record in pairs(records[selected_item.key] or empty) do
			tinsert(amounts, ceil(record.unit_price or 0))
		end
		money.set_full_parts(money.any_copper(amounts))
		for _, record in pairs(records[selected_item.key] or empty) do
			local price_color = tonumber(tostring(undercut(record, stack_size_input:GetNumber(), listing == 'bid'))) < reference and aux.color.red
			local price = record.unit_price * (listing == 'bid' and aux.account_data.post_bid == 'stack' and record.stack_size or 1)
			-- units for sale at this price (yours in green)
			local units = record.count * (record.stack_size or 1)
			tinsert(rows, {
				cols = {
                { value = record.own and aux.color.green(units) or units },
				{ value = al.time_left(record.duration) },
				{ value = money.to_string(price, true, nil, price_color) },
				{ value = historical_value and gui.percentage_historical(aux.round(price / historical_value * 100)) or '---' },
            },
				record = record,
            })
		end
		if historical_value then
			tinsert(rows, {
				cols = {
				{ value = '---' },
				{ value = '---' },
				{ value = money.to_string(historical_value * (listing == 'bid' and aux.account_data.post_bid == 'stack' and stack_size_input:GetNumber() or 1), true, nil, aux.color.green) },
				{ value = historical_value and gui.percentage_historical(100) or '---' },
            },
				record = { historical_value = true, stack_size = stack_size, unit_price = historical_value }
            })
		end
		money.set_full_parts(false)
		sort(rows, function(a, b)
			return sort_util.multi_lt(
				a.record.unit_price * (listing == 'bid' and a.record.stack_size or 1),
				b.record.unit_price * (listing == 'bid' and b.record.stack_size or 1),

				a.record.historical_value and 1 or 0,
				b.record.historical_value and 1 or 0,

				b.record.own and 0 or 1,
				a.record.own and 0 or 1,

				a.record.stack_size,
				b.record.stack_size,

				a.record.duration,
				b.record.duration
			)
		end)
	end
	if listing == 'bid' then
		bid_listing:SetData(rows)
	elseif listing == 'buyout' then
		buyout_listing:SetData(rows)
	end
end

function update_auction_listings()
	update_auction_listing('bid', bid_records, get_unit_start_price())
	update_auction_listing('buyout', buyout_records, get_unit_buyout_price())
end

function M.select_item(item_key)
    for _, inventory_record in pairs(aux.filter(aux.copy(inventory_records), function(record) return record.count > 0 end)) do
        if inventory_record.key == item_key then
            update_item(inventory_record)
            return
        end
    end
end

function price_update()
    if selected_item then
        local historical_value = history.value(selected_item.key)
        if get_bid_selection() or get_buyout_selection() then
	        set_unit_start_price(undercut(get_bid_selection() or get_buyout_selection(), stack_size_input:GetNumber(), get_bid_selection()))
	        unit_start_price_input:SetText(money.to_string(get_unit_start_price(), true, nil, nil, true))
        end
        if get_buyout_selection() then
	        set_unit_buyout_price(undercut(get_buyout_selection(), stack_size_input:GetNumber()))
	        unit_buyout_price_input:SetText(money.to_string(get_unit_buyout_price(), true, nil, nil, true))
        end
        start_price_percentage:SetText(historical_value and gui.percentage_historical(aux.round(get_unit_start_price() / historical_value * 100)) or '---')
        buyout_price_percentage:SetText(historical_value and gui.percentage_historical(aux.round(get_unit_buyout_price() / historical_value * 100)) or '---')
        price_note:SetText(price_note_text())
    end
end

-- auxForever (0.5, FB-003): a post that does not happen always says why, in the Post tab (left,
-- under Duration) and in chat. Darkhorse clicked Post once and nothing happened, with no message.
local message, message_color, message_until

function M.show_post_message(text, color, seconds)
    message, message_color, message_until = text, color or aux.color.red, GetTime() + (seconds or 12)
    if color ~= aux.color.positive then
        aux.print(text)
    end
    refresh = true
end

local NOT_POSTED = {
    gone = 'Not posted: the item is no longer in your bags.',
    locked = 'Not posted: the item is on your mouse pointer, or in a trade or the mail.',
    damaged = 'Not posted: this item must be repaired first.',
    invalid = 'Not posted: the auction house does not accept this item.',
    refused = 'Not posted: the auction house refused it.',
    timeout = 'No answer from the auction house. Check the Auctions tab before posting again.',
    cancelled = 'Not posted: you cancelled it.',
    unchanged = 'Not posted, as far as aux can tell: the item is still in your bags.',
}
M.NOT_POSTED = NOT_POSTED

-- why no bag slot with the item can be posted (find_item_location found none)
function M.missing_item_reason(item_key)
    local reason = 'gone'
    for slot in info.inventory() do
        local item_info = info.container_item(unpack(slot))
        if item_info and item_info.item_key == item_key then
            local durability, max_durability = C_Container.GetContainerItemDurability(unpack(slot))
            if item_info.locked then
                return 'locked'
            elseif durability and max_durability and durability < max_durability then
                reason = 'damaged'
            elseif reason == 'gone' then
                reason = 'invalid'
            end
        end
    end
    return reason
end

-- how many of the item are in the bags, postable or not
function M.bag_count(item_key)
    local count = 0
    for slot in info.inventory() do
        local item_info = info.container_item(unpack(slot))
        if item_info and item_info.item_key == item_key then
            count = count + (item_info.count or 1)
        end
    end
    return count
end

-- the message after a post ends: how many left the bags against how many were meant to
function M.post_result_text(outcome, wanted, posted, name, error_text)
    if posted > 0 then
        if posted < wanted then
            return 'Posted ' .. posted .. ' of ' .. wanted .. ' × ' .. name .. (error_text and ('. The game said: ' .. error_text) or ''), aux.color.gold
        end
        return 'Posted ' .. posted .. ' × ' .. name, aux.color.positive
    end
    local text = NOT_POSTED[outcome] or NOT_POSTED.unchanged
    if error_text then
        text = text .. ' The game said: ' .. error_text
    end
    return text, aux.color.red
end

-- Finds a bag slot holding the item that can be put up for auction
function find_item_location(item_key)
    for slot in info.inventory() do
        local item_info = info.container_item(unpack(slot))
        if item_info and item_info.auctionable and not item_info.locked and item_info.item_key == item_key then
            return item_info.item_location
        end
    end
end

function confirm_post()
    last_post_update = GetTime()
    if pending_post then
        local post = pending_post
        pending_post = nil
        if post.commodity then
            C_AuctionHouse.ConfirmPostCommodity(post.location, post.duration, post.quantity, post.unit_price)
        else
            C_AuctionHouse.ConfirmPostItem(post.location, post.duration, post.quantity, post.bid, post.buyout)
        end
    end
end

-- Bid and buyout for an item auction. The server refuses a buyout that is not above the starting bid
-- ("Internal auction error"; Blizzard's own sell frame blocks it too), so a starting bid at or above
-- the buyout is left out and the item is posted for buyout only, at the price the player sees.
function M.item_post_prices(start_price, buyout_price)
    local buyout = buyout_price > 0 and round_price(buyout_price) or nil
    local bid = round_price(max(1, start_price))
    if buyout and bid >= buyout then
        bid = nil
    end
    return bid, buyout
end

-- Forever: commodities are posted as one listing of (stack size x stack count) units at a unit price;
-- other items are posted as one auction per item.
function post_auction()
    local item_key = selected_item.key

    local stack_size = stack_size_input:GetNumber()
    local stack_count = stack_count_input:GetNumber()
    local duration = duration_dropdown:GetIndex()

    local location = find_item_location(item_key)
    if not location then
        show_post_message(NOT_POSTED[missing_item_reason(item_key)])
        return
    end

    StaticPopup_Hide('AUX_POST_CONFIRM')
    post_outcome, post_error_text, message = nil, nil, nil
    local bags_before = bag_count(item_key)
    local wanted = post_quantity()
    local name = selected_item.name or '?'
    local post
    if selected_item.commodity then
        post = {
            commodity = true,
            location = location,
            duration = duration,
            quantity = stack_size * stack_count,
            unit_price = round_price(get_unit_buyout_price()),
        }
        pending_post = post
        if not C_AuctionHouse.PostCommodity(post.location, post.duration, post.quantity, post.unit_price) then
            pending_post = nil
        end
        posting = 'single'
    else
        local bid, buyout = item_post_prices(get_unit_start_price(), get_unit_buyout_price())
        post = {
            location = location,
            duration = duration,
            quantity = stack_count,
            bid = bid,
            buyout = buyout,
        }
        pending_post = post
        if not C_AuctionHouse.PostItem(post.location, post.duration, post.quantity, post.bid, post.buyout) then
            pending_post = nil
        end
        posting = stack_count == 1 and 'single' or 'multi'
    end

    aux.coro_thread(function()
        last_post_update = GetTime()
        while posting do
            -- waits longer while a confirmation dialog is open
            if GetTime() - last_post_update > (pending_post and 60 or 5) then
                post_outcome = post_outcome or 'timeout'
                StaticPopup_Hide('AUX_POST_CONFIRM')
                pending_post = nil
                posting = nil
                last_post_update = nil
                break
            end
            aux.coro_wait()
            if not frame:IsShown() then
                return
            end
        end

        do
            local posted = max(0, bags_before - bag_count(item_key))
            show_post_message(post_result_text(post_outcome, wanted, posted, name, post_error_text))
            post_outcome, post_error_text = nil, nil
        end
        update_inventory_records()
        local all_posted = true
        for _, record in pairs(inventory_records) do
            if record.key == item_key then
                all_posted = false
                break
            end
        end
        if selected_item and selected_item.key == item_key then
            if all_posted then
                local next_item = next_item_after(selected_item.name, item_key)
                selected_item = nil
                if next_item then
                    update_item(next_item)
                end
            else
                update_item(selected_item)
            end
        end
        refresh = true
    end)
end

-- auxForever: the line under the price saying how it was chosen
function M.price_note_text()
    local selection = get_buyout_selection() or get_bid_selection()
    local note
    if not selection then
        note = aux.color.label.enabled('Your own price')
    elseif selection.historical_value then
        note = aux.color.label.enabled('The usual price for this item')
    elseif selection.own then
        note = aux.color.label.enabled('Same as your own listing at ') .. money.to_string(selection.unit_price, true)
    elseif aux.account_data.post_undercut then
        local step = price_step() == 1 and '1 copper' or '1 silver'
        note = aux.color.gold(step .. ' below the lowest listing (') .. money.to_string(selection.unit_price, true) .. aux.color.gold(')')
        if price_step() > 1 then
            note = note .. aux.color.gold('. Gear is priced in whole silver')
        end
    else
        note = aux.color.label.enabled('Same as the lowest listing')
    end
    -- gear: a starting bid equal to the buyout is left out when posting (item_post_prices)
    if selected_item and not selected_item.commodity and get_unit_buyout_price() > 0 then
        local bid = item_post_prices(get_unit_start_price(), get_unit_buyout_price())
        if not bid and get_unit_start_price() <= get_unit_buyout_price() then
            note = note .. '\n' .. aux.color.label.disabled('Bid equals buyout, so it posts as buyout only')
        end
    end
    return note
end

-- the Post button fades when it cannot be used, since its amber color would otherwise look ready
local post_enabled
local function set_post_enabled(enabled)
    if enabled == post_enabled then return end
    post_enabled = enabled
    if enabled then
        post_button:Enable()
        post_button:SetAlpha(1)
    else
        post_button:Disable()
        post_button:SetAlpha(.45)
    end
end

-- auxForever (0.5, FB-003): why the Post button is faded, shown next to it (nil when it is not)
function M.disabled_reason()
    if not selected_item then
        return
    elseif posting then
        return 'Posting...'
    elseif get_unit_buyout_price() > 0 and get_unit_start_price() > get_unit_buyout_price() then
        return 'The starting bid is above the buyout.'
    elseif selected_item.commodity and get_unit_buyout_price() == 0 then
        return 'Type a price to post.'
    elseif not selected_item.commodity and get_unit_start_price() == 0 then
        return 'Type a price to post.'
    elseif stack_count_input:GetNumber() == 0 then
        return 'Choose how many to post.'
    elseif deposit_amount() > GetMoney() then
        return 'Not enough money for the deposit.'
    end
end

local shown_message
function update_post_message(reason)
    local text
    if message and GetTime() < message_until then
        text = message_color(message)
    else
        text = reason and aux.color.label.enabled(reason) or ''
    end
    if text ~= shown_message then
        shown_message = text
        post_message:SetText(text)
    end
end

function validate_parameters()
    local reason = disabled_reason()
    update_post_message(reason)
    set_post_enabled(selected_item and not reason and true or false)
end

-- auxForever: how many units the current settings post (one auction per item for gear)
function M.post_quantity()
    if not selected_item then
        return 0
    elseif selected_item.commodity then
        return stack_size_input:GetNumber() * stack_count_input:GetNumber()
    end
    return stack_count_input:GetNumber()
end

function update_item_configuration()
    local summary = {posting_summary, total_summary, cut_label, cut_summary, receipt_line, net_label, net_summary, net_detail, deposit_label, deposit, price_note, price_caption, usual_caption, mode_switch}
	if not selected_item then
        refresh_button:Disable()

        item.texture:SetTexture(nil)
        item.count:SetText()
        item.name:SetTextColor(aux.color.label.enabled())
        item.name:SetText('No item selected')
        item_detail:SetText('Pick an item on the left, or drop one here')

        unit_start_price_input:Hide()
        unit_buyout_price_input:Hide()
        stack_size_input:Hide()
        stack_count_input:Hide()
        duration_dropdown:Hide()
        hide_checkbox:Hide()
        for _, region in ipairs(summary) do region:Hide() end
        vendor_warning:Hide()
        post_button:SetText('Post')
    else
		-- Forever: commodities have no bids, only a buyout price per unit; gear is posted one per auction
		if selected_item.commodity then
			unit_start_price_input:Hide()
		else
			unit_start_price_input:Show()
		end
		stack_size_input:Hide()
        layout_parameters(selected_item.commodity)
        unit_buyout_price_input:Show()
        stack_count_input:Show()
        duration_dropdown:Show()
        hide_checkbox:Show()
        for _, region in ipairs(summary) do region:Show() end

        item.texture:SetTexture(selected_item.texture)
        item.name:SetText(selected_item.name)
		do
	        local color = ITEM_QUALITY_COLORS[selected_item.quality]
	        item.name:SetTextColor(color.r, color.g, color.b)
        end
		if selected_item.count > 1 then
            item.count:SetText(selected_item.count)
		else
            item.count:SetText()
        end
        item_detail:SetText(selected_item.count .. ' in your bags')

        local quantity = post_quantity()
        local unit_price = get_unit_buyout_price() > 0 and get_unit_buyout_price() or get_unit_start_price()
        local total = unit_price * quantity
        local items = quantity .. (quantity == 1 and ' item' or ' items')
        posting_summary:SetText((get_unit_buyout_price() > 0 and 'Total, ' or 'Starting bids, ') .. items)
        total_summary:SetText(money.to_string(total, true))
        cut_summary:SetText(aux.color.negative('-') .. money.to_string(total - floor(total * (1 - AUCTION_CUT)), true, nil, aux.color.negative))
        do
            -- money going out in red (bright red when it is more than the player has), coming in green
            local amount = deposit_amount()
            local out = amount > GetMoney() and aux.color.red or aux.color.negative
            deposit:SetText(out('-') .. money.to_string(amount, true, nil, out))
        end
        do
            -- what the sale brings in; red, with the warning box, when a vendor would pay more
            local net = floor(total * (1 - AUCTION_CUT))
            local vendor = (selected_item.unit_vendor_price or 0) * quantity
            local below_vendor = vendor > 0 and net < vendor
            local color = below_vendor and aux.color.red or aux.color.positive
            net_summary:SetText(money.to_string(net, true, nil, color))
            local parts = {}
            if quantity > 1 then
                tinsert(parts, money.to_string(floor(unit_price * (1 - AUCTION_CUT)), true) .. ' each')
            end
            if below_vendor then
                vendor_warning.amount:SetText(money.to_string(vendor, true))
            elseif vendor > 0 then
                tinsert(parts, 'vendor pays ' .. money.to_string(vendor, true))
            end
            net_detail:SetText(table.concat(parts, ', '))
            -- shown or hidden only when it changes (AGENTS.md: never hide and show every frame)
            if below_vendor ~= vendor_warning:IsShown() then
                if below_vendor then vendor_warning:Show() else vendor_warning:Hide() end
            end
        end
        post_button:SetText('Post ' .. quantity .. (quantity == 1 and ' item' or ' items'))

        refresh_button:Enable()
	end
end

function deposit_amount()
    local duration = duration_dropdown:GetIndex()
    local stack_size, stack_count = stack_size_input:GetNumber(), stack_count_input:GetNumber()
    if selected_item.commodity then
        return C_AuctionHouse.CalculateCommodityDeposit(selected_item.item_id, duration, stack_size * stack_count) or 0
    end
    local location = selected_item.item_location
    if location and location:IsValid() and C_Item.DoesItemExist(location) then
        return C_AuctionHouse.CalculateItemDeposit(location, duration, stack_count) or 0
    end
    return 0
end

-- Forever: gear and other items that are not trade goods are priced in whole silver (no gear
-- listing ever shows copper); trade goods ("commodities") can use copper when the auction house
-- supports copper values. Prices are rounded down, so the price shown is the price posted.
function M.price_step()
    if selected_item and selected_item.commodity and C_AuctionHouse.SupportsCopperValues() then
        return 1
    end
    return 100
end

function M.round_price(amount)
    local step = price_step()
    return max(step, floor(amount / step) * step)
end

-- auxForever: on Forever the newest listing at a price sells first, so by default aux matches the
-- cheapest price. Undercut mode (the goblin toggle) goes one step below it, like aux on Classic.
function M.undercut(record, stack_size, bid)
    if record.historical_value or record.own or not aux.account_data.post_undercut then
        return record.unit_price
    else
        -- one step below: 1 copper for trade goods, 1 silver for gear
        local step = price_step()
        return max(step, round_price(record.unit_price) - step)
    end
end

function quantity_update(maximize_count)
    if selected_item then
        -- Forever: a trade good is posted as one listing of any quantity, so there are no stacks:
        -- stack size stays 1 and the count is the quantity, up to everything in the bags
        local location = selected_item.item_location
        local max_stack_count = selected_item.count
        if location and location:IsValid() and C_Item.DoesItemExist(location) then
            max_stack_count = min(max_stack_count, max(1, C_AuctionHouse.GetAvailablePostCount(location)))
        end
        stack_count_input.max_value = max_stack_count
        if maximize_count then
            stack_count_input:SetNumber(max_stack_count)
        end
    end
    refresh = true
end

function update_item(item)
    local settings = read_settings(item.key)

    item.unit_vendor_price = select(11, GetItemInfo(item.item_id)) or 0

    scan.abort()

    selected_item = item -- must be before the dropdown and slider setup

    do
        local options = {}
        for i = 1, 3 do
            tinsert(options, aux.pluralize(info.duration_hours(i) .. ' ' .. HOURS))
        end
        duration_dropdown:SetOptions(options)
    end
    duration_dropdown:SetIndex(settings.duration)

    hide_checkbox:SetChecked(settings.hidden)

    stack_size_input.max_value = 1
    stack_size_input:SetNumber(1)
    quantity_update(true)

    unit_start_price_input:SetText(money.to_string(settings.start_price, true, nil, nil, true))
    unit_buyout_price_input:SetText(money.to_string(settings.buyout_price, true, nil, nil, true))
    write_settings(settings, item.key)

    -- start from the lowest listing once the listings are in (auto_pick_price)
    auto_price_key = item.key
    if not listings_known(item.key) then
        refresh_entries()
    else
        listings_ready[item.key] = true
    end
    update_post_done()

    refresh = true
end

function update_inventory_records(reset)
    local auctionable_map = {}
    for slot in info.inventory() do
	    local item_info = info.container_item(unpack(slot))
        if item_info and item_info.auctionable then
            if not auctionable_map[item_info.item_key] then
                auctionable_map[item_info.item_key] = {
                    item_id = item_info.item_id,
                    suffix_id = item_info.suffix_id,
                    key = item_info.item_key,
                    link = item_info.link,
                    name = item_info.name,
                    texture = item_info.texture,
                    quality = item_info.quality,
                    count = item_info.count,
                    max_stack = item_info.max_stack,
                    item_location = item_info.item_location,
                    commodity = C_AuctionHouse.GetItemCommodityStatus(item_info.item_location) == Enum.ItemCommodityStatus.Commodity,
                }
            else
                local auctionable = auctionable_map[item_info.item_key]
                auctionable.count = auctionable.count + item_info.count
            end
        end
    end

    if reset then
        inventory_records = aux.values(auctionable_map)
    else
        for i = #inventory_records, 1, -1 do
            local new_record = auctionable_map[inventory_records[i].key]
            if new_record then
                for k in pairs(new_record) do
                    inventory_records[i][k] = new_record[k]
                end
            else
                tremove(inventory_records, i)
            end
        end
    end
end

-- auxForever: once an item's listings are in, start from the price most posts use: the lowest
-- listing (matched, or one step below in undercut mode), else the item's usual price, so the
-- player can post right away. Picking a row or typing a price afterwards still wins.
function M.auto_pick_price()
    if not selected_item or auto_price_key ~= selected_item.key or not listings_ready[selected_item.key] then
        return
    end
    auto_price_key = nil
    local cheapest
    for _, record in pairs(buyout_records[selected_item.key] or empty) do
        if not cheapest or record.unit_price < cheapest.unit_price or (record.unit_price == cheapest.unit_price and cheapest.own and not record.own) then
            cheapest = record
        end
    end
    if not cheapest then
        local historical_value = history.value(selected_item.key)
        if historical_value then
            cheapest = { historical_value = true, stack_size = stack_size_input:GetNumber(), unit_price = historical_value }
        end
    end
    if cheapest then
        set_buyout_selection(cheapest)
        set_bid_selection()
        refresh = true
    end
end

function refresh_entries()
	if selected_item then
        local item_key = selected_item.key
		set_bid_selection()
        set_buyout_selection()
        auto_price_key = item_key
        listings_ready[item_key] = nil
        update_post_done()
        bid_records[item_key], buyout_records[item_key] = nil, nil
        local query = scan_util.item_query(selected_item.item_id)

		scan.start{
            type = 'list',
            sort_type = 'unitprice',
            ignore_owner = true,
			queries = {query},
            on_scan_start = function()
                aux.status_bar:update_status(0, 0)
            end,
            on_page_loaded = function(page, total_pages)
                aux.status_bar:update_status(page / total_pages, 0)
            end,
            on_page_scanned = function()
                bid_records[item_key] = bid_records[item_key] or {}
                buyout_records[item_key] = buyout_records[item_key] or {}
                listings_ready[item_key] = true
                refresh = true
                if not aux.account_data.post_full_scan and next(buyout_records[item_key]) then
                    scan.abort()
                    aux.coro_wait()
                end
            end,
			on_auction = function(auction_record)
				if auction_record.item_key == item_key then
                    record_auction(auction_record)
				end
			end,
			on_abort = function()
                aux.status_bar:update_status(1, 1)
                listings_ready[item_key] = true
                refresh = true
                update_post_done()
			end,
			on_complete = function()
                aux.status_bar:update_status(1, 1)
                bid_records[item_key] = bid_records[item_key] or {}
                buyout_records[item_key] = buyout_records[item_key] or {}
                listings_ready[item_key] = true
                refresh = true
                update_post_done()
            end,
		}
	end
end

-- auxForever: a full scan reads every auction on the auction house (69,591 in Tyler's, 0.4.1) and
-- aux kept the listings of every item for the Post tab, all session long: about 30 MB after a
-- cleanup. The Post tab only shows items in your bags, so the full scan now keeps theirs alone;
-- any other item's listings are read when it is picked, as before.
local scan_keys

function M.clear_auctions()
    bid_records, buyout_records = {}, {}
    aux.wipe(listings_ready)
    scan_keys = {}
    for slot in info.inventory() do
        local item_info = info.container_item(unpack(slot))
        if item_info then
            scan_keys[item_info.item_key] = true
        end
    end
    update_post_done()
end

-- an auction from a full scan: kept only for items in the bags
function M.record_scanned_auction(auction)
    if scan_keys and scan_keys[auction.item_key] then
        record_auction(auction)
    end
end

-- /aux memory detail: items whose listings the Post tab keeps
function M.memory_counts()
    local n = 0
    for _ in pairs(bid_records) do n = n + 1 end
    return n
end

-- whether the listings of an item are known (from a full scan or an earlier read)
function M.listings_known(item_key)
    return bid_records[item_key] ~= nil
end

function M.record_auction(auction)
    bid_records[auction.item_key] = bid_records[auction.item_key] or {}
    if not auction.commodity then
	    local entry
	    for _, record in pairs(bid_records[auction.item_key]) do
	        if auction.unit_blizzard_bid == record.unit_price and auction.count == record.stack_size and auction.duration == record.duration and info.is_player(auction.owner) == record.own then
	            entry = record
	        end
	    end
	    if not entry then
	        entry =  { stack_size = auction.count, unit_price = auction.unit_blizzard_bid, duration = auction.duration, own = info.is_player(auction.owner), count = 0 }
	        tinsert(bid_records[auction.item_key], entry)
	    end
	    entry.count = entry.count + (auction.auction_count or 1)
    end
    buyout_records[auction.item_key] = buyout_records[auction.item_key] or {}
    if auction.unit_buyout_price == 0 then return end
    do
	    local entry
	    for _, record in pairs(buyout_records[auction.item_key]) do
		    if auction.unit_buyout_price == record.unit_price and auction.count == record.stack_size and auction.duration == record.duration and info.is_player(auction.owner) == record.own then
			    entry = record
		    end
	    end
	    if not entry then
		    entry = { stack_size = auction.count, unit_price = auction.unit_buyout_price, duration = auction.duration, own = info.is_player(auction.owner), count = 0 }
		    tinsert(buyout_records[auction.item_key], entry)
	    end
	    entry.count = entry.count + (auction.auction_count or 1)
    end
end

-- auxForever: the Post button is checked (price boxes read, deposit asked from the game) five times
-- a second and after every change, not every frame as before
function on_update()
    auto_pick_price()
    local changed = refresh
    if refresh then
        refresh = false
        price_update()
        update_item_configuration()
        update_inventory_listing()
        update_auction_listings()
    end
    if changed or GetTime() >= (next_validate or 0) then
        next_validate = GetTime() + .2
        validate_parameters()
    end
end

function M.set_undercut_mode(enabled)
    aux.account_data.post_undercut = enabled and true or false
    mode_switch:SetChecked(aux.account_data.post_undercut)
    price_update()
    refresh = true
end

function duration_selection_change()
    if selected_item then
        local settings = read_settings()
        settings.duration = duration_dropdown:GetIndex()
        write_settings(settings)
        refresh = true
    end
end
