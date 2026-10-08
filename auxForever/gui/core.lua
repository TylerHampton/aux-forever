select(2, ...) 'aux.gui'

local aux = require 'aux'
local completion = require 'aux.util.completion'

-- auxForever: Forever does not load fonts from addons (it rejected Barlow, a basic rebuild of it and
-- PT Sans Narrow, while its own fonts load), so aux's original game font is used.
M.font = (function()
    local font = CreateFrame'Frame':CreateFontString()
    font:SetFontObject(NumberFont_Normal_Med)
    return font:GetFont()
end)()
M.font_bold = font

M.font_size = aux.immutable-{
    small = 13,
    medium = 15,
    large = 18,
}

-- auxForever (0.5, docs/clicks.md): the gray lines at the bottom of a row's tooltip that say what its
-- clicks do. The text is "Click: select  ·  Right-click: search"; each click gets its own line, the
-- click on the left and what it does on the right (one wrapped paragraph was hard to read, Tyler
-- build 1). A tooltip holding only the hint (alone) has no blank line above it.
M.HINT_SEPARATOR = '  ·  '
local HINT_GRAY = {.62, .60, .56}
function M.add_click_hint(tooltip, text, alone)
    if not text or text == '' then
        return
    end
    if not alone then
        tooltip:AddLine(' ')
    end
    local r, g, b = HINT_GRAY[1], HINT_GRAY[2], HINT_GRAY[3]
    -- split by hand: aux.split only handles one-character separators
    local parts, start = {}, 1
    while true do
        local i, j = strfind(text, HINT_SEPARATOR, start, true)
        tinsert(parts, strsub(text, start, (i or 0) - 1))
        if not i then break end
        start = j + 1
    end
    for _, part in ipairs(parts) do
        local click, action = strmatch(part, '^(.-):%s*(.*)$')
        if click then
            tooltip:AddDoubleLine(click, action, r, g, b, r, g, b)
        else
            tooltip:AddLine(part, r, g, b)
        end
    end
end

do
    local id = 1
    function M.unique_name()
        id = id + 1
        return 'aux.frame' .. id
    end
end

function M.set_size(frame, width, height)
    frame:SetWidth(width)
    frame:SetHeight(height or width)
end

-- auxForever (0.6, the UI Kit): square shapes. A frame gets a fill and a 1px outline, and the
-- frame's SetBackdropColor and SetBackdropBorderColor are replaced so every existing caller recolors
-- the shape instead of a backdrop. The radius arguments of older callers are ignored.
local WHITE = [[Interface\Buttons\WHITE8X8]]

-- left, right, top, bottom are insets like a backdrop's (negative values grow the shape)
local function create_shape(frame, layer, sublevel, kind, radius, left, right, top, bottom)
    left, right, top, bottom = left or 0, right or 0, top or 0, bottom or 0
    local pieces = {}
    local function rect()
        local t = frame:CreateTexture(nil, layer, nil, sublevel)
        t:SetTexture(WHITE)
        tinsert(pieces, t)
        return t
    end
    if kind == 'fill' then
        local t = rect()
        t:SetPoint('TOPLEFT', left, -top)
        t:SetPoint('BOTTOMRIGHT', -right, bottom)
    else
        local t = rect()
        t:SetPoint('TOPLEFT', left, -top)
        t:SetPoint('TOPRIGHT', -right, -top)
        t:SetHeight(1)
        t = rect()
        t:SetPoint('BOTTOMLEFT', left, bottom)
        t:SetPoint('BOTTOMRIGHT', -right, bottom)
        t:SetHeight(1)
        t = rect()
        t:SetPoint('TOPLEFT', left, -top)
        t:SetPoint('BOTTOMLEFT', left, bottom)
        t:SetWidth(1)
        t = rect()
        t:SetPoint('TOPRIGHT', -right, -top)
        t:SetPoint('BOTTOMRIGHT', -right, bottom)
        t:SetWidth(1)
    end
    local shape = {pieces = pieces}
    function shape:SetColor(r, g, b, a)
        for _, t in ipairs(self.pieces) do
            t:SetVertexColor(r, g, b, a or 1)
        end
    end
    function shape:SetShown(shown)
        for _, t in ipairs(self.pieces) do
            if shown then t:Show() else t:Hide() end
        end
    end
    return shape
