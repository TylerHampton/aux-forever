select(2, ...) 'aux.gui.auction_listing'

local aux = require 'aux'
local info = require 'aux.util.info'
local sort_util = require 'aux.util.sort'
local money = require 'aux.util.money'
local history = require 'aux.core.history'
local gui = require 'aux.gui'
local tooltip = require 'aux.core.tooltip'

-- Forever: prices default to per item. Item rows are single items anyway, and a commodity row's
-- "stack" is everything listed at that price, so its total is rarely what you want to compare.
price_per_unit, percentage_for_bid = true, false

local HEAD_HEIGHT = 27
local HEAD_SPACE = 2

-- Forever: labels come from the auction house's time left bands
local TIME_LEFT_STRINGS = {
    aux.color.red(info.time_left_label(1)), -- Short
    aux.color.orange(info.time_left_label(2)), -- Medium
    aux.color.yellow(info.time_left_label(3)), -- Long
    aux.color.blue(info.time_left_label(4)), -- Very Long
}

-- auxForever: Forever names the seller only when one player sells at a row's price
function M.seller_text(record)
    if info.is_player(record.owner) then
        return aux.color.yellow(record.owner)
    elseif record.owner then
        return record.owner
    elseif (record.seller_count or 0) > 1 then
        return aux.color.label.enabled(record.seller_count .. ' sellers')
    end
    return '?'
end

function item_column_init(rt, cell)
    local spacer = CreateFrame('Frame', nil, cell)
    spacer:SetPoint('TOPLEFT', 0, 0)
    spacer:SetHeight(rt.ROW_HEIGHT)
    spacer:SetWidth(1)
    cell.spacer = spacer

    local iconBtn = CreateFrame('Button', nil, cell)
    iconBtn:SetPoint('TOPLEFT', spacer, 'TOPRIGHT')
    iconBtn:SetHeight(rt.ROW_HEIGHT)
    iconBtn:SetWidth(rt.ROW_HEIGHT)
    iconBtn:SetScript('OnEnter', rt.OnIconEnter)
    iconBtn:SetScript('OnLeave', rt.OnIconLeave)
    iconBtn:SetScript('OnClick', rt.OnIconClick)
    iconBtn:SetScript('OnDoubleClick', rt.OnIconDoubleClick)
    local icon = iconBtn:CreateTexture(nil, 'ARTWORK')
    icon:SetPoint('TOPLEFT', 2, -2)
    icon:SetPoint('BOTTOMRIGHT', -2, 2)
    icon:SetTexCoord(.08, .92, .08, .92)

    cell.iconBtn = iconBtn
    cell.icon = icon

    cell.text:ClearAllPoints()
    cell.text:SetPoint('TOPLEFT', iconBtn, 'TOPRIGHT', 2, 0)
    cell.text:SetPoint('BOTTOMRIGHT', 0, 0)
end

function item_column_fill(cell, record, _, _, _, indented)
	cell.icon:SetTexture(record.texture)
	if indented then
		cell.spacer:SetWidth(10)
		cell.icon:SetAlpha(.5)
		cell.text:SetAlpha(.7)
	else
		cell.spacer:SetWidth(1)
		cell.icon:SetAlpha(1)
		cell.text:SetAlpha(1)
	end
	cell.text:SetText(gsub(record.link, '[%[%]]', ''))
end

function status_code(record)
    if record.sale_status == 1 then
        return 1
    elseif not record.high_bidder then
        return 2
    else
        return 3
    end
end

-- auxForever: columns shared by the tables. Level is a narrow first column everywhere. Quantity
-- replaces aux's Auctions and Stack Size: on Forever a trade good row is one price tier and gear
-- rows are identical single items, so the units for sale at that price is the useful number.
local function level_column()
    return {
        title = 'Lvl',
        width = .03,
        align = 'CENTER',
        fill = function(cell, record)
            local requirement = record.requirement or 0
            local display_level = max(requirement, 1)
            display_level = UnitLevel'player' < requirement and aux.color.red(display_level) or display_level
            cell.text:SetText(display_level)
        end,
        cmp = function(record_a, record_b, desc)
            return sort_util.compare(record_a.requirement or 0, record_b.requirement or 0, desc)
        end,
    }
end

-- units: the units on this row (or of all rows of a collapsed item), own_units: the player's
local function quantity_column(title)
    return {
        title = title,
        width = .065,
        align = 'CENTER',
        fill = function(cell, record, units, own_units, expandable)
            local text = units and units > 0 and units or '?'
            text = expandable and aux.color.link(text) or text
            if own_units and own_units > 0 then
                text = text .. ' ' .. aux.color.yellow('(' .. own_units .. ')')
            end
            cell.text:SetText(text)
        end,
        cmp = function(record_a, record_b, desc)
            return sort_util.compare(record_a.count * (record_a.auction_count or 1), record_b.count * (record_b.auction_count or 1), desc)
        end,
    }
