-- auxForever tests: what players do while the auction house is still answering (2026-10-18).
--
-- Run by load_test.lua with the slow auction house of tests/slow_server.lua. Each test plays out
-- what a player does, click by click, while answers arrive a second later, and checks what the
-- addon finally sent to the auction house (the price posted, the amount bought), not only what it
-- shows.

return function(env)
  local G, check, try, addon, dir = env.G, env.check, env.try, env.addon, env.dir
  local rawset = env.rawset -- a nil puts back what a swapped field held (load_test.lua)
  local new_server = dofile(dir .. 'slow_server.lua')

  local function module(name)
    return loadstring("select(2, ...) '" .. name .. "'; return _M")('auxForever', addon)
  end
  local aux = loadstring("select(2, ...) 'aux.test.timing'; return require 'aux'")('auxForever', addon)
  local money = loadstring("select(2, ...) 'aux.test.timing'; return require 'aux.util.money'")('auxForever', addon)

  -- a player typing into an edit box: focus, one key at a time, then Enter (which ends the focus)
  local function type_into(box, text)
    box.__scripts.OnEditFocusGained(box)
    if text == '' then -- the old text selected and deleted
      box:SetText('')
      box.__scripts.OnTextChanged(box, true)
    end
    for i = 1, #text do
      box:SetText(text:sub(1, i))
      box.__scripts.OnTextChanged(box, true)
    end
    box.__scripts.OnEnterPressed(box)
    box.__scripts.OnEditFocusLost(box)
    box.__scripts.OnTextChanged(box, false)
  end

  -- the Post tab with a bag of Rough Stone (Sarrath's item, FB-021) and listings at 7c and 8c
  local function post_setup(server, opts)
    opts = opts or {}
    local post = module 'aux.tabs.post'
    server.items[2835] = {name = 'Rough Stone', commodity = true, vendor = 1}
    server.items[7001] = {name = 'Sword', commodity = false, vendor = 100}
    server.listings[2835] = {{price = 7, quantity = 40}, {price = 8, quantity = 25}}
    server.listings[7001] = {{price = 20000, quantity = 1}, {price = 25000, quantity = 1}}
    server.bag = {{id = 2835, count = 20}, {id = 7001, count = 1}}
    server:install()
    -- the quantity boxes and the duration keep what is set (the stubs return a fixed number)
    for _, box in ipairs{post.stack_size_input, post.stack_count_input} do
      local n = 1
      rawset(box, 'SetNumber', function(self, v) n = math.max(0, math.min(v, self.max_value or v)) end)
      rawset(box, 'GetNumber', function() return n end)
    end
    rawset(post.duration_dropdown, 'GetIndex', function() return 2 end)
    post.set_undercut_mode(opts.undercut or false)
    aux.set_tab(3) -- Search 1, Sniper 2, Post 3
    return post
  end

  -- a click on Post, as in the game: a faded Post button takes no clicks. The addon fades it when
  -- it has a reason (validate_parameters, five times a second).
  local function click_post(post)
    post.validate_parameters()
    if post.selected_item and not post.disabled_reason() then
      post.post_button.__scripts.OnClick(post.post_button)
      return true
    end
    return false
  end

  local function post_teardown(server, post)
    aux.set_tab(1)
    post.set_undercut_mode(false)
    for _, box in ipairs{post.stack_size_input, post.stack_count_input} do
      rawset(box, 'SetNumber', nil); rawset(box, 'GetNumber', nil)
    end
    rawset(post.duration_dropdown, 'GetIndex', nil)
    server:restore()
  end

  local function listings_in(post)
    -- what the player sees: the status bar turns gold once the listings are in
    return function() return aux.status_bar.done and post.selected_item and post.selected_item.key == '2835:0' end
  end

  -- FB-021 (sarrathsilentstrider, 2026-10-18): "Rough Stone is on the AH for 7c and I am trying to
  -- post it for 5c and AUX will not let me. 6c is fine, but I cannot do 5c."
  try('timing: FB-021 a price typed after the listings are in is posted', function()
    local server = new_server(env)
    local post = post_setup(server)
    post.select_item('2835:0')
    check('FB-021: the listings arrive', server:wait(listings_in(post), 50))
    server:ticks(3)
    check('FB-021: starts at the lowest listing, 7c', post.get_unit_buyout_price() == 7)
    type_into(post.unit_buyout_price_input, '5c')
    server:ticks(5)
    check('FB-021: the typed 5c is kept', post.get_unit_buyout_price() == 5)
    click_post(post)
    server:ticks(15)
    local sent = server.posts[1]
    check('FB-021: 5c is what the auction house receives', sent and sent.unit_price == 5)
    post_teardown(server, post)
  end)

  try('timing: FB-021 a price typed while the listings load is kept', function()
    local server = new_server(env)
    local post = post_setup(server)
    post.select_item('2835:0')
    server:ticks(2) -- the listings are still on their way
    check('FB-021: still waiting for the listings', not aux.status_bar.done)
    type_into(post.unit_buyout_price_input, '5c')
    check('FB-021: the listings arrive', server:wait(listings_in(post), 50))
    server:ticks(5)
    check('FB-021: a price typed before the listings arrived is not replaced', post.get_unit_buyout_price() == 5)
    click_post(post)
    server:ticks(15)
    local sent = server.posts[1]
    check('FB-021: and 5c is what is posted', sent and sent.unit_price == 5)
    post_teardown(server, post)
  end)

  try('timing: FB-021 undercut mode and a typed price', function()
    local server = new_server(env)
    local post = post_setup(server, {undercut = true})
    post.select_item('2835:0')
    check('FB-021: the listings arrive', server:wait(listings_in(post), 50))
    server:ticks(3)
    check('FB-021: undercut starts one copper below, 6c', post.get_unit_buyout_price() == 6)
    type_into(post.unit_buyout_price_input, '5c')
    server:ticks(5)
    check('FB-021: undercut mode keeps a typed 5c', post.get_unit_buyout_price() == 5)
    click_post(post)
    server:ticks(15)
    local sent = server.posts[1]
    check('FB-021: undercut mode posts the typed 5c', sent and sent.unit_price == 5)
    post_teardown(server, post)
  end)

  -- FB-021 follow-up: until the listings are in, the price shown is the one remembered from the
  -- last visit. Post waits for the listings unless the player typed a price.
  try('timing: Post waits for the listings', function()
    local server = new_server(env)
    local post = post_setup(server)
    post.select_item('2835:0')
    post.set_unit_buyout_price(3000) -- remembered from an earlier visit
    server:ticks(1)
    post.validate_parameters()
    check('post waits: says it is reading the listings', post.disabled_reason() == 'Reading the listings...')
    click_post(post)
    server:ticks(2)
    check('post waits: nothing posted at the old price', #server.posts == 0)
    check('post waits: the listings arrive', server:wait(listings_in(post), 50))
    server:ticks(3)
    post.validate_parameters()
    check('post waits: then Post is ready at the lowest listing', post.disabled_reason() == nil and post.get_unit_buyout_price() == 7)
    click_post(post)
    server:ticks(15)
    check('post waits: and posts at 7c', server.posts[1] and server.posts[1].unit_price == 7 and #server.posts == 1)
    post_teardown(server, post)
  end)

  try('timing: a typed price can be posted before the listings arrive', function()
    local server = new_server(env)
    local post = post_setup(server)
    post.select_item('2835:0')
    server:ticks(1)
    type_into(post.unit_buyout_price_input, '6c')
    post.validate_parameters()
    check('typed early: Post is ready', post.disabled_reason() == nil)
    click_post(post)
    server:ticks(30)
    check('typed early: posts the typed 6c', server.posts[1] and server.posts[1].unit_price == 6)
    post_teardown(server, post)
  end)

  -- buying a trade good from the buy bar: the price is asked first, then confirmed, each answered
  -- a second later. What the server charged is checked, not only what the bar says.
  local function buy_setup(server)
    local bar = module 'aux.gui.buy_bar'
    server.items[2589] = {name = 'Linen Cloth', commodity = true, max_stack = 200}
    server.listings[2589] = {{price = 6, quantity = 6}, {price = 7, quantity = 100}}
    server:install()
    local bought
    local function tiers()
      local list = {}
      for _, l in ipairs(server.listings[2589]) do
        if l.quantity > 0 then table.insert(list, {count = l.quantity, commodity_unit_price = l.price}) end
      end
      return list
    end
    bar.show_commodity{item_id = 2589, name = 'Linen Cloth', max_stack = 20, tiers = tiers,
      on_success = function(n) bought = n end, on_refresh = function() end}
    server:ticks(1)
    return bar, function() return bought end
  end

  local function plain(t) return ((t or ''):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('FONT_COLOR_CODE_CLOSE', '')) end

  try('timing: buying a trade good, answered a second later', function()
    local server = new_server(env)
    local bar, bought = buy_setup(server)
    check('buy: starts at one stack', bar.primary_label():find('^Buy 20 for') ~= nil)
    bar.primary_click()
    bar.primary_click() -- a second click while the price is asked does nothing
    check('buy: one price request', #server.requests == 1)
    check('buy: the price arrives', server:wait(function() return bar.primary_label():find('^Confirm') end, 30))
    bar.primary_click()
    bar.primary_click() -- a double click on Confirm buys once
    check('buy: the purchase arrives', server:wait(function() return bought() end, 30))
    check('buy: bought once, 20 for 1s 34c', #server.purchases == 1 and server.purchases[1].quantity == 20 and server.purchases[1].total == 134)
    server:restore()
    bar.clear()
  end)

  try('timing: someone buys the cheap ones while the price is asked', function()
    local server = new_server(env)
    local bar, bought = buy_setup(server)
    bar.primary_click()
    server.listings[2589][1].quantity = 0 -- the 6 at 6c sell to someone else meanwhile
    server:ticks(30)
    check('buy: a higher price is never confirmed', #server.purchases == 0 and not bought())
    local l1 = plain(bar.lines())
    check('buy: says the price went up', l1:find('price went up', 1, true) ~= nil)
    server:restore()
    bar.clear()
  end)

  -- a purchase the server confirms after the bar stopped waiting (10 seconds) still went through:
  -- the bar must not say "Nothing was bought", or the player may buy again
  try('timing: a purchase that is answered late', function()
    local server = new_server(env)
    local bar, bought = buy_setup(server)
    bar.primary_click()
    server:wait(function() return bar.primary_label():find('^Confirm') end, 30)
    server.delay = 12
    bar.primary_click()
    server:ticks(110) -- 11 seconds: the bar has stopped waiting, the server has not answered yet
    local l1, l2 = bar.lines()
    check('late buy: does not say nothing was bought', not plain(l2):find('Nothing was bought', 1, true))
    check('late buy: says it may still go through', (plain(l1) .. ' ' .. plain(l2)):find('may still', 1, true) ~= nil)
    server:ticks(20)
    check('late buy: it did go through', #server.purchases == 1)
    server:restore()
    bar.clear()
  end)

  -- gear from the Search tab: a search, a click on a row, Buy; the auction house answers later
  local function gear_setup(server)
    local search = module 'aux.tabs.search'
    local bar = module 'aux.gui.buy_bar'
    server.items[7001] = {name = 'Sword', commodity = false}
    server.listings[7001] = {{price = 20000, quantity = 2}, {price = 25000, quantity = 1}}
    server:install()
    aux.set_tab(1)
    search.frame:Show()
    search.update_mode(search.NORMAL_MODE)
    local before = search.current_search()
    search.search_box:SetText('sword/exact')
    search.execute(nil, false)
    server:wait(function() local s = search.current_search(); return s and s.complete and #s.records > 0 end, 100)
    local s = search.current_search()
    local cheapest
    for _, r in ipairs(s.records) do
      if not cheapest or r.buyout_price < cheapest.buyout_price then cheapest = r end
    end
    s.table:SetSelectedRecord(cheapest) -- the player clicks its row
    server:ticks(1)
    return search, bar, cheapest
  end

  try('timing: buying gear from a search, answered a second later', function()
    local server = new_server(env)
    local search, bar, record = gear_setup(server)
    check('gear: the search found the sword', record and record.buyout_price == 20000)
    check('gear: the bar shows its price', bar.primary_label():find('^Buy for') ~= nil)
    bar.primary_click()
    bar.primary_click() -- a second click before the answer buys nothing more
    server:ticks(20)
    check('gear: bought one, at the price shown', #server.purchases == 1 and server.purchases[1].total == 20000)
    server:ticks(80) -- the row of identical auctions is read again after a purchase
    check('gear: the next one at that price is ready', record.auction_count == 1 and not record.syncing)
    search.frame:Hide()
    server:restore()
    bar.clear()
  end)

  -- aux stops waiting for a purchase after 5 seconds; one answered later still went through
  try('timing: buying gear, answered late', function()
    local server = new_server(env)
    local search, bar = gear_setup(server)
    server.delay = 7
    bar.primary_click()
    server:ticks(55)
    local l1, l2 = bar.lines()
    check('late gear buy: says it may still go through', (plain(l1) .. ' ' .. plain(l2)):find('may still', 1, true) ~= nil)
    server:ticks(30)
    check('late gear buy: it did go through', #server.purchases == 1)
    search.frame:Hide()
    server:restore()
    bar.clear()
  end)

  -- after buying one of several identical auctions, aux reads that item again. It used to stop
  -- any search running at that moment, so a search the player started right after buying was cut
  -- off without a word.
  try('timing: a search started right after buying gear finishes', function()
    local server = new_server(env)
    local search, bar = gear_setup(server)
    server.items[2589] = {name = 'Linen Cloth', commodity = true, max_stack = 200}
    server.listings[2589] = {{price = 6, quantity = 50}}
    bar.primary_click()
    server:ticks(12) -- bought; aux is reading the sword's listings again
    search.search_box:SetText('linen cloth/exact')
    search.execute(nil, false)
    local done = server:wait(function()
      local s = search.current_search()
      return s and s.complete and s.filter_string == 'linen cloth/exact'
    end, 150)
    local s = search.current_search()
    check('search after buying: it finishes', done)
    check('search after buying: it found the linen', s and #s.records > 0 and s.records[1].item_id == 2589)
    server:ticks(80)
    search.frame:Hide()
    server:restore()
    bar.clear()
  end)

  -- leaving the Post tab while a post waits for its answer, and the answer never comes: the Post
  -- tab must not stay on "Posting..." when the player comes back
  try('timing: leaving the Post tab during a post that is never answered', function()
    local server = new_server(env)
    local post = post_setup(server)
    post.select_item('2835:0')
    server:wait(listings_in(post), 50)
    server:ticks(3)
    server.delay = 1000 -- the auction house never answers
    check('left mid-post: posted', click_post(post))
    aux.set_tab(1)
    server:ticks(700) -- 70 seconds on another tab
    server.delay = 1
    aux.set_tab(3)
    post.select_item('2835:0')
    server:wait(listings_in(post), 50)
    server:ticks(3)
    post.validate_parameters()
    check('left mid-post: Post works again', post.disabled_reason() == nil)
    post_teardown(server, post)
  end)

  -- the Sniper: a round reads the item list, then opens each item that looks like a deal (one
  -- request each). Clicking a deal stops the round; the items it had not opened yet must be opened
  -- in a later round, or those deals are never found until their price changes.
  -- 0.8.2 build 7 (H-010): the rounds go on while a trade good is selected. Buy clicked in the
  -- middle of a round: the round stops before the price is asked, the purchase is the amount shown
  -- at or below the price shown, and the rounds go on after it.
  try('timing: Sniper buys a selected trade good while a round runs', function()
    local server = new_server(env)
    local sniper = module 'aux.tabs.sniper'
    local bar = module 'aux.gui.buy_bar'
    server.items[9101] = {name = 'Heavy Leather', commodity = true, vendor = 50, max_stack = 20}
    server.listings[9101] = {{price = 20, quantity = 5}, {price = 60, quantity = 40}}
    for i = 1, 3 do
      server.items[9110 + i] = {name = 'Other ' .. i, commodity = true, vendor = 50, max_stack = 20}
      server.listings[9110 + i] = {{price = 60, quantity = 5}}
    end
    server:install()
    aux.account_data.sniper_profit = 1
    sniper.clear_deals()
    aux.set_tab(2) -- Search 1, Sniper 2
    sniper.start()
    local deal
    check('sniper buy: the deal is found', server:wait(function()
      for _, d in ipairs(sniper.deals) do if d.item_id == 9101 then deal = d end end
      return deal ~= nil
    end, 200))
    deal.deal_read_at = G.GetTime()
    sniper.listing:SetSelectedRecord(deal)
    check('sniper buy: a round runs while it is selected', server:wait(function() return sniper.active end, 200))
    server:ticks(3)
    check('sniper buy: the bar offers the 5 below vendor price', bar.primary_label():find('^Buy 5 for') ~= nil)
    check('sniper buy: the round still runs when Buy is clicked', sniper.active)
    local before = #server.requests
    bar.primary_click()
    check('sniper buy: the price arrives', server:wait(function() return bar.primary_label():find('^Confirm') end, 30))
    check('sniper buy: the round stopped for it', not sniper.active)
    bar.primary_click()
    check('sniper buy: the purchase arrives', server:wait(function() return #server.purchases > 0 end, 30))
    check('sniper buy: 5 bought for 1s, no more than shown', #server.purchases == 1 and server.purchases[1].quantity == 5 and server.purchases[1].total == 100)
    local between = {}
    for i = before + 1, #server.requests do table.insert(between, server.requests[i]) end
    check('sniper buy: nothing else was sent between the price and the purchase', table.concat(between, ', ') == 'quote 9101 5, confirm 9101 5')
    local r = sniper.round
    check('sniper buy: the rounds go on after it', server:wait(function() return sniper.round > r end, 300))
    sniper.listing:SetSelectedRecord()
    sniper.stop()
    aux.account_data.sniper_profit = 500
    sniper.clear_deals()
    bar.clear()
    aux.set_tab(1)
    server:restore()
  end)

  try('timing: Sniper items not yet opened when a round stops are opened later', function()
    local server = new_server(env)
    local sniper = module 'aux.tabs.sniper'
    for i = 1, 4 do
      server.items[9000 + i] = {name = 'Thing ' .. i, commodity = false, vendor = 5000}
      server.listings[9000 + i] = {{price = 1000, quantity = 1}}
    end
    server:install()
    sniper.clear_deals()
    aux.set_tab(2) -- Search 1, Sniper 2
    sniper.start()
    check('sniper: a first deal is found', server:wait(function() return #sniper.deals >= 1 end, 100))
    server:ticks(6)
    check('sniper: not all found yet', #sniper.deals < 4)
    sniper.listing:SetSelectedRecord(sniper.deals[1]) -- the player clicks it; the round stops
    server:ticks(30)
    sniper.listing:SetSelectedRecord() -- and lets go of it; the rounds go on
    check('sniper: the other deals are found in a later round', server:wait(function() return #sniper.deals >= 4 end, 300))
    sniper.stop()
    sniper.clear_deals()
    aux.set_tab(1)
    server:restore()
  end)

  -- a bag change that has nothing to do with the post (loot, a quest item) while the post waits for
  -- its answer: aux must not say "Not posted" and let Post be clicked again before the answer
  try('timing: an unrelated bag change while a post waits', function()
    local server = new_server(env)
    local post = post_setup(server)
    post.select_item('2835:0')
    server:wait(listings_in(post), 50)
    server:ticks(3)
    post.stack_count_input:SetNumber(5)
    check('bag change: posted', click_post(post))
    server:ticks(2)
    env.fire('BAG_UPDATE', 1) -- something else changed in another bag
    server:ticks(2)
    post.validate_parameters()
    check('bag change: still waiting for the answer', post.disabled_reason() == 'Posting...')
    server:ticks(20)
    check('bag change: posted once', #server.posts == 1)
    local shown = plain(post.post_message.__text)
    check('bag change: says it was posted', shown:find('Posted 5', 1, true) ~= nil)
    post_teardown(server, post)
  end)

  -- the auction house closed in the middle of a post and of a purchase, then opened again:
  -- nothing may stay stuck
  try('timing: closing the auction house mid-post and mid-purchase', function()
    local server = new_server(env)
    local post = post_setup(server)
    post.select_item('2835:0')
    server:wait(listings_in(post), 50)
    server:ticks(3)
    post.stack_count_input:SetNumber(5)
    check('closed mid-post: posted', click_post(post))
    env.fire('AUCTION_HOUSE_CLOSED')
    server:ticks(30)
    check('closed mid-post: the post still went through', #server.posts == 1 and server:bag_count(2835) == 15)
    env.fire('AUCTION_HOUSE_SHOW')
    server:ticks(2)
    aux.set_tab(3)
    post.select_item('2835:0')
    server:wait(listings_in(post), 50)
    server:ticks(3)
    post.validate_parameters()
    check('closed mid-post: Post works after opening again', post.disabled_reason() == nil)
    post_teardown(server, post)

    server = new_server(env)
    local bar, bought = buy_setup(server)
    bar.primary_click()
    env.fire('AUCTION_HOUSE_CLOSED')
    server:ticks(20)
    check('closed mid-quote: nothing bought', #server.purchases == 0)
    env.fire('AUCTION_HOUSE_SHOW')
    server:ticks(2)
    server:restore()
    server = new_server(env)
    bar, bought = buy_setup(server)
    bar.primary_click()
    check('closed mid-quote: a new price arrives after opening again', server:wait(function() return bar.primary_label():find('^Confirm') end, 30))
    bar.primary_click()
    check('closed mid-quote: and the purchase goes through', server:wait(function() return bought() end, 30))
    server:restore()
    bar.clear()
    aux.set_tab(1)
  end)

  -- gear with an empty starting bid and a typed buyout: Blizzard's sell frame posts it as buyout
  -- only. aux asked for a price instead (and would have sent a 1s bid). Same kind as FB-021: a rule
  -- the game does not have.
  try('timing: gear with only a buyout can be posted', function()
    local server = new_server(env)
    local post = post_setup(server)
    post.select_item('7001:0')
    check('buyout only: the listings arrive', server:wait(function() return aux.status_bar.done and post.selected_item and post.selected_item.key == '7001:0' end, 80))
    server:ticks(3)
    type_into(post.unit_start_price_input, '')
    type_into(post.unit_buyout_price_input, '1g 90s')
    post.validate_parameters()
    check('buyout only: Post is ready', post.disabled_reason() == nil)
    check('buyout only: the note says so', plain(post.price_note_text()):find('No starting bid', 1, true) ~= nil)
    click_post(post)
    server:ticks(20)
    local sent = server.posts[1]
    check('buyout only: posted with no bid at 1g 90s', sent and sent.bid == nil and sent.buyout == 19000)
    post_teardown(server, post)
  end)

  -- gear versions (0.8): a Medicine Staff of the Wolf in the bags, and on the auction house
  -- cheaper staffs with other endings. The Post tab prices and posts the Wolf against Wolf listings
  -- only, as Blizzard's Sell window does; before, every ending looked alike to aux (the link's
  -- suffix field is empty on Forever, seen 2026-10-20) and the Wolf was priced at an Arcane
  -- Protection staff's price.
  try('timing: gear is posted against its own ending', function()
    local server = new_server(env)
    local post = module 'aux.tabs.post'
    server.items[4575] = {name = 'Medicine Staff', commodity = false, vendor = 1487,
      versions = {[101] = 'of the Bandit', [102] = 'of Arcane Protection', [103] = 'of Arcane Protection', [104] = 'of the Wolf', [105] = 'of the Whale', [106] = 'of the Wolf'}}
    -- an item nobody sells at all
    server.items[4576] = {name = 'Sturdy Stick', commodity = false, vendor = 100}
    -- the Wolf is the last version the auction house lists (Tyler, build 4: Merc Sword of Agility
    -- had 4 listed, but the Post tab found none when another ending came first)
    server.listings[4575] = {
      {price = 11500, quantity = 1, version = 101},
      {price = 11000, quantity = 1, version = 102},
      {price = 11500, quantity = 1, version = 103},
      {price = 15000, quantity = 1, version = 104},
      -- a second version of the same name, read after the first and cheaper: the Post tab must read
      -- every version (Tyler, build 5: "the numbers dont add up")
      {price = 14000, quantity = 1, version = 106},
    }
    server.bag = {{id = 4575, count = 1, version = 104}, {id = 4575, count = 1, version = 101}, {id = 4575, count = 1, version = 105}, {id = 4576, count = 1}}
    server:install()
    -- a usual price of its own, so a price taken from it cannot pass for the Wolf listing's (it did
    -- in build 3: the listings were never shown and the usual price happened to match)
    local h = module 'aux.core.history'
    h.write_record('4575:of the wolf', {day = h.today(), points = {{day = h.today() - 1, value = 21000}}})
    -- the quantity boxes and the duration keep what is set, as in post_setup
    for _, box in ipairs{post.stack_size_input, post.stack_count_input} do
      local n = 1
      rawset(box, 'SetNumber', function(self, v) n = math.max(0, math.min(v, self.max_value or v)) end)
      rawset(box, 'GetNumber', function() return n end)
    end
    rawset(post.duration_dropdown, 'GetIndex', function() return 2 end)
    post.set_undercut_mode(false)
    aux.set_tab(3)
    server:ticks(2)
    post.select_item('4575:of the bandit')
    check('gear: the Bandit staff is its own item in the bag list', post.selected_item and post.selected_item.key == '4575:of the bandit')
    local requests_before = #server.requests
    post.select_item('4575:of the wolf')
    check('gear: and so is the Wolf staff', post.selected_item and post.selected_item.key == '4575:of the wolf')
    check('gear: each is named with its ending', post.selected_item and post.selected_item.name == 'Medicine Staff of the Wolf')
    check('gear: the listings arrive', server:wait(function() return aux.status_bar.done and post.selected_item and post.selected_item.key == '4575:of the wolf' end, 150))
    server:ticks(3)
    check('gear: priced against the cheapest Wolf of every version, not the cheaper endings', post.get_unit_buyout_price() == 14000)
    -- only the Wolf's own two versions are searched; the other endings' lowest prices come from the
    -- item list (Tyler, build 7: a Merc Sword took about 25 requests)
    local searches = 0
    for i = requests_before + 1, #server.requests do
      if server.requests[i]:find('^search ') then searches = searches + 1 end
    end
    check('gear: only the versions of its own name are searched', searches == 2)
    check('gear: the Wolf listing is shown in the table', plain(post.price_note_text()):find('lowest listing', 1, true) ~= nil)
    click_post(post)
    server:ticks(20)
    local sent = server.posts[1]
    check('gear: the Wolf staff is posted at the Wolf price', sent and sent.version == 104 and sent.buyout == 14000 and #server.posts == 1)
    post.validate_parameters()
    check('gear: the post is over', post.disabled_reason() ~= 'Posting...')
    -- read until the Post tab itself has the listings (the bar can still show the last item's)
    local function read_done(key)
      return function()
        post.validate_parameters()
        return post.selected_item and (not key or post.selected_item.key == key) and post.disabled_reason() ~= 'Reading the listings...' and server:pending() == 0
      end
    end
    -- after a post the Post tab picks the next item and reads it; that read ends first. (Picked
    -- before its item list came back, the late list was taken for the next item's: experiment E7 in
    -- docs/forever-auction-house.md, not yet known to happen in game.)
    server:wait(read_done(nil), 200)
    -- an ending nobody sells: the cheapest other ending is suggested, said as such
    post.select_item('4575:of the whale')
    check('gear: the Whale staff is read', server:wait(read_done('4575:of the whale'), 200))
    server:ticks(3)
    post.validate_parameters()
    check('gear: none of its name for sale: the cheapest other ending is suggested', post.get_unit_buyout_price() == 11000)
    check('gear: and the note says where the price comes from', plain(post.price_note_text()):find('None of this name for sale', 1, true) ~= nil)
    -- nothing of the item for sale at all: it says so
    post.select_item('4576:0')
    check('gear: the stick is read', server:wait(read_done('4576:0'), 200))
    server:ticks(3)
    post.validate_parameters()
    check('gear: none for sale, and it says so', post.disabled_reason() == 'None for sale. Type a price to post.')
    post_teardown(server, post)
  end)

  -- Gemini's review, finding 1 (H-002): one gear name listed under two versions. A full search reads
  -- each version on its own; the day's market of the name must count both, not only the last read.
  -- Reading one version alone afterwards (a Sniper candidate) must not replace that.
  try('timing: the versions of one gear name add up (review H-002, finding 1)', function()
    local server = new_server(env)
    local search = module 'aux.tabs.search'
    local h = module 'aux.core.history'
    local scan = loadstring("select(2, ...) 'aux.test.h002t'; return require 'aux.core.scan'")('auxForever', addon)
    server.items[4577] = {name = 'Ritual Belt', commodity = false,
      versions = {[201] = 'of Arcane Protection', [202] = 'of Arcane Protection', [203] = 'of the Owl'}}
    server.listings[4577] = {
      {price = 600, quantity = 2, version = 201},
      {price = 650, quantity = 3, version = 202},
      {price = 900, quantity = 1, version = 203},
    }
    server:install()
    aux.set_tab(1)
    search.frame:Show()
    search.update_mode(search.NORMAL_MODE)
    search.search_box:SetText('ritual belt/exact')
    search.execute(nil, false)
    check('versions: the search finishes', server:wait(function() local s = search.current_search(); return s and s.complete and #s.records > 0 end, 200))
    local _, units = h.today_market('4577:of arcane protection')
    check('versions: both versions of the name counted (2 + 3 units)', units == 5)
    local _, owl = h.today_market('4577:of the owl')
    check('versions: another ending is apart', owl == 1)
    -- one version read alone: today's lowest only, the full view stays
    local done
    local filter_util = loadstring("select(2, ...) 'aux.test.h002t2'; return require 'aux.util.filter'")('auxForever', addon)
    scan.start{type = 'list', quiet = true, queries = filter_util.queries('ritual belt/exact'),
      on_item_list = function() scan.read_item(server:key(4577, 202)); done = true end}
    server:wait(function() return done end, 150)
    check('versions: the one-version read ran', done)
    _, units = h.today_market('4577:of arcane protection')
    check('versions: one version read alone does not replace the full view', units == 5)
    search.frame:Hide()
    server:restore()
  end)

  -- Gemini's release review (H-006, finding 3): a search stopped after one version of an item must
  -- not replace the day's price, read from all its versions, with that one version's
  try('timing: a search stopped between versions keeps the full price (review H-006, finding 3)', function()
    local server = new_server(env)
    local search = module 'aux.tabs.search'
    local h = module 'aux.core.history'
    local scan = loadstring("select(2, ...) 'aux.test.h006t'; return require 'aux.core.scan'")('auxForever', addon)
    local filter_util = loadstring("select(2, ...) 'aux.test.h006t2'; return require 'aux.util.filter'")('auxForever', addon)
    server.items[4592] = {name = 'Bandit Boots', commodity = false, versions = {[221] = 'of the Owl', [222] = 'of the Owl'}}
    server.listings[4592] = {{price = 5000, quantity = 1, version = 221}, {price = 1000, quantity = 10, version = 222}}
    server:install()
    aux.set_tab(1)
    search.frame:Show()
    search.update_mode(search.NORMAL_MODE)
    search.search_box:SetText('bandit boots/exact')
    search.execute(nil, false)
    check('stopped: the full search finishes', server:wait(function() local s = search.current_search(); return s and s.complete and #s.records > 0 end, 200))
    local market, units = h.today_market('4592:of the owl')
    check('stopped: both versions counted', units == 11 and market == 1000)
    local stopped
    scan.start{type = 'list', queries = filter_util.queries('bandit boots/exact'),
      on_page_scanned = function() scan.abort() end, on_abort = function() stopped = true end}
    server:wait(function() return stopped end, 150)
    market, units = h.today_market('4592:of the owl')
    check('stopped: the search was stopped after one version', stopped == true)
    check('stopped: the day\'s price is still the one from both versions', units == 11 and market == 1000)
    search.frame:Hide()
    server:restore()
  end)

  -- crates (0.8, FB-020): Alt-click a crate, then another before the first search has its answers.
  -- The search and the bottom bar must be the second crate's, with nothing of the first mixed in.
  try('timing: a second crate clicked while the first is still searching', function()
    local server = new_server(env)
    local search = module 'aux.tabs.search'
    local shortcut = module 'aux.core.shortcut'
    server.items[2592] = {name = 'Wool Cloth', commodity = true, max_stack = 200}
    server.items[4306] = {name = 'Silk Cloth', commodity = true, max_stack = 200}
    server.items[2997] = {name = 'Bolt of Woolen Cloth', commodity = true, max_stack = 200}
    server.items[4305] = {name = 'Bolt of Silk Cloth', commodity = true, max_stack = 200}
    server.items[990698] = {name = 'Waylaid Crate: Journeyman Textiles', commodity = false}
    server.items[990711] = {name = 'Waylaid Crate: Journeyman Fabrics', commodity = false}
    server.listings[2592] = {{price = 30, quantity = 60}}
    server.listings[4306] = {{price = 14, quantity = 100}}
    server.listings[2997] = {{price = 90, quantity = 20}}
    server.listings[4305] = {{price = 70, quantity = 30}}
    -- item numbers of their own: crate lists are kept per item, and other tests read real crates
    server:install()
    local lists = {
      [990698] = '- 20 Wool Cloth\n- 40 Silk Cloth',
      [990711] = '- 6 Bolt of Woolen Cloth\n- 10 Bolt of Silk Cloth',
    }
    local real_info, real_alt, was_shown = G.C_TooltipInfo, G.IsAltKeyDown, aux.frame.__shown
    G.C_TooltipInfo = {GetHyperlink = function(link)
      local id = tonumber(link:match('item:(%d+)'))
      return {lines = {{leftText = 'Use: Fill the crate with any bundle from the following list:\n' .. lists[id]}}}
    end}
    G.IsAltKeyDown = function() return true end
    aux.frame.__shown = true
    aux.set_tab(1)
    search.frame:Show()
    search.update_mode(search.NORMAL_MODE)
    shortcut.on_modified_click(server:link(990698))
    -- the first crate's item list is in and its listings are on their way. (Clicked before its item
    -- list arrives, the late list is taken for the second search's: a search engine question, not a
    -- crate one, and whether Forever answers a replaced question is not known; status.md, 2026-10-20.)
    server:ticks(12)
    check('crates: the first search is still running', not search.current_search().complete)
    shortcut.on_modified_click(server:link(990711))
    local fabrics = 'bolt of woolen cloth/exact;bolt of silk cloth/exact'
    local done = server:wait(function()
      local s = search.current_search()
      return s and s.complete and s.filter_string == fabrics
    end, 200)
    local s = search.current_search()
    check('crates: the second search finishes', done)
    check('crates: it is the second crate', s and s.recipe and s.recipe.name == 'Journeyman Fabrics')
    search.update_results_summary(true)
    local summary = plain(search.recipe_label.__text)
    check('crates: the bottom bar prices the second crate', summary:find('Journeyman Fabrics', 1, true) and summary:find('6 Bolt of Woolen Cloth  5s 40c', 1, true) ~= nil)
    check('crates: nothing of the first crate in it', not summary:find('Wool Cloth ', 1, true) and not summary:find('Textiles', 1, true))
    G.C_TooltipInfo, G.IsAltKeyDown, aux.frame.__shown = real_info, real_alt, was_shown
    server:ticks(40)
    search.frame:Hide()
    server:restore()
  end)

  -- gamepad (gamepad.lua, contributed by nokkty): Y presses Post. It must obey a faded Post as a
  -- click does: nothing while the listings load, and one post for two quick presses.
  try('timing: gamepad Y on the Post tab', function()
    local server = new_server(env)
    local post = post_setup(server)
    local aux_frame = module('aux').frame
    local real = {G.SetOverrideBindingClick, G.ClearOverrideBindings, G.InCombatLockdown}
    G.SetOverrideBindingClick, G.ClearOverrideBindings, G.InCombatLockdown = function() end, function() end, function() return false end
    G.InputUtil = {IsGamepadUIEnabled = function() return true end}
    aux_frame:Hide(); aux_frame:Show()
    aux.set_tab(3)
    -- as in the game: Post is faded while the addon has a reason (the harness's IsEnabled is always true)
    rawset(post.post_button, 'IsVisible', function() return true end)
    rawset(post.post_button, 'IsEnabled', function() return post.selected_item ~= nil and not post.disabled_reason() end)
    rawset(post.post_button, 'Click', function(self) self.__scripts.OnClick(self) end)
    local function y() post.validate_parameters(); local b = G.auxForeverPadY; b.__scripts.OnClick(b) end

    post.select_item('2835:0')
    post.set_unit_buyout_price(3000) -- remembered from an earlier visit
    server:ticks(1)
    y()
    server:ticks(2)
    check('pad Y: nothing posted while the listings load', #server.posts == 0)
    check('pad Y: the listings arrive', server:wait(listings_in(post), 50))
    server:ticks(3)
    y(); y()
    server:ticks(15)
    check('pad Y: two quick presses post once, at the lowest listing', #server.posts == 1 and server.posts[1].unit_price == 7)

    rawset(post.post_button, 'IsVisible', nil); rawset(post.post_button, 'IsEnabled', nil); rawset(post.post_button, 'Click', nil)
    aux_frame:Hide()
    G.SetOverrideBindingClick, G.ClearOverrideBindings, G.InCombatLockdown = real[1], real[2], real[3]
    G.InputUtil = nil
    aux_frame:Show()
    post_teardown(server, post)
  end)

  -- Outside review of 2026-11-10 (docs/reviews/2026-11-10-outside-review.md), 0.8.2.1.
  -- R-01: a Sniper round the auction house does not answer saw nothing, and marked every deal gone.
  -- R-02: a list that arrived only in part did the same to the deals past its end.
  -- Gone deals stayed gone: an item is opened again only when its lowest price changes.
  try('timing: R-01 R-02 a Sniper round without the whole item list keeps the deals', function()
    local server = new_server(env)
    local sniper = module 'aux.tabs.sniper'
    for i = 1, 3 do
      server.items[9200 + i] = {name = 'Quiet Thing ' .. i, commodity = false, vendor = 5000}
      server.listings[9200 + i] = {{price = 1000, quantity = 1}}
    end
    server:install()
    sniper.clear_deals()
    sniper.settings_changed()
    aux.set_tab(2) -- Search 1, Sniper 2
    sniper.start()
    check('R-01: the three deals are found', server:wait(function() return #sniper.deals >= 3 end, 300))
    local function gone()
      local n = 0
      for _, d in ipairs(sniper.deals) do if d.deal_gone then n = n + 1 end end
      return n
    end
    local r = sniper.round
    check('R-01: a whole round ends with them still listed', server:wait(function() return sniper.round > r end, 300) and gone() == 0)
    -- the auction house stops answering item lists; aux gives up on one after 20 seconds
    local said = {}
    rawset(G.DEFAULT_CHAT_FRAME, 'AddMessage', function(_, text) table.insert(said, tostring(text)) end)
    server.browse_silent = true
    server:ticks(330)
    check('R-01: an unanswered round leaves every deal as it was', #sniper.deals >= 3 and gone() == 0)
    check('R-01: and says nothing in chat (a quiet scan)', #said == 0)
    rawset(G.DEFAULT_CHAT_FRAME, 'AddMessage', nil)
    server.browse_silent = false
    -- the list arrives one row at a time and the request for more is never answered
    server.page_size, server.more_silent = 1, true
    server:ticks(330)
    check('R-02: a round with part of the list leaves the deals past its end alone', #sniper.deals >= 3 and gone() == 0)
    -- a deal that really sold is still found gone by the next whole round
    server.page_size, server.more_silent = nil, nil
    server.listings[9202] = {}
    check('R-01: a whole round still marks a sold deal gone', server:wait(function() return gone() == 1 end, 400))
    sniper.stop()
    sniper.clear_deals()
    aux.set_tab(1)
    server:restore()
  end)

  -- R-02 on the Post tab: gear is read by name, version by version. When the item list stops before
  -- the versions of the selected name, the Post tab had nothing of that name, called its listings
  -- ready and picked a price from elsewhere.
  try('timing: R-02 the Post tab does not price gear from part of the item list', function()
    local server = new_server(env)
    local post = module 'aux.tabs.post'
    server.items[4585] = {name = 'Cut Staff', commodity = false, vendor = 1487,
      versions = {[201] = 'of the Bandit', [202] = 'of the Bear', [203] = 'of the Wolf'}}
    server.listings[4585] = {
      {price = 11500, quantity = 1, version = 201},
      {price = 11000, quantity = 1, version = 202},
      {price = 15000, quantity = 1, version = 203},
    }
    server.bag = {{id = 4585, count = 1, version = 203}}
    server.page_size, server.more_silent = 2, true -- the Wolf's row is past the cut
    server:install()
    for _, box in ipairs{post.stack_size_input, post.stack_count_input} do
      local n = 1
      rawset(box, 'SetNumber', function(self, v) n = math.max(0, math.min(v, self.max_value or v)) end)
      rawset(box, 'GetNumber', function() return n end)
    end
    rawset(post.duration_dropdown, 'GetIndex', function() return 2 end)
    post.set_undercut_mode(false)
    aux.set_tab(3)
    server:ticks(2)
    post.select_item('4585:of the wolf')
    check('R-02 post: the Wolf staff is selected', post.selected_item and post.selected_item.key == '4585:of the wolf')
    post.set_unit_buyout_price(0)
    local function read_over()
      post.validate_parameters()
      return post.disabled_reason() ~= 'Reading the listings...'
    end
    check('R-02 post: the read ends', server:wait(read_over, 400))
    server:ticks(3)
    post.validate_parameters()
    check('R-02 post: it says the read stopped, not that none are for sale', post.disabled_reason() == 'Reading stopped. Press Refresh, or type a price.')
    check('R-02 post: no price was picked from the part that arrived', post.get_unit_buyout_price() == 0)
    -- Refresh with the whole list: the Wolf listing is found and priced against
    server.page_size, server.more_silent = nil, nil
    post.refresh_button_click()
    check('R-02 post: after Refresh the listings are in', server:wait(function()
      post.validate_parameters()
      return post.get_unit_buyout_price() == 15000
    end, 300))
    post_teardown(server, post)
  end)

  -- R-02 on the Search tab: the search says that items are missing (chat and the results line)
  try('timing: R-02 a search with part of the item list says so', function()
    local server = new_server(env)
    local search = module 'aux.tabs.search'
    local scan = module 'aux.core.scan'
    for i = 1, 3 do
      server.items[9300 + i] = {name = 'Partial Cloth ' .. i, commodity = true, vendor = 1}
      server.listings[9300 + i] = {{price = 50, quantity = 10}}
    end
    server.page_size, server.more_silent = 2, true
    server:install()
    aux.set_tab(1)
    search.frame:Show()
    search.update_mode(search.NORMAL_MODE)
    local said = {}
    rawset(G.DEFAULT_CHAT_FRAME, 'AddMessage', function(_, text) table.insert(said, tostring(text)) end)
    search.search_box:SetText('partial cloth')
    search.execute(nil, false)
    check('R-02 search: the search ends', server:wait(function() local s = search.current_search(); return s and s.complete end, 400))
    local s = search.current_search()
    check('R-02 search: it found the part that arrived', #s.records == 2)
    check('R-02 search: the search is marked as missing items', s.incomplete == true)
    local told
    for _, line in ipairs(said) do if line:find(scan.PARTIAL_LIST_TEXT, 1, true) then told = true end end
    check('R-02 search: chat says the list was cut', told)
    check('R-02 search: the results line says so too', plain(search.results_summary(s) or ''):find('some items missing', 1, true) ~= nil)
    rawset(G.DEFAULT_CHAT_FRAME, 'AddMessage', nil)
    -- the same search with the whole list: nothing missing
    server.page_size, server.more_silent = nil, nil
    search.execute(nil, false)
    check('R-02 search: searched again, the whole list arrives', server:wait(function() local t = search.current_search(); return t and t.complete and #t.records == 3 end, 400))
    check('R-02 search: and nothing is said to be missing', not search.current_search().incomplete)
    search.frame:Hide()
    server:restore()
  end)

  -- Tyler, build 4 test: a Full search for linen brought up "Table full!", a popup to close ("I had
  -- to close this error"), at every search. The limit stays (a bigger table costs frame rate at
  -- every redraw); it is said next to the results and once in chat, with how much is not shown.
  try('timing: a full table says so without a popup', function()
    local server = new_server(env)
    local search = module 'aux.tabs.search'
    server.items[9400] = {name = 'Crowded Cloth', commodity = true, vendor = 1}
    server.listings[9400] = {}
    for i = 1, 6 do table.insert(server.listings[9400], {price = 49 + i, quantity = 10}) end
    server:install()
    local set_limit = loadstring("select(2, ...) 'aux.tabs.search'; M.TABLE_LIMIT = (select(3, ...))")
    set_limit('auxForever', addon, 4)
    local popups, said = 0, {}
    rawset(G, 'StaticPopup_Show', function() popups = popups + 1 end)
    rawset(G.DEFAULT_CHAT_FRAME, 'AddMessage', function(_, text) table.insert(said, plain(tostring(text))) end)
    aux.set_tab(1)
    search.frame:Show()
    search.update_mode(search.NORMAL_MODE)
    local was_full = aux.account_data.full_search
    aux.account_data.full_search = true -- Full mode: every listing, not one row per item
    search.search_box:SetText('crowded cloth')
    search.execute(nil, false)
    check('table full: the search ends', server:wait(function() local s = search.current_search(); return s and s.complete end, 400))
    local s = search.current_search()
    check('table full: the table holds its limit (' .. #s.records .. ')', #s.records == 4)
    check('table full: what is not shown is counted in units for sale (' .. tostring(s.not_shown) .. ')', s.not_shown == 20)
    check('table full: no popup to close', popups == 0)
    check('table full: the results line says how much is not shown', plain(search.results_summary(s) or ''):find('table full: 20 more not shown', 1, true) ~= nil)
    local told = 0
    for _, line in ipairs(said) do if line:find('The results table is full (4 auctions). 20 more for sale', 1, true) then told = told + 1 end end
    check('table full: chat says it once (' .. told .. ')', told == 1)
    -- with room for everything, nothing is said
    set_limit('auxForever', addon, 2000)
    search.execute(nil, false)
    check('table full: searched again with room, everything shows', server:wait(function() local t = search.current_search(); return t and t.complete and #t.records == 6 end, 400))
    check('table full: and the note is gone', not search.current_search().not_shown
      and not plain(search.results_summary(search.current_search()) or ''):find('table full', 1, true))
    aux.account_data.full_search = was_full
    rawset(G, 'StaticPopup_Show', nil)
    rawset(G.DEFAULT_CHAT_FRAME, 'AddMessage', nil)
    search.frame:Hide()
    server:restore()
  end)

  -- R-02 on the Auctions tab: gear the price check found nothing for, because the item list was cut
  -- before its versions, read "Only one listed"
  try('timing: R-02 the Auctions check does not call an unread item the lowest', function()
    local server = new_server(env)
    local auctions = module 'aux.tabs.auctions'
    server.items[4586] = {name = 'Check Staff', commodity = false, vendor = 1487,
      versions = {[301] = 'of the Bandit', [302] = 'of the Bear', [303] = 'of the Wolf'}}
    server.listings[4586] = {
      {price = 11500, quantity = 1, version = 301},
      {price = 11000, quantity = 1, version = 302},
      {price = 9000, quantity = 1, version = 303},
    }
    server.page_size, server.more_silent = 2, true
    server:install()
    local mine = {item_id = 4586, price_key = '4586:of the wolf', item_search_key = server:key(4586, 303), sale_status = 0,
      buyout_price = 15000, unit_buyout_price = 15000, count = 1, auction_id = 5, name = 'Check Staff of the Wolf'}
    local real_records = auctions.listing.records
    auctions.listing.records = {mine}
    auctions.checks = {}
    auctions.check_prices()
    check('R-02 auctions: the check ends', server:wait(function() return not auctions.checking end, 400))
    check('R-02 auctions: an item it could not read stays "Not checked"', auctions.auction_status(mine) == 'unchecked')
    server.page_size, server.more_silent = nil, nil
    auctions.check_prices()
    check('R-02 auctions: checked again with the whole list', server:wait(function() return not auctions.checking end, 400))
    local status, by = auctions.auction_status(mine)
    check('R-02 auctions: the cheaper Wolf listing is found', status == 'undercut' and by == 6000)
    auctions.listing.records = real_records
    auctions.checks = {}
    server:restore()
  end)

  -- R-14: a gear deal read again before buying. When its auction is gone and a cheaper one of the
  -- item is there, the deal takes on that auction, price included: the button shows and sends what
  -- that auction costs (the old, higher buyout was sent with the new auction's ID).
  try('timing: R-14 a Sniper gear deal bought at the price of the auction found', function()
    local server = new_server(env)
    local sniper = module 'aux.tabs.sniper'
    local bar = module 'aux.gui.buy_bar'
    server.items[9401] = {name = 'Found Blade', commodity = false, vendor = 5000}
    server.listings[9401] = {{price = 1000, quantity = 1}}
    server:install()
    aux.account_data.sniper_profit = 1
    sniper.clear_deals()
    sniper.settings_changed()
    aux.set_tab(2) -- Search 1, Sniper 2
    sniper.start()
    local deal
    check('R-14: the deal is found at 10s', server:wait(function()
      for _, d in ipairs(sniper.deals) do if d.item_id == 9401 then deal = d end end
      return deal ~= nil
    end, 200) and deal.buyout_price == 1000)
    sniper.stop()
    server:ticks(20)
    -- that auction sells and a cheaper one is posted before the player clicks the deal
    server.listings[9401] = {{price = 900, quantity = 1}}
    deal.deal_read_at = G.GetTime() - 100
    sniper.listing:SetSelectedRecord(deal)
    check('R-14: the deal is read again and offered', server:wait(function() return (bar.primary_label() or ''):find('^Buy for') ~= nil end, 100))
    check('R-14: the button shows the price of the auction found, 9s', deal.buyout_price == 900 and plain(bar.primary_label()):find('9s', 1, true) ~= nil)
    bar.primary_click()
    check('R-14: the purchase arrives', server:wait(function() return #server.purchases > 0 end, 50))
    check('R-14: 9s is what was sent, not the 10s first seen', #server.purchases == 1 and server.purchases[1].total == 900)
    sniper.listing:SetSelectedRecord()
    aux.account_data.sniper_profit = 500
    sniper.clear_deals()
    bar.clear()
    aux.set_tab(1)
    server:restore()
  end)

  -- R-12 and R-20: a full-mode search draws its table a few times a second, not after every item,
  -- and an alert favorite brings up its popup once per search
  try('timing: R-12 R-20 a search redraws now and then and alerts once', function()
    local server = new_server(env)
    local search = module 'aux.tabs.search'
    for i = 1, 12 do
      server.items[9500 + i] = {name = 'Redraw Cloth ' .. i, commodity = true, vendor = 1}
      server.listings[9500 + i] = {{price = 50 + i, quantity = 10}}
    end
    server.delay, server.throttle = .1, 0 -- a fast auction house: an item read every frame or two
    server:install()
    local alert = {filter_string = 'redraw cloth', prettified = 'redraw cloth', alert = true}
    tinsert(search.favorite_searches, 1, alert)
    local alerts = 0
    local real_show = G.StaticPopup_Show
    G.StaticPopup_Show = function(name, ...) if name == 'AUX_SCAN_ALERT' then alerts = alerts + 1 end; return real_show(name, ...) end
    aux.set_tab(1)
    search.frame:Show()
    search.update_mode(search.NORMAL_MODE)
    local was_full = aux.account_data.full_search
    search.set_full_search(true)
    search.search_box:SetText('redraw cloth')
    search.execute(nil, false)
    local s = search.current_search()
    local draws, real_set = 0, s.table.SetDatabase
    rawset(s.table, 'SetDatabase', function(...) draws = draws + 1; return real_set(...) end)
    check('R-12: the search ends with every item', server:wait(function() return s.complete end, 400) and #s.records == 12)
    check('R-12: the table was drawn less often than once per item', draws >= 1 and draws <= 8)
    local shown = 0
    for _, row in ipairs(s.table.rowInfo) do shown = shown + #row.children end
    check('R-12: and holds every row at the end', shown == 12)
    check('R-20: an alert favorite brings up its popup once per search', alerts == 1)
    rawset(s.table, 'SetDatabase', nil)
    G.StaticPopup_Show = real_show
    for i = #search.favorite_searches, 1, -1 do if search.favorite_searches[i] == alert then table.remove(search.favorite_searches, i) end end
    search.set_full_search(was_full)
    search.frame:Hide()
    server:restore()
  end)

  -- Found by the random player (tests/fuzz_test.lua): leaving the Post tab while a gear item's
  -- listings are still being read. The read went on and used the selection, which the tab clears
  -- when it closes: an error at every answer, and "The search stopped because of an error".
  try('timing: leaving the Post tab while gear listings are read', function()
    local server = new_server(env)
    local post = module 'aux.tabs.post'
    server.items[4590] = {name = 'Leave Staff', commodity = false, vendor = 1487, versions = {[401] = 'of the Bandit', [402] = 'of the Wolf'}}
    server.listings[4590] = {{price = 11500, quantity = 1, version = 401}, {price = 15000, quantity = 1, version = 402}}
    server.bag = {{id = 4590, count = 1, version = 402}}
    server:install()
    aux.set_tab(3)
    server:ticks(2)
    post.select_item('4590:of the wolf')
    check('leave post: the staff is selected and its listings are on their way', post.selected_item ~= nil and server:pending() > 0)
    local errors_before = env.errors()
    aux.set_tab(1) -- the player goes to another tab before the answer
    server:ticks(80)
    check('leave post: the read ends without an error', env.errors() == errors_before)
    aux.set_tab(1)
    server:restore()
  end)
end
