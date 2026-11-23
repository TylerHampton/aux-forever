select(2, ...) 'aux.core.inventory'

local aux = require 'aux'
local info = require 'aux.util.info'

-- auxForever (0.9.1, FB-023, Kortan; Tyler 2026-11-22: opt-in, starts off by default):
-- Per-character inventory snapshots (bags, bank once opened, mail once opened) saved per realm and
-- faction in aux.faction_data.inventory. Nothing listens or writes until the player opts in (via
-- Settings > Tooltip Lines > Inventory counts, the Shopping List's Count alts switch, or /aux
-- inventory on). No OnUpdate handler: zero per-frame cost.

local CLASS_RGB = {
    DRUID = {1.00, 0.49, 0.04},
    HUNTER = {0.67, 0.83, 0.45},
    MAGE = {0.25, 0.78, 0.92},
    PALADIN = {0.96, 0.55, 0.73},
    PRIEST = {1.00, 1.00, 1.00},
    ROGUE = {1.00, 0.96, 0.41},
    SHAMAN = {0.00, 0.44, 0.87},
    WARLOCK = {0.53, 0.53, 0.93},
    WARRIOR = {0.78, 0.61, 0.43},
}

local CHAR_BANK_BAGS = {
    Enum.BagIndex.Characterbanktab or -2,
    Enum.BagIndex.CharacterBankTab_1 or 6,
    Enum.BagIndex.CharacterBankTab_2 or 7,
    Enum.BagIndex.CharacterBankTab_3 or 8,
    Enum.BagIndex.CharacterBankTab_4 or 9,
    Enum.BagIndex.CharacterBankTab_5 or 10,
    Enum.BagIndex.CharacterBankTab_6 or 11,
    Enum.BagIndex.CharacterBankTab_7 or 12,
    Enum.BagIndex.CharacterBankTab_8 or 13,
    Enum.BagIndex.CharacterBankTab_9 or 14,
}

local ACCOUNT_BANK_BAGS = {
    Enum.BagIndex.AccountBankTab_1 or 15,
    Enum.BagIndex.AccountBankTab_2 or 16,
    Enum.BagIndex.AccountBankTab_3 or 17,
    Enum.BagIndex.AccountBankTab_4 or 18,
    Enum.BagIndex.AccountBankTab_5 or 19,
    Enum.BagIndex.AccountBankTab_6 or 20,
    Enum.BagIndex.AccountBankTab_7 or 21,
    Enum.BagIndex.AccountBankTab_8 or 22,
    Enum.BagIndex.AccountBankTab_9 or 23,
}

local bank_open = false
local mail_open = false
local listener_ids = {}
local change_callbacks = {}

local function is_secret(value)
    return issecretvalue and issecretvalue(value)
end

local function store()
    if not aux.faction_data then
        return nil
    end
    aux.faction_data.inventory = aux.faction_data.inventory or {}
    aux.faction_data.inventory.chars = aux.faction_data.inventory.chars or {}
    aux.faction_data.inventory.account_bank = aux.faction_data.inventory.account_bank or {}
    return aux.faction_data.inventory
end

local function player_name()
    local name = UnitName and UnitName('player')
    if type(name) == 'string' and name ~= '' then
        return name
    end
    return nil
end

local function player_class()
    if UnitClass then
        local _, class = UnitClass('player')
        if type(class) == 'string' and class ~= '' then
            return class
        end
    end
    return nil
end

local function ensure_self_entry()
    local inv = store()
    local name = player_name()
    if not inv or not name then
        return nil
    end
    local entry = inv.chars[name]
    if type(entry) ~= 'table' then
        entry = {bags = {}, bank = {}, mail = {}}
        inv.chars[name] = entry
    end
    entry.bags = entry.bags or {}
    entry.bank = entry.bank or {}
    entry.mail = entry.mail or {}
    local class = player_class()
    if class then
        entry.class = class
    end
    return entry
end

local function notify_changed()
    for _, fn in ipairs(change_callbacks) do
        fn()
    end
end

function M.on_change(fn)
    if type(fn) == 'function' then
        tinsert(change_callbacks, fn)
    end
end