end

M.search_columns = {
    level_column(),
    {
        title = 'Item',
        width = .35,
        init = item_column_init,
        fill = item_column_fill,
        cmp = function(record_a, record_b, desc)
            return sort_util.compare(record_a.name, record_b.name, desc)
        end,
    },
    quantity_column('For sale'),
    {
        title = 'Time\nLeft',
        width = .04,
        align = 'CENTER',
        fill = function(cell, record)
            cell.text:SetText(TIME_LEFT_STRINGS[record.duration or 0] or '?')
        end,
        cmp = function(record_a, record_b, desc)
            return sort_util.compare(record_a.duration, record_b.duration, desc)
        end,
    },
    {
        title = 'Seller',
        width = .13,
        align = 'CENTER',
        fill = function(cell, record)
            cell.text:SetText(seller_text(record))
        end,
        cmp = function(record_a, record_b, desc)
            if not record_a.owner and not record_b.owner then
                return sort_util.EQ
            elseif not record_a.owner then
                return sort_util.GT
            elseif not record_b.owner then
                return sort_util.LT
            else
                return sort_util.compare(record_a.owner, record_b.owner, desc)
            end
        end,
    },
    {
        title = {'Auction Bid\n(per item)', 'Auction Bid\n(per stack)'},
        bid = true,
        width = .125,
        align = 'RIGHT',
        toggle = 'price_per_unit',
        fill = function(cell, record)
            -- Forever: commodities cannot be bid on
            if record.commodity then
                cell.text:SetText('---')
                return
            end
            local price_color
            if record.high_bidder then
	            price_color = aux.color.green
            elseif record.high_bid ~= 0 then
	            price_color = aux.color.orange
            end
            local price
            if record.high_bidder then
                price = price_per_unit and ceil(record.high_bid / record.count) or record.high_bid
            else
                price = price_per_unit and ceil(record.unit_bid_price) or record.bid_price
            end
            cell.text:SetText(money.to_string(price, true, false, price_color))
        end,
        cmp = function(record_a, record_b, desc)
            local price_a
            if record_a.high_bidder then
                price_a = price_per_unit and record_a.high_bid / record_a.count or record_a.high_bid
            else
                price_a = price_per_unit and record_a.unit_bid_price or record_a.bid_price
            end
            local price_b
            if record_b.high_bidder then
                price_b = price_per_unit and record_b.high_bid / record_b.count or record_b.high_bid
            else
                price_b = price_per_unit and record_b.unit_bid_price or record_b.bid_price
            end
            if record_a.high_bidder and not record_b.high_bidder then
	            return sort_util.GT
            elseif record_b.high_bidder and not record_a.high_bidder then
	            return sort_util.LT
            end
            if price_a == price_b then
				if record_a.high_bid == 0 and record_b.high_bid ~= 0 then
		            return sort_util.GT
	            elseif record_b.high_bid == 0 and record_a.high_bid ~= 0 then
		            return sort_util.LT
	            end
            end
            return sort_util.compare(price_a, price_b, desc)
        end,
    },
    {
        title = {'Auction Buyout\n(per item)', 'Auction Buyout\n(per stack)'},
        width = .125,
        align = 'RIGHT',
        toggle = 'price_per_unit',
        fill = function(cell, record)
            local price = price_per_unit and ceil(record.unit_buyout_price) or record.buyout_price
            cell.text:SetText(price > 0 and money.to_string(price, true) or '---')
        end,
        cmp = function(record_a, record_b, desc)
            local price_a = price_per_unit and record_a.unit_buyout_price or record_a.buyout_price
            local price_b = price_per_unit and record_b.unit_buyout_price or record_b.buyout_price
            price_a = price_a > 0 and price_a or (desc and -math.huge or math.huge)
            price_b = price_b > 0 and price_b or (desc and -math.huge or math.huge)

            return sort_util.compare(price_a, price_b, desc)
        end,
    },
    {
        title = {'% Hist.\nValue (Bid)', '% Hist.\nValue'},
        width = .08,
        align = 'CENTER',
        toggle = 'percentage_for_bid',
        fill = function(cell, record)
            local primary, secondary = record_percentage(record)
            cell.text:SetText((primary or secondary) and gui.percentage_historical(primary or secondary, not primary) or '?')
        end,
        cmp = function(record_a, record_b, desc)
            local pct_a = record_percentage(record_a) or (desc and -math.huge or math.huge)
            local pct_b = record_percentage(record_b) or (desc and -math.huge or math.huge)
            return sort_util.compare(pct_a, pct_b, desc)
        end,
    },
}

