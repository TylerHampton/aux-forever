select(2, ...) 'aux.core.scan'

-- Forever: rewritten for the modern auction house (C_AuctionHouse).
--
-- Classic aux paged through results 50 auctions at a time. The modern auction house works in two steps:
--   1. a browse query returns one row per distinct item ("item key") matching the search
--   2. a search query per item key returns the individual auctions (or, for commodities, price tiers)
-- aux's scan callbacks are kept, with one "page" now meaning one item key. A full scan ("get_all")
-- uses C_AuctionHouse.ReplicateItems, which the server allows once every 15 minutes.

local aux = require 'aux'
local info = require 'aux.util.info'
local history = require 'aux.core.history'

M.REPLICATE_COOLDOWN = 15 * 60

local TIMEOUT = 20

local state

local SORTS = {
    {sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false},
    {sortOrder = Enum.AuctionHouseSortOrder.Name, reverseSort = false},
}

local SEARCH_SORTS = {
    {sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false},
}

local QUALITY_FILTERS = {
    [0] = Enum.AuctionHouseFilter.PoorQuality,
    Enum.AuctionHouseFilter.CommonQuality,
    Enum.AuctionHouseFilter.UncommonQuality,
    Enum.AuctionHouseFilter.RareQuality,
    Enum.AuctionHouseFilter.EpicQuality,
    Enum.AuctionHouseFilter.LegendaryQuality,
}

function aux.event.CLOSE()
	abort()
end

function M.is_scanning()
    return state ~= nil
end

function M.owner_auctions()
    local auctions = {}
    for i = 1, C_AuctionHouse.GetNumOwnedAuctions() do
        local owned = C_AuctionHouse.GetOwnedAuctionInfo(i)
        local record = owned and info.owned_record(owned)
        if record then
            auctions[i] = record
        end
    end
    return pairs(auctions)
end

function M.bidder_auctions()
    local auctions = {}
    for i = 1, C_AuctionHouse.GetNumBids() do
        local bid = C_AuctionHouse.GetBidInfo(i)
        local record = bid and info.bid_record(bid)
        if record then
            auctions[i] = record
        end
    end
    return pairs(auctions)
end

function M.start(params)
    if state then
        abort()
    end
    do (params.on_scan_start or pass)() end
    aux.coro_thread(function()
        state = {
            id = aux.coro_id(),
            params = params,
            listener_ids = {},
        }
        scan()
    end)
end

function M.abort()
    if state then
        aux.coro_kill(state.id)
        for id in pairs(state.listener_ids) do
            aux.kill_listener(id)
        end
        local on_abort = state.params.on_abort
        state = nil
        do (on_abort or pass)() end
    end
end

function complete()
    local on_complete = state.params.on_complete
    state = nil
    do (on_complete or pass)() end
end

function get_query()
	return state.params.queries[state.query_index]
end

-- A callback may abort the scan (or start a new one). The aborted coroutine is killed at its next
-- yield, so yield right away instead of touching the state again.
function check_aborted(scan_state)
    if state ~= scan_state then
        aux.coro_wait()
    end
end

-- Starts listening for any of the given events before a request is sent; the returned
-- function waits until one arrives (and passes the optional predicate), the optional stop
-- function returns true, or the timeout runs out.
function listen(events, predicate)
    local received
    local ids = {}
    for _, event in ipairs(events) do
        local id = aux.event_listener(event, function(...)
            if not received and (not predicate or predicate(...)) then
                received = event
            end
        end)
        ids[id] = true
        state.listener_ids[id] = true
    end
    return function(timeout, stop)
        local t0 = GetTime()
        while not received and GetTime() - t0 < (timeout or TIMEOUT) and not (stop and stop(GetTime() - t0)) do
            aux.coro_wait()
        end
        for id in pairs(ids) do
            aux.kill_listener(id)
            state.listener_ids[id] = nil
        end
        return received
    end
end

-- Sends a request and waits for its answer; returns the event that answered it (or true when
-- cached results were used). A request the throttle system drops is sent again. The client does
-- not always fire the results event again for results it already holds, so if no event arrives
-- within a second but cached() reports results, those are used.
function request(send, events, match, cached)
    for _ = 1, 3 do
        wait_throttle()
        local dropped
        local drop_id = aux.event_listener('AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED', function()
            dropped = true
        end)
        state.listener_ids[drop_id] = true
        local wait = listen(events, match)
        send()
        local received = wait(TIMEOUT, function(elapsed)
            return dropped or (cached and elapsed > 1 and cached())
        end)
        aux.kill_listener(drop_id)
        state.listener_ids[drop_id] = nil
        if received then
            return received
        elseif not dropped then
            return cached and cached() or false
        end
    end
    return false
