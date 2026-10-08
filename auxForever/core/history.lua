select(2, ...) 'aux.core.history'

local aux = require 'aux'

local persistence = require 'aux.util.persistence'

-- auxForever (0.5): better price data (docs/price-data.md, "Plan for 0.5").
--
-- Per item, one packed line in the saved variables:
--   day         the day number (days since 1 January 1970, local calendar) the "today" fields belong to
--   low         today's lowest unit buyout seen by any scan ("Today" in tooltips)
--   market      today's market price: the average unit price of the cheapest 20% of the units listed,
--               recorded only from a complete view of the item (every auction of it was seen)
--   units       how many units that complete view listed
--   points      up to 14 past days: day number, that day's price (its market price, or its lowest
--               price when no complete view was seen that day) and its units
-- The usual price ("Value") is the weighted median of the past days' prices; a day's weight halves
-- every 7 days of age, so recent days count more. One cheap auction moves the market price only a
-- little, where it used to set the whole day.

local history_schema = {'tuple', '#', {day='number'}, {low='number'}, {market='number'}, {units='number'}, {points={'list', ';', {'tuple', '@', {day='number'}, {value='number'}, {units='number'}}}}}
-- the 0.4 format (history_version 2): when the day ends (a timestamp), today's lowest, past lows
local old_schema = {'tuple', '#', {next_push='number'}, {daily_min_buyout='number'}, {data_points={'list', ';', {'tuple', '@', {value='number'}, {time='number'}}}}}

M.MARKET_SHARE = .2
M.MAX_POINTS = 14
M.HALF_LIFE = 7
-- a usual price whose newest data is this many days old is shown dimmed
M.OLD_DAYS = 7

local value_cache = {}

function aux.event.PLAYER_LOGIN()
	data = aux.faction_data.history
end

