select(2, ...) 'aux.core.slash'

local aux = require 'aux'
local post = require 'aux.tabs.post'
local info = require 'aux.util.info'
local scan = require 'aux.core.scan'

function status(enabled)
	return (enabled and aux.color.green'on' or aux.color.red'off')
end

_G.SLASH_AUX1 = '/aux'
_G.SLASH_AUX2 = '/auxforever'
function SlashCmdList.AUX(command)
	if not command then return end
	local arguments = aux.tokenize(command)
    local tooltip_settings = aux.character_data.tooltip
    if arguments[1] == 'scale' and tonumber(arguments[2]) then
    	local scale = tonumber(arguments[2])
	    aux.frame:SetScale(scale)
	    aux.account_data.scale = scale
    elseif arguments[1] == 'ignore' and arguments[2] == 'owner' then
	    aux.account_data.ignore_owner = not aux.account_data.ignore_owner
        aux.print('ignore owner ' .. status(aux.account_data.ignore_owner))
    elseif arguments[1] == 'action' and arguments[2] == 'shortcuts' then
        aux.account_data.action_shortcuts = not aux.account_data.action_shortcuts
        aux.print('action shortcuts ' .. status(aux.account_data.action_shortcuts))
    elseif arguments[1] == 'post' and arguments[2] == 'full' and arguments[3] == 'scan' then
        aux.account_data.post_full_scan = not aux.account_data.post_full_scan
        aux.print('post full scan ' .. status(aux.account_data.post_full_scan))
    elseif arguments[1] == 'post' and arguments[2] == 'bid' then
        aux.account_data.post_bid = ({ unit = 'unit', stack = 'stack' })[arguments[3]]
	    aux.print('post bid ' .. aux.color.blue(aux.account_data.post_bid or 'off'))
    elseif arguments[1] == 'post' and arguments[2] == 'duration' and post_duration_code(arguments[3]) then
        -- Forever: accepts the hours of the auction house's options (e.g. 12, 24, 48)
        aux.account_data.post_duration = post_duration_code(arguments[3])
        aux.print('post duration ' .. aux.color.blue(info.duration_hours(aux.account_data.post_duration) .. 'h'))
    elseif arguments[1] == 'crafting' and arguments[2] == 'cost' then
		aux.account_data.crafting_cost = not aux.account_data.crafting_cost
		aux.print('crafting cost ' .. status(aux.account_data.crafting_cost))
    elseif arguments[1] == 'tooltip' and arguments[2] == 'value' then
	    tooltip_settings.value = not tooltip_settings.value
        aux.print('tooltip value ' .. status(tooltip_settings.value))
    elseif arguments[1] == 'tooltip' and arguments[2] == 'daily' then
	    tooltip_settings.daily = not tooltip_settings.daily
        aux.print('tooltip daily ' .. status(tooltip_settings.daily))
    elseif arguments[1] == 'tooltip' and arguments[2] == 'merchant' and arguments[3] == 'buy' then
	    tooltip_settings.merchant_buy = not tooltip_settings.merchant_buy
        aux.print('tooltip merchant buy ' .. status(tooltip_settings.merchant_buy))
    elseif arguments[1] == 'tooltip' and arguments[2] == 'merchant' and arguments[3] == 'sell' then
	    tooltip_settings.merchant_sell = not tooltip_settings.merchant_sell
        aux.print('tooltip merchant sell ' .. status(tooltip_settings.merchant_sell))
    elseif arguments[1] == 'tooltip' and arguments[2] == 'disenchant' and arguments[3] == 'value' then
	    tooltip_settings.disenchant_value = not tooltip_settings.disenchant_value
        aux.print('tooltip disenchant value ' .. status(tooltip_settings.disenchant_value))
    elseif arguments[1] == 'tooltip' and arguments[2] == 'disenchant' and arguments[3] == 'distribution' then
	    tooltip_settings.disenchant_distribution = not tooltip_settings.disenchant_distribution
        aux.print('tooltip disenchant distribution ' .. status(tooltip_settings.disenchant_distribution))
    elseif arguments[1] == 'tooltip' and arguments[2] == 'money'  and arguments[3] == 'icons' then
	    tooltip_settings.money_icons = not tooltip_settings.money_icons
        aux.print('tooltip money icons ' .. status(tooltip_settings.money_icons))
    elseif arguments[1] == 'clear' and arguments[2] == 'item' and arguments[3] == 'cache' then
	    aux.account_data.items = {}
        aux.account_data.item_ids = {}
        aux.account_data.unused_item_ids = {}
        aux.account_data.auctionable_items = {}
        aux.print('Item cache cleared.')
    elseif arguments[1] == 'undercut' then
        if arguments[2] == 'on' or arguments[2] == 'off' then
            post.set_undercut_mode(arguments[2] == 'on')
        end
        aux.print('Undercutting on Forever: when several listings share a price, the newest one sells first.')
        aux.print('So posting at the cheapest price sells just as fast as going below it, and keeps prices from sliding.')
        aux.print('auxForever matches the cheapest price by default. Undercut mode (the goblin on the Post tab) goes one step below it.')
        aux.print('This is known for trade goods. For gear, buyers pick the listing themselves.')
        aux.print('Undercut mode [' .. status(aux.account_data.post_undercut) .. '] - /aux undercut on|off')
    elseif arguments[1] == 'clear' and arguments[2] == 'post' then
        aux.faction_data.post = {}
        aux.print('Post data cleared.')
	else
		aux.print('Usage:')
        aux.print('- scale [' .. aux.color.blue(aux.account_data.scale) .. ']')
		aux.print('- ignore owner [' .. status(aux.account_data.ignore_owner) .. ']')
        aux.print('- action shortcuts [' .. status(aux.account_data.action_shortcuts) .. ']')
        aux.print('- post full scan [' .. status(aux.account_data.post_full_scan) .. ']')
        aux.print('- post bid [' .. aux.color.blue(aux.account_data.post_bid or 'off') .. ']')
        aux.print('- post duration [' .. aux.color.blue(info.duration_hours(aux.account_data.post_duration) .. 'h') .. ']')
        aux.print('- undercut [' .. status(aux.account_data.post_undercut) .. ']')
        aux.print('- crafting cost [' .. status(aux.account_data.crafting_cost) .. ']')
		aux.print('- tooltip value [' .. status(tooltip_settings.value) .. ']')
		aux.print('- tooltip daily [' .. status(tooltip_settings.daily) .. ']')
		aux.print('- tooltip merchant buy [' .. status(tooltip_settings.merchant_buy) .. ']')
		aux.print('- tooltip merchant sell [' .. status(tooltip_settings.merchant_sell) .. ']')
		aux.print('- tooltip disenchant value [' .. status(tooltip_settings.disenchant_value) .. ']')
		aux.print('- tooltip disenchant distribution [' .. status(tooltip_settings.disenchant_distribution) .. ']')
        aux.print('- tooltip money icons [' .. status(tooltip_settings.money_icons) .. ']')
		aux.print('- clear item cache')
        aux.print('- clear post')
    end
end

function post_duration_code(hours)
    for code = 1, 3 do
        if tostring(info.duration_hours(code)) == hours then
            return code
        end
    end
end
