select(2, ...) 'aux'

local post = require 'aux.tabs.post'

function M.print(...)
	DEFAULT_CHAT_FRAME:AddMessage(LIGHTYELLOW_FONT_COLOR_CODE .. '<auxForever> ' .. join(map({...}, tostring), ' '))
end

local event_frame = CreateFrame'Frame'
for _, event in pairs{'ADDON_LOADED', 'PLAYER_LOGIN', 'AUCTION_HOUSE_SHOW', 'AUCTION_HOUSE_CLOSED'} do
	event_frame:RegisterEvent(event)
end

local aux_events = {}
M.event = setmetatable({}, {__metatable=false, __newindex=function(_, k, v) aux_events[k](v) end})

do
	local handlers, handlers2, handlers3 = {}, {}, {}
	function aux_events.AUX_LOADED(f)
		tinsert(handlers, f)
	end
	function aux_events.PLAYER_LOGIN(f)
		tinsert(handlers2, f)
    end
    function aux_events.AUCTION_HOUSE_LOADED(f)
        tinsert(handlers3, f)
    end
	event_frame:SetScript('OnEvent', function(_, event, arg1, ...)
		if event == 'ADDON_LOADED' then
            if arg1 == 'auxForever' then
                for _, f in ipairs(handlers) do f(arg1, ...) end
            elseif arg1 == 'Blizzard_AuctionHouseUI' then
                for _, f in ipairs(handlers3) do f(arg1, ...) end
            end
		elseif event == 'PLAYER_LOGIN' then
			for _, f in ipairs(handlers2) do f(arg1, ...) end
            sort(account_data.auctionable_items, function(a, b) return strlen(a) < strlen(b) or (strlen(a) == strlen(b) and a < b) end)
            print('loaded. aux by shirsig, re-imagined by a fan. /aux for help')
		else
			_M[event](arg1, ...)
		end
	end)
end

function event.AUX_LOADED()
    _G.aux = aux or {}
    assign(aux, {
        account = {},
        realm = {},
        faction = {},
        character = {},
    })
    M.account_data = assign(aux.account, {
        scale = 1,
        ignore_owner = true,
        action_shortcuts = false,
        crafting_cost = true,
        post_full_scan = nil,
        post_bid = nil,
        post_duration = post.DURATION_8,
        post_undercut = false,
        full_search = false,
        sniper_percent = 60,
        sniper_profit = 500,
        sniper_sound = true,
        sniper_ignored = {},
        replicate_time = 0,
        window = {},
        background_opacity = 1,
        items = {},
        item_ids = {},
        unused_item_ids = {},
        auctionable_items = {},
        merchant_buy = {},
    })
    do
        local key = format('%s|%s', GetRealmName(), UnitName'player')
        aux.character[key] = aux.character[key] or {}
        M.character_data = assign(aux.character[key], {
            bid_auction_ids = {},
            tooltip = {
                value = true,
                merchant_sell = true,
                merchant_buy = false,
                daily = false,
                disenchant_value = false,
                disenchant_distribution = false,
                money_icons = false
            }
        })
    end
    do
        local key = GetRealmName()
        aux.realm[key] = aux.realm[key] or {}
        M.realm_data = assign(aux.realm[key], {
            characters = {},
            recent_searches = {},
            favorite_searches = {},
        })
    end
    do
        local key = format('%s|%s', GetRealmName(), UnitFactionGroup 'player')
        aux.faction[key] = aux.faction[key] or {}
        M.faction_data = assign(aux.faction[key], {
            history = {},
            post = {},
        })
        -- Forever: the first test version recorded item prices divided by the number of auctions
        -- in a search row, which made recorded values far too low. Start the price history over.
        if faction_data.history_version ~= 2 then
            faction_data.history = {}
            faction_data.history_version = 2
        end
    end
end

tab_info = {}
function M.tab(name)
	local tab = { name = name }
	local tab_event = {
		OPEN = function(f) tab.OPEN = f end,
		CLOSE = function(f) tab.CLOSE = f end,
		USE_ITEM = function(f) tab.USE_ITEM = f end,
		CLICK_LINK = function(f) tab.CLICK_LINK = f end,
	}
	tinsert(tab_info, tab)
	return setmetatable({}, {__metatable=false, __newindex=function(_, k, v) tab_event[k](v) end})
end

do
	local index
	function M.get_tab() return tab_info[index] end
	function on_tab_click(i)
		do (index and get_tab().CLOSE or pass)() end
		index = i
		do (index and get_tab().OPEN or pass)() end
	end
end

M.orig = setmetatable({[_G]={}}, {__index=function(self, key) return self[_G][key] end})
function M.hook(...)
	local name, object, handler
	if select('#', ...) == 3 then
		name, object, handler = ...
	else
		object, name, handler = _G, ...
	end
	handler = handler or getfenv(3)[name]
	orig[object] = orig[object] or {}
	orig[object][name], object[name] = object[name], handler
	return hook
end

