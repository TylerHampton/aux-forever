select(2, ...) 'aux'

function C(r, g, b, a)
	local mt = { __metatable = false, __newindex = pass, color = {r, g, b, a} }
	function mt:__call(text)
		local r, g, b, a = unpack(mt.color)
		if text then
			return format('|c%02X%02X%02X%02X', a, r, g, b) .. text .. FONT_COLOR_CODE_CLOSE
		else
			return r/255, g/255, b/255, a
		end
	end
	function mt:__concat(text)
		local r, g, b, a = unpack(mt.color)
		return format('|c%02X%02X%02X%02X', a, r, g, b) .. text
	end
	return setmetatable({}, mt)
end

M.color = immutable-{
	none = setmetatable({}, {__metatable=false, __newindex=pass, __call=function(_, v) return v end, __concat=function(_, v) return v end}),
	-- auxForever palette (0.6, the UI Kit in the Paper file "auxForever Screens"): near black
	-- surfaces with black edges, one gold accent for what is selected or primary
	text = immutable-{enabled = C(235, 235, 235, 1), disabled = C(107, 107, 107, 1)},
	label = immutable-{enabled = C(168, 168, 168, 1), disabled = C(94, 94, 94, 1)},
	link = C(153, 255, 255, 1),
	window = immutable-{background = C(22, 22, 22, .97), border = C(0, 0, 0, 1)},
	panel = immutable-{background = C(12, 12, 12, 1), border = C(0, 0, 0, 1)},
	-- raised things (buttons, tabs): 42 at the top, darker toward the bottom (gui.add_sheen)
	content = immutable-{background = C(42, 42, 42, 1), border = C(0, 0, 0, 1)},
	-- sunken things (tables, inputs, status bar)
	input = immutable-{background = C(10, 10, 10, 1), border = C(0, 0, 0, 1)},
	header = immutable-{background = C(34, 34, 34, 1), text = C(207, 207, 207, 1)},
	state = immutable-{enabled = C(77, 204, 102, 1), disabled = C(122, 58, 52, 1)},
	accent = immutable-{background = C(229, 190, 91, 1), text = C(229, 190, 91, 1), selected = C(42, 35, 18, 1), hover = C(242, 212, 138, 1), raised = C(39, 32, 18, 1)},
	selected = C(229, 190, 91, .13),
	hover = C(255, 255, 255, .06),
	-- money coming to the player (green) and going out (red)
	positive = C(77, 204, 102, 1),
	negative = C(232, 87, 74, 1),

	tooltip = immutable-{
		value = C(255, 255, 154, 1),
		merchant = C(204, 127, 25, 1),
		disenchant = immutable-{
			value = C(25, 153, 153, 1),
			distribution = C(204, 204, 51, 1),
			source = C(178, 178, 178, 1),
		}
	},

	-- status and deals (percentages of the usual price, errors)
	blue = C(90, 169, 255, 1),
	green = C(77, 204, 102, 1),
	yellow = C(232, 212, 77, 1),
	orange = C(240, 148, 60, 1),
	red = C(232, 87, 74, 1),
	gray = C(187, 187, 187, 1),
	gold = C(255, 255, 154, 1),

	blizzard = C(0, 180, 255, 1),
}