end
M.create_shape = create_shape

local function shape_SetBackdropColor(self, r, g, b, a)
    self.aux_fill:SetColor(r, g, b, a)
end

local function shape_SetBackdropBorderColor(self, r, g, b, a)
    self.aux_border:SetColor(r, g, b, a)
end

function M.set_frame_style(frame, backdrop_color, border_color, left, right, top, bottom)
    if not frame.aux_fill then
        if frame.SetBackdrop then frame:SetBackdrop(nil) end
        frame.aux_fill = create_shape(frame, 'BACKGROUND', -8, 'fill', 0, left, right, top, bottom)
        frame.aux_border = create_shape(frame, 'BACKGROUND', -6, 'line', 0, left, right, top, bottom)
    end
    frame.SetBackdropColor = shape_SetBackdropColor
    frame.SetBackdropBorderColor = shape_SetBackdropBorderColor
    frame:SetBackdropColor(backdrop_color())
    frame:SetBackdropBorderColor(border_color())
end

function M.set_window_style(frame, left, right, top, bottom)
    set_frame_style(frame, aux.color.window.background, aux.color.window.border, left, right, top, bottom)
end

function M.set_panel_style(frame, left, right, top, bottom)
    set_frame_style(frame, aux.color.panel.background, aux.color.panel.border, left, right, top, bottom)
end

function M.set_content_style(frame, left, right, top, bottom)
    set_frame_style(frame, aux.color.content.background, aux.color.content.border, left, right, top, bottom)
end

-- sunken: tables, inputs, the status bar
function M.set_well_style(frame, left, right, top, bottom)
    set_frame_style(frame, aux.color.input.background, aux.color.input.border, left, right, top, bottom)
end

-- A vertical gradient from clear at the top to black at the bottom, over a frame's fill, so a raised
-- thing (button, tab, column header) goes from its fill color at the top to darker at the bottom,
-- with a faint light line along its top edge. Drawn once; costs nothing per frame.
local function set_gradient(texture, bottom_alpha)
    texture:SetTexture(WHITE)
    texture:SetVertexColor(1, 1, 1, 1)
    -- the modern call takes color objects, older clients took numbers; unknown which Forever has,
    -- so each is tried and a plain half dark shade is the last resort
    if texture.SetGradient and CreateColor
        and pcall(texture.SetGradient, texture, 'VERTICAL', CreateColor(0, 0, 0, bottom_alpha), CreateColor(0, 0, 0, 0)) then
        return
    end
    if texture.SetGradientAlpha and pcall(texture.SetGradientAlpha, texture, 'VERTICAL', 0, 0, 0, bottom_alpha, 0, 0, 0, 0) then
        return
    end
    texture:SetVertexColor(0, 0, 0, bottom_alpha / 2)
end
M.set_gradient = set_gradient

function M.add_sheen(frame, strength)
    if frame.aux_sheen then return frame.aux_sheen end
    local shade = frame:CreateTexture(nil, 'BACKGROUND', nil, -7)
    shade:SetPoint('TOPLEFT', 1, -1)
    shade:SetPoint('BOTTOMRIGHT', -1, 1)
    set_gradient(shade, strength or .33)
    local line = frame:CreateTexture(nil, 'BACKGROUND', nil, -7)
    line:SetTexture(WHITE)
    line:SetVertexColor(1, 1, 1, .09)
    line:SetPoint('TOPLEFT', 1, -1)
    line:SetPoint('TOPRIGHT', -1, -1)
    line:SetHeight(1)
    local sheen = {shade = shade, line = line}
    function sheen:SetShown(shown)
        if shown then shade:Show(); line:Show() else shade:Hide(); line:Hide() end
    end
    frame.aux_sheen = sheen
    return sheen
end

-- A highlight shown while the mouse is over the frame
function M.add_highlight(frame, radius, r, g, b, a)
    local shape = create_shape(frame, 'HIGHLIGHT', 0, 'fill', 0)
    shape:SetColor(r or 1, g or 1, b or 1, a or .07)
    return shape
end

