-- auxForever tests: how much CPU one Sniper round costs aux, and how many requests it sends.
--
-- Written for FB-055 (2026-11-17), when Tyler found the Sniper slow. It showed that aux's own work
-- per round is 20 to 50 ms of CPU for 8,000 items; the rest of a round is waiting on the auction
-- house (the list comes 500 items per request, about one request every 0.5 to 0.75 s on Forever).
--
-- Run from auxForever/ (it plays against the slow fake auction house of tests/slow_server.lua):
--   AUX_BENCH=1 lua5.1 ../tests/load_test.lua            (8,000 items)
--   AUX_BENCH=1 BENCH_N=25000 lua5.1 ../tests/load_test.lua   (Forever's size on 2026-11-17)
-- It prints three rounds: game time (the fake's clock: answers after 0.5 s, throttle 0.3 s, so
-- not the game's real speed), requests sent, the Sniper's status line, and check_list's CPU time.
-- One item in ten is gray, as a guess; on Forever grays were 2% (2026-11-17).
return function(env)
  local G, addon, dir = env.G, env.addon, env.dir
  local new_server = dofile(dir .. 'slow_server.lua')
  local function module(name) return loadstring("select(2, ...) '" .. name .. "'; return _M")('auxForever', addon) end
  local aux = loadstring("select(2, ...) 'aux.test.bench'; return require 'aux'")('auxForever', addon)
  local N = tonumber(os.getenv('BENCH_N') or '8000')
  local server = new_server(env)
  server.page_size = 500
  server.delay = .5
  math.randomseed(1)
  for i = 1, N do
    local id = 20000 + i
    server.items[id] = {name = 'Bench ' .. i, commodity = i % 10 < 7, vendor = 100, max_stack = 20, quality = (i % 10 == 9) and 0 or 1}
    server.listings[id] = {{price = 500 + math.random(1000), quantity = 5}, {price = 2000, quantity = 10}}
  end
  server:install()
  local sniper = module 'aux.tabs.sniper'
  local old_profit = aux.account_data.sniper_profit
  aux.account_data.sniper_profit = 1
  sniper.clear_deals()
  local real = sniper.check_list
  local calls = {}
  rawset(sniper, 'check_list', function(results, seen)
    local t = os.clock()
    real(results, seen)
    table.insert(calls, {n = #results, cpu = os.clock() - t})
  end)
  aux.set_tab(2) -- Search 1, Sniper 2
  local r0 = #server.requests
  local cpu0 = os.clock()
  sniper.start()
  local t0 = G.GetTime()
  for _ = 1, 3 do
    local before = sniper.round
    server:wait(function() return sniper.round > before end, 5000)
    print(string.format('bench: round %d, game time %.1fs, requests so far %d, status: %s', sniper.round, G.GetTime() - t0, #server.requests - r0, select(2, sniper.status())))
    if calls[#calls] then print(string.format('bench:   check_list: %d items, %.0f ms CPU (pauses included)', calls[#calls].n, calls[#calls].cpu * 1000)) end
    for i = 1, N, 50 do server.listings[20000 + i][1].price = 500 + math.random(1000) end
  end
  print(string.format('bench: total CPU %.2fs for 3 rounds, the fake auction house included', os.clock() - cpu0))
  sniper.stop()
  rawset(sniper, 'check_list', nil)
  aux.account_data.sniper_profit = old_profit
  aux.set_tab(1)
  server:restore()
end