-- days since 1 January 1970 of a calendar date (Howard Hinnant's days_from_civil). Calendar days,
-- so summer time and time zones never make two days share a number or skip one.
function M.day_number_of(year, month, day)
	if month <= 2 then year = year - 1 end
	local era = floor(year / 400)
	local yoe = year - era * 400
	local doy = floor((153 * (month + (month > 2 and -3 or 9)) + 2) / 5) + day - 1
	local doe = yoe * 365 + floor(yoe / 4) - floor(yoe / 100) + doy
	return era * 146097 + doe - 719468
end

function M.day_of_time(timestamp)
	local t = date('*t', timestamp)
	return day_number_of(t.year, t.month, t.day)
end

do
	local current_day, until_time = 0, 0
	-- today's day number; worked out again only after local midnight
	function M.today()
		if time() >= until_time then
			local t = date('*t')
			current_day = day_number_of(t.year, t.month, t.day)
			t.hour, t.min, t.sec = 24, 0, 0
			until_time = time(t)
		end
		return current_day
	end
	-- the time today ends (kept for code that waits for midnight)
	function M.get_next_push()
		today()
		return until_time
	end
end

function new_record()
	return { day = today(), points = {} }
end

-- a 0.4 line becomes a 0.5 record: every past daily low is kept with its day; its old time was the
-- midnight that ended that day, so the day is read 12 hours earlier
function M.convert_old(str)
	local old = persistence.read(old_schema, str)
	local record = { day = day_of_time((old.next_push or time()) - 43200), low = old.daily_min_buyout, points = {} }
	for _, point in ipairs(old.data_points or empty) do
		if point.value and point.time then
			tinsert(record.points, { day = day_of_time(point.time - 43200), value = point.value })
		end
	end
	return record
end

local function unpack_record(str)
	-- a 0.4 line starts with a timestamp (10 digits), a 0.5 line with a day number (5 digits)
	local first = tonumber(strmatch(str, '^[^#]*'))
	if first and first > 1e7 then
		return convert_old(str)
	end
	local record = persistence.read(history_schema, str)
	record.day = record.day or today()
	return record
end

function read_record(item_key)
	local record = data[item_key] and unpack_record(data[item_key]) or new_record()
	if record.day < today() then
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

-- the day's price for the record: its market price, else its lowest
local function day_price(record)
	return record.market or record.low
end

function push_record(record)
	local price = day_price(record)
	if price then
		tinsert(record.points, 1, { day = record.day, value = price, units = record.market and record.units or nil })
		while #record.points > MAX_POINTS do
			tremove(record.points)
		end
	end
	record.day, record.low, record.market, record.units = today(), nil, nil, nil
end

-- auxForever: a scan sees every auction, and aux unpacked and repacked the item's saved history for
-- each one. Today's lowest price per item is kept in memory (one number per item seen today), so
-- the saved text is only touched when a price is a new low for the day.
local today_min, today_day = {}, 0

local function today_min_table()
	if today() ~= today_day then
		today_min, today_day = {}, today()
	end
	return today_min
end

function M.process_auction(auction_record)
	local unit_buyout_price = ceil(auction_record.buyout_price / auction_record.count)
	if unit_buyout_price <= 0 then
		return
	end
	local mins = today_min_table()
	local key = auction_record.item_key
	local known = mins[key]
	if known and unit_buyout_price >= known then
		return
	end
	local item_record = read_record(key)
	if unit_buyout_price < (item_record.low or math.huge) then
		item_record.low = unit_buyout_price
		write_record(key, item_record)
	end
	mins[key] = item_record.low or unit_buyout_price
end

-- units of an auction record: commodity tiers and replicated stacks carry them in count, an item
-- search row is auction_count identical auctions of one item each
function M.record_units(record)
	return max(1, record.count or 1) * max(1, record.auction_count or 1)
end

-- Market price of a list of unit prices and counts, flat: {price1, count1, price2, count2, ...}.
-- The average of the cheapest MARKET_SHARE of the units (at least one unit). Sorts the list.
function M.market_price(flat)
	local n = #flat / 2
	if n == 0 then
		return
	end
	local order = {}
	local total = 0
	for i = 1, n do
		order[i] = i
		total = total + flat[2 * i]
	end
	if total <= 0 then
		return
	end
	sort(order, function(a, b) return flat[2 * a - 1] < flat[2 * b - 1] end)
	local wanted = max(1, ceil(total * MARKET_SHARE))
	local left, sum = wanted, 0
	for _, i in ipairs(order) do
		local take = min(left, flat[2 * i])
		sum = sum + take * flat[2 * i - 1]
		left = left - take
		if left <= 0 then
			break
		end
	end
	return ceil(sum / wanted), total, flat[2 * order[1] - 1]
end

-- One complete view of an item (every auction of it): flat unit prices and counts as above. Sets
-- today's market price and units (the latest complete view of the day wins) and today's lowest.
function M.record_view(item_key, flat)
	local market, units, lowest = market_price(flat)
	if not market then
		return
	end
	local record = read_record(item_key)
	record.market, record.units = market, units
	if lowest < (record.low or math.huge) then
		record.low = lowest
	end
	write_record(item_key, record)
	local mins = today_min_table()
	mins[item_key] = record.low
end

-- A complete view from auction records (one item's search results)
function M.record_view_of(records)
	local flat, key = {}, nil
	for _, record in ipairs(records or empty) do
		local units = record_units(record)
		if (record.buyout_price or 0) > 0 and record.item_key and units > 0 then
			key = key or record.item_key
			if record.item_key == key then
				tinsert(flat, ceil(record.buyout_price / max(1, record.count or 1)))
				tinsert(flat, units)
			end
		end
	end
	if key then
		record_view(key, flat)
	end
end

function M.data_points(item_key)
	return read_record(item_key).points
end

local function compute_value(record)
	local points = record.points
	if #points == 0 then
		return day_price(record)
	end
	local total_weight, weighted_values = 0, {}
	local newest = points[1].day
	for _, point in ipairs(points) do
		local weight = .5 ^ ((newest - point.day) / HALF_LIFE)
		total_weight = total_weight + weight
		tinsert(weighted_values, { value = point.value, weight = weight })
	end
	for _, weighted_value in ipairs(weighted_values) do
		weighted_value.weight = weighted_value.weight / total_weight
	end
	return weighted_median(weighted_values)
end

local function cached(item_key)
	local entry = value_cache[item_key]
	if not entry or entry.day ~= today() then
		local record = read_record(item_key)
		local seen = record.low and record.day or (record.points[1] and record.points[1].day)
		-- the latest price: today's (market, else lowest) when seen today, else the newest past day's
		local latest = day_price(record) or (record.points[1] and record.points[1].value)
		entry = { value = compute_value(record), latest = latest, day = today(), days = #record.points, age = seen and today() - seen or nil }
		value_cache[item_key] = entry
	end
	return entry
end

function M.value(item_key)
	-- auxForever: an item without any history needs no unpacking and no cache entry (the Sniper asks
	-- about every item on the auction house)
	if not data[item_key] then
		return
	end
	return cached(item_key).value
end

-- auxForever: the usual price and how many days of history it rests on, from the same cache (the
-- Sniper used to unpack the saved history again just to count its days)
function M.value_and_days(item_key)
	if not data[item_key] then
		return nil, 0
	end
	local entry = cached(item_key)
	return entry.value, entry.days
end

-- auxForever (0.5): the usual price and how many days ago aux last saw the item (0: today), or nil
function M.value_and_age(item_key)
	if not data[item_key] then
		return
	end
	local entry = cached(item_key)
	return entry.value, entry.age
end

-- auxForever (0.5, build 3): the price of the latest complete look at the item (its market price, or
-- its lowest when no complete look was had that day) and how many days ago that was. Tooltips and
-- the recipe cost show this: players scan, post and leave, and need the tooltip to match the
-- auction house they just saw (Tyler, 2026-10-08). The multi-day usual price (value) stays for
-- finding deals: the Sniper, the search % column and the percentage filters.
function M.latest(item_key)
	if not data[item_key] then
		return
	end
	local entry = cached(item_key)
	return entry.latest, entry.age
end

-- the usual price differs this much or more from the latest: tooltips add "usually ..."
M.USUALLY_SHARE = .3
function M.usually_differs(latest, usual)
	return latest and usual and usual > 0 and abs(latest - usual) / usual >= USUALLY_SHARE or false
end

-- "today", "1 day ago", "9 days ago"
function M.age_text(age)
	if not age then
		return
	elseif age <= 0 then
		return 'today'
	elseif age == 1 then
		return '1 day ago'
	end
	return age .. ' days ago'
end

function M.market_value(item_key)
	if not data[item_key] then
		return
	end
	return read_record(item_key).low
end

-- today's market price and the units it was worked out from, if a complete view was seen today
function M.today_market(item_key)
	if not data[item_key] then
		return
	end
	local record = read_record(item_key)
	return record.market, record.units
end

function weighted_median(list)
	sort(list, function(a,b) return a.value < b.value end)
	local weight = 0
	for _, v in ipairs(list) do
		weight = weight + v.weight
		if weight >= .5 - 1e-9 then
			return v.value
		end
	end
	return list[#list] and list[#list].value
end

-- auxForever (0.5): the Full scan's auctions arrive in no item order. A collector gathers unit
-- prices and counts per item in flat number arrays while the scan runs; finish records each item
-- once (yielding every few hundred items) and drops everything.
function M.new_collector()
	return { items = {}, count = 0, partial = {} }
end

function M.collect(collector, record)
	local units = record_units(record)
	if (record.buyout_price or 0) <= 0 or not record.item_key then
		return
	end
	local flat = collector.items[record.item_key]
	if not flat then
		flat = {}
		collector.items[record.item_key] = flat
		collector.count = collector.count + 1
	end
	tinsert(flat, ceil(record.buyout_price / max(1, record.count or 1)))
	tinsert(flat, units)
end

-- must run inside a coroutine (it yields)
function M.finish_collector(collector)
	local done = 0
	for key, flat in pairs(collector.items) do
		if not collector.partial[tonumber(strmatch(key, '^%d+'))] then
			record_view(key, flat)
		end
		done = done + 1
		if done % 200 == 0 then
			aux.coro_wait()
		end
	end
	collector.items, collector.count, collector.partial = {}, 0, {}
end

-- auxForever (0.5): /aux price <item>. What aux keeps for an item, in plain words, so a price that
-- looks wrong can be checked against what was recorded (Tyler, build 1). money_text formats copper.
function M.report(item_key, money_text)
	if not data[item_key] then
		return {'No price history for this item yet.'}
	end
	local record = read_record(item_key)
	local entry = cached(item_key)
	local lines = {}
	tinsert(lines, format('Value in tooltips (latest look, seen %s): %s', age_text(entry.age) or '?', entry.latest and money_text(entry.latest) or '?'))
	tinsert(lines, format('Usual price, for finding deals: %s, from %d past %s', entry.value and money_text(entry.value) or '?', #record.points, #record.points == 1 and 'day' or 'days'))
	if record.points[1] == nil then
		tinsert(lines, 'With no past days yet, the usual price is today\'s price. Today counts from tomorrow on.')
	else
		tinsert(lines, 'Today is not part of the usual price until the day ends.')
	end
	tinsert(lines, format('Today: lowest %s; market %s', record.low and money_text(record.low) or '?', record.market and (money_text(record.market) .. format(' (cheapest fifth of %d listed)', record.units or 0)) or '? (no complete look today)'))
	local parts = {}
	for _, point in ipairs(record.points) do
		tinsert(parts, format('%s %s', age_text(today() - point.day), money_text(point.value)) .. (point.units and format(' (%d listed)', point.units) or ' (lowest, 0.4)'))
	end
	if #parts > 0 then
		tinsert(lines, 'Past days: ' .. table.concat(parts, ', '))
	end
	return lines
end

-- auxForever: /aux memory detail
function M.memory_counts()
	local cached_n, today_n = 0, 0
	for _ in pairs(value_cache) do cached_n = cached_n + 1 end
	for _ in pairs(today_min) do today_n = today_n + 1 end
	return cached_n, today_n
end
