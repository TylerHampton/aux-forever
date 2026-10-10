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
ROUND_PAUSE = 2.5 -- seconds between rounds: less garbage and fewer requests than 1s, deals still quick (Tyler)
MAX_DEALS = 100
ALERT_GAP = 10 -- seconds: at most one sound per this long, however many deals turn up

running = false -- Start was pressed
active = false -- a round is under way
round = 0
last_count, last_seconds = nil, nil
deals = {} -- one record per item: the cheapest checked auction, with deal_* fields

local known = {} -- item key text -> the lowest price already judged
local seen_items = {} -- during a round: item key text -> lowest price on the list
local next_round_at
local last_alert -- GetTime() of the last sound
local checked -- the selected deal, as the buy bar shows it
checking = nil -- during a round: {done, total} possible deals being opened
deals_changed = false -- the table is redrawn soon (throttled) while a round finds deals

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
-- Runs for every item whose price changed (all of them in the first round), so it builds no tables:
-- the vendor price straight from the game, the history from its cache.
-- auxForever (0.6, Tyler): the Sniper is for making money, so
-- - gray (poor) items are never a deal: "gray items definitely cannot be in the sniper". They get
--   no usual price and no vendor price, so judge finds nothing, below vendor price included.
-- - the days counted are days of complete looks only (history.value_and_complete_days), so a usual
--   price resting on a few old asking prices cannot make a deal.
POOR = 0
function M.item_facts(key, item_id)
    local name, _, quality, _, _, _, _, _, _, _, sell_price = GetItemInfo(item_id)
    if not name then
        -- the game drops item data now and then; aux's own saved item list still has the vendor price
        info.request_item(item_id)
        local saved = info.item_info(item_id)
        if not saved then
            return
        end
        quality, sell_price = saved.quality, saved.sell_price
    end
    if quality == POOR then
        return nil, 0, 0
    end
    local usual, days = history.value_and_complete_days(key)
    if days > history_days then
        history_days = days
    end
    return usual, sell_price or 0, days
end

-- auxForever (0.6 build 9, Tyler): the most days of complete looks any item has, seen while judging
-- items (no extra work), and whether a whole round has been judged, so the notice below can say how
-- far the price history is from MIN_DAYS
history_days, history_days_known = 0, false
STALE_SECONDS = 2 * 24 * 60 * 60

-- The line next to the deal count: a warning when the last Full scan is more than two days old
-- (usual prices may be out of date), or, while the price history is too short for deals against
-- the usual price, how far along it is. nil when all is well. A warning, not a lock: below vendor
-- deals need no history, and the game allows a Full scan only once every 15 minutes (Tyler, build 9).
function M.history_notice(now, last_scan, days, known)
    if last_scan and last_scan > 0 and now - last_scan > STALE_SECONDS then
        local ago = floor((now - last_scan) / (24 * 60 * 60))
        return 'Your last Full scan was ' .. ago .. (ago == 1 and ' day' or ' days') .. ' ago. Usual prices may be out of date.', 'stale'
    end
    if (known or not last_scan or last_scan <= 0) and days < MIN_DAYS then
        return 'Deals against the usual price start after ' .. MIN_DAYS .. ' days of Full scans; you have ' .. days .. ' so far.', 'thin'
    end
end

local function settings()
    return aux.account_data.sniper_percent, aux.account_data.sniper_profit
end

function M.judge_record(record)
    local usual, vendor, days = item_facts(record.item_key, record.item_id)
    if usual == nil and vendor == nil then
        if not record.deal_key then
            return
        end
        -- a deal already found keeps the facts it was judged with while the game reloads the item
        -- (without this, every deal could vanish from the table at once and come back later)
        usual, vendor, days = record.deal_history, record.deal_vendor, record.deal_days
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

