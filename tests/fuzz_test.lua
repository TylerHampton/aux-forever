-- auxForever tests: a player doing random things (outside review 2026-11-10, second pass).
--
-- Run by load_test.lua after the timing tests, with the slow auction house of tests/slow_server.lua.
-- The timing tests each play one story. This plays many at random: a made-up player switches tabs,
-- searches, selects rows, buys, posts and starts the Sniper in any order, while the auction house
-- answers late, drops an item list now and then, changes its listings and closes and opens. The
-- same seed always plays the same story, so a failure can be played again.
--
-- What must hold whatever the player does:
--   - no Lua error
--   - nothing is bought for more than a button showed when it was pressed
--   - a post reaches the auction house at the price the Post tab showed when Post was pressed
--   - once the player stops and the auction house has answered everything, nothing is left waiting:
--     no search running, no purchase or post under way, no threads or listeners left behind
--
-- More seeds: AUX_FUZZ_SEEDS=200 lua5.1 ../tests/load_test.lua   (the default is a short run)
-- One seed, with every step printed: AUX_FUZZ_SEED=17 lua5.1 ../tests/load_test.lua

return function(env)
  local G, check, try, addon, dir, rawset = env.G, env.check, env.try, env.addon, env.dir, env.rawset
  local new_server = dofile(dir .. 'slow_server.lua')

  local function module(name)
    return loadstring("select(2, ...) '" .. name .. "'; return _M")('auxForever', addon)
  end
  local aux, money = module 'aux', module 'aux.util.money'
  local search, post, sniper, bar, scan = module 'aux.tabs.search', module 'aux.tabs.post', module 'aux.tabs.sniper', module 'aux.gui.buy_bar', module 'aux.core.scan'
  local auctions = module 'aux.tabs.auctions'

  local function plain(t) return ((t or ''):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('FONT_COLOR_CODE_CLOSE', '')) end

  local SEARCHES = {'rough stone', 'rough stone/exact', 'stone', 'fuzz blade/exact', 'blade', 'staff', 'fuzz', 'light feather/exact', 'feather/price/1s', 'nothing at all',
    'fuzz belt/exact', 'belt'}

  local function run(seed, steps, loud)
    -- a small generator of its own: math.random differs between machines
    local state = seed * 7919 + 13
    local function rnd(n)
      state = (state * 1103515245 + 12345) % 2147483648
      return math.floor(state / 65536) % n + 1
    end
    local function say(text) if loud then print('  fuzz ' .. seed .. ': ' .. text) end end

    local server = new_server(env)
    server.items[2835] = {name = 'Rough Stone', commodity = true, vendor = 1, max_stack = 20}
    server.items[2836] = {name = 'Light Feather', commodity = true, vendor = 2, max_stack = 20}
    server.items[7101] = {name = 'Fuzz Blade', commodity = false, vendor = 4000}
    server.items[7102] = {name = 'Fuzz Staff', commodity = false, vendor = 1500, versions = {[11] = 'of the Wolf', [12] = 'of the Bear', [13] = 'of the Wolf'}}
    server.listings[2835] = {{price = 7, quantity = 40}, {price = 8, quantity = 25}, {price = 30, quantity = 200}}
    server.listings[2836] = {{price = 1, quantity = 3}, {price = 12, quantity = 60}}
    server.listings[7101] = {{price = 900, quantity = 2}, {price = 20000, quantity = 1}, {price = 25000, quantity = 3}}
    server.listings[7102] = {{price = 11000, quantity = 1, version = 11}, {price = 9000, quantity = 1, version = 12}, {price = 14000, quantity = 2, version = 13}}
    -- S-08: a piece of gear from many sellers at one price. The search keeps 3 auctions of a row and
    -- counts the rest (FOLD_KEEP is 20 in the game), and reads a row again after one purchase.
    server.items[7103] = {name = 'Fuzz Belt', commodity = false, vendor = 100}
    server.listings[7103] = {{price = 700, quantity = 1, bid = 300, owner = 'Bidder'}}
    for i = 1, 12 do table.insert(server.listings[7103], {price = 500, quantity = 1, owner = 'Belt' .. (i % 9)}) end
    local set_search = loadstring("select(2, ...) 'aux.tabs.search'; local k, v = select(3, ...); M[k] = v")
    set_search('auxForever', addon, 'FOLD_KEEP', 3)
    set_search('auxForever', addon, 'REFILL_AT', 3) -- one purchase from the row reads it again
    server.bag = {{id = 2835, count = 20}, {id = 7101, count = 2}, {id = 7102, count = 1, version = 11}, {id = 2836, count = 7}}
    server.money = 5000000
    server:install()
    for _, box in ipairs{post.stack_size_input, post.stack_count_input} do
      local n = 1
      rawset(box, 'SetNumber', function(self, v) n = math.max(0, math.min(v, self.max_value or v)) end)
      rawset(box, 'GetNumber', function() return n end)
    end
    rawset(post.duration_dropdown, 'GetIndex', function() return 2 end)
    local said = {}
    rawset(G.DEFAULT_CHAT_FRAME, 'AddMessage', function(_, text) said[#said + 1] = tostring(text) end)

    local old_profit, old_percent, old_full = aux.account_data.sniper_profit, aux.account_data.sniper_percent, aux.account_data.full_search
    aux.account_data.sniper_profit = 1
    sniper.clear_deals()
    sniper.settings_changed()
    post.set_undercut_mode(false)
    local threads_before, listeners_before = aux.thread_count(), aux.listener_count()
    local errors_before = env.errors()
    local open = true
    aux.set_tab(1)
    search.frame:Show()
    search.update_mode(search.NORMAL_MODE)

    local shown_spend, post_clicks = 0, {}
    local tab = 1

    -- every third player uses a gamepad: aux then holds the pad buttons and walks its own controls
    local pad_mode = seed % 3 == 0
    local real_pad = {G.SetOverrideBindingClick, G.ClearOverrideBindings, G.InCombatLockdown, G.InputUtil}
    local combat = false
    if pad_mode then
      G.SetOverrideBindingClick, G.ClearOverrideBindings = function() end, function() end
      G.InCombatLockdown = function() return combat end
      G.InputUtil = {IsGamepadUIEnabled = function() return true end}
      aux.frame:Hide(); aux.frame:Show()
      aux.set_tab(1)
      search.frame:Show()
    end
    local function pad(name)
      if not pad_mode or not open then return end
      local button = G['auxForeverPad' .. name]
      if button and button.__scripts.OnClick then button.__scripts.OnClick(button) end
    end

    local function money_in(label)
      local text = plain(label)
      local amount = text:match('for (.+)$') or text:match('^Confirm (.+)$') or text:match('^Bid (.+)$')
      return amount and money.from_string(amount)
    end

    -- Every purchase the addon sends is compared with what its button shows at that moment,
    -- whoever pressed it (the mouse, Alt-click, the gamepad): the two calls that spend money are
    -- watched on their way to the auction house.
    local C = G.C_AuctionHouse
    local real_confirm, real_bid = C.ConfirmCommoditiesPurchase, C.PlaceBid
    rawset(C, 'ConfirmCommoditiesPurchase', function(id, quantity)
      local label = bar.primary_label() or ''
      local shown = money_in(label)
      real_confirm(id, quantity)
      local cost = server.last_confirm_total
      if not shown then
        check('fuzz ' .. seed .. ': a purchase was confirmed from a button that showed no price: "' .. plain(label) .. '"', false)
      else
        shown_spend = shown_spend + shown
        if cost and cost > shown then
          check('fuzz ' .. seed .. ': a purchase of ' .. cost .. ' was confirmed from a button showing ' .. shown, false)
        end
      end
      say('confirmed with "' .. plain(label) .. '"')
    end)
    rawset(C, 'PlaceBid', function(auction_id, amount)
      local buy, bid = money_in(bar.primary_label() or ''), money_in(bar.bid_button:GetText() or '')
      real_bid(auction_id, amount)
      if amount == buy or amount == bid then
        shown_spend = shown_spend + amount
      else
        check('fuzz ' .. seed .. ': ' .. tostring(amount) .. ' was sent for an auction while the buttons showed ' .. tostring(buy) .. ' and ' .. tostring(bid), false)
        shown_spend = shown_spend + (amount or 0)
      end
      say('bid ' .. tostring(amount))
    end)

    -- the buy bar's main button, pressed only when it is lit, as a mouse could
    local function press_buy()
      if not open or not bar.primary_button:IsEnabled() then return end
      bar.primary_click()
    end

    local function press_post()
      if not open or tab ~= 3 then return end
      post.validate_parameters()
      if not post.selected_item or post.disabled_reason() then return end
      local item = post.selected_item
      local expected = {key = item.key, commodity = item.commodity, buyout = post.get_unit_buyout_price(), start = post.get_unit_start_price(), quantity = post.post_quantity()}
      local before = #server.posts
      post.post_button.__scripts.OnClick(post.post_button)
      if #server.posts > before then
        local sent = server.posts[#server.posts]
        if expected.commodity then
          check('fuzz ' .. seed .. ': a trade good was posted at the price shown', sent.unit_price == expected.buyout and sent.quantity == expected.quantity)
        else
          local shown_buyout = expected.buyout > 0 and expected.buyout or nil
          check('fuzz ' .. seed .. ': gear was posted at the buyout shown', sent.buyout == shown_buyout)
        end
        say('posted ' .. expected.key)
      end
    end

    local function current_records()
      local s = search.current_search()
      return s and s.records or {}, s
    end

    local actions = {
      -- switch tabs
      function()
        if not open then return end
        tab = rnd(5)
        aux.set_tab(tab)
        say('tab ' .. tab)
      end,
      -- search something
      function()
        if not open then return end
        tab = 1
        aux.set_tab(1)
        if rnd(4) == 1 then search.set_full_search(rnd(2) == 1) end
        local text = SEARCHES[rnd(#SEARCHES)]
        search.search_box:SetText(text)
        search.execute(nil, false)
        say('search ' .. text)
      end,
      -- click a row of the results
      function()
        if not open or tab ~= 1 then return end
        local records, s = current_records()
        if #records > 0 then
          s.table:SetSelectedRecord(records[rnd(#records)])
        elseif s then
          s.table:SetSelectedRecord()
        end
      end,
      -- the buy bar
      press_buy,
      press_buy,
      function() if open then bar.bid_click() end end,
      function()
        if open and bar.chips and bar.chips[1] and bar.chips[1].__shown ~= false then
          local chip = bar.chips[rnd(4)]
          if chip.__shown and chip.__scripts.OnClick then chip.__scripts.OnClick(chip) end
        end
      end,
      -- pause, resume, live
      function() if open and tab == 1 then search.pause() end end,
      function() if open and tab == 1 and search.current_search().continuation then search.execute(nil, true) end end,
      function() if open and tab == 1 and rnd(3) == 1 then search.toggle_live() end end,
      -- the Post tab
      function()
        if not open then return end
        tab = 3
        aux.set_tab(3)
        local keys = {'2835:0', '7101:0', '7102:of the wolf', '2836:0'}
        post.select_item(keys[rnd(#keys)])
      end,
      function()
        if not open or tab ~= 3 or not post.selected_item then return end
        local prices = {'5c', '1s', '3s 20c', '2g', '', '0'}
        local box = post.unit_buyout_price_input
        local text = prices[rnd(#prices)]
        box.__scripts.OnEditFocusGained(box)
        box:SetText(text)
        box.__scripts.OnTextChanged(box, true)
        box.__scripts.OnEditFocusLost(box)
        box.__scripts.OnTextChanged(box, false)
      end,
      press_post,
      press_post,
      function() if open and tab == 3 and post.selected_item then post.refresh_button_click() end end,
      function() if open and tab == 3 then post.set_undercut_mode(rnd(2) == 1) end end,
      -- the Sniper
      function()
        if not open then return end
        tab = 2
        aux.set_tab(2)
        if sniper.running then sniper.stop() else sniper.start() end
        say('sniper ' .. (sniper.running and 'on' or 'off'))
      end,
      function()
        if not open or tab ~= 2 then return end
        local deals = sniper.shown_deals()
        if #deals > 0 and rnd(3) > 1 then
          sniper.listing:SetSelectedRecord(deals[rnd(#deals)])
        else
          sniper.listing:SetSelectedRecord()
        end
      end,
      -- the auction house: slower, faster, silent, listings change, it closes and opens
      function() server.delay = ({.1, .5, 1, 2, 6})[rnd(5)] end,
      function() server.browse_silent = rnd(4) == 1 end,
      function()
        if rnd(3) == 1 then server.page_size, server.more_silent = 1, rnd(2) == 1 else server.page_size, server.more_silent = nil, nil end
      end,
      function()
        local ids = {2835, 2836, 7101, 7103}
        local id = ids[rnd(#ids)]
        local list = server.listings[id]
        local what = rnd(3)
        if what == 1 and list[1] then
          list[1].quantity = math.max(0, list[1].quantity - rnd(5))
        elseif what == 2 then
          table.insert(list, {price = math.max(1, (list[1] and list[1].price or 10) - rnd(3) + 2), quantity = rnd(10)})
        elseif list[1] then
          list[1].price = list[1].price + rnd(5)
        end
      end,
      function()
        if rnd(5) ~= 1 then return end
        if open then
          env.fire('AUCTION_HOUSE_CLOSED')
          open = false
          say('closed')
        else
          env.fire('AUCTION_HOUSE_SHOW')
          open, tab = true, 1
          say('opened')
        end
      end,
    }

    -- whole errands, so that buying and posting happen often: each still waits a random time
    -- between its clicks, and the next action can cut in anywhere
    local function shop()
      if not open then return end
      tab = 1
      aux.set_tab(1)
      search.search_box:SetText(({'rough stone/exact', 'fuzz blade/exact', 'light feather/exact', 'fuzz staff'})[rnd(4)])
      search.execute(nil, false)
      server:ticks(rnd(60))
      local records, s = current_records()
      if #records == 0 then return end
      s.table:SetSelectedRecord(records[rnd(#records)])
      server:ticks(rnd(8))
      press_buy()
      server:ticks(rnd(40))
      press_buy()
      server:ticks(rnd(30))
    end
    local function snipe()
      if not open then return end
      tab = 2
      aux.set_tab(2)
      if not sniper.running then sniper.start() end
      server:ticks(rnd(150))
      local deals = sniper.shown_deals()
      if #deals == 0 then return end
      sniper.listing:SetSelectedRecord(deals[rnd(#deals)])
      server:ticks(rnd(50))
      press_buy()
      server:ticks(rnd(40))
      press_buy()
      server:ticks(rnd(30))
      if rnd(2) == 1 then sniper.listing:SetSelectedRecord() end
    end
    local function sell()
      if not open then return end
      tab = 3
      aux.set_tab(3)
      local keys = {'2835:0', '7101:0', '7102:of the wolf', '2836:0'}
      post.select_item(keys[rnd(#keys)])
      server:ticks(rnd(60))
      press_post()
      server:ticks(rnd(40))
    end
    -- the Auctions tab: look at your auctions, check their prices, cancel one. A cancel is only
    -- pressed when its button is lit, and must name an auction of your own.
    local function manage()
      if not open then return end
      tab = 4
      aux.set_tab(4)
      server:ticks(rnd(40))
      local what = rnd(4)
      if what == 1 then
        auctions.check_prices()
        server:ticks(rnd(60))
      end
      local records = auctions.listing.records or {}
      if #records > 0 and rnd(3) > 1 then
        auctions.listing:SetSelectedRecord(records[rnd(#records)])
      end
      server:ticks(rnd(6))
      local before = #server.cancels
      if what == 3 and auctions.cancel_button.aux_enabled ~= false then
        auctions.cancel_button.__scripts.OnClick(auctions.cancel_button)
      elseif what == 4 and auctions.cancel_undercut_button.aux_enabled ~= false then
        auctions.cancel_undercut_button.__scripts.OnClick(auctions.cancel_undercut_button)
      end
      for i = before + 1, #server.cancels do
        check('fuzz ' .. seed .. ': a cancel names an auction of your own that is still up', G.C_AuctionHouse.CanCancelAuction(server.cancels[i]) == true)
        say('cancelled auction ' .. server.cancels[i])
      end
      server:ticks(rnd(30))
    end
    for _, errand in ipairs{shop, shop, snipe, sell, sell, manage, manage} do actions[#actions + 1] = errand end
    if pad_mode then
      local PAD = {'up', 'down', 'left', 'right', 'A', 'A', 'B', 'X', 'Y', 'Y', 'LB', 'RB'}
      for _ = 1, 12 do
        actions[#actions + 1] = function()
          for _ = 1, rnd(4) do pad(PAD[rnd(#PAD)]) end
          -- B can close aux; the player opens the auction house again
          if open and not aux.frame.__shown then
            -- closing aux's window closes the auction house, and the game says so
            env.fire('AUCTION_HOUSE_CLOSED')
            open = false
            say('closed with the pad')
          end
          tab = aux.get_tab() and ({Search = 1, Sniper = 2, Post = 3, Auctions = 4, Bids = 5})[aux.get_tab().name] or tab
        end
      end
      -- a fight starts or ends
      actions[#actions + 1] = function()
        if not combat then
          env.fire('PLAYER_REGEN_DISABLED')
          combat = true
        else
          combat = false
          env.fire('PLAYER_REGEN_ENABLED')
        end
      end
    end

    for step = 1, steps do
      actions[rnd(#actions)]()
      server:ticks(rnd(12))
      if env.errors() > errors_before then
        check('fuzz ' .. seed .. ': a Lua error at step ' .. step .. ' (run again with AUX_FUZZ_SEED=' .. seed .. ' to see the steps)', false)
        break
      end
    end

    -- the player stops; the auction house answers again and everything settles
    if combat then
      combat = false
      env.fire('PLAYER_REGEN_ENABLED')
    end
    if not open then
      env.fire('AUCTION_HOUSE_SHOW')
      open = true
    end
    server.delay, server.browse_silent, server.page_size, server.more_silent = .2, false, nil, nil
    if sniper.running then sniper.stop() end
    sniper.listing:SetSelectedRecord()
    aux.set_tab(1)
    tab = 1
    if search.mode == search.LIVE_MODE then search.toggle_live() end
    local s = search.current_search()
    if s and s.mode == search.LIVE_MODE and (s.active or s.continuation) then search.toggle_live() end
    if search.mode == search.LIVE_MODE then search.toggle_live() end
    scan.abort()
    bar.clear()
    -- long enough for a 20 second wait, a 60 second post confirmation and the row re-read after a buy
    server:ticks(700)

    local spent = 0
    for _, purchase in ipairs(server.purchases) do spent = spent + purchase.total end
    env.fuzz_totals = env.fuzz_totals or {purchases = 0, posts = 0, deals = 0, runs = 0, cancels = 0}
    env.fuzz_totals.cancels = env.fuzz_totals.cancels + #server.cancels
    env.fuzz_totals.purchases = env.fuzz_totals.purchases + #server.purchases
    env.fuzz_totals.posts = env.fuzz_totals.posts + #server.posts
    env.fuzz_totals.deals = env.fuzz_totals.deals + #sniper.deals
    env.fuzz_totals.runs = env.fuzz_totals.runs + 1
    local clean = env.errors() == errors_before
    check('fuzz ' .. seed .. ': no Lua error', clean)
    check('fuzz ' .. seed .. ': never spent more than the buttons showed (' .. spent .. ' spent, ' .. shown_spend .. ' shown)', spent <= shown_spend)
    check('fuzz ' .. seed .. ': the money left matches what was bought', server.money == 5000000 - spent)
    check('fuzz ' .. seed .. ': no search is left running', not scan.is_scanning())
    check('fuzz ' .. seed .. ': no purchase is left under way', not bar.busy() and not aux.bid_in_progress())
    post.validate_parameters()
    check('fuzz ' .. seed .. ': no post is left under way', post.posting == nil)
    check('fuzz ' .. seed .. ': no threads are left behind (' .. aux.thread_count() .. ' now, ' .. threads_before .. ' before)', aux.thread_count() <= threads_before)
    check('fuzz ' .. seed .. ': no listeners are left behind (' .. aux.listener_count() .. ' now, ' .. listeners_before .. ' before)', aux.listener_count() <= listeners_before)

    -- back to how the other tests left things
    rawset(C, 'ConfirmCommoditiesPurchase', nil)
    rawset(C, 'PlaceBid', nil)
    if pad_mode then
      aux.frame:Hide()
      G.SetOverrideBindingClick, G.ClearOverrideBindings, G.InCombatLockdown, G.InputUtil = real_pad[1], real_pad[2], real_pad[3], real_pad[4]
      aux.frame:Show()
    end
    rawset(G.DEFAULT_CHAT_FRAME, 'AddMessage', nil)
    for _, box in ipairs{post.stack_size_input, post.stack_count_input} do
      rawset(box, 'SetNumber', nil); rawset(box, 'GetNumber', nil)
    end
    rawset(post.duration_dropdown, 'GetIndex', nil)
    post.set_undercut_mode(false)
    aux.account_data.sniper_profit, aux.account_data.sniper_percent = old_profit, old_percent
    search.set_full_search(old_full)
    set_search('auxForever', addon, 'FOLD_KEEP', 20)
    set_search('auxForever', addon, 'REFILL_AT', 5)
    sniper.clear_deals()
    sniper.settings_changed()
    bar.clear()
    aux.set_tab(1)
    search.frame:Hide()
    server:restore()
    return clean
  end

  local one = tonumber(os.getenv('AUX_FUZZ_SEED') or '')
  local seeds = tonumber(os.getenv('AUX_FUZZ_SEEDS') or '') or 6
  local steps = tonumber(os.getenv('AUX_FUZZ_STEPS') or '') or 120
  if one then
    try('fuzz: seed ' .. one, function() run(one, steps, true) end)
  else
    for seed = 1, seeds do
      try('fuzz: seed ' .. seed, function() run(seed, steps) end)
    end
  end
  -- what the random players got done, so a change that stops them from buying or posting shows
  local totals = env.fuzz_totals
  if totals and os.getenv('AUX_FUZZ_SEEDS') then
    print(string.format('fuzz: %d runs, %d purchases, %d posts, %d cancels, %d Sniper deals at the end', totals.runs, totals.purchases, totals.posts, totals.cancels, totals.deals))
  end
end
