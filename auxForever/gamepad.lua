select(2, ...) 'aux'

local gui = require 'aux.gui'

-- Gamepad support for Forever's gamepad mode. Nothing here runs unless gamepad mode is on.
--
-- aux must not write into Blizzard's gamepad system (GamepadMode, SmartNavigation, the window
-- manager or its binding stack): whatever aux writes there taints Blizzard's own code later. The
-- first try registered aux with Blizzard's window manager; closing aux by gamepad then had Blizzard
-- call SetPreferredGamepadInteractTarget, which was blocked, each "blocked" popup was blocked in turn
-- (259 times) and the game froze (Logs/taint.log, 2026-10-13).
--
-- So aux has a navigator of its own. While aux is open it binds the pad buttons to buttons of its own
-- with override bindings on a frame it owns; they win over Blizzard's navigation, which still drives
-- the invisible Blizzard auction house window (probe, 2026-10-13), and a press through them counts
-- as a hardware event, so A can buy and post.
--   D-pad  moves a gold frame to the nearest control in that direction; in a list, past the last
--          row shown, it scrolls the list
--   A      presses the control (focuses a text box; opens a dropdown, then picks an option)
--   B      closes what is open: a dropdown, a text box, a popup (Settings, quick searches), then aux
--   LB/RB  step through the top bar: the five tabs (switched at once), then Settings, Full scan
--          and Blizzard UI (A presses them)
-- Nothing runs every frame: the controls are found when a button is pressed.

local KEYS = {
    {'up', 'GAMEPAD_DPAD_TOP', 'PADDUP'},
    {'down', 'GAMEPAD_DPAD_BOTTOM', 'PADDDOWN'},
    {'left', 'GAMEPAD_DPAD_LEFT', 'PADDLEFT'},
    {'right', 'GAMEPAD_DPAD_RIGHT', 'PADDRIGHT'},
    {'A', 'GAMEPAD_FACE_BOTTOM', 'PAD1'},
    {'B', 'GAMEPAD_FACE_RIGHT', 'PAD2'},
    {'LB', 'GAMEPAD_SHOULDER_LEFT', 'PADLSHOULDER'},
    {'RB', 'GAMEPAD_SHOULDER_RIGHT', 'PADRSHOULDER'},
}
local TOP_BAR_HEIGHT = 40

function M.gamepad_enabled()
    local input = _G.InputUtil
    return input ~= nil and input.IsGamepadUIEnabled ~= nil and input.IsGamepadUIEnabled() and true or false
end

local owner = CreateFrame('Frame')
local focused

-- the gold frame around the control that has the pad's focus, above popups and menus
local marker = CreateFrame('Frame', nil, frame)
marker:SetFrameStrata('FULLSCREEN_DIALOG')
marker:Hide()
do
    local edges = {}
    for i = 1, 4 do
        edges[i] = marker:CreateTexture(nil, 'OVERLAY')
        edges[i]:SetTexture([[Interface\Buttons\WHITE8X8]])
    end
    edges[1]:SetPoint('TOPLEFT'); edges[1]:SetPoint('TOPRIGHT'); edges[1]:SetHeight(2)
    edges[2]:SetPoint('BOTTOMLEFT'); edges[2]:SetPoint('BOTTOMRIGHT'); edges[2]:SetHeight(2)
    edges[3]:SetPoint('TOPLEFT'); edges[3]:SetPoint('BOTTOMLEFT'); edges[3]:SetWidth(2)
    edges[4]:SetPoint('TOPRIGHT'); edges[4]:SetPoint('BOTTOMRIGHT'); edges[4]:SetWidth(2)
    marker:SetScript('OnShow', function()
        for _, edge in ipairs(edges) do edge:SetVertexColor(color.accent.background()) end
    end)
end

-- the top bar: tabs, then the Settings, Full scan and Blizzard UI buttons
local function top_bar()
    local items = {}
    for _, tab in ipairs(tabs._tabs) do tinsert(items, tab) end
    tinsert(items, settings_button)
    tinsert(items, scan_button)
    tinsert(items, blizzard_button)
    return items
