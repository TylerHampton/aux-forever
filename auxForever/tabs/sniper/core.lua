select(2, ...) 'aux.tabs.sniper'

local aux = require 'aux'
local info = require 'aux.util.info'
local money = require 'aux.util.money'
local scan = require 'aux.core.scan'
local history = require 'aux.core.history'
local buy_bar = require 'aux.gui.buy_bar'

local tab = aux.tab 'Sniper'

-- auxForever: the Sniper. It reads the item list of the whole auction house again and again (one
-- round took 8.5 seconds for 7718 items on Forever, Tyler's /aux debug list, 2026-10-05) and lists
-- the items whose lowest price is a deal. The list only knows each item's lowest price, which may
-- be a bid, so an item that looks like a deal is opened (one request) to check its real auctions.
-- Only checked auctions are listed, and they are what the buy bar buys.
-- It runs only while its tab is open: the Sniper, searches and posting share the game's request
-- limit. Closing the tab holds it; closing the auction house stops it.

AUCTION_CUT = .05 -- the auction house cut, as on the Post tab
MIN_DAYS = 3 -- days of price history needed before a price can be a deal against the usual price
ROUND_PAUSE = 1 -- seconds between rounds
MAX_DEALS = 100

running = false -- Start was pressed
active = false -- a round is under way
round = 0
last_count, last_seconds = nil, nil
deals = {} -- one record per item: the cheapest checked auction, with deal_* fields

local known = {} -- item key text -> the lowest price already judged
local next_round_at

-- The deal rule. unit_price: lowest price per item; usual: the usual price (nil without history);
-- vendor: what a vendor pays for one; days: days of price history; percent, min_profit: the
-- player's settings. Returns why it is a deal ('vendor' or 'usual'), the profit per item and the
-- percent of the usual price; nil when it is not a deal.
-- Below vendor price is a deal without any history (a sure profit). Otherwise the price must be at
-- most percent of the usual price and the usual price must rest on MIN_DAYS days of history, so a
-- thin price history does not fake deals. Either way the profit per item (after the auction house
-- cut when reselling) must be at least min_profit, which hides trivial finds.
-- The usual price used here is never below the vendor price.
function M.judge(unit_price, usual, vendor, days, percent, min_profit)
    vendor = vendor or 0
    if not unit_price or unit_price <= 0 then
        return
    end
    local reference = usual and usual > 0 and max(usual, vendor) or nil
    if vendor > 0 and unit_price < vendor then
        if vendor - unit_price >= min_profit then
            return 'vendor', vendor - unit_price, reference and aux.round(100 * unit_price / reference) or nil
        end
        return
    end
    if not reference or (days or 0) < MIN_DAYS then
        return
    end
    local profit = floor(reference * (1 - AUCTION_CUT)) - unit_price
    local pct = 100 * unit_price / reference
    if pct <= percent and profit >= min_profit then
        return 'usual', profit, aux.round(pct)
    end
end

-- usual price, vendor price, days of history; nil when the client has not loaded the item yet
function M.item_facts(key, item_id)
    local item_info = info.item(item_id)
    if not item_info then
        info.request_item(item_id)
        return
    end
    return history.value(key), item_info.sell_price or 0, #history.data_points(key)
end

local function settings()
    return aux.account_data.sniper_percent, aux.account_data.sniper_profit
end

function M.judge_record(record)
    local usual, vendor, days = item_facts(record.item_key, record.item_id)
    if usual == nil and vendor == nil then
        return
    end
    return judge(ceil(record.unit_buyout_price), usual, vendor, days, settings())
end

local function find_deal(key)
    for i, deal in ipairs(deals) do
        if deal.deal_key == key then
            return deal, i
        end
    end
end

local function alert()
    if aux.account_data.sniper_sound then
        PlaySound(SOUNDKIT.RAID_WARNING or 8959, 'Master')
    end
    if type(FlashClientIcon) == 'function' then
        FlashClientIcon()
    end
end

-- a deal no longer matching the settings (or no longer listed) stays in the list as gone
local function set_gone(deal)
    if deal and not deal.deal_gone then
        deal.deal_gone = true
        deal.deal_gone_at = time()
    end
end

-- Open one item (inside the round) and keep its cheapest auction when it is a deal
function check_item(item_key, key)
    local records = scan.read_item(item_key)
    if not records then
        known[key] = nil -- no answer: try again next round
        return
    end
    local cheapest
    local tiers = {}
    for _, record in ipairs(records) do
        if not record.own and record.buyout_price > 0 then
            tinsert(tiers, record)
            if not cheapest or record.unit_buyout_price < cheapest.unit_buyout_price then
                cheapest = record
            end
        end
    end
    local old = find_deal(key)
    if not cheapest then
        set_gone(old)
        return
    end
    local reason, profit, pct = judge_record(cheapest)
    if not reason then
        -- the list showed a bid, or the cheap one sold meanwhile
        set_gone(old)
        return
    end
    sort(tiers, function(a, b) return a.unit_buyout_price < b.unit_buyout_price end)
    -- the usual price is only shown when it rests on enough history to be trusted
    local usual, vendor, days = item_facts(cheapest.item_key, cheapest.item_id)
    if (days or 0) < MIN_DAYS then
        usual = nil
    end
    cheapest.deal_key = key
    cheapest.deal_reason = reason
    cheapest.deal_profit = profit
    cheapest.deal_percent = pct
    cheapest.deal_usual = usual and max(usual, vendor or 0) or nil
    cheapest.deal_tiers = cheapest.commodity and tiers or nil
    local same = old and not old.deal_gone and ceil(old.unit_buyout_price) == ceil(cheapest.unit_buyout_price)
    cheapest.deal_found = same and old.deal_found or time()
    if old then
        tremove(deals, aux.key(deals, old))
    end
    tinsert(deals, cheapest)
    while #deals > MAX_DEALS do
        tremove(deals, 1)
    end
    if not same then
        alert()
    end
end

-- One round's item list: judge every item whose lowest price changed, then open the ones that
-- look like a deal
function check_list(results, seen)
    local percent, min_profit = settings()
    local candidates = {}
    for i, result in ipairs(results) do
        local price = result.minPrice or 0
        if (result.totalQuantity or 0) > 0 and price > 0 then
            local key = scan.item_key_string(result.itemKey)
            seen[key] = price
            if not aux.account_data.sniper_ignored[key] and known[key] ~= price then
                local usual, vendor, days = item_facts(key, result.itemKey.itemID)
                if usual ~= nil or vendor ~= nil then
                    known[key] = price
                    if judge(price, usual, vendor, days, percent, min_profit) then
                        tinsert(candidates, result)
                    end
                end
            end
        end
        if i % 200 == 0 then
            aux.coro_wait()
        end
    end
    for _, result in ipairs(candidates) do
        check_item(result.itemKey, scan.item_key_string(result.itemKey))
    end
end

-- after a round: a deal whose item is gone from the list, or whose lowest price went up, sold
local function mark_gone(seen)
    for _, deal in ipairs(deals) do
        local price = seen[deal.deal_key]
        if not price or price > ceil(deal.unit_buyout_price) then
            set_gone(deal)
        end
    end
end

function start_round()
    active = true
    next_round_at = nil
    local t0 = GetTime()
    local seen = {}
    scan.start{
        type = 'list',
        queries = {{blizzard_query = {}}},
        on_item_list = function(results)
            last_count = #results
            check_list(results, seen)
        end,
        on_complete = function()
            active = false
            round = round + 1
            last_seconds = GetTime() - t0
            if last_count then
                mark_gone(seen)
            end
            next_round_at = GetTime() + ROUND_PAUSE
            update_deals()
        end,
        on_abort = function()
            active = false
            next_round_at = running and GetTime() + ROUND_PAUSE or nil
        end,
    }
end

function M.start()
    running = true
    next_round_at = GetTime()
    update_controls()
end

function M.stop()
    running = false
    next_round_at = nil
    if active then
        scan.abort()
    end
    active = false
    update_controls()
end

-- the settings changed: every item is judged again
function M.settings_changed()
    aux.wipe(known)
    update_deals()
end

function M.clear_deals()
    aux.wipe(deals)
    update_deals()
end

function M.ignore(record)
    if not record then return end
    aux.account_data.sniper_ignored[record.deal_key] = record.name
    local _, index = find_deal(record.deal_key)
    if index then
        tremove(deals, index)
    end
    update_deals()
end

function M.unignore_all()
    aux.wipe(aux.account_data.sniper_ignored)
    aux.wipe(known)
    update_deals()
end

function M.ignored_count()
    return aux.size(aux.account_data.sniper_ignored)
end

-- The deals shown: those that pass the current settings, gone ones too (a 1c find from a looser
-- setting no longer clutters the list once the profit is set back to 5s)
function M.shown_deals()
    local shown = {}
    for _, deal in ipairs(deals) do
        if judge_record(deal) then
            tinsert(shown, deal)
        end
    end
    return shown
end

-- every frame while the tab is shown
function M.update()
    -- the Sniper owns the request limit while its tab is open: a search still running elsewhere stops
    if running and not active and next_round_at and GetTime() >= next_round_at then
        start_round()
    end
    update_controls()
    update_selection()
    -- "found 20s ago" keeps counting
    if GetTime() >= (next_refresh or 0) then
        next_refresh = GetTime() + 1
        listing:UpdateRows()
    end
end

function aux.event.CLOSE()
    running = false
    active = false
    next_round_at = nil
end

function tab.OPEN()
    frame:Show()
    buy_bar.attach(frame.listing)
    if running and not active then
        next_round_at = GetTime()
    end
    update_deals()
    update_controls()
end

function tab.CLOSE()
    -- held: the rounds carry on when the tab is open again
    if active then
        scan.abort()
    end
    active = false
    next_round_at = nil
    listing:SetSelectedRecord()
    buy_bar.attach_default()
    frame:Hide()
end

-- the status next to Start / Stop
function M.status()
    if not running then
        return 'Stopped', 'Start watches the whole auction house for deals'
    elseif round == 0 then
        return 'Watching', 'first round, reading the item list...'
    end
    return 'Watching', format('round %d, %s items in %.1fs', round, last_count or 0, last_seconds or 0)
end

-- buying

local checked

local function show_deal(record)
    if record.commodity then
        local item_info = info.item(record.item_id)
        buy_bar.show_commodity{
            item_id = record.item_id,
            name = record.name,
            texture = record.texture,
            quality = record.quality,
            max_stack = item_info and item_info.max_stack or 1,
            tiers = function() return record.deal_gone and {} or record.deal_tiers or {record} end,
            on_success = function(n)
                -- the cheapest units went first; check the item again in the next round
                known[record.deal_key] = nil
                local left, rest = n, {}
                for _, tier in ipairs(record.deal_tiers or {}) do
                    local taken = min(left, tier.count)
                    left = left - taken
                    if taken < tier.count then
                        info.set_commodity_count(tier, tier.count - taken)
                        tinsert(rest, tier)
                    end
                end
                record.deal_tiers = rest
                if rest[1] ~= record then
                    -- the deal's own price is bought up
                    record.deal_bought = true
                    set_gone(record)
                end
                update_deals()
            end,
            on_refresh = function()
                known[record.deal_key] = nil
                set_gone(record)
                update_deals()
            end,
        }
    else
        buy_bar.show_item{
            record = record,
            name = record.name,
            texture = record.texture,
            quality = record.quality,
            own = false,
            busy = function()
                return record.deal_gone or record.deal_bought or aux.bid_in_progress()
            end,
            on_buy = function()
                aux.place_bid(record.auction_id, record.buyout_price, function()
                    -- the next one at this price has a new auction ID: the next round finds it
                    record.deal_bought = true
                    known[record.deal_key] = nil
                    set_gone(record)
                    update_deals()
                end, function()
                    set_gone(record)
                    update_deals()
                end)
            end,
            on_bid = function()
                aux.place_bid(record.auction_id, record.bid_price, function()
                    known[record.deal_key] = nil
                    set_gone(record)
                    update_deals()
                end)
            end,
        }
    end
end

function update_selection()
    local selection = listing:GetSelection()
    if selection and selection.record ~= checked then
        checked = selection.record
        show_deal(checked)
    elseif not selection and checked then
        checked = nil
        buy_bar.clear()
    end
end
