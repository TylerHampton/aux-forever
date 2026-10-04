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

-- auxForever: rounded corners. A frame gets a fill and an outline, each made of four corner pieces
-- and straight pieces between them. The frame's SetBackdropColor and SetBackdropBorderColor are
-- replaced so every existing caller recolors the rounded shape instead of a square backdrop.
local CORNER_FILL = [[Interface\AddOns\auxForever\textures\corner-fill.tga]]
local CORNER_LINE = [[Interface\AddOns\auxForever\textures\corner-line.tga]]
local WHITE = [[Interface\Buttons\WHITE8X8]]
-- texture coordinates that turn the top left corner texture into each corner
local CORNERS = {
    {'TOPLEFT', 0, 1, 0, 1},
    {'TOPRIGHT', 1, 0, 0, 1},
    {'BOTTOMLEFT', 0, 1, 1, 0},
    {'BOTTOMRIGHT', 1, 0, 1, 0},
}

local function shape_texture(frame, layer, sublevel, file)
    local texture = frame:CreateTexture(nil, layer, nil, sublevel)
    texture:SetTexture(file)
    return texture
end

-- left, right, top, bottom are insets like a backdrop's (negative values grow the shape)
local function create_shape(frame, layer, sublevel, kind, radius, left, right, top, bottom)
    left, right, top, bottom = left or 0, right or 0, top or 0, bottom or 0
    local inset = {TOPLEFT = {left, -top}, TOPRIGHT = {-right, -top}, BOTTOMLEFT = {left, bottom}, BOTTOMRIGHT = {-right, bottom}}
    local pieces = {}
    local corners = {}
    for _, c in ipairs(CORNERS) do
        local point, x = c[1], inset[c[1]]
        local t = shape_texture(frame, layer, sublevel, kind == 'fill' and CORNER_FILL or CORNER_LINE)
        t:SetSize(radius, radius)
        t:SetPoint(point, x[1], x[2])
        t:SetTexCoord(c[2], c[3], c[4], c[5])
        corners[point] = t
        tinsert(pieces, t)
    end
    local function rect(a1, r1, p1, a2, r2, p2)
        local t = shape_texture(frame, layer, sublevel, WHITE)
        t:SetPoint(a1, r1, p1)
        t:SetPoint(a2, r2, p2)
        tinsert(pieces, t)
        return t
    end
    if kind == 'fill' then
        rect('TOPLEFT', corners.TOPLEFT, 'TOPRIGHT', 'BOTTOMRIGHT', corners.BOTTOMRIGHT, 'BOTTOMLEFT')
        rect('TOPLEFT', corners.TOPLEFT, 'BOTTOMLEFT', 'BOTTOMRIGHT', corners.BOTTOMLEFT, 'TOPRIGHT')
        rect('TOPLEFT', corners.TOPRIGHT, 'BOTTOMLEFT', 'BOTTOMRIGHT', corners.BOTTOMRIGHT, 'TOPRIGHT')
    else
        -- the straight edges are as thick as the outline in the corner texture
        local width = radius / 4
        rect('TOPLEFT', corners.TOPLEFT, 'TOPRIGHT', 'TOPRIGHT', corners.TOPRIGHT, 'TOPLEFT'):SetHeight(width)
        rect('BOTTOMLEFT', corners.BOTTOMLEFT, 'BOTTOMRIGHT', 'BOTTOMRIGHT', corners.BOTTOMRIGHT, 'BOTTOMLEFT'):SetHeight(width)
        rect('TOPLEFT', corners.TOPLEFT, 'BOTTOMLEFT', 'BOTTOMLEFT', corners.BOTTOMLEFT, 'TOPLEFT'):SetWidth(width)
        rect('TOPRIGHT', corners.TOPRIGHT, 'BOTTOMRIGHT', 'BOTTOMRIGHT', corners.BOTTOMRIGHT, 'TOPRIGHT'):SetWidth(width)
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

function M.set_frame_style(frame, backdrop_color, border_color, left, right, top, bottom, radius)
    radius = radius or frame.aux_radius or 5
    if not frame.aux_fill then
        if frame.SetBackdrop then frame:SetBackdrop(nil) end
        frame.aux_fill = create_shape(frame, 'BACKGROUND', -8, 'fill', radius, left, right, top, bottom)
        frame.aux_border = create_shape(frame, 'BACKGROUND', -7, 'line', radius, left, right, top, bottom)
        frame.SetBackdropColor = shape_SetBackdropColor
        frame.SetBackdropBorderColor = shape_SetBackdropBorderColor
    end
    frame:SetBackdropColor(backdrop_color())
    frame:SetBackdropBorderColor(border_color())
end

function M.set_window_style(frame, left, right, top, bottom)
    set_frame_style(frame, aux.color.window.background, aux.color.window.border, left, right, top, bottom, frame.aux_radius or 8)
end

function M.set_panel_style(frame, left, right, top, bottom)
    set_frame_style(frame, aux.color.panel.background, aux.color.panel.border, left, right, top, bottom, frame.aux_radius or 6)
end

