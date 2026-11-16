select(2, ...) 'aux.core.weights'

-- auxForever (Upgrades tab, docs/upgrades.md): each spec's stat priority, and the weights the
-- Upgrades tab scores gear with (core/stats.lua).
--
-- The priorities are Icy Veins' WoW Forever stat pages, one per spec, read 2026-11-16
-- (docs/stat-priorities.md; Outside). They give an order, not numbers per point, so the weights are
-- ranked (Ben, 2026-11-16, option A): in a list of n stats the first is worth n per point, the next
-- n - 1, down to 1 for the last. A stat not in the list is worth 0. Only the order within one spec
-- matters, since a spec is only compared with itself.
--
-- A weight is keyed by the names GetItemStats gives stats (core/stats.lua). The game knows these
-- names on Forever (E10, the global strings ITEM_MOD_*_SHORT printed in game, Ben 2026-11-16, Seen):
-- for several stats it has more than one (Hit, Hit (Melee), Hit (Spell), Hit (Ranged)), so each of
-- our stats lists every one of them. A real item gave Spell Power under ITEM_MOD_SPELL_POWER_SHORT
-- only (Brutal War Axe of the Sorcerer, Seen); the names for Hit, Crit and MP5 on an item are not
-- seen yet, and an item giving one of them under two names would count it twice.

-- our stat names -> the game's stat names
M.STATS = {
    strength = {'ITEM_MOD_STRENGTH_SHORT'},
    agility = {'ITEM_MOD_AGILITY_SHORT'},
    stamina = {'ITEM_MOD_STAMINA_SHORT'},
    intellect = {'ITEM_MOD_INTELLECT_SHORT'},
    spirit = {'ITEM_MOD_SPIRIT_SHORT'},
    -- "Weapon Damage" in the hunter, Subtlety and Retribution pages too: the stats give DPS only
    weapon_dps = {'ITEM_MOD_DAMAGE_PER_SECOND_SHORT'},
    attack_power = {'ITEM_MOD_ATTACK_POWER_SHORT', 'ITEM_MOD_MELEE_ATTACK_POWER_SHORT', 'ITEM_MOD_RANGED_ATTACK_POWER_SHORT'},
    -- "Spell Power" and "Spell Damage" (the guides use both words)
    spell_power = {'ITEM_MOD_SPELL_POWER_SHORT', 'ITEM_MOD_SPELL_DAMAGE_DONE_SHORT'},
    healing = {'ITEM_MOD_SPELL_HEALING_DONE_SHORT'},
    hit = {'ITEM_MOD_HIT_RATING_SHORT', 'ITEM_MOD_HIT_MELEE_RATING_SHORT', 'ITEM_MOD_HIT_SPELL_RATING_SHORT', 'ITEM_MOD_HIT_RANGED_RATING_SHORT'},
    crit = {'ITEM_MOD_CRIT_RATING_SHORT', 'ITEM_MOD_CRIT_MELEE_RATING_SHORT', 'ITEM_MOD_CRIT_SPELL_RATING_SHORT', 'ITEM_MOD_CRIT_RANGED_RATING_SHORT'},
    haste = {'ITEM_MOD_HASTE_RATING_SHORT'},
    expertise = {'ITEM_MOD_EXPERTISE_RATING_SHORT'},
    -- "Spell Piercing" in game
    spell_pierce = {'ITEM_MOD_SPELL_PENETRATION_SHORT'},
    -- "Mana Regeneration per 5 sec" and "Mana Per 5 Sec."
    mp5 = {'ITEM_MOD_MANA_REGENERATION_SHORT', 'ITEM_MOD_POWER_REGEN0_SHORT'},
    -- base armor (RESISTANCE0_NAME, Retail's name; not in the printed list, which held only
    -- ITEM_MOD_ names) and "Bonus Armor"
    armor = {'RESISTANCE0_NAME', 'ITEM_MOD_EXTRA_ARMOR_SHORT'},
    defense = {'ITEM_MOD_DEFENSE_SKILL_RATING_SHORT'},
    dodge = {'ITEM_MOD_DODGE_RATING_SHORT'},
    -- "Avoidance": dodge, parry and block
    avoidance = {'ITEM_MOD_DODGE_RATING_SHORT', 'ITEM_MOD_PARRY_RATING_SHORT', 'ITEM_MOD_BLOCK_RATING_SHORT'},
    -- Subtlety's Weapon Skill: the melee weapon skills ("Daggers Skill", "Swords Skill", ...)
    weapon_skill = {'ITEM_MOD_DAGGERS_SHORT', 'ITEM_MOD_SWORDS_SHORT', 'ITEM_MOD_MACES_SHORT', 'ITEM_MOD_AXES_SHORT', 'ITEM_MOD_FIST_WEAPONS_SHORT'},
}

