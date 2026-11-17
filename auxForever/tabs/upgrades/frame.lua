select(2, ...) 'aux.tabs.upgrades'

local aux = require 'aux'
local gui = require 'aux.gui'
local money = require 'aux.util.money'
local sort_util = require 'aux.util.sort'
local auction_listing = require 'aux.gui.auction_listing'
local search_tab = require 'aux.tabs.search'
local buy_bar = require 'aux.gui.buy_bar'
local weights = require 'aux.core.weights'

-- auxForever: the Upgrades tab's screen, from the approved mockup: the choices on the left (spec,
-- slot, required level, Search, what is worn, the weights), the upgrades in a table on the right.
-- Redrawn only when something changed (core.lua calls refresh through on_change).

local LEFT_WIDTH = 270

M.frame = CreateFrame('Frame', nil, aux.frame)
frame:SetAllPoints(aux.frame.body)
frame:Hide()

local left = gui.panel(frame)
left:SetPoint('TOPLEFT', aux.frame.body, 'TOPLEFT', 4, -6)
left:SetPoint('BOTTOMLEFT', aux.frame.content, 'BOTTOMLEFT', 0, 0)
left:SetWidth(LEFT_WIDTH)

frame.listing = gui.panel(frame)
frame.listing:SetPoint('TOPLEFT', aux.frame.content, 'TOPLEFT', LEFT_WIDTH + 6, 0)
frame.listing:SetPoint('BOTTOMRIGHT', aux.frame.content, 'BOTTOMRIGHT', 0, 0)

-- the table, with the buy bar under it (core.lua attaches the bar while the tab is open)
frame.listing.list = CreateFrame('Frame', nil, frame.listing)
frame.listing.list:SetPoint('TOPLEFT', 0, 0)
frame.listing.list:SetPoint('BOTTOMRIGHT', 0, buy_bar.HEIGHT + 4)
-- for the gamepad: Y on a row of it buys (gamepad.lua)
M.upgrades_list = frame.listing.list

local function small_label(text, anchor, y)
    local label = gui.label(left, gui.font_size.small)
    label:SetPoint('TOPLEFT', anchor, anchor == left and 'TOPLEFT' or 'BOTTOMLEFT', anchor == left and 10 or 0, y)
    label:SetText(text)
    gui.text_color(label, aux.color.label.enabled)
    return label
end

-- spec
local spec_label = small_label('Spec', left, -10)
M.spec_dropdown = gui.dropdown(left)
spec_dropdown:SetPoint('TOPLEFT', spec_label, 'BOTTOMLEFT', 0, -4)
spec_dropdown:SetWidth(LEFT_WIDTH - 20)
spec_dropdown.enter = spec_dropdown.ClearFocus
spec_dropdown.selection_change = function()
    local spec = weights.specs(class())[spec_dropdown:GetIndex() or 0]
    if spec and spec.id ~= saved().spec then set_spec(spec.id) end
end
local spec_note = gui.label(left, gui.font_size.small)
spec_note:SetPoint('TOPLEFT', spec_dropdown, 'BOTTOMLEFT', 0, -3)
spec_note:SetText('Remembered for this character')
gui.text_color(spec_note, aux.color.label.disabled)

-- slot: a grid of 16 buttons, four to a row
local slot_label = small_label('Slot', spec_note, -10)
M.slot_buttons = {}
do
    local width = floor((LEFT_WIDTH - 20 - 3 * 3) / 4)
    for i, slot in ipairs(SLOTS) do
        local btn = gui.button(left, gui.font_size.small)
        btn:SetSize(width, 22)
        local column, row = (i - 1) % 4, floor((i - 1) / 4)
        btn:SetPoint('TOPLEFT', slot_label, 'BOTTOMLEFT', column * (width + 3), -4 - row * 25)
        btn:SetText(slot.name)
        btn:SetScript('OnClick', function() set_slot(i) end)
        slot_buttons[i] = btn
    end
end

-- required level
local level_label = small_label('Required level', slot_buttons[13], -12)
M.level_dropdown = gui.dropdown(left)
level_dropdown:SetPoint('TOPLEFT', level_label, 'BOTTOMLEFT', 0, -4)
level_dropdown:SetWidth(LEFT_WIDTH - 20)
level_dropdown.enter = level_dropdown.ClearFocus
level_dropdown.selection_change = function()
    local index = level_dropdown:GetIndex()
    if index and index ~= saved().extra then set_extra(index) end
