select(2, ...) 'aux.core.shortcut'

local aux = require 'aux'
local info = require 'aux.util.info'

-- Shift-click or Alt-click an item (in your bags, a chat link, ...) while aux is open to use it in
-- the current tab: the Search tab searches for it, the Post tab selects it.
-- Forever: a Shift-click normally goes into Blizzard's own auction house search box, which aux
-- keeps hidden, so it is taken over here. With a chat box open, Shift-click still links to chat.
hooksecurefunc('HandleModifiedItemClick', function(item_link)
    if not item_link or not aux.frame:IsShown() or not strfind(item_link, 'item:', 1, true) then
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
end)