-- our stat names as the Upgrades tab shows them
M.STAT_NAMES = {
    strength = 'Strength', agility = 'Agility', stamina = 'Stamina', intellect = 'Intellect',
    spirit = 'Spirit', weapon_dps = 'Weapon DPS', attack_power = 'Attack Power',
    spell_power = 'Spell Power', healing = 'Healing Power', hit = 'Hit', crit = 'Crit',
    haste = 'Haste', expertise = 'Expertise', spell_pierce = 'Spell Pierce', mp5 = 'MP5',
    armor = 'Armor', defense = 'Defense', dodge = 'Dodge', avoidance = 'Avoidance',
    weapon_skill = 'Weapon Skill',
}

-- ap: how much Attack Power one point of a stat gives this spec, from its guide's own words (Icy
-- Veins, read 2026-11-16, docs/stat-priorities.md; Outside). Specs whose list has no Attack Power
-- get a weight for it from these (derived_attack_power).
local function spec(id, name, priority, page, ap)
    return {id = id, name = name, priority = priority, page = page, ap = ap}
end

-- "Each point of Strength gives a Warrior 2 melee Attack Power"; Agility gives Warriors none
local WARRIOR_AP = {strength = 2}
-- Rogues: 1 Attack Power per point of Agility, and per point of Strength
local ROGUE_AP = {agility = 1, strength = 1}

-- by the class token UnitClass gives ('SHAMAN'); page: the Icy Veins page, without
-- https://www.icy-veins.com/wow-forever/ and -stat-priority
M.SPECS = {
    DRUID = {
        spec('balance', 'Balance', {'hit', 'crit', 'spell_power', 'intellect'}, 'balance-druid-ranged-dps-pve'),
        spec('feral', 'Feral (damage and threat)', {'weapon_dps', 'expertise', 'hit', 'agility', 'strength'}, 'feral-druid-melee-dps-and-tank-pve', {strength = 2, agility = 1}),
        spec('feral_tank', 'Feral (tank survival)', {'armor', 'defense', 'stamina', 'agility', 'dodge'}, 'feral-druid-melee-dps-and-tank-pve'),
        spec('restoration', 'Restoration', {'healing', 'intellect', 'spirit', 'mp5', 'crit'}, 'restoration-druid-healer-pve'),
    },
    HUNTER = {
        spec('beast_mastery', 'Beast Mastery', {'weapon_dps', 'hit', 'crit', 'agility', 'attack_power'}, 'beast-mastery-hunter-ranged-dps-pve'),
        spec('marksmanship', 'Marksmanship', {'weapon_dps', 'hit', 'crit', 'agility', 'attack_power'}, 'marksmanship-hunter-ranged-dps-pve'),
        spec('survival', 'Survival', {'weapon_dps', 'hit', 'crit', 'agility', 'attack_power'}, 'survival-hunter-melee-dps-pve'),
    },
    MAGE = {
        spec('arcane', 'Arcane', {'hit', 'spell_power', 'crit', 'intellect', 'spirit', 'mp5'}, 'arcane-mage-ranged-dps-pve'),
        spec('fire', 'Fire', {'hit', 'spell_power', 'crit', 'intellect', 'spirit', 'mp5'}, 'fire-mage-ranged-dps-pve'),
        spec('frost', 'Frost', {'hit', 'spell_power', 'crit', 'intellect', 'mp5', 'spirit'}, 'frost-mage-ranged-dps-pve'),
    },
    PALADIN = {
        spec('retribution', 'Retribution (Unsealed Wrath)', {'weapon_dps', 'hit', 'expertise', 'strength', 'spell_power'}, 'retribution-paladin-melee-dps-pve', {strength = 2}),
        spec('retribution_shock', 'Retribution (Holy Shock)', {'weapon_dps', 'hit', 'spell_power', 'crit', 'expertise'}, 'retribution-paladin-melee-dps-pve', {strength = 2}),
        spec('protection', 'Protection', {'stamina', 'defense', 'spell_power', 'intellect', 'strength'}, 'protection-paladin-tank-pve', {strength = 1}),
        spec('holy', 'Holy', {'healing', 'intellect', 'spirit', 'mp5', 'crit'}, 'holy-paladin-healer-pve'),
    },
    PRIEST = {
        spec('discipline', 'Discipline', {'healing', 'mp5', 'spirit', 'intellect', 'crit'}, 'discipline-priest-healer-pve'),
        spec('holy', 'Holy', {'healing', 'mp5', 'spirit', 'intellect', 'crit'}, 'holy-priest-healer-pve'),
        spec('shadow', 'Shadow', {'hit', 'spell_power', 'crit', 'spell_pierce', 'spirit'}, 'shadow-priest-ranged-dps-pve'),
    },
    ROGUE = {
        spec('assassination', 'Assassination', {'expertise', 'hit', 'agility', 'weapon_dps', 'crit'}, 'assassination-rogue-melee-dps-pve', ROGUE_AP),
        spec('combat', 'Combat', {'expertise', 'hit', 'agility', 'weapon_dps', 'crit'}, 'combat-rogue-melee-dps-pve', ROGUE_AP),
        spec('subtlety', 'Subtlety', {'weapon_dps', 'expertise', 'hit', 'weapon_skill', 'agility'}, 'subtlety-rogue-melee-dps-pve', ROGUE_AP),
    },
    SHAMAN = {
        spec('elemental', 'Elemental', {'spell_power', 'hit', 'crit', 'intellect', 'mp5'}, 'elemental-shaman-ranged-dps-pve'),
        spec('enhancement', 'Enhancement', {'weapon_dps', 'hit', 'expertise', 'strength', 'intellect', 'spell_power'}, 'enhancement-shaman-melee-dps-pve', {strength = 2}),
        spec('restoration', 'Restoration', {'healing', 'crit', 'intellect', 'spirit', 'mp5'}, 'restoration-shaman-healer-pve'),
    },
    WARLOCK = {
        spec('affliction', 'Affliction', {'hit', 'spell_power', 'crit', 'haste', 'intellect'}, 'affliction-warlock-ranged-dps-pve'),
        spec('demonology', 'Demonology', {'hit', 'spell_power', 'crit', 'haste', 'intellect'}, 'demonology-warlock-ranged-dps-pve'),
        spec('destruction', 'Destruction', {'hit', 'spell_power', 'haste', 'crit', 'intellect'}, 'destruction-warlock-ranged-dps-pve'),
    },
    WARRIOR = {
        spec('arms', 'Arms', {'weapon_dps', 'hit', 'expertise', 'crit', 'strength'}, 'arms-warrior-melee-dps-pve', WARRIOR_AP),
        spec('fury', 'Fury', {'weapon_dps', 'hit', 'expertise', 'crit', 'strength'}, 'fury-warrior-melee-dps-pve', WARRIOR_AP),
        spec('protection', 'Protection (threat)', {'expertise', 'hit', 'agility', 'strength', 'stamina'}, 'protection-warrior-tank-pve', WARRIOR_AP),
        spec('protection_survival', 'Protection (survival)', {'stamina', 'armor', 'agility', 'avoidance', 'defense'}, 'protection-warrior-tank-pve'),
    },
}