end

-- Search (Y on a gamepad, gamepad.lua)
M.search_button = gui.button(left)
search_button:SetPoint('TOPLEFT', level_dropdown, 'BOTTOMLEFT', 0, -12)
search_button:SetSize(LEFT_WIDTH - 20, 28)
search_button:SetText('Search')
gui.set_primary(search_button)
search_button:SetScript('OnClick', function() search() end)

-- what is worn in that slot
local worn_box = CreateFrame('Frame', nil, left, 'BackdropTemplate')
worn_box:SetPoint('TOPLEFT', search_button, 'BOTTOMLEFT', 0, -12)
worn_box:SetSize(LEFT_WIDTH - 20, 74)
gui.set_frame_style(worn_box, aux.color.content.background, aux.color.content.border)
local worn_title = gui.label(worn_box, gui.font_size.small)
worn_title:SetPoint('TOPLEFT', 8, -6)
worn_title:SetText('WEARING NOW')
gui.text_color(worn_title, aux.color.label.enabled)
local worn_name = gui.label(worn_box, gui.font_size.medium)
worn_name:SetPoint('TOPLEFT', worn_title, 'BOTTOMLEFT', 0, -4)
worn_name:SetPoint('RIGHT', worn_box, 'RIGHT', -8, 0)
local worn_score = gui.label(worn_box, gui.font_size.small)
worn_score:SetPoint('BOTTOMLEFT', 8, 6)
worn_score:SetPoint('RIGHT', worn_box, 'RIGHT', -8, 0)

-- the weights in use
local weights_label = gui.label(left, gui.font_size.small)
weights_label:SetPoint('BOTTOMLEFT', 10, 38)
weights_label:SetWidth(LEFT_WIDTH - 20)
weights_label:SetWordWrap(true)
weights_label:SetJustifyH('LEFT')
gui.text_color(weights_label, aux.color.label.enabled)

-- opens the weights editor (tabs/upgrades/weights.lua), also reached from Settings
M.weights_button = gui.button(left, gui.font_size.small)
weights_button:SetPoint('BOTTOMLEFT', 10, 10)
weights_button:SetSize(LEFT_WIDTH - 20, 22)
weights_button:SetText('Change weights')
weights_button:SetScript('OnClick', function() open_weights() end)

-- above the table: which slot, and what the search found
local title = gui.label(frame, gui.font_size.large)
title:SetPoint('BOTTOMLEFT', aux.frame.content, 'TOPLEFT', LEFT_WIDTH + 16, 10)
local status = gui.label(frame, gui.font_size.small)
status:SetPoint('BOTTOMRIGHT', aux.frame.content, 'TOPRIGHT', -10, 12)
gui.text_color(status, aux.color.label.enabled)

-- the table
local function stat_label(key)
    local text = _G[key]
    if type(text) ~= 'string' then return key end
    return text == 'damage per second' and 'DPS' or text
end

-- the stats that change, biggest weighted change first: "+3.1 DPS, +4 Strength, -2 Stamina"
function M.changes_text(changes, limit)
    local parts = {}
    for i, change in ipairs(changes or {}) do
        if i > (limit or 3) then break end
        local diff = change.diff
        local number = (diff == floor(diff)) and format('%+d', diff) or format('%+.1f', diff)
        local text = number .. ' ' .. stat_label(change.name)
        local color = change.weighted > 0 and aux.color.green or change.weighted < 0 and aux.color.red or aux.color.label.enabled
        tinsert(parts, color(text))
    end
    return table.concat(parts, ', ')
end

-- "+16.8%", or the points gained when nothing is worn there
function M.gain_text(upgrade)
    if upgrade.percent then
        return format('+%.1f%%', upgrade.percent)
    end
    return format('+%.1f', upgrade.gain)
end

-- gain per gold: whole numbers from 10 up, one decimal from 1, two below; "?" without a price
function M.per_gold_text(value)
    if not value then return '?' end
    if value >= 10 then return format('%d', floor(value + .5)) end
    if value >= 1 then return format('%.1f', value) end
    return format('%.2f', value)
