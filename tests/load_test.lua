-- Run from the auxForever folder: lua5.1 ../tests/load_test.lua
-- and again without the bundled font: AUX_TEST_FONT_FAIL=1 lua5.1 ../tests/load_test.lua
-- Load test: stub the WoW API, load every file in TOC order, then fire the startup events
-- (ADDON_LOADED, PLAYER_LOGIN), open the auction house, run OnUpdate scripts a few times and
-- walk through a commodity purchase.
local G = _G
local frames = {}
local NUMERIC = { GetRight=1, GetLeft=1, GetTop=1, GetBottom=1, GetWidth=1, GetHeight=1, GetNumber=1, GetScale=1, GetEffectiveScale=1, GetAlpha=1, GetID=1, GetNumPoints=1, GetVerticalScroll=1, GetHorizontalScroll=1, GetCursorPosition=1, GetStringWidth=1, GetTextWidth=1, GetFrameLevel=1, GetValue=1 }
local function new_frame(name)
  local f = { __scripts = {}, __events = {}, __name = name, __shown = true, __text = '' }
  return setmetatable(f, { __index = function(t, k)
    if type(k) ~= 'string' or not k:match('^%u') then return nil end
    if k == 'GetName' then return function() return t.__name or 'Stub' end end
    if k == 'SetScript' then return function(self, s, fn) self.__scripts[s] = fn end end
    if k == 'GetScript' then return function(self, s) return self.__scripts[s] end end
    if k == 'HookScript' then return function(self, s, fn) self.__scripts[s] = fn end end
    if k == 'RegisterEvent' then return function(self, e) self.__events[e] = true end end
    if k == 'UnregisterEvent' then return function(self, e) self.__events[e] = nil end end
    if k == 'Show' then return function(self) self.__shown = true; if self.__scripts.OnShow then self.__scripts.OnShow(self) end end end
    if k == 'Hide' then return function(self) self.__shown = false; if self.__scripts.OnHide then self.__scripts.OnHide(self) end end end
    if k == 'IsShown' or k == 'IsVisible' then return function(self) return self.__shown end end
    if k == 'SetText' then return function(self, x) self.__text = x end end
    if k == 'GetText' then return function(self) return self.__text end end
    -- like the game: SetFont needs a font file and a height above 0. With AUX_TEST_FONT_FAIL set,
    -- the bundled font cannot be loaded (as after a /reload right after installing)
    if k == 'SetFont' then return function(self, a, b, c, d)
      local path, height = a, b
      if a == 'p' or a == 'h1' or a == 'h2' or a == 'h3' then path, height = b, c end -- SimpleHTML
      if type(path) ~= 'string' then error("bad argument #1 to 'SetFont'", 2) end
      if not height or height <= 0 then error('Invalid font height', 2) end
      if os.getenv('AUX_TEST_FONT_FAIL') and path:find('auxForever') then self.__font, self.__height = nil, 0; return false end
      self.__font, self.__height = path, height
      return true
    end end
    if k == 'SetFontObject' then return function(self) self.__font, self.__height = [[Fonts\ARIALN.TTF]], 14 end end
    if k == 'GetFont' then return function(self)
      if self.__height then return self.__font, self.__height, '' end
      return 'font', 12, ''
    end end
    if k == 'IsEnabled' then return function() return true end end
    if k == 'GetChecked' or k == 'IsMouseOver' or k == 'HasFocus' or k == 'IsForbidden' then return function() return false end end
    if NUMERIC[k] then return function()
      if G.__geometry and (k == 'GetHeight' or k == 'GetWidth') then return G.__geometry.size end
      if G.__geometry and (k == 'GetRight' or k == 'GetLeft' or k == 'GetTop' or k == 'GetBottom') then return G.__geometry.edge end
      return 10
    end end
    if k:match('^Get') or k:match('^Create') then return function() return new_frame() end end
    return function() end
  end })
