-- auxForever tests: what players do while the auction house is still answering (2026-10-18).
--
-- Run by load_test.lua with the slow auction house of tests/slow_server.lua. Each test plays out
-- what a player does, click by click, while answers arrive a second later, and checks what the
-- addon finally sent to the auction house (the price posted, the amount bought), not only what it
-- shows.

return function(env)
  local G, check, try, addon, dir = env.G, env.check, env.try, env.addon, env.dir
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
end
