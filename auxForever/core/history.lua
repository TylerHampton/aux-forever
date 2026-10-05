select(2, ...) 'aux.core.history'

local aux = require 'aux'

local persistence = require 'aux.util.persistence'

local history_schema = {'tuple', '#', {next_push='number'}, {daily_min_buyout='number'}, {data_points={'list', ';', {'tuple', '@', {value='number'}, {time='number'}}}}}

local value_cache = {}

function aux.event.PLAYER_LOGIN()
	data = aux.faction_data.history
end

do
	local next_push = 0
	function get_next_push()
		if time() > next_push then
			local date = date('*t')
			date.hour, date.min, date.sec = 24, 0, 0
			next_push = time(date)
        end
		return next_push
	end
end

function new_record()
	return { next_push = get_next_push(), data_points = {} }
end

function read_record(item_key)
	local record = data[item_key] and persistence.read(history_schema, data[item_key]) or new_record()
	if record.next_push <= time() then
		push_record(record)
		write_record(item_key, record)
	end
	return record
end

function write_record(item_key, record)
	data[item_key] = persistence.write(history_schema, record)
	if value_cache[item_key] then
		value_cache[item_key] = nil
	end
end

-- auxForever: a scan sees every auction, and aux unpacked and repacked the item's saved history for
-- each one. Today's lowest price per item is kept in memory (one number per item seen today), so
-- the saved text is only touched when a price is a new low for the day.
local today_min, today_until = {}, 0

function M.process_auction(auction_record)
	local unit_buyout_price = ceil(auction_record.buyout_price / auction_record.count)
	if unit_buyout_price <= 0 then
		return
	end
	if time() >= today_until then
		today_min, today_until = {}, get_next_push()
	end
	local key = auction_record.item_key
	local known = today_min[key]
	if known and unit_buyout_price >= known then
		return
	end
	local item_record = read_record(key)
	if unit_buyout_price < (item_record.daily_min_buyout or math.huge) then
		item_record.daily_min_buyout = unit_buyout_price
		write_record(key, item_record)
	end
	today_min[key] = item_record.daily_min_buyout or unit_buyout_price
end

function M.data_points(item_key)
	return read_record(item_key).data_points
end

function M.value(item_key)
	-- auxForever: an item without any history needs no unpacking and no cache entry (the Sniper asks
	-- about every item on the auction house)
	if not data[item_key] then
		return
	end
	if not value_cache[item_key] or value_cache[item_key].next_push <= time() then
		local item_record, value
		item_record = read_record(item_key)
		if #item_record.data_points > 0 then
			local total_weight, weighted_values = 0, {}
			for _, data_point in pairs(item_record.data_points) do
				local weight = .99 ^ aux.round((item_record.data_points[1].time - data_point.time) / (60 * 60 * 24))
				total_weight = total_weight + weight
				tinsert(weighted_values, { value = data_point.value, weight = weight })
			end
			for _, weighted_value in pairs(weighted_values) do
				weighted_value.weight = weighted_value.weight / total_weight
			end
			value = weighted_median(weighted_values)
		else
			value = item_record.daily_min_buyout
		end
		value_cache[item_key] = { value = value, next_push = item_record.next_push, days = #item_record.data_points }
	end
	return value_cache[item_key].value
end

-- auxForever: the usual price and how many days of history it rests on, from the same cache (the
-- Sniper used to unpack the saved history again just to count its days)
function M.value_and_days(item_key)
	local usual = value(item_key)
	local cached = value_cache[item_key]
	return usual, cached and data[item_key] and cached.days or 0
end

function M.market_value(item_key)
	return read_record(item_key).daily_min_buyout
end

function weighted_median(list)
	sort(list, function(a,b) return a.value < b.value end)
	local weight = 0
	for _, v in ipairs(list) do
		weight = weight + v.weight
		if weight >= .5 then
			return v.value
		end
	end
end

function push_record(item_record)
	if item_record.daily_min_buyout then
		tinsert(item_record.data_points, 1, { value = item_record.daily_min_buyout, time = item_record.next_push })
		while #item_record.data_points > 11 do
			tremove(item_record.data_points)
		end
	end
	item_record.next_push, item_record.daily_min_buyout = get_next_push(), nil
end