end

local top_bar_set
local function in_top_bar(f)
    -- the tabs exist once the saved settings load (event.AUX_LOADED in frame.lua)
    if not top_bar_set or not top_bar_set[tabs._tabs[1] or false] then
        top_bar_set = {}
        for _, item in ipairs(top_bar()) do top_bar_set[item] = true end
    end
    return top_bar_set[f] or false
end

local function usable(f)
    if not f or not f:IsVisible() then return false end
    if f.GetEffectiveAlpha and f:GetEffectiveAlpha() < .05 then return false end
    local x = f:GetCenter()
    return x ~= nil
end

-- what A can act on: buttons, text boxes, and frames that react to a mouse press (the Post tab's
-- bag list rows)
local function is_stop(f)
    if f == resize_grip or f == close_button or f == marker or in_top_bar(f) then return false end
    if f:IsObjectType('ScrollFrame') or f:IsObjectType('Slider') then return false end
    if f:IsObjectType('Button') or f:IsObjectType('EditBox') then return true end
    return f:GetScript('OnMouseUp') ~= nil or f:GetScript('OnMouseDown') ~= nil
end

local function collect(f, found)
    if not usable(f) then return end
    if f ~= frame and is_stop(f) then
        tinsert(found, f)
        return -- a row's own icon button is part of the row
    end
    -- a list's scroll bar is driven by the D-pad, not visited
    if f:IsObjectType('ScrollFrame') then return end
    for _, child in ipairs{f:GetChildren()} do
        collect(child, found)
    end
end

-- a popup on top of aux keeps the focus inside it: Settings, the quick search menu and the Filter
-- Builder's menu are aux's only frames in the DIALOG layer
local function find_popup(f)
    for _, child in ipairs{f:GetChildren()} do
        if child:IsVisible() and child ~= marker then
            if child:GetFrameStrata() == 'DIALOG' then return child end
            local popup = find_popup(child)
            if popup then return popup end
        end
    end
end

local function root()
    return find_popup(frame) or frame
end

local function stops()
    local found = {}
    collect(root(), found)
    return found
end

local function show_tooltip(f)
    local enter = f and f:GetScript('OnEnter')
    if enter then enter(f) end
end

local function hide_tooltip(f)
    local leave = f and f:GetScript('OnLeave')
    if leave then leave(f) end
end

local function set_focus(f)
    if focused == f then return end
    if focused then
        hide_tooltip(focused)
        if focused:IsObjectType('EditBox') and focused:HasFocus() then focused:ClearFocus() end
    end
    focused = f
    if f then
        marker:ClearAllPoints()
        marker:SetPoint('TOPLEFT', f, 'TOPLEFT', -3, 3)
        marker:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 3, -3)
        marker:Show()
        show_tooltip(f)
    else
        marker:Hide()
    end
end
M.gamepad_set_focus = set_focus
function M.gamepad_focused() return focused end

local function first_stop()
    local best, best_top, best_left
    for _, f in ipairs(stops()) do
        if not in_top_bar(f) then
            local left, top = f:GetLeft(), f:GetTop()
            if not best or top > best_top + 4 or (abs(top - best_top) <= 4 and left < best_left) then
                best, best_top, best_left = f, top, left
            end
        end
    end
    return best
end

-- the nearest control in a direction: mostly along it, little to the side
local function nearest(from, direction)
    local x0, y0 = from:GetCenter()
    local best, best_score
    for _, f in ipairs(stops()) do
        if f ~= from then
            local x, y = f:GetCenter()
            local dx, dy = x - x0, y - y0
            local along, side
            if direction == 'up' then along, side = dy, abs(dx)
            elseif direction == 'down' then along, side = -dy, abs(dx)
            elseif direction == 'left' then along, side = -dx, abs(dy)
            else along, side = dx, abs(dy) end
            if along > 1 then
                local score = along + side * 2
                if not best or score < best_score then best, best_score = f, score end
            end
        end
    end
    return best