end

M.columns = {
    auction_listing.requirement_column(),
    auction_listing.item_level_column(),
    {
        title = 'Item',
        width = .24,
        init = auction_listing.item_column_init,
        fill = auction_listing.item_column_fill,
        cmp = function(a, b, desc) return sort_util.compare(a.name, b.name, desc) end,
    },
    {
        title = 'Score',
        width = .07,
        align = 'CENTER',
        fill = function(cell, record) cell.text:SetText(format('%.1f', record.upgrade.score)) end,
        cmp = function(a, b, desc) return sort_util.compare(a.upgrade.score, b.upgrade.score, desc) end,
    },
    {
        title = 'Gain',
        width = .08,
        align = 'CENTER',
        fill = function(cell, record) cell.text:SetText(aux.color.green(gain_text(record.upgrade))) end,
        cmp = function(a, b, desc)
            return sort_util.compare(a.upgrade.percent or a.upgrade.gain, b.upgrade.percent or b.upgrade.gain, desc)
        end,
    },
    {
        -- score points gained for each gold of the price: cheap small upgrades and dear big ones on
        -- one scale (Ben, 2026-11-16)
        title = 'Per gold',
        width = .08,
        align = 'CENTER',
        fill = function(cell, record) cell.text:SetText(per_gold_text(record.upgrade.per_gold)) end,
        cmp = function(a, b, desc) return sort_util.compare(a.upgrade.per_gold or 0, b.upgrade.per_gold or 0, desc) end,
    },
    {
        title = 'Changes',
        width = .22,
        align = 'LEFT',
        fill = function(cell, record) cell.text:SetText(changes_text(record.upgrade.changes)) end,
        cmp = function(a, b, desc) return sort_util.compare(a.upgrade.gain, b.upgrade.gain, desc) end,
    },
    {
        title = 'For sale',
        width = .07,
        align = 'CENTER',
        fill = function(cell, record) cell.text:SetText(record.auction_count or 1) end,
        cmp = function(a, b, desc) return sort_util.compare(a.auction_count or 1, b.auction_count or 1, desc) end,
    },
    {
        title = 'Buyout',
        width = .14,
        align = 'RIGHT',
        fill = function(cell, record) cell.text:SetText(money.to_string(ceil(record.unit_buyout_price), true)) end,
        cmp = function(a, b, desc) return sort_util.compare(a.unit_buyout_price, b.unit_buyout_price, desc) end,
    },
}
-- Gain is column 5, Per gold 6 (AGENTS.md: adding a column shifts these numbers)
M.GAIN_COLUMN = 5
M.PER_GOLD_COLUMN = 6

M.listing = auction_listing.new(frame.listing.list, 19, columns)
listing.one_row_each = true
-- every row is another item: a row that left the table leaves nothing selected, so another item is
-- never offered to buy without being clicked (as on the Sniper)
listing.keep_selection_only = true
listing.select_hint = 'Click: select to buy'
listing:SetSort(-GAIN_COLUMN)
listing:Reset()
-- Right-click opens that exact item (its ending included) on the Search tab, as right-click on a row
-- does in every table (docs/clicks.md). A click selects it to buy here (core.lua, select_row).
function M.open_in_search(record)
    aux.set_tab(1)
    search_tab.set_filter(strlower(record.name) .. '/exact')
    search_tab.execute(nil, false)
end
listing:SetHandler('OnClick', function(row, button)
    if row.record and button == 'RightButton' then open_in_search(row.record) end
end)
listing:SetHandler('OnSelectionChanged', function(_, selection)
    select_row(selection and selection.record or nil)
end)

local function level_options()
    local options = {}
    for _, extra in ipairs(EXTRA_LEVELS) do
        local level = min(60, UnitLevel('player') + extra)
        tinsert(options, extra == 0 and format('Up to my level (%d)', level) or format('Up to my level + %d (%d)', extra, level))
    end
    return options
end

