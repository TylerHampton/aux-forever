-- Writes tests/forever_categories.lua: Forever's auction house categories (AuctionCategories) as
-- plain data, for the test harness. It runs Blizzard's own category code outside the game, so the
-- tests see the same tree as the game: which categories have a third level, and the filters each
-- one sends to the auction house.
--
-- Usage, from the repository root (Lua 5.1):
--   lua5.1 tests/tools/make_forever_categories.lua <wow-ui-source> <BlizzardInterfaceResources> > tests/forever_categories.lua
--
-- <wow-ui-source>: a checkout of branch `forever` of github.com/Gethe/wow-ui-source (Blizzard's
--   UI code). Needed: Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionData.lua and
--   .../Camelot/Blizzard_AuctionData.lua (Forever loads the Camelot list).
-- <BlizzardInterfaceResources>: a checkout of branch `forever` of
--   github.com/Ketho/BlizzardInterfaceResources. Needed: Resources/LuaEnum.lua (Enum values) and
--   Resources/GlobalStrings/enUS.lua (English text: category and slot names).
-- Both repositories can be cloned with --filter=blob:none --no-checkout, then single files
-- checked out (AGENTS.md).
--
-- Item type names ("Daggers", "Cloth", ...) come from the game's item database, which neither
-- repository has. They are written below by hand (ITEM_SUBCLASS_NAMES) and are not checked
-- against Forever; so are the subclass lists the game hands out at run time (AUCTION_SUBCLASSES).

local ui_source, resources = arg[1], arg[2]
assert(ui_source and resources, 'usage: make_forever_categories.lua <wow-ui-source> <BlizzardInterfaceResources>')

local env = setmetatable({}, {__index = _G})
local function load_into_env(path)
    local chunk = assert(loadfile(path))
    setfenv(chunk, env)
    chunk()
end

load_into_env(resources .. '/Resources/LuaEnum.lua')
local Enum = env.Enum
-- read line by line: the file has a few lines that are not Lua (a test string with a space in its
-- name)
for line in io.lines(resources .. '/Resources/GlobalStrings/enUS.lua') do
    local key, value = line:match('^([%w_]+) = (".*");%s*$')
    if key then
        env[key] = assert(loadstring('return ' .. value))()
    end
end

-- Not checked against Forever (see the top). English names as the Classic and modern clients
-- show them.
local ITEM_SUBCLASS_NAMES = {
    [Enum.ItemClass.Weapon] = {
        Axe1H = 'One-Handed Axes', Axe2H = 'Two-Handed Axes', Bows = 'Bows', Guns = 'Guns',
        Mace1H = 'One-Handed Maces', Mace2H = 'Two-Handed Maces', Polearm = 'Polearms',
        Sword1H = 'One-Handed Swords', Sword2H = 'Two-Handed Swords', Staff = 'Staves',
        Unarmed = 'Fist Weapons', Generic = 'Miscellaneous', Dagger = 'Daggers', Thrown = 'Thrown',
        Crossbow = 'Crossbows', Wand = 'Wands', Fishingpole = 'Fishing Poles',
    },
    [Enum.ItemClass.Armor] = {
        Generic = 'Miscellaneous', Cloth = 'Cloth', Leather = 'Leather', Mail = 'Mail',
        Plate = 'Plate', Shield = 'Shields', Libram = 'Librams', Idol = 'Idols', Totem = 'Totems',
    },
    [Enum.ItemClass.Container] = {
        Bag = 'Bag', Soul = 'Soul Bag', Herb = 'Herb Bag', Enchanting = 'Enchanting Bag',
        Engineering = 'Engineering Bag', Mining = 'Mining Bag',
        Leatherworking = 'Leatherworking Bag', Tacklebox = 'Tackle Box', Cooking = 'Cooking Bag',
        Reagent = 'Reagent Bag',
    },
    [Enum.ItemClass.Quiver] = {Quiver = 'Quiver', Ammopouch = 'Ammo Pouch'},
    [Enum.ItemClass.Consumable] = {
        Generic = 'Consumable', Potion = 'Potion', Elixir = 'Elixir', Flasksphials = 'Flask',
        Scroll = 'Scroll', Fooddrink = 'Food & Drink', Itemenhancement = 'Item Enhancement',
        Bandage = 'Bandage', Other = 'Other', ItemenhancementTemporary = 'Item Enhancement (Temporary)',
    },
    [Enum.ItemClass.Tradegoods] = {
        [0] = 'Trade Goods', [1] = 'Parts', [2] = 'Explosives', [3] = 'Devices', [5] = 'Cloth',
        [6] = 'Leather', [7] = 'Metal & Stone', [8] = 'Meat', [9] = 'Herb', [10] = 'Elemental',
        [11] = 'Other', [12] = 'Enchanting',
    },
    [Enum.ItemClass.Projectile] = {[2] = 'Arrow', [3] = 'Bullet'},
    [Enum.ItemClass.Recipe] = {
        Book = 'Book', Leatherworking = 'Leatherworking', Tailoring = 'Tailoring',
        Engineering = 'Engineering', Blacksmithing = 'Blacksmithing', Cooking = 'Cooking',
        Alchemy = 'Alchemy', FirstAid = 'First Aid', Enchanting = 'Enchanting', Fishing = 'Fishing',
    },
    [Enum.ItemClass.Miscellaneous] = {
        Junk = 'Junk', Reagent = 'Reagent', CompanionPet = 'Companion Pets', Holiday = 'Holiday',
        Other = 'Other', Mount = 'Mount',
    },
}
local SUBCLASS_ENUMS = {
    [Enum.ItemClass.Weapon] = Enum.ItemWeaponSubclass,
    [Enum.ItemClass.Armor] = Enum.ItemArmorSubclass,
    [Enum.ItemClass.Container] = Enum.ItemContainerSubclass,
    [Enum.ItemClass.Quiver] = Enum.ItemQuiverSubclass,
    [Enum.ItemClass.Consumable] = Enum.ItemConsumableSubclass,
    [Enum.ItemClass.Recipe] = Enum.ItemRecipeSubclass,
    [Enum.ItemClass.Miscellaneous] = Enum.ItemMiscellaneousSubclass,
}
-- by subclass number
local subclass_names = {}
for class_id, names in pairs(ITEM_SUBCLASS_NAMES) do
    subclass_names[class_id] = {}
    for key, name in pairs(names) do
        local id = type(key) == 'number' and key or assert(SUBCLASS_ENUMS[class_id][key], key)
        subclass_names[class_id][id] = name
    end
