select(2, ...) 'aux'

local gui = require 'aux.gui'
local scan = require 'aux.core.scan'
local post = require 'aux.tabs.post'
local search = require 'aux.tabs.search'
local info = require 'aux.util.info'

function event.AUX_LOADED()
	for _, v in ipairs(tab_info) do
		tabs:create_tab(v.name)
	end
	-- the saved position and size are in the window's own scale, so the scale comes first
	account_data.scale = clean_scale(account_data.scale)
	frame:SetScale(account_data.scale)
	restore_window()
	account_data.background_opacity = gui.set_background_opacity(account_data.background_opacity)
end

-- Forever: the window can be resized from its bottom right corner (double-click the corner for the
-- default size), and it remembers its size and position.
local DEFAULT_WIDTH, DEFAULT_HEIGHT = 1100, 660
local MIN_WIDTH, MIN_HEIGHT = 1000, 549
-- auxForever: the logo, tabs, full scan, Blizzard UI and close sit in a bar across the top
local TOP_BAR_HEIGHT = 40

local function max_size()
	local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
	return max(MIN_WIDTH, UIParent:GetWidth() / scale), max(MIN_HEIGHT, UIParent:GetHeight() / scale)
end

function save_window()
	local window = account_data.window
	window.width, window.height = frame:GetWidth(), frame:GetHeight()
	local point, _, relative_point, x, y = frame:GetPoint(1)
	window.point, window.relative_point, window.x, window.y = point, relative_point, x, y
end

-- the window keeps its top left corner where it is; sizing and scaling then grow it to the right
-- and down only. Sizing from the corner while it hung from another point (it starts out anchored
-- by its left edge) could make the window jump to full screen on a single click.
function M.anchor_top_left()
	local left, top = frame:GetLeft(), frame:GetTop()
	local point, relative, relative_point, x, y = frame:GetPoint(1)
	-- already there: leave it, so a click never moves the window by a rounding error
	if point == 'TOPLEFT' and relative == UIParent and relative_point == 'BOTTOMLEFT' and left and top
		and abs((x or 0) - left) < .5 and abs((y or 0) - top) < .5 then
		return
	end
	if left and top then
		frame:ClearAllPoints()
		frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', left, top)
	end
end

MIN_SCALE, MAX_SCALE = .7, 1.5

-- auxForever: window scale, 70% to 150% (the Scale setting and /aux scale)
function M.clean_scale(scale)
	return bounded(MIN_SCALE, MAX_SCALE, floor((tonumber(scale) or 1) * 20 + .5) / 20)
end

function M.set_window_scale(scale)
	scale = clean_scale(scale)
	anchor_top_left()
	local left, top = frame:GetLeft(), frame:GetTop()
	local old = frame:GetScale()
	frame:SetScale(scale)
	-- keep the top left corner in place on screen: anchor offsets are in the window's own scale
	if left and top and old and old > 0 then
		frame:ClearAllPoints()
		frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', left * old / scale, top * old / scale)
	end
	-- never bigger than the screen at the new scale
	local max_width, max_height = max_size()
	gui.set_size(frame, bounded(MIN_WIDTH, max_width, frame:GetWidth()), bounded(MIN_HEIGHT, max_height, frame:GetHeight()))
	save_window()
	return scale
end

function M.restore_window()
	local window = account_data.window
	local max_width, max_height = max_size()
	local width = bounded(MIN_WIDTH, max_width, window.width or DEFAULT_WIDTH)
	local height = bounded(MIN_HEIGHT, max_height, window.height or DEFAULT_HEIGHT)
	gui.set_size(frame, width, height)
	if window.point then
		frame:ClearAllPoints()
		frame:SetPoint(window.point, UIParent, window.relative_point, window.x, window.y)
	end
end

