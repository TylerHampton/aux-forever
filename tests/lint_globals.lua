-- Run from the repository root: lua5.1 tests/lint_globals.lua
-- Looks for misspelled names in the addon (outside review 2026-11-10, R-24).
--
-- In aux's module system (libs/package.lua) a name that is not a local is looked up in the file's
-- module, then in the game's globals. A misspelled one is simply nil: no error says so, and the
-- tests only notice when the mistake changes what they check. This reads every file's compiled
-- code (luac -l) and lists each name that is read but that nothing defines: not the module (in any
-- of its files), not the module system, and not a game global aux is known to use
-- (tests/known_globals.lua). A new game global goes into that file once it is checked to exist.
-- Ends with "lint: 0 unknown names", or lists them and exits with an error.

local known = dofile('tests/known_globals.lua')
local api = dofile('tests/forever_api.lua')
local global = {}
for _, name in ipairs(known) do global[name] = true end
for _, name in ipairs(api.globals) do global[name] = true end
for namespace in pairs(api.functions) do global[namespace] = true end

-- what the module system and Lua itself give every module
for _, name in ipairs{'M', '_M', 'pass', 'empty', 'require', '_G', 'select', 'pairs', 'ipairs', 'next', 'type', 'tostring',
    'tonumber', 'unpack', 'setmetatable', 'getmetatable', 'rawget', 'rawset', 'error', 'pcall', 'assert', 'getfenv', 'setfenv',
    'string', 'table', 'math', 'coroutine', 'collectgarbage', 'date', 'time', 'gmatch', 'loadstring', 'print'} do
    global[name] = true
end

local files = {}
for line in io.lines('auxForever/auxForever.toc') do
    if not line:match('^##') and line:match('%S') then
        files[#files + 1] = 'auxForever/' .. line:gsub('\\', '/'):gsub('%s+$', '')
    end
end

local defined, reads = {}, {} -- module -> names it defines; {module, file, line, name}
for _, path in ipairs(files) do
    local file = assert(io.open(path))
    local source = file:read('*a')
    file:close()
    local module = source:match("^select%(2, %.%.%.%) '([%w%._]+)'") or path
    defined[module] = defined[module] or {}
    for name in source:gmatch('M%.([%a_][%w_]*)%s*=') do defined[module][name] = true end
    for name in source:gmatch('function M[%.:]([%a_][%w_]*)') do defined[module][name] = true end
    local listing = assert(io.popen('luac5.1 -l -p "' .. path .. '"'))
    for row in listing:lines() do
        local line, op, name = row:match('%[(%d+)%]%s+(%u+GLOBAL)%s+[%-%d]+%s+[%-%d]+%s+; ([%a_][%w_]*)')
        if op == 'SETGLOBAL' then
            defined[module][name] = true
        elseif op == 'GETGLOBAL' then
            reads[#reads + 1] = {module, path, tonumber(line), name}
        end
    end
    listing:close()
end

-- event handlers are written into the module by name (function AUCTION_HOUSE_SHOW() in module aux)
local unknown, seen = {}, {}
for _, read in ipairs(reads) do
    local module, path, line, name = read[1], read[2], read[3], read[4]
    if not defined[module][name] and not global[name] then
        local key = path .. ':' .. name
        if not seen[key] then
            seen[key] = true
            unknown[#unknown + 1] = string.format('%s:%d: %s', path, line, name)
        end
    end
end
table.sort(unknown)
for _, text in ipairs(unknown) do print(text) end
print('lint: ' .. #unknown .. ' unknown names')
if #unknown > 0 then os.exit(1) end
