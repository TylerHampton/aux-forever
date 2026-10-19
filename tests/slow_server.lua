-- auxForever tests: a slow auction house (2026-10-18, FB-021).
--
-- The stubs in load_test.lua answer a request at once, or never. Forever's auction house answers a
-- second or more later, and players click and type while they wait. A bug that depends on that
-- order passed every test: FB-021 (sarrathsilentstrider) typed a price while the Post tab was still
-- reading the listings, and the automatic price replaced it when they arrived.
--
-- This fake keeps a bag and the listings of a few items, answers every request after `delay`
-- seconds of game time (the tests' tick() moves the clock by 0.1 s), keeps the throttle busy for a
-- moment after each request, and records what the addon posted and bought. It follows Blizzard's
-- calls and events as the game sends them (docs/forever-auction-house.md); only what aux uses is
-- here.
--
-- Use: local server = dofile(dir .. 'slow_server.lua')(env); server:install() ... server:restore()

return function(env)
  local G = env.G

  local server = {
    delay = 1,       -- seconds before an answer arrives
    throttle = .3,   -- seconds the throttle stays busy after a request
    items = {},      -- [item_id] = {name, commodity, quality, vendor, max_stack, level}
    listings = {},   -- [item_id] = {{price, quantity, own, bid}, ...}; price per unit
    bag = {},        -- {{id, count, locked}, ...}: bag 0, one slot each
    posts = {},      -- every post the addon sent: {id, quantity, unit_price, bid, buyout, duration}
    purchases = {},  -- every confirmed commodity purchase: {id, quantity, unit_price}
    requests = {},   -- names of the requests sent, in order
    money = 1000000,
  }

  local saved, due, results, browse = {}, {}, {}, nil
  local auctions = {} -- [auction ID] = {id, listing}, as last shown in search results
  local quote
  local ready_at = 0
  local next_auction_id = 1000

  local function now() return G.GetTime() end
  local function set(t, k, v) table.insert(saved, {t, k, rawget(t, k)}); rawset(t, k, v) end
  local function later(f, seconds) table.insert(due, {at = now() + (seconds or server.delay), f = f}) end
  local function sent(name)
    table.insert(server.requests, name)
    ready_at = now() + server.throttle
  end

  function server:link(id)
    return '|cffffffff|Hitem:' .. id .. '::::::0:0|h[' .. self.items[id].name .. ']|h|r'
  end

  function server:key(id) return {itemID = id, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0} end

  local function item_id_of(x)
    if type(x) == 'table' then return x.itemID end
    return tonumber(tostring(x):match('item:(%d+)') or x)
  end

  -- the listings as the server holds them now, cheapest first
  local function sorted(id)
    local list = {}
    for _, l in ipairs(server.listings[id] or {}) do
      if l.quantity > 0 then table.insert(list, l) end
    end
    table.sort(list, function(a, b) return a.price < b.price end)
    return list
  end

  function server:bag_count(id)
    local n = 0
    for _, slot in ipairs(self.bag) do if slot.id == id then n = n + slot.count end end
    return n
  end

  local function take_from_bag(id, quantity)
    for _, slot in ipairs(server.bag) do
      if slot.id == id and quantity > 0 then
        local taken = math.min(slot.count, quantity)
        slot.count = slot.count - taken
        quantity = quantity - taken
      end
    end
    for i = #server.bag, 1, -1 do
      if server.bag[i].count <= 0 then table.remove(server.bag, i) end
    end
  end

  local function add_listing(id, price, quantity, own, bid)
    server.listings[id] = server.listings[id] or {}
    table.insert(server.listings[id], {price = price, quantity = quantity, own = own, bid = bid})
  end

  -- one commodity search result row, as GetCommoditySearchResultInfo returns it
  local function commodity_row(id, l, i)
    auctions[id * 100 + i] = {id = id, listing = l}
    return {
      itemID = id, quantity = l.quantity, unitPrice = l.price, auctionID = id * 100 + i,
      owners = {l.own and 'player' or 'Someone'}, totalNumberOfOwners = 1,
      numOwnerItems = l.own and l.quantity or 0, containsOwnerItem = l.own or false,
      timeLeftSeconds = 40000,
    }
  end

  local function item_row(id, l, i)
    auctions[id * 100 + i] = {id = id, listing = l}
    return {
      itemKey = server:key(id), itemLink = server:link(id), auctionID = id * 100 + i,
      quantity = l.quantity, buyoutAmount = l.price, minBid = l.bid, bidAmount = nil,
      owners = {l.own and 'player' or 'Someone'}, totalNumberOfOwners = 1,
      containsOwnerItem = l.own or false, timeLeftSeconds = 40000,
    }
  end

  -- delivers the answers that are due; runs on every tick through a frame of its own
  local function deliver()
    local i = 1
    while i <= #due do
      if now() >= due[i].at then
        local d = table.remove(due, i)
        d.f()
      else
        i = i + 1
      end
    end
  end

  -- tick until done() is true, at most n ticks; returns whether it became true
  function server:wait(done, n)
    for _ = 1, n or 100 do
      if done() then return true end
      env.tick()
    end
    return done() and true or false
  end

  function server:ticks(n) for _ = 1, n do env.tick() end end

  function server:install()
    local C = G.C_AuctionHouse
    -- item data
    set(G, 'GetItemInfo', function(x)
      local id = item_id_of(x)
      local it = id and server.items[id]
      if it then
        return it.name, server:link(id), it.quality or 1, it.level or 1, it.requirement or 1,
          it.commodity and 'Trade Goods' or 'Weapon', it.commodity and 'Parts' or 'Sword',
          it.max_stack or (it.commodity and 200 or 1), it.commodity and '' or 'INVTYPE_WEAPON', 1, it.vendor or 0
      end
    end)
    set(G.C_Item, 'IsItemDataCachedByID', function() return true end)
    set(G.C_Item, 'DoesItemExist', function(location) return server.bag[location.slot] ~= nil end)
    set(G.C_Item, 'GetItemID', function(location) local s = server.bag[location.slot]; return s and s.id end)
    set(G.AuxTooltip, 'NumLines', function() return 0 end)
    for _, k in ipairs{'ITEM_BIND_ON_PICKUP', 'ITEM_BIND_QUEST', 'ITEM_SOULBOUND'} do set(G, k, k) end
    set(G, 'GetMoney', function() return server.money end)
    -- the commodity status the game gives (Unknown 0, Item 1, Commodity 2 as numbers of our own)
    set(G.Enum, 'ItemCommodityStatus', {Unknown = 0, Item = 1, Commodity = 2})

    -- the bag
    set(G.C_Container, 'GetContainerNumSlots', function(b) return b == 0 and #server.bag or 0 end)
    set(G.C_Container, 'GetContainerItemLink', function(b, i) local s = b == 0 and server.bag[i]; return s and server:link(s.id) end)
    set(G.C_Container, 'GetContainerItemInfo', function(b, i)
      local s = b == 0 and server.bag[i]
      return s and {stackCount = s.count, isLocked = s.locked or false, iconFileID = 1, hasLoot = false}
    end)
    set(G.C_Container, 'GetContainerItemDurability', function() end)
    set(G.ItemLocation, 'CreateFromBagAndSlot', function(_, b, i)
      return {bag = b, slot = i, IsValid = function() return b == 0 and server.bag[i] ~= nil end}
    end)
    set(C, 'IsSellItemValid', function(location) local s = server.bag[location.slot]; return s and not s.locked or false end)
    set(C, 'GetItemCommodityStatus', function(location)
      local s = server.bag[location.slot]
      return s and (server.items[s.id].commodity and 2 or 1) or 0
    end)
    set(C, 'GetAvailablePostCount', function(location) local s = server.bag[location.slot]; return s and server:bag_count(s.id) or 0 end)
    set(C, 'GetItemKeyFromItem', function(location) local s = server.bag[location.slot]; return s and server:key(s.id) end)
    set(C, 'MakeItemKey', function(id) return server:key(id) end)
    set(C, 'GetItemKeyInfo', function(key)
      local it = server.items[key.itemID]
      return it and {itemID = key.itemID, itemName = it.name, quality = it.quality or 1, isCommodity = it.commodity or false,
        isEquipment = not it.commodity, iconFileID = 1}
    end)
    set(C, 'CalculateCommodityDeposit', function(_, _, quantity) return 15 * quantity end)
    set(C, 'CalculateItemDeposit', function(_, _, quantity) return 50 * quantity end)
    set(C, 'SupportsCopperValues', function() return true end)

    -- requests and their answers
    set(C, 'IsThrottledMessageSystemReady', function() return now() >= ready_at end)
    set(C, 'SendSearchQuery', function(key, sorts, separate_own)
      sent('search ' .. key.itemID)
      local id = key.itemID
      results[id] = nil -- a new search drops the old results, as the game does
      later(function()
        results[id] = sorted(id)
        if server.items[id].commodity then
          env.fire('COMMODITY_SEARCH_RESULTS_UPDATED', id)
        else
          env.fire('ITEM_SEARCH_RESULTS_UPDATED', server:key(id), nil)
        end
      end)
    end)
    set(C, 'HasFullCommoditySearchResults', function(id) return results[id] ~= nil end)
    set(C, 'GetCommoditySearchResultsQuantity', function(id)
      local n = 0
      for _, l in ipairs(results[id] or {}) do n = n + l.quantity end
      return n
    end)
    set(C, 'GetNumCommoditySearchResults', function(id) return #(results[id] or {}) end)
    set(C, 'GetCommoditySearchResultInfo', function(id, i) local l = (results[id] or {})[i]; return l and commodity_row(id, l, i) end)
    set(C, 'RequestMoreCommoditySearchResults', function() sent('more') end)
    set(C, 'HasSearchResults', function(key) return results[key.itemID] ~= nil end)
    set(C, 'HasFullItemSearchResults', function(key) return results[key.itemID] ~= nil end)
    set(C, 'GetItemSearchResultsQuantity', function(key) return #(results[key.itemID] or {}) end)
    set(C, 'GetNumItemSearchResults', function(key) return #(results[key.itemID] or {}) end)
    set(C, 'GetItemSearchResultInfo', function(key, i) local l = (results[key.itemID] or {})[i]; return l and item_row(key.itemID, l, i) end)
    set(C, 'RequestMoreItemSearchResults', function() sent('more') end)

    -- the item list of a search (browse)
    set(C, 'SendBrowseQuery', function(query)
      sent('browse ' .. (query.searchString or ''))
      browse = nil
      later(function()
        browse = {}
        local text = string.lower(query.searchString or '')
        for id, it in pairs(server.items) do
          local list = sorted(id)
          if #list > 0 and string.find(string.lower(it.name), text, 1, true) then
            local total, own = 0, false
            for _, l in ipairs(list) do total = total + l.quantity; own = own or l.own end
            table.insert(browse, {itemKey = server:key(id), totalQuantity = total, minPrice = list[1].price, containsOwnerItem = own})
          end
        end
        table.sort(browse, function(a, b) return a.itemKey.itemID < b.itemKey.itemID end)
        env.fire('AUCTION_HOUSE_BROWSE_RESULTS_UPDATED')
      end)
    end)
    set(C, 'HasFullBrowseResults', function() return browse ~= nil end)
    set(C, 'GetBrowseResults', function() return browse or {} end)
    set(C, 'RequestMoreBrowseResults', function() sent('more browse') end)

    -- posting: the item leaves the bag and the listing appears when the server has answered
    local function finish_post(post)
      take_from_bag(post.id, post.quantity)
      add_listing(post.id, post.unit_price or post.buyout, post.quantity, true, post.bid)
      env.fire('AUCTION_HOUSE_AUCTION_CREATED', next_auction_id)
      next_auction_id = next_auction_id + 1
      env.fire('BAG_UPDATE', 0)
    end
    set(C, 'PostCommodity', function(location, duration, quantity, unit_price)
      local s = server.bag[location.slot]
      if not s then return false end
      sent('post')
      local post = {id = s.id, quantity = quantity, unit_price = unit_price, duration = duration}
      table.insert(server.posts, post)
      later(function() finish_post(post) end)
      return true
    end)
    set(C, 'PostItem', function(location, duration, quantity, bid, buyout)
      local s = server.bag[location.slot]
      if not s then return false end
      sent('post')
      local post = {id = s.id, quantity = quantity, bid = bid, buyout = buyout, duration = duration}
      table.insert(server.posts, post)
      later(function() finish_post(post) end)
      return true
    end)

    -- buying a trade good: a quote first, then the purchase, each answered later
    set(C, 'StartCommoditiesPurchase', function(id, quantity)
      sent('quote ' .. id .. ' ' .. quantity)
      later(function()
        local left, total = quantity, 0
        for _, l in ipairs(sorted(id)) do
          if not l.own and left > 0 then
            local n = math.min(left, l.quantity)
            total = total + n * l.price
            left = left - n
          end
        end
        if left > 0 then
          env.fire('COMMODITY_PRICE_UNAVAILABLE')
        else
          quote = {id = id, quantity = quantity, total = total}
          env.fire('COMMODITY_PRICE_UPDATED', math.ceil(total / quantity), total)
        end
      end)
    end)
    set(C, 'GetQuoteDurationRemaining', function() return 30 end)
    set(C, 'ConfirmCommoditiesPurchase', function(id, quantity)
      sent('confirm ' .. id .. ' ' .. quantity)
      local q = quote
      quote = nil
      later(function()
        if not q or q.id ~= id or q.quantity ~= quantity then
          env.fire('COMMODITY_PURCHASE_FAILED')
          return
        end
        local left = quantity
        for _, l in ipairs(sorted(id)) do
          if not l.own and left > 0 then
            local n = math.min(left, l.quantity)
            l.quantity = l.quantity - n
            left = left - n
          end
        end
        server.money = server.money - q.total
        table.insert(server.purchases, {id = id, quantity = quantity, total = q.total})
        env.fire('COMMODITY_PURCHASE_SUCCEEDED')
      end)
    end)
    set(C, 'CancelCommoditiesPurchase', function() quote = nil end)

    -- buying (or bidding on) one auction of an item by its auction ID
    set(C, 'PlaceBid', function(auction_id, amount)
      sent('bid ' .. auction_id .. ' ' .. amount)
      later(function()
        local a = auctions[auction_id]
        if not a or a.listing.quantity <= 0 or a.listing.own then
          env.fire('AUCTION_HOUSE_SHOW_ERROR', G.Enum.AuctionHouseError.ItemNotFound)
          return
        end
        a.listing.quantity = a.listing.quantity - 1
        server.money = server.money - amount
        table.insert(server.purchases, {id = a.id, auction_id = auction_id, total = amount})
        env.fire('AUCTION_HOUSE_PURCHASE_COMPLETED', auction_id)
      end)
    end)

    -- the answers arrive on a later tick, after every other frame has had its update
    local frame = G.CreateFrame('Frame')
    frame:SetScript('OnUpdate', deliver)
    server.frame = frame
  end

  function server:restore()
    if self.frame then self.frame:Hide(); self.frame:SetScript('OnUpdate', nil) end
    for i = #saved, 1, -1 do rawset(saved[i][1], saved[i][2], saved[i][3]) end
    saved, due, results, browse, quote, auctions = {}, {}, {}, nil, nil, {}
  end

  -- an answer the server still owes
  function server:pending() return #due end

  return server
end