end
G.CreateFrame = function(_, name) local f = new_frame(name); tinsert(frames, f); if name then G[name] = f end return f end
for _, n in ipairs{'UIParent','GameTooltip','ItemRefTooltip','DEFAULT_CHAT_FRAME','UIErrorsFrame','AuctionHouseFrame'} do G[n] = new_frame(n) end
G.UISpecialFrames = {}; G.StaticPopupDialogs = {}; G.SlashCmdList = {}; G.SOUNDKIT = {}
local api = function(t) return setmetatable(t or {}, {__index=function() return function() return 0 end end}) end
G.C_AuctionHouse = api{GetTimeLeftBandInfo=function(b) return 0, ({1800,7200,43200,86400})[b+1] end, IsThrottledMessageSystemReady=function() return true end, SupportsCopperValues=function() return true end, GetBrowseResults=function() return {} end}
G.Enum = setmetatable({}, {__index=function(t,k) local e = setmetatable({}, {__index=function() return 1 end}); rawset(t,k,e); return e end})
for _, n in ipairs{'C_Item','C_Container','C_CurrencyInfo','C_Sound','C_AddOns','C_MerchantFrame','C_PlayerInfo','TooltipDataProcessor','ItemLocation','ChatFrameUtil'} do G[n] = api() end
G.C_Container.GetContainerNumSlots = function() return 0 end
G.ITEM_QUALITY_COLORS = setmetatable({}, {__index=function() return {r=1,g=1,b=1} end})
G.AuctionCategories = {}
G.GetRealmName = function() return 'R' end; G.UnitName = function() return 'P' end; G.UnitFactionGroup = function() return 'Horde' end; G.UnitGUID = function() return 'g' end; G.UnitLevel = function() return 60 end
G.GetMoney = function() return 100000 end; G.GetItemInfo = function() end
local clock = 0; G.GetTime = function() return clock end; G.time = os.time; G.date = os.date
G.strmatch = string.match; G.strfind = string.find; G.strsub = string.sub; G.strlower = string.lower; G.strupper=string.upper; G.strlen=string.len; G.format=string.format; G.gsub=string.gsub; G.tinsert=table.insert; G.tremove=table.remove; G.sort=table.sort; G.floor=math.floor; G.ceil=math.ceil; G.max=math.max; G.min=math.min; G.abs=math.abs; G.mod=math.fmod; G.sin=math.sin
G.hooksecurefunc = function() end; G.FauxScrollFrame_Update = function() end; G.FauxScrollFrame_GetOffset = function() return 0 end; G.FauxScrollFrame_SetOffset=function() end; G.FauxScrollFrame_OnVerticalScroll=function() end
G.IsShiftKeyDown = function() return false end; G.IsAltKeyDown = G.IsShiftKeyDown; G.IsControlKeyDown = G.IsShiftKeyDown
G.PlaySound = function() end; G.ClearCursor = function() end; G.StaticPopup_Show = function() end; G.StaticPopup_Hide = function() end
for _, s in ipairs{'LIGHTYELLOW_FONT_COLOR_CODE','FONT_COLOR_CODE_CLOSE','GRAY_FONT_COLOR_CODE','HOURS','ITEM_SPELL_CHARGES'} do G[s] = s end
G.ITEM_SPELL_CHARGES = '%d Charges'; G.AUCTION_DURATION_ONE = '2 Hours'; G.AUCTION_DURATION_TWO = '8 Hours'; G.AUCTION_DURATION_THREE = '24 Hours'
setmetatable(G, {__index=function(_, k) if type(k)=='string' and (k:match('Button$') or k:match('ScrollBar$') or k:match('Text$') or k:match('Icon$') or k:match('Count$') or k:match('Text[LR]%a+%d+$')) then return new_frame(k) end end})

local errors = 0
local function try(label, f, ...)
  local ok, err = pcall(f, ...)
  if not ok then errors = errors + 1; print('ERROR', label, err) end
end
local addon = {}
for line in io.lines('auxForever.toc') do
  if not line:match('^##') and line:match('%S') then
    local file = line:gsub('\\','/'):gsub('%s+$','')
    try('load ' .. file, assert(loadfile(file)), 'auxForever', addon)
  end