local function weights_text(spec)
    local parts = {}
    local ranks, own = weights.ranks(spec, overrides(spec.id)), overrides(spec.id)
    local listed = {}
    for _, name in ipairs(spec.priority) do listed[name] = true end
    listed.attack_power = listed.attack_power or spec.ap ~= nil
    for _, name in ipairs(weights.STAT_ORDER) do
        if ranks[name] and (listed[name] or own[name]) then
            tinsert(parts, {name = name, value = ranks[name]})
        end
    end
    sort(parts, function(a, b) return a.value > b.value or a.value == b.value and a.name < b.name end)
    for i, part in ipairs(parts) do
        local text = (weights.STAT_NAMES[part.name] or part.name) .. ' ' .. format('%g', part.value)
        parts[i] = own[part.name] and aux.color.accent.text(text) or text
    end
    local source = next(own) and 'Your own numbers in gold; the rest from Icy Veins (WoW Forever), ' or 'From Icy Veins (WoW Forever), '
    return 'Weights: ' .. table.concat(parts, ', ') .. '. ' .. source .. spec.name .. '.'
end

-- Full scan tip (Ben, 2026-11-17: "running a full scan prior to looking for upgrades is highly
-- recommended"). A Full scan saves the stats of every ending (core.lua), so a search here skips
-- most of its reading step (E11: 21 reads instead of 100+). Shown before a search and while the
-- tab reads endings, only when no Full scan was started in the last day. On the status line, not
-- the left panel: the left panel has no room left at the smallest window.
M.FULL_SCAN_TIP_AGE = 24 * 3600
function M.full_scan_recent()
    return time() - (aux.account_data.replicate_time or 0) < FULL_SCAN_TIP_AGE
end
local TIP = 'Tip: run a Full scan first (top right), then searches here are much faster'

function M.status_text(s, slot)
    if s.searching then return 'Searching ' .. slot.name .. '...' end
    if s.endings then
        local text = format('Reading the stats of each ending (%d of %d)...', s.endings.done, s.endings.total)
        return full_scan_recent() and text or text .. ' A Full scan first skips this step'
    end
    if s.scoring then return 'Scoring...' end
    if s.stopped then return 'Stopped before the end: search again' end
    if not s.searched_at then
        return full_scan_recent() and 'Pick a slot and press Search' or aux.color.accent.text(TIP)
    end
    local text = format('%d upgrade%s among %d %s item%s you can use, searched at %s',
        #results(), #results() == 1 and '' or 's', s.considered or 0, slot.name, (s.considered or 0) == 1 and '' or 's', date('%H:%M', s.searched_at))
    if (s.unloaded or 0) > 0 then
        text = text .. format(' (%d not loaded yet: search again)', s.unloaded)
    end
    if (s.base_only or 0) > 0 then
        text = text .. format(' (%d scored without their ending\'s stats: search again)', s.base_only)
    end
    if (s.below_floor or 0) > 0 then
        text = text .. format(' (%d below level %d scored without their ending\'s stats)', s.below_floor, s.floor or 1)
    end
    if s.worn_loading then
        text = text .. ' (what you wear was still loading: search again)'
    end
    return text
end

function M.refresh()
    if not frame:IsShown() then return end
    local spec, slot, u = current_spec(), current_slot(), saved()

    local names, spec_index = {}, nil
    for i, s in ipairs(weights.specs(class())) do
        tinsert(names, s.name)
        if s.id == u.spec then spec_index = i end
    end
    spec_dropdown:SetOptions(names)
    spec_dropdown:SetIndex(spec_index)
    level_dropdown:SetOptions(level_options())
    level_dropdown:SetIndex(u.extra)
    for i, btn in ipairs(slot_buttons) do
        gui.style_choice(btn, i == u.slot)
    end

    local score, link, loaded = worn()
    if link then
        worn_name:SetText(link)
    elseif score and score > 0 then
        worn_name:SetText('Main hand and off hand')
    else
        worn_name:SetText(aux.color.label.disabled('Nothing'))
    end
    worn_score:SetText(score and ('Score ' .. format('%.1f', score) .. (loaded == false and ' (still loading)' or '')) or '')
    weights_label:SetText(spec and weights_text(spec) or 'No stat priorities for this class')

    title:SetText('Upgrades for ' .. aux.color.accent.text(slot.name))
    status:SetText(status_text(state(), slot))
    listing:SetDatabase(results())
end

on_change(refresh)