-- A table row's selection: gold 13% with a 2px gold bar at its left edge. Mouse over a row shows
-- the lighter hover (row_hover) instead.
function M.row_selection(row)
    local fill = row:CreateTexture(nil, 'BACKGROUND', nil, 2)
    fill:SetAllPoints()
    fill:SetColorTexture(aux.color.selected())
    local bar = row:CreateTexture(nil, 'BORDER')
    bar:SetPoint('TOPLEFT')
    bar:SetPoint('BOTTOMLEFT')
    bar:SetWidth(2)
    bar:SetColorTexture(aux.color.accent.background())
    local selection = {}
    function selection:Show() fill:Show(); bar:Show(); self.shown = true end
    function selection:Hide() fill:Hide(); bar:Hide(); self.shown = false end
    function selection:IsShown() return self.shown end
    selection:Hide()
    return selection
end

function M.row_hover(row)
    local hover = row:CreateTexture(nil, 'BACKGROUND', nil, 1)
    hover:SetAllPoints()
    hover:SetColorTexture(aux.color.hover())
    hover:Hide()
    return hover
end

-- auxForever: background opacity. The main window and the panels made by gui.panel are registered,
-- and only their fill fades: text, buttons, inputs and the buy bar stay solid. Never below 50%.
local backgrounds = {}
local background_opacity = 1
M.MIN_BACKGROUND_OPACITY = .5

local function paint_background(frame)
    local r, g, b, a = frame.aux_background_color()
    frame:SetBackdropColor(r, g, b, a * background_opacity)
end

function M.register_background(frame, color)
    frame.aux_background_color = color
    tinsert(backgrounds, frame)
    paint_background(frame)
end

function M.set_background_opacity(opacity)
    background_opacity = aux.bounded(MIN_BACKGROUND_OPACITY, 1, opacity or 1)
    for _, frame in ipairs(backgrounds) do
        paint_background(frame)
    end
    return background_opacity
end

function M.panel(parent)
    local panel = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    set_panel_style(panel)
    register_background(panel, aux.color.panel.background)
    return panel
end

function M.checkbutton(parent, text_height)
    local button = button(parent, text_height)
    button.state = false
    function button:SetChecked(state)
        self.state = state and true or false
        style_choice(self, self.state)
    end
    function button:GetChecked()
        return self.state
    end
    button:SetChecked(false)
    return button
end

-- auxForever (0.6, the UI Kit): a button has a look, kept in button.aux_look and drawn by
-- apply_look; Enable and Disable redraw it.
--   default   raised gray, gold label
--   primary   the main action of a view: warm raised, gold outline, gold label
--   selected  a selected tab or a toggle that is on: warm raised, gold outline, white label
--   choice    one option of a row of choices (12h / 24h / 48h): sunken, gray label
--   choice_on the chosen option: dark gold, gold outline at 55%, gold label
--   tab       a tab that is not selected: raised gray, label in white at 70%
-- A disabled button is flat dark gray with a gray label, whatever its look.
local LOOKS = {
    default = {fill = {42, 42, 42, 1}, border = {0, 0, 0, 1}, text = {229, 190, 91, 1}, sheen = true},
    primary = {fill = {46, 39, 22, 1}, border = {229, 190, 91, 1}, text = {229, 190, 91, 1}, sheen = true},
    selected = {fill = {46, 39, 22, 1}, border = {229, 190, 91, 1}, text = {255, 255, 255, 1}, sheen = true},
    choice = {fill = {10, 10, 10, 1}, border = {0, 0, 0, 1}, text = {138, 138, 138, 1}},
    choice_on = {fill = {42, 35, 18, 1}, border = {229, 190, 91, .55}, text = {229, 190, 91, 1}},
    tab = {fill = {42, 42, 42, 1}, border = {0, 0, 0, 1}, text = {235, 235, 235, .7}, sheen = true},
    -- the buy bar's Confirm: green, money is about to be spent at the price shown
    confirm = {fill = {22, 44, 28, 1}, border = {77, 204, 102, 1}, text = {77, 204, 102, 1}, sheen = true},
    -- an option in an open dropdown menu
    menu = {fill = {14, 14, 14, 1}, border = {0, 0, 0, 0}, text = {235, 235, 235, 1}},
}
local DISABLED_LOOK = {fill = {26, 26, 26, 1}, text = {107, 107, 107, 1}}
M.LOOKS = LOOKS

local function rgb(c) return c[1] / 255, c[2] / 255, c[3] / 255, c[4] end