end
local function fire(event, ...)
  for _, f in ipairs(frames) do
    if f.__events[event] and f.__scripts.OnEvent then try(event, f.__scripts.OnEvent, f, event, ...) end
  end
end
fire('ADDON_LOADED', 'auxForever')
fire('PLAYER_LOGIN')
fire('ADDON_LOADED', 'Blizzard_AuctionHouseUI')
fire('AUCTION_HOUSE_SHOW')
for i = 1, 5 do
  clock = clock + 0.1
  for _, f in ipairs(frames) do
    if f.__shown and f.__scripts.OnUpdate then try('OnUpdate', f.__scripts.OnUpdate, f, 0.1) end
  end
end
-- Buy bar (gui/buy_bar.lua)
local function check(label, ok)
  if not ok then errors = errors + 1; print('FAIL', label) end
end
local function tick()
  clock = clock + 0.1
  for _, f in ipairs(frames) do
    if f.__shown and f.__scripts.OnUpdate then try('OnUpdate', f.__scripts.OnUpdate, f, 0.1) end
  end
end
local function same(a, b)
  if #a ~= #b then return false end
  for i = 1, #a do if a[i] ~= b[i] then return false end end
  return true
end
try('buy bar', function()
  local require = loadstring("select(2, ...) 'aux.test'; return require")('auxForever', addon)
  local bar = require 'aux.gui.buy_bar'

  -- quantity buttons follow the stack size, the full stack being the largest
  check('stack 20 -> 1 5 10 20', same(bar.quantities(20), {1, 5, 10, 20}))
  check('stack 10 -> 1 5 10', same(bar.quantities(10), {1, 5, 10}))
  check('stack 5 -> 1 5', same(bar.quantities(5), {1, 5}))
  check('stack 200 -> 1 50 100 200', same(bar.quantities(200), {1, 50, 100, 200}))
  check('no stack -> none', same(bar.quantities(1), {}))

  local calls = {}
  C_AuctionHouse.StartCommoditiesPurchase = function(id, n) tinsert(calls, 'start ' .. id .. ' ' .. n) end
  C_AuctionHouse.ConfirmCommoditiesPurchase = function(id, n) tinsert(calls, 'confirm ' .. id .. ' ' .. n) end
  C_AuctionHouse.CancelCommoditiesPurchase = function() tinsert(calls, 'cancel') end
  C_AuctionHouse.GetQuoteDurationRemaining = function() return 30 end
  local tiers = {{count = 6, commodity_unit_price = 6}, {count = 100, commodity_unit_price = 7}}
  local bought, refreshed
  bar.show_commodity{item_id = 123, name = 'Light Feather', max_stack = 20, tiers = function() return tiers end,
    on_success = function(n) bought = n end, on_refresh = function() refreshed = true end}
  tick()
  check('starts at one stack: Buy 20', bar.primary_label():find('^Buy 20 for') ~= nil)

  -- 20 units, cheapest first: 6 x 6c + 14 x 7c = 1s 34c
  bar.primary_click()
  check('quote requested for 20', calls[1] == 'start 123 20')
  fire('COMMODITY_PRICE_UPDATED', 7, 134)
  tick()
  check('confirm shows the price', bar.primary_label():find('^Confirm') ~= nil)
  check('nothing confirmed before the click', #calls == 1)
  bar.primary_click()
  check('confirmed after the click', calls[2] == 'confirm 123 20')
  fire('COMMODITY_PURCHASE_SUCCEEDED')
  tick()
  check('success reported for 20', bought == 20)
  check('back to Buy', bar.primary_label():find('^Buy') ~= nil)

  -- a server price above the estimate is cancelled, never confirmed, and the listings re-read
  calls = {}
  bar.primary_click()
  fire('COMMODITY_PRICE_UPDATED', 7, 135)
  tick()
  check('higher price cancelled', calls[2] == 'cancel')
  check('higher price not confirmed', #calls == 2)
  check('higher price refreshes listings', refreshed)
  check('higher price returns to Buy', bar.primary_label():find('^Buy') ~= nil)

  -- selecting something else while a price is shown cancels it
  calls = {}
  bar.primary_click()
  fire('COMMODITY_PRICE_UPDATED', 6, 120)
  bar.clear()
  check('clearing the bar cancels the quote', calls[2] == 'cancel')

  -- items: one per click at the price on the button; never your own
  local buys = 0
  local record = {buyout_price = 21000, bid_price = 15000, auction_count = 6}
  bar.show_item{record = record, name = 'Heavy Brown Bag', busy = function() return false end,
    on_buy = function() buys = buys + 1 end, on_bid = function() end}
  tick()
  check('item button shows its price', bar.primary_label():find('^Buy for') ~= nil)
  bar.primary_click()
  check('item bought once', buys == 1)
  bar.show_item{record = {buyout_price = 21000, bid_price = 15000}, name = 'Heavy Brown Bag', own = true,
    busy = function() return false end, on_buy = function() buys = buys + 1 end, on_bid = function() end}
  tick()
  bar.primary_click()
  check('own auction not bought', buys == 1)
end)

-- Listings sized by anchors have no size until the first layout pass (Post tab price lists).
try('listing before layout', function()
  local require = loadstring("select(2, ...) 'aux.test2'; return require")('auxForever', addon)
  local listing = require 'aux.gui.listing'
  G.__geometry = {size = 0, edge = nil}
  local st = listing.new(new_frame())
  st:SetColInfo{{name = 'Price', width = .5}, {name = 'Count', width = .5}}
  st:SetData{{cols = {{value = '1s'}, {value = '5'}}}}
  check('no rows before layout', st.numRows == 0)
  G.__geometry = {size = 200, edge = 100}
  st.__scripts.OnSizeChanged(st)
  check('rows appear after layout', st.numRows > 0 and #st.rows == st.numRows)
  G.__geometry = nil
end)

-- Resizable window: lists show as many rows as fit and keep up when the window changes size.
try('lists follow the window size', function()
  local require = loadstring("select(2, ...) 'aux.test3'; return require")('auxForever', addon)
  local auction_listing = require 'aux.gui.auction_listing'
  local item_listing = require 'aux.gui.item_listing'
  G.__geometry = {size = 0, edge = nil}
  local rt = auction_listing.new(new_frame(), 19, auction_listing.search_columns)
  check('auction list: no rows before layout', #rt.rows == 0)
  G.__geometry = {size = 29 + 19 * 14, edge = 100}
  rt.__scripts.OnSizeChanged(rt)
  check('auction list: 14 rows fit', #rt.rows == 14)
  for _, row in ipairs(rt.rows) do row:Show() end -- as if filled with auctions
  G.__geometry.size = 29 + 19 * 9
  rt.__scripts.OnSizeChanged(rt)
  check('auction list: shrinks to 9 rows', #rt.rows == 9 and not rt.all_rows[10].__shown)
  G.__geometry.size = 29 + 19 * 14
  rt.__scripts.OnSizeChanged(rt)
  check('auction list: grows back reusing rows', #rt.rows == 14 and #rt.all_rows == 14)

  G.__geometry = {size = 0, edge = nil}
  local il = item_listing.new(new_frame(), function() end, function() return false end)
  item_listing.populate(il, {})
  check('item list: no rows before layout', #il.rows == 0)
  G.__geometry = {size = 400, edge = 100}
  il.content_frame.__scripts.OnSizeChanged(il.content_frame)
  check('item list: 10 rows fit', #il.rows == 10)
  G.__geometry = nil

  -- the window size is saved and restored within the screen
  local aux = require 'aux'
  local f, w, h = aux.frame
  rawset(f, 'SetWidth', function(_, x) w = x end)
  rawset(f, 'SetHeight', function(_, x) h = x end)
  rawset(f, 'GetWidth', function() return w end)
  rawset(f, 'GetHeight', function() return h end)
  G.__geometry = {size = 3000, edge = 100}
  aux.account_data.window = {width = 1300, height = 700}
  aux.restore_window()
  check('window restores its saved size', w == 1300 and h == 700)
  aux.account_data.window = {width = 400, height = 9000}
  aux.restore_window()
  check('window size kept within bounds', w == 1000 and h == 3000)
  G.__geometry = nil
end)

-- Visual refresh: rounded styling keeps the old backdrop color calls working; seller column text
try('restyle', function()
  local require = loadstring("select(2, ...) 'aux.test4'; return require")('auxForever', addon)
  local gui = require 'aux.gui'
  local auction_listing = require 'aux.gui.auction_listing'
  local colored = {}
  local button = gui.button(new_frame())
  check('button has a rounded fill', button.aux_fill and #button.aux_fill.pieces == 7)
  check('button has a rounded outline', button.aux_border and #button.aux_border.pieces == 8)
  for _, t in ipairs(button.aux_fill.pieces) do rawset(t, 'SetVertexColor', function(_, r) colored[#colored + 1] = r end) end
  button:SetBackdropColor(.5, .5, .5, 1)
  check('SetBackdropColor recolors every fill piece', #colored == 7 and colored[1] == .5)
  check('named seller shown', auction_listing.seller_text{owner = 'Violet Toes'} == 'Violet Toes')
  check('several sellers counted', auction_listing.seller_text{seller_count = 12}:find('12 sellers') ~= nil)
  check('unknown seller', auction_listing.seller_text{seller_count = 1} == '?')

  -- after a /reload the new font file is not available yet and a label reports height 0;
  -- the game errors on SetFont with height 0, so set_primary must never pass it on
  local heights = {}
  local label = new_frame()
  rawset(label, 'GetFont', function() return nil, 0 end)
  rawset(label, 'SetFont', function(_, _, h) heights[#heights + 1] = h end)
  local primary = gui.button(new_frame())
  rawset(primary, 'GetFontString', function() return label end)
  gui.set_primary(primary)
  check('primary button font height is never 0', #heights == 1 and heights[1] > 0)
  check('bundled font status is reported', gui.bundled_font_loaded == (os.getenv('AUX_TEST_FONT_FAIL') == nil))
  check('a font is always set', type(gui.font) == 'string' and type(gui.font_bold) == 'string')
end)

-- Dropdowns: on the modern client the edit box loses focus as soon as an option is pressed
try('dropdown option click', function()
  local require = loadstring("select(2, ...) 'aux.test5'; return require")('auxForever', addon)
  local gui = require 'aux.gui'
  local dropdown = gui.dropdown(new_frame())
  dropdown:SetOptions{'2 Hours', '8 Hours', '24 Hours'}
  dropdown:SetIndex(2)
  dropdown.focus_gain()
  local menu = gui.dropdown_menu
  check('menu opens', menu.__shown)
  rawset(menu, 'IsMouseOver', function() return true end)
  dropdown.focus_loss() -- the press on an option takes focus first
  check('menu stays open while an option is being clicked', menu.__shown)
  local option = gui.dropdown_items[3]
  option.__scripts.OnMouseDown(option)
  check('clicked option is selected', dropdown:GetIndex() == 3)
  check('menu closes after the click', not menu.__shown)
  rawset(menu, 'IsMouseOver', function() return false end)
  dropdown.focus_gain()
  dropdown.focus_loss()
  check('menu closes when focus leaves elsewhere', not menu.__shown)
end)

-- Posting: match the cheapest price by default, one step below it in undercut mode
try('undercut mode', function()
  local require = loadstring("select(2, ...) 'aux.test6'; return require")('auxForever', addon)
  local aux = require 'aux'
  local post = require 'aux.tabs.post'
  check('undercut mode is off by default', aux.account_data.post_undercut == false)
  check('default matches the cheapest price', post.undercut({unit_price = 88}, 1) == 88)
  post.set_undercut_mode(true)
  check('undercut mode goes one step below', post.undercut({unit_price = 88}, 1) == 87)
  check('own listing is never undercut', post.undercut({unit_price = 88, own = true}, 1) == 88)
  post.set_undercut_mode(false)
  check('turning it off matches again', post.undercut({unit_price = 88}, 1) == 88 and aux.account_data.post_undercut == false)
end)

fire('AUCTION_HOUSE_CLOSED')
print('done, errors: ' .. errors)
