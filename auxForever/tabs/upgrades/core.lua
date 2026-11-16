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
function M.current_slot() return SLOTS[saved().slot] end
function M.max_level() return min(60, UnitLevel('player') + EXTRA_LEVELS[saved().extra]) end

function M.set_spec(id)
    if weights.spec(class(), id) then saved().spec = id; rescore() end
end
function M.set_slot(index)
    if SLOTS[index] and saved().slot ~= index then
        saved().slot = index
        found, shown, state = {}, {}, {}
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
    local w, slot_set = weights.weights(spec), set_of(slot.locations)
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
    return stats.worn_score(slot.locations[1], weights.weights(spec))
end

function tab.OPEN()
    frame:Show()
    changed()
end

function tab.CLOSE()
    frame:Hide()
end
