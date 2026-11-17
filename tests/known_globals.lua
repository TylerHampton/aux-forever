-- Game globals the addon reads, for tests/lint_globals.lua (outside review 2026-11-10, R-24).
-- Functions of the C_ namespaces and the documented global functions come from
-- tests/forever_api.lua; these are the rest. Each was looked up for Forever on 2026-11-10:
-- GlobalAPI, FrameXML, Frames and GlobalStrings are the lists of
-- github.com/Ketho/BlizzardInterfaceResources (branch forever, build 70532); "Blizzard's Lua" is a
-- global its interface code defines (github.com/Gethe/wow-ui-source, branch forever).
-- Add a name here only after checking that Forever has it.
return {
  -- GlobalAPI: functions of the game
  'ClearOverrideBindings', 'CreateFrame', 'GetBuybackItemInfo', 'GetInventoryItemCount', 'GetLootSlotInfo',
  'GetMerchantItemLink', 'GetMerchantNumItems', 'InCombatLockdown', 'IsModifiedClick', 'PlaySound',
  'SetOverrideBindingClick', 'hooksecurefunc',
  -- GlobalAPI: the game's short names for Lua's own functions
  'abs', 'ceil', 'floor', 'format', 'gsub', 'max', 'min', 'mod', 'sin', 'sort', 'strfind', 'strlen', 'strlower',
  'strmatch', 'strsub', 'strupper', 'tinsert', 'tremove',
  -- FrameXML: functions of Blizzard's interface code
  'CreateColor', 'FauxScrollFrame_GetOffset', 'FauxScrollFrame_OnVerticalScroll', 'FauxScrollFrame_SetOffset',
  'FauxScrollFrame_Update', 'GameTooltip_SetDefaultAnchor', 'GameTooltip_ShowCompareItem', 'GetUIPanel',
  'GetUIPanelLayoutAttribute', 'GetUIPanelWidth', 'GetUIPanelWidthUnscaled', 'HandleModifiedItemClick', 'ReloadUI',
  'StaticPopup_Hide', 'StaticPopup_Show', 'UpdateUIPanelPositions',
  -- Frames
  'AuctionHouseFrame', 'GameTooltip', 'ItemRefTooltip', 'ProfessionsFrame', 'UIErrorsFrame', 'UIParent',
  -- GlobalStrings: the game's text
  'ACCEPT', 'ALL', 'AUCTION_POSTING_ERROR_TEXT', 'CANCEL', 'CONFIRM_AUCTION_POSTING_TEXT', 'ERR_AUCTION_BID_PLACED',
  'ERR_NOT_ENOUGH_MONEY', 'HOURS', 'ITEM_BIND_ON_PICKUP', 'ITEM_BIND_QUEST', 'ITEM_CONJURED', 'ITEM_MIN_LEVEL',
  'ITEM_SOULBOUND', 'ITEM_SPELL_CHARGES', 'ITEM_SPELL_KNOWN', 'ITEM_SPELL_TRIGGER_ONUSE', 'OKAY',
  -- Blizzard's Lua: tables and constants its interface code defines
  'AuctionCategories', 'ChatFrameUtil', 'DEFAULT_CHAT_FRAME', 'Enum', 'FONT_COLOR_CODE_CLOSE', 'GRAY_FONT_COLOR_CODE',
  'ITEM_QUALITY_COLORS', 'ItemLocation', 'LIGHTYELLOW_FONT_COLOR_CODE', 'MAXIMUM_BID_PRICE',
  'NUM_TOTAL_EQUIPPED_BAG_SLOTS', 'SOUNDKIT', 'STATICPOPUP_NUMDIALOGS', 'SlashCmdList', 'StaticPopupDialogs',
  'TooltipDataProcessor', 'UISpecialFrames',
  -- old names Forever no longer has as globals: compat.lua maps them to today's functions
  -- (GetItemCount is tried only as a fallback, tabs/search/crate.lua)
  'GetCoinTextureString', 'GetItemInfo', 'GetItemQualityColor', 'GetMerchantItemInfo', 'GetItemCount',
  'NumberFont_Normal_Med', 'compat_load_auction_house_ui',
  -- aux's own: its saved variables table and its hidden tooltip
  'aux', 'AuxTooltip',
}