M.auctions_columns = {
    level_column(),
    {
        title = 'Item',
        width = .35,
        init = item_column_init,
        fill = item_column_fill,
        cmp = function(record_a, record_b, desc)
            return sort_util.compare(record_a.name, record_b.name, desc)
        end,
    },
    quantity_column('Quantity'),
    {
        title = 'Time\nLeft',
        width = .04,
        align = 'CENTER',
        fill = function(cell, record)
            if record.sale_status == 1 then
                cell.text:SetText('?')
            else
                cell.text:SetText(TIME_LEFT_STRINGS[record.duration or 0] or '?')
            end
        end,
        cmp = function(record_a, record_b, desc)
            if record_a.sale_status == 1 and record_b.sale_status == 1 then
                return sort_util.EQ
            elseif record_a.sale_status == 1 then
                return sort_util.GT
            elseif record_b.sale_status == 1 then
                return sort_util.LT
            else
                return sort_util.compare(record_a.duration, record_b.duration, desc)
            end
        end,
    },
    {
        title = {'Auction Bid\n(per item)', 'Auction Bid\n(per stack)'},
        bid = true,
        width = .125,
        align = 'RIGHT',
        toggle = 'price_per_unit',
        fill = function(cell, record)
            if record.sale_status == 1 and price_per_unit then
                cell.text:SetText('?')
                return
            end
            local price
            if record.high_bidder then
                price = price_per_unit and ceil(record.high_bid / record.count) or record.high_bid
            else
                price = price_per_unit and ceil(record.start_price / record.count) or record.start_price
            end
            cell.text:SetText(money.to_string(price, true))
        end,
        cmp = function(record_a, record_b, desc)
            if price_per_unit then
                if record_a.sale_status == 1 and record_b.sale_status == 1 then
                    return sort_util.EQ
                elseif record_a.sale_status == 1 then
                    return sort_util.GT
                elseif record_b.sale_status == 1 then
                    return sort_util.LT
                end
            end
            local price_a
            if record_a.high_bidder then
                price_a = price_per_unit and record_a.high_bid / record_a.count or record_a.high_bid
            else
                price_a = price_per_unit and record_a.start_price / record_b.count or record_a.start_price
            end
            local price_b
            if record_b.sale_status == 1 and price_per_unit then
                price_b = math.huge
            elseif record_b.high_bidder then
                price_b = price_per_unit and record_b.high_bid / record_b.count or record_b.high_bid
            else
                price_b = price_per_unit and record_b.start_price / record_b.count or record_b.start_price
            end
            return sort_util.compare(price_a, price_b, desc)
        end,
    },
    {
        title = {'Auction Buyout\n(per item)', 'Auction Buyout\n(per stack)'},
        width = .125,
        align = 'RIGHT',
        toggle = 'price_per_unit',
        fill = function(cell, record)
            if record.sale_status == 1 and price_per_unit then
                cell.text:SetText('?')
                return
            end
            local price = price_per_unit and ceil(record.unit_buyout_price) or record.buyout_price
            cell.text:SetText(price > 0 and money.to_string(price, true) or '---')
        end,
        cmp = function(record_a, record_b, desc)
            if price_per_unit then
                if record_a.sale_status == 1 and record_b.sale_status == 1 then
                    return sort_util.EQ
                elseif record_a.sale_status == 1 then
                    return sort_util.GT
                elseif record_b.sale_status == 1 then
                    return sort_util.LT
                end
            end

            local price_a = price_per_unit and record_a.unit_buyout_price or record_a.buyout_price
            local price_b = price_per_unit and record_b.unit_buyout_price or record_b.buyout_price
            price_a = price_a > 0 and price_a or (desc and -math.huge or math.huge)
            price_b = price_b > 0 and price_b or (desc and -math.huge or math.huge)

            return sort_util.compare(price_a, price_b, desc)
        end,
    },
    {
        title = 'Status',
        width = .21,
        align = 'CENTER',
        fill = function(cell, record)
            local text
            if not record.high_bidder then
                text = aux.color.red'No Bids'
            elseif record.sale_status == 1 then
                text = aux.color.blue'Sold: ' .. record.high_bidder
            else
                text = aux.color.green'Bid: ' .. record.high_bidder
            end
            cell.text:SetText(text)
        end,
        cmp = function(record_a, record_b, desc)
            local status_order = sort_util.compare(status_code(record_a), status_code(record_b), desc)
            if status_order ~= sort_util.EQ then
                return status_order
            elseif not record_a.high_bidder and not record_b.high_bidder then
                return sort_util.EQ
            elseif not record_a.high_bidder then
                return sort_util.GT
            elseif not record_b.high_bidder then
                return sort_util.LT
            else
                return sort_util.compare(record_a.high_bidder, record_b.high_bidder, desc)
            end
        end,
    },
}

