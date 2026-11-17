select(2, ...) 'aux.tabs.upgrades'

local aux = require 'aux'
local filter_util = require 'aux.util.filter'
local scan = require 'aux.core.scan'
local stats = require 'aux.core.stats'
local weights = require 'aux.core.weights'

-- auxForever: the Upgrades tab (docs/upgrades.md, mockup approved by Ben 2026-11-16). The player
-- picks a spec and a slot; aux reads the item list of that slot's gear they can use (one fast
-- request per category, as the Sniper and fast searches do), scores each version with the spec's
-- ranked weights (core/weights.lua) and lists the ones that beat what is worn (core/stats.lua).
-- It informs: the score and the stats that change, never "buy this". Nothing runs on a timer: work
-- happens when the player presses Search, and the screen is redrawn when something changed.

local tab = aux.tab 'Upgrades'

local ARMOR_TYPES = {'plate', 'mail', 'leather', 'cloth'}
local function armor(slot)
    local list = {}
    for _, kind in ipairs(ARMOR_TYPES) do
        tinsert(list, 'armor/' .. kind .. '/' .. slot)
    end
    return list
end

-- the slots to pick: what equip locations count as that slot, and the searches that find them (in
-- aux's search language; Forever's categories, tests/forever_categories.lua). "usable" leaves out
-- what the character cannot use (armor type, weapon skill); the equip location keeps only the slot.
M.SLOTS = {
    {name = 'Head', locations = {'INVTYPE_HEAD'}, searches = armor('head')},
    {name = 'Neck', locations = {'INVTYPE_NECK'}, searches = {'armor/miscellaneous/neck'}},
    {name = 'Shoulder', locations = {'INVTYPE_SHOULDER'}, searches = armor('shoulder')},
    {name = 'Back', locations = {'INVTYPE_CLOAK'}, searches = {'armor/miscellaneous/cloak'}},
    {name = 'Chest', locations = {'INVTYPE_CHEST', 'INVTYPE_ROBE'}, searches = armor('chest')},
    {name = 'Wrist', locations = {'INVTYPE_WRIST'}, searches = armor('wrist')},
    {name = 'Hands', locations = {'INVTYPE_HAND'}, searches = armor('hands')},
    {name = 'Waist', locations = {'INVTYPE_WAIST'}, searches = armor('waist')},
    {name = 'Legs', locations = {'INVTYPE_LEGS'}, searches = armor('legs')},
    {name = 'Feet', locations = {'INVTYPE_FEET'}, searches = armor('feet')},
    {name = 'Ring', locations = {'INVTYPE_FINGER'}, searches = {'armor/miscellaneous/finger'}},
    {name = 'Trinket', locations = {'INVTYPE_TRINKET'}, searches = {'armor/miscellaneous/trinket'}},
    {name = 'Main Hand', locations = {'INVTYPE_WEAPON', 'INVTYPE_WEAPONMAINHAND'}, searches = {'weapons/one-handed'}},
    {name = 'Off Hand', locations = {'INVTYPE_WEAPONOFFHAND', 'INVTYPE_SHIELD', 'INVTYPE_HOLDABLE'},
        searches = {'armor/miscellaneous/held in off-hand', 'armor/miscellaneous/shields', 'weapons/one-handed'}},
    {name = 'Two-Hand', locations = {'INVTYPE_2HWEAPON'}, searches = {'weapons/two-handed'}},
    {name = 'Ranged', locations = {'INVTYPE_RANGED', 'INVTYPE_RANGEDRIGHT', 'INVTYPE_THROWN', 'INVTYPE_RELIC'},
        searches = {'weapons/ranged', 'weapons/one-handed/wands', 'armor/relic'}},
}

-- how far above the player's level to look (Required level dropdown)
M.EXTRA_LEVELS = {0, 2, 5}

local found = {}      -- the records of the last search, upgrades or not
local shown = {}      -- the upgrades among them, with record.upgrade
local state = {}      -- what the screen shows: searching, counts, when
local listeners = {}

-- the screen (frame.lua) redraws when this is called
function M.on_change(f) tinsert(listeners, f) end
local function changed()
    for _, f in ipairs(listeners) do f() end
end