-- force_enabled draws the enabled look on a disabled button (the selected tab)
function M.apply_look(btn, look, force_enabled)
    look = look or btn.aux_look or 'default'
    btn.aux_look = look
    local style = LOOKS[look] or LOOKS.default
    local enabled = force_enabled or btn:IsEnabled()
    local fill = enabled and style.fill or DISABLED_LOOK.fill
    btn:SetBackdropColor(rgb(fill))
    if look == 'primary' and not enabled then
        btn:SetBackdropBorderColor(74 / 255, 64 / 255, 38 / 255, 1)
    else
        btn:SetBackdropBorderColor(rgb(style.border))
    end
    if btn.aux_sheen then
        btn.aux_sheen:SetShown(enabled and style.sheen)
    end
    local label = btn:GetFontString()
    if label then
        label:SetTextColor(rgb(enabled and style.text or DISABLED_LOOK.text))
    end
end

function M.button(parent, text_height)
    text_height = text_height or font_size.medium
    local button = CreateFrame('Button', nil, parent, 'BackdropTemplate')
    set_size(button, 80, 24)
    set_content_style(button)
    add_sheen(button)
    button.highlight = add_highlight(button)

    local label = button:CreateFontString()
    label:SetFont(font, text_height)
    label:SetAllPoints(button)
    label:SetJustifyH('CENTER')
    label:SetJustifyV('MIDDLE')
    button:SetFontString(label)

    -- redrawn only when the state changes: some callers run ten times a second
    button.default_Enable = button.Enable
    function button:Enable()
        if self.aux_enabled == true then return end
        self.aux_enabled = true
        self:default_Enable()
        apply_look(self)
    end
    button.default_Disable = button.Disable
    function button:Disable()
        if self.aux_enabled == false then return end
        self.aux_enabled = false
        self:default_Disable()
        apply_look(self)
    end
    button.aux_enabled = true

    button.label = label
    apply_look(button, 'default')
    return button
end

function M.set_default(btn)
    apply_look(btn, 'default')
end

-- one option of a row of choice buttons (2h / 8h / 24h, Fast / Full): the chosen one is lit
function M.style_choice(btn, selected)
    apply_look(btn, selected and 'choice_on' or 'choice')
end

-- a selected tab, or a toggle that is on (Sound, Live); off is the default look
function M.set_selected(btn, selected)
    apply_look(btn, selected and 'selected' or 'default')
end

-- auxForever: the main action of a view (Search, Post, Buy): gold outline and label
function M.set_primary(button)
    apply_look(button, 'primary')
    local label = button:GetFontString()
    local _, size = label:GetFont()
    label:SetFont(font_bold, size and size > 0 and size or font_size.large)
end