M.bids_columns = {
    level_column(),
    {
        title = 'Item',
        width = .35,
        init = item_column_init,
        fill = item_column_fill,
        cmp = function(record_a, record_b, desc)
            return sort_util.compare(record_a.name, record_b.name, desc)
        end,
    },
    quantity_column('Quantity'),
    {
        title = 'Time\nLeft',
        width = .04,
        align = 'CENTER',
        fill = function(cell, record)
            cell.text:SetText(TIME_LEFT_STRINGS[record.duration or 0] or '?')
        end,
        cmp = function(record_a, record_b, desc)
            return sort_util.compare(record_a.duration, record_b.duration, desc)
        end,
    },
    {
        title = 'Seller',
        width = .13,
        align = 'CENTER',
        fill = function(cell, record)
            cell.text:SetText(seller_text(record))
        end,
        cmp = function(record_a, record_b, desc)
            if not record_a.owner and not record_b.owner then
                return sort_util.EQ
            elseif not record_a.owner then
                return sort_util.GT
            elseif not record_b.owner then
                return sort_util.LT
            else
                return sort_util.compare(record_a.owner, record_b.owner, desc)
            end
        end,
    },
    {
        title = {'Auction Bid\n(per item)', 'Auction Bid\n(per stack)'},
        bid = true,
        width = .125,
        align = 'RIGHT',
        toggle = 'price_per_unit',
        fill = function(cell, record)
            local price
            if record.high_bidder then
                price = price_per_unit and ceil(record.high_bid / record.count) or record.high_bid
            else
                price = price_per_unit and ceil(record.unit_bid_price) or record.bid_price
            end
            cell.text:SetText(money.to_string(price))
        end,
        cmp = function(record_a, record_b, desc)
            local price_a
            if record_a.high_bidder then
                price_a = price_per_unit and record_a.high_bid / record_a.count or record_a.high_bid
            else
                price_a = price_per_unit and record_a.unit_bid_price or record_a.bid_price
            end
            local price_b
            if record_b.high_bidder then
                price_b = price_per_unit and record_b.high_bid / record_b.count or record_b.high_bid
            else
                price_b = price_per_unit and record_b.unit_bid_price or record_b.bid_price
            end
            return sort_util.compare(price_a, price_b, desc)
        end,
    },
    {
        title = {'Auction Buyout\n(per item)', 'Auction Buyout\n(per stack)'},
        width = .125,
        align = 'RIGHT',
        toggle = 'price_per_unit',
        fill = function(cell, record)
            local price = price_per_unit and ceil(record.unit_buyout_price) or record.buyout_price
            cell.text:SetText(price > 0 and money.to_string(price, true) or '---')
        end,
        cmp = function(record_a, record_b, desc)
            local price_a = price_per_unit and record_a.unit_buyout_price or record_a.buyout_price
            local price_b = price_per_unit and record_b.unit_buyout_price or record_b.buyout_price
            price_a = price_a > 0 and price_a or (desc and -math.huge or math.huge)
            price_b = price_b > 0 and price_b or (desc and -math.huge or math.huge)

            return sort_util.compare(price_a, price_b, desc)
        end,
    },
    {
        title = 'Status',
        width = .115,
        align = 'CENTER',
        fill = function(cell, record)
            local status
            if record.high_bidder then
                status = aux.color.yellow'High Bidder'
            else
                status = aux.color.red'Outbid'
            end
            cell.text:SetText(status)
        end,
        cmp = function(record_a, record_b, desc)
            return sort_util.compare(record_a.high_bidder and 1 or 0, record_b.high_bidder and 1 or 0, desc)
        end,
    },
}

function record_percentage(record)
    if not record then return end

    local historical_value = history.value(record.item_key) or 0
    if historical_value > 0 then
        if record.unit_buyout_price > 0 or percentage_for_bid then
            local unit_price = percentage_for_bid and record.unit_bid_price or record.unit_buyout_price
            return aux.round(100 * unit_price / historical_value)
        end
        return nil, aux.round(100 * record.unit_bid_price / historical_value)
    end
end

function M.time_left(code)
    return TIME_LEFT_STRINGS[code]
end

