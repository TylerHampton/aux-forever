select(2, ...) 'aux.tabs.upgrades'

local aux = require 'aux'
local gui = require 'aux.gui'
local weights = require 'aux.core.weights'

-- auxForever: the weights editor, "Settings / Upgrade weights" in the approved mockup. One number per
-- stat for a spec: the guide's ranked weight until the player types their own. Kept per character
-- and spec (core.lua, set_weight). Opened from the Upgrades tab and from Settings. A popup in the
-- DIALOG layer, so the gamepad keeps its focus inside it and B closes it (gamepad.lua).

local WIDTH, PAD, ROW, COLUMN_GAP = 520, 16, 28, 24
local COLUMN = (WIDTH - 2 * PAD - COLUMN_GAP) / 2

local popup = CreateFrame('Frame', nil, aux.frame, 'BackdropTemplate')
gui.set_panel_style(popup)
popup:SetFrameStrata('DIALOG')
popup:SetPoint('CENTER', aux.frame, 'CENTER')
popup:EnableMouse(true)
popup:Hide()
M.weights_popup = popup

local title = gui.label(popup, gui.font_size.small)
title:SetPoint('TOPLEFT', PAD, -12)
title:SetText('SETTINGS / UPGRADE WEIGHTS')
gui.text_color(title, aux.color.accent.background)

local close = gui.button(popup, gui.font_size.small)
gui.set_size(close, 60, 22)
close:SetPoint('TOPRIGHT', -PAD, -8)
close:SetText('Close')
close:SetScript('OnClick', function() popup:Hide() end)

local intro = gui.label(popup, gui.font_size.small)
intro:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -8)
intro:SetWidth(WIDTH - 2 * PAD)
intro:SetWordWrap(true)
intro:SetJustifyH('LEFT')
intro:SetText('How much each stat is worth to a spec, per point. The Upgrades tab adds up an item\'s stats times these numbers. Your numbers show in gold and are kept for this character; an empty box or Reset brings back the guide\'s. 0 leaves a stat out.')
gui.text_color(intro, aux.color.label.enabled)

local spec_label = gui.label(popup, gui.font_size.small)
spec_label:SetPoint('TOPLEFT', intro, 'BOTTOMLEFT', 0, -12)
spec_label:SetText('Spec')
gui.text_color(spec_label, aux.color.label.enabled)

-- the spec being edited (not necessarily the one the tab searches with)
local editing
M.weights_spec_dropdown = gui.dropdown(popup)
weights_spec_dropdown:SetPoint('TOPLEFT', spec_label, 'BOTTOMLEFT', 0, -4)
weights_spec_dropdown:SetWidth(COLUMN)
weights_spec_dropdown.enter = weights_spec_dropdown.ClearFocus
weights_spec_dropdown.selection_change = function()
    local spec = weights.specs(class())[weights_spec_dropdown:GetIndex() or 0]
    if spec and spec.id ~= editing then
        editing = spec.id
        refresh_weights()
    end
end

M.reset_button = gui.button(popup, gui.font_size.small)
gui.set_size(reset_button, 140, 24)
reset_button:SetPoint('LEFT', weights_spec_dropdown, 'RIGHT', COLUMN_GAP, 0)
reset_button:SetText('Reset to defaults')
reset_button:SetScript('OnClick', function()
    if editing then reset_weights(editing) end
    refresh_weights()
end)

-- one row per stat, two columns: its name, and a box with its number
local grid = CreateFrame('Frame', nil, popup)
grid:SetPoint('TOPLEFT', weights_spec_dropdown, 'BOTTOMLEFT', 0, -14)
local rows = ceil(#weights.STAT_ORDER / 2)
gui.set_size(grid, WIDTH - 2 * PAD, rows * ROW)
M.weight_boxes = {}

-- the number typed in a box, or nil for an empty box (the guide's number); false when not a number
function M.parse_weight(text)
    text = aux.trim(text or '')
    if text == '' then return nil end
    local value = tonumber(text)
    if not value or value < 0 or value ~= value then return false end
    return value
end

for i, stat in ipairs(weights.STAT_ORDER) do
    local column, row = (i - 1) % 2, floor((i - 1) / 2)
    local x, y = column * (COLUMN + COLUMN_GAP), -row * ROW
    local label = gui.label(grid, gui.font_size.medium)
    label:SetPoint('TOPLEFT', x, y - 5)
    label:SetText(weights.STAT_NAMES[stat])
    gui.text_color(label, aux.color.text.enabled)
    local box = gui.editbox(grid)
    box:SetPoint('TOPRIGHT', grid, 'TOPLEFT', x + COLUMN, y)
    gui.set_size(box, 70, 22)
    box:SetJustifyH('RIGHT')
    box.stat = stat
    local function commit()
        if not editing then return end
        local value = parse_weight(box:GetText())
        if value ~= false then set_weight(editing, stat, value) end
        refresh_weights()
    end
    box.enter = function() box:ClearFocus() end
    box.focus_loss = commit
    weight_boxes[i] = box
end

local note = gui.label(popup, gui.font_size.small)
note:SetPoint('TOPLEFT', grid, 'BOTTOMLEFT', 0, -12)
note:SetWidth(WIDTH - 2 * PAD)
note:SetWordWrap(true)
note:SetJustifyH('LEFT')
gui.text_color(note, aux.color.label.disabled)

gui.set_size(popup, WIDTH, 200 + rows * ROW)

local function number_text(value)
    return value and format('%g', value) or '0'
end

function M.refresh_weights()
    if not popup:IsShown() then return end
    local specs = weights.specs(class())
    if not weights.spec(class(), editing) then editing = saved().spec end
    local spec = weights.spec(class(), editing)
    local names, index = {}, nil
    for i, s in ipairs(specs) do
        tinsert(names, s.name)
        if s.id == editing then index = i end
    end
    weights_spec_dropdown:SetOptions(names)
    weights_spec_dropdown:SetIndex(index)
    if not spec then
        note:SetText('No stat priorities for this class.')
        return
    end
    local own, ranks = overrides(spec.id), weights.ranks(spec, overrides(spec.id))
    for _, box in ipairs(weight_boxes) do
        if not box:HasFocus() then
            box:SetText(number_text(ranks[box.stat]))
        end
        local color = own[box.stat] and aux.color.accent.text or aux.color.text.enabled
        box:SetTextColor(color())
    end
    note:SetText('Guide: Icy Veins, WoW Forever, ' .. spec.name .. ' stat priority (icy-veins.com/wow-forever/' .. spec.page .. '-stat-priority). Its order became 1 point for the last stat up to ' .. #spec.priority .. ' for the first. Made for level 60; Forever\'s items may call for other numbers.')
    do (refresh or pass)() end
end

-- opens the editor on the spec the tab uses
function M.open_weights()
    editing = saved().spec
    popup:Show()
    refresh_weights()
end