end

-- a list (search results, the Post tab's bag items) shows only the rows that fit: past the last one
-- shown, the D-pad scrolls it instead
local function scroll_bar_of(row)
    local list = row:GetParent() and row:GetParent():GetParent()
    if not list then return end
    for _, child in ipairs{list:GetChildren()} do
        if child:IsObjectType('ScrollFrame') then
            local name = child:GetName()
            return child.ScrollBar or (name and _G[name .. 'ScrollBar'])
        end
    end
end

local function scroll(row, direction)
    local bar = scroll_bar_of(row)
    if not bar then return false end
    local before = bar:GetValue()
    local low, high = bar:GetMinMaxValues()
    local step = row:GetHeight()
    bar:SetValue(bounded(low, high, before + (direction == 'down' and step or -step)))
    return bar:GetValue() ~= before
end

local function inside(f, ancestor)
    while f do
        if f == ancestor then return true end
        f = f:GetParent()
    end
    return false
end

local top_bar_step -- defined below, with LB and RB

local function move(direction)
    if not usable(focused) or not inside(focused, root()) then
        set_focus(first_stop())
        return
    end
    if in_top_bar(focused) then
        if direction == 'down' then
            set_focus(first_stop())
        elseif direction == 'left' or direction == 'right' then
            top_bar_step(direction == 'left' and -1 or 1)
        end
        return
    end
    local target = nearest(focused, direction)
    local vertical = direction == 'up' or direction == 'down'
    -- leaving a list sideways is a move; leaving it up or down scrolls it while it can
    if vertical and (not target or target:GetParent() ~= focused:GetParent()) and scroll(focused, direction) then
        show_tooltip(focused)
        return
    end
    if target then set_focus(target) end
end

-- presses the control as a mouse click would; runs inside the pad press, a hardware event
local function press(f)
    if f:IsObjectType('EditBox') then
        f:SetFocus()
        return
    end
    if f:IsObjectType('Button') and f:GetScript('OnClick') then
        if f:IsEnabled() then f:Click('LeftButton') end
        return
    end
    local down, up = f:GetScript('OnMouseDown'), f:GetScript('OnMouseUp')
    if down then down(f, 'LeftButton') end
    if up then up(f, 'LeftButton') end
end

-- an open dropdown menu (Category, Rarity, ...): it opens outside aux's window, so its options are
-- walked here
local menu, menu_items = gui.dropdown_menu, gui.dropdown_items
local menu_index

local function menu_open()
    return menu:IsShown() and menu.owner and menu.owner:HasFocus()
end

local function menu_count()
    local n = 0
    while menu_items[n + 1] and menu_items[n + 1]:IsShown() do n = n + 1 end
    return n
end

local function menu_move(step)
    local n = menu_count()
    if n == 0 then return end
    local current = menu_index or (menu.owner.GetIndex and menu.owner:GetIndex()) or (step > 0 and 0 or 2)
    menu_index = bounded(1, n, current + step)
    marker:ClearAllPoints()
    marker:SetPoint('TOPLEFT', menu_items[menu_index], 'TOPLEFT', -3, 3)
    marker:SetPoint('BOTTOMRIGHT', menu_items[menu_index], 'BOTTOMRIGHT', 3, -3)
end

local function menu_close()
    menu_index = nil
    if menu.owner then menu.owner:ClearFocus() end
    menu:Hide()
    if focused then set_focus(nil); set_focus(focused) end
end

local function menu_pick()
    local option = menu_index and menu_items[menu_index]
    menu_index = nil
    local owner_box = menu.owner
    if option then
        local down = option:GetScript('OnMouseDown')
        if down then down(option, 'LeftButton') end
    else
        menu_close()
    end
    -- back on the dropdown itself
    if owner_box then
        focused = nil
        set_focus(owner_box)
        if owner_box:HasFocus() then owner_box:ClearFocus() end
    end
end

local function back()
    if menu_open() then
        menu_close()
    elseif focused and focused:IsObjectType('EditBox') and focused:HasFocus() then
        local escape = focused:GetScript('OnEscapePressed')
        if escape then escape(focused) else focused:ClearFocus() end
    elseif root() ~= frame then
        root():Hide()
        set_focus(first_stop())
    else
        frame:Hide()
    end
end

-- LB and RB: the top bar, from the item that has the focus or else the selected tab
function top_bar_step(step)
    local items = top_bar()
    local index = tabs._selected or 1
    for i, item in ipairs(items) do
        if item == focused then index = i end
    end
    index = (index - 1 + step) % #items + 1
    local item = items[index]
    if index <= #tabs._tabs then
        if item.id ~= tabs._selected then
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            tabs:select(item.id)
        end
        set_focus(item)
    else
        set_focus(item)
    end
end

local actions = {
    up = function() if menu_open() then menu_move(-1) else move('up') end end,
    down = function() if menu_open() then menu_move(1) else move('down') end end,
    left = function() if not menu_open() then move('left') end end,
    right = function() if not menu_open() then move('right') end end,
    A = function()
        if menu_open() then
            menu_pick()
        elseif usable(focused) then
            -- a tab selected with LB/RB is already open: A goes into it
            if in_top_bar(focused) and focused.group == tabs then
                set_focus(first_stop())
            else
                press(focused)
            end
        else
            set_focus(first_stop())
        end
    end,
    B = back,
    LB = function() if menu_open() then menu_close() end; top_bar_step(-1) end,
    RB = function() if menu_open() then menu_close() end; top_bar_step(1) end,
}

for _, entry in ipairs(KEYS) do
    local name = entry[1]
    local button = CreateFrame('Button', 'auxForeverPad' .. name, owner)
    button:RegisterForClicks('AnyDown')
    button:SetScript('OnClick', function() actions[name]() end)
end

local bound, unbind_after_combat

local function key_of(entry)
    return _G[entry[2]] or entry[3]
end

function M.gamepad_bind()
    if bound or not gamepad_enabled() or InCombatLockdown() then return end
    for _, entry in ipairs(KEYS) do
        SetOverrideBindingClick(owner, true, key_of(entry), 'auxForeverPad' .. entry[1])
    end
    bound = true
end

function M.gamepad_unbind()
    if not bound then return end
    -- bindings cannot change in combat: they are given back once it ends
    if InCombatLockdown() then
        unbind_after_combat = true
        owner:RegisterEvent('PLAYER_REGEN_ENABLED')
        return
    end
    ClearOverrideBindings(owner)
    bound = false
end

owner:SetScript('OnEvent', function(self, event)
    if event == 'PLAYER_REGEN_ENABLED' then
        self:UnregisterEvent('PLAYER_REGEN_ENABLED')
        if unbind_after_combat and not (frame:IsShown() and not blizzard_frame_shown()) then
            unbind_after_combat = false
            gamepad_unbind()
        end
    end
end)

-- one frame after aux shows: Blizzard sets up its own bindings for its window as it opens, and the
-- latest override may be the one that counts
frame:HookScript('OnShow', function()
    if not gamepad_enabled() then return end
    focused = nil
    local function start()
        if not frame:IsShown() then return end
        gamepad_bind()
        set_focus(first_stop())
    end
    if C_Timer and C_Timer.After then C_Timer.After(0, start) else start() end
end)
frame:HookScript('OnHide', function()
    unbind_after_combat = false
    set_focus(nil)
    gamepad_unbind()
end)

-- the Blizzard UI button shows Blizzard's window on top of aux: its own gamepad navigation drives it
-- then, so aux gives the pad buttons back until it is hidden again
do
    local set_shown = set_blizzard_frame_shown
    function M.set_blizzard_frame_shown(shown)
        set_shown(shown)
        if not gamepad_enabled() or not frame:IsShown() then return end
        if shown then
            set_focus(nil)
            gamepad_unbind()
        else
            gamepad_bind()
        end
    end
end