do
	local locked

	function M.bid_in_progress()
        return locked
    end

	-- Forever: bids and buyouts go through C_AuctionHouse.PlaceBid with the auction's ID.
	-- Must be called from a click handler (hardware event).
	function M.place_bid(auction_id, amount, on_success, on_failure)
		if locked or not auction_id then
            return
        end
		if GetMoney() < amount then
			UIErrorsFrame:AddExternalErrorMessage(ERR_NOT_ENOUGH_MONEY)
			return
		end
		C_AuctionHouse.PlaceBid(auction_id, amount)
		locked = true
		local result
		local listeners = {
			event_listener('AUCTION_HOUSE_PURCHASE_COMPLETED', function(id)
				if id == auction_id then result = true end
			end),
			event_listener('BID_ADDED', function()
				result = true
			end),
			event_listener('CHAT_MSG_SYSTEM', function(message)
				if message == ERR_AUCTION_BID_PLACED then result = true end
			end),
			event_listener('AUCTION_HOUSE_SHOW_ERROR', function(error)
				result = result or error
			end),
		}
		coro_thread(function()
			local t0 = GetTime()
			while result == nil and GetTime() - t0 < 5 do
				coro_wait()
			end
			for _, listener_id in ipairs(listeners) do
				kill_listener(listener_id)
			end
			locked = false
			if result == true then
				tinsert(character_data.bid_auction_ids, auction_id)
				while #character_data.bid_auction_ids > 200 do
					tremove(character_data.bid_auction_ids, 1)
				end
				do (on_success or pass)() end
			else
				do (on_failure or pass)(result) end
			end
		end)
	end
end

-- Forever: Blizzard's AuctionHouseFrame must stay "shown" while the auction house is open,
-- because hiding it closes the auction house. Instead it is kept invisible behind aux.
do
    local blizzard_visible = false
    local HIDDEN_SCALE = .01

    -- The game lays out its side windows (UIParentPanelManager) with offsets divided by the
    -- window's scale. Any layout while the Blizzard window is shrunk (opening the character sheet,
    -- spellbook, a vendor...) therefore puts it 100 times too far away, off screen, and growing
    -- it back left it there: the Blizzard UI button seemed to do nothing. Bring such an anchor
    -- back to what the layout meant.
    function M.fix_blizzard_frame_position()
        local point, relative_to, relative_point, x, y = AuctionHouseFrame:GetPoint(1)
        if point and y and abs(y) > UIParent:GetHeight() then
            AuctionHouseFrame:ClearAllPoints()
            AuctionHouseFrame:SetPoint(point, relative_to, relative_point, x * HIDDEN_SCALE, y * HIDDEN_SCALE)
        end
    end

    function M.blizzard_frame_shown()
        return blizzard_visible
    end

    function M.set_blizzard_frame_shown(shown)
        if not AuctionHouseFrame then return end
        blizzard_visible = shown
        if shown then
            AuctionHouseFrame:SetScale(1)
            fix_blizzard_frame_position()
            -- never off screen, whatever moved it
            AuctionHouseFrame:SetClampedToScreen(true)
            AuctionHouseFrame:SetAlpha(1)
            AuctionHouseFrame:EnableMouse(true)
            -- both windows sit in the same layer, and whichever was shown or clicked last is on top
            AuctionHouseFrame:Raise()
        else
            AuctionHouseFrame:SetScale(HIDDEN_SCALE)
            AuctionHouseFrame:SetAlpha(0)
            AuctionHouseFrame:EnableMouse(false)
        end
        do (update_blizzard_button or pass)() end
    end

    -- hooked once, whoever loaded Blizzard's auction house first (another addon may load it
    -- before aux, and then its load event has already passed)
    local hooked
    function M.hook_blizzard_frame()
        if hooked or not AuctionHouseFrame then return end
        hooked = true
        AuctionHouseFrame:HookScript('OnShow', function(self)
            set_blizzard_frame_shown(false)
            -- aux handles posting confirmations itself; stop the hidden frame from popping its own dialog
            self:UnregisterEvent('AUCTION_HOUSE_POST_WARNING')
            self:UnregisterEvent('AUCTION_HOUSE_POST_ERROR')
        end)
        AuctionHouseFrame:HookScript('OnHide', function()
            blizzard_visible = false
            do (update_blizzard_button or pass)() end
        end)
    end

    function event.AUCTION_HOUSE_LOADED()
        hook_blizzard_frame()
    end
end

function AUCTION_HOUSE_SHOW()
    compat_load_auction_house_ui()
    hook_blizzard_frame()
    if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
        set_blizzard_frame_shown(false)
    end
    frame:Show()
    set_tab(1)
    -- auxForever: undercut mode is a choice for the moment, so it starts off every visit
    post.set_undercut_mode(false)
    query_owned_auctions()
    query_bids()
end

function M.query_owned_auctions()
    C_AuctionHouse.QueryOwnedAuctions({{sortOrder = Enum.AuctionHouseSortOrder.Name, reverseSort = false}})
end

function M.query_bids()
    local ids = {}
    for _, id in ipairs(character_data.bid_auction_ids) do
        tinsert(ids, id)
    end
    for _, id in ipairs(_G.g_activeBidAuctionIDs or empty) do
        tinsert(ids, id)
    end
    C_AuctionHouse.QueryBids({{sortOrder = Enum.AuctionHouseSortOrder.Name, reverseSort = false}}, ids)
end

do
	local handlers = {}
	function aux_events.CLOSE(f)
		tinsert(handlers, f)
	end
	function AUCTION_HOUSE_CLOSED()
		for _, handler in pairs(handlers) do
			handler()
		end
		set_tab()
		frame:Hide()
	end
end
