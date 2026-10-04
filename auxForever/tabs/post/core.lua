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
end

function tab.CLOSE()
    selected_item = nil
    ClearCursor()
    frame:Hide()
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

function update_inventory_listing()
	local records = aux.values(aux.filter(aux.copy(inventory_records), function(record)
		local settings = read_settings(record.key)
		return record.count > 0 and (not settings.hidden or show_hidden_checkbox:GetChecked())
	end))
	sort(records, function(a, b) return a.name < b.name end)
	item_listing.populate(inventory_listing, records)
end

function update_auction_listing(listing, records, reference)
	local rows = {}
	if selected_item then
		local historical_value = history.value(selected_item.key)
		local stack_size = stack_size_input:GetNumber()
		for _, record in pairs(records[selected_item.key] or empty) do
			local price_color = tonumber(tostring(undercut(record, stack_size_input:GetNumber(), listing == 'bid'))) < reference and aux.color.red
			local price = record.unit_price * (listing == 'bid' and aux.account_data.post_bid == 'stack' and record.stack_size or 1)
			tinsert(rows, {
				cols = {
                { value = record.own and aux.color.green(record.count) or record.count },
				{ value = al.time_left(record.duration) },
				{ value = record.stack_size == stack_size and aux.color.green(record.stack_size) or record.stack_size },
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
				{ value = '---' },
				{ value = money.to_string(historical_value * (listing == 'bid' and aux.account_data.post_bid == 'stack' and stack_size_input:GetNumber() or 1), true, nil, aux.color.green) },
				{ value = historical_value and gui.percentage_historical(100) or '---' },
            },
				record = { historical_value = true, stack_size = stack_size, unit_price = historical_value }
            })
		end
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

-- Forever: commodities are posted as one listing of (stack size x stack count) units at a unit price;
-- other items are posted as one auction per item.
function post_auction()
    local item_key = selected_item.key

    local stack_size = stack_size_input:GetNumber()
    local stack_count = stack_count_input:GetNumber()
    local duration = duration_dropdown:GetIndex()

    local location = find_item_location(item_key)
    if not location then
        return
    end

    StaticPopup_Hide('AUX_POST_CONFIRM')
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
        local buyout = get_unit_buyout_price() > 0 and round_price(get_unit_buyout_price()) or nil
        post = {
            location = location,
            duration = duration,
            quantity = stack_count,
            bid = round_price(max(1, get_unit_start_price())),
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
                selected_item = nil
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
        return aux.color.label.enabled('Your own price')
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
        note = aux.color.label.enabled('Same as the lowest listing. On Forever the newest listing at a price sells first')
    end
    return note
end

-- the Post button fades when it cannot be used, since its amber color would otherwise look ready
local function set_post_enabled(enabled)
    if enabled then
        post_button:Enable()
        post_button:SetAlpha(1)
    else
        post_button:Disable()
        post_button:SetAlpha(.45)
    end
end

function validate_parameters()
    if posting or not selected_item then
        set_post_enabled(false)
        return
    end
    if get_unit_buyout_price() > 0 and get_unit_start_price() > get_unit_buyout_price() then
        set_post_enabled(false)
        return
    end
    if selected_item.commodity and get_unit_buyout_price() == 0 then
        set_post_enabled(false)
        return
    end
    if not selected_item.commodity and get_unit_start_price() == 0 then
        set_post_enabled(false)
        return
    end
    if stack_count_input:GetNumber() == 0 then
        set_post_enabled(false)
        return
    end
    if deposit_amount() > GetMoney() then
        set_post_enabled(false)
        return
    end
    set_post_enabled(true)
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
    local summary = {posting_summary, total_summary, deposit, net_summary, price_note, price_caption, mode_switch}
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
        post_button:SetText('Post')
    else
		-- Forever: commodities have no bids, only a buyout price per unit; gear is posted one per auction
		if selected_item.commodity then
			unit_start_price_input:Hide()
			stack_size_input:Show()
		else
			unit_start_price_input:Show()
			stack_size_input:Hide()
		end
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
        item_detail:SetText(selected_item.count .. ' in your bags' .. ((selected_item.commodity and (selected_item.max_stack or 1) > 1) and ' · stack of ' .. selected_item.max_stack or ''))

        local quantity = post_quantity()
        local unit_price = get_unit_buyout_price() > 0 and get_unit_buyout_price() or get_unit_start_price()
        local total = unit_price * quantity
        posting_summary:SetText('Posting ' .. aux.color.text.enabled(quantity .. (quantity == 1 and ' item' or ' items')))
        total_summary:SetText((get_unit_buyout_price() > 0 and 'Total ' or 'Starting bids ') .. money.to_string(total, true))
        do
            local amount = deposit_amount()
            deposit:SetText('Deposit ' .. money.to_string(amount, true, nil, amount > GetMoney() and aux.color.red or nil))
        end
        net_summary:SetText('You get ' .. money.to_string(floor(total * (1 - AUCTION_CUT)), true))
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
        local max_stack_count
        if selected_item.commodity then
            max_stack_count = floor(selected_item.count / stack_size_input:GetNumber())
        else
            local location = selected_item.item_location
            max_stack_count = selected_item.count
            if location and location:IsValid() and C_Item.DoesItemExist(location) then
                max_stack_count = min(max_stack_count, max(1, C_AuctionHouse.GetAvailablePostCount(location)))
            end
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

    local max_stack_size = item.commodity and min(item.max_stack, item.count) or 1
    stack_size_input.max_value = max_stack_size
    stack_size_input:SetNumber(max_stack_size)
    quantity_update(true)

    unit_start_price_input:SetText(money.to_string(settings.start_price, true, nil, nil, true))
    unit_buyout_price_input:SetText(money.to_string(settings.buyout_price, true, nil, nil, true))
    write_settings(settings, item.key)

    if not bid_records[item.key] then
        refresh_entries()
    end

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

function refresh_entries()
	if selected_item then
        local item_key = selected_item.key
		set_bid_selection()
        set_buyout_selection()
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
			end,
			on_complete = function()
                aux.status_bar:update_status(1, 1)
            end,
		}
	end
end

function M.clear_auctions()
    bid_records, buyout_records = {}, {}
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

function on_update()
    if refresh then
        refresh = false
        price_update()
        update_item_configuration()
        update_inventory_listing()
        update_auction_listings()
    end
    validate_parameters()
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
