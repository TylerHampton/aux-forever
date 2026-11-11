-- Writes tests/forever_api.lua: the game functions, events and enum values Forever really has, as
-- plain data, for the test harness (outside review 2026-11-10, R-22). The harness answered any
-- C_ function name and any enum member, so a misspelled one passed every test and was only found
-- in game. With this list the harness fails on a call to a function, an event or an enum member
-- that Forever does not have.
--
-- Usage, from the repository root (Lua 5.1):
--   lua5.1 tests/tools/make_forever_api.lua <wow-ui-source> > tests/forever_api.lua
--
-- <wow-ui-source>: a checkout of branch `forever` of github.com/Gethe/wow-ui-source with
--   Interface/AddOns/Blizzard_APIDocumentationGenerated (Blizzard's generated documentation of the
--   game's own functions; clone with --filter=blob:none --no-checkout, then check out that folder).
--
-- What is written:
--   functions  for every C_ namespace the addon's code names: all of its functions
--   globals    every documented function that is not in a namespace (debugprofilestop, ...)
--   events     every event name
--   enums      for every Enum the addon's code names: its members and their values
-- Run it again after a Blizzard patch, or when the addon starts using a new namespace or Enum (the
-- harness says so). Functions written in Lua by Blizzard's interface code (mixins such as
-- ItemLocation, frames such as AuctionHouseFrame) are not in the documentation and not checked.

local ui_source = arg[1]
assert(ui_source, 'usage: make_forever_api.lua <wow-ui-source>')
local docs_dir = ui_source .. '/Interface/AddOns/Blizzard_APIDocumentationGenerated'

-- which namespaces and enums the addon names
local used_namespaces, used_enums = {}, {}
local toc = assert(io.open('auxForever/auxForever.toc'))
for line in toc:lines() do
    if not line:match('^##') and line:match('%S') then
        local path = 'auxForever/' .. line:gsub('\\', '/'):gsub('%s+$', '')
        local file = assert(io.open(path))
        local text = file:read('*a')
        file:close()
        for namespace in text:gmatch('(C_%a+)') do used_namespaces[namespace] = true end
        for enum in text:gmatch('Enum%.(%a+)') do used_enums[enum] = true end
    end
end
toc:close()

local functions, globals, events, enums = {}, {}, {}, {}
local env = setmetatable({}, {__index = _G})
env.APIDocumentation = {AddDocumentationTable = function(_, doc)
    local namespace = doc.Namespace
    for _, f in ipairs(doc.Functions or {}) do
        if namespace and namespace ~= '' then
            if used_namespaces[namespace] then
                functions[namespace] = functions[namespace] or {}
                functions[namespace][f.Name] = true
            end
        elseif doc.Type == 'System' then
            globals[f.Name] = true
        end
    end
    for _, e in ipairs(doc.Events or {}) do
        if e.LiteralName then events[e.LiteralName] = true end
    end
    for _, t in ipairs(doc.Tables or {}) do
        if t.Type == 'Enumeration' and used_enums[t.Name] then
            enums[t.Name] = enums[t.Name] or {}
            for _, field in ipairs(t.Fields or {}) do
                enums[t.Name][field.Name] = field.EnumValue
            end
        end
    end
end}

-- a few documentation files read Enum or Constants values while they load; any value will do here
local function anything() return setmetatable({}, {__index = function() return 0 end}) end
env.Enum = setmetatable({}, {__index = anything})
env.Constants = setmetatable({}, {__index = anything})

local list = assert(io.popen('ls "' .. docs_dir .. '"'))
for name in list:lines() do
    if name:match('%.lua$') then
        local chunk = assert(loadfile(docs_dir .. '/' .. name))
        setfenv(chunk, env)
        local ok, err = pcall(chunk)
        if not ok then io.stderr:write('skipped ' .. name .. ': ' .. tostring(err) .. '\n') end
    end
end
list:close()

local function sorted(set)
    local keys = {}
    for key in pairs(set) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

-- names on lines of about 100 characters
local function write_names(names, indent)
    local line = indent
    for _, name in ipairs(names) do
        local piece = "'" .. name .. "', "
        if #line + #piece > 100 then
            print((line:gsub('%s+$', '')))
            line = indent
        end
        line = line .. piece
    end
    if line ~= indent then print((line:gsub('%s+$', ''))) end
end

print('-- Made by tests/tools/make_forever_api.lua from Blizzard\'s generated documentation for Forever')
print('-- (github.com/Gethe/wow-ui-source, branch forever). Do not edit by hand: run the tool again.')
print('return {')
print('  functions = {')
for _, namespace in ipairs(sorted(used_namespaces)) do
    if functions[namespace] then
        print('    ' .. namespace .. ' = {')
        write_names(sorted(functions[namespace]), '      ')
        print('    },')
    end
end
print('  },')
print('  -- namespaces the addon names that the documentation does not have')
print('  undocumented = {')
for _, namespace in ipairs(sorted(used_namespaces)) do
    if not functions[namespace] then print("    '" .. namespace .. "',") end
end
print('  },')
print('  globals = {')
write_names(sorted(globals), '    ')
print('  },')
print('  events = {')
write_names(sorted(events), '    ')
print('  },')
print('  enums = {')
for _, enum in ipairs(sorted(used_enums)) do
    if enums[enum] then
        local parts = {}
        for _, member in ipairs(sorted(enums[enum])) do
            parts[#parts + 1] = member .. ' = ' .. tostring(enums[enum][member])
        end
        local line = '    ' .. enum .. ' = {'
        local out = line
        for _, part in ipairs(parts) do
            if #out + #part + 2 > 100 then
                print(out)
                out = '      '
            end
            out = out .. part .. ', '
        end
        print((out:gsub('%s+$', '')))
        print('    },')
    end
end
print('  },')
print('  -- Enums the addon names that the documentation does not have')
print('  undocumented_enums = {')
for _, enum in ipairs(sorted(used_enums)) do
    if not enums[enum] then print("    '" .. enum .. "',") end
end
print('  },')
print('}')