do
    local mt = {__index={}}
    function mt.__index:create_tab(text)
        local id = #self._tabs + 1

        -- auxForever (0.6): every tab is a raised button, 1px apart; the selected one has the gold
        -- outline and a white label
        local tab = CreateFrame('Button', unique_name(), self._frame, 'BackdropTemplate')
        tab.id = id
        tab.group = self
        tab:SetHeight(26)
        set_content_style(tab)
        add_sheen(tab)
        tab.highlight = add_highlight(tab)

        tab.text = tab:CreateFontString()
        tab.text:SetAllPoints()
        tab.text:SetJustifyH('CENTER')
        tab.text:SetJustifyV('MIDDLE')
        tab.text:SetFont(font, font_size.medium)
        tab:SetFontString(tab.text)

        tab:SetText(text)

        tab:SetScript('OnClick', function(self)
            if self.id ~= self.group.selected then
                PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
                self.group:select(self.id)
            end
        end)

        if #self._tabs == 0 then
            tab:SetPoint('LEFT', self._anchor, 'RIGHT', 14, 0)
        else
            tab:SetPoint('LEFT', self._tabs[#self._tabs], 'RIGHT', 1, 0)
        end

        tab:SetWidth(tab:GetFontString():GetStringWidth() + 28)

        tinsert(self._tabs, tab)
    end
    function mt.__index:select(id)
        self._selected = id
        self:update()
        do (self._on_select or pass)(id) end
    end
    function mt.__index:update()
        for _, tab in pairs(self._tabs) do
            local selected = tab.group._selected == tab.id
            -- the look first: Enable and Disable redraw it
            tab.aux_look = selected and 'selected' or 'tab'
            if selected then tab:Disable() else tab:Enable() end
            -- a selected tab is disabled (it cannot be clicked again) but keeps its lit look
            apply_look(tab, nil, true)
        end
    end
    function M.tabs(parent, orientation, anchor)
        local self = {
            _frame = parent,
            _orientation = orientation,
            _anchor = anchor,
            _tabs = {},
        }
        return setmetatable(self, mt)
    end
end

function M.editbox(parent)
    local editbox = CreateFrame('EditBox', nil, parent, 'BackdropTemplate')
    editbox:SetAutoFocus(false)
    editbox:SetTextInsets(1.5, 1.5, 3, 3)
    editbox:SetHeight(24)
    editbox:SetTextColor(0, 0, 0, 0)
    set_frame_style(editbox, aux.color.input.background, aux.color.input.border)
    -- auxForever (0.6): a border set while not typing (red for a bad value, gold for the buy bar's
    -- own quantity) is remembered and comes back when typing ends; while typing it is gold
    local set_border = editbox.SetBackdropBorderColor
    editbox.aux_rest_border = {aux.color.input.border()}
    function editbox:SetBackdropBorderColor(r, g, b, a)
        if not self.focused then
            self.aux_rest_border = {r, g, b, a}
            set_border(self, r, g, b, a)
        end
    end
    editbox:SetScript('OnEscapePressed', function(self)
        self:ClearFocus()
        do (self.escape or pass)(self) end
    end)
    editbox:SetScript('OnEnterPressed', function(self)
        (self.enter or pass)(self)
    end)
    editbox:SetScript('OnEditFocusGained', function(self)
        if self.block_focus then
            self.block_focus = false
            self:ClearFocus()
            return
        end
        self.overlay:Hide()
        self:SetTextColor(1, 1, 1)
        -- auxForever (0.6): a gold outline while typing
        self.focused = true
        set_border(self, 229 / 255, 190 / 255, 91 / 255, .6)
        self:HighlightText()
        do (self.focus_gain or pass)(self) end
    end)
    editbox:SetScript('OnEditFocusLost', function(self)
        self.overlay:Show()
        self:SetTextColor(0, 0, 0, 0)
        self.focused = false
        set_border(self, unpack(self.aux_rest_border))
        self:HighlightText(0, 0)
        self:SetScript('OnUpdate', nil)
        do (self.focus_loss or pass)(self) end
    end)
    editbox:SetScript('OnTextChanged', function(self, is_user_input)
        do (self.change or pass)(self, is_user_input) end
        self.overlay:SetText(self.formatter and self.formatter(self:GetText()) or self:GetText())
    end)
    editbox:SetScript('OnChar', function(self) (self.char or pass)(self) end)
    do
        local last_click = { t = 0 }
        editbox:SetScript('OnMouseDown', function(self, button)
            if button == 'RightButton' then
                self:SetText(self.reset_text or '')
                do (self.change or pass)(self, true) end
                self:ClearFocus()
                self.block_focus = true
            else
                local x, y = GetCursorPosition()
                -- local offset = x - editbox:GetLeft()*editbox:GetEffectiveScale() TODO use a fontstring to measure getstringwidth for structural highlighting
                -- or use an overlay with itemlinks
                if GetTime() - last_click.t < .5 and x == last_click.x and y == last_click.y then
                    aux.coro_thread(function()
                        aux.coro_wait()
                        editbox:HighlightText()
                    end)
                end
                aux.wipe(last_click)
                last_click.t = GetTime()
                last_click.x = x
                last_click.y = y
            end
        end)
    end
    function editbox:SetAlignment(alignment)
        self:SetJustifyH(alignment)
        self.overlay:SetJustifyH(alignment)
    end
    function editbox:SetFontSize(size)
        self:SetFont(font, size, '')
        self.overlay:SetFont(font, size, '')
    end
    local overlay = label(editbox)
    overlay:SetPoint('LEFT', 1.5, 0)
    overlay:SetPoint('RIGHT', -1.5, 0)
    overlay:SetTextColor(1, 1, 1)
    editbox.overlay = overlay
    editbox:SetAlignment('LEFT')
    editbox:SetFontSize(font_size.medium)
    return editbox
end

do
    local function C_TRACK() return 9 / 255, 9 / 255, 9 / 255, 1 end

    local function update_alpha(self)
        self:SetAlpha(1 - (sin(GetTime() * 180) + 1) / 4)
    end

    function M.status_bar(parent)
        local self = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
        set_frame_style(self, C_TRACK, aux.color.input.border)
        do
            local status_bar = CreateFrame('StatusBar', nil, self, 'TextStatusBar')
            status_bar:SetOrientation('HORIZONTAL')
            status_bar:SetMinMaxValues(0, 1)
            status_bar:SetPoint('TOPLEFT', 2, -2)
            status_bar:SetPoint('BOTTOMRIGHT', -2, 2)
            status_bar:SetStatusBarTexture([[Interface\Buttons\WHITE8X8]])
            status_bar:SetStatusBarColor(.35, .28, .14, .6)
            self.secondary_status_bar = status_bar
        end
        do
            local status_bar = CreateFrame('StatusBar', nil, self.secondary_status_bar, 'TextStatusBar')
            status_bar:SetOrientation('HORIZONTAL')
            status_bar:SetMinMaxValues(0, 1)
            status_bar:SetAllPoints()
            status_bar:SetStatusBarTexture([[Interface\Buttons\WHITE8X8]])
            status_bar:SetStatusBarColor(.59, .47, .24, 1)
            self.primary_status_bar = status_bar
            -- darker toward the bottom, like the raised buttons
            local shade = status_bar:CreateTexture(nil, 'ARTWORK')
            shade:SetAllPoints(status_bar:GetStatusBarTexture())
            set_gradient(shade, .3)
            self.shade = shade
        end
        -- auxForever (0.6, the UI Kit): a sunken track; amber while loading, dark gold with a gold
        -- outline when a search has finished (set_done), a faint fill otherwise.
        local function paint(self)
            if self.loading then
                self.primary_status_bar:SetStatusBarColor(.59, .47, .24, 1)
                self.shade:Show()
                self:SetBackdropBorderColor(aux.color.input.border())
            elseif self.done then
                self.primary_status_bar:SetStatusBarColor(aux.color.accent.selected())
                self.shade:Hide()
                self:SetBackdropBorderColor(aux.color.accent.background())
            else
                self.primary_status_bar:SetStatusBarColor(1, 1, 1, .06)
                self.shade:Hide()
                self:SetBackdropBorderColor(aux.color.input.border())
            end
        end
        -- auxForever (0.5): a short text in the bar, e.g. what a Full scan is doing
        local text = self.primary_status_bar:CreateFontString(nil, 'OVERLAY')
        text:SetFont(font, font_size.small, '')
        text:SetPoint('LEFT', 8, 0)
        text:SetPoint('RIGHT', -8, 0)
        text:SetJustifyH('CENTER')
        text:SetTextColor(1, 1, 1)
        self.text = text
        function self:set_text(value)
            if value ~= self.shown_text then
                self.shown_text = value
                text:SetText(value or '')
            end
        end
        function self:set_done(done)
            self.done = done and true or false
            paint(self)
        end
        function self:update_status(primary_status, secondary_status)
            self.loading = min(primary_status or 0, secondary_status or 0) < 1
            if self.loading then
                self:SetScript('OnUpdate', update_alpha)
            else
                self:SetScript('OnUpdate', nil)
                self:SetAlpha(1)
            end
            paint(self)
            if primary_status then
                self.primary_status_bar:SetValue(primary_status)
            end
            if secondary_status then
                self.secondary_status_bar:SetValue(secondary_status)
            end
        end
        return self
    end
end

function M.item(parent)
    local item = CreateFrame('Frame', nil, parent)
    set_size(item, 260, 40)
    local btn = CreateFrame('CheckButton', unique_name(), item, 'ActionButtonTemplate')
    item.button = btn
    btn:SetPoint('LEFT', 2, .5)
    btn:ClearHighlightTexture()
    btn:RegisterForClicks()
    item.texture = _G[btn:GetName() .. 'Icon']
    item.texture:SetTexCoord(.06, .94, .06, .94)
    item.name = label(btn, font_size.medium)
    item.name:SetJustifyH('LEFT')
    item.name:SetPoint('LEFT', btn, 'RIGHT', 10, 0)
    item.name:SetPoint('RIGHT', item, 'RIGHT', -10, .5)
    item.count = _G[btn:GetName() .. 'Count']
    item.count:SetTextHeight(17)
    return item
end

function M.label(parent, size)
    local label = parent:CreateFontString()
    label:SetFont(font, size or font_size.small)
    label:SetTextColor(aux.color.label.enabled())
    label:SetWordWrap(false)
    return label
end

function M.horizontal_line(parent, y_offset, inverted_color)
    local texture = parent:CreateTexture()
    texture:SetPoint('TOPLEFT', parent, 'TOPLEFT', 2, y_offset)
    texture:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', -2, y_offset)
    texture:SetHeight(1)
    -- auxForever (0.6): edges are black
    texture:SetColorTexture(aux.color.window.border())
    return texture
end

function M.vertical_line(parent, x_offset, top_offset, bottom_offset, inverted_color)
    local texture = parent:CreateTexture()
    texture:SetPoint('TOPLEFT', parent, 'TOPLEFT', x_offset, top_offset or -2)
    texture:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', x_offset, bottom_offset or 2)
    texture:SetWidth(1)
    texture:SetColorTexture(aux.color.window.border())
    return texture
end

do
    local dropdown_frame = panel()
    dropdown_frame:SetFrameStrata('FULLSCREEN_DIALOG')
    dropdown_frame:SetHeight(1)
    local dropdown_item_buttons = {}
    M.dropdown_menu, M.dropdown_items = dropdown_frame, dropdown_item_buttons
    -- auxForever: the modern client takes focus from an edit box on any mouse press, so clicking an
    -- option takes focus from the dropdown before the option gets the click. The menu stays open
    -- while the mouse is over it and closes once neither the dropdown nor the menu is in use.
    dropdown_frame:SetScript('OnUpdate', function(self)
        if not (self.owner and self.owner:HasFocus()) and not self:IsMouseOver() then
            self:Hide()
        end
    end)

    function M.dropdown(parent, text_height)
        text_height = text_height or font_size.medium

        local index, set_index, update_dropdown
        local options = {}
        local color_table = {}

        local editbox = editbox(parent)

        editbox.complete = completion.complete(function() return options end)

        function editbox:char()
            self:complete()
            for i, choice in pairs(options) do
                if editbox:GetText() == choice then
                    set_index(i)
                end
            end
        end

        function set_index(new_index)
            if new_index then
                local color = color_table[new_index]
                new_index = max(1, min(#options, new_index))
                if editbox:GetText() ~= options[new_index] then
                    editbox:SetText(options[new_index])
                end
                if color then
                    editbox.overlay:SetTextColor(color.r, color.g, color.b)
                else
                    editbox.overlay:SetTextColor(aux.color.text.enabled())
                end
            else
                editbox:SetText('')
            end
            if new_index ~= index then
                index = new_index
                do (editbox.selection_change or pass)() end
            end
        end

        local function update_dropdown()
            if #options == 0 then
                dropdown_frame:Hide()
                return
            end

            dropdown_frame.owner = editbox
            dropdown_frame:SetScale(editbox:GetEffectiveScale())
            dropdown_frame:ClearAllPoints()
            local width = editbox:GetWidth() + 4
            dropdown_frame:SetWidth(width)
            dropdown_frame:SetPoint('TOP', editbox, 'BOTTOM', 0, 0)
            for i = 1, max(#options, #dropdown_item_buttons) do
                local color = color_table[i]
                local item_button = dropdown_item_buttons[i]
                if not item_button then
                    item_button = button(dropdown_frame, text_height)
                    apply_look(item_button, 'menu')
                    item_button.label:SetJustifyH('LEFT')
                    dropdown_item_buttons[i] = item_button
                else
                    item_button.label:SetFont(font, text_height)
                end
                if i > #options then
                    item_button:Hide()
                else
                    item_button:ClearAllPoints()
                    item_button:SetWidth(width - 4)
                    item_button:SetText(' ' .. options[i])
                    if color then
                        item_button.label:SetTextColor(color.r, color.g, color.b)
                    else
                        item_button.label:SetTextColor(aux.color.text.enabled())
                    end
                    if i == 1 then
                        item_button:SetPoint('TOP', editbox, 'BOTTOM', 0, -2)
                    else
                        item_button:SetPoint('TOP', dropdown_item_buttons[i - 1], 'BOTTOM', 0, -2)
                    end
                    item_button:SetScript('OnMouseDown', function()
                        set_index(i)
                        editbox:ClearFocus()
                        dropdown_frame:Hide()
                    end)
                    if index == i then
                        item_button:LockHighlight()
                    else
                        item_button:UnlockHighlight()
                    end
                    item_button:Show()
                end
                if i == #options then
                    dropdown_frame:SetPoint('BOTTOM', item_button, 'BOTTOM', 0, -2)
                end
                dropdown_frame:Show()
            end
        end

        local function set_color_table(new_color_table)
            --[[
            Example:
                table = {
                    [1] = {r=1,g=1,b=1},
                    ...
                    [n] = {r=1,g=1,b=1},
                }
            --]]
            color_table = new_color_table or {}
        end

        editbox.focus_gain = function()
            update_dropdown()
        end

        editbox.focus_loss = function()
            set_index(index)
            if not dropdown_frame:IsMouseOver() then
                dropdown_frame:Hide()
            end
        end

        function editbox:SetOptions(new_options, new_color_table)
            options = new_options
            set_color_table(new_color_table)
            set_index(nil)
            if editbox:HasFocus() then
                update_dropdown()
            end
        end

        function editbox:GetIndex()
            return index
        end

        function editbox:SetIndex(new_index)
            set_index(new_index)
        end

        return editbox
    end
end

function M.slider(parent)

    local slider = CreateFrame('Slider', nil, parent, 'BackdropTemplate')
    slider:SetOrientation('HORIZONTAL')
    slider:SetHeight(6)
    slider:SetHitRectInsets(0, 0, -12, -12)
    slider:SetStepsPerPage(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(0)

    set_well_style(slider)
    local thumb_texture = slider:CreateTexture(nil, 'ARTWORK')
    thumb_texture:SetPoint('CENTER', 0, 0)
    thumb_texture:SetColorTexture(aux.color.accent.background())
    thumb_texture:SetHeight(18)
    thumb_texture:SetWidth(8)
    set_size(thumb_texture, 8, 18)
    slider:SetThumbTexture(thumb_texture)

    local label = slider:CreateFontString(nil, 'OVERLAY')
    label:SetPoint('BOTTOMLEFT', slider, 'TOPLEFT', -3, 8)
    label:SetPoint('BOTTOMRIGHT', slider, 'TOPRIGHT', 6, 8)
    label:SetJustifyH('LEFT')
    label:SetHeight(13)
    label:SetFont(font, font_size.small)
    label:SetTextColor(aux.color.label.enabled())

    local editbox = editbox(slider)
    editbox:SetPoint('LEFT', slider, 'RIGHT', 5, 0)
    set_size(editbox, 45, 18)
    editbox:SetAlignment('CENTER')
    editbox:SetFontSize(17)

    slider.label = label
    slider.editbox = editbox
    return slider
end

function M.checkbox(parent)
    local checkbox = CreateFrame('CheckButton', nil, parent, 'UICheckButtonTemplate,BackdropTemplate')
    checkbox:SetWidth(16)
    checkbox:SetHeight(16)
    set_well_style(checkbox)
    checkbox:ClearNormalTexture()
    checkbox:ClearPushedTexture()
    checkbox:GetHighlightTexture():SetAllPoints()
    checkbox:GetHighlightTexture():SetColorTexture(1, 1, 1, .08)
    checkbox:GetCheckedTexture():SetTexCoord(.12, .88, .12, .88)
    checkbox:GetHighlightTexture('BLEND')
    return checkbox
end

do
    local editbox = CreateFrame('EditBox')
    editbox:SetAutoFocus(false)
    function M.clear_focus()
        editbox:SetFocus()
        editbox:ClearFocus()
    end
end

function M.percentage_historical(pct, bid)
    local text = (pct > 10000 and '>10000' or pct) .. '%'
    if bid then
        return aux.color.gray(text)
    elseif pct < 50 then
        return aux.color.blue(text)
    elseif pct < 80 then
        return aux.color.green(text)
    elseif pct < 110 then
        return aux.color.yellow(text)
    elseif pct < 135 then
        return aux.color.orange(text)
    else
        return aux.color.red(text)
    end
end