do
	local frame = CreateFrame('Frame', 'aux_frame', UIParent, 'BackdropTemplate')
	tinsert(UISpecialFrames, 'aux_frame')
	gui.set_window_style(frame)
	gui.register_background(frame, color.window.background)
	-- Forever: wider, and resizable (see restore_window)
	gui.set_size(frame, DEFAULT_WIDTH, DEFAULT_HEIGHT)
	frame:SetPoint('LEFT', 100, 0)
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	if frame.SetDontSavePosition then frame:SetDontSavePosition(true) end
	frame:EnableMouse(true)
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', frame.StartMoving)
    frame:SetScript('OnDragStop', function(self)
        self:StopMovingOrSizing()
        save_window()
    end)
	frame:SetClampedToScreen(true)
--	frame:CreateTitleRegion():SetAllPoints() TODO classic why
	frame:SetScript('OnShow', function() PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN) end)
	frame:SetScript('OnHide', function() PlaySound(SOUNDKIT.AUCTION_WINDOW_CLOSE); C_AuctionHouse.CloseAuctionHouse() end)
	-- everything under the top bar; each tab's frame fills it
	frame.body = CreateFrame('Frame', nil, frame)
	frame.body:SetPoint('TOPLEFT', 0, -TOP_BAR_HEIGHT)
	frame.body:SetPoint('BOTTOMRIGHT', 0, 0)
	frame.content = CreateFrame('Frame', nil, frame)
	frame.content:SetPoint('TOPLEFT', frame.body, 'TOPLEFT', 4, -80)
	frame.content:SetPoint('BOTTOMRIGHT', -4, 35)
	local divider = frame:CreateTexture(nil, 'BORDER')
	divider:SetColorTexture(color.panel.border())
	divider:SetHeight(1)
	divider:SetPoint('TOPLEFT', 2, -TOP_BAR_HEIGHT)
	divider:SetPoint('TOPRIGHT', -2, -TOP_BAR_HEIGHT)
	frame:Hide()
	M.frame = frame
end
do
    local status_bar = gui.status_bar(frame.content)
    status_bar:SetWidth(265)
    status_bar:SetHeight(27)
    status_bar:SetPoint('TOPLEFT', frame.content, 'BOTTOMLEFT', 0, -3)
    status_bar:update_status(1, 1)
    M.status_bar = status_bar
end
do
	local logo = gui.label(frame, 20)
	logo:SetFont(gui.font_bold, 20)
	logo:SetPoint('LEFT', frame, 'TOPLEFT', 14, -TOP_BAR_HEIGHT / 2)
	logo:SetText(color.accent.background'aux' .. color.text.enabled'Forever')
	logo_label = logo
end
do
	tabs = gui.tabs(frame, 'BAR', logo_label)
	tabs._on_select = on_tab_click
	function M.set_tab(id) tabs:select(id) end
