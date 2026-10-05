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

-- auxForever: search timing log (/aux debug). While it is on, each search records where its time
-- goes and prints a summary when it ends, so slow searches can be measured instead of guessed.
local timing

local function timing_add(field, amount)
    if timing then
        timing[field] = timing[field] + (amount or 1)
    end
end

local function format_seconds(seconds)
    if seconds >= 60 then
        return format('%dm %02ds', floor(seconds / 60), floor(seconds % 60))
    end
    return format('%.1fs', seconds)
end

-- the summary lines for a finished (or stopped) search
function M.timing_report(t, total, stopped)
    local lines = {}
    local head = 'Search timing' .. (stopped and ' (stopped)' or '') .. ': ' .. format_seconds(total)
    if t.items > 0 then
        head = head .. format(' for %d %s, %.2fs each', t.items, t.items == 1 and 'item' or 'items', total / t.items)
    end
    tinsert(lines, head)
    local other = max(0, total - t.browse - t.answer - t.throttle - t.item_data)
    tinsert(lines, format('Waiting: item list %s, server answers %s, throttle %s, item data %s, other %s',
        format_seconds(t.browse), format_seconds(t.answer), format_seconds(t.throttle), format_seconds(t.item_data), format_seconds(other)))
    tinsert(lines, format('Answers: %d on time, %d after the 1s fallback, %d timed out (20s each), %d dropped and resent',
        t.event, t.cached, t.timeout, t.dropped))
    if #t.slow > 0 then
        sort(t.slow, function(a, b) return a.seconds > b.seconds end)
        local parts = {}
        for i = 1, min(3, #t.slow) do
            tinsert(parts, format('%s %s', t.slow[i].name, format_seconds(t.slow[i].seconds)))
        end
        tinsert(lines, 'Slowest: ' .. table.concat(parts, ', '))
    end
    return lines
end

function M.new_timing()
    return {t0 = GetTime(), items = 0, event = 0, cached = 0, timeout = 0, dropped = 0,
        browse = 0, answer = 0, throttle = 0, item_data = 0, slow = {}}
end

local function timing_finish(stopped)
    if timing then
        for _, line in ipairs(timing_report(timing, GetTime() - timing.t0, stopped)) do
            aux.print(line)
        end
        timing = nil
    end
end

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
        timing = aux.account_data.debug_timing and new_timing() or nil
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
        timing_finish(true)
        do (on_abort or pass)() end
    end
end

function complete()
    local on_complete = state.params.on_complete
    state = nil
    timing_finish()
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
local requests_sent = 0

function request(send, events, match, cached)
    for _ = 1, 3 do
        requests_sent = requests_sent + 1
        local t_throttle = GetTime()
        wait_throttle()
        timing_add('throttle', GetTime() - t_throttle)
        local t_answer = GetTime()
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
        timing_add('answer', GetTime() - t_answer)
        if received then
            timing_add('event')
            return received
        elseif not dropped then
            local from_cache = cached and cached() or false
            timing_add(from_cache and 'cached' or 'timeout')
            return from_cache
        end
        timing_add('dropped')
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
    timing_add('item_data', GetTime() - t0)
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
        local t0 = GetTime()
        listen({'ITEM_KEY_ITEM_INFO_RECEIVED'}, function(item_id) return item_id == item_key.itemID end)(3)
        timing_add('item_data', GetTime() - t0)
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

-- auxForever: the item list of a query, one entry per item with only itemKey, totalQuantity,
-- minPrice and containsOwnerItem. Returns nil if the auction house did not answer.
function browse_results(blizzard_query)
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
    return C_AuctionHouse.GetBrowseResults()
end

-- Returns the list of item keys matching the query, or nil if the auction house did not answer.
function browse(blizzard_query)
    local results = browse_results(blizzard_query)
    if not results then
        return
    end
    local item_keys = {}
    for _, result in ipairs(results) do
        tinsert(item_keys, result.itemKey)
    end
    return item_keys
end

-- auxForever: an item key as text, the same form as a record's item_key ("item:suffix")
function M.item_key_string(item_key)
    return item_key.itemID .. ':' .. (item_key.itemSuffix or 0)
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
    -- a fast mode row only knows the lowest price, which may be a bid: it is not price history
    if not auction.fast then
        history.process_auction(auction)
    end
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
        local t_item = GetTime()
        local records = search(item_keys[page + 1])
        if timing then
            timing.items = timing.items + 1
            local seconds = GetTime() - t_item
            if seconds > 1.5 then
                local key_info = C_AuctionHouse.GetItemKeyInfo(item_keys[page + 1])
                tinsert(timing.slow, {name = key_info and key_info.itemName or ('item ' .. item_keys[page + 1].itemID), seconds = seconds})
            end
        end
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

-- auxForever: fast mode. Each item of the list becomes one row with its lowest price and how many
-- are for sale, without opening it. Items in params.open (item key strings) are read in full
-- instead. Items the client has not loaded yet are asked for and added as they arrive.
function scan_item_list(results)
    local scan_state = state
    local open = state.params.open or empty
    local validator = get_query().validator
    local pending = {}
    local function add(result)
        local record = info.browse_record(result)
        if not record then
            return false
        end
        record.validator = validator
        process_auction(record)
        return true
    end
    for i, result in ipairs(results) do
        if (result.totalQuantity or 0) > 0 then
            if open[item_key_string(result.itemKey)] then
                for _, record in ipairs(search(result.itemKey) or empty) do
                    process_auction(record)
                    check_aborted(scan_state)
                end
            elseif not add(result) then
                info.request_item(result.itemKey.itemID)
                tinsert(pending, result)
            end
            check_aborted(scan_state)
        end
        if i % 100 == 0 then
            do (state.params.on_page_scanned or pass)() end
            aux.coro_wait()
            check_aborted(scan_state)
        end
    end
    local t0 = GetTime()
    while #pending > 0 and GetTime() - t0 < 5 do
        aux.coro_wait()
        check_aborted(scan_state)
        for i = #pending, 1, -1 do
            if add(pending[i]) then
                tremove(pending, i)
                check_aborted(scan_state)
            end
        end
    end
    timing_add('items', #results)
    do (state.params.on_page_scanned or pass)() end
    check_aborted(scan_state)
end

-- auxForever: one item's auctions, for code running inside a scan (the sniper). They count as
-- price history like any search.
function M.read_item(item_key)
    local records = search(item_key)
    for _, record in ipairs(records or empty) do
        history.process_auction(record)
    end
    return records
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

-- auxForever: /aux debug list. Times the item list of the whole auction house without opening any
-- item, which is what fast mode and the sniper would do: how long it takes and how big it is.
function M.measure_item_list()
    if state then
        aux.print('A search is running; try again when it is done.')
        return
    end
    aux.coro_thread(function()
        -- a scan state of its own, so no search starts meanwhile and Close stops it like a search
        state = {id = aux.coro_id(), params = {}, listener_ids = {}}
        local requests_before = requests_sent
        local t0 = GetTime()
        -- no pcall here: WoW's Lua 5.1 cannot pause (yield) inside one, and the request must wait
        local item_keys = browse({})
        local requests = requests_sent - requests_before
        state = nil
        if not item_keys then
            aux.print('Item list: the auction house did not answer.')
            return
        end
        aux.print(format('Item list of the whole auction house: %d items in %s (%d %s)', #item_keys, format_seconds(GetTime() - t0), requests, requests == 1 and 'request' or 'requests'))
    end)
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
        elseif state.params.fast or state.params.on_item_list then
            local t_browse = GetTime()
            local results = browse_results(get_query().blizzard_query or empty)
            timing_add('browse', GetTime() - t_browse)
            if timing then
                timing.answer = max(0, timing.answer - (GetTime() - t_browse))
            end
            if not results then
                aux.print('the auction house did not respond to the search')
            elseif state.params.on_item_list then
                state.params.on_item_list(results)
            else
                scan_item_list(results)
            end
        else
            local t_browse = GetTime()
            local item_keys = browse(get_query().blizzard_query or empty)
            timing_add('browse', GetTime() - t_browse)
            -- the item list's own request time is counted as item list, not as server answers
            if timing and item_keys then
                timing.answer = max(0, timing.answer - (GetTime() - t_browse))
            end
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