-- One sound for a burst of finds: the first round with a loose setting can find dozens of deals,
-- each opened one by one (about half a second each), and a sound per deal played over and over.
function M.alert()
    local now = GetTime()
    if last_alert and now - last_alert < ALERT_GAP then
        return
    end
    last_alert = now
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
        deals_changed = true
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
    -- only the units that are a deal can be bought here: the buy bar offered 20 Ironweb Spider Silk
    -- where 7 were below vendor price and the rest cost more (Tyler, 0.4.1)
    for i = #tiers, 1, -1 do
        if not judge_record(tiers[i]) then
            tremove(tiers, i)
        end
    end
    -- the usual price is only shown when it rests on enough history to be trusted
    local usual, vendor, days = item_facts(cheapest.item_key, cheapest.item_id)
    cheapest.deal_history, cheapest.deal_vendor, cheapest.deal_days = usual, vendor, days
    if (days or 0) < MIN_DAYS then
        usual = nil
    end
    cheapest.deal_key = key
    cheapest.deal_item_key = item_key -- to read the item again when the deal is selected
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
    deals_changed = true
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
    -- each one is a request: shown as "checking 12 possible deals (3 done)" while it runs
    checking = {done = 0, total = #candidates}
    for _, result in ipairs(candidates) do
        check_item(result.itemKey, scan.item_key_string(result.itemKey))
        checking.done = checking.done + 1
    end
    checking = nil
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
    -- one table for every round: a new one per round was 7000+ entries of garbage each time
    aux.wipe(seen_items)
    local seen = seen_items
    scan.start{
        type = 'list',
        quiet = true,
        queries = {{blizzard_query = {}}},
        on_item_list = function(results)
            last_count = #results
            check_list(results, seen)
        end,
        on_complete = function()
            active = false
            checking = nil
            round = round + 1
            history_days_known = true
            last_seconds = GetTime() - t0
            if last_count then
                mark_gone(seen)
            end
            next_round_at = GetTime() + ROUND_PAUSE
            deals_changed = true
        end,
        on_abort = function()
            active = false
            checking = nil
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
    if running and (buy_bar.busy() or aux.bid_in_progress() or refreshing or checked) then
        -- a purchase talks to the auction house too: the round stops, and the next one waits until
        -- the purchase is done and no deal is selected (a round would also search other items and
        -- could replace the deal being bought)
        if active then
            scan.abort()
        end
        next_round_at = GetTime() + ROUND_PAUSE
    elseif running and not active and next_round_at and GetTime() >= next_round_at then
        start_round()
    end
    if GetTime() >= (next_controls or 0) then
        next_controls = GetTime() + .2
        update_controls()
    end
    update_selection()
    -- deals found during a round show up at once, at most twice a second, but not while the mouse is
    -- over the table: rows moved under the cursor while Tyler tried to pick one (0.4.1)
    if deals_changed and GetTime() >= (next_deals or 0) and not frame.listing:IsMouseOver() then
        next_deals = GetTime() + .5
        deals_changed = false
        update_deals()
    end
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
    if active or refreshing then
        scan.abort()
    end
    refreshing = nil
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
    end
    if buy_bar.busy() or aux.bid_in_progress() then
        return 'Watching', 'waits while you buy'
    elseif refreshing then
        return 'Watching', 'checking the selected deal...'
    elseif checked then
        return 'Holding', 'while a deal is selected; click it again to go on'
    end
    local done = round > 0 and format('round %d, %s items in %.1fs', round, last_count or 0, last_seconds or 0) or 'first round'
    if checking and checking.total > 0 then
        return 'Watching', format('%s; checking %d possible %s (%d done)', done, checking.total, checking.total == 1 and 'deal' or 'deals', checking.done)
    elseif round == 0 then
        return 'Watching', 'first round, reading the item list...'
    end
    return 'Watching', format('round %d, %s items in %.1fs', round, last_count or 0, last_seconds or 0)
end

-- buying

refreshing = nil -- the gear deal being read again before it can be bought

-- Tyler, 0.4.1: gear deals could not be bought from the Sniper (the button did nothing), while gear
-- from the Search tab and trade goods from the Sniper could. Likely cause: the rounds search other
-- items between finding a deal and the click, and the auction house takes a purchase of an auction
-- from the latest search of its item. So a selected gear deal is read again first (one request),
-- the rounds hold while a deal is selected, and the purchase itself stays on the player's click.

local show_item_bar, show_commodity_bar

-- Read a deal's item again when it is selected; the buy bar offers it once that answer is in.
-- Gear: the same auction, or another one at the shown price or lower. Trade goods: the units that
-- are still a deal, at today's counts (4 of 5 trade good buys failed with "Internal auction error"
-- on deals found minutes earlier, Tyler, 0.4.1).
local function refresh_deal(record)
    local item_key = record.deal_item_key or record.item_search_key
    if not item_key then
        if record.commodity then show_commodity_bar(record) else show_item_bar(record) end
        return
    end
    if active then
        scan.abort()
    end
    refreshing = record
    buy_bar.show_note(record.name, record.commodity and 'Checking what is left...' or 'Checking the auction...')
    local fresh = {}
    scan.start{
        type = 'list',
        quiet = true,
        queries = {{item_keys = {item_key}}},
        on_auction = function(auction)
            if not auction.own and auction.buyout_price > 0 then
                tinsert(fresh, auction)
            end
        end,
        on_complete = function()
            if refreshing ~= record then return end
            refreshing = nil
            if record.commodity then
                local tiers = {}
                for _, tier in ipairs(fresh) do
                    if judge_record(tier) then
                        tinsert(tiers, tier)
                    end
                end
                sort(tiers, function(a, b) return a.unit_buyout_price < b.unit_buyout_price end)
                if tiers[1] then
                    record.deal_tiers = tiers
                    if checked == record then
                        show_commodity_bar(record)
                    end
                    return
                end
            else
                -- the same auction, or another one at the shown price or lower (never more than shown)
                local found
                for _, auction in ipairs(fresh) do
                    if auction.auction_id == record.auction_id then
                        found = auction
                        break
                    elseif not found and ceil(auction.unit_buyout_price) <= ceil(record.unit_buyout_price) then
                        found = auction
                    end
                end
                if found then
                    record.auction_id = found.auction_id
                    if checked == record then
                        show_item_bar(record)
                    end
                    return
                end
            end
            set_gone(record)
            if checked == record then
                buy_bar.show_note(record.name, 'Sold before you could buy it', aux.color.red)
            end
        end,
        on_abort = function()
            if refreshing == record then
                refreshing = nil
            end
        end,
    }
end

local function show_deal(record)
    if record.deal_gone then
        buy_bar.show_note(record.name, record.deal_bought and 'Bought' or 'Gone: sold or relisted')
    else
        refresh_deal(record)
    end
end

function show_commodity_bar(record)
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
                if not rest[1] or ceil(rest[1].unit_buyout_price) > ceil(record.unit_buyout_price) then
                    -- the deal's own price is bought up: the rounds go on
                    record.deal_bought = true
                    set_gone(record)
                    if checked == record then
                        listing:SetSelectedRecord()
                    end
                end
                update_deals()
            end,
            on_refresh = function()
                known[record.deal_key] = nil
                set_gone(record)
                update_deals()
            end,
        }
end

function show_item_bar(record)
        buy_bar.show_item{
            record = record,
            name = record.name,
            texture = record.texture,
            quality = record.quality,
            own = false,
            busy = function()
                return record.deal_gone or record.deal_bought or aux.bid_in_progress() or refreshing ~= nil
            end,
            on_buy = function()
                aux.place_bid(record.auction_id, record.buyout_price, function()
                    -- the next one at this price has a new auction ID: the next round finds it
                    record.deal_bought = true
                    known[record.deal_key] = nil
                    set_gone(record)
                    update_deals()
                    -- bought: the rounds go on
                    if checked == record then
                        listing:SetSelectedRecord()
                    end
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

-- a click on the deal that is already selected lets it go, and the rounds go on
function M.click_deal(record)
    if record and record == checked then
        listing:SetSelectedRecord()
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

local function count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

-- /aux memory detail: what the Sniper keeps
function M.memory_counts()
    return count(known), count(seen_items), #deals
end