function M.class()
    return select(2, UnitClass('player'))
end

-- this character's choices, kept in the saved variables (aux-addon.lua, character_settings)
local function saved()
    local u = aux.character_data.upgrades
    local specs = weights.specs(class())
    if not weights.spec(class(), u.spec) then u.spec = specs[1] and specs[1].id end
    if not SLOTS[u.slot or 0] then u.slot = 1 end
    if not EXTRA_LEVELS[u.extra or 0] then u.extra = 1 end
    return u
end
M.saved = saved

function M.current_spec() return weights.spec(class(), saved().spec) end

-- The player's own weights for a spec (the weights editor, tabs/upgrades/weights.lua): stat name ->
-- number, kept per character and spec in character_data.upgrades.weights. Only numbers that differ
-- from the guide's are kept, so a later change to the guide's order still reaches the rest.
function M.overrides(spec_id)
    local u = saved()
    u.weights = u.weights or {}
    return u.weights[spec_id] or {}
end

-- sets one weight (nil: back to the guide's), then scores the last search again
function M.set_weight(spec_id, stat, value)
    local spec = weights.spec(class(), spec_id)
    if not spec or not weights.STATS[stat] then return end
    local u = saved()
    u.weights = u.weights or {}
    local own = u.weights[spec_id] or {}
    local default = weights.default_ranks(spec)[stat] or 0
    if value == nil or value == default or value < 0 then
        own[stat] = nil
    else
        own[stat] = value
    end
    u.weights[spec_id] = next(own) and own or nil
    rescore()
end

function M.reset_weights(spec_id)
    local u = saved()
    if u.weights then u.weights[spec_id] = nil end
    rescore()
end

-- the weights in use for a spec, by the game's stat names
function M.spec_weights(spec)
    return weights.weights(spec, overrides(spec.id))
end
function M.current_slot() return SLOTS[saved().slot] end
function M.max_level() return min(60, UnitLevel('player') + EXTRA_LEVELS[saved().extra]) end

function M.set_spec(id)
    if weights.spec(class(), id) then saved().spec = id; rescore() end
end
function M.set_slot(index)
    if SLOTS[index] and saved().slot ~= index then
        saved().slot = index
        found, shown, state = {}, {}, {}
        let_go()
        changed()
    end
end
function M.set_extra(index)
    if EXTRA_LEVELS[index] then saved().extra = index; changed() end
end

-- the search text for a slot, up to a level: one query per category, joined by ";"
function M.filter_string(slot, max_level)
    local parts = {}
    for _, search in ipairs(slot.searches) do
        tinsert(parts, search .. '/usable/1/' .. max_level)
    end
    return table.concat(parts, ';')
end

local function equip_location(item_id)
    local get = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    local location = get and select(4, get(item_id))
    return type(location) == 'string' and location ~= '' and location or nil
end

-- score points gained for each gold of the price; nil without a buyout price
function M.per_gold(gain, price)
    if not gain or not price or price <= 0 then return end
    return gain / (price / 10000)
end

local function set_of(list)
    local set = {}
    for _, v in ipairs(list) do set[v] = true end
    return set
end

-- Scores one record: false while the game has not loaded it (ask again), true when done. An item
-- of the slot that beats what is worn gets record.upgrade and goes on the list.
local function score(record, slot_set, w, counts, list)
    local location = equip_location(record.item_id)
    if not location then return false end
    if not slot_set[location] then return true end
    local item_stats = stats.key_stats(record.browse_key)
    if not item_stats then return false end
    counts.considered = counts.considered + 1
    local c = stats.compare(item_stats, location, w)
    if not c then return true end
    if not c.ready then counts.worn_loading = true end
    if c.gain > 0 then
        c.changes = stats.changes(item_stats, c.worn_link and stats.link_stats(c.worn_link), w)
        c.per_gold = per_gold(c.gain, record.unit_buyout_price)
        record.upgrade = c
        tinsert(list, record)
    end
    return true
end

-- Scores the found records against the current spec. Long lists yield every 100 items. The list
-- shows as soon as every loaded item is scored; an item the game has not loaded yet is asked again
-- twice a second for up to 5 seconds and added when it loads. A newer search or spec ends an
-- older pass (generation).
local generation = 0
local RETRY_SECONDS, WAIT_SECONDS = .5, 5
function M.rescore()
    local spec, slot = current_spec(), current_slot()
    if not spec or #found == 0 then changed(); return end
    local w, slot_set = spec_weights(spec), set_of(slot.locations)
    local records = found
    generation = generation + 1
    local mine = generation
    state.scoring = true
    changed()
    aux.coro_thread(function()
        local counts, list, pending = {considered = 0}, {}, {}
        local function publish(done)
            if mine ~= generation then return end
            shown = list
            state.scoring = not done and #pending > 0
            state.considered, state.unloaded, state.worn_loading = counts.considered, #pending, counts.worn_loading
            changed()
        end
        for i, record in ipairs(records) do
            record.upgrade = nil
            if not score(record, slot_set, w, counts, list) then tinsert(pending, record) end
            if i % 100 == 0 then
                aux.coro_wait()
                if mine ~= generation then return end
            end
        end
        publish(#pending == 0)
        local t0, next_try = GetTime(), GetTime() + RETRY_SECONDS
        while #pending > 0 and GetTime() - t0 < WAIT_SECONDS do
            aux.coro_wait()
            if mine ~= generation then return end
            if GetTime() >= next_try then
                next_try = GetTime() + RETRY_SECONDS
                local left, before = {}, #list
                for _, record in ipairs(pending) do
                    if not score(record, slot_set, w, counts, list) then tinsert(left, record) end
                end
                pending = left
                if #list ~= before or #pending == 0 then publish(#pending == 0) end
            end
        end
        publish(true)
    end)
end

function M.search()
    local slot = current_slot()
    local queries, problem = filter_util.queries(filter_string(slot, max_level()))
    if not queries then
        aux.print('Upgrades: could not search ' .. slot.name .. ': ' .. tostring(problem))
        return
    end
    local records = {}
    let_go()
    generation = generation + 1 -- ends a scoring pass of the last search
    found, shown = records, {}
    state = {searching = true, slot = slot.name}
    changed()
    scan.start{
        type = 'list',
        fast = true,
        queries = queries,
        on_scan_start = function() aux.status_bar:update_status(0, 0) end,
        on_auction = function(record) tinsert(records, record) end,
        on_complete = function()
            aux.status_bar:update_status(1, 1)
            if found ~= records then return end
            state.searching = false
            state.searched_at = time()
            rescore()
        end,
        on_abort = function()
            aux.status_bar:update_status(1, 1)
            if found ~= records then return end
            state.searching = false
            state.stopped = true
            changed()
        end,
    }
end

function M.results() return shown end
function M.state() return state end

-- what is worn in the current slot, scored with the current spec: score, link (nil for an empty
-- slot or both hands), loaded
function M.worn()
    local spec, slot = current_spec(), current_slot()
    if not spec then return end
    return stats.worn_score(slot.locations[1], spec_weights(spec))
end

-- Buying (Ben, 2026-11-17: buy straight from this tab, with the mouse and the gamepad). A row comes
-- from the item list: its lowest price, not an auction. Selecting it reads that version's auctions
-- (one request), and the buy bar under the table (gui/buy_bar.lua, borrowed as the Sniper does)
-- offers the cheapest one at its real price, on the button. Nothing is bought without a click or a
-- pad press on Buy: the game takes a purchase only from a button press (aux-addon.lua, place_bid),
-- so a read that ends later cannot buy by itself. A row is read again on every selection, because
-- the auction house buys from the latest read of an item (the Sniper's finding, Tyler, 0.4.1).

local buy_bar = require 'aux.gui.buy_bar'

local checked  -- the row selected for buying
local reading  -- the row whose auctions are being read
local offer    -- the auction on the buy bar now, and its row

local show_offer

-- reads a row's auctions; the cheapest with a buyout goes on the buy bar
local function read_row(row, note)
    reading, offer = row, nil
    buy_bar.show_note(row.name, note or 'Reading its auctions...')
    local loaded = {}
    scan.start{
        type = 'list',
        quiet = true,
        no_view = true, -- one version of an item, not a look at the whole item (scan.lua)
        queries = {{item_keys = {row.browse_key}}},
        on_auction = function(auction)
            if not auction.own and not auction.commodity and auction.buyout_price > 0 then
                tinsert(loaded, auction)
            end
        end,
        on_complete = function()
            if reading ~= row then return end
            reading = nil
            local cheapest
            for _, auction in ipairs(loaded) do
                if not cheapest or auction.buyout_price < cheapest.buyout_price then cheapest = auction end
            end
            local count = 0
            for _, auction in ipairs(loaded) do count = count + (auction.auction_count or 1) end
            if cheapest then
                -- the row shows what is for sale now
                row.unit_buyout_price, row.buyout_price, row.auction_count = cheapest.unit_buyout_price, cheapest.buyout_price, count
                if row.upgrade then row.upgrade.per_gold = per_gold(row.upgrade.gain, cheapest.unit_buyout_price) end
            else
                -- gone: off the list (found too, or the next scoring brings it back)
                for _, list in ipairs{found, shown} do
                    local index = aux.key(list, row)
                    if index then tremove(list, index) end
                end
            end
            changed()
            if checked ~= row then return end
            if cheapest then
                show_offer(row, cheapest)
            else
                buy_bar.show_note(row.name, 'Nothing left to buy: it sold or was taken down')
            end
        end,
        on_abort = function()
            if reading ~= row then return end
            reading = nil
            if checked == row then
                buy_bar.show_note(row.name, 'Stopped before its auctions were read: select it again')
            end
        end,
    }
end

function show_offer(row, auction)
    offer = {row = row, auction = auction}
    local mine = offer
    local function after(note)
        return function()
            if offer == mine then offer = nil end
            if checked == row then read_row(row, note) end
        end
    end
    local function failure(error)
        if offer == mine then offer = nil end
        if error == 'timeout' then
            -- it may still go through on a slow server: nothing more is offered until it is read again
            buy_bar.show_message('No answer from the auction house yet', 'It may still go through: check your mail before buying again', aux.color.red)
        elseif checked == row then
            read_row(row, 'Could not buy it: reading its auctions again...')
        end
    end
    buy_bar.show_item{
        record = auction,
        name = row.name,
        texture = row.texture,
        quality = row.quality,
        own = false,
        busy = function() return offer ~= mine or reading ~= nil or aux.bid_in_progress() end,
        on_buy = function()
            aux.place_bid(auction.auction_id, auction.buyout_price, after('Bought. Looking for another one...'), failure)
        end,
        on_bid = function()
            aux.place_bid(auction.auction_id, auction.bid_price, after('Bid placed. Reading its auctions again...'), failure)
        end,
    }
end

-- the table's selection changed (frame.lua): read the new row, or clear the bar
function M.select_row(row)
    if row == checked then return end
    checked = row
    if row then
        read_row(row)
    else
        offer = nil
        if reading then reading = nil; scan.abort() end
        buy_bar.clear()
    end
end

-- a new search or slot: nothing selected, nothing on the buy bar
function M.let_go()
    if listing then listing:SetSelectedRecord(nil, true) end
    select_row(nil)
end

-- whether the buy bar offers this row now (the gamepad's Y buys it then)
function M.offering(row)
    return row ~= nil and offer ~= nil and offer.row == row and checked == row and reading == nil
end

-- Y on a gamepad with a row in focus: Buy when the bar offers that row, else select it so its
-- auctions are read (and the next Y buys). Runs inside the pad press, so the purchase is allowed.
function M.pad_buy(row)
    if not row then return end
    if offering(row) then
        buy_bar.primary_click()
    elseif row ~= checked then
        listing:SetSelectedRecord(row)
    elseif reading ~= row then
        read_row(row) -- selected, but its read was stopped or found nothing: read it again
    end
end

-- whether this row's auctions are being read now (the gamepad hint waits)
function M.reading_row(row)
    return row ~= nil and reading == row
end

function tab.OPEN()
    frame:Show()
    buy_bar.attach(frame.listing)
    changed()
end

function tab.CLOSE()
    if reading then reading = nil; scan.abort() end
    checked, offer = nil, nil
    listing:SetSelectedRecord(nil, true)
    buy_bar.attach_default()
    frame:Hide()
end