function M.set_content_style(frame, left, right, top, bottom)
    set_frame_style(frame, aux.color.content.background, aux.color.content.border, left, right, top, bottom)
end

-- A rounded highlight shown while the mouse is over the frame
function M.add_highlight(frame, radius, r, g, b, a)
    local shape = create_shape(frame, 'HIGHLIGHT', 0, 'fill', radius or frame.aux_radius or 5)
    shape:SetColor(r or 1, g or 1, b or 1, a or .08)
    return shape
end

function M.panel(parent)
    local panel = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    set_panel_style(panel)
    return panel
end

function M.checkbutton(parent, text_height)
    local button = button(parent, text_height)
    button.state = false
    button:SetBackdropColor(aux.color.state.disabled())
    function button:SetChecked(state)
        if state then
            self:SetBackdropColor(aux.color.state.enabled())
            self.state = true
        else
            self:SetBackdropColor(aux.color.state.disabled())
            self.state = false
        end
    end
    function button:GetChecked()
        return self.state
    end
    return button
end

function M.button(parent, text_height)
    text_height = text_height or font_size.large
    local button = CreateFrame('Button', nil, parent, 'BackdropTemplate')
    set_size(button, 80, 24)
    set_content_style(button)
    button.highlight = add_highlight(button)

    local label = button:CreateFontString()
    label:SetFont(font, text_height)
    label:SetAllPoints(button)
    label:SetJustifyH('CENTER')
    label:SetJustifyV('MIDDLE')
    label:SetTextColor(aux.color.text.enabled())
    button:SetFontString(label)

    button.default_Enable = button.Enable
    function button:Enable()
        if self:IsEnabled() == 1 then return end
        self:GetFontString():SetTextColor(aux.color.text.enabled())
        return self:default_Enable()
    end
    button.default_Disable = button.Disable
    function button:Disable()
        if self:IsEnabled() == 0 then return end
        self:GetFontString():SetTextColor(aux.color.text.disabled())
        return self:default_Disable()
    end

    button.label = label
    return button
end

-- auxForever: the main action of a view (Search), in the accent color
function M.set_primary(button)
    button:SetBackdropColor(aux.color.accent.background())
    button:SetBackdropBorderColor(aux.color.accent.background())
    button:GetFontString():SetTextColor(aux.color.accent.text())
    local label = button:GetFontString()
    local _, size = label:GetFont()
    label:SetFont(font_bold, size and size > 0 and size or font_size.large)
end

