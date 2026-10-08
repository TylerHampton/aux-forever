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
  aux.set_tab(3) -- Search, Sniper, Post
  post.update_item(item)
  check('post: gold once the listings are in', aux.status_bar.done == true)
  local plain = function(t) return ((t or ''):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('FONT_COLOR_CODE_CLOSE', '')) end
  post.update_item_configuration()
  check('deposit shown as money going out', plain(post.deposit.__text):find('^Deposit %-') ~= nil)
  check('you get shown in green', post.net_summary.__text:find('You get ', 1, true) == 1 and post.net_summary.__text:upper():find('6FD39A', 1, true) ~= nil)
  aux.set_tab(4)
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
  -- the selected record stays selected when rows are added above it (Tyler, 0.4.1)
  local function grec(key, price) return {count = 1, item_key = key, search_signature = key, name = key, requirement = 0, unit_buyout_price = price, buyout_price = price, unit_bid_price = 0, bid_price = 0, high_bid = 0, duration = 2} end
  local ra, rb = grec('ka', 100), grec('kb', 200)
  local db = {ra, rb}
  rt:SetDatabase(db)
  rt:SetSelectedRecord(rb)
  tinsert(db, 1, grec('kc', 50))
  rt:SetDatabase(db)
  check('selection stays on the same record when rows are added', rt:GetSelection() and rt:GetSelection().record == rb)
  -- an auction with no starting bid shows no bid, not its buyout (Tyler, 0.4.1)
  local bid_col
  for i, c in ipairs(al.search_columns) do
    if type(c.title) == 'table' and c.title[1]:find('^Auction Bid') then bid_col = i end
  end
  local bcell = {text = new_frame()}
  al.search_columns[bid_col].fill(bcell, {count = 1, unit_buyout_price = 1200, buyout_price = 1200, unit_bid_price = 1200, bid_price = 1200, high_bid = 0})
  check('bid column: buyout only shows ---', bcell.text.__text == '---')
  al.search_columns[bid_col].fill(bcell, {count = 1, unit_buyout_price = 1200, buyout_price = 1200, unit_bid_price = 800, bid_price = 800, high_bid = 0})
  check('bid column: a real starting bid shows', tostring(bcell.text.__text):find('^8') ~= nil)
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

  -- Blizzard's tabs are measured again at full size when its window is shown
  local resized = {}
  local function tab(name)
    local t = new_frame(name)
    t.__scripts.OnShow = function(self) tinsert(resized, self.__name) end
    return t
  end
  rawset(AuctionHouseFrame, 'Tabs', {tab('Buy'), tab('Sell'), tab('Auctions')})
  local auctions_frame = new_frame('AuctionsFrame')
  rawset(auctions_frame, 'Tabs', {tab('Auctions sub'), tab('Bids sub')})
  rawset(AuctionHouseFrame, 'AuctionsFrame', auctions_frame)
  a.set_blizzard_frame_shown(true)
  check('Blizzard tabs are resized at full size', #resized == 5 and resized[1] == 'Buy' and resized[5] == 'Bids sub')
  resized = {}
  a.set_blizzard_frame_shown(false)
  check('tabs are not resized while hidden', #resized == 0)
  rawset(AuctionHouseFrame, 'Tabs', nil); rawset(AuctionHouseFrame, 'AuctionsFrame', nil)
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
  -- Tyler, 0.4.1: one click on the resize corner could make the whole window jump diagonally.
  -- aux sizes the window itself now: only a drag changes the size, by exactly the drag.
  local f, grip = a.frame, a.resize_grip
  local w, h, sizes, anchored = 1200, 600, 0, nil
  local cx, cy, down = 500, 300, true
  rawset(f, 'GetWidth', function() return w end); rawset(f, 'GetHeight', function() return h end)
  rawset(f, 'SetWidth', function(_, v) w = v; sizes = sizes + 1 end); rawset(f, 'SetHeight', function(_, v) h = v; sizes = sizes + 1 end)
  rawset(f, 'SetSize', function(_, x, y) w, h = x, y; sizes = sizes + 1 end)
  rawset(f, 'GetLeft', function() return 100 end); rawset(f, 'GetTop', function() return 900 end)
  rawset(f, 'GetEffectiveScale', function() return 1 end)
  rawset(UIParent, 'GetEffectiveScale', function() return 1 end)
  rawset(UIParent, 'GetWidth', function() return 1920 end); rawset(UIParent, 'GetHeight', function() return 1080 end)
  rawset(f, 'SetPoint', function(_, point) anchored = point end)
  rawset(f, 'StartSizing', function() anchored = 'game sizing' end)
  G.GetCursorPosition = function() return cx, cy end
  G.IsMouseButtonDown = function() return down end
  grip.__scripts.OnMouseDown(grip, 'LeftButton')
  check('resize corner anchors the window by its top left', anchored == 'TOPLEFT')
  for _ = 1, 3 do grip.__scripts.OnUpdate(grip) end
  grip.__scripts.OnMouseUp(grip)
  check('a click on the resize corner changes nothing', sizes == 0 and w == 1200 and h == 600)
  check('the drag stops with the click', grip.__scripts.OnUpdate == nil)
  down = true
  grip.__scripts.OnMouseDown(grip, 'LeftButton')
  cx, cy = 560, 260
  grip.__scripts.OnUpdate(grip)
  check('a drag resizes by exactly the drag', w == 1260 and h == 640)
  cx, cy = 5000, -5000
  grip.__scripts.OnUpdate(grip)
  check('the window stays on screen', w == 1820 and h == 900)
  down = false
  grip.__scripts.OnUpdate(grip)
  check('releasing the mouse anywhere ends the drag', grip.__scripts.OnUpdate == nil)
  for _, k in ipairs{'GetWidth', 'GetHeight', 'SetWidth', 'SetHeight', 'SetSize', 'GetLeft', 'GetTop', 'GetEffectiveScale', 'SetPoint', 'StartSizing'} do rawset(f, k, nil) end
  for _, k in ipairs{'GetEffectiveScale', 'GetWidth', 'GetHeight'} do rawset(UIParent, k, nil) end
  G.GetCursorPosition, G.IsMouseButtonDown = nil, nil
end)

-- Search timing log (/aux debug): the summary says where a search's time went
try('search timing log', function()
  local scan = loadstring("select(2, ...) 'aux.core.scan'; return _M")('auxForever', addon)
  local t = scan.new_timing()
  t.items, t.event, t.cached, t.timeout, t.dropped = 400, 380, 18, 2, 3
  t.browse, t.answer, t.throttle, t.item_data = 2, 150, 10, 5
  t.slow = {{name = 'Ritual Sandals', seconds = 21}, {name = 'Seer\'s Pants', seconds = 2}}
  local lines = scan.timing_report(t, 200)
  check('total and per item', lines[1] == 'Search timing: 3m 20s for 400 items, 0.50s each')
  check('where the time went', lines[2] == 'Waiting: item list 2.0s, server answers 2m 30s, throttle 10.0s, item data 5.0s, other 33.0s')
  check('how answers came', lines[3] == 'Answers: 380 on time, 18 after the 1s fallback, 2 timed out (20s each), 3 dropped and resent')
  check('slowest items first', lines[4] == 'Slowest: Ritual Sandals 21.0s, Seer\'s Pants 2.0s')
  check('stopped searches say so', scan.timing_report(scan.new_timing(), 1, true)[1]:find('(stopped)', 1, true) ~= nil)
  local a = loadstring("select(2, ...) 'aux'; return _M")('auxForever', addon)
  local before = a.account_data.debug_timing
  SlashCmdList.AUX('debug')
  check('/aux debug switches it', a.account_data.debug_timing == not before)
  SlashCmdList.AUX('debug')
end)

-- The timing log during a real search run: an item whose answer never comes as an event is
-- counted as answered after the 1s fallback, and the summary prints when the search ends
try('search timing during a search', function()
  local scan = loadstring("select(2, ...) 'aux.core.scan'; return _M")('auxForever', addon)
  local a = loadstring("select(2, ...) 'aux'; return _M")('auxForever', addon)
  local printed = {}
  local real_add = DEFAULT_CHAT_FRAME.AddMessage
  rawset(DEFAULT_CHAT_FRAME, 'AddMessage', function(_, text) tinsert(printed, text) end)
  local saved = {}
  for k, v in pairs{GetItemKeyInfo = function() return {isCommodity = false, itemName = 'Test Item'} end,
                    HasSearchResults = function() return true end, HasFullItemSearchResults = function() return true end,
                    GetNumItemSearchResults = function() return 0 end} do
    saved[k] = rawget(C_AuctionHouse, k); C_AuctionHouse[k] = v
  end
  local cached_saved = C_Item.IsItemDataCachedByID
  C_Item.IsItemDataCachedByID = function() return true end
  a.account_data.debug_timing = true
  local done
  scan.start{type = 'list', queries = {{blizzard_query = {}, item_keys = {{itemID = 4}}}}, on_complete = function() done = true end}
  for _ = 1, 40 do if done then break end tick() end
  a.account_data.debug_timing = false
  rawset(DEFAULT_CHAT_FRAME, 'AddMessage', real_add)
  for k in pairs(saved) do C_AuctionHouse[k] = saved[k] end
  C_Item.IsItemDataCachedByID = cached_saved
  local all = table.concat(printed, '\n')
  check('the search finished', done)
  check('summary printed after the search', all:find('Search timing:', 1, true) ~= nil and all:find('for 1 item,', 1, true) ~= nil)
  check('the 1s fallback is counted', all:find('0 on time, 1 after the 1s fallback', 1, true) ~= nil)
end)

-- /aux debug list: times the whole auction house's item list without opening items
try('item list measurement', function()
  local scan = loadstring("select(2, ...) 'aux.core.scan'; return _M")('auxForever', addon)
  local printed = {}
  local real_add = DEFAULT_CHAT_FRAME.AddMessage
  rawset(DEFAULT_CHAT_FRAME, 'AddMessage', function(_, text) tinsert(printed, text) end)
  local saved = {}
  for k, v in pairs{GetBrowseResults = function() return {{itemKey = {itemID = 1}}, {itemKey = {itemID = 2}}, {itemKey = {itemID = 3}}} end,
                    HasFullBrowseResults = function() return true end} do
    saved[k] = rawget(C_AuctionHouse, k); C_AuctionHouse[k] = v
  end
  local real_send = C_AuctionHouse.SendBrowseQuery
  local sent = 0
  -- the game answers a browse query with an event a moment later (so the request has to wait)
  local answer_due
  C_AuctionHouse.SendBrowseQuery = function() sent = sent + 1; answer_due = true end
  scan.measure_item_list()
  for _ = 1, 30 do
    tick()
    if answer_due then
      answer_due = false
      for _, f in ipairs(frames) do
        if f.__events['AUCTION_HOUSE_BROWSE_RESULTS_UPDATED'] and f.__scripts.OnEvent then
          f.__scripts.OnEvent(f, 'AUCTION_HOUSE_BROWSE_RESULTS_UPDATED')
        end
      end
    end
  end
  rawset(DEFAULT_CHAT_FRAME, 'AddMessage', real_add)
  for k in pairs(saved) do C_AuctionHouse[k] = saved[k] end
  C_AuctionHouse.SendBrowseQuery = real_send
  local all = table.concat(printed, '\n')
  check('one browse request sent', sent >= 1)
  check('the measurement is reported', all:find('Item list of the whole auction house: 3 items in', 1, true) ~= nil and all:find('(1 request)', 1, true) ~= nil)
  check('no false "did not answer"', all:find('did not answer', 1, true) == nil)
end)


-- 0.3: a fake auction house that answers a moment after each request, as the game does
local function fake_ah(items)
  local saved = {}
  local function set(t, k, v) tinsert(saved, {t, k, rawget(t, k)}); rawset(t, k, v) end
  local pending = {}
  local by_id = {}
  for _, it in ipairs(items) do by_id[it.id] = it end
  local function link(it) return '|cff1eff00|Hitem:' .. it.id .. '::::::' .. (it.suffix or 0) .. ':0|h[' .. it.name .. ']|h|r' end
  local browses = 0
  set(C_AuctionHouse, 'SendBrowseQuery', function() browses = browses + 1; tinsert(pending, {'AUCTION_HOUSE_BROWSE_RESULTS_UPDATED'}) end)
  set(C_AuctionHouse, 'HasFullBrowseResults', function() return true end)
  set(C_AuctionHouse, 'GetBrowseResults', function()
    local r = {}
    for _, it in ipairs(items) do
      if it.qty > 0 then tinsert(r, {itemKey = {itemID = it.id, itemSuffix = it.suffix or 0, itemLevel = 0}, totalQuantity = it.qty, minPrice = it.min, containsOwnerItem = false}) end
    end
    return r
  end)
  set(C_AuctionHouse, 'GetItemKeyInfo', function(key) local it = by_id[key.itemID]; return it and {itemID = it.id, itemName = it.name, quality = it.quality or 2, iconFileID = 1, isCommodity = it.commodity or false} end)
  set(C_AuctionHouse, 'GetItemKeyRequiredLevel', function(key) return by_id[key.itemID].req or 1 end)
  set(C_AuctionHouse, 'SendSearchQuery', function(key)
    local it = by_id[key.itemID]
    if it.commodity then tinsert(pending, {'COMMODITY_SEARCH_RESULTS_UPDATED', it.id}) else tinsert(pending, {'ITEM_SEARCH_RESULTS_UPDATED', key}) end
  end)
  set(C_AuctionHouse, 'HasSearchResults', function() return true end)
  set(C_AuctionHouse, 'HasFullItemSearchResults', function() return true end)
  set(C_AuctionHouse, 'HasFullCommoditySearchResults', function() return true end)
  set(C_AuctionHouse, 'GetNumItemSearchResults', function(key) return by_id[key.itemID].qty > 0 and #by_id[key.itemID].auctions or 0 end)
  set(C_AuctionHouse, 'GetNumCommoditySearchResults', function(id) return by_id[id].qty > 0 and #by_id[id].auctions or 0 end)
  set(C_AuctionHouse, 'GetItemSearchResultInfo', function(key, i)
    local it = by_id[key.itemID]; local a = it.auctions[i]
    return {itemKey = key, itemLink = link(it), auctionID = it.id * 100 + i, quantity = a.qty or 1, buyoutAmount = a.buyout, minBid = a.bid or 0, bidAmount = 0,
      owners = {a.own and 'player' or 'Seller'}, totalNumberOfOwners = 1, containsOwnerItem = a.own or false, timeLeft = 3}
  end)
  set(C_AuctionHouse, 'GetCommoditySearchResultInfo', function(id, i)
    local a = by_id[id].auctions[i]
    return {itemID = id, quantity = a.qty or 1, unitPrice = a.buyout, auctionID = id * 100 + i, owners = {'Seller'}, numOwnerItems = 0, timeLeftSeconds = 3600, totalNumberOfOwners = 1}
  end)
  set(G, 'GetItemInfo', function(x)
    local id = type(x) == 'number' and x or tonumber(tostring(x):match('item:(%d+)'))
    local it = by_id[id]
    if not it then return end
    return it.name, link(it), it.quality or 2, 10, it.req or 1, 'Armor', 'Cloth', it.stack or 1, 'INVTYPE_CHEST', 1, it.sell or 0
  end)
  set(C_Item, 'IsItemDataCachedByID', function() return true end)
  local function deliver()
    local list = pending; pending = {}
    for _, p in ipairs(list) do fire(p[1], p[2]) end
  end
  local function run(n) for _ = 1, n or 40 do tick(); deliver() end end
  local function restore() for i = #saved, 1, -1 do rawset(saved[i][1], saved[i][2], saved[i][3]) end end
  return run, restore, function() return browses end
end

try('fast mode choice', function()
  local search = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local require = loadstring("select(2, ...) 'aux.test30'; return require")('auxForever', addon)
  local filter = require 'aux.util.filter'
  local aux = require 'aux'
  check('price search is fast', search.fast_choice(filter.queries('herb/price/20s')) == true)
  check('percent and rarity are fast', search.fast_choice(filter.queries('robe/uncommon/percent/80')) == true)
  local fast, why = search.fast_choice(filter.queries('robe/seller/thrakk'))
  check('seller search reads every auction', fast == false and why == 'seller')
  fast, why = search.fast_choice(filter.queries('robe/left/30m'))
  check('time left search reads every auction', fast == false and why == 'time left')
  fast, why = search.fast_choice(filter.queries('robe/bid-price/1g'))
  check('bid search reads every auction', fast == false and why == 'bid')
  fast, why = search.fast_choice(filter.queries('robe/of the owl'))
  check('tooltip text search reads every auction', fast == false and why == 'tooltip text')
  fast, why = search.fast_choice(filter.queries('linen cloth/exact'))
  check('one exact item reads every auction', fast == false and why == nil)
  aux.account_data.full_search = true
  check('Full reads every auction', search.fast_choice(filter.queries('herb/price/20s')) == false)
  aux.account_data.full_search = false
end)

local ROBES = function()
  return {
    {id = 101, name = 'Spellbinder Robe', min = 18500, qty = 3, sell = 3000, auctions = {{buyout = 18500, bid = 15000}, {buyout = 21000, bid = 18000}, {buyout = 25000, bid = 20000}}},
    {id = 102, name = 'Greenweave Robe', min = 6400, qty = 2, auctions = {{buyout = 6400}, {buyout = 7000}}},
    {id = 103, name = 'Pagan Robe', min = 22000, qty = 1, auctions = {{buyout = 22000}}},
  }
end

try('fast search', function()
  local search = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local require = loadstring("select(2, ...) 'aux.test31'; return require")('auxForever', addon)
  local history = require 'aux.core.history'
  local run, restore = fake_ah(ROBES())
  search.frame:Show()
  search.update_mode(search.NORMAL_MODE)
  search.search_box:SetText('robe')
  search.execute(nil, false)
  run(40)
  local s = search.current_search()
  check('fast: the search finished', s.complete == true and s.fast == true)
  local rows = {}
  for _, r in ipairs(s.records) do rows[r.item_id] = r end
  check('fast: one row per item', #s.records == 3 and rows[101] and rows[101].fast)
  check('fast: a row has the lowest price and the units for sale', rows[101].unit_buyout_price == 18500 and rows[101].count * rows[101].auction_count == 3)
  check('fast: the row is named from the item list', rows[101].name == 'Spellbinder Robe' and rows[101].item_key == '101:0')
  check('fast: summary says fast', (search.results_summary(s) or ''):find('3 items, 6 for sale, fast', 1, true) ~= nil)
  check('fast: the list is not price history', history.value('101:0') == nil)
  search.open_item(s, rows[101])
  run(40)
  local robes, list_rows = 0, 0
  for _, r in ipairs(s.records) do
    if r.item_id == 101 then robes = robes + 1; if r.fast then list_rows = list_rows + 1 end end
  end
  check('fast: an opened item shows its auctions', robes == 3 and list_rows == 0)
  check('fast: the other items stay as list rows', (function() for _, r in ipairs(s.records) do if r.item_id == 102 then return r.fast end end end)())
  local selection = s.table:GetSelection()
  check('fast: the cheapest auction is selected for the buy bar', selection and selection.record.unit_buyout_price == 18500 and not selection.record.fast)
  check('fast: the opened item is expanded', s.table.expanded['101:0'] == true)
  check('fast: its auctions are price history', history.value('101:0') == 18500)

  -- a condition the list does not have: every auction is read, and the summary says why
  search.search_box:SetText('robe/seller/seller')
  search.execute(nil, false)
  run(60)
  s = search.current_search()
  check('full: a seller search reads every auction', s.fast == false and #s.records == 6 and not s.records[1].fast)
  check('full: summary says why', (search.results_summary(s) or ''):find('full (uses seller)', 1, true) ~= nil)
  search.frame:Hide()
  restore()
end)

try('live mode', function()
  local search = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local run, restore, browses = fake_ah(ROBES())
  search.frame:Show()
  search.update_mode(search.NORMAL_MODE)
  search.search_box:SetText('robe')
  search.toggle_live()
  local s = search.current_search()
  check('live: turning Live on runs the search', search.mode == search.LIVE_MODE and s.mode == search.LIVE_MODE and s.active)
  tick()
  check('live: "Updating" during a round', search.live_status(s) == 'updating' and search.mode_button:GetText() == 'Updating')
  run(20)
  local status, seconds = search.live_status(s)
  check('live: a countdown after the round', status == 'waiting' and seconds >= 1 and seconds <= search.LIVE_INTERVAL and s.live_round == 1)
  check('live: the button counts down', search.mode_button:GetText():find('^Live %ds$') ~= nil)
  check('live: summary says when the next round is', (search.results_summary(s) or ''):find('live: updated just now, next in', 1, true) ~= nil)
  run(70)
  check('live: the next round runs after the countdown', s.live_round >= 2)
  search.pause()
  check('live: Pause shows Paused', search.live_status(s) == 'paused')
  search.update_live_button()
  check('live: the button says Paused', search.mode_button:GetText() == 'Paused')
  check('live: Resume says Resume live', search.resume_button:GetText() == 'Resume live' and search.resume_button.__shown)
  local round = s.live_round
  run(80)
  check('live: no rounds while paused', s.live_round == round)
  search.execute(nil, true)
  run(20)
  check('live: Resume carries on', s.live_round > round and s.active)
  search.hold_live()
  round = s.live_round
  run(80)
  check('live: held while on another tab, not paused', s.live_round == round and search.live_status(s) ~= 'paused')
  search.resume_held_live()
  run(20)
  check('live: carries on when back on the tab', s.live_round > round)
  -- Tyler, 0.4.1: a live round during a trade good's price quote ended it with "Internal auction
  -- error"; live rounds wait while the buy bar is buying, and are held, not paused
  local live_req = loadstring("select(2, ...) 'aux.test50'; return require")('auxForever', addon)
  local live_bar = live_req 'aux.gui.buy_bar'
  local real_busy = live_bar.busy
  rawset(live_bar, 'busy', function() return true end)
  tick()
  round = s.live_round
  run(80)
  check('live: no round while buying', s.live_round == round and search.live_status(s) ~= 'paused')
  rawset(live_bar, 'busy', real_busy)
  run(30)
  check('live: rounds go on after the purchase', s.live_round > round)
  search.toggle_live()
  check('live: turning Live off stops it and keeps the results', s.mode == search.NORMAL_MODE and not s.active and #s.records > 0)
  local sent = browses()
  run(80)
  check('live: no more rounds once off', browses() == sent)
  search.update_live_button()
  check('live: the button says Live again', search.mode_button:GetText() == 'Live')
  -- Tyler, 0.4.1: a new search while Live is on (a saved recipe search) ends Live and runs
  search.search_box:SetText('robe')
  search.toggle_live()
  run(20)
  local old = search.current_search()
  local addon_aux = loadstring("select(2, ...) 'aux'; return _M")('auxForever', addon)
  addon_aux.account_data.full_search = true
  rawset(AuxTooltip, 'NumLines', function() return 0 end)
  search.set_filter('spellbinder robe/exact;greenweave robe/exact')
  search.execute()
  local new = search.current_search()
  check('live: a new search ends Live', search.mode == search.NORMAL_MODE and new ~= old and new.mode == search.NORMAL_MODE)
  run(60)
  check('live: the new search runs', #new.records > 0 and not old.active)
  sent = browses()
  run(80)
  check('live: the old search does not go on', browses() == sent)
  addon_aux.account_data.full_search = false
  rawset(AuxTooltip, 'NumLines', nil)
  -- the item data this search loaded is not left for later tests
  for _, it in ipairs(ROBES()) do
    addon_aux.account_data.items[it.id] = nil
    addon_aux.account_data.item_ids[strlower(it.name)] = nil
  end
  search.frame:Hide()
  restore()
end)

try('sniper deal rule', function()
  local sniper = loadstring("select(2, ...) 'aux.tabs.sniper'; return _M")('auxForever', addon)
  local reason, profit = sniper.judge(50, nil, 100, 0, 60, 50)
  check('below vendor price is a deal without history', reason == 'vendor' and profit == 50)
  check('a trivial profit below vendor price is not a deal', sniper.judge(50, nil, 100, 0, 60, 500) == nil)
  check('no deal against the usual price with under 3 days of history', sniper.judge(1000, 5000, 0, 2, 60, 500) == nil)
  reason, profit = sniper.judge(1000, 5000, 0, 3, 60, 500)
  check('a deal: 20% of usual, profit after the cut', reason == 'usual' and profit == 3750)
  check('not a deal above the percentage', sniper.judge(3100, 5000, 0, 5, 60, 500) == nil)
  check('not a deal under the minimum profit', sniper.judge(200, 600, 0, 5, 60, 500) == nil)
  local _, _, pct = sniper.judge(100, 50, 200, 5, 60, 0)
  check('the usual price is never below the vendor price', pct == 50)
end)

try('sniper round', function()
  local aux_require = loadstring("select(2, ...) 'aux.test32'; return require")('auxForever', addon)
  local aux = aux_require 'aux'
  local sniper = loadstring("select(2, ...) 'aux.tabs.sniper'; return _M")('auxForever', addon)
  local h = loadstring("select(2, ...) 'aux.core.history'; return _M")('auxForever', addon)
  local function days(key, value)
    local d = h.today()
    h.write_record(key, {day = d, points = {{value = value, day = d - 1}, {value = value, day = d - 2}, {value = value, day = d - 3}}})
  end
  days('201:0', 2200); days('203:0', 600); days('204:0', 5000)
  -- the kilt was only seen today: a usual price, but not one to show
  h.write_record('202:0', {day = h.today(), low = 1500, points = {}})
  local items = {
    {id = 201, name = 'Kingsblood', commodity = true, min = 850, qty = 41, sell = 50, stack = 20, auctions = {{buyout = 850, qty = 12}, {buyout = 900, qty = 29}}},
    {id = 202, name = 'Ritual Kilt', min = 1500, qty = 1, sell = 2200, auctions = {{buyout = 1500}}},
    {id = 203, name = 'Wool Cloth', commodity = true, min = 210, qty = 80, sell = 33, auctions = {{buyout = 210, qty = 80}}},
    {id = 204, name = 'Bid Only Robe', min = 1000, qty = 1, sell = 0, auctions = {{buyout = 0, bid = 1000}}},
  }
  local run, restore = fake_ah(items)
  aux.set_tab(2)
  check('sniper: second tab', sniper.frame.__shown)
  sniper.start()
  run(60)
  check('sniper: a round completed', sniper.round >= 1)
  local found = {}
  for _, deal in ipairs(sniper.deals) do found[deal.name] = deal end
  check('sniper: a trade good under its usual price', found.Kingsblood and found.Kingsblood.deal_reason == 'usual' and found.Kingsblood.unit_buyout_price == 850 and found.Kingsblood.deal_percent == 39)
  check('sniper: below vendor price', found['Ritual Kilt'] and found['Ritual Kilt'].deal_reason == 'vendor' and found['Ritual Kilt'].deal_profit == 700)
  check('sniper: no usual price shown without enough history', found['Ritual Kilt'].deal_usual == nil and found.Kingsblood.deal_usual == 2200)
  check('sniper: too little profit is not a deal', not found['Wool Cloth'])
  check('sniper: a bid shown as the lowest price is not a deal', not found['Bid Only Robe'])
  check('sniper: deals are in the table', #sniper.listing.records == 2)
  check('sniper: a commodity deal keeps its tiers to buy', found.Kingsblood.deal_tiers and #found.Kingsblood.deal_tiers == 2)
  items[2].qty = 0
  run(40)
  check('sniper: a deal that sold shows as gone', found['Ritual Kilt'].deal_gone == true and not found.Kingsblood.deal_gone)
  check('sniper: the count says how many are left and gone', sniper.deals_count(sniper.shown_deals()) == '1 to buy, 1 gone')
  -- Tyler, 0.4.1: deals that sold go to the bottom of the table
  local function shown_order()
    local out = {}
    for _, info in ipairs(sniper.listing.rowInfo) do tinsert(out, info.children[1].record) end
    return out
  end
  found.Kingsblood.deal_found, found['Ritual Kilt'].deal_found = 100, 200 -- the gone one is newer
  sniper.update_deals()
  local order = shown_order()
  check('sniper: a deal that sold sorts below the ones to buy', #order == 2 and not order[1].deal_gone and order[2].deal_gone)
  -- Tyler, 0.4 build 2: after a few rounds every deal vanished from the table, then came back. The
  -- game had dropped the items' data for a moment, and a deal without item data was hidden.
  local real_info = G.GetItemInfo
  G.GetItemInfo = function() end
  sniper.update_deals()
  check('sniper: deals stay listed while the game reloads item data', #sniper.listing.records == 2 and sniper.deals_count(sniper.shown_deals()) == '1 to buy, 1 gone')
  G.GetItemInfo = real_info
  sniper.update_deals()
  aux.account_data.sniper_profit = 800
  sniper.settings_changed()
  check('sniper: a gone deal under the current rule is hidden', #sniper.listing.records == 1 and sniper.listing.records[1].name == 'Kingsblood')
  aux.account_data.sniper_profit = 500
  sniper.settings_changed()
  -- buying a deal from the buy bar: the cheapest units first, never above the price shown
  local bar = aux_require 'aux.gui.buy_bar'
  sniper.listing:SetSelectedRecord(found.Kingsblood)
  -- the deal is read again first (Tyler, 0.4.1: trade good buys failed on old deals)
  run(10)
  check('sniper: a trade good deal is read again when selected', sniper.refreshing == nil and #found.Kingsblood.deal_tiers == 2)
  check('sniper: the buy bar offers the deal', bar.primary_label():find('^Buy 20 for') ~= nil)
  bar.primary_click()
  fire('COMMODITY_PRICE_UPDATED', 900, 17400)
  tick()
  check('sniper: the server price is confirmed only after a click', bar.primary_label():find('^Confirm') ~= nil)
  bar.primary_click()
  fire('COMMODITY_PURCHASE_SUCCEEDED')
  tick()
  check('sniper: once its price is bought up the deal shows as bought', found.Kingsblood.deal_bought == true and found.Kingsblood.deal_gone == true)
  check('sniper: the rest stays to buy at the next price', #found.Kingsblood.deal_tiers == 1 and found.Kingsblood.deal_tiers[1].count == 21)
  found.Kingsblood.deal_gone, found.Kingsblood.deal_bought = nil, nil
  sniper.listing:SetSelectedRecord()
  tick()
  aux.account_data.sniper_percent = 30
  sniper.settings_changed()
  check('sniper: a stricter rule hides deals that no longer pass', #sniper.listing.records == 1)
  aux.account_data.sniper_percent = 60
  sniper.settings_changed()
  sniper.ignore(found.Kingsblood)
  check('sniper: an ignored item is removed and remembered', sniper.ignored_count() == 1 and #sniper.shown_deals() == 1)
  run(40)
  local again
  for _, deal in ipairs(sniper.deals) do if deal.name == 'Kingsblood' then again = true end end
  check('sniper: an ignored item is not found again', not again)
  sniper.unignore_all()
  sniper.stop()
  local round = sniper.round
  run(60)
  check('sniper: no rounds after Stop', sniper.round == round)
  aux.set_tab(1)
  sniper.clear_deals()
  restore()
end)


-- Tyler, 0.4: memory grew from 8.6 to 26 MB over Sniper rounds. Judging an item must not unpack its
-- saved history again each round, nor touch history for items that have none.
try('sniper: judging items reuses the history cache', function()
  local req = loadstring("select(2, ...) 'aux.test42'; return require")('auxForever', addon)
  local persistence = req 'aux.util.persistence'
  local sniper = loadstring("select(2, ...) 'aux.tabs.sniper'; return _M")('auxForever', addon)
  local h = loadstring("select(2, ...) 'aux.core.history'; return _M")('auxForever', addon)
  local d = h.today()
  h.write_record('401:0', {day = d, points = {{value = 500, day = d - 1}, {value = 500, day = d - 2}, {value = 500, day = d - 3}}})
  local real_read, reads = persistence.read, 0
  rawset(persistence, 'read', function(...) reads = reads + 1; return real_read(...) end)
  local real_info = G.GetItemInfo
  G.GetItemInfo = function(id) return 'Thing', 'link', 2, 1, 1, 'Armor', 'Cloth', 1, '', 1, 77 end
  local usual, vendor, days = sniper.item_facts('401:0', 401)
  check('sniper facts: usual price, vendor price and days', usual == 500 and vendor == 77 and days == 3)
  reads = 0
  for _ = 1, 5 do sniper.item_facts('401:0', 401) end
  check('sniper facts: the saved history is not unpacked again', reads == 0)
  local real_new, built = h.new_record, 0
  h.new_record = function() built = built + 1; return real_new() end
  local u2, _, d2 = sniper.item_facts('402:0', 402)
  h.new_record = real_new
  check('sniper facts: an item without history reads and builds nothing', reads == 0 and built == 0 and u2 == nil and d2 == 0)
  rawset(persistence, 'read', real_read)
  G.GetItemInfo = real_info
end)

-- Tyler, 0.4: memory after a cleanup went from 8.1 MB at login to 16.4 MB after 23 Sniper rounds.
-- The Sniper may keep notes on each item once, but nothing may pile up round after round.
try('sniper: rounds keep no memory', function()
  local aux_require = loadstring("select(2, ...) 'aux.test43'; return require")('auxForever', addon)
  local aux = aux_require 'aux'
  local sniper = loadstring("select(2, ...) 'aux.tabs.sniper'; return _M")('auxForever', addon)
  local items = {}
  for i = 1, 2000 do
    tinsert(items, {id = 5000 + i, name = 'Item ' .. i, min = 1000, qty = 3, sell = 10, auctions = {{buyout = 1000}}})
  end
  local run, restore = fake_ah(items)
  aux.set_tab(2)
  sniper.start()
  local r0 = sniper.round
  local live = {}
  for _ = 1, 20000 do
    run(1)
    local r = sniper.round - r0
    if (r == 2 or r == 8) and not live[r] and not sniper.active then
      -- some prices change every round, so items are judged again
      for i = r, 2000, 7 do items[i].min = items[i].min + 1 end
      collectgarbage('collect')
      live[r] = collectgarbage('count')
    end
    if r >= 8 and live[8] then break end
  end
  check('sniper memory: measured at rounds 2 and 8', live[2] and live[8])
  check('sniper memory: no growth from round 2 to round 8', live[2] and live[8] and live[8] - live[2] < 64)
  sniper.stop()
  aux.set_tab(1)
  restore()
end)

-- Tyler, 0.4: the first round at 1c profit played the sound about 40 times before any deal showed
try('sniper: one sound per burst, deals shown during the round, no timing lines', function()
  local aux_require = loadstring("select(2, ...) 'aux.test41'; return require")('auxForever', addon)
  local aux = aux_require 'aux'
  local sniper = loadstring("select(2, ...) 'aux.tabs.sniper'; return _M")('auxForever', addon)
  local items = {}
  for i = 1, 6 do
    tinsert(items, {id = 300 + i, name = 'Cheap Thing ' .. i, min = 100, qty = 1, sell = 900, auctions = {{buyout = 100}}})
  end
  local run, restore = fake_ah(items)
  local sounds = 0
  local real_sound = G.PlaySound
  G.PlaySound = function() sounds = sounds + 1 end
  local printed = {}
  local real_add = DEFAULT_CHAT_FRAME.AddMessage
  rawset(DEFAULT_CHAT_FRAME, 'AddMessage', function(_, text) tinsert(printed, text) end)
  aux.account_data.debug_timing = true
  aux.account_data.sniper_profit = 1
  aux.set_tab(2)
  local r0 = sniper.round
  sniper.start()
  local seen_mid_round, status_mid_round
  for _ = 1, 200 do
    run(1)
    if sniper.round == r0 and sniper.checking and sniper.checking.done > 0 and sniper.checking.done < sniper.checking.total and #sniper.listing.records > 0 then
      seen_mid_round = true
      status_mid_round = select(2, sniper.status())
    end
    if sniper.round > r0 then break end
  end
  check('sniper: the round found every deal', #sniper.deals == 6)
  check('sniper: deals show in the table before the round ends', seen_mid_round)
  check('sniper: the status says how many possible deals are being checked', status_mid_round and status_mid_round:find('checking 6 possible deals') ~= nil)
  check('sniper: six deals in one round play the sound once', sounds == 1)
  local timing_lines = 0
  for _, text in ipairs(printed) do if text:find('Search timing') then timing_lines = timing_lines + 1 end end
  check('sniper: rounds print no timing lines with /aux debug on', timing_lines == 0)
  -- 2.5 seconds between rounds (Tyler, 0.4): the next round starts after the pause, not before
  local r1 = sniper.round
  run(23)
  check('sniper: no new round during the pause', sniper.round == r1 and not sniper.active)
  run(5)
  check('sniper: the next round starts after 2.5 seconds', sniper.active or sniper.round > r1)
  sniper.stop()
  aux.account_data.debug_timing = false
  aux.account_data.sniper_profit = 500
  rawset(DEFAULT_CHAT_FRAME, 'AddMessage', real_add)
  G.PlaySound = real_sound
  aux.set_tab(1)
  sniper.clear_deals()
  restore()
end)

try('an error does not leave a search stuck', function()
  local search = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local scan = loadstring("select(2, ...) 'aux.core.scan'; return _M")('auxForever', addon)
  local run, restore = fake_ah(ROBES())
  local printed = {}
  local real_add = DEFAULT_CHAT_FRAME.AddMessage
  rawset(DEFAULT_CHAT_FRAME, 'AddMessage', function(_, text) tinsert(printed, text) end)
  local real_results = C_AuctionHouse.GetBrowseResults
  rawset(C_AuctionHouse, 'GetBrowseResults', function() error('test error in the item list') end)
  -- like tick(), but the error raised for BugSack is expected here
  local raised = 0
  local function quiet_run(n)
    for _ = 1, n do
      clock = clock + 0.1
      for _, f in ipairs(frames) do
        if f.__shown and f.__scripts.OnUpdate then
          if not pcall(f.__scripts.OnUpdate, f, 0.1) then raised = raised + 1 end
        end
      end
      for _, f in ipairs(frames) do
        if f.__events['AUCTION_HOUSE_BROWSE_RESULTS_UPDATED'] and f.__scripts.OnEvent then
          pcall(f.__scripts.OnEvent, f, 'AUCTION_HOUSE_BROWSE_RESULTS_UPDATED')
        end
      end
    end
  end
  search.frame:Show()
  search.update_mode(search.NORMAL_MODE)
  search.search_box:SetText('robe')
  search.toggle_live()
  local s = search.current_search()
  quiet_run(20)
  check('the error still reaches BugSack', raised >= 1)
  check('the scan is not left running', not scan.is_scanning())
  check('live shows Paused instead of Updating forever', search.live_status(s) == 'paused')
  check('chat says the search stopped because of an error', table.concat(printed, '\n'):find('stopped because of an error', 1, true) ~= nil)
  rawset(C_AuctionHouse, 'GetBrowseResults', real_results)
  rawset(DEFAULT_CHAT_FRAME, 'AddMessage', real_add)

  -- "Updating" with no round running carries on by itself
  search.execute(nil, true)
  run(20)
  local round = s.live_round or 0
  s.live_next = nil
  run(40)
  check('a live search with no round running carries on', (s.live_round or 0) > round)
  search.toggle_live()
  search.frame:Hide()
  restore()
end)


try('reagent bag', function()
  local require = loadstring("select(2, ...) 'aux.test33'; return require")('auxForever', addon)
  local info = require 'aux.util.info'
  local real = C_Container.GetContainerNumSlots
  -- backpack with 2 slots, no bags, a reagent bag with 3 slots
  C_Container.GetContainerNumSlots = function(bag) return ({[0] = 2, [5] = 3})[bag] or 0 end
  local slots = {}
  for slot in info.inventory() do tinsert(slots, slot[1] .. ':' .. slot[2]) end
  C_Container.GetContainerNumSlots = real
  check('the reagent bag is read', table.concat(slots, ' ') == '0:1 0:2 5:1 5:2 5:3')
end)


-- Performance: nothing heavy runs every frame (Tyler, 2026-10-05: performance matters)
try('per-frame work', function()
  local a = loadstring("select(2, ...) 'aux'; return _M")('auxForever', addon)
  -- events: unused ones are unregistered after a kill, and idle frames do nothing
  local id = a.event_listener('AUX_TEST_EVENT', function() end)
  local event_frame
  for _, f in ipairs(frames) do if f.__events['AUX_TEST_EVENT'] then event_frame = f end end
  local unregistered = 0
  rawset(event_frame, 'UnregisterEvent', function(self, e) unregistered = unregistered + 1; self.__events[e] = nil end)
  for _ = 1, 5 do tick() end
  check('idle frames unregister nothing', unregistered == 0)
  a.kill_listener(id)
  tick()
  check('a killed listener\'s event is unregistered', unregistered == 1 and not event_frame.__events['AUX_TEST_EVENT'])
  tick()
  check('and only once', unregistered == 1)
  rawset(event_frame, 'UnregisterEvent', nil)
  -- with many listeners an idle frame stays cheap (aux compared every listener with every other
  -- listener on every frame, all game long)
  local ids = {}
  for i = 1, 400 do tinsert(ids, a.event_listener('AUX_TEST_EVENT_' .. (i % 20), function() end)) end
  local t0 = os.clock()
  for _ = 1, 30 do event_frame.__scripts.OnUpdate(event_frame) end
  check('an idle frame costs next to nothing', os.clock() - t0 < .05)
  for _, i in ipairs(ids) do a.kill_listener(i) end
  tick()

  -- Auctions tab: the list follows events, not a rebuild every second
  local auctions = loadstring("select(2, ...) 'aux.tabs.auctions'; return _M")('auxForever', addon)
  local real_scan, scans = auctions.scan_auctions, 0
  auctions.scan_auctions = function() scans = scans + 1 end
  auctions.frame:Show()
  for _ = 1, 30 do tick() end
  check('Auctions tab: no rebuild every second', scans <= 1)
  auctions.refresh = true
  tick()
  check('Auctions tab: rebuilt when the game says the list changed', scans == 2)
  auctions.frame:Hide()
  auctions.scan_auctions = real_scan

  -- Full scan button: restyled only when ready changes
  local styled = 0
  rawset(a.scan_button, 'SetBackdropColor', function() styled = styled + 1 end)
  for _ = 1, 30 do tick() end
  check('Full scan button is not restyled every frame', styled <= 1)
  rawset(a.scan_button, 'SetBackdropColor', nil)
end)


try('/aux memory', function()
  local slash = loadstring("select(2, ...) 'aux.core.slash'; return _M")('auxForever', addon)
  local updated
  G.UpdateAddOnMemoryUsage = function() updated = true end
  G.GetAddOnMemoryUsage = function(name) return name == 'auxForever' and 3584 or 0 end
  local report = slash.memory_report()
  check('memory is measured when asked', updated == true)
  check('memory report in MB with the history size', report:find('uses 3.5 MB of memory; price history for %d+ items') ~= nil)
  check('memory report says what is left after a cleanup', report:find('After a cleanup: 3.5 MB', 1, true) ~= nil)
  local detail = slash.memory_detail()
  check('memory detail: one line per store', #detail == 6 and detail[1]:find('^Sniper: %d+ items known') ~= nil and detail[6]:find('^Events: %d+ listeners') ~= nil)
  G.UpdateAddOnMemoryUsage, G.GetAddOnMemoryUsage = nil, nil
end)


try('auctions tab: undercut check', function()
  local aux = loadstring("select(2, ...) 'aux'; return _M")('auxForever', addon)
  local auctions = loadstring("select(2, ...) 'aux.tabs.auctions'; return _M")('auxForever', addon)
  local items = ROBES()
  tinsert(items, {id = 104, name = 'Native Robe', min = 3000, qty = 1, auctions = {{buyout = 3000}}})
  -- another seller at 6400 for the Greenweave Robe, the same price as ours
  local run, restore = fake_ah(items)
  local function link(id, name) return '|cff1eff00|Hitem:' .. id .. '::::::0:0|h[' .. name .. ']|h|r' end
  local owned = {
    {auctionID = 9001, itemKey = {itemID = 101, itemSuffix = 0, itemLevel = 0}, itemLink = link(101, 'Spellbinder Robe'), status = 0, quantity = 1, timeLeft = 3, buyoutAmount = 20000},
    {auctionID = 9002, itemKey = {itemID = 102, itemSuffix = 0, itemLevel = 0}, itemLink = link(102, 'Greenweave Robe'), status = 0, quantity = 1, timeLeft = 3, buyoutAmount = 6400},
    {auctionID = 9003, itemKey = {itemID = 103, itemSuffix = 0, itemLevel = 0}, itemLink = link(103, 'Pagan Robe'), status = 0, quantity = 1, timeLeft = 3, buyoutAmount = 21000},
    {auctionID = 9004, itemKey = {itemID = 101, itemSuffix = 0, itemLevel = 0}, itemLink = link(101, 'Spellbinder Robe'), status = 1, quantity = 1, timeLeft = 3, buyoutAmount = 19000},
  }
  local saved = {}
  local function set(k, v) saved[k] = rawget(C_AuctionHouse, k); rawset(C_AuctionHouse, k, v) end
  set('GetNumOwnedAuctions', function() return #owned end)
  set('GetOwnedAuctionInfo', function(i) return owned[i] end)
  local cancels = {}
  set('CancelAuction', function(id) tinsert(cancels, id) end)
  set('CanCancelAuction', function() return true end)
  set('GetCancelCost', function() return 925 end)
  local searches = 0
  local real_search = C_AuctionHouse.SendSearchQuery
  rawset(C_AuctionHouse, 'SendSearchQuery', function(...) searches = searches + 1; return real_search(...) end)
  local real_sold = Enum.AuctionStatus
  rawset(Enum, 'AuctionStatus', {Active = 0, Sold = 1})

  aux.set_tab(4) -- Search, Sniper, Post, Auctions
  check('auctions: fourth tab', auctions.frame.__shown)
  run(60)
  local by_id = {}
  for _, record in ipairs(auctions.listing.records) do by_id[record.auction_id] = record end
  local status, amount, lowest = auctions.auction_status(by_id[9001])
  check('auctions: a lower price from someone else is undercut, by how much', status == 'undercut' and amount == 1500 and lowest == 18500)
  status, amount = auctions.auction_status(by_id[9002])
  check('auctions: someone else at your price is tied', status == 'tied' and amount == 1)
  check('auctions: cheapest is lowest', auctions.auction_status(by_id[9003]) == 'lowest')
  check('auctions: sold is sold', auctions.auction_status(by_id[9004]) == 'sold')
  check('auctions: each item is read once', searches == 3)
  check('auctions: summary', auctions.summary_text(auctions.status_counts()) == '4 auctions: 1 undercut, 1 tied, 1 lowest, 1 sold')

  auctions.update_controls()
  check('auctions: the button says how many are undercut', auctions.cancel_undercut_button:GetText() == 'Cancel undercut (1)')
  check('auctions: it says which one is next', auctions.next_label:GetText():find('Next: Spellbinder Robe', 1, true) ~= nil)
  auctions.cancel_next_undercut()
  check('auctions: Cancel undercut cancels the undercut one', #cancels == 1 and cancels[1] == 9001)
  check('auctions: and marks it cancelled', auctions.auction_status(by_id[9001]) == 'cancelled')
  auctions.cancel_next_undercut()
  check('auctions: tied and lowest auctions are left alone', #cancels == 1)

  -- opening the tab again soon does not read the prices again
  aux.set_tab(1); aux.set_tab(4)
  run(20)
  check('auctions: no new check within two minutes', searches == 3)
  -- an auction posted since then is checked when the tab opens, without waiting two minutes
  tinsert(owned, {auctionID = 9005, itemKey = {itemID = 104, itemSuffix = 0, itemLevel = 0}, itemLink = link(104, 'Native Robe'), status = 0, quantity = 1, timeLeft = 3, buyoutAmount = 3500})
  aux.set_tab(1); aux.set_tab(4)
  run(40)
  check('auctions: a newly posted auction is checked at once', searches == 7)
  aux.set_tab(1)
  rawset(C_AuctionHouse, 'SendSearchQuery', real_search)
  for k, v in pairs(saved) do rawset(C_AuctionHouse, k, v) end
  rawset(Enum, 'AuctionStatus', real_sold)
  restore()
end)


try('post: next item after posting', function()
  local post = loadstring("select(2, ...) 'aux.tabs.post'; return _M")('auxForever', addon)
  local list = {
    {key = 'd:0', name = 'Delta', count = 3}, {key = 'a:0', name = 'Alpha', count = 2},
    {key = 'c:0', name = 'Charlie', count = 0}, {key = 'b:0', name = 'Bravo', count = 1},
  }
  check('post: the next item in the list', (post.next_item_after('Alpha', 'a:0', list) or {}).name == 'Bravo')
  check('post: items with none left are skipped', (post.next_item_after('Bravo', 'b:0', list) or {}).name == 'Delta')
  check('post: nothing after the last item', post.next_item_after('Delta', 'd:0', list) == nil)
end)


try('per-frame work 0.4', function()
  local require = loadstring("select(2, ...) 'aux.test40'; return require")('auxForever', addon)
  -- tooltips: whether an item can be auctioned is read from a hidden tooltip once per item
  local tooltip = loadstring("select(2, ...) 'aux.core.tooltip'; return _M")('auxForever', addon)
  local built = 0
  rawset(AuxTooltip, 'SetHyperlink', function() built = built + 1 end)
  rawset(AuxTooltip, 'NumLines', function() return 0 end)
  local item_info = {link = 'item:4000', quality = 1}
  tooltip.is_auctionable(4000, item_info); tooltip.is_auctionable(4000, item_info); tooltip.is_auctionable(4000, item_info)
  check('an item tooltip is scanned once, not on every hover', built == 1)
  rawset(AuxTooltip, 'SetHyperlink', nil); rawset(AuxTooltip, 'NumLines', nil)

  -- Post tab: the Post button is checked a few times a second, not every frame
  local post = loadstring("select(2, ...) 'aux.tabs.post'; return _M")('auxForever', addon)
  local real_validate, validations = post.validate_parameters, 0
  post.validate_parameters = function() validations = validations + 1 end
  post.refresh = false
  for _ = 1, 20 do post.on_update() end
  check('Post tab: not validated every frame', validations <= 1)
  post.validate_parameters = real_validate

  -- buy bar: its texts refresh ten times a second, not every frame
  local bar = require 'aux.gui.buy_bar'
  local refreshed = 0
  bar.show_item{record = {buyout_price = 100, bid_price = 50, count = 1, auction_count = 1}, name = 'Test', busy = function() refreshed = refreshed + 1 return false end, on_buy = function() end, on_bid = function() end}
  refreshed = 0
  for _ = 1, 20 do bar.frame.__scripts.OnUpdate(bar.frame) end
  check('buy bar: not refreshed every frame', refreshed <= 2)
  bar.clear()

  -- price history: a price that is not a new daily low does not unpack the saved history
  local history = loadstring("select(2, ...) 'aux.core.history'; return _M")('auxForever', addon)
  local real_data, reads = history.data, 0
  history.data = setmetatable({}, {__index = function(_, k) reads = reads + 1 return real_data[k] end, __newindex = function(_, k, v) real_data[k] = v end})
  local function auction(price) return {item_key = '4321:0', buyout_price = price, count = 1} end
  history.process_auction(auction(500))
  local after_first = reads
  for _ = 1, 10 do history.process_auction(auction(600)) end
  check('history: higher prices do not unpack the saved history', reads == after_first)
  history.process_auction(auction(400))
  check('history: a new low is still recorded', history.market_value('4321:0') == 400)
  history.data = real_data
end)


-- Tyler, 0.4.1: the buy bar offered 20 Ironweb Spider Silk on the Sniper where only 7 were a deal,
-- and the buy did not go through while rounds kept running
try('sniper: only deal-priced units to buy, rounds wait while buying', function()
  local aux_require = loadstring("select(2, ...) 'aux.test47'; return require")('auxForever', addon)
  local aux = aux_require 'aux'
  local buy_bar = aux_require 'aux.gui.buy_bar'
  local sniper = loadstring("select(2, ...) 'aux.tabs.sniper'; return _M")('auxForever', addon)
  local items = {
    {id = 501, name = 'Ironweb Spider Silk', commodity = true, stack = 20, min = 2499, qty = 25, sell = 2500,
      auctions = {{buyout = 2499, qty = 7}, {buyout = 2550, qty = 18}}},
  }
  local run, restore = fake_ah(items)
  aux.account_data.sniper_profit = 1
  sniper.clear_deals()
  aux.set_tab(2)
  local r0 = sniper.round
  sniper.start()
  for _ = 1, 200 do run(1) if sniper.round > r0 then break end end
  local deal = sniper.deals[1]
  local units = 0
  for _, tier in ipairs(deal and deal.deal_tiers or {}) do units = units + tier.count end
  check('sniper: only the units below vendor price can be bought', deal and units == 7)
  -- selected later, after someone bought 4 of the 7: the deal is read again with today's counts
  items[1].auctions[1].qty = 3
  sniper.listing:SetSelectedRecord(deal)
  run(10)
  units = 0
  for _, tier in ipairs(deal.deal_tiers or {}) do units = units + tier.count end
  check('sniper: a selected trade good deal shows what is left', units == 3)
  sniper.listing:SetSelectedRecord()
  run(2)
  local real_busy = buy_bar.busy
  rawset(buy_bar, 'busy', function() return true end)
  local r1 = sniper.round
  run(60)
  check('sniper: no round while a purchase is under way', sniper.round == r1 and not sniper.active)
  check('sniper: the status says it waits', select(2, sniper.status()) == 'waits while you buy')
  rawset(buy_bar, 'busy', real_busy)
  run(60)
  check('sniper: rounds go on after the purchase', sniper.round > r1)
  sniper.stop()
  aux.account_data.sniper_profit = 500
  sniper.clear_deals()
  aux.set_tab(1)
  restore()
end)

-- Tyler, 0.4.1 build 4: gear deals could not be bought from the Sniper, and the table moved under the
-- mouse. A selected gear deal is read again before it can be bought, and the rounds hold meanwhile.
try('sniper: a selected gear deal is checked again and the rounds hold', function()
  local aux_require = loadstring("select(2, ...) 'aux.test48'; return require")('auxForever', addon)
  local aux = aux_require 'aux'
  local bar = aux_require 'aux.gui.buy_bar'
  local sniper = loadstring("select(2, ...) 'aux.tabs.sniper'; return _M")('auxForever', addon)
  local items = {
    {id = 601, name = 'Massive Battle Axe', min = 2800, qty = 1, sell = 3036, auctions = {{buyout = 2800}}},
    {id = 602, name = 'Long Redwood Bow', min = 5500, qty = 1, sell = 5568, auctions = {{buyout = 5500}}},
  }
  local run, restore = fake_ah(items)
  local searched = {}
  local real_send = C_AuctionHouse.SendSearchQuery
  rawset(C_AuctionHouse, 'SendSearchQuery', function(key, ...) searched[key.itemID] = (searched[key.itemID] or 0) + 1; return real_send(key, ...) end)
  aux.account_data.sniper_profit = 1
  sniper.clear_deals()
  aux.set_tab(2)
  local r0 = sniper.round
  sniper.start()
  for _ = 1, 300 do run(1) if sniper.round > r0 then break end end
  local axe
  for _, d in ipairs(sniper.deals) do if d.item_id == 601 then axe = d end end
  check('sniper gear: the deal is found', axe ~= nil)
  local before = searched[601] or 0
  sniper.listing:SetSelectedRecord(axe)
  run(3)
  check('sniper gear: selecting it reads its item again', (searched[601] or 0) > before)
  run(10)
  check('sniper gear: then the buy bar offers it', bar.primary_label():find('^Buy for') ~= nil)
  local r1 = sniper.round
  run(80)
  check('sniper gear: no round while a deal is selected', sniper.round == r1 and not sniper.active)
  check('sniper gear: the status says it holds', sniper.status() == 'Holding')
  sniper.click_deal(axe)
  check('sniper gear: a click on the selected deal lets it go', sniper.listing:GetSelection() == nil)
  run(80)
  check('sniper gear: the rounds go on', sniper.round > r1)

  -- sold before the click: the deal shows as gone, nothing to buy
  local bow
  for _, d in ipairs(sniper.deals) do if d.item_id == 602 then bow = d end end
  items[2].qty = 0
  sniper.listing:SetSelectedRecord(bow)
  run(15)
  check('sniper gear: sold before the click shows as gone', bow and bow.deal_gone == true)
  sniper.listing:SetSelectedRecord()

  -- the table waits while the mouse is over it
  local before_records = sniper.listing.records
  rawset(sniper.frame.listing, 'IsMouseOver', function() return true end)
  sniper.deals_changed = true
  sniper.update(); run(2)
  check('sniper: the table does not change under the mouse', sniper.listing.records == before_records and sniper.deals_changed == true)
  rawset(sniper.frame.listing, 'IsMouseOver', nil)
  run(10)
  check('sniper: the table catches up when the mouse leaves', sniper.deals_changed == false)

  sniper.stop()
  rawset(C_AuctionHouse, 'SendSearchQuery', real_send)
  aux.account_data.sniper_profit = 500
  sniper.clear_deals()
  aux.set_tab(1)
  restore()
end)

-- Tyler, 0.4.1: after a full scan (69,591 auctions) aux held 42 MB after a cleanup: the Post tab kept
-- the listings of every item. It keeps only the items in the bags now.
try('full scan keeps Post listings for bag items only', function()
  local req = loadstring("select(2, ...) 'aux.test46'; return require")('auxForever', addon)
  local info = req 'aux.util.info'
  local post = loadstring("select(2, ...) 'aux.tabs.post'; return _M")('auxForever', addon)
  local real_inventory, real_container = info.inventory, info.container_item
  rawset(info, 'inventory', function()
    local done = false
    return function() if not done then done = true return {0, 1} end end
  end)
  rawset(info, 'container_item', function() return {item_key = '111:0'} end)
  post.clear_auctions()
  post.record_scanned_auction({item_key = '111:0', commodity = true, unit_buyout_price = 50, count = 5, duration = 2, owner = 'Someone'})
  post.record_scanned_auction({item_key = '222:0', commodity = true, unit_buyout_price = 70, count = 9, duration = 2, owner = 'Someone'})
  check('full scan: an item in the bags keeps its listings', post.listings_known('111:0'))
  check('full scan: an item not in the bags is not kept', not post.listings_known('222:0'))
  rawset(info, 'inventory', real_inventory); rawset(info, 'container_item', real_container)
  post.clear_auctions()
end)

-- Tyler, 0.4.1: prices read "7s", not "7s 00c"
try('money without zero parts', function()
  local req = loadstring("select(2, ...) 'aux.test45'; return require")('auxForever', addon)
  local money = req 'aux.util.money'
  local function plain(n) return money.to_string(n, true, nil, nil, true) end
  check('money: 7s', plain(700) == '7s')
  check('money: 1g 92s', plain(19200) == '1g 92s')
  check('money: 1g 5c', plain(10005) == '1g 05c')
  check('money: 1s 23c', plain(123) == '1s 23c')
  check('money: 0c', plain(0) == '0c')
  check('money: 3g', plain(30000) == '3g')
  check('money: negative', plain(-700) == '-7s')
  -- Tyler: in a column of copper prices "1s" broke the line-up; tables with copper keep all parts
  money.set_full_parts(true)
  check('money in a table with copper: 1s 00c', plain(100) == '1s 00c')
  money.set_full_parts(false)
  check('money outside tables stays short', plain(100) == '1s')
  local al = req 'aux.gui.auction_listing'
  local buyout_col
  for i, c in ipairs(al.search_columns) do
    if type(c.title) == 'table' and c.title[1]:find('^Auction Buyout') then buyout_col = i end
  end
  local rt = al.new(new_frame(), 19, al.search_columns)
  local function rec(key, price) return {count = 1, item_key = key, search_signature = key, name = key, requirement = 0, unit_buyout_price = price, buyout_price = price, unit_bid_price = 0, bid_price = 0, high_bid = 0, duration = 2} end
  rt:SetDatabase({rec('a', 47), rec('b', 100)})
  check('table with copper: every price keeps its copper', rt.has_copper == true)
  rt:SetDatabase({rec('c', 1200), rec('d', 1500)})
  check('table without copper: prices stay short', rt.has_copper == false)
  rt.has_copper = true
  rt:UpdateRows()
  check('the table leaves short prices for everything else', plain(100) == '1s')
end)

try('an empty search does not list the whole auction house', function()
  local search = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local req = loadstring("select(2, ...) 'aux.test49'; return require")('auxForever', addon)
  local exports = req 'aux.core.scan'
  local real_start, started = exports.start, false
  rawset(exports, 'start', function() started = true end)
  search.search_box:SetText('  ')
  search.execute(nil, false)
  check('empty search: nothing is searched', not started)
  rawset(exports, 'start', real_start)
end)

try('per-frame work 0.4.1', function()
  local aux_require = loadstring("select(2, ...) 'aux.test44'; return require")('auxForever', addon)
  local aux = aux_require 'aux'
  -- Saved Searches: the Alt key is only checked while a favorite is being dragged
  local search = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local real_alt, alt_checks = G.IsAltKeyDown, 0
  G.IsAltKeyDown = function() alt_checks = alt_checks + 1 return false end
  search.dragged_search = nil
  for _ = 1, 20 do search.frame.saved.__scripts.OnUpdate(search.frame.saved) end
  check('Saved Searches: no Alt check every frame while nothing is dragged', alt_checks == 0)
  G.IsAltKeyDown = real_alt

  -- Bids tab: its buttons follow the selection a few times a second, not every frame
  local bids = loadstring("select(2, ...) 'aux.tabs.bids'; return _M")('auxForever', addon)
  local real_get, gets = bids.listing.GetSelection, 0
  rawset(bids.listing, 'GetSelection', function() gets = gets + 1 end)
  bids.refresh, bids.next_refresh = false, GetTime() + 100
  for _ = 1, 20 do bids.on_update() end
  check('Bids tab: buttons not updated every frame', gets <= 1)
  rawset(bids.listing, 'GetSelection', nil)

  -- aux's item list at login: numbers the game says are no item are not asked about, and a
  -- complete list is walked over many frames, not in one long one
  local info = loadstring("select(2, ...) 'aux.util.info'; return _M")('auxForever', addon)
  local real_items, real_unused = aux.account_data.items, aux.account_data.unused_item_ids
  aux.account_data.items, aux.account_data.unused_item_ids = {}, {}
  for id = 1, 30000 do aux.account_data.unused_item_ids[id] = true end
  local real_exists, real_info, asked = C_Item.DoesItemExistByID, G.GetItemInfo, {}
  rawset(C_Item, 'DoesItemExistByID', function(id) return id ~= 777 end)
  G.GetItemInfo = function(x) asked[tonumber(tostring(x):match('%d+'))] = true end
  -- a complete list: nothing to ask, still spread over frames
  info.item_walk_done = nil
  info.fetch_item_data()
  check('item list: a complete list is not walked in one frame', not info.item_walk_done)
  for _ = 1, 100 do tick() end
  check('item list: a complete list is walked within a few frames', info.item_walk_done == true)
  aux.account_data.unused_item_ids[777], aux.account_data.unused_item_ids[778] = nil, nil
  info.item_walk_done = nil
  info.fetch_item_data()
  for _ = 1, 100 do tick() end
  check('item list: done after some frames', info.item_walk_done == true)
  check('item list: a number that is no item is not asked about', not asked[777] and asked[778])
  local known, _, _, done = info.item_list_progress()
  check('item list: progress for /aux memory', known == 0 and done == true)
  rawset(C_Item, 'DoesItemExistByID', real_exists)
  G.GetItemInfo = real_info
  aux.account_data.items, aux.account_data.unused_item_ids = real_items, real_unused
end)

try('recipe search', function()
  local aux = loadstring("select(2, ...) 'aux'; return _M")('auxForever', addon)
  local search = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local shortcut = loadstring("select(2, ...) 'aux.core.shortcut'; return _M")('auxForever', addon)
  check('recipe link: enchant', search.recipe_id_from_link('|cffffd000|Henchant:12046|h[Tailoring: Simple Kilt]|h|r') == 12046)
  check('recipe link: spell', search.recipe_id_from_link('|Hspell:12046|h[x]|h') == 12046)
  check('an item link is not a recipe', search.recipe_id_from_link('|Hitem:2589::::::0:0|h[Linen Cloth]|h') == nil)

  -- a made-up recipe: one robe from three of another robe and one of a third
  local schematic = {name = 'Robe Kit', outputItemID = 101, quantityMin = 1, reagentSlotSchematics = {
    {reagents = {{itemID = 102}}, quantityRequired = 3, required = true},
    {reagents = {{itemID = 103}}, quantityRequired = 1, required = true},
    {reagents = {{itemID = 104}}, quantityRequired = 1, required = false},
  }}
  G.C_TradeSkillUI = {GetRecipeSchematic = function(id) return id == 12046 and schematic or nil end}
  local parts = search.recipe_parts(12046)
  check('recipe: the item it makes', parts.output.item_id == 101 and parts.output.count == 1)
  check('recipe: required materials only', #parts.reagents == 2 and parts.reagents[1].count == 3)

  local run, restore = fake_ah(ROBES())
  search.update_mode(search.NORMAL_MODE)
  local was_shown = aux.frame.__shown
  aux.frame.__shown = true
  shortcut.on_modified_click('|cffffd000|Henchant:12046|h[Tailoring: Robe Kit]|h|r')
  check('recipe: a plain click on a recipe does nothing', search.search_box:GetText() ~= 'spellbinder robe/exact;greenweave robe/exact;pagan robe/exact')
  local real_alt = IsAltKeyDown
  G.IsAltKeyDown = function() return true end
  shortcut.on_modified_click('|cffffd000|Henchant:12046|h[Tailoring: Robe Kit]|h|r')
  G.IsAltKeyDown = real_alt
  run(120)
  local s = search.current_search()
  check('recipe: Alt-click searches the item and its materials', search.search_box:GetText() == 'spellbinder robe/exact;greenweave robe/exact;pagan robe/exact')
  check('recipe: the search knows its recipe', s.recipe and s.recipe.name == 'Robe Kit')
  -- materials: 3 x 64s + 2g 20s = 4g 12s; sells for 1g 85s less 5% = 1g 75s 75c: a loss
  search.update_results_summary(true)
  local summary = search.recipe_label.__text or ''
  check('recipe: the line adds up the craft', summary:find('materials 4g 12s', 1, true) ~= nil and summary:find('sells 1g 75s 75c after cut', 1, true) ~= nil and summary:find('loss 2g 36s 25c', 1, true) ~= nil)
  -- Tyler, 0.4: the cost crowded the line next to the sub tabs and was cut off; it is in the bottom bar
  check('recipe: the cost is in the bottom bar, not next to the sub tabs', summary:find('Robe Kit', 1, true) ~= nil and not (search.results_summary(s) or ''):find('materials', 1, true))
  -- Tyler, 0.4: "materials ?" did not say which material had no price (Gray Dye, not for sale)
  local without = {}
  for _, r in ipairs(s.records) do if r.item_id ~= 103 then tinsert(without, r) end end
  local partial = search.recipe_summary{recipe = s.recipe, records = without}
  local info = loadstring("select(2, ...) 'aux.util.info'; return _M")('auxForever', addon)
  local dye = info.item(103).name
  check('recipe: a material without a price is named', partial:find('materials 1g 92s + ' .. dye .. ' (no price)', 1, true) ~= nil)
  check('recipe: with a material missing the loss is a bound', partial:find('loss at least 16s 25c', 1, true) ~= nil)

  -- Tyler, 0.4: a saved recipe search showed as its raw text "[Colorful Kilt];[Bolt of Woolen Cloth];..."
  local recent = search.recent_searches[1]
  check('recipe: the recent entry keeps its recipe', recent.recipe and recent.recipe.name == 'Robe Kit')
  local rows
  rawset(search.recent_searches_listing, 'SetData', function(_, r) rows = r end)
  search.update_search_listings()
  rawset(search.recent_searches_listing, 'SetData', nil)
  local name = rows and rows[1].cols[1].value or ''
  check('recipe: Recent shows "Recipe  Robe Kit  (2 materials)"', name:find('Recipe', 1, true) and name:find('Robe Kit', 1, true) and name:find('(2 materials)', 1, true) and not name:find('exact', 1, true))
  check('recipe: the quick menu shows the last profit or loss', recent.last_profit == -23625 and search.quick_entry_detail(recent):find('^Loss ') ~= nil)
  check('recipe: saved as a favorite with its recipe', search.save_favorite(search.search_box:GetText()) == 'saved' and search.favorite_searches[1].recipe ~= nil)
  -- another search, then the favorite again: the cost line comes back
  search.set_filter('pagan robe/exact')
  search.execute(nil, false)
  run(60)
  check('recipe: a plain search has no recipe', search.current_search().recipe == nil)
  search.handlers.OnClick(search.favorite_searches_listing, {search = search.favorite_searches[1], index = 1}, nil, 'LeftButton')
  run(120)
  local again = search.current_search()
  check('recipe: running the saved recipe search shows the cost line again', again.recipe and again.recipe.name == 'Robe Kit' and (search.recipe_summary(again) or ''):find('materials', 1, true) ~= nil)
  tremove(search.favorite_searches, 1)

  -- the button on the profession window
  local form = new_frame()
  rawset(form, 'GetRecipeInfo', function() return {recipeID = 12046} end)
  G.ProfessionsFrame = {CraftingPage = {SchematicForm = form}}
  fire('ADDON_LOADED', 'Blizzard_Professions')
  check('recipe: a Search in aux button on the profession window', search.recipe_button ~= nil and search.recipe_button.__text == 'Search in aux')
  search.search_box:SetText('')
  search.recipe_button.__scripts.OnClick(search.recipe_button)
  run(120)
  check('recipe: the button searches the shown recipe', search.search_box:GetText():find('spellbinder robe/exact', 1, true) == 1)
  fire('AUCTION_HOUSE_CLOSED')
  check('recipe: the button hides when the auction house closes', not search.recipe_button.__shown)
  G.ProfessionsFrame, G.C_TradeSkillUI = nil, nil
  aux.frame.__shown = was_shown
  restore()
end)


-- 0.5: better price data (docs/price-data.md, "Plan for 0.5")
try('price data 0.5', function()
  local h = loadstring("select(2, ...) 'aux.core.history'; return _M")('auxForever', addon)
  local persistence = loadstring("select(2, ...) 'aux.test50'; return require")('auxForever', addon) 'aux.util.persistence'
  local today = h.today()

  -- one very cheap auction among many barely moves the market price; today's lowest is that auction
  local records = {{item_key = '9001:0', buyout_price = 1, count = 1}}
  for i = 1, 20 do tinsert(records, {item_key = '9001:0', buyout_price = 5000, count = 5}) end
  for _, r in ipairs(records) do h.process_auction(r) end
  h.record_view_of(records)
  local market, units = h.today_market('9001:0')
  check('price: today\'s lowest is the cheap auction', h.market_value('9001:0') == 1)
  check('price: one cheap auction barely moves the market price', market and market >= 950 and units == 101)
  check('price: with no past days the usual price is the market price', h.value('9001:0') == market)

  -- gear rows: an item search row is auction_count auctions of one item
  check('price: units of a gear row', h.record_units({count = 1, auction_count = 4}) == 4 and h.record_units({count = 20}) == 20)

  -- recent days outweigh old ones: three recent days at 100 against five days a month old at 200
  local points = {}
  for d = 1, 3 do tinsert(points, {day = today - d, value = 100}) end
  for d = 25, 29 do tinsert(points, {day = today - d, value = 200}) end
  h.write_record('9002:0', {day = today, points = points})
  check('price: recent days count more in the usual price', h.value('9002:0') == 100)

  -- a day ends: its market price becomes a past day, its lowest is kept only without a market price
  h.write_record('9003:0', {day = today - 1, low = 50, market = 80, units = 12, points = {}})
  local r = h.read_record('9003:0')
  check('price: a finished day keeps its market price and units', #r.points == 1 and r.points[1].value == 80 and r.points[1].units == 12 and r.points[1].day == today - 1 and r.low == nil)
  h.write_record('9004:0', {day = today - 1, low = 50, points = {}})
  check('price: a day without a complete view keeps its lowest', h.read_record('9004:0').points[1].value == 50)
  local many = {}
  for d = 1, 20 do tinsert(many, {day = today - 1 - d, value = d}) end
  h.write_record('9005:0', {day = today - 1, low = 7, points = many})
  check('price: at most 14 past days are kept', #h.read_record('9005:0').points == 14)

  -- the age of a price: seen today, or how many days since the newest day
  local _, age = h.value_and_age('9001:0')
  check('price: seen today', age == 0 and h.age_text(age) == 'today')
  _, age = h.value_and_age('9002:0')
  check('price: seen 1 day ago', age == 1 and h.age_text(age) == '1 day ago' and h.age_text(9) == '9 days ago')

  -- version 2 (0.4) lines are converted: every old daily low survives with its day
  local old_schema = {'tuple', '#', {next_push='number'}, {daily_min_buyout='number'}, {data_points={'list', ';', {'tuple', '@', {value='number'}, {time='number'}}}}}
  local function midnight_after(days_ago)
    local t = os.date('*t', os.time() - days_ago * 86400)
    t.hour, t.min, t.sec = 24, 0, 0
    return os.time(t)
  end
  local old_points = {}
  local old_values = {300, 310, 290, 900, 305}
  for i, v in ipairs(old_values) do tinsert(old_points, {value = v, time = midnight_after(i)}) end
  h.data['9006:0'] = persistence.write(old_schema, {next_push = midnight_after(0), daily_min_buyout = 280, data_points = old_points})
  local converted = h.read_record('9006:0')
  local all_kept = #converted.points == #old_values
  for i, v in ipairs(old_values) do
    all_kept = all_kept and converted.points[i].value == v and converted.points[i].day == today - i
  end
  check('price: a 0.4 line keeps every daily low with its day', all_kept)
  check('price: a 0.4 line keeps today\'s lowest', converted.low == 280 and converted.day == today)
  check('price: the converted usual price is the old one for steady prices', h.value('9006:0') == 305)
  h.write_record('9006:0', converted)
  check('price: the converted line is saved in the 0.5 form', not h.data['9006:0']:find('^%d%d%d%d%d%d%d%d'))
  -- a stale day 0.4 line (last scanned days ago) moves its lowest into the past days
  h.data['9007:0'] = persistence.write(old_schema, {next_push = midnight_after(3), daily_min_buyout = 444, data_points = {}})
  local stale = h.read_record('9007:0')
  check('price: a stale 0.4 day becomes a past day', #stale.points == 1 and stale.points[1].value == 444 and stale.points[1].day == today - 3)

  -- day numbers are calendar days
  check('price: day numbers', h.day_number_of(1970, 1, 1) == 0 and h.day_number_of(2000, 3, 1) == 11017 and h.day_number_of(2026, 10, 8) - h.day_number_of(2026, 10, 7) == 1)
end)

try('price data 0.5: full scan', function()
  local req = loadstring("select(2, ...) 'aux.test51'; return require")('auxForever', addon)
  local scan = req 'aux.core.scan'
  local h = loadstring("select(2, ...) 'aux.core.history'; return _M")('auxForever', addon)
  -- two items, auctions mixed: item 9101 has 50 units at 100c and one at 5c, item 9102 3 at 700c
  local list = {}
  for i = 1, 10 do tinsert(list, {id = 9101, count = 5, buyout = 500}) ; if i == 4 then tinsert(list, {id = 9102, count = 1, buyout = 700}) end end
  tinsert(list, 3, {id = 9101, count = 1, buyout = 5})
  tinsert(list, {id = 9102, count = 2, buyout = 1400})
  local saved = {}
  local function set(t, k, v) tinsert(saved, {t, k, rawget(t, k)}); rawset(t, k, v) end
  local fired
  set(C_AuctionHouse, 'ReplicateItems', function() fired = true end)
  set(C_AuctionHouse, 'GetNumReplicateItems', function() return #list end)
  set(C_AuctionHouse, 'GetReplicateItemInfo', function(i)
    local a = list[i + 1]
    return 'Item', 1, a.count, 1, true, 1, nil, 0, 0, a.buyout, 0, false, nil, 'Seller', nil, 0, a.id, true
  end)
  set(C_AuctionHouse, 'GetReplicateItemLink', function(i) return '|cffffffff|Hitem:' .. list[i + 1].id .. '::::::0:0|h[Item]|h|r' end)
  set(G, 'GetItemInfo', function(x)
    local id = type(x) == 'number' and x or tonumber(tostring(x):match('item:(%d+)'))
    if id ~= 9101 and id ~= 9102 then return end
    return 'Item ' .. id, '|cffffffff|Hitem:' .. id .. '::::::0:0|h[Item]|h|r', 1, 10, 1, 'Trade Goods', 'Herb', 20, '', 1, 1
  end)
  local views = {}
  local real_view = h.record_view
  h.record_view = function(key, flat) views[key] = (views[key] or 0) + 1; return real_view(key, flat) end
  local done
  scan.start{type = 'list', queries = {{blizzard_query = {}}}, get_all = true, quiet = true, on_complete = function() done = true end}
  for _ = 1, 10 do tick() end
  fire('REPLICATE_ITEM_LIST_UPDATE')
  for _ = 1, 80 do tick() end
  h.record_view = real_view
  for i = #saved, 1, -1 do rawset(saved[i][1], saved[i][2], saved[i][3]) end
  check('full scan: finished', fired and done)
  check('full scan: each item recorded once', views['9101:0'] == 1 and views['9102:0'] == 1)
  local m1, u1 = h.today_market('9101:0')
  local m2, u2 = h.today_market('9102:0')
  -- 9101: 51 units, cheapest 11 (20%): one at 5c and ten at 100c -> 1005 / 11 = 92c (rounded up)
  check('full scan: market price and units, whatever the order', m1 == 92 and u1 == 51 and m2 == 700 and u2 == 3)
  check('full scan: today\'s lowest', h.market_value('9101:0') == 5)
end)

-- 0.5: a view that missed auctions (a request for more went unanswered) gives no market price
try('price data 0.5: incomplete view', function()
  local search = loadstring("select(2, ...) 'aux.tabs.search'; return _M")('auxForever', addon)
  local h = loadstring("select(2, ...) 'aux.core.history'; return _M")('auxForever', addon)
  local run, restore = fake_ah{{id = 9201, name = 'Partial Robe', min = 900, qty = 2, auctions = {{buyout = 900}, {buyout = 950}}}}
  local real_full = C_AuctionHouse.HasFullItemSearchResults
  rawset(C_AuctionHouse, 'HasFullItemSearchResults', function() return false end)
  rawset(C_AuctionHouse, 'RequestMoreItemSearchResults', function() end)
  search.set_filter('partial robe/exact')
  search.execute(nil, false)
  run(400)
  rawset(C_AuctionHouse, 'HasFullItemSearchResults', real_full)
  rawset(C_AuctionHouse, 'RequestMoreItemSearchResults', nil)
  check('incomplete: today\'s lowest is still recorded', h.market_value('9201:0') == 900)
  check('incomplete: no market price', h.today_market('9201:0') == nil)
  restore()
end)

-- 0.5: the usual price in tooltips says how fresh it is
try('price data 0.5: tooltip age', function()
  local h = loadstring("select(2, ...) 'aux.core.history'; return _M")('auxForever', addon)
  local tooltip = loadstring("select(2, ...) 'aux.core.tooltip'; return _M")('auxForever', addon)
  local today = h.today()
  h.write_record('9301:0', {day = today, points = {{day = today - 3, value = 1000}}})
  h.write_record('9302:0', {day = today, points = {{day = today - 9, value = 1000}}})
  local function value_line(id)
    local lines = {}
    local tip = new_frame()
    rawset(tip, 'AddLine', function(_, text) tinsert(lines, text) end)
    tooltip.extend_tooltip(tip, '|cffffffff|Hitem:' .. id .. '::::::0:0|h[X]|h|r', 1)
    for _, l in ipairs(lines) do if l:find('^Value') then return l end end
  end
  rawset(AuxTooltip, 'NumLines', function() return 0 end)
  local fresh, old = value_line(9301) or '', value_line(9302) or ''
  rawset(AuxTooltip, 'NumLines', nil)
  check('tooltip: Value says when it was seen', fresh:find('seen 3 days ago', 1, true) ~= nil)
  check('tooltip: an old price is dimmed', old:find('seen 9 days ago', 1, true) ~= nil and old ~= fresh:gsub('3 days', '9 days'))
end)

print('done, errors: ' .. errors)
