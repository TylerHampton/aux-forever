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
	-- auxForever palette (see the redesign mockup): warm text on dark slate, amber accent
	text = immutable-{enabled = C(243, 239, 230, 1), disabled = C(125, 122, 115, 1)},
	label = immutable-{enabled = C(168, 164, 155, 1), disabled = C(110, 107, 100, 1)},
	link = C(153, 255, 255, 1),
	window = immutable-{background = C(22, 24, 27, .97), border = C(43, 47, 53, 1)},
	panel = immutable-{background = C(24, 26, 29, 1), border = C(38, 42, 47, 1)},
	content = immutable-{background = C(29, 32, 36, 1), border = C(47, 52, 58, 1)},
	input = immutable-{background = C(15, 17, 19, 1), border = C(58, 63, 70, 1)},
	header = immutable-{background = C(29, 32, 36, 1), text = C(142, 138, 129, 1)},
	state = immutable-{enabled = C(63, 174, 106, 1), disabled = C(122, 58, 52, 1)},
	accent = immutable-{background = C(227, 164, 59, 1), text = C(26, 20, 8, 1), selected = C(58, 46, 21, 1)},
	selected = C(227, 164, 59, .22),
	-- money coming to the player (green) and going out (red), readable on the dark panels
	positive = C(111, 211, 154, 1),
	negative = C(255, 138, 126, 1),

	tooltip = immutable-{
		value = C(255, 255, 154, 1),
		merchant = C(204, 127, 25, 1),
		disenchant = immutable-{
			value = C(25, 153, 153, 1),
			distribution = C(204, 204, 51, 1),
			source = C(178, 178, 178, 1),
		}
	},

	blue = C(41, 146, 255, 1),
	green = C(22, 255, 22, 1),
	yellow = C(255, 255, 0, 1),
	orange = C(255, 146, 24, 1),
	red = C(255, 0, 0, 1),
	gray = C(187, 187, 187, 1),
	gold = C(255, 255, 154, 1),

	blizzard = C(0, 180, 255, 1),
}
