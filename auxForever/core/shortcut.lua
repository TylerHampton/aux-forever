select(2, ...) 'aux.core.shortcut'

local aux = require 'aux'
local info = require 'aux.util.info'
local search_tab = require 'aux.tabs.search'

-- Shift-click or Alt-click an item (in your bags, a chat link, ...) while aux is open to use it in
-- the current tab: the Search tab searches for it, the Post tab selects it.
-- Forever: a Shift-click normally goes into Blizzard's own auction house search box, which aux
-- keeps hidden, so it is taken over here. With a chat box open, Shift-click still links to chat.
-- auxForever (0.4): Alt-click on a recipe in the profession window searches its item and materials
-- (Shift-click on a recipe is Blizzard's "track recipe", so only Alt is used for recipes)
function M.on_modified_click(item_link)
    if not item_link or not aux.frame:IsShown() then
        return
    end
    local recipe_id = search_tab.recipe_id_from_link(item_link)
    if recipe_id then
        if IsAltKeyDown() then
            search_tab.search_recipe(recipe_id)
        end
        return
    end
    if not strfind(item_link, 'item:', 1, true) then
        return
    end
    -- clicks on aux's own result rows are handled by aux itself
    if aux.frame:IsMouseOver() then
        return
    end
    local tab = aux.get_tab()
    if not (tab and tab.USE_ITEM) then
        return
    end
    local chat_open = ChatFrameUtil and ChatFrameUtil.GetActiveWindow and ChatFrameUtil.GetActiveWindow()
    if IsAltKeyDown() or (IsModifiedClick('CHATLINK') and not chat_open) then
        tab.USE_ITEM(info.parse_link(item_link))
    end
end

hooksecurefunc('HandleModifiedItemClick', function(item_link)
    on_modified_click(item_link)
end)