-- Opt-in check: true only when the player turned on alt tracking (via Settings > Tooltip Lines >
-- Inventory counts, the Shopping List's Count alts switch, or /aux inventory on).
function M.is_enabled()
    return aux.account_data and aux.account_data.alt_inventory and true or false
end

local function scan_bag_list(bags, target)
    aux.wipe(target)
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then
        return false
    end
    local any_slots = false
    for _, bag in ipairs(bags) do
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        if slots > 0 then
            any_slots = true
            for slot = 1, slots do
                local item = C_Container.GetContainerItemInfo(bag, slot)
                if type(item) == 'table' then
                    local item_id = item.itemID
                    local count = item.stackCount
                    if not item_id and C_Container.GetContainerItemID then
                        item_id = C_Container.GetContainerItemID(bag, slot)
                    end
                    if type(item_id) == 'number' and item_id > 0 and not is_secret(item_id) and not is_secret(count) then
                        count = type(count) == 'number' and count > 0 and count or 1
                        target[item_id] = (target[item_id] or 0) + count
                    end
                end
            end
        end
    end
    return any_slots
end

function M.scan_bags()
    if not is_enabled() then
        return false
    end
    local entry = ensure_self_entry()
    if not entry then
        return false
    end
    local bags = {}
    for bag = 0, info.last_bag() do
        tinsert(bags, bag)
    end
    scan_bag_list(bags, entry.bags)
    entry.bags_at = time()
    notify_changed()
    return true
end

-- Forever uses modern CharacterBankTab_1..9 (and AccountBankTab_1..9 if enabled; Code,
-- Blizzard_UIPanels_Game/Camelot/BankFrame.lua). Only scanned while the bank frame is open so
-- closed bank tabs returning 0 slots never overwrite a character's saved bank snapshot.
function M.scan_bank()
    if not is_enabled() or not bank_open then
        return false
    end
    local inv = store()
    local entry = ensure_self_entry()
    if not inv or not entry then
        return false
    end
    local char_bank = {}
    if scan_bag_list(CHAR_BANK_BAGS, char_bank) then
        entry.bank = char_bank
        entry.bank_at = time()
    end
    local acc = {}
    if scan_bag_list(ACCOUNT_BANK_BAGS, acc) then
        inv.account_bank = acc
        inv.account_bank_at = time()
    end
    notify_changed()
    return true
end

-- Mail snapshot: GetInboxNumItems + GetInboxItem (Code, Blizzard_MailFrame/MailFrame.lua on
-- Forever). Only scanned while the mailbox is open; skips currency attachments (isCurrency).
function M.scan_mail()
    if not is_enabled() or not mail_open then
        return false
    end
    local entry = ensure_self_entry()
    if not entry or not (GetInboxNumItems and GetInboxItem) then
        return false
    end
    aux.wipe(entry.mail)
    local num_mail = GetInboxNumItems() or 0
    local max_attach = ATTACHMENTS_MAX_RECEIVE or 16
    for i = 1, num_mail do
        for a = 1, max_attach do
            local _, item_id, _, count, _, _, is_currency = GetInboxItem(i, a)
            if not is_currency and type(item_id) == 'number' and item_id > 0
                    and not is_secret(item_id) and not is_secret(count) then
                count = type(count) == 'number' and count > 0 and count or 1
                entry.mail[item_id] = (entry.mail[item_id] or 0) + count
            end
        end
    end
    entry.mail_at = time()
    notify_changed()
    return true
end

local function kill_listeners()
    for _, id in ipairs(listener_ids) do
        aux.kill_listener(id)
    end
    listener_ids = {}
end

local function register_listeners()
    if #listener_ids > 0 then
        return
    end
    local function on(event, fn)
        tinsert(listener_ids, aux.event_listener(event, fn))
    end
    on('BAG_UPDATE_DELAYED', function()
        scan_bags()
        if bank_open then
            scan_bank()
        end
    end)
    on('BANKFRAME_OPENED', function()
        bank_open = true
        scan_bank()
    end)
    on('BANKFRAME_CLOSED', function()
        bank_open = false
    end)
    on('PLAYERBANKSLOTS_CHANGED', function()
        if bank_open then
            scan_bank()
        end
    end)
    on('PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED', function()
        if bank_open then
            scan_bank()
        end
    end)
    on('BANK_TABS_CHANGED', function()
        if bank_open then
            scan_bank()
        end
    end)
    on('MAIL_SHOW', function()
        mail_open = true
        scan_mail()
    end)
    on('MAIL_INBOX_UPDATE', function()
        if mail_open then
            scan_mail()
        end
    end)
    on('MAIL_CLOSED', function()
        mail_open = false
    end)
end

function M.sync_listeners()
    if is_enabled() then
        register_listeners()
    else
        kill_listeners()
        bank_open = false
        mail_open = false
    end
end

function M.set_enabled(on)
    if not aux.account_data then
        return false
    end
    aux.account_data.alt_inventory = on and true or false
    sync_listeners()
    if aux.account_data.alt_inventory then
        scan_bags()
    else
        notify_changed()
    end
    return aux.account_data.alt_inventory
end

function M.clear()
    local inv = store()
    if inv then
        aux.wipe(inv.chars)
        aux.wipe(inv.account_bank)
        inv.account_bank_at = nil
    end
    if is_enabled() then
        scan_bags()
    else
        notify_changed()
    end
end

function M.character_count()
    local inv = store()
    if not inv then
        return 0
    end
    local n = 0
    for _ in pairs(inv.chars) do
        n = n + 1
    end
    return n
end

-- Live bag count for the current character (always works, even when opt-in alt tracking is off).
function M.live_bag_count(item_id)
    if type(item_id) ~= 'number' or item_id <= 0 then
        return 0
    end
    local count
    if C_Item and C_Item.GetItemCount then
        count = C_Item.GetItemCount(item_id, false)
    elseif GetItemCount then
        count = GetItemCount(item_id, false)
    end
    return type(count) == 'number' and not is_secret(count) and count > 0 and count or 0
end

-- Returns: total, entries (current character first, then alts alphabetically), account_bank_count
-- Each entry: {name, class, is_self, bags, bank, mail, total}
function M.item_breakdown(item_id)
    if type(item_id) ~= 'number' or item_id <= 0 then
        return 0, {}, 0
    end
    local me = player_name()
    local inv = store()
    local chars = inv and inv.chars or empty
    local entries = {}
    local total = 0

    local self_entry = me and chars[me]
    local self_bags = live_bag_count(item_id)
    local self_bank = is_enabled() and self_entry and self_entry.bank and self_entry.bank[item_id] or 0
    local self_mail = is_enabled() and self_entry and self_entry.mail and self_entry.mail[item_id] or 0
    local self_total = self_bags + self_bank + self_mail
    if self_total > 0 then
        tinsert(entries, {
            name = me or 'You',
            class = (self_entry and self_entry.class) or player_class(),
            is_self = true,
            bags = self_bags,
            bank = self_bank,
            mail = self_mail,
            total = self_total,
        })
        total = total + self_total
    end

    if is_enabled() then
        local alt_names = {}
        for name in pairs(chars) do
            if name ~= me then
                tinsert(alt_names, name)
            end
        end
        sort(alt_names)
        for _, name in ipairs(alt_names) do
            local c = chars[name]
            local bags = c and c.bags and c.bags[item_id] or 0
            local bank = c and c.bank and c.bank[item_id] or 0
            local mail = c and c.mail and c.mail[item_id] or 0
            local char_total = bags + bank + mail
            if char_total > 0 then
                tinsert(entries, {
                    name = name,
                    class = c.class,
                    is_self = false,
                    bags = bags,
                    bank = bank,
                    mail = mail,
                    total = char_total,
                })
                total = total + char_total
            end
        end
    end

    local account_bank = is_enabled() and inv and inv.account_bank and inv.account_bank[item_id] or 0
    total = total + account_bank
    return total, entries, account_bank
end

-- Counts for the Shopping List: self_bags (always live), extra_have (this char's bank/mail +
-- alts + account bank, only when include_alts is true and tracking is enabled), and breakdown.
function M.shopping_counts(item_id, include_alts)
    local self_bags = live_bag_count(item_id)
    if not include_alts or not is_enabled() then
        return self_bags, 0, {}, 0
    end
    local total, entries, account_bank = item_breakdown(item_id)
    local extra = max(0, total - self_bags)
    return self_bags, extra, entries, account_bank
end

local function format_places(entry)
    local parts = {}
    if entry.bags > 0 then tinsert(parts, entry.bags .. ' bags') end
    if entry.bank > 0 then tinsert(parts, entry.bank .. ' bank') end
    if entry.mail > 0 then tinsert(parts, entry.mail .. ' mail') end
    return table.concat(parts, ', ')
end

-- Per-character inventory block for item tooltips (Tyler, 2026-11-22: per character, opt-in,
-- starts off). Adds nothing when the player owns 0 of the item.
function M.add_tooltip_lines(tooltip, item_id)
    local total, entries, account_bank = item_breakdown(item_id)
    if total <= 0 then
        return
    end
    local multi = #entries + (account_bank > 0 and 1 or 0) > 1
    local header = multi and ('Owned: ' .. total .. ' total') or ('Owned: ' .. total)
    local hr, hg, hb = aux.color.tooltip.value()
    tooltip:AddLine(header, hr, hg, hb)
    local rr, rg, rb = aux.color.label.enabled()
    for _, entry in ipairs(entries) do
        local rgb = entry.class and CLASS_RGB[entry.class]
        local lr, lg, lb = rgb and rgb[1] or 1, rgb and rgb[2] or 1, rgb and rgb[3] or 1
        local label = '  ' .. entry.name .. (entry.is_self and ' (You)' or '')
        tooltip:AddDoubleLine(label, format_places(entry), lr, lg, lb, rr, rg, rb)
    end
    if account_bank > 0 then
        local ar, ag, ab = aux.color.blue()
        tooltip:AddDoubleLine('  Account Bank', tostring(account_bank), ar, ag, ab, rr, rg, rb)
    end
end

function M.memory_counts()
    local chars = character_count()
    local items = 0
    local inv = store()
    if inv then
        for _, c in pairs(inv.chars) do
            for _ in pairs(c.bags or empty) do items = items + 1 end
            for _ in pairs(c.bank or empty) do items = items + 1 end
            for _ in pairs(c.mail or empty) do items = items + 1 end
        end
        for _ in pairs(inv.account_bank or empty) do items = items + 1 end
    end
    return chars, items
end

function aux.event.PLAYER_LOGIN()
    sync_listeners()
    if is_enabled() then
        scan_bags()
    end
end