local methods = {

    ResizeColumns = function(self)
        local function column_width(cell)
            return (cell.info.bid and self.hide_bid) and 0 or cell.info.width
        end
        local weight = 0
        for _, cell in pairs(self.headCells) do
            weight = weight + column_width(cell)
        end
        local right, left = self.contentFrame:GetRight(), self.contentFrame:GetLeft()
        if not right or not left then return end
        weight = (right - left) / weight
        for i, cell in pairs(self.headCells) do
            local width = column_width(cell) * weight
            local shown = width > 0
            cell:SetWidth(max(width, .001))
            if shown then cell:Show() else cell:Hide() end
            for _, row in pairs(self.rows) do
                row.cells[i]:SetWidth(max(width, .001))
                if shown then row.cells[i]:Show() else row.cells[i]:Hide() end
            end
        end
    end,

    OnHeadColumnClick = function(self, button)
        local rt = self.rt

        local toggle = rt.headCells[self.columnIndex].info.toggle
        if button == 'RightButton' and toggle then
            _M[toggle] = not _M[toggle]
            for _, cell in pairs(rt.headCells) do
                if cell.info.toggle == toggle then
                    cell:SetText(cell.info.title[_M[toggle] and 1 or 2])
                end
            end
            rt:SetSort()
            return
        end

        local descending = false
        if #rt.sorts > 0 and rt.sorts[1].index == self.columnIndex then
            descending = not rt.sorts[1].descending
        end
        rt:SetSort((descending and -1 or 1) * self.columnIndex)
    end,

    OnIconEnter = function(self)
        local rt = self:GetParent().row.rt
        local row = self:GetParent().row
        if row.record then
	        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            GameTooltip:SetHyperlink(row.record.link)
            GameTooltip_ShowCompareItem()
        end
    end,

    OnIconLeave = function()
        GameTooltip:Hide()
    end,

    OnEnter = function(self)
        local rt = self.rt

        if not rt.rowInfo.single_item then
            if rt.expanded[self.expandKey] then
                GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                GameTooltip:AddLine('Double-click to collapse this item.', 1, 1, 1, true)
                GameTooltip:Show()
            elseif self.expandable then
                GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                GameTooltip:AddLine('Double-click to expand this item.', 1, 1, 1, true)
                GameTooltip:Show()
            end
        end

        self.highlight:Show()
    end,

    OnLeave = function(self)
        GameTooltip:Hide()
        if not self.rt.selected or self.rt.selected.search_signature ~= self.record.search_signature then
            self.highlight:Hide()
        end
    end,

    OnClick = function(self, button)
        if IsControlKeyDown() or IsShiftKeyDown() then
            HandleModifiedItemClick(self.record.link)
        else
            if button == 'LeftButton' then
                local selection = self.rt:GetSelection()
                if not selection or selection.record ~= self.record then
                    self.rt:SetSelectedRecord(self.record)
                end
            end
	        do (self.rt.handlers.OnClick or pass)(self, button) end
        end
    end,

    OnDoubleClick = function(self)
        local rt = self.rt
        local expand = not rt.expanded[self.expandKey]

        rt.expanded[self.expandKey] = expand
        rt:UpdateRowInfo()
        rt:UpdateRows()
        if not self.indented then
            rt:SetSelectedRecord(self.record)
        end
    end,

    UpdateRowInfo = function(self)
        aux.wipe(self.rowInfo)
        self.rowInfo.numDisplayRows = 0
        self.isSorted = nil
        self:SetSelectedRecord(nil, true)

	    local records = self.records

        self.rowInfo.single_item = aux.all(records, function(record) return record.item_key == records[1].item_key end)

        sort(records, function(a, b) return a.search_signature < b.search_signature or a.search_signature == b.search_signature and tostring(a) < tostring(b) end)

        for i = 1, #records do
            local record = records[i]
            local prevRecord = records[i - 1]
            if prevRecord and record.search_signature == prevRecord.search_signature then
                -- it's an identical auction to the previous row so increment the number of auctions
                -- Forever: one record can stand for a bucket of identical auctions (auction_count)
                self.rowInfo[#self.rowInfo].children[#self.rowInfo[#self.rowInfo].children].count = self.rowInfo[#self.rowInfo].children[#self.rowInfo[#self.rowInfo].children].count + (record.auction_count or 1)
            elseif not self.rowInfo.single_item and prevRecord and record.item_key == prevRecord.item_key then
                -- it's the same base item as the previous row so insert a new auction
                tinsert(self.rowInfo[#self.rowInfo].children, { count = record.auction_count or 1, record = record })
                if self.expanded[self.rowInfo[#self.rowInfo].expandKey] then
                    self.rowInfo.numDisplayRows = self.rowInfo.numDisplayRows + 1
                end
            else
                -- it's a different base item from the previous row
                tinsert(self.rowInfo, { item_key = record.item_key, expandKey = record.item_key, children = {{ count = record.auction_count or 1, record = record }} })
                self.rowInfo.numDisplayRows = self.rowInfo.numDisplayRows + 1
            end
        end

	    -- auxForever: rows show units for sale (see quantity_column), so total units per item
	    for _, v in ipairs(self.rowInfo) do
            local totalUnits, totalPlayerUnits = 0, 0
            for _, childInfo in pairs(v.children) do
                childInfo.units = childInfo.count * (childInfo.record.count or 1)
                totalUnits = totalUnits + childInfo.units
                if info.is_player(childInfo.record.owner) then
                    totalPlayerUnits = totalPlayerUnits + childInfo.units
                end
            end
            v.totalUnits = totalUnits
            v.totalPlayerUnits = totalPlayerUnits
	    end

	    -- auxForever: trade goods cannot be bid on, so the Bid column hides when every row is one
	    local all_commodities = #records > 0
	    for _, record in ipairs(records) do
	        if not record.commodity then
	            all_commodities = false
	            break
	        end
	    end
	    self.hide_bid = all_commodities
    end,

    UpdateRows = function(self)
	    if self.rowInfo.numDisplayRows > #self.rows then
		    self.contentFrame:SetPoint('BOTTOMRIGHT', -15, 0)
	    else
		    self.contentFrame:SetPoint('BOTTOMRIGHT', 0, 0)
	    end
	    self:ResizeColumns()

	    FauxScrollFrame_Update(self.scrollFrame, self.rowInfo.numDisplayRows, #self.rows, self.ROW_HEIGHT)

	    local maxOffset = max(self.rowInfo.numDisplayRows - #self.rows, 0)
	    if FauxScrollFrame_GetOffset(self.scrollFrame) > maxOffset then
		    FauxScrollFrame_SetOffset(self.scrollFrame, maxOffset)
	    end

        for _, cell in pairs(self.headCells) do
            local tex = cell:GetNormalTexture()
            tex:SetColorTexture(aux.color.header.background())
        end

        if #self.sorts > 0 then
            local last_sort = self.sorts[1]
            if last_sort.descending then
                self.headCells[last_sort.index]:GetNormalTexture():SetColorTexture(.89, .64, .23, .3)
            else
                self.headCells[last_sort.index]:GetNormalTexture():SetColorTexture(.42, .6, .85, .3)
            end
        end

        if not self.isSorted then
            local function sort_helper(a, b)

                local record_a, record_b
                if a.children then
                    record_a = a.children[1].record
                    record_b = b.children[1].record
                else
                    record_a = a.record
                    record_b = b.record
                end

                for _, sort in pairs(self.sorts) do
                    local ordering = self.columns[sort.index].cmp and self.columns[sort.index].cmp(record_a, record_b, sort.descending) or sort_util.EQ

                    if ordering == sort_util.LT then
                        return true
                    elseif ordering == sort_util.GT then
                        return false
                    end
                end

                return tostring(a) < tostring(b)
            end

            for _, v in ipairs(self.rowInfo) do
                sort(v.children, sort_helper)
            end
            sort(self.rowInfo, sort_helper)
            self.isSorted = true
        end

	    for _, row in pairs(self.rows) do
		    row:Hide()
	    end
        local rowIndex = 1 - FauxScrollFrame_GetOffset(self.scrollFrame)
        for _, v in ipairs(self.rowInfo) do
            if self.expanded[v.expandKey] then
                for j, childInfo in ipairs(v.children) do
                    self:SetRowInfo(rowIndex, childInfo.record, childInfo.units, 0, j > 1, false, v.expandKey)
                    rowIndex = rowIndex + 1
                end
            else
                self:SetRowInfo(rowIndex, v.children[1].record, v.totalUnits, #v.children > 1 and v.totalPlayerUnits or 0, false, #v.children > 1, v.expandKey)
                rowIndex = rowIndex + 1
            end
        end
    end,

    SetRowInfo = function(self, rowIndex, record, units, own_units, indented, expandable, expandKey)
        if rowIndex <= 0 or rowIndex > #self.rows then return end
        local row = self.rows[rowIndex]
        row:Show()
        if self.selected and record.search_signature == self.selected.search_signature then
            row.highlight:Show()
        else
            row.highlight:Hide()
        end

        row.record = record
        row.expandable = expandable
        row.indented = indented
        row.expandKey = expandKey

        for i, column in pairs(self.columns) do
	        column.fill(row.cells[i], record, units, own_units, expandable, indented)
        end
    end,

    SetSelectedRecord = function(self, record, silent)
        self.selected = record
        local selectedData = self:GetSelection()
        self.selected = selectedData and self.selected or nil

        for _, row in pairs(self.rows) do
            if self.selected and row.record and row.record.search_signature == self.selected.search_signature then
                row.highlight:Show()
            else
                row.highlight:Hide()
            end
        end

        if not silent and self.handlers.OnSelectionChanged then
            self.handlers.OnSelectionChanged(self, selectedData or nil)
        end
    end,

    Reset = function(self)
        aux.wipe(self.expanded)
        self:UpdateRowInfo()
        self:UpdateRows()
        self:SetSelectedRecord()
    end,

    SetDatabase = function(self, database)
        if database and database ~= self.records then
            self.records = database
        end

        local prevSelectedIndex
        if self.selected then
            for i, row in pairs(self.rows) do
                if row:IsVisible() and row.record == self.selected then
                    prevSelectedIndex = i
                end
            end
        end

        self:UpdateRowInfo()
        self:UpdateRows()

        if not self.selected and prevSelectedIndex then
            -- try to select the same row
            local row = self.rows[prevSelectedIndex]
            if row and row:IsVisible() and row.record then
                self:SetSelectedRecord(row.record)
            end
            if not self.selected then
                -- select the first row
                row = self.rows[1]
                if row and row:IsVisible() and row.record then
                    self:SetSelectedRecord(row.record)
                end
            end
        end
    end,

    RemoveAuctionRecord = function(self, record)
        local index = aux.key(self.records, record)
        if index then
            tremove(self.records, index)
        end
        self:SetDatabase()
    end,

    ContainsRecord = function(self, record)
        if aux.key(self.records, record) then
            return true
        end
    end,

    SetSort = function(self, ...)
        for _, v in ipairs{...} do
            for i, sort in ipairs(self.sorts) do
                if sort.index == abs(v) then
                    tremove(self.sorts, i)
                    break
                end
            end
            tinsert(self.sorts, 1, {index=abs(v), descending=v < 0})
        end

        self.isSorted = nil
        self:UpdateRows()
    end,

    SetHandler = function(self, event, handler)
        self.handlers[event] = handler
    end,

    GetSelection = function(self)
        if not self.selected then return end
        local selectedData
        for _, v in ipairs(self.rowInfo) do
            for _, childInfo in pairs(v.children) do
                if childInfo.record.search_signature == self.selected.search_signature then
                    selectedData = childInfo
                    break
                end
            end
        end
        return selectedData
    end,
}

-- Forever: the window can be resized, so a listing has a fixed row height and shows as many rows
-- as fit. Rows are created when first needed and kept for when the window grows again.
local function create_row(rt, i)
    local row = CreateFrame('Button', nil, rt.contentFrame)
    row.rt = rt
    row:SetHeight(rt.ROW_HEIGHT)
    row:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    row:SetScript('OnEnter', rt.OnEnter)
    row:SetScript('OnLeave', rt.OnLeave)
    row:SetScript('OnClick', rt.OnClick)
    row:SetScript('OnDoubleClick', rt.OnDoubleClick)
    row:SetPoint('TOPLEFT', 0, -(HEAD_HEIGHT + HEAD_SPACE + (i - 1) * rt.ROW_HEIGHT))
    row:SetPoint('TOPRIGHT', 0, -(HEAD_HEIGHT + HEAD_SPACE + (i - 1) * rt.ROW_HEIGHT))
    local highlight = row:CreateTexture()
    highlight:SetAllPoints()
    highlight:SetColorTexture(aux.color.selected())
    highlight:Hide()
    row.highlight = highlight

    row.cells = {}
    for j, column in ipairs(rt.columns) do
        local cell = CreateFrame('Frame', nil, row)
        local text = cell:CreateFontString()
        cell.text = text
        text:SetFont(gui.font, min(14, rt.ROW_HEIGHT))
        text:SetJustifyH(column.align or 'LEFT')
        text:SetJustifyV('MIDDLE')
        text:SetPoint('TOPLEFT', 1, -1)
        text:SetPoint('BOTTOMRIGHT', -1, 1)
        cell:SetHeight(rt.ROW_HEIGHT)
        cell.rt = rt
        cell.row = row

        if j == 1 then
            cell:SetPoint('TOPLEFT', 0, 0)
        else
            cell:SetPoint('TOPLEFT', row.cells[j - 1], 'TOPRIGHT')
        end

        if mod(j, 2) == 1 then
            local tex = cell:CreateTexture()
            tex:SetAllPoints()
            tex:SetColorTexture(1, 1, 1, .025)
        end

        if column.init then
            column.init(rt, cell)
        end

        tinsert(row.cells, cell)
    end

    if mod(i, 2) == 0 then
        local tex = row:CreateTexture()
        tex:SetAllPoints()
        tex:SetColorTexture(1, 1, 1, .035)
    end

    row:Hide()
    return row
end

local function fit_rows(rt)
    if not rt.all_rows then return end
    local height = rt:GetHeight() or 0
    if height <= 0 then return end
    local count = max(floor((height - HEAD_HEIGHT - HEAD_SPACE) / rt.ROW_HEIGHT), 0)
    if count == #rt.rows then
        rt:ResizeColumns()
        return
    end
    for i = count + 1, #rt.all_rows do
        rt.all_rows[i]:Hide()
    end
    rt.rows = {}
    for i = 1, count do
        rt.all_rows[i] = rt.all_rows[i] or create_row(rt, i)
        rt.rows[i] = rt.all_rows[i]
    end
    rt:ResizeColumns()
    rt:UpdateRows()
end

function M.new(parent, row_height, columns)
    local rt = CreateFrame('Frame', nil, parent)
    rt.columns = columns
    rt.ROW_HEIGHT = row_height
    rt.expanded = {}
    rt.handlers = {}
    rt.sorts = {}
    rt.records = {}
    rt.rowInfo = {numDisplayRows=0}

    for name, func in pairs(methods) do
        rt[name] = func
    end

    rt:SetScript('OnShow', function(self)
        fit_rows(self)
        for _, cell in pairs(self.headCells) do
            if cell.info.toggle then
                cell:SetText(cell.info.title[_M[cell.info.toggle] and 1 or 2])
            end
        end
    end)

    local contentFrame = CreateFrame('Frame', nil, rt)
    contentFrame:SetPoint('TOPLEFT', 0, 0)
    contentFrame:SetPoint('BOTTOMRIGHT', 0, 0)
    rt.contentFrame = contentFrame

    local scrollFrame = CreateFrame('ScrollFrame', gui.unique_name(), rt, 'FauxScrollFrameTemplate')
    scrollFrame:SetScript('OnVerticalScroll', function(self, offset)
	    FauxScrollFrame_OnVerticalScroll(self, offset, rt.ROW_HEIGHT, function() rt:UpdateRows() end)
    end)
    scrollFrame:SetAllPoints(contentFrame)
    rt.scrollFrame = scrollFrame
    FauxScrollFrame_Update(rt.scrollFrame, 0, 0, rt.ROW_HEIGHT)

    local scrollBar = _G[scrollFrame:GetName() .. 'ScrollBar']
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint('TOPRIGHT', rt, -4, -HEAD_HEIGHT)
    scrollBar:SetPoint('BOTTOMRIGHT', rt, -4, 4)
    scrollBar:SetWidth(10)
    local thumbTex = scrollBar:GetThumbTexture()
    thumbTex:SetPoint('CENTER', 0, 0)
    thumbTex:SetColorTexture(aux.color.content.border())
    thumbTex:SetHeight(150)
    thumbTex:SetWidth(scrollBar:GetWidth())
    _G[scrollBar:GetName() .. 'ScrollUpButton']:Hide()
    _G[scrollBar:GetName() .. 'ScrollDownButton']:Hide()

    rt.headCells = {}
    for i, column in ipairs(rt.columns) do
        local cell = CreateFrame('Button', nil, rt.contentFrame)
        cell:SetHeight(HEAD_HEIGHT)
        if i == 1 then
            cell:SetPoint('TOPLEFT', 0, 0)
        else
            cell:SetPoint('TOPLEFT', rt.headCells[i - 1], 'TOPRIGHT')
        end
        cell.info = column
        cell.rt = rt
        cell.columnIndex = i
        cell:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

        cell:SetScript('OnClick', rt.OnHeadColumnClick)

        local text = cell:CreateFontString()
        text:SetJustifyH('CENTER')
        text:SetFont(gui.font, 12)
        text:SetTextColor(aux.color.label.enabled())
        cell:SetFontString(text)
        if not column.toggle then cell:SetText(column.title or '') end -- TODO
        text:SetAllPoints()

        local tex = cell:CreateTexture()
        tex:SetAllPoints()
        tex:SetColorTexture(aux.color.header.background())
        cell:SetNormalTexture(tex)

        local tex = cell:CreateTexture()
        tex:SetAllPoints()
        tex:SetTexture([[Interface\Buttons\UI-Listbox-Highlight]])
        tex:SetTexCoord(.025, .957, .087, .931)
        tex:SetAlpha(.2)
        cell:SetHighlightTexture(tex)

        tinsert(rt.headCells, cell)
    end

    rt.rows = {}
    rt.all_rows = {}
    rt:SetScript('OnSizeChanged', fit_rows)

    rt:SetAllPoints()
    fit_rows(rt)
    rt:ResizeColumns()
    return rt
end