-- a class's specs, in the order above
function M.specs(class)
    return SPECS[class or ''] or {}
end

-- one spec of a class by its id, or nil
function M.spec(class, id)
    for _, s in ipairs(specs(class)) do
        if s.id == id then return s end
    end
end

-- the order the weights editor lists the stats in (tabs/upgrades/weights.lua)
M.STAT_ORDER = {
    'weapon_dps', 'strength', 'agility', 'attack_power', 'stamina', 'intellect', 'spirit',
    'spell_power', 'healing', 'hit', 'crit', 'haste', 'expertise', 'spell_pierce', 'mp5', 'armor',
    'defense', 'dodge', 'avoidance', 'weapon_skill',
}

-- Attack Power for a spec whose list does not name it: worth what the stats that give it are worth
-- per point of Attack Power they give (Strength 3 that gives 2 Attack Power: 1.5), the most of
-- them. A stat that gives more than Attack Power (Agility's crit) makes this a little generous.
local function derived_attack_power(s, ranks)
    if not s.ap then return end
    local best
    for stat, amount in pairs(s.ap) do
        if ranks[stat] and amount > 0 then
            best = max(best or 0, ranks[stat] / amount)
        end
    end
    return best
end

local function lists(s, name)
    for _, stat in ipairs(s.priority) do
        if stat == name then return true end
    end
end

-- the guide's ranked weights by our stat names: n for the first of n, down to 1, and Attack Power
-- from its conversions when the list does not name it
function M.default_ranks(s)
    local ranks, n = {}, #s.priority
    for i, name in ipairs(s.priority) do
        ranks[name] = n - i + 1
    end
    if not lists(s, 'attack_power') then
        ranks.attack_power = derived_attack_power(s, ranks)
    end
    return ranks
end

-- the weights in use by our stat names: the guide's, with the player's own numbers over them
-- (overrides: stat name -> number, from the weights editor; 0 turns a stat off). Derived Attack
-- Power follows the player's Strength or Agility unless they set Attack Power themselves.
function M.ranks(s, overrides)
    local ranks = default_ranks(s)
    for name, value in pairs(overrides or {}) do
        if STATS[name] and type(value) == 'number' then
            ranks[name] = value > 0 and value or nil
        end
    end
    if not lists(s, 'attack_power') and not (overrides and overrides.attack_power) then
        ranks.attack_power = derived_attack_power(s, ranks)
    end
    return ranks
end

-- a spec's weights by the game's stat names, for stats.score
function M.weights(s, overrides)
    local weights = {}
    for name, rank in pairs(ranks(s, overrides)) do
        for _, key in ipairs(STATS[name] or {}) do
            weights[key] = max(weights[key] or 0, rank)
        end
    end
    return weights
end