end

function wait_throttle()
    while not C_AuctionHouse.IsThrottledMessageSystemReady() do
        aux.coro_wait()
    end
end

function wait_item(item_id)
    if C_Item.IsItemDataCachedByID(item_id) then
        return true
    end
    info.request_item(item_id)
    local t0 = GetTime()
    while not C_Item.IsItemDataCachedByID(item_id) and GetTime() - t0 < 3 do
        aux.coro_wait()
    end
    return C_Item.IsItemDataCachedByID(item_id)
end

function same_item_key(a, b)
    return a and b
        and a.itemID == b.itemID
        and (a.itemLevel or 0) == (b.itemLevel or 0)
        and (a.itemSuffix or 0) == (b.itemSuffix or 0)
        and (a.battlePetSpeciesID or 0) == (b.battlePetSpeciesID or 0)
end

function item_key_info(item_key)
    local key_info = C_AuctionHouse.GetItemKeyInfo(item_key)
    if not key_info then
        listen({'ITEM_KEY_ITEM_INFO_RECEIVED'}, function(item_id) return item_id == item_key.itemID end)(3)
        key_info = C_AuctionHouse.GetItemKeyInfo(item_key)
    end
    return key_info
end

function category_filters(blizzard_query)
    if not AuctionCategories or not blizzard_query.class then
        return {}
    end
    local category = AuctionCategories[blizzard_query.class]
    if category and blizzard_query.subclass then
        category = category.subCategories and category.subCategories[blizzard_query.subclass]
        if category and blizzard_query.slot then
            category = category.subCategories and category.subCategories[blizzard_query.slot]
        end
    end
    return category and category.filters or {}, category and category.implicitFilter
end

function browse_query(blizzard_query)
    local filters = {}
    for quality = blizzard_query.quality or 0, 5 do
        tinsert(filters, QUALITY_FILTERS[quality])
    end
    if blizzard_query.usable then
        tinsert(filters, Enum.AuctionHouseFilter.UsableOnly)
    end
    -- as in Classic aux, exact matching is not used for weapons and armor because of random suffixes
    if blizzard_query.exact and blizzard_query.class ~= 1 and blizzard_query.class ~= 2 then
        tinsert(filters, Enum.AuctionHouseFilter.ExactMatch)
    end
    local item_class_filters, implicit_filter = category_filters(blizzard_query)
    if implicit_filter then
        tinsert(filters, implicit_filter)
    end
    return {
        searchString = blizzard_query.name or '',
        minLevel = blizzard_query.min_level or 0,
        maxLevel = blizzard_query.max_level or 0,
        filters = filters,
        itemClassFilters = item_class_filters,
        sorts = SORTS,
    }
end

-- Returns the list of item keys matching the query, or nil if the auction house did not answer.
function browse(blizzard_query)
    local events = {'AUCTION_HOUSE_BROWSE_RESULTS_UPDATED', 'AUCTION_HOUSE_BROWSE_RESULTS_ADDED', 'AUCTION_HOUSE_BROWSE_FAILURE'}
    local query = browse_query(blizzard_query)
    local answer = request(function() C_AuctionHouse.SendBrowseQuery(query) end, events)
    if not answer or answer == 'AUCTION_HOUSE_BROWSE_FAILURE' then
        return
    end
    while not C_AuctionHouse.HasFullBrowseResults() do
        answer = request(function() C_AuctionHouse.RequestMoreBrowseResults() end, events)
        if not answer or answer == 'AUCTION_HOUSE_BROWSE_FAILURE' then
            break
        end
    end
    local item_keys = {}
    for _, result in ipairs(C_AuctionHouse.GetBrowseResults()) do
        tinsert(item_keys, result.itemKey)
    end
    return item_keys
end

