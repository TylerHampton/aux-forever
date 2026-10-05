-- Run from the auxForever folder: lua5.1 ../tests/load_test.lua
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
    -- like the game: SetFont needs a font file and a height above 0
    if k == 'SetFont' then return function(self, a, b, c, d)
      local path, height = a, b
      if a == 'p' or a == 'h1' or a == 'h2' or a == 'h3' then path, height = b, c end -- SimpleHTML
      if type(path) ~= 'string' then error("bad argument #1 to 'SetFont'", 2) end
      if not height or height <= 0 then error('Invalid font height', 2) end
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
for i, q in ipairs{'Poor', 'Common', 'Uncommon', 'Rare', 'Epic'} do G['ITEM_QUALITY' .. (i - 1) .. '_DESC'] = q end
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

  -- the Cancel button next to Confirm cancels the quote and buys nothing
  local cancel_button
  for _, f in ipairs(frames) do if f.__text == 'Cancel' and not cancel_button then cancel_button = f end end -- the buy bar's is created first
  calls = {}
  bar.primary_click()
  fire('COMMODITY_PRICE_UPDATED', 6, 120)
  tick()
  check('Cancel button exists and is shown with a quote', cancel_button and cancel_button.__shown)
  -- the bar redraws every frame; hiding the button between mouse press and release loses the click
  local hides = 0
  rawset(cancel_button, 'Hide', function(self) hides = hides + 1; self.__shown = false end)
  tick(); tick()
  rawset(cancel_button, 'Hide', nil)
  check('Cancel button is not hidden while the quote is shown', hides == 0 and cancel_button.__shown)
  cancel_button.__scripts.OnClick(cancel_button, 'LeftButton')
  tick()
  check('Cancel button cancels the quote', calls[2] == 'cancel' and #calls == 2)
  check('Cancel button returns to Buy', bar.primary_label():find('^Buy') ~= nil)

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

-- Posting: match the cheapest price by default, one step below it in undercut mode.
-- Gear is priced in whole silver; trade goods can use copper.
try('undercut mode', function()
  local require = loadstring("select(2, ...) 'aux.test6'; return require")('auxForever', addon)
  local aux = require 'aux'
  local post = require 'aux.tabs.post'
  local post_env = loadstring("select(2, ...) 'aux.tabs.post'; return _M")('auxForever', addon)
  check('undercut mode is off by default', aux.account_data.post_undercut == false)
  post.set_undercut_mode(true)
  fire('AUCTION_HOUSE_SHOW')
  check('undercut mode starts off every time the auction house opens', aux.account_data.post_undercut == false)

  post_env.selected_item = {commodity = true, key = '2447:0'}
  check('trade goods: default matches the cheapest price', post.undercut({unit_price = 88}, 1) == 88)
  post.set_undercut_mode(true)
  check('trade goods: undercut goes 1 copper below', post.undercut({unit_price = 88}, 1) == 87)
  check('own listing is never undercut', post.undercut({unit_price = 88, own = true}, 1) == 88)

  post_env.selected_item = {commodity = false, key = '15248:0'}
  check('gear: undercut goes 1 silver below', post.undercut({unit_price = 21000}, 1) == 20900)
  check('gear: never below 1 silver', post.undercut({unit_price = 100}, 1) == 100)
  check('gear: prices round down to whole silver', post.round_price(20947) == 20900 and post.round_price(40) == 100)
  post.set_undercut_mode(false)
  check('gear: default matches the cheapest price', post.undercut({unit_price = 21000}, 1) == 21000)

  local copper = C_AuctionHouse.SupportsCopperValues
  C_AuctionHouse.SupportsCopperValues = function() return false end
  post_env.selected_item = {commodity = true, key = '2447:0'}
  post.set_undercut_mode(true)
  check('trade goods without copper: 1 silver below', post.undercut({unit_price = 8800}, 1) == 8700)
  C_AuctionHouse.SupportsCopperValues = copper
  post.set_undercut_mode(false)
  check('turning it off matches again', post.undercut({unit_price = 88}, 1) == 88 and aux.account_data.post_undercut == false)
  post_env.selected_item = nil
end)

-- The status bar is amber only while something loads, dim gray when idle
try('status bar idle color', function()
  local require = loadstring("select(2, ...) 'aux.test7'; return require")('auxForever', addon)
  local gui = require 'aux.gui'
  local bar = gui.status_bar(new_frame())
  local color
  rawset(bar.primary_status_bar, 'SetStatusBarColor', function(_, r) color = r end)
  bar:update_status(0, 0)
  check('amber while loading', color == .89)
  bar:update_status(1, 1)
  check('gray when idle', color == .30)
  bar:set_done(true)
  check('gold when a search has finished', color == .23)
  bar:update_status(0, 0)
  check('amber again while loading', color == .89)
  bar:update_status(1, 1)
  bar:set_done(false)
  check('gray after leaving the search', color == .30)

  -- the search tab turns it gold for a finished search shown in the results, and off when leaving
  local aux = require 'aux'
  local search = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  search.frame:Show()
  search.new_search('light feather/exact', search.NORMAL_MODE or 1)
  search.set_subtab(search.RESULTS)
  check('new search is not gold', not aux.status_bar.done)
  search.current_search().complete = true
  search.update_done()
  check('finished search is gold', aux.status_bar.done)
  search.set_subtab(search.SAVED)
  check('leaving to saved searches ends gold', not aux.status_bar.done)
  search.set_subtab(search.RESULTS)
  check('back on the results it is gold again', aux.status_bar.done)
  search.new_search('copper ore/exact', search.NORMAL_MODE or 1)
  check('a new search ends gold', not aux.status_bar.done)
  search.previous_search()
  check('going back to the finished search is gold', aux.status_bar.done)
  search.frame:Hide()
  search.update_done()
  check('leaving the search tab ends gold', not aux.status_bar.done)
end)

-- Quick search menu: pinned (favorites) and recent searches with the last price seen
try('quick searches', function()
  local require = loadstring("select(2, ...) 'aux.test8'; return require")('auxForever', addon)
  local search = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local recent, favorites = search.recent_searches, search.favorite_searches
  while tremove(recent) do end
  while tremove(favorites) do end
  local copper = {filter_string = 'copper ore/exact', prettified = 'copper ore'}
  local cloth = {filter_string = 'cloth/20/30', prettified = 'cloth 20-30'}
  local hide = {filter_string = 'light hide/exact', prettified = 'light hide'}
  tinsert(recent, copper); tinsert(recent, cloth); tinsert(recent, hide)

  check('never searched shows a hint', search.quick_entry_detail(hide) == 'Search again to see prices')
  search.remember_search_result('copper ore/exact', {
    {item_id = 2770, unit_buyout_price = 300}, {item_id = 2770, unit_buyout_price = 277},
    {item_id = 2770, unit_buyout_price = 100, own = true}})
  check('cheapest price of other players is kept', copper.last_price == 277)
  check('single item search keeps the item', copper.item_id == 2770 and copper.last_time ~= nil)
  check('detail shows the cheapest price', search.quick_entry_detail(copper):find('^Cheapest') ~= nil)
  search.remember_search_result('cloth/20/30', {{item_id = 2589, unit_buyout_price = 50}, {item_id = 2996, unit_buyout_price = 900}})
  check('several items keep no item', cloth.item_id == nil and cloth.last_price == 50)
  search.remember_search_result('light hide/exact', {})
  check('nothing found has no price', hide.last_price == nil and hide.last_time ~= nil)

  local now = time()
  check('time: minutes', search.time_ago(now - 300) == '5m ago')
  check('time: hours', search.time_ago(now - 7200) == '2h ago')
  check('time: yesterday', search.time_ago(now - 90000) == 'yesterday')
  check('time: days', search.time_ago(now - 3 * 86400) == '3 days ago')

  search.frame:Show()
  search.toggle_quick_menu()
  check('menu opens', search.quick_menu.__shown)
  local function shown_rows()
    local n = 0
    for _, row in ipairs(search.quick_menu_rows) do if row.__shown then n = n + 1 end end
    return n
  end
  check('three recent rows', shown_rows() == 3)

  search.pin_search(cloth)
  check('pinned search is a favorite', favorites[1] == cloth and search.is_pinned(cloth))
  check('pinned search is listed once', shown_rows() == 3)
  search.pin_search(cloth)
  check('pinning twice adds nothing', #favorites == 1)
  search.unpin_search(cloth)
  check('unpinned search is no longer a favorite', #favorites == 0 and not search.is_pinned(cloth))
  local old = {filter_string = 'linen cloth/exact', prettified = 'linen cloth'}
  tinsert(favorites, old)
  search.unpin_search(old)
  check('unpinning a search that is not recent keeps it in recent', recent[1] == old)

  local row = search.quick_menu_rows[1]
  row.__scripts.OnClick(row)
  check('clicking a row closes the menu', not search.quick_menu.__shown)
  check('clicking a row searches it', search.search_box:GetText() == row.entry.filter_string)
  search.toggle_quick_menu()
  search.frame:Hide()
  check('menu closes with the search tab', not search.quick_menu.__shown)
end)

-- The back and forward arrows never disappear; they fade when there is nowhere to go
try('history arrows', function()
  local search = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local state = {}
  for _, name in ipairs{'previous_button', 'next_button'} do
    local b = search[name]
    state[name] = {}
    rawset(b, 'Enable', function() state[name].enabled = true end)
    rawset(b, 'Disable', function() state[name].enabled = false end)
    rawset(b, 'SetAlpha', function(_, a) state[name].alpha = a end)
    rawset(b, 'Hide', function() state[name].hidden = true end)
  end
  search.new_search('copper ore/exact', search.NORMAL_MODE or 1)
  search.new_search('light hide/exact', search.NORMAL_MODE or 1)
  check('newest search: forward faded, not hidden', state.next_button.enabled == false and state.next_button.alpha < 1 and not state.next_button.hidden)
  check('newest search: back works', state.previous_button.enabled == true and state.previous_button.alpha == 1)
  search.previous_search()
  check('after going back: forward works', state.next_button.enabled == true and state.next_button.alpha == 1)
  for _, name in ipairs{'previous_button', 'next_button'} do
    for _, k in ipairs{'Enable', 'Disable', 'SetAlpha', 'Hide'} do rawset(search[name], k, nil) end
  end
end)

-- Background opacity: only backgrounds fade, never below 70%
try('background opacity', function()
  local require = loadstring("select(2, ...) 'aux.test9'; return require")('auxForever', addon)
  local aux = require 'aux'
  local gui = require 'aux.gui'
  local panel = gui.panel(new_frame())
  local alpha
  rawset(panel, 'SetBackdropColor', function(_, r, g, b, a) alpha = a end)
  aux.set_background_opacity(.85)
  check('opacity is saved', math.abs(aux.account_data.background_opacity - .85) < .001)
  check('panel background fades', math.abs(alpha - .85) < .001)
  aux.set_background_opacity(.2)
  check('opacity never goes below 50%', math.abs(aux.account_data.background_opacity - .5) < .001 and math.abs(alpha - .5) < .001)
  aux.set_background_opacity(1.5)
  check('opacity never goes above 100%', aux.account_data.background_opacity == 1)
  SlashCmdList.AUX('opacity 80')
  check('/aux opacity 80 sets 80%', math.abs(aux.account_data.background_opacity - .8) < .001)
  local button = gui.button(new_frame())
  local button_alpha
  rawset(button, 'SetBackdropColor', function(_, r, g, b, a) button_alpha = a end)
  aux.set_background_opacity(.5)
  check('buttons are not faded', button_alpha == nil)
  aux.set_background_opacity(1)
end)

-- Post tab panel: summary, note under the price, duration buttons, mode switch
try('post panel', function()
  local require = loadstring("select(2, ...) 'aux.test10'; return require")('auxForever', addon)
  local aux = require 'aux'
  local post = loadstring("select(2, ...) 'aux.tabs.post'; return _M")('auxForever', addon)
  local function text(region) return region.__text end
  local function plain(t) return ((t or ''):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('FONT_COLOR_CODE_CLOSE', '')) end

  post.selected_item = {commodity = true, key = '3385:0', item_id = 3385, name = 'Minor Mana Potion', quality = 1, count = 3, max_stack = 5}
  post.stack_size_input:SetNumber(3); post.stack_size_input.__number = 3
  rawset(post.stack_size_input, 'GetNumber', function() return 3 end)
  rawset(post.stack_count_input, 'GetNumber', function() return 2 end)
  post.set_unit_buyout_price(69)
  post.update_item_configuration()
  check('trade good: posts stack size x stacks', post.post_quantity() == 6)
  check('item name without brackets', text(post.item.name) == 'Minor Mana Potion')
  check('bags shown, no stacks for trade goods', plain(text(post.item_detail)):find('3 in your bags') ~= nil and plain(text(post.item_detail)):find('stack of') == nil)
  check('posting line', plain(text(post.posting_summary)) == 'Posting 6 items')
  check('post button says what it posts', text(post.post_button) == 'Post 6 items')
  check('total and what you get are shown', text(post.total_summary):find('^Total') ~= nil and text(post.net_summary):find('^You get') ~= nil)
  check('the cut is 5%', post.AUCTION_CUT == .05)
  local colors = {}
  rawset(post.post_button, 'GetFontString', function(self) return self.label end)
  rawset(post.post_button.label, 'SetTextColor', function(_, r) colors[#colors + 1] = r end)
  post.post_button:Enable(); post.post_button:Disable()
  check('post button keeps its dark text', colors[#colors] < .2 and colors[#colors - 1] < .2)

  check('typed price note', plain(post.price_note_text()) == 'Your own price')
  post.set_buyout_selection({unit_price = 69})
  post.set_undercut_mode(false)
  check('match note', plain(post.price_note_text()):find('^Same as the lowest listing') ~= nil)
  post.set_undercut_mode(true)
  check('undercut note for trade goods', plain(post.price_note_text()):find('^1 copper below') ~= nil)
  post.selected_item.commodity = false
  check('undercut note for gear', plain(post.price_note_text()):find('^1 silver below') ~= nil and plain(post.price_note_text()):find('whole silver') ~= nil)
  post.set_undercut_mode(false)
  post.set_buyout_selection({unit_price = 69, own = true})
  check('own listing note', plain(post.price_note_text()):find('your own listing') ~= nil)
  post.set_buyout_selection()

  post.update_item_configuration()
  check('gear posts one per count', post.post_quantity() == 2)
  check('gear hides stack size', post.stack_size_input.__shown == false)
  check('gear count caption', text(post.stack_count_input.caption) == 'Count')

  local changed = 0
  local original = post.duration_dropdown.selection_change
  post.duration_dropdown.selection_change = function() changed = changed + 1 end
  post.duration_dropdown:SetIndex(3)
  check('duration buttons select', post.duration_dropdown:GetIndex() == 3 and changed == 1)
  post.duration_dropdown:SetIndex(3)
  check('same duration again changes nothing', changed == 1)
  post.duration_dropdown.buttons[1].__scripts.OnClick(post.duration_dropdown.buttons[1])
  check('clicking 2h selects it', post.duration_dropdown:GetIndex() == 1)
  post.duration_dropdown.selection_change = original

  local undercut_button = post.mode_switch.undercut_button
  undercut_button.__scripts.OnClick(undercut_button)
  check('switch turns undercut on', aux.account_data.post_undercut == true)
  post.mode_switch.match_button.__scripts.OnClick(post.mode_switch.match_button)
  check('switch turns it off', aux.account_data.post_undercut == false)
  post.selected_item = nil
  post.update_item_configuration()
  check('no item: post button plain', text(post.post_button) == 'Post')
end)

-- Post: once an item's listings are in, the price starts at the lowest listing (or one step below)
try('post auto price', function()
  local require = loadstring("select(2, ...) 'aux.test11'; return require")('auxForever', addon)
  local aux = require 'aux'
  local post = loadstring("select(2, ...) 'aux.tabs.post'; return _M")('auxForever', addon)
  post.clear_auctions()
  local function listing(price, own)
    post.record_auction({item_key = '4422:0', commodity = true, unit_buyout_price = price, count = 5, duration = 2, owner = own and 'P' or 'Someone'})
  end
  listing(300); listing(240); listing(290)
  local item = {key = '4422:0', item_id = 4422, commodity = true, name = 'Scroll of Stamina', quality = 1, count = 2, max_stack = 5}
  post.set_undercut_mode(false)
  post.update_item(item)
  post.set_unit_buyout_price(30000) -- the price remembered from last time
  post.on_update()
  check('starts at the lowest listing', post.get_unit_buyout_price() == 240)
  check('the lowest listing is selected', post.get_buyout_selection() and post.get_buyout_selection().unit_price == 240)
  post.set_undercut_mode(true)
  post.on_update()
  check('undercut mode goes one step below the lowest', post.get_unit_buyout_price() == 239)
  post.set_undercut_mode(false)
  post.set_buyout_selection()
  post.set_unit_buyout_price(500)
  post.on_update()
  check('a typed price is kept', post.get_unit_buyout_price() == 500)
  post.update_item(item)
  post.on_update()
  check('loading the item again starts at the lowest again', post.get_unit_buyout_price() == 240)

  -- the status bar is gold once the listings are in, and back to normal on leaving the tab
  aux.set_tab(2)
  post.update_item(item)
  check('post: gold once the listings are in', aux.status_bar.done == true)
  local plain = function(t) return ((t or ''):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('FONT_COLOR_CODE_CLOSE', '')) end
  post.update_item_configuration()
  check('deposit shown as money going out', plain(post.deposit.__text):find('^Deposit %-') ~= nil)
  check('you get shown in green', post.net_summary.__text:find('You get ', 1, true) == 1 and post.net_summary.__text:upper():find('6FD39A', 1, true) ~= nil)
  aux.set_tab(3)
  check('post: leaving the tab ends gold', aux.status_bar.done == false)
  post.selected_item = nil
end)

-- Post: per-item amount and the vendor warning under "You get"; deposit explained on mouse over
try('post money details', function()
  local require = loadstring("select(2, ...) 'aux.test12'; return require")('auxForever', addon)
  local post = loadstring("select(2, ...) 'aux.tabs.post'; return _M")('auxForever', addon)
  local plain = function(t) return ((t or ''):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('FONT_COLOR_CODE_CLOSE', '')) end
  post.selected_item = {commodity = true, key = '765:0', item_id = 765, name = 'Silverleaf', quality = 1, count = 20, max_stack = 20, unit_vendor_price = 5}
  rawset(post.stack_size_input, 'GetNumber', function() return 10 end)
  rawset(post.stack_count_input, 'GetNumber', function() return 2 end)
  post.set_unit_buyout_price(100)
  post.update_item_configuration()
  check('per item amount shown for several items', plain(post.net_detail.__text):find('each') ~= nil)
  check('no vendor warning when the auction house pays more', plain(post.net_detail.__text):find('vendor') == nil)
  post.set_unit_buyout_price(4)
  post.update_item_configuration()
  check('vendor warning when a vendor pays more', plain(post.net_detail.__text):find('a vendor pays') ~= nil)
  check('you get turns red below vendor price', post.net_summary.__text:upper():find('FF0000', 1, true) ~= nil)
  rawset(post.stack_count_input, 'GetNumber', function() return 1 end)
  rawset(post.stack_size_input, 'GetNumber', function() return 1 end)
  post.set_unit_buyout_price(100)
  post.update_item_configuration()
  check('no per item line for a single item', post.net_detail.__text == '')
  rawset(post.stack_size_input, 'GetNumber', nil); rawset(post.stack_count_input, 'GetNumber', nil)
  post.selected_item = nil
end)

-- Tables: level first, units for sale, and no Bid column when every row is a trade good
try('table columns', function()
  local require = loadstring("select(2, ...) 'aux.test13'; return require")('auxForever', addon)
  local al = require 'aux.gui.auction_listing'
  for name, columns in pairs{search = al.search_columns, auctions = al.auctions_columns, bids = al.bids_columns} do
    check(name .. ': level is the first column', columns[1].title == 'Lvl')
    check(name .. ': item is second', columns[2].title == 'Item')
    local titles = {}
    for _, c in ipairs(columns) do titles[#titles + 1] = type(c.title) == 'table' and c.title[1] or c.title end
    local joined = table.concat(titles, '|')
    check(name .. ': no Auctions or Stack Size column', not joined:find('Auctions|', 1, true) and not joined:find('Stack', 1, true))
  end
  check('search: For sale column', al.search_columns[3].title == 'For sale')
  local cell = {text = new_frame()}
  al.search_columns[3].fill(cell, {count = 1032}, 1032, 0, false)
  check('for sale shows units', cell.text.__text == 1032)
  al.search_columns[3].fill(cell, {count = 1}, 6, 2, false)
  check('for sale shows your own units', tostring(cell.text.__text):find('(2)', 1, true) ~= nil)

  local rt = al.new(new_frame(), 19, al.search_columns)
  local function bid_hidden() return rt.hide_bid == true end
  rt:SetDatabase({{commodity = true, count = 20, item_key = 'a', search_signature = 'a1', name = 'A', requirement = 0, unit_buyout_price = 7, buyout_price = 140, unit_bid_price = 0, bid_price = 0, duration = 2, sniping_signature = 'x'}})
  check('bid column hidden for trade goods only', bid_hidden())
  rt:SetDatabase({{commodity = true, count = 20, item_key = 'a', search_signature = 'a1', name = 'A', requirement = 0, unit_buyout_price = 7, buyout_price = 140, unit_bid_price = 0, bid_price = 0, duration = 2},
                  {count = 1, auction_count = 3, item_key = 'b', search_signature = 'b1', name = 'B', requirement = 10, unit_buyout_price = 900, buyout_price = 900, unit_bid_price = 500, bid_price = 500, high_bid = 0, duration = 3}})
  check('bid column shown when gear is in the results', not bid_hidden())
end)

-- Post price lists: units for sale, time left, price, % of usual
try('post listing columns', function()
  local require = loadstring("select(2, ...) 'aux.test14'; return require")('auxForever', addon)
  local post = loadstring("select(2, ...) 'aux.tabs.post'; return _M")('auxForever', addon)
  local data
  rawset(post.buyout_listing, 'SetData', function(_, rows) data = rows end)
  post.clear_auctions()
  post.record_auction({item_key = '2589:0', commodity = true, unit_buyout_price = 40, count = 206, duration = 3, owner = 'Someone'})
  post.selected_item = {commodity = true, key = '2589:0', item_id = 2589, name = 'Linen Cloth', quality = 1, count = 20, max_stack = 20}
  post.update_auction_listings()
  check('post list has four columns', data and data[1] and #data[1].cols == 4)
  check('post list first column is units for sale', data and data[1] and data[1].cols[1].value == 206)
  rawset(post.buyout_listing, 'SetData', nil)
  post.selected_item = nil
end)

fire('AUCTION_HOUSE_CLOSED')
-- Posting gear: the server refuses a buyout that is not above the starting bid ("Internal auction
-- error"), so a bid equal to the buyout is left out and the item goes up for buyout only.
try('post item prices', function()
  local require = loadstring("select(2, ...) 'aux.test15'; return require")('auxForever', addon)
  local post = loadstring("select(2, ...) 'aux.tabs.post'; return _M")('auxForever', addon)
  post.selected_item = {key = '5210:0', item_id = 5210, name = 'Blazing Wand', quality = 2, count = 1, max_stack = 1}
  local bid, buyout = post.item_post_prices(700, 700)
  check('bid equal to buyout: buyout only', bid == nil and buyout == 700)
  bid, buyout = post.item_post_prices(900, 700)
  check('bid above buyout: buyout only', bid == nil and buyout == 700)
  bid, buyout = post.item_post_prices(500, 700)
  check('bid below buyout is kept', bid == 500 and buyout == 700)
  bid, buyout = post.item_post_prices(500, 0)
  check('no buyout: bid only', bid == 500 and buyout == nil)

  -- the post itself sends no bid when it would equal the buyout
  local args
  local real_post, real_find = C_AuctionHouse.PostItem, post.find_item_location
  C_AuctionHouse.PostItem = function(...) args = {n = select('#', ...), ...} return false end
  post.find_item_location = function() return 'bag slot' end
  rawset(post.stack_count_input, 'GetNumber', function() return 1 end)
  rawset(post.duration_dropdown, 'GetIndex', function() return 2 end)
  post.set_unit_start_price(700)
  post.set_unit_buyout_price(700)
  post.post_auction()
  check('PostItem called for gear', args ~= nil)
  check('PostItem gets no bid when it equals the buyout', args and args[4] == nil and args[5] == 700)
  C_AuctionHouse.PostItem, post.find_item_location = real_post, real_find
  rawset(post.stack_count_input, 'GetNumber', nil); rawset(post.duration_dropdown, 'GetIndex', nil)
  post.selected_item = nil
end)

-- Filter Builder: aux's and/or/not post filter as a tree of groups and back, and in words
try('filter builder model', function()
  local require = loadstring("select(2, ...) 'aux.test16'; return require")('auxForever', addon)
  local filter_util = require 'aux.util.filter'
  local s = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local function roundtrip(str)
    local parsed = filter_util.parse_filter_string(str)
    return s.post_string(s.tree_from_post(parsed.post)), s.tree_from_post(parsed.post)
  end
  check('single condition', roundtrip('price/5g') == 'price/5g')
  local out, root = roundtrip('or/price/5g/percent/60')
  check('or at the top shows as Match Any', root.mode == 'or' and #root.items == 2)
  check('or at the top writes back with a count', out == 'or2/price/5g/percent/60')
  check('not on a condition', roundtrip('not/price/5g') == 'not/price/5g')
  out, root = roundtrip('price/5g/not/or2/seller/bob/left/30m')
  check('negated group is one item', #root.items == 2 and root.items[2].kind == 'group' and root.items[2].negated and root.items[2].mode == 'or')
  check('negated group writes back', out == 'price/5g/not/or2/seller/bob/left/30m')
  out = roundtrip('or/and2/profit/5g/percent/60/and3/bid-profit/5g/bid-percent/60/left/30m')
  check("Simon's example keeps its meaning", out == 'or2/and2/profit/5g/percent/60/and3/bid-profit/5g/bid-percent/60/left/30m')
  check('a bare and over everything is the same as the top level', roundtrip('and/price/5g/percent/60') == 'price/5g/percent/60')
  local words = s.post_words(s.tree_from_post(filter_util.parse_filter_string('price/5g/not/or2/seller/bob/left/30m').post))
  check('in words: not and or read out', words and words:find('NOT (', 1, true) and words:find(' OR ', 1, true) and words:find(' AND ', 1, true))
  local g = s.new_group('and')
  local c = s.new_condition('price'); c.value = 'abc'
  tinsert(g.items, c)
  tinsert(g.items, s.new_condition('utilizable'))
  check('an unfinished condition is left out', s.post_string(g) == 'utilizable')
  c.value = '1.5g'
  check('money is written the aux way', s.post_string(g) == 'price/1g 50s/utilizable')
  local empty_group = s.new_group('or')
  tinsert(g.items, empty_group)
  check('an empty group is left out', s.post_string(g) == 'price/1g 50s/utilizable')
  check('every post filter has a menu entry', (function()
    for key in pairs(filter_util.filters) do
      local found
      for _, info in ipairs(s.CONDITIONS) do if info.key == key then found = true end end
      if not found then return false end
    end
    return true
  end)())
end)

-- Favorites: an empty search bar saves nothing, and a search is saved once
try('favorites', function()
  local s = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local before = #s.favorite_searches
  check('empty search is not saved', s.add_favorite('') == 'empty' and s.add_favorite('   ') == 'empty' and #s.favorite_searches == before)
  check('a search is saved', s.add_favorite('copper ore/exact') == 'saved' and #s.favorite_searches == before + 1)
  check('the same search again is not', s.add_favorite('Copper Ore/exact') == 'duplicate' and #s.favorite_searches == before + 1)
  tremove(s.favorite_searches, 1)
end)

-- Settings: default auction length
try('auction length setting', function()
  local a = loadstring("select(2, ...) 'aux'; return _M")('auxForever', addon)
  local buttons = a.auction_length_buttons
  check('three auction length buttons', buttons and #buttons == 3)
  buttons[3].__scripts.OnClick(buttons[3])
  check('choosing one sets the default length', a.account_data.post_duration == 3)
  buttons[2].__scripts.OnClick(buttons[2])
  check('and back', a.account_data.post_duration == 2)
end)

-- Filter Builder: rows follow the search bar, and every edit rewrites the search bar
try('filter builder ui', function()
  local s = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local function shown_rows()
    local list = {}
    for _, row in ipairs(s.builder_rows) do if row.__shown and row.item then tinsert(list, row) end end
    return list
  end
  local function find_row(fn) for _, row in ipairs(shown_rows()) do if fn(row.item) then return row end end end
  local function click(widget) widget.__scripts.OnClick(widget) end
  local function pick(value)
    for _, b in ipairs(s.builder_menu_buttons) do if b.__shown and b.value == value then click(b) return true end end
  end
  local text = function() return s.search_box:GetText() end

  s.search_box:SetText('price/5g/not/or2/seller/bob/left/30m')
  s.set_subtab(s.FILTER)
  local rows = shown_rows()
  check('rows: condition, group, two inside, two add rows', #rows == 6)
  check('first row is the price condition', rows[1].item.kind == 'cond' and rows[1].type_btn.__text == 'Price per item' and rows[1].value_box.__text == '5g')
  check('group row is negated and Any', rows[2].item.kind == 'group' and rows[2].item.node.negated and rows[2].item.node.mode == 'or')
  check('in words shown', tostring(s.builder_words_text.__text):find('NOT (', 1, true) ~= nil)
  check('loading does not rewrite the search bar', text() == 'price/5g/not/or2/seller/bob/left/30m')

  click(rows[1].not_btn)
  check('not switch writes not', text() == 'not/price/5g/not/or2/seller/bob/left/30m')
  click(find_row(function(i) return i.kind == 'cond' and i.node.filter == 'price' end).not_btn)

  local root_add = find_row(function(i) return i.kind == 'add' and i.group == s.get_builder_root() end)
  click(root_add.add_cond)
  check('condition menu lists every filter', #s.builder_menu_buttons >= 18)
  check('picking a condition adds a row', pick('percent'))
  local pct = find_row(function(i) return i.kind == 'cond' and i.node.filter == 'percent' end)
  check('new condition row', pct ~= nil)
  check('unfinished condition stays out of the search bar', text() == 'price/5g/not/or2/seller/bob/left/30m')
  pct.value_box:SetText('60')
  pct.value_box.change(pct.value_box, true)
  check('typing a value writes it', text() == 'price/5g/not/or2/seller/bob/left/30m/percent/60')

  local left = find_row(function(i) return i.kind == 'cond' and i.node.filter == 'left' end)
  click(left.value_btn)
  check('choice menu', pick('2h'))
  check('choice written', text():find('left/2h', 1, true) ~= nil)

  click(find_row(function(i) return i.kind == 'group' end).remove)
  check('removing a group removes its conditions', text() == 'price/5g/percent/60')
  click(s.root_any_button)
  check('Match any at the top', text() == 'or2/price/5g/percent/60')
  click(s.root_all_button)

  root_add = find_row(function(i) return i.kind == 'add' and i.group == s.get_builder_root() end)
  click(root_add.add_group)
  local inner_add = find_row(function(i) return i.kind == 'add' and i.group ~= s.get_builder_root() end)
  check('a new group has its own add row', inner_add ~= nil)
  click(inner_add.add_cond); pick('seller')
  local seller = find_row(function(i) return i.kind == 'cond' and i.node.filter == 'seller' end)
  check('condition added inside the group', seller and seller.item.depth == 1)
  seller.value_box:SetText('Bob'); seller.value_box.change(seller.value_box, true)
  check('a group with one condition is written without and/or', text() == 'price/5g/percent/60/seller/bob')

  s.search_box:SetText('price/3g')
  s.search_box.change(s.search_box, true)
  rows = shown_rows()
  check('typing in the search bar updates the builder', #rows == 2 and rows[1].value_box.__text == '3g')
  s.search_box:SetText('price')
  s.search_box.change(s.search_box, true)
  check('unreadable search bar text is explained', tostring(s.builder_words_text.__text):find('cannot', 1, true) ~= nil)
  check('and the rows stay as they were', #shown_rows() == 2)

  s.search_box:SetText('copper ore/exact;linen cloth')
  s.load_builder()
  click(s.root_any_button)
  check('other searches after ; are kept', text():find(';linen cloth', 1, true) ~= nil)

  local favorites = #s.favorite_searches
  click(s.builder_clear_button)
  check('Clear all empties the search bar', text() == '' and #s.get_builder_root().items == 0)
  click(s.builder_save_button)
  check('saving an empty search saves nothing', #s.favorite_searches == favorites)
  s.set_subtab(s.SAVED)
end)

-- Search tab: result count on the sub tab, summary line next to the sub tabs, magnifier in the search bar
try('search results summary', function()
  local s = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local plain = function(t) return ((tostring(t or '')):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('FONT_COLOR_CODE_CLOSE', '')) end
  check('no summary without results', s.results_summary({records = {}}) == nil)
  local search = {records = {{item_key = 'a', count = 20, auction_count = 1}, {item_key = 'a', count = 1, auction_count = 6}, {item_key = 'a', count = 1000, auction_count = 6}}, complete = true, completed_at = time()}
  local text = s.results_summary(search)
  check('one item: price levels and units', text and text:find('3 price levels, 6,026 for sale', 1, true) ~= nil)
  local gear = {records = {{item_key = 'x', count = 1}, {item_key = 'x', count = 1}, {item_key = 'y', count = 1}}, complete = true, completed_at = time()}
  check('many items: items and units', s.results_summary(gear):find('^2 items, 3 for sale') ~= nil)
  check('sub tab number counts items', s.results_count(gear) == 2 and s.results_count(search) == 3)
  check('summary says when', text and text:find('searched just now', 1, true) ~= nil)
  search.active, search.complete = true, false
  check('summary while searching', s.results_summary(search):find('still searching', 1, true) ~= nil)
  check('one price level', s.results_summary({records = {{count = 5}}}):find('^1 price level, 5 for sale') ~= nil)

  s.set_subtab(s.RESULTS)
  local current = s.current_search()
  local saved = current.records
  current.records = {{item_key = 'a', count = 3}, {item_key = 'a', count = 2}}
  current.complete, current.completed_at, current.active = true, time(), false
  s.update_results_summary(true)
  check('result count on the sub tab', plain(s.search_results_button.__text) == 'Search Results  2')
  check('summary line shown on Results', s.results_summary_label.__text:find('2 price levels, 5 for sale', 1, true) ~= nil)
  s.set_subtab(s.SAVED)
  check('summary hidden on other sub tabs', s.results_summary_label.__text == '')
  check('count stays on the sub tab', plain(s.search_results_button.__text) == 'Search Results  2')
  current.records = saved
  s.update_results_summary(true)
  check('magnifier in the search bar', s.search_icon ~= nil)
end)

-- Post: trade goods are one listing on Forever, so one Quantity box, and Max is everything in the bags
try('post quantity', function()
  local post = loadstring("select(2, ...) 'aux.tabs.post'; return _M")('auxForever', addon)
  post.selected_item = {commodity = true, key = '7076:0', item_id = 7076, name = 'Blood Shard', quality = 1, count = 29, max_stack = 10}
  post.quantity_update(true)
  check('Max is everything in the bags', post.stack_count_input.max_value == 29)
  post.layout_parameters(true)
  check('the box is called Quantity', post.stack_count_input.caption.__text == 'Quantity')
  post.update_item_configuration()
  check('no stack size box', post.stack_size_input.__shown == false)
  post.layout_parameters(false)
  check('gear keeps Count', post.stack_count_input.caption.__text == 'Count')
  post.selected_item = nil
end)

-- Filter Builder: the builder keeps its own groups when it opens again, and All / Any fades when
-- there is nothing to choose between
try('filter builder keeps groups', function()
  local s = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  s.set_subtab(s.FILTER)
  s.clear_builder()
  local root = s.get_builder_root()
  root.mode = 'or'
  local g = s.new_group('and')
  local c1 = s.new_condition('price'); c1.value = '20s'
  local c2 = s.new_condition('item'); c2.value = 'linen cloth'
  tinsert(g.items, c1); tinsert(g.items, c2); tinsert(root.items, g)
  s.sync_builder(); s.update_builder()
  check('root switch faded with one group', s.root_any_button.idle == true)
  check('group switch active with two conditions', (function()
    for _, row in ipairs(s.builder_rows) do if row.__shown and row.item and row.item.kind == 'group' then return row.all_btn.idle == false end end
  end)())
  s.set_subtab(s.RESULTS)
  s.set_subtab(s.FILTER)
  check('the group is still a group after leaving and coming back', s.get_builder_root().items[1] == g and s.get_builder_root().mode == 'or')
  local g2 = s.new_group('and'); local c3 = s.new_condition('price'); c3.value = '3s'; tinsert(g2.items, c3); tinsert(root.items, g2)
  s.sync_builder(); s.update_builder()
  check('root switch active with two groups', s.root_any_button.idle == false)
  s.clear_builder()
  s.set_subtab(s.SAVED)
end)

-- Blizzard UI button: the Blizzard window comes to the front, the button shows its state, and the
-- hooks are installed even when another addon loaded Blizzard's auction house first
try('blizzard ui button', function()
  local a = loadstring("select(2, ...) 'aux'; return _M")('auxForever', addon)
  local raised, hooks = 0, {}
  rawset(AuctionHouseFrame, 'Raise', function() raised = raised + 1 end)
  rawset(AuctionHouseFrame, 'HookScript', function(self, script, fn) hooks[script] = (hooks[script] or 0) + 1 end)
  a.hook_blizzard_frame(); a.hook_blizzard_frame()
  check('the Blizzard window is hooked only once', hooks.OnShow == nil and hooks.OnHide == nil)
  local lit
  rawset(a.blizzard_button, 'SetBackdropBorderColor', function(self, r, g, b) lit = (r == a.color.blizzard()) end)
  a.blizzard_button.__scripts.OnClick(a.blizzard_button)
  check('Blizzard window shown and brought to the front', a.blizzard_frame_shown() and raised == 1)
  check('button lit while shown', lit == true)
  a.blizzard_button.__scripts.OnClick(a.blizzard_button)
  check('second click hides it', not a.blizzard_frame_shown() and lit == false)
  -- the game laid the window out while it was shrunk: 100 times too far, off screen
  local placed
  rawset(AuctionHouseFrame, 'GetPoint', function() return 'TOPLEFT', UIParent, 'TOPLEFT', 1600, -11600 end)
  rawset(AuctionHouseFrame, 'SetPoint', function(self, p, r, rp, x, y) placed = {x, y} end)
  a.blizzard_button.__scripts.OnClick(a.blizzard_button)
  check('an off screen window comes back where the layout meant it', placed and placed[1] == 16 and placed[2] == -116)
  placed = nil
  rawset(AuctionHouseFrame, 'GetPoint', function() return 'TOPLEFT', UIParent, 'TOPLEFT', 16, -2 end)
  a.blizzard_button.__scripts.OnClick(a.blizzard_button)
  a.blizzard_button.__scripts.OnClick(a.blizzard_button)
  check('a window in place is left alone', placed == nil)
  a.blizzard_button.__scripts.OnClick(a.blizzard_button)
  rawset(AuctionHouseFrame, 'GetPoint', nil); rawset(AuctionHouseFrame, 'SetPoint', nil)
  rawset(AuctionHouseFrame, 'Raise', nil); rawset(AuctionHouseFrame, 'HookScript', nil)
  rawset(a.blizzard_button, 'SetBackdropBorderColor', nil)
end)

-- Settings: scale from 70% to 150% that is kept, no explanation text; the resize corner anchors
-- the window by its top left corner before sizing
try('settings scale and resize corner', function()
  local a = loadstring("select(2, ...) 'aux'; return _M")('auxForever', addon)
  local scaled
  rawset(a.frame, 'SetScale', function(self, x) scaled = x end)
  a.change_window_scale(1.2)
  check('scale applied and kept', scaled == 1.2 and a.account_data.scale == 1.2)
  a.scale_buttons[2].__scripts.OnClick(a.scale_buttons[2])
  check('plus steps 5%', math.abs(a.account_data.scale - 1.25) < .001)
  a.change_window_scale(5)
  check('never above 150%', a.account_data.scale == 1.5)
  a.change_window_scale(.1)
  check('never below 70%', a.account_data.scale == .7)
  a.change_window_scale(1)
  check('scale values are cleaned up', a.clean_scale(1.31) == 1.3 and a.clean_scale('x') == 1)
  a.change_window_scale(1)
  rawset(a.frame, 'SetScale', nil)
  local anchored
  rawset(a.frame, 'SetPoint', function(self, point) anchored = point end)
  rawset(a.frame, 'StartSizing', function() sized_after = anchored end)
  sized_after = nil
  a.resize_grip.__scripts.OnMouseDown(a.resize_grip, 'LeftButton')
  check('resize corner anchors top left before sizing', sized_after == 'TOPLEFT')
  rawset(a.frame, 'SetPoint', nil); rawset(a.frame, 'StartSizing', nil)
end)

print('done, errors: ' .. errors)