do
    local mt = {__index={}}
    function mt.__index:create_tab(text)
        local id = #self._tabs + 1

        local tab = CreateFrame('Button', unique_name(), self._frame, 'BackdropTemplate')
        tab.id = id
        tab.group = self
        tab:SetHeight(24)
        if self._orientation == 'BAR' then
            tab.aux_radius = 5
        end
        set_panel_style(tab)
        local dock = tab:CreateTexture(nil, 'OVERLAY')
        dock:SetHeight(3)
        if self._orientation == 'UP' then
            dock:SetPoint('BOTTOMLEFT', 1, -1)
            dock:SetPoint('BOTTOMRIGHT', -1, -1)
        elseif self._orientation == 'DOWN' then
            dock:SetPoint('TOPLEFT', 1, 1)
            dock:SetPoint('TOPRIGHT', -1, 1)
        end
        dock:SetColorTexture(aux.color.panel.background())
        tab.dock = dock
        tab.highlight = add_highlight(tab)

        tab.text = tab:CreateFontString()
        tab.text:SetAllPoints()
        tab.text:SetJustifyH('CENTER')
        tab.text:SetJustifyV('MIDDLE')
        tab.text:SetFont(font, font_size.large)
        tab:SetFontString(tab.text)

        tab:SetText(text)

        tab:SetScript('OnClick', function(self)
            if self.id ~= self.group.selected then
                PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
                self.group:select(self.id)
            end
        end)

        if self._orientation == 'BAR' then
            -- auxForever: tabs sit in the window's top bar, after the anchor (the logo)
            tab:SetHeight(26)
            tab.text:SetFont(font, font_size.medium)
            if #self._tabs == 0 then
                tab:SetPoint('LEFT', self._anchor, 'RIGHT', 16, 0)
            else
                tab:SetPoint('LEFT', self._tabs[#self._tabs], 'RIGHT', 4, 0)
            end
        elseif #self._tabs == 0 then
            if self._orientation == 'UP' then
                tab:SetPoint('BOTTOMLEFT', self._frame, 'TOPLEFT', 4, -1)
            elseif self._orientation == 'DOWN' then
                tab:SetPoint('TOPLEFT', self._frame, 'BOTTOMLEFT', 4, 1)
            end
        else
            if self._orientation == 'UP' then
                tab:SetPoint('BOTTOMLEFT', self._tabs[#self._tabs], 'BOTTOMRIGHT', 4, 0)
            elseif self._orientation == 'DOWN' then
                tab:SetPoint('TOPLEFT', self._tabs[#self._tabs], 'TOPRIGHT', 4, 0)
            end
        end

        tab:SetWidth(tab:GetFontString():GetStringWidth() + (self._orientation == 'BAR' and 26 or 14))

        tinsert(self._tabs, tab)
    end
    function mt.__index:select(id)
        self._selected = id
        self:update()
        do (self._on_select or pass)(id) end
    end
    function mt.__index:update()
        for _, tab in pairs(self._tabs) do
            if tab.group._orientation == 'BAR' then
                local selected = tab.group._selected == tab.id
                tab.dock:Hide()
                tab.text:SetTextColor((selected and aux.color.text.enabled or aux.color.label.enabled)())
                tab:SetBackdropColor(aux.color.content.background())
                tab:SetBackdropBorderColor(aux.color.content.background())
                tab.aux_fill:SetShown(selected)
                tab.aux_border:SetShown(selected)
                if selected then tab:Disable() else tab:Enable() end
            elseif tab.group._selected == tab.id then
                tab.text:SetTextColor(aux.color.label.enabled())
                tab:Disable()
                tab:SetBackdropColor(aux.color.panel.background())
                tab.dock:Show()
                tab:SetHeight(29)
            else
                tab.text:SetTextColor(aux.color.text.enabled())
                tab:Enable()
                tab:SetBackdropColor(aux.color.content.background())
                tab.dock:Hide()
                tab:SetHeight(24)
            end
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
        self:SetTextColor(aux.color.text.enabled())
        self.focused = true
        self:HighlightText()
        do (self.focus_gain or pass)(self) end
    end)
    editbox:SetScript('OnEditFocusLost', function(self)
        self.overlay:Show()
        self:SetTextColor(0, 0, 0, 0)
        self.focused = false
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
    overlay:SetTextColor(aux.color.text.enabled())
    editbox.overlay = overlay
    editbox:SetAlignment('LEFT')
    editbox:SetFontSize(font_size.medium)
    return editbox
end

do
    local function update_alpha(self)
        self:SetAlpha(1 - (sin(GetTime() * 180) + 1) / 4)
    end

    function M.status_bar(parent)
        local self = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
        self.aux_radius = 4
        set_window_style(self)
        do
            local status_bar = CreateFrame('StatusBar', nil, self, 'TextStatusBar')
            status_bar:SetOrientation('HORIZONTAL')
            status_bar:SetMinMaxValues(0, 1)
            status_bar:SetPoint('TOPLEFT', 1.5, -1.5)
            status_bar:SetPoint('BOTTOMRIGHT', -1.5, 1.5)
            status_bar:SetStatusBarTexture([[Interface\Buttons\WHITE8X8]])
            status_bar:SetStatusBarColor(.42, .42, .42, .7)
            self.secondary_status_bar = status_bar
        end
        do
            local status_bar = CreateFrame('StatusBar', nil, self.secondary_status_bar, 'TextStatusBar')
            status_bar:SetOrientation('HORIZONTAL')
            status_bar:SetMinMaxValues(0, 1)
            status_bar:SetAllPoints()
            status_bar:SetStatusBarTexture([[Interface\Buttons\WHITE8X8]])
            status_bar:SetStatusBarColor(.89, .64, .23, .55)
            self.primary_status_bar = status_bar
        end
        function self:update_status(primary_status, secondary_status)
            if min(primary_status or 0, secondary_status or 0) < 1 then
                self:SetScript('OnUpdate', update_alpha)
                self.primary_status_bar:SetStatusBarColor(.89, .64, .23, .55)
            else
                -- auxForever: dim gray when idle, amber only while something is loading
                self:SetScript('OnUpdate', nil)
                self:SetAlpha(1)
                self.primary_status_bar:SetStatusBarColor(.30, .32, .35, .6)
            end
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
    texture:SetHeight(2)
    if inverted_color then
        texture:SetColorTexture(aux.color.panel.background())
    else
        texture:SetColorTexture(aux.color.content.background())
    end
    return texture
end

function M.vertical_line(parent, x_offset, top_offset, bottom_offset, inverted_color)
    local texture = parent:CreateTexture()
    texture:SetPoint('TOPLEFT', parent, 'TOPLEFT', x_offset, top_offset or -2)
    texture:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', x_offset, bottom_offset or 2)
    texture:SetWidth(2)
    if inverted_color then
        texture:SetColorTexture(aux.color.panel.background())
    else
        texture:SetColorTexture(aux.color.content.background())
    end
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
    slider.aux_radius = 3
    slider:SetHitRectInsets(0, 0, -12, -12)
    slider:SetStepsPerPage(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(0)

    set_panel_style(slider)
    local thumb_texture = slider:CreateTexture(nil, 'ARTWORK')
    thumb_texture:SetPoint('CENTER', 0, 0)
    thumb_texture:SetColorTexture(aux.color.content.background())
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
    checkbox.aux_radius = 4
    set_content_style(checkbox)
    checkbox:ClearNormalTexture()
    checkbox:ClearPushedTexture()
    checkbox:GetHighlightTexture():SetAllPoints()
    checkbox:GetHighlightTexture():SetColorTexture(1, 1, 1, .2)
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
