-- auxForever smoke checks: tooltip basics that FB-023 keeps putting at risk.
--
-- Always run from load_test.lua. For a fast loop while editing tooltips:
--   cd auxForever
--   lua5.1 ../tests/load_test.lua smoke
--
-- Covers: disenchant table, disenchant/value/vendor lines on extend_tooltip, settings gates,
-- and that suffix inject must not wipe those lines with a late Show().

return function(env)
  local G, check, try, addon = env.G, env.check, env.try, env.addon

  local function module(name)
    return loadstring("select(2, ...) '" .. name .. "'; return _M")('auxForever', addon)
  end

  local function tip_lines()
    local lines = {}
    local tip = {
      GetName = function() return 'GameTooltip' end,
      NumLines = function() return #lines end,
      AddLine = function(_, text) tinsert(lines, tostring(text or '')) end,
      Show = function() end,
      IsShown = function() return true end,
      IsForbidden = function() return false end,
      GetItem = function() return nil, nil end,
    }
    for i = 1, 40 do
      G['GameTooltipTextLeft' .. i] = { GetText = function() return lines[i] end }
    end
    -- extend_tooltip asks AuxTooltip how many lines an item has (auctionable cache).
    if G.AuxTooltip then
      rawset(G.AuxTooltip, 'NumLines', function() return 0 end)
    end
    return tip, lines
  end

  local function has(lines, fragment)
    for _, t in ipairs(lines) do
      if t:find(fragment, 1, true) then
        return true
      end
    end
    return false
  end

  local function with_item_info(items, body)
    local real = G.GetItemInfo
    G.GetItemInfo = function(x)
      local id = tonumber(tostring(x):match('item:(%d+)') or tostring(x):match('(%d+)'))
      local row = id and items[id]
      if row then
        return unpack(row)
      end
    end
    local ok, err = pcall(body)
    G.GetItemInfo = real
    if not ok then
      error(err, 0)
    end
  end

  try('smoke: disenchant table', function()
    local de = module 'aux.core.disenchant'
    check('smoke: green chest has DE outcomes', #de.distribution('INVTYPE_CHEST', 2, 20) > 0)
    check('smoke: green weapon has DE outcomes', #de.distribution('INVTYPE_WEAPON', 2, 30) > 0)
    check('smoke: white chest has no DE', #de.distribution('INVTYPE_CHEST', 1, 20) == 0)
    check('smoke: shirt slot has no DE', #de.distribution('INVTYPE_BODY', 2, 20) == 0)
    check('smoke: gray junk has no DE', #de.distribution('INVTYPE_CHEST', 0, 20) == 0)
  end)

  try('smoke: tooltip lines for green gear', function()
    local tip_mod = module 'aux.core.tooltip'
    local aux = module 'aux'
    local tip, lines = tip_lines()
    aux.character_data.tooltip.disenchant_value = true
    aux.character_data.tooltip.disenchant_distribution = true
    aux.character_data.tooltip.value = true
    aux.character_data.tooltip.merchant_sell = true
    aux.character_data.tooltip.money_icons = false

    with_item_info({
      [6545] = { 'Soldier\'s Boots', '|cff1eff00|Hitem:6545::::::0:0|h[Soldier\'s Boots]|h|r', 2, 20, 15, 'Armor', 'Mail', 1, 'INVTYPE_FEET', '', 100 },
    }, function()
      tip_mod.extend_tooltip(tip, '|cff1eff00|Hitem:6545::::::0:0|h[Soldier\'s Boots]|h|r', 1)
    end)

    check('smoke: Disenchants into line', has(lines, 'Disenchants into:'))
    check('smoke: Disenchant value line', has(lines, 'Disenchant:'))
    check('smoke: Vendor sell line', has(lines, 'Vendor:'))
  end)

  try('smoke: tooltip omits DE when settings are off', function()
    local tip_mod = module 'aux.core.tooltip'
    local aux = module 'aux'
    local tip, lines = tip_lines()
    aux.character_data.tooltip.disenchant_value = false
    aux.character_data.tooltip.disenchant_distribution = false
    aux.character_data.tooltip.merchant_sell = true
    aux.character_data.tooltip.value = false

    with_item_info({
      [6545] = { 'Soldier\'s Boots', '|cff1eff00|Hitem:6545::::::0:0|h[Soldier\'s Boots]|h|r', 2, 20, 15, 'Armor', 'Mail', 1, 'INVTYPE_FEET', '', 100 },
    }, function()
      tip_mod.extend_tooltip(tip, '|cff1eff00|Hitem:6545::::::0:0|h[Soldier\'s Boots]|h|r', 1)
    end)

    check('smoke: no Disenchants into when off', not has(lines, 'Disenchants into:'))
    check('smoke: no Disenchant value when off', not has(lines, 'Disenchant:'))
    check('smoke: Vendor still shown when that switch is on', has(lines, 'Vendor:'))
  end)

  try('smoke: white item gets no DE lines', function()
    local tip_mod = module 'aux.core.tooltip'
    local aux = module 'aux'
    local tip, lines = tip_lines()
    aux.character_data.tooltip.disenchant_value = true
    aux.character_data.tooltip.disenchant_distribution = true

    with_item_info({
      [33] = { 'Brawler\'s Harness', '|cffffffff|Hitem:33::::::0:0|h[Brawler\'s Harness]|h|r', 1, 5, 1, 'Armor', 'Leather', 1, 'INVTYPE_BODY', '', 1 },
    }, function()
      tip_mod.extend_tooltip(tip, '|cffffffff|Hitem:33::::::0:0|h[Brawler\'s Harness]|h|r', 1)
    end)

    check('smoke: white shirt has no Disenchants into', not has(lines, 'Disenchants into:'))
    check('smoke: white shirt has no Disenchant value', not has(lines, 'Disenchant:'))
  end)

  -- Forever rebuilds the tip on a late Show() and drops aux AddLines. Suffix retry must not
  -- Show() after inject; AddLine on an open tip is enough and keeps DE/value.
  try('smoke: suffix inject must not erase DE lines', function()
    local tip_mod = module 'aux.core.tooltip'
    local aux = module 'aux'
    local tip, lines = tip_lines()
    local show_calls = 0
    aux.character_data.tooltip.disenchant_value = true
    aux.character_data.tooltip.disenchant_distribution = true
    aux.character_data.tooltip.merchant_sell = false
    aux.character_data.tooltip.value = false

    G.ITEM_MOD_STRENGTH_SHORT = 'Strength'
    G.GetItemStats = function(link, dest)
      dest = dest or {}
      for k in pairs(dest) do dest[k] = nil end
      dest.RESISTANCE0_NAME = 10
      if type(link) == 'string' and link:find('12732', 1, true) then
        dest.ITEM_MOD_STRENGTH_SHORT = 5
      end
      return dest
    end
    G.C_Item.GetItemStats = G.GetItemStats

    local auction_link = 'item:6545::::::::20:1489::1:12732::::'
    rawset(tip, 'Show', function()
      show_calls = show_calls + 1
      -- Forever: late Show rebuilds and drops aux lines.
      for i = #lines, 1, -1 do
        lines[i] = nil
      end
    end)

    with_item_info({
      [6545] = { 'Soldier\'s Boots', '|cff1eff00|Hitem:6545::::::0:0|h[Soldier\'s Boots]|h|r', 2, 20, 15, 'Armor', 'Mail', 1, 'INVTYPE_FEET', '', 100 },
    }, function()
      -- Quiet Show during the first extend so we keep the AddLines under test.
      local quiet = 0
      rawset(tip, 'Show', function() quiet = quiet + 1 end)
      tip_mod.extend_tooltip(tip, auction_link, 1)
      check('smoke: DE present after extend', has(lines, 'Disenchants into:') and has(lines, 'Disenchant:'))
      check('smoke: suffix +stat present after extend', has(lines, '+5 Strength'))

      show_calls = 0
      rawset(tip, 'Show', function()
        show_calls = show_calls + 1
        for i = #lines, 1, -1 do
          lines[i] = nil
        end
      end)
      tip_mod.schedule_suffix_stats(tip, auction_link)
      for _ = 1, 10 do
        env.tick()
      end
    end)

    check('smoke: DE still present after suffix retry', has(lines, 'Disenchants into:') and has(lines, 'Disenchant:'))
    check('smoke: suffix +stat still present after retry', has(lines, '+5 Strength'))
    check('smoke: suffix retry did not Show (would wipe DE)', show_calls == 0)
  end)
end