end

-- Not checked against Forever (see the top): the subclasses the game lists for these classes.
local AUCTION_SUBCLASSES = {
    [Enum.ItemClass.Consumable] = {0, 1, 2, 3, 4, 5, 6, 7, 8},
    [Enum.ItemClass.Tradegoods] = {0, 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12},
    [Enum.ItemClass.Projectile] = {2, 3},
    [Enum.ItemClass.Recipe] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9},
    [Enum.ItemClass.Miscellaneous] = {0, 1, 2, 3, 4, 5},
}

-- Enum.InventoryType.IndexHeadType -> INVTYPE_HEAD, the text GetItemInventorySlotInfo returns
local slot_names = {}
for key, id in pairs(Enum.InventoryType) do
    local part = key:match('^Index(.+)Type$')
    if part then
        local global = part == 'NonEquip' and 'INVTYPE_NON_EQUIP' or 'INVTYPE_' .. part:upper()
        slot_names[id] = env[global]
    end
end

env.CreateFromMixins = function(...)
    local t = {}
    for i = 1, select('#', ...) do
        for k, v in pairs((select(i, ...))) do t[k] = v end
    end
    return t
end
env.C_Item = {
    GetItemInventorySlotInfo = function(id) return assert(slot_names[id], 'slot ' .. tostring(id)) end,
    GetItemSubClassInfo = function(class_id, subclass_id)
        return assert(subclass_names[class_id] and subclass_names[class_id][subclass_id], 'no name for ' .. class_id .. '/' .. subclass_id)
    end,
    GetItemClassInfo = function(class_id) error('no class name for ' .. class_id) end,
}
env.C_AuctionHouse = {
    GetAuctionItemSubClasses = function(class_id) return assert(AUCTION_SUBCLASSES[class_id], 'no subclasses for ' .. class_id) end,
}
env.ITEM_CLASS_WOW_TOKEN = Enum.ItemClass.WoWToken
env.AUCTION_HOUSE_FILTER_STRINGS = env.AUCTION_HOUSE_FILTER_STRINGS or {}

local folder = ui_source .. '/Interface/AddOns/Blizzard_AuctionHouseUI/'
load_into_env(folder .. 'Shared/Blizzard_AuctionData.lua')
load_into_env(folder .. 'Camelot/Blizzard_AuctionData.lua')

-- write it out as data
local out = {}
local function w(s) out[#out + 1] = s end
local function filters_string(filters)
    local parts = {}
    for _, f in ipairs(filters) do
        local fields = {}
        for _, key in ipairs{'classID', 'subClassID', 'inventoryType'} do
            if f[key] then fields[#fields + 1] = key .. ' = ' .. f[key] end
        end
        parts[#parts + 1] = '{' .. table.concat(fields, ', ') .. '}'
    end
    return '{' .. table.concat(parts, ', ') .. '}'
end
local function write_category(category, indent)
    w(indent .. '{name = ' .. string.format('%q', category.name))
    if category.filters then w(', filters = ' .. filters_string(category.filters)) end
    if category.implicitFilter then w(', implicitFilter = ' .. category.implicitFilter) end
    if category.flags then
        local flags = {}
        for flag in pairs(category.flags) do flags[#flags + 1] = flag .. ' = true' end
        table.sort(flags)
        w(', flags = {' .. table.concat(flags, ', ') .. '}')
    end
    if category.subCategories then
        w(', subCategories = {\n')
        for _, sub in ipairs(category.subCategories) do write_category(sub, indent .. '  ') end
        w(indent .. '}')
    end
    w('},\n')
end

local version = io.open(ui_source .. '/version.txt')
version = version and version:read('*l') or 'unknown'
w('-- Forever\'s auction house categories (AuctionCategories), build ' .. version .. '.\n')
w('-- Made by tests/tools/make_forever_categories.lua from Blizzard\'s Camelot/Blizzard_AuctionData.lua\n')
w('-- (Gethe/wow-ui-source, branch forever) and the English text of the same build\n')
w('-- (Ketho/BlizzardInterfaceResources, branch forever). Do not edit by hand: run the script again.\n')
w('-- Item type names (Daggers, Cloth, ...) and the subclass lists of Consumables, Trade Goods, Ammo,\n')
w('-- Recipes and Miscellaneous are not checked against the game; see the script.\n')
w('return {\n')
for _, category in ipairs(env.AuctionCategories) do write_category(category, '  ') end
w('}\n')
io.write(table.concat(out))
