select(2, ...) 'aux.tabs.search'

local aux = require 'aux'
local info = require 'aux.util.info'
local filter_util = require 'aux.util.filter'
local scan = require 'aux.core.scan'

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

    function update_search(index)
        searches[search_index].table:Hide()
        searches[search_index].table:SetSelectedRecord()

        search_index = index

        searches[search_index].table:Show()

        search_box:SetText(searches[search_index].filter_string or '')
        if search_index == 1 then
            previous_button:Disable()
        else
            previous_button:Enable()
        end
        if search_index == #searches then
            next_button:Hide()
            mode_button:SetPoint('LEFT', previous_button, 'RIGHT', 4, 0)
        else
            next_button:Show()
            mode_button:SetPoint('LEFT', next_button, 'RIGHT', 4, 0)
        end
        update_mode(searches[search_index].mode)
        update_start_stop()
        update_continuation()
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
        search.table:SetSort(1, 2, 3, 4, 5, 6, 7, 8, 9)
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

function start_search(queries, continuation)
    local current_query, current_page, total_queries, start_query, start_page

    local search = current_search()

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
do
    local selected, checked

    local function failure(search, record)
        return function(error)
            if error == Enum.AuctionHouseError.ItemNotFound or error == Enum.AuctionHouseError.ItemNotAvailable or error == 'unavailable' then
                search.table:RemoveAuctionRecord(record)
            end
        end
    end

    -- A commodity purchase takes the cheapest listings first (never the player's own), so update the
    -- displayed tiers the same way instead of just removing the selected row.
    local function consume_commodity(search, record)
        local tiers = {}
        for _, r in ipairs(search.records) do
            if r.commodity and r.item_id == record.item_id and not r.own then
                tinsert(tiers, r)
            end
        end
        sort(tiers, function(a, b) return a.unit_buyout_price < b.unit_buyout_price end)
        local remaining = record.count
        for _, tier in ipairs(tiers) do
            if remaining <= 0 then break end
            local taken = min(remaining, tier.count)
            remaining = remaining - taken
            if taken == tier.count then
                local index = aux.key(search.records, tier)
                if index then tremove(search.records, index) end
            else
                local unit_price = tier.unit_buyout_price
                tier.count = tier.count - taken
                tier.buyout_price = unit_price * tier.count
                tier.bid_price, tier.start_price, tier.blizzard_bid = tier.buyout_price, tier.buyout_price, tier.buyout_price
                info.signatures(tier)
            end
        end
        search.table:SetDatabase()
    end

    function find_auction(record)
        local search = current_search()
        selected, checked = nil, record
        if not search.table:ContainsRecord(record) or info.is_player(record.owner) or record.own then
            return
        end
        selected = record

        bid_button:SetScript('OnClick', function()
            if search.table:ContainsRecord(record) then
                aux.place_bid(record.auction_id, record.bid_price, record.bid_price < record.buyout_price and function()
                    info.bid_update(record)
                    search.table:SetDatabase()
                end or function() search.table:RemoveAuctionRecord(record) end, failure(search, record))
            end
        end)

        buyout_button:SetScript('OnClick', function()
            if search.table:ContainsRecord(record) then
                if record.commodity then
                    aux.buy_commodity(record.item_id, record.count, record.buyout_price, function()
                        consume_commodity(search, record)
                    end, failure(search, record))
                else
                    aux.place_bid(record.auction_id, record.buyout_price, function() search.table:RemoveAuctionRecord(record) end, failure(search, record))
                end
            end
        end)
    end

    function on_update()
        local selection = current_search().table:GetSelection()
        if selection and selection.record ~= checked then
            find_auction(selection.record)
        end
        local record = selection and selected == selection.record and selected
        local busy = aux.bid_in_progress() or aux.commodity_purchase_in_progress()

        if record and not busy and not record.commodity and not record.high_bidder then
            bid_button:Enable()
        else
            bid_button:Disable()
        end
        if record and not busy and record.buyout_price > 0 then
            buyout_button:Enable()
        else
            buyout_button:Disable()
        end
    end
end