end
do
	local grip = CreateFrame('Button', nil, frame)
	grip:SetPoint('BOTTOMRIGHT', -2, 2)
	gui.set_size(grip, 16, 16)
	grip:SetNormalTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]])
	grip:SetHighlightTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]])
	grip:SetPushedTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]])
	-- auxForever (0.4.1): aux sizes the window itself instead of the game's StartSizing. With
	-- StartSizing a single click on the corner could make the whole window jump diagonally, again
	-- with each click (Tyler; not reproduced here). Now the size follows the mouse only while it is
	-- dragged, measured from where the drag started, so a click that does not move changes nothing.
	-- The top left corner stays put and the window stays on screen. Runs only during a drag.
	local function cursor()
		local x, y = GetCursorPosition()
		local scale = frame:GetEffectiveScale()
		return x / scale, y / scale
	end
	local function stop_sizing()
		if grip:GetScript('OnUpdate') then
			grip:SetScript('OnUpdate', nil)
			save_window()
		end
	end
	grip:SetScript('OnMouseDown', function(_, button)
		if button ~= 'LeftButton' then return end
		anchor_top_left()
		local x0, y0 = cursor()
		local width0, height0 = frame:GetWidth(), frame:GetHeight()
		-- room up to the right and bottom edges of the screen, in the window's own scale
		local screen = UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
		local max_width = max(MIN_WIDTH, UIParent:GetWidth() * screen - (frame:GetLeft() or 0))
		local max_height = max(MIN_HEIGHT, frame:GetTop() or UIParent:GetHeight() * screen)
		local last_width, last_height = width0, height0
		grip:SetScript('OnUpdate', function()
			if not IsMouseButtonDown('LeftButton') then
				stop_sizing()
				return
			end
			local x, y = cursor()
			local width = floor(bounded(MIN_WIDTH, max_width, width0 + x - x0) + .5)
			local height = floor(bounded(MIN_HEIGHT, max_height, height0 + y0 - y) + .5)
			if width ~= last_width or height ~= last_height then
				last_width, last_height = width, height
				gui.set_size(frame, width, height)
			end
		end)
	end)
	grip:SetScript('OnMouseUp', stop_sizing)
	grip:SetScript('OnDoubleClick', function()
		stop_sizing()
		anchor_top_left()
		gui.set_size(frame, DEFAULT_WIDTH, DEFAULT_HEIGHT)
		save_window()
	end)
	grip:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOP')
		GameTooltip:AddLine('Drag to resize')
		GameTooltip:AddLine('Double-click for the default size', 1, 1, 1)
		GameTooltip:Show()
	end)
	grip:SetScript('OnLeave', function() GameTooltip:Hide() end)
	resize_grip = grip
end
do
	local btn = gui.button(frame, 22)
	btn:SetPoint('RIGHT', frame, 'TOPRIGHT', -8, -TOP_BAR_HEIGHT / 2)
	gui.set_size(btn, 28, 26)
	btn:SetText('\195\151')
	btn:SetBackdropColor(0, 0, 0, 0)
	btn:SetBackdropBorderColor(0, 0, 0, 0)
	btn:GetFontString():SetTextColor(color.label.enabled())
	btn:SetScript('OnClick', function() frame:Hide() end)
	btn:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_BOTTOM')
		GameTooltip:AddLine('Close')
		GameTooltip:Show()
	end)
	btn:SetScript('OnLeave', function() GameTooltip:Hide() end)
	close_button = btn
end
do
	local btn = gui.button(frame, gui.font_size.small)
	btn:SetPoint('RIGHT', close_button, 'LEFT' , -8, 0)
	gui.set_size(btn, 80, 26)
	btn:SetText(color.blizzard'Blizzard UI')
	btn:SetScript('OnClick',function()
		set_blizzard_frame_shown(not blizzard_frame_shown())
	end)
	btn:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_BOTTOM')
		GameTooltip:AddLine(blizzard_frame_shown() and 'Hide the Blizzard auction house' or 'Show the Blizzard auction house')
		GameTooltip:AddLine('It opens on top of aux. Click aux to bring aux back to the front.', 1, 1, 1, true)
		GameTooltip:Show()
	end)
	btn:SetScript('OnLeave', function() GameTooltip:Hide() end)
    blizzard_button = btn
    -- lit while the Blizzard window is shown, so its state is always visible
    function M.update_blizzard_button()
        if blizzard_frame_shown() then
            btn:SetBackdropColor(color.accent.selected())
            btn:SetBackdropBorderColor(color.blizzard())
        else
            btn:SetBackdropColor(color.content.background())
            btn:SetBackdropBorderColor(color.content.border())
        end
    end
