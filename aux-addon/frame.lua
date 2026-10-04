select(2, ...) 'aux'

local gui = require 'aux.gui'
local scan = require 'aux.core.scan'
local post = require 'aux.tabs.post'
local search = require 'aux.tabs.search'

function event.AUX_LOADED()
	for _, v in ipairs(tab_info) do
		tabs:create_tab(v.name)
	end
	restore_window()
end

-- Forever: the window can be resized from its bottom right corner (double-click the corner for the
-- default size), and it remembers its size and position.
local DEFAULT_WIDTH, DEFAULT_HEIGHT = 1100, 620
local MIN_WIDTH, MIN_HEIGHT = 1000, 509

local function max_size()
	local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
	return max(MIN_WIDTH, UIParent:GetWidth() / scale), max(MIN_HEIGHT, UIParent:GetHeight() / scale)
end

local function set_resize_bounds()
	local max_width, max_height = max_size()
	if frame.SetResizeBounds then
		frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, max_width, max_height)
	else
		frame:SetMinResize(MIN_WIDTH, MIN_HEIGHT)
		frame:SetMaxResize(max_width, max_height)
	end
end

function save_window()
	local window = account_data.window
	window.width, window.height = frame:GetWidth(), frame:GetHeight()
	local point, _, relative_point, x, y = frame:GetPoint(1)
	window.point, window.relative_point, window.x, window.y = point, relative_point, x, y
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
	-- Forever: wider, and resizable (see restore_window)
	gui.set_size(frame, 1100, 620)
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
	frame.content = CreateFrame('Frame', nil, frame)
	frame.content:SetPoint('TOPLEFT', 4, -80)
	frame.content:SetPoint('BOTTOMRIGHT', -4, 35)
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
	tabs = gui.tabs(frame, 'DOWN')
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
	grip:SetScript('OnMouseDown', function(_, button)
		if button ~= 'LeftButton' then return end
		set_resize_bounds()
		frame:StartSizing('BOTTOMRIGHT')
	end)
	grip:SetScript('OnMouseUp', function()
		frame:StopMovingOrSizing()
		save_window()
	end)
	grip:SetScript('OnDoubleClick', function()
		frame:StopMovingOrSizing()
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
	local btn = gui.button(frame)
	btn:SetPoint('BOTTOMRIGHT', -22, 5)
	gui.set_size(btn, 60, 24)
	btn:SetText('Close')
	btn:SetScript('OnClick', function() frame:Hide() end)
	close_button = btn
end
do
	local btn = gui.button(frame, gui.font_size.small)
	btn:SetPoint('RIGHT', close_button, 'LEFT' , -5, 0)
	gui.set_size(btn, 60, 24)
	btn:SetText(color.blizzard'Blizzard UI')
	btn:SetScript('OnClick',function()
		set_blizzard_frame_shown(not blizzard_frame_shown())
	end)
    blizzard_button = btn
end
do
    local btn = gui.button(frame)
    btn:SetPoint('RIGHT', blizzard_button, 'LEFT' , -5, 0)
    gui.set_size(btn, 60, 24)
    btn:SetText('Scan')
    -- Forever: a full scan uses C_AuctionHouse.ReplicateItems, which the server allows once every 15 minutes
    local function seconds_until_scan()
        return max(0, account_data.replicate_time + scan.REPLICATE_COOLDOWN - time())
    end
    btn:SetScript('OnUpdate', function(self)
        if seconds_until_scan() == 0 and not scan.is_scanning() then
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
                post.record_auction(auction_record)
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
end
