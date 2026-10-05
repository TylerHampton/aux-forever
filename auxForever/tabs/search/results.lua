select(2, ...) 'aux.tabs.search'

local aux = require 'aux'
local info = require 'aux.util.info'
local filter_util = require 'aux.util.filter'
local scan = require 'aux.core.scan'
local buy_bar = require 'aux.gui.buy_bar'

StaticPopupDialogs.AUX_SCAN_ALERT = {
    text = 'One of your alert queries matched!',
    button1 = 'Ok',
    showAlert = 1,
    timeout = 0,
    hideOnEscape = 1,
    preferredIndex = STATICPOPUP_NUMDIALOGS,
}

NORMAL_MODE, LIVE_MODE = {}, {}

mode = nil

bid_enabled = false
buyout_enabled = false

function aux.event.AUX_LOADED()
    new_search(nil, NORMAL_MODE)
end

function update_mode(mode)
    _M.mode = mode
    if mode == NORMAL_MODE then
        mode_button:SetBackdropColor(aux.color.content.background())
    else
        mode_button:SetBackdropColor(aux.color.state.enabled())
    end
end

do
    local searches = {}
    local search_index = 1

    function M.clear_selection()
        if searches[search_index] then
            searches[search_index].table:SetSelectedRecord()
        end
    end

    function current_search()
        return searches[search_index]
    end

    function M.set_nav_enabled(button, enabled)
        if enabled then
            button:Enable()
            button:SetAlpha(1)
        else
            button:Disable()
            button:SetAlpha(.35)
        end
    end

    function update_search(index)
        searches[search_index].table:Hide()
        searches[search_index].table:SetSelectedRecord()

        search_index = index

        searches[search_index].table:Show()

        search_box:SetText(searches[search_index].filter_string or '')
        -- auxForever: the arrows stay in place and fade when there is nowhere to go, so the row
        -- of buttons never shifts
        set_nav_enabled(previous_button, search_index > 1)
        set_nav_enabled(next_button, search_index < #searches)
        mode_button:SetPoint('LEFT', next_button, 'RIGHT', 4, 0)
        update_mode(searches[search_index].mode)
        update_start_stop()
        update_continuation()
        update_done()
    end

    function new_search(filter_string, mode)
        while #searches > search_index do
            tremove(searches)
        end
        local search = { records = {}, filter_string = filter_string, mode = mode }
        tinsert(searches, search)
        if #searches > 5 then
            tremove(searches, 1)
            tinsert(tables, tremove(tables, 1))
            search_index = 4
        end

        aux.status_bar:update_status(1, 1)

        search.table = tables[#searches]
        search.table:SetSort(1, 2, 3, 4, 5, 6, 7, 8)
        search.table:Reset()
        search.table:SetDatabase(search.records)

        update_search(#searches)
    end

    function previous_search()
        search_box:ClearFocus()
        update_search(search_index - 1)
        set_subtab(RESULTS)
    end

    function next_search()
        search_box:ClearFocus()
        update_search(search_index + 1)
        set_subtab(RESULTS)
    end
end

function update_continuation()
    if current_search().continuation then
        resume_button:Show()
        search_box:SetPoint('RIGHT', resume_button, 'LEFT', -4, 0)
    else
        resume_button:Hide()
        search_box:SetPoint('RIGHT', start_button, 'LEFT', -4, 0)
    end
end

function discard_continuation()
    scan.abort()
    current_search().continuation = nil
    update_continuation()
end

function update_start_stop()
    if current_search().active then
        stop_button:Show()
        start_button:Hide()
    else
        start_button:Show()
        stop_button:Hide()
    end
end

-- Forever: there are no result pages to watch, so real time mode repeats the whole search and
-- replaces the table with the current listings. Alerts only fire for auctions not seen before.
function start_live_scan(query, search)
    search = search or current_search()

    local seen = {}
    for _, record in pairs(search.records) do
        seen[record.sniping_signature] = true
    end

    local new_records = {}
    local alerted
    scan.start {
        type = 'list',
        sort_type = search.sort_type,
        queries = { query },
        on_scan_start = function()
            aux.status_bar:update_status(.9999, .9999)
        end,
        on_auction = function(auction_record)
            if not seen[auction_record.sniping_signature] and (search.alert_validator or pass)(auction_record) and not alerted then
                alerted = true
                StaticPopup_Show('AUX_SCAN_ALERT')
                FlashClientIcon()
            end
            tinsert(new_records, auction_record)
        end,
        on_complete = function()
            if #new_records > 2000 then
                StaticPopup_Show('AUX_SEARCH_TABLE_FULL')
            else
                search.records = new_records
                search.table:SetDatabase(search.records)
            end
            start_live_scan(query, search)
        end,
        on_abort = function()
            aux.status_bar:update_status(1, 1)
            search.continuation = true
            if current_search() == search then
                update_continuation()
            end
            search.active = false
            update_start_stop()
        end,
    }
end

-- auxForever: the status bar turns gold while the results of a finished search are shown, and goes
-- back to normal on a new search, another search in the history, Clear, another sub tab or tab.
function M.update_done()
    local search = current_search()
    aux.status_bar:set_done(frame:IsShown() and frame.results:IsShown() and search and search.complete)
end

function start_search(queries, continuation)
    local current_query, current_page, total_queries, start_query, start_page

    local search = current_search()
    search.complete = false
    update_done()

    total_queries = #queries

    if continuation then
        start_query, start_page = unpack(continuation)
        for i = 1, start_query - 1 do
            tremove(queries, 1)
        end
        queries[1].blizzard_query.first_page = (queries[1].blizzard_query.first_page or 0) + start_page - 1
        search.table:SetSelectedRecord()
    else
        start_query, start_page = 1, 1
    end


    scan.start {
        type = 'list',
        sort_type = search.sort_type,
        queries = queries,
        alert_validator = search.alert_validator,
        on_scan_start = function()
            aux.status_bar:update_status(0, 0)
        end,
        on_page_loaded = function(_, total_scan_pages)
            current_page = current_page + 1
            total_scan_pages = total_scan_pages + (start_page - 1)
            total_scan_pages = max(total_scan_pages, 1)
            current_page = min(current_page, total_scan_pages)
            aux.status_bar:update_status(current_page / total_scan_pages, current_query / #queries)
        end,
        on_page_scanned = function()
            search.table:SetDatabase()
        end,
        on_start_query = function(query)
            current_query = current_query and current_query + 1 or start_query
            current_page = current_page and 0 or start_page - 1
        end,
        on_auction = function(auction_record)
            if (search.alert_validator or pass)(auction_record) then
                StaticPopup_Show('AUX_SCAN_ALERT') -- TODO retail improve this
            end
            if #search.records < 2000 then
                tinsert(search.records, auction_record)
                if #search.records == 2000 then
                    StaticPopup_Show('AUX_SEARCH_TABLE_FULL')
                end
            end
        end,
        on_complete = function()
            aux.status_bar:update_status(1, 1)
            search.complete = true
            update_done()
            remember_search_result(search.filter_string, search.records)

            if current_search() == search and frame.results:IsVisible() and #search.records == 0 then
                set_subtab(SAVED)
            end

            search.active = false
            update_start_stop()
        end,
        on_abort = function()
            aux.status_bar:update_status(1, 1)

            if current_query then
                search.continuation = { current_query, current_page + 1 }
            else
                search.continuation = { start_query, start_page }
            end
            if current_search() == search then
                update_continuation()
            end

            search.active = false
            update_start_stop()
        end,
    }
end

function M.execute(_, resume, mode)

    if resume then
        mode = current_search().mode
    elseif mode == nil then
        mode = _M.mode
    end

    if resume then
        search_box:SetText(current_search().filter_string)
    end
    local filter_string = search_box:GetText()

    local queries, error = filter_util.queries(filter_string)
    if not queries then
        aux.print('Invalid filter:', error)
        return
    elseif mode == LIVE_MODE then
        if #queries > 1 then
            aux.print('Error: The real time mode does not support multi-queries')
            return
        end
    end

    if resume then
        current_search().table:SetSelectedRecord()
    else
        if filter_string ~= current_search().filter_string then
            if current_search().filter_string then
                new_search(filter_string, mode)
            else
                current_search().filter_string = filter_string
            end
            new_recent_search(filter_string, aux.join(aux.map(aux.copy(queries), function(filter) return filter.prettified end), ';'))
        else
            local search = current_search()
            search.records = {}
            search.table:Reset()
            search.table:SetDatabase(search.records)
        end
        local search = current_search()
        search.mode = mode
        if mode ~= LIVE_MODE then
            search.sort_type = 'unitprice'
        end
        search.alert_validator = get_alert_validator()
    end

    local continuation = resume and current_search().continuation
    discard_continuation()
    current_search().active = true
    update_start_stop()
    search_box:ClearFocus()
    set_subtab(RESULTS)
    if mode == LIVE_MODE then
        start_live_scan(queries[1])
    else
        start_search(queries, continuation)
    end
end

-- Forever: every record carries its auction ID, so the selected auction can be bought or bid on
-- right away instead of first being found again by a scan as in Classic aux.
-- Item rows are buckets of identical auctions priced per item: Buyout buys one, like buying one
-- single-item auction in Classic. Both are bought from the buy bar under the results (gui/buy_bar.lua).
do
    local checked

    local function failure(search, record)
        return function(error)
            if error == Enum.AuctionHouseError.ItemNotFound or error == Enum.AuctionHouseError.ItemNotAvailable then
                search.table:RemoveAuctionRecord(record)
            end
        end
    end

    local function same_bucket(result, record)
        return result.itemLink == record.link
            and (result.buyoutAmount or 0) == record.raw_buyout
            and (result.bidAmount or 0) == record.raw_bid
            and not (#result.owners == 1 and result.containsOwnerItem)
    end

    local function find_bucket(record)
        local key = record.item_search_key
        for i = 1, C_AuctionHouse.GetNumItemSearchResults(key) do
            local result = C_AuctionHouse.GetItemSearchResultInfo(key, i)
            if result and same_bucket(result, record) then
                return result
            end
        end
    end

    -- One auction of a bucket was bought (or bid on). The bucket carries on under a new auction
    -- ID, so re-read the item's results to pick it up before the next purchase.
    local function sync_bucket(search, record)
        record.auction_count = record.auction_count - 1
        if record.auction_count <= 0 then
            search.table:RemoveAuctionRecord(record)
            return
        end
        record.syncing = true
        search.table:SetDatabase()
        local key, old_id = record.item_search_key, record.auction_id
        aux.coro_thread(function()
            local updated
            local listener_id = aux.event_listener('ITEM_SEARCH_RESULTS_UPDATED', function(item_key)
                if item_key and item_key.itemID == key.itemID then
                    updated = true
                end
            end)
            local t0 = GetTime()
            while not updated and GetTime() - t0 < 1.5 do
                -- the update may already have arrived before this started listening
                local bucket = find_bucket(record)
                if bucket and bucket.auctionID ~= old_id then
                    updated = true
                    break
                end
                aux.coro_wait()
            end
            if not updated then
                -- the client no longer holds this item's results; ask for them again
                scan.abort()
                while not C_AuctionHouse.IsThrottledMessageSystemReady() do
                    aux.coro_wait()
                end
                C_AuctionHouse.SendSearchQuery(key, {{sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false}}, true)
                t0 = GetTime()
                while not updated and GetTime() - t0 < 5 do
                    aux.coro_wait()
                end
            end
            aux.kill_listener(listener_id)
            local bucket = find_bucket(record)
            record.syncing = nil
            if bucket and (bucket.auctionID ~= old_id or updated) then
                record.auction_id = bucket.auctionID
                record.auction_count = max(1, bucket.quantity or 1)
                search.table:SetDatabase()
            else
                search.table:RemoveAuctionRecord(record)
            end
        end)
    end

    -- The tiers of a commodity the player can buy, cheapest first
    local function commodity_tiers(search, item_id)
        local tiers = {}
        for _, record in ipairs(search.records) do
            if record.commodity and record.item_id == item_id and not record.own then
                tinsert(tiers, record)
            end
        end
        sort(tiers, function(a, b) return a.commodity_unit_price < b.commodity_unit_price end)
        return tiers
    end

    -- A purchase took the cheapest units first, so update the displayed tiers the same way
    local function consume_commodity(search, item_id, quantity)
        local remaining = quantity
        for _, tier in ipairs(commodity_tiers(search, item_id)) do
            if remaining <= 0 then break end
            local taken = min(remaining, tier.count)
            remaining = remaining - taken
            if taken == tier.count then
                local index = aux.key(search.records, tier)
                if index then tremove(search.records, index) end
            else
                info.set_commodity_count(tier, tier.count - taken)
            end
        end
        search.table:SetDatabase()
    end

    -- Re-read the listings of one commodity (after its price went up), replacing its rows
    local function refresh_commodity(search, item_id)
        local fresh = {}
        scan.start{
            type = 'list',
            queries = {{item_keys = {C_AuctionHouse.MakeItemKey(item_id)}}},
            on_auction = function(record)
                tinsert(fresh, record)
            end,
            on_complete = function()
                for i = #search.records, 1, -1 do
                    if search.records[i].commodity and search.records[i].item_id == item_id then
                        tremove(search.records, i)
                    end
                end
                for _, record in ipairs(fresh) do
                    tinsert(search.records, record)
                end
                search.table:SetDatabase()
            end,
        }
    end

    local function show_commodity(search, record)
        local item_info = info.item(record.item_id)
        buy_bar.show_commodity{
            item_id = record.item_id,
            name = record.name,
            texture = record.texture,
            quality = record.quality,
            max_stack = item_info and item_info.max_stack or 1,
            tiers = function() return commodity_tiers(search, record.item_id) end,
            on_success = function(n) consume_commodity(search, record.item_id, n) end,
            on_refresh = function() refresh_commodity(search, record.item_id) end,
        }
    end

    local function show_item(search, record)
        buy_bar.show_item{
            record = record,
            name = record.name,
            texture = record.texture,
            quality = record.quality,
            own = info.is_player(record.owner) or record.own,
            busy = function()
                return record.syncing or aux.bid_in_progress() or not search.table:ContainsRecord(record)
            end,
            on_buy = function()
                aux.place_bid(record.auction_id, record.buyout_price, function()
                    sync_bucket(search, record)
                end, failure(search, record))
            end,
            on_bid = function()
                aux.place_bid(record.auction_id, record.bid_price, function()
                    if record.auction_count and record.auction_count > 1 then
                        sync_bucket(search, record)
                    elseif record.bid_price < record.buyout_price then
                        info.bid_update(record)
                        search.table:SetDatabase()
                    else
                        search.table:RemoveAuctionRecord(record)
                    end
                end, failure(search, record))
            end,
        }
    end

    function find_auction(record)
        local search = current_search()
        checked = record
        if not search.table:ContainsRecord(record) then
            buy_bar.clear()
        elseif record.commodity then
            -- Forever: commodities are bought by quantity, whichever row is selected
            show_commodity(search, record)
        else
            show_item(search, record)
        end
    end

    function on_update()
        local selection = current_search().table:GetSelection()
        if selection and selection.record ~= checked then
            find_auction(selection.record)
        elseif not selection and checked then
            checked = nil
            buy_bar.clear()
        end
    end
end