end
do
    local btn = gui.button(frame)
    btn:SetPoint('RIGHT', blizzard_button, 'LEFT' , -6, 0)
    gui.set_size(btn, 80, 26)
    btn:SetText('Full scan')
    -- Forever: a full scan uses C_AuctionHouse.ReplicateItems, which the server allows once every 15 minutes
    local function seconds_until_scan()
        return max(0, account_data.replicate_time + scan.REPLICATE_COOLDOWN - time())
    end
    -- auxForever: checked twice a second and restyled only when ready changes (it was every frame)
    local ready, next_check
    btn:SetScript('OnUpdate', function(self)
        if GetTime() < (next_check or 0) then return end
        next_check = GetTime() + .5
        local now_ready = seconds_until_scan() == 0 and not scan.is_scanning()
        if now_ready == ready then return end
        ready = now_ready
        if ready then
            self:Enable()
            self:SetBackdropColor(color.state.enabled())
        else
            self:Disable()
            self:SetBackdropColor(color.content.background())
        end
    end)
    btn:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_TOP')
        GameTooltip:AddLine('Full scan')
        local seconds = seconds_until_scan()
        if seconds > 0 then
            GameTooltip:AddLine(format('Available again in %d:%02d', floor(seconds / 60), seconds % 60), 1, 1, 1)
        else
            GameTooltip:AddLine('Records prices of everything on the auction house.', 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    btn:SetScript('OnLeave', function() GameTooltip:Hide() end)
    btn:SetMotionScriptsWhileDisabled(true)
    btn:SetScript('OnClick', function()
        local count = 0
        scan.start{
            type = 'list',
            queries = {{blizzard_query = {}}},
            get_all = true,
            on_scan_start = function()
                status_bar:update_status(0, 0)
                post.clear_auctions()
                search.clear_selection()
            end,
            on_auction = function(auction_record, total)
                count = count + 1
                status_bar:update_status(count / total, 0)
                post.record_scanned_auction(auction_record)
            end,
            on_abort = function()
                status_bar:update_status(1, 1)
            end,
            on_complete = function()
                status_bar:update_status(1, 1)
                print('full scan complete: ' .. count .. ' auctions recorded')
            end,
        }
    end)
    scan_button = btn
end
do
    -- auxForever: settings (background opacity, scale, default duration), behind a gear in the top bar
    local btn = gui.button(frame)
    btn:SetPoint('RIGHT', scan_button, 'LEFT', -6, 0)
    gui.set_size(btn, 28, 26)
    local icon = btn:CreateTexture(nil, 'ARTWORK')
    icon:SetTexture([[Interface\AddOns\auxForever\textures\gear.tga]])
    icon:SetSize(15, 15)
    icon:SetPoint('CENTER')
    icon:SetVertexColor(color.label.enabled())
    btn:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_BOTTOM')
        GameTooltip:AddLine('Settings')
        GameTooltip:Show()
    end)
    btn:SetScript('OnLeave', function() GameTooltip:Hide() end)
    settings_button = btn

    local popup = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
    gui.set_frame_style(popup, color.content.background, color.input.border, nil, nil, nil, nil, 8)
    popup:SetFrameStrata('DIALOG')
    gui.set_size(popup, 250, 138)
    popup:SetPoint('TOPRIGHT', btn, 'BOTTOMRIGHT', 0, -4)
    popup:EnableMouse(true)
    popup:Hide()
    settings_popup = popup

    local title = gui.label(popup, gui.font_size.small)
    title:SetPoint('TOPLEFT', 12, -10)
    title:SetText('SETTINGS')
    title:SetTextColor(color.accent.background())

    local function row_label(text, y)
        local label = gui.label(popup, gui.font_size.medium)
        label:SetPoint('TOPLEFT', 12, y)
        label:SetText(text)
        label:SetTextColor(color.text.enabled())
        return label
    end

    -- a value with - and + at the right of a row
    local function stepper(y)
        local plus = gui.button(popup, gui.font_size.large)
        gui.set_size(plus, 26, 24)
        plus:SetPoint('TOPRIGHT', -10, y + 5)
        plus:SetText('+')
        local value = gui.label(popup, gui.font_size.medium)
        value:SetWidth(46)
        value:SetJustifyH('CENTER')
        value:SetPoint('RIGHT', plus, 'LEFT', -2, 0)
        value:SetTextColor(color.text.enabled())
        local minus = gui.button(popup, gui.font_size.large)
        gui.set_size(minus, 26, 24)
        minus:SetPoint('RIGHT', value, 'LEFT', -2, 0)
        minus:SetText('-')
        return minus, value, plus
    end

    local function percent(x) return floor(x * 100 + .5) .. '%' end

    row_label('Background', -40)
    local opacity_minus, opacity_value, opacity_plus = stepper(-40)
    row_label('Scale', -72)
    local scale_minus, scale_value, scale_plus = stepper(-72)
    row_label('Default duration', -104)
    local length_buttons = {}
    for i = 3, 1, -1 do
        local b = gui.button(popup, gui.font_size.small)
        gui.set_size(b, 38, 24)
        if i == 3 then
            b:SetPoint('TOPRIGHT', -10, -99)
        else
            b:SetPoint('RIGHT', length_buttons[i + 1], 'LEFT', -3, 0)
        end
        length_buttons[i] = b
    end
    M.auction_length_buttons = length_buttons
    M.scale_buttons = {scale_minus, scale_plus}
    M.scale_value = scale_value

    local function refresh()
        local opacity = account_data.background_opacity
        opacity_value:SetText(percent(opacity))
        if opacity > gui.MIN_BACKGROUND_OPACITY + .001 then opacity_minus:Enable() else opacity_minus:Disable() end
        if opacity < .999 then opacity_plus:Enable() else opacity_plus:Disable() end
        local scale = account_data.scale or 1
        scale_value:SetText(percent(scale))
        if scale > MIN_SCALE + .001 then scale_minus:Enable() else scale_minus:Disable() end
        if scale < MAX_SCALE - .001 then scale_plus:Enable() else scale_plus:Disable() end
        for i, b in ipairs(length_buttons) do
            b:SetText(info.duration_hours(i) .. 'h')
            gui.style_choice(b, account_data.post_duration == i)
        end
    end
    function M.set_background_opacity(opacity)
        account_data.background_opacity = gui.set_background_opacity(opacity)
        refresh()
    end
    function M.change_window_scale(scale)
        account_data.scale = set_window_scale(scale)
        refresh()
    end
    opacity_minus:SetScript('OnClick', function() set_background_opacity(account_data.background_opacity - .05) end)
    opacity_plus:SetScript('OnClick', function() set_background_opacity(account_data.background_opacity + .05) end)
    scale_minus:SetScript('OnClick', function() change_window_scale((account_data.scale or 1) - .05) end)
    scale_plus:SetScript('OnClick', function() change_window_scale((account_data.scale or 1) + .05) end)
    for i, b in ipairs(length_buttons) do
        b:SetScript('OnClick', function()
            account_data.post_duration = i
            refresh()
        end)
    end

    popup:SetScript('OnShow', function()
        refresh()
        btn:SetBackdropColor(color.accent.selected())
        btn:SetBackdropBorderColor(color.accent.background())
    end)
    popup:SetScript('OnHide', function()
        btn:SetBackdropColor(color.content.background())
        btn:SetBackdropBorderColor(color.content.border())
    end)
    -- a click anywhere else closes it
    pcall(popup.RegisterEvent, popup, 'GLOBAL_MOUSE_DOWN')
    popup:SetScript('OnEvent', function(self)
        if self:IsShown() and not self:IsMouseOver() and not btn:IsMouseOver() then
            self:Hide()
        end
    end)
    btn:SetScript('OnClick', function()
        if popup:IsShown() then popup:Hide() else popup:Show() end
    end)
end
do
    -- auxForever: credit to aux's creator, shown on every tab
    local label = gui.label(frame, gui.font_size.small)
    label:SetPoint('BOTTOMRIGHT', -24, 12)
    label:SetText('aux by shirsig, re-imagined by a fan')
    label:SetTextColor(.55, .55, .55)
    M.credit_label = label
end
