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
end