-- Returns the auction records for one item key, or nil if the auction house did not answer.
function search(item_key)
    local key_info = item_key_info(item_key)
    if not key_info then
        return
    end
    wait_item(item_key.itemID)

    local records = {}
    if key_info.isCommodity then
        local item_id = item_key.itemID
        local function match(id) return id == item_id end
        local events = {'COMMODITY_SEARCH_RESULTS_UPDATED', 'COMMODITY_SEARCH_RESULTS_ADDED'}
        local function cached()
            return C_AuctionHouse.HasFullCommoditySearchResults(item_id) or C_AuctionHouse.GetCommoditySearchResultsQuantity(item_id) > 0
        end
        if not request(function() C_AuctionHouse.SendSearchQuery(item_key, SEARCH_SORTS, true) end, events, match, cached) then
            return
        end
        while not C_AuctionHouse.HasFullCommoditySearchResults(item_id) do
            if not request(function() C_AuctionHouse.RequestMoreCommoditySearchResults(item_id) end, events, match) then
                break
            end
        end
        for i = 1, C_AuctionHouse.GetNumCommoditySearchResults(item_id) do
            local result = C_AuctionHouse.GetCommoditySearchResultInfo(item_id, i)
            local record = result and info.commodity_record(result)
            if record then
                tinsert(records, record)
            end
        end
    else
        local function match(key) return same_item_key(key, item_key) end
        local events = {'ITEM_SEARCH_RESULTS_UPDATED', 'ITEM_SEARCH_RESULTS_ADDED'}
        local function cached()
            return C_AuctionHouse.HasSearchResults(item_key)
                and (C_AuctionHouse.HasFullItemSearchResults(item_key) or C_AuctionHouse.GetItemSearchResultsQuantity(item_key) > 0)
        end
        if not request(function() C_AuctionHouse.SendSearchQuery(item_key, SEARCH_SORTS, true) end, events, match, cached) then
            return
        end
        while not C_AuctionHouse.HasFullItemSearchResults(item_key) do
            if not request(function() C_AuctionHouse.RequestMoreItemSearchResults(item_key) end, events, match) then
                break
            end
        end
        for i = 1, C_AuctionHouse.GetNumItemSearchResults(item_key) do
            local result = C_AuctionHouse.GetItemSearchResultInfo(item_key, i)
            local record = result and info.item_search_record(result)
            if record then
                tinsert(records, record)
            end
        end
    end
    return records
end

function process_auction(auction, page, total)
    history.process_auction(auction)
    auction.page = page
    auction.blizzard_query = get_query().blizzard_query
    if not get_query().validator or get_query().validator(auction) then
        do (state.params.on_auction or pass)(auction, total) end
    end
end

function scan_item_keys(item_keys)
    local scan_state = state
    local blizzard_query = get_query().blizzard_query or empty
    local first_page = blizzard_query.first_page or 0
    local last_page = min(blizzard_query.last_page or math.huge, #item_keys - 1)
    for page = first_page, last_page do
        local records = search(item_keys[page + 1])
        do
            (state.params.on_page_loaded or pass)(
                page - first_page + 1,
                last_page - first_page + 1,
                max(0, #item_keys - 1),
                records and #records or 0
            )
        end
        check_aborted(scan_state)
        for _, record in ipairs(records or empty) do
            process_auction(record, page)
            check_aborted(scan_state)
        end
        do (state.params.on_page_scanned or pass)() end
        check_aborted(scan_state)
    end
end

function replicate()
    local scan_state = state
    local wait = listen({'REPLICATE_ITEM_LIST_UPDATE'})
    C_AuctionHouse.ReplicateItems()
    aux.account_data.replicate_time = time()
    if not wait(120) then
        aux.print('full scan: the auction house did not respond. It can only be used once every 15 minutes.')
        return
    end
    -- the list can arrive in several parts; wait until it stops growing
    local count, t0 = C_AuctionHouse.GetNumReplicateItems(), GetTime()
    while GetTime() - t0 < 2 do
        aux.coro_wait()
        if C_AuctionHouse.GetNumReplicateItems() ~= count then
            count, t0 = C_AuctionHouse.GetNumReplicateItems(), GetTime()
        end
    end

    local pending = {}
    for index = 0, count - 1 do
        local record, item_id = info.replicate_record(index)
        if record then
            process_auction(record, nil, count)
            check_aborted(scan_state)
        else
            pending[index] = true
            if item_id then
                info.request_item(item_id)
            end
        end
        if index % 100 == 0 then
            aux.coro_wait()
        end
    end
    -- items the client had not cached yet
    local t1 = GetTime()
    while next(pending) and GetTime() - t1 < 30 do
        aux.coro_wait()
        local processed = 0
        for index in pairs(pending) do
            local record = info.replicate_record(index)
            if record then
                pending[index] = nil
                process_auction(record, nil, count)
                processed = processed + 1
                if processed >= 100 then break end
            end
        end
    end
end

function scan()
    local scan_state = state
    state.query_index = 1
	while get_query() do
		do (state.params.on_start_query or pass)(state.query_index) end
        check_aborted(scan_state)
        if state.params.get_all then
            replicate()
        elseif get_query().item_keys then
            scan_item_keys(get_query().item_keys)
        else
            local item_keys = browse(get_query().blizzard_query or empty)
            if item_keys then
                scan_item_keys(item_keys)
            else
                aux.print('the auction house did not respond to the search')
            end
        end
        check_aborted(scan_state)
        state.query_index = state.query_index + 1
    end
	complete()
